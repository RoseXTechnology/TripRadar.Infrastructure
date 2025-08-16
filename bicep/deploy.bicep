@description('TripRadar Infrastructure - Deployment Template with Resource Group Creation')

targetScope = 'subscription'

// ================================
// PARAMETERS
// ================================

@description('The Azure region for the resource group and resources')
param location string = 'North Europe'

@description('Environment type (dev, staging, prod)')
@allowed(['dev', 'staging', 'prod'])
param environment string

@description('Application name')
param appName string = 'tripradar'

@description('Unique suffix for resource naming')
param uniqueSuffix string = uniqueString(subscription().subscriptionId, environment, appName)

@description('Key Vault administrator object ID')
param keyVaultAdminObjectId string

@description('PostgreSQL administrator username')
@secure()
param postgresqlAdminUsername string

@description('PostgreSQL administrator password')
@secure()
param postgresqlAdminPassword string

@description('Container image versions')
param containerImages object = {
  mainApi: 'mcr.microsoft.com/azuredocs/containerapps-helloworld:latest'
  jobsApi: 'mcr.microsoft.com/azuredocs/containerapps-helloworld:latest'
  database: 'postgres:15-alpine'
}

@description('Enable private endpoints')
param enablePrivateEndpoints bool = environment == 'prod'

@description('Enable high availability features')
param enableHighAvailability bool = environment == 'prod'

// ================================
// VARIABLES
// ================================

var resourceGroupName = 'rg-${appName}-${environment}-${take(uniqueSuffix, 6)}'

var commonTags = {
  Environment: environment
  Application: appName
  ManagedBy: 'Bicep'
  CostCenter: environment == 'prod' ? 'Production' : 'Development'
  Owner: 'DevOps Team'
  Project: 'TripRadar Infrastructure'
  DeployedAt: utcNow('yyyy-MM-dd HH:mm:ss')
}

// ================================
// RESOURCE GROUP
// ================================

resource resourceGroup 'Microsoft.Resources/resourceGroups@2023-07-01' = {
  name: resourceGroupName
  location: location
  tags: commonTags
}

// ================================
// MAIN INFRASTRUCTURE DEPLOYMENT
// ================================

module mainInfrastructure 'main.bicep' = {
  name: 'deploy-main-infrastructure'
  scope: resourceGroup
  params: {
    location: location
    environment: environment
    appName: appName
    uniqueSuffix: uniqueSuffix
    keyVaultAdminObjectId: keyVaultAdminObjectId
    postgresqlAdminUsername: postgresqlAdminUsername
    postgresqlAdminPassword: postgresqlAdminPassword
    containerImages: containerImages
    enablePrivateEndpoints: enablePrivateEndpoints
    enableHighAvailability: enableHighAvailability
  }
}

// ================================
// OUTPUTS
// ================================

@description('Deployment Summary')
output deploymentSummary object = {
  resourceGroupName: resourceGroup.name
  resourceGroupId: resourceGroup.id
  location: location
  environment: environment
  appName: appName
  deployedAt: utcNow('yyyy-MM-dd HH:mm:ss')
  enablePrivateEndpoints: enablePrivateEndpoints
  enableHighAvailability: enableHighAvailability
}

@description('Resource Group Information')
output resourceGroup object = {
  id: resourceGroup.id
  name: resourceGroup.name
  location: resourceGroup.location
}

@description('Infrastructure Outputs')
output infrastructure object = mainInfrastructure.outputs

@description('Quick Access URLs')
output quickAccess object = {
  mainApiUrl: 'https://${mainInfrastructure.outputs.applications.mainApiFqdn}'
  azurePortalResourceGroup: 'https://portal.azure.com/#@/resource${resourceGroup.id}'
  keyVaultUrl: 'https://portal.azure.com/#@/resource${mainInfrastructure.outputs.security.keyVaultId}'
  containerAppsUrl: 'https://portal.azure.com/#@/resource${mainInfrastructure.outputs.containers.environmentId}'
  applicationInsightsUrl: 'https://portal.azure.com/#@/resource${mainInfrastructure.outputs.monitoring.applicationInsightsId}'
}

@description('Connection Information')
output connectionInfo object = {
  mainApiFqdn: mainInfrastructure.outputs.applications.mainApiFqdn
  containerRegistryLoginServer: mainInfrastructure.outputs.containers.loginServer
  keyVaultUri: mainInfrastructure.outputs.security.keyVaultUri
  databaseFqdn: mainInfrastructure.outputs.database.serverFqdn
  redisHostName: mainInfrastructure.outputs.storage.redisHostName
}

@description('Resource Names for CI/CD Integration')
output resourceNames object = mainInfrastructure.outputs.resourceNames

@description('Applied Tags')
output appliedTags object = commonTags
