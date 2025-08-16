@description('TripRadar Infrastructure - Main Orchestration Template')

targetScope = 'resourceGroup'

// ================================
// PARAMETERS
// ================================

@description('The location for all resources')
param location string = resourceGroup().location

@description('Environment type (dev, staging, prod)')
@allowed(['dev', 'staging', 'prod'])
param environment string

@description('Application name')
param appName string = 'tripradar'

@description('Unique suffix for resource naming')
param uniqueSuffix string = uniqueString(resourceGroup().id, deployment().name)

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
  database: 'mcr.microsoft.com/azuredocs/containerapps-helloworld:latest'
}

@description('Enable private endpoints')
param enablePrivateEndpoints bool = environment == 'prod'

@description('Enable high availability features')
param enableHighAvailability bool = environment == 'prod'

// ================================
// VARIABLES
// ================================

var namingPrefix = '${appName}-${environment}-${take(uniqueSuffix, 6)}'

var resourceNames = {
  // Networking
  vnet: '${namingPrefix}-vnet'
  
  // Security
  keyVault: '${namingPrefix}-kv'
  
  // Storage
  storageAccount: replace('${namingPrefix}storage', '-', '')
  redis: '${namingPrefix}-redis'
  
  // Database
  postgresql: '${namingPrefix}-postgres'
  
  // Monitoring
  logAnalytics: '${namingPrefix}-logs'
  appInsights: '${namingPrefix}-appinsights'
  
  // Containers
  containerRegistry: replace('${namingPrefix}acr', '-', '')
  containerAppsEnv: '${namingPrefix}-containerenv'
  mainApi: '${namingPrefix}-mainapi'
  jobsApi: '${namingPrefix}-jobsapi'
  database: '${namingPrefix}-db'
}

var commonTags = {
  Environment: environment
  Application: appName
  ManagedBy: 'Bicep'
  CostCenter: environment == 'prod' ? 'Production' : 'Development'
  DeployedAt: utcNow('yyyy-MM-dd HH:mm:ss')
}

// ================================
// NETWORKING MODULE
// ================================

module virtualNetwork 'modules/networking/virtual-network.bicep' = {
  name: 'deploy-vnet'
  params: {
    vnetName: resourceNames.vnet
    location: location
    environment: environment
    appName: appName
    addressSpace: environment == 'prod' ? '10.0.0.0/16' : '10.1.0.0/16'
  }
}

// ================================
// SECURITY MODULE
// ================================

module keyVault 'modules/security/key-vault.bicep' = {
  name: 'deploy-keyvault'
  params: {
    keyVaultName: resourceNames.keyVault
    location: location
    environment: environment
    appName: appName
    privateEndpointSubnetId: virtualNetwork.outputs.subnetIds.privateEndpointSubnet
    vnetId: virtualNetwork.outputs.vnetId
    enablePrivateEndpoint: enablePrivateEndpoints
    keyVaultAdminObjectId: keyVaultAdminObjectId
  }
}

// ================================
// MONITORING MODULE
// ================================

module monitoring 'modules/monitoring/application-insights.bicep' = {
  name: 'deploy-monitoring'
  params: {
    workspaceName: resourceNames.logAnalytics
    appInsightsName: resourceNames.appInsights
    location: location
    environment: environment
    appName: appName
    keyVaultId: keyVault.outputs.keyVaultId
    retentionInDays: environment == 'prod' ? 90 : 30
  }
}

// ================================
// STORAGE MODULES
// ================================

module storageAccount 'modules/storage/storage-account.bicep' = {
  name: 'deploy-storage'
  params: {
    storageAccountName: resourceNames.storageAccount
    location: location
    environment: environment
    appName: appName
    privateEndpointSubnetId: virtualNetwork.outputs.subnetIds.privateEndpointSubnet
    vnetId: virtualNetwork.outputs.vnetId
    enablePrivateEndpoint: enablePrivateEndpoints
    keyVaultId: keyVault.outputs.keyVaultId
  }
}

module redis 'modules/storage/redis.bicep' = {
  name: 'deploy-redis'
  params: {
    redisCacheName: resourceNames.redis
    location: location
    environment: environment
    appName: appName
    privateEndpointSubnetId: virtualNetwork.outputs.subnetIds.privateEndpointSubnet
    vnetId: virtualNetwork.outputs.vnetId
    enablePrivateEndpoint: enablePrivateEndpoints
    keyVaultId: keyVault.outputs.keyVaultId
  }
}

// ================================
// DATABASE MODULE
// ================================

module postgresql 'modules/database/postgresql.bicep' = {
  name: 'deploy-postgresql'
  params: {
    serverName: resourceNames.postgresql
    location: location
    environment: environment
    appName: appName
    databaseSubnetId: virtualNetwork.outputs.subnetIds.databaseSubnet
    vnetId: virtualNetwork.outputs.vnetId
    administratorLogin: postgresqlAdminUsername
    administratorPassword: postgresqlAdminPassword
    keyVaultId: keyVault.outputs.keyVaultId
  }
}

// ================================
// CONTAINER MODULES
// ================================

