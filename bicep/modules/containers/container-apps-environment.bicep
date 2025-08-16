@description('Azure Container Apps Environment for TripRadar applications')

targetScope = 'resourceGroup'

@description('The name of the Container Apps managed environment')
param environmentName string

@description('The location for all resources')
param location string = resourceGroup().location

@description('Environment type (dev, staging, prod)')
@allowed(['dev', 'staging', 'prod'])
param environment string

@description('Application name for resource tagging')
param appName string

@description('Container subnet ID for Container Apps environment')
param containerSubnetId string

@description('Log Analytics workspace ID')
param logAnalyticsWorkspaceId string

@description('Application Insights connection string')
param appInsightsConnectionString string

@description('Key Vault URI for configuration')
param keyVaultUri string

@description('Managed Identity client ID for Key Vault access')
param managedIdentityClientId string

var commonTags = {
  Environment: environment
  Application: appName
  ManagedBy: 'Bicep'
  CostCenter: environment == 'prod' ? 'Production' : 'Development'
}

// Container Apps Managed Environment
resource containerAppsEnvironment 'Microsoft.App/managedEnvironments@2024-03-01' = {
  name: environmentName
  location: location
  tags: commonTags
  properties: {
    appLogsConfiguration: {
      destination: 'log-analytics'
      logAnalyticsConfiguration: {
        customerId: logAnalyticsWorkspaceId
        sharedKey: listKeys(resourceId('Microsoft.OperationalInsights/workspaces', last(split(logAnalyticsWorkspaceId, '/'))), '2021-06-01').primarySharedKey
      }
    }
    vnetConfiguration: {
      infrastructureSubnetId: containerSubnetId
      internal: false
    }
    zoneRedundant: environment == 'prod'
    kedaConfiguration: {}
    daprConfiguration: {
      enabled: true
    }
  }
}

// Environment variables for all container apps
resource environmentVariables 'Microsoft.App/managedEnvironments/workloadProfileStates@2024-03-01' = {
  parent: containerAppsEnvironment
  name: 'environment-variables'
  properties: {
    currentWorkloadProfile: {
      name: 'Consumption'
      workloadProfileType: 'Consumption'
    }
  }
}

// Dapr components for shared resources
resource redisStateStore 'Microsoft.App/managedEnvironments/daprComponents@2024-03-01' = {
  parent: containerAppsEnvironment
  name: 'redis-statestore'
  properties: {
    componentType: 'state.redis'
    version: 'v1'
    metadata: [
      {
        name: 'redisHost'
        secretRef: 'redis-host'
      }
      {
        name: 'redisPassword'
        secretRef: 'redis-password'
      }
      {
        name: 'enableTLS'
        value: 'true'
      }
    ]
    secrets: [
      {
        name: 'redis-host'
        keyVaultUrl: '${keyVaultUri}secrets/RedisConnectionString'
        identity: managedIdentityClientId
      }
      {
        name: 'redis-password'
        keyVaultUrl: '${keyVaultUri}secrets/RedisPrimaryKey'
        identity: managedIdentityClientId
      }
    ]
    scopes: []
  }
}

resource redisPubSub 'Microsoft.App/managedEnvironments/daprComponents@2024-03-01' = {
  parent: containerAppsEnvironment
  name: 'redis-pubsub'
  properties: {
    componentType: 'pubsub.redis'
    version: 'v1'
    metadata: [
      {
        name: 'redisHost'
        secretRef: 'redis-host'
      }
      {
        name: 'redisPassword'
        secretRef: 'redis-password'
      }
      {
        name: 'enableTLS'
        value: 'true'
      }
    ]
    secrets: [
      {
        name: 'redis-host'
        keyVaultUrl: '${keyVaultUri}secrets/RedisConnectionString'
        identity: managedIdentityClientId
      }
      {
        name: 'redis-password'
        keyVaultUrl: '${keyVaultUri}secrets/RedisPrimaryKey'
        identity: managedIdentityClientId
      }
    ]
    scopes: []
  }
}

resource secretsBinding 'Microsoft.App/managedEnvironments/daprComponents@2024-03-01' = {
  parent: containerAppsEnvironment
  name: 'secrets-binding'
  properties: {
    componentType: 'bindings.azure.keyvault'
    version: 'v1'
    metadata: [
      {
        name: 'vaultName'
        value: last(split(keyVaultUri, '/'))
      }
      {
        name: 'azureClientId'
        value: managedIdentityClientId
      }
    ]
    scopes: []
  }
}

// Auto-scaling profiles based on environment
resource workloadProfile 'Microsoft.App/managedEnvironments/workloadProfiles@2024-03-01' = if (environment == 'prod') {
  parent: containerAppsEnvironment
  name: 'general-purpose'
  properties: {
    workloadProfileType: 'D4'
    minimumCount: 1
    maximumCount: 10
  }
}

@description('Container Apps Environment resource ID')
output environmentId string = containerAppsEnvironment.id

@description('Container Apps Environment name')
output environmentName string = containerAppsEnvironment.name

@description('Container Apps Environment default domain')
output defaultDomain string = containerAppsEnvironment.properties.defaultDomain

@description('Container Apps Environment static IP')
output staticIp string = containerAppsEnvironment.properties.staticIp
