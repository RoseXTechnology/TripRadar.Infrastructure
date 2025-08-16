@description('Azure Application Insights and Log Analytics for TripRadar application monitoring')

targetScope = 'resourceGroup'

@description('The name of the Log Analytics workspace')
param workspaceName string

@description('The name of the Application Insights component')
param appInsightsName string

@description('The location for all resources')
param location string = resourceGroup().location

@description('Environment type (dev, staging, prod)')
@allowed(['dev', 'staging', 'prod'])
param environment string

@description('Application name for resource tagging')
param appName string

@description('Key Vault resource ID for storing secrets')
param keyVaultId string

@description('Data retention in days')
param retentionInDays int = environment == 'prod' ? 90 : 30

var commonTags = {
  Environment: environment
  Application: appName
  ManagedBy: 'Bicep'
  CostCenter: environment == 'prod' ? 'Production' : 'Development'
}

// Environment-specific pricing tier
var pricingTier = environment == 'prod' ? 'PerGB2018' : 'PerGB2018'

// Log Analytics Workspace
resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2023-09-01' = {
  name: workspaceName
  location: location
  tags: commonTags
  properties: {
    sku: {
      name: pricingTier
    }
    retentionInDays: retentionInDays
    features: {
      enableLogAccessUsingOnlyResourcePermissions: true
      disableLocalAuth: false
    }
    workspaceCapping: {
      dailyQuotaGb: environment == 'dev' ? 1 : environment == 'staging' ? 5 : -1
    }
  }
}

// Application Insights
resource applicationInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: appInsightsName
  location: location
  tags: commonTags
  kind: 'web'
  properties: {
    Application_Type: 'web'
    WorkspaceResourceId: logAnalyticsWorkspace.id
    IngestionMode: 'LogAnalytics'
    DisableIpMasking: false
    DisableLocalAuth: false
    publicNetworkAccessForIngestion: 'Enabled'
    publicNetworkAccessForQuery: 'Enabled'
  }
}

// Action Groups for alerting
resource actionGroup 'Microsoft.Insights/actionGroups@2023-01-01' = {
  name: '${appName}-${environment}-alerts'
  location: 'global'
  tags: commonTags
  properties: {
    groupShortName: '${appName}${environment}'
    enabled: true
    emailReceivers: []
    smsReceivers: []
    webhookReceivers: []
    azureFunctionReceivers: []
    logicAppReceivers: []
  }
}

// Availability test for production
resource availabilityTest 'Microsoft.Insights/webtests@2022-06-15' = if (environment == 'prod') {
  name: '${appName}-availability-test'
  location: location
  tags: union(commonTags, {
    'hidden-link:${applicationInsights.id}': 'Resource'
  })
  kind: 'ping'
  properties: {
    SyntheticMonitorId: '${appName}-availability-test'
    Name: '${appName} Availability Test'
    Enabled: true
    Frequency: 300
    Timeout: 120
    Kind: 'ping'
    Locations: [
      {
        Id: 'emea-nl-ams-azr'
      }
      {
        Id: 'emea-gb-db3-azr'
      }
      {
        Id: 'us-ca-sjc-azr'
      }
    ]
    Configuration: {
      WebTest: '<WebTest Name="${appName} Availability Test" Id="ABD48585-0831-40CB-9069-682A25A54A34" Enabled="True" CssProjectStructure="" CssIteration="" Timeout="120" WorkItemIds="" xmlns="http://microsoft.com/schemas/VisualStudio/TeamTest/2010" Description="" CredentialUserName="" CredentialPassword="" PreAuthenticate="True" Proxy="default" StopOnError="False" RecordedResultFile="" ResultsLocale=""><Items><Request Method="GET" Guid="a5f10126-e4cd-570d-961c-cea43999a200" Version="1.1" Url="https://placeholder-url.azurecontainerapps.io" ThinkTime="0" Timeout="120" ParseDependentRequests="True" FollowRedirects="True" RecordResult="True" Cache="False" ResponseTimeGoal="0" Encoding="utf-8" ExpectedHttpStatusCode="200" ExpectedResponseUrl="" ReportingName="" IgnoreHttpStatusCode="False" /></Items></WebTest>'
    }
  }
}