module containerRegistry 'modules/containers/container-registry.bicep' = {
  name: 'deploy-acr'
  params: {
    registryName: resourceNames.containerRegistry
    location: location
    environment: environment
    appName: appName
    privateEndpointSubnetId: virtualNetwork.outputs.subnetIds.privateEndpointSubnet
    vnetId: virtualNetwork.outputs.vnetId
    enablePrivateEndpoint: enablePrivateEndpoints
    keyVaultId: keyVault.outputs.keyVaultId
    managedIdentityPrincipalId: keyVault.outputs.managedIdentityPrincipalId
  }
}

module containerAppsEnvironment 'modules/containers/container-apps-environment.bicep' = {
  name: 'deploy-containerenv'
  params: {
    environmentName: resourceNames.containerAppsEnv
    location: location
    environment: environment
    appName: appName
    containerSubnetId: virtualNetwork.outputs.subnetIds.containerSubnet
    logAnalyticsWorkspaceId: monitoring.outputs.workspaceId
    appInsightsConnectionString: monitoring.outputs.connectionString
    keyVaultUri: keyVault.outputs.keyVaultUri
    managedIdentityClientId: keyVault.outputs.managedIdentityClientId
  }
  dependsOn: [
    redis
    storageAccount
  ]
}

// ================================
// APPLICATION MODULES
// ================================

module tripRadarApp 'modules/applications/tripradar-real.bicep' = {
  name: 'deploy-tripradar-app'
  params: {
    appNamePrefix: namingPrefix
    location: location
    environment: environment
    appName: appName
    containerAppsEnvironmentId: containerAppsEnvironment.outputs.environmentId
    containerRegistryLoginServer: containerRegistry.outputs.loginServer
    mainApiImage: containerImages.mainApi
    jobsApiImage: containerImages.jobsApi
    databaseImage: containerImages.database
    keyVaultUri: keyVault.outputs.keyVaultUri
    managedIdentityClientId: keyVault.outputs.managedIdentityClientId
    managedIdentityId: keyVault.outputs.managedIdentityId
    postgresqlConnectionString: postgresql.outputs.serverFqdn
  }
  dependsOn: [
    postgresql
    redis
    storageAccount
    monitoring
  ]
}

// ================================
// OUTPUTS
// ================================

@description('Resource Group Information')
output resourceGroup object = {
  id: resourceGroup().id
  name: resourceGroup().name
  location: resourceGroup().location
}

@description('Networking Outputs')
output networking object = {
  vnetId: virtualNetwork.outputs.vnetId
  vnetName: virtualNetwork.outputs.vnetName
  subnetIds: virtualNetwork.outputs.subnetIds
}

@description('Security Outputs')
output security object = {
  keyVaultId: keyVault.outputs.keyVaultId
  keyVaultName: keyVault.outputs.keyVaultName
  keyVaultUri: keyVault.outputs.keyVaultUri
  managedIdentityId: keyVault.outputs.managedIdentityId
  managedIdentityClientId: keyVault.outputs.managedIdentityClientId
}

@description('Storage Outputs')
output storage object = {
  storageAccountId: storageAccount.outputs.storageAccountId
  storageAccountName: storageAccount.outputs.storageAccountName
  redisId: redis.outputs.redisCacheId
  redisName: redis.outputs.redisCacheName
  redisHostName: redis.outputs.redisHostName
}

@description('Database Outputs')
output database object = {
  serverId: postgresql.outputs.serverId
  serverName: postgresql.outputs.serverName
  serverFqdn: postgresql.outputs.serverFqdn
  databaseName: postgresql.outputs.databaseName
  jobsDatabaseName: postgresql.outputs.jobsDatabaseName
}

@description('Monitoring Outputs')
output monitoring object = {
  logAnalyticsWorkspaceId: monitoring.outputs.workspaceId
  applicationInsightsId: monitoring.outputs.applicationInsightsId
  connectionString: monitoring.outputs.connectionString
  instrumentationKey: monitoring.outputs.instrumentationKey
}

@description('Container Outputs')
output containers object = {
  registryId: containerRegistry.outputs.registryId
  registryName: containerRegistry.outputs.registryName
  loginServer: containerRegistry.outputs.loginServer
  environmentId: containerAppsEnvironment.outputs.environmentId
  environmentName: containerAppsEnvironment.outputs.environmentName
  defaultDomain: containerAppsEnvironment.outputs.defaultDomain
}

@description('Application Outputs')
output applications object = {
  mainApiId: tripRadarApp.outputs.mainApiId
  mainApiName: tripRadarApp.outputs.mainApiName
  mainApiFqdn: tripRadarApp.outputs.mainApiFqdn
  jobsApiId: tripRadarApp.outputs.jobsApiId
  jobsApiName: tripRadarApp.outputs.jobsApiName
  databaseJobId: tripRadarApp.outputs.databaseJobId
  databaseJobName: tripRadarApp.outputs.databaseJobName
}

@description('Resource Names for Reference')
output resourceNames object = resourceNames

@description('Common Tags Applied')
output commonTags object = commonTags

@description('Environment Configuration')
output environmentConfig object = {
  environment: environment
  enablePrivateEndpoints: enablePrivateEndpoints
  enableHighAvailability: enableHighAvailability
  location: location
}