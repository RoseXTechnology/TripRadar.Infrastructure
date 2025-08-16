@description('Azure Database for PostgreSQL Flexible Server for TripRadar application')

targetScope = 'resourceGroup'

@description('The name of the PostgreSQL server')
param serverName string

@description('The location for all resources')
param location string = resourceGroup().location

@description('Environment type (dev, staging, prod)')
@allowed(['dev', 'staging', 'prod'])
param environment string

@description('Application name for resource tagging')
param appName string

@description('The subnet ID for database delegation')
param databaseSubnetId string

@description('The virtual network ID for private DNS zone')
param vnetId string

@description('Administrator username for the server')
@secure()
param administratorLogin string

@description('Administrator password for the server')
@secure()
param administratorPassword string

@description('Key Vault resource ID for storing secrets')
param keyVaultId string

var commonTags = {
  Environment: environment
  Application: appName
  ManagedBy: 'Bicep'
  CostCenter: environment == 'prod' ? 'Production' : 'Development'
}

// Environment-specific SKU configuration
var skuConfig = {
  dev: {
    name: 'Standard_B1ms'
    tier: 'Burstable'
  }
  staging: {
    name: 'Standard_D2s_v3'
    tier: 'GeneralPurpose'
  }
  prod: {
    name: 'Standard_D4s_v3'
    tier: 'GeneralPurpose'
  }
}

var storageConfig = {
  dev: {
    storageSizeGB: 32
    autoGrow: 'Enabled'
    geoRedundantBackup: 'Disabled'
    backupRetentionDays: 7
  }
  staging: {
    storageSizeGB: 128
    autoGrow: 'Enabled'
    geoRedundantBackup: 'Disabled'
    backupRetentionDays: 14
  }
  prod: {
    storageSizeGB: 512
    autoGrow: 'Enabled'
    geoRedundantBackup: 'Enabled'
    backupRetentionDays: 35
  }
}

// Private DNS Zone for PostgreSQL
resource postgresqlPrivateDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: '${serverName}.private.postgres.database.azure.com'
  location: 'global'
  tags: commonTags
}

// Link Private DNS Zone to VNet
resource postgresqlPrivateDnsZoneLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  parent: postgresqlPrivateDnsZone
  name: '${serverName}-dns-link'
  location: 'global'
  properties: {
    virtualNetwork: {
      id: vnetId
    }
    registrationEnabled: false
  }
}

// PostgreSQL Flexible Server
resource postgresqlServer 'Microsoft.DBforPostgreSQL/flexibleServers@2023-06-01-preview' = {
  name: serverName
  location: location
  tags: commonTags
  sku: skuConfig[environment]
  properties: {
    version: '15'
    administratorLogin: administratorLogin
    administratorLoginPassword: administratorPassword
    storage: {
      storageSizeGB: storageConfig[environment].storageSizeGB
      autoGrow: storageConfig[environment].autoGrow
    }
    backup: {
      backupRetentionDays: storageConfig[environment].backupRetentionDays
      geoRedundantBackup: storageConfig[environment].geoRedundantBackup
    }
    highAvailability: {
      mode: environment == 'prod' ? 'ZoneRedundant' : 'Disabled'
    }
    network: {
      delegatedSubnetResourceId: databaseSubnetId
      privateDnsZoneArmResourceId: postgresqlPrivateDnsZone.id
    }
    maintenanceWindow: {
      customWindow: 'Enabled'
      dayOfWeek: 0
      startHour: 2
      startMinute: 0
    }
  }
}

// Database configuration
resource postgresqlConfiguration 'Microsoft.DBforPostgreSQL/flexibleServers/configurations@2023-06-01-preview' = {
  parent: postgresqlServer
  name: 'max_connections'
  properties: {
    value: environment == 'prod' ? '200' : '100'
    source: 'user-override'
  }
}

// Main application database
resource tripRadarDatabase 'Microsoft.DBforPostgreSQL/flexibleServers/databases@2023-06-01-preview' = {
  parent: postgresqlServer
  name: '${appName}DB'
  properties: {
    charset: 'UTF8'
    collation: 'en_US.utf8'
  }
}

// Jobs database (if separate database needed)
resource jobsDatabase 'Microsoft.DBforPostgreSQL/flexibleServers/databases@2023-06-01-preview' = {
  parent: postgresqlServer
  name: '${appName}JobsDB'
  properties: {
    charset: 'UTF8'
    collation: 'en_US.utf8'
  }
}

// Store connection string in Key Vault
resource keyVault 'Microsoft.KeyVault/vaults@2023-07-01' existing = {
  name: last(split(keyVaultId, '/'))
}

resource connectionStringSecret 'Microsoft.KeyVault/vaults/secrets@2023-07-01' = {
  parent: keyVault
  name: 'PostgreSQLConnectionString'
  properties: {
    value: 'Server=${postgresqlServer.properties.fullyQualifiedDomainName};Database=${tripRadarDatabase.name};Port=5432;User Id=${administratorLogin};Password=${administratorPassword};Ssl Mode=Require;'
  }
}

resource jobsConnectionStringSecret 'Microsoft.KeyVault/vaults/secrets@2023-07-01' = {
  parent: keyVault
  name: 'PostgreSQLJobsConnectionString'
  properties: {
    value: 'Server=${postgresqlServer.properties.fullyQualifiedDomainName};Database=${jobsDatabase.name};Port=5432;User Id=${administratorLogin};Password=${administratorPassword};Ssl Mode=Require;'
  }
}

@description('PostgreSQL server resource ID')
output serverId string = postgresqlServer.id

@description('PostgreSQL server name')
output serverName string = postgresqlServer.name

@description('PostgreSQL server FQDN')
output serverFqdn string = postgresqlServer.properties.fullyQualifiedDomainName

@description('Main database name')
output databaseName string = tripRadarDatabase.name

@description('Jobs database name')
output jobsDatabaseName string = jobsDatabase.name

@description('Private DNS Zone resource ID')
output privateDnsZoneId string = postgresqlPrivateDnsZone.id
