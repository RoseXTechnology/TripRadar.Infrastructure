using './main.bicep'

// Minimal sample values for quick compilation/deployment
param workspaceName = 'oiwmin001'
param appInsightsName = 'apimin001'
param managedEnvName = 'caemin001'
param containerAppName = 'acamin001'
param containerImage = 'mcr.microsoft.com/azuredocs/containerapps-helloworld:latest'

// Optional overrides (defaults exist in main.bicep)
// param containerCpu = '0.5'
// param containerMemory = '0.5Gi'