// Critical alerts
resource highErrorRateAlert 'Microsoft.Insights/metricAlerts@2018-03-01' = {
  name: '${appName}-${environment}-high-error-rate'
  location: 'global'
  tags: commonTags
  properties: {
    description: 'High error rate detected'
    severity: 1
    enabled: true
    scopes: [
      applicationInsights.id
    ]
    evaluationFrequency: 'PT5M'
    windowSize: 'PT5M'
    criteria: {
      'odata.type': 'Microsoft.Azure.Monitor.SingleResourceMultipleMetricCriteria'
      allOf: [
        {
          name: 'HighErrorRate'
          metricName: 'exceptions/count'
          operator: 'GreaterThan'
          threshold: environment == 'prod' ? 10 : 5
          timeAggregation: 'Count'
          criterionType: 'StaticThresholdCriterion'
        }
      ]
    }
    actions: [
      {
        actionGroupId: actionGroup.id
      }
    ]
  }
}

resource highResponseTimeAlert 'Microsoft.Insights/metricAlerts@2018-03-01' = {
  name: '${appName}-${environment}-high-response-time'
  location: 'global'
  tags: commonTags
  properties: {
    description: 'High response time detected'
    severity: 2
    enabled: true
    scopes: [
      applicationInsights.id
    ]
    evaluationFrequency: 'PT5M'
    windowSize: 'PT5M'
    criteria: {
      'odata.type': 'Microsoft.Azure.Monitor.SingleResourceMultipleMetricCriteria'
      allOf: [
        {
          name: 'HighResponseTime'
          metricName: 'requests/duration'
          operator: 'GreaterThan'
          threshold: environment == 'prod' ? 2000 : 5000
          timeAggregation: 'Average'
          criterionType: 'StaticThresholdCriterion'
        }
      ]
    }
    actions: [
      {
        actionGroupId: actionGroup.id
      }
    ]
  }
}

// Workbook for monitoring dashboard
resource monitoringWorkbook 'Microsoft.Insights/workbooks@2023-06-01' = {
  name: guid('${appName}-${environment}-monitoring-workbook')
  location: location
  tags: commonTags
  kind: 'shared'
  properties: {
    displayName: '${appName} ${environment} Monitoring Dashboard'
    serializedData: json(loadTextContent('./workbook-template.json'))
    category: 'workbook'
    sourceId: applicationInsights.id
  }
}

// Store Application Insights secrets in Key Vault
resource keyVault 'Microsoft.KeyVault/vaults@2023-07-01' existing = {
  name: last(split(keyVaultId, '/'))
}

resource appInsightsConnectionStringSecret 'Microsoft.KeyVault/vaults/secrets@2023-07-01' = {
  parent: keyVault
  name: 'ApplicationInsights-ConnectionString'
  properties: {
    value: applicationInsights.properties.ConnectionString
  }
}

resource appInsightsInstrumentationKeySecret 'Microsoft.KeyVault/vaults/secrets@2023-07-01' = {
  parent: keyVault
  name: 'ApplicationInsights-InstrumentationKey'
  properties: {
    value: applicationInsights.properties.InstrumentationKey
  }
}

@description('Log Analytics Workspace resource ID')
output workspaceId string = logAnalyticsWorkspace.id

@description('Log Analytics Workspace name')
output workspaceName string = logAnalyticsWorkspace.name

@description('Log Analytics Workspace GUID')
output workspaceGuid string = logAnalyticsWorkspace.properties.customerId

@description('Application Insights resource ID')
output applicationInsightsId string = applicationInsights.id

@description('Application Insights name')
output applicationInsightsName string = applicationInsights.name

@description('Application Insights connection string')
output connectionString string = applicationInsights.properties.ConnectionString

@description('Application Insights instrumentation key')
output instrumentationKey string = applicationInsights.properties.InstrumentationKey

@description('Action Group resource ID')
output actionGroupId string = actionGroup.id
