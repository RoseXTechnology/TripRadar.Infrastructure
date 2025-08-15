targetScope = 'resourceGroup'

@description('Location for all resources.')
param location string = resourceGroup().location

@description('Name of the Log Analytics Workspace.')
param workspaceName string

@description('Name of the Application Insights component.')
param appInsightsName string

@description('Name of the Container Apps Managed Environment.')
param managedEnvName string

@description('Name of the Container App.')
param containerAppName string

@description('Container image for the Container App.')
param containerImage string

@description('CPU requested for the container (string, e.g., "0.5").')
param containerCpu string = '0.5'

@description('Memory requested for the container (e.g., "0.5Gi").')
param containerMemory string = '0.5Gi'

// ------------------------------------------------------------
// AVM module versions pinned for reproducible deployments
// - Container App:            0.18.1
// - Managed Environment:      0.11.2
// - Log Analytics Workspace:  0.12.0
// - Application Insights:     0.6.0
// ------------------------------------------------------------

// Log Analytics Workspace
module logAnalytics 'br/public:avm/res/operational-insights/workspace:0.12.0' = {
  name: 'logAnalytics'
  params: {
    name: workspaceName
    location: location
  }
}

// Application Insights (workspace-based)
module appInsights 'br/public:avm/res/insights/component:0.6.0' = {
  name: 'appInsights'
  params: {
    name: appInsightsName
    workspaceResourceId: logAnalytics.outputs.resourceId
    location: location
  }
}

// Container Apps Managed Environment
module managedEnv 'br/public:avm/res/app/managed-environment:0.11.2' = {
  name: 'managedEnvironment'
  params: {
    name: managedEnvName
  }
}

// Container App
module containerApp 'br/public:avm/res/app/container-app:0.18.1' = {
  name: 'containerApp'
  params: {
    name: containerAppName
    environmentResourceId: managedEnv.outputs.resourceId
    containers: [
      {
        image: containerImage
        name: 'main'
        resources: {
          cpu: containerCpu
          memory: containerMemory
        }
      }
    ]
  }
}

// -----------------
// Root-level outputs
// -----------------
@description('Container App FQDN (Ingress). If ingress is disabled in the module, this will be "IngressDisabled".')
output containerAppFqdn string = containerApp.outputs.fqdn

@description('Container App resource ID')
output containerAppResourceId string = containerApp.outputs.resourceId

@description('Managed Environment resource ID')
output managedEnvironmentResourceId string = managedEnv.outputs.resourceId

@description('Log Analytics Workspace resource ID')
output logAnalyticsWorkspaceResourceId string = logAnalytics.outputs.resourceId

@description('Log Analytics Workspace ID (GUID)')
output logAnalyticsWorkspaceId string = logAnalytics.outputs.logAnalyticsWorkspaceId

@description('Application Insights Connection String')
output appInsightsConnectionString string = appInsights.outputs.connectionString

@description('Application Insights Instrumentation Key')
output appInsightsInstrumentationKey string = appInsights.outputs.instrumentationKey
