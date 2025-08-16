@description('Azure Storage Account for TripRadar application artifacts and backups')

targetScope = 'resourceGroup'

@description('The name of the storage account')
param storageAccountName string

@description('The location for all resources')
param location string = resourceGroup().location

@description('Environment type (dev, staging, prod)')
@allowed(['dev', 'staging', 'prod'])
param environment string

@description('Application name for resource tagging')
param appName string

@description('The subnet ID for private endpoint')
param privateEndpointSubnetId string

@description('The virtual network ID for private DNS zone')
param vnetId string

@description('Enable private endpoint')
param enablePrivateEndpoint bool = true

@description('Key Vault resource ID for storing secrets')
param keyVaultId string

var commonTags = {
  Environment: environment
  Application: appName
  ManagedBy: 'Bicep'
  CostCenter: environment == 'prod' ? 'Production' : 'Development'
}

// Environment-specific configuration
var storageConfig = {
  dev: {
    sku: 'Standard_LRS'
    accessTier: 'Hot'
  }
  staging: {
    sku: 'Standard_ZRS'
    accessTier: 'Hot'
  }
  prod: {
    sku: 'Standard_GRS'
    accessTier: 'Hot'
  }
}

// Storage Account
resource storageAccount 'Microsoft.Storage/storageAccounts@2023-01-01' = {
  name: storageAccountName
  location: location
  tags: commonTags
  sku: {
    name: storageConfig[environment].sku
  }
  kind: 'StorageV2'
  properties: {
    defaultToOAuthAuthentication: true
    allowCrossTenantReplication: false
    minimumTlsVersion: 'TLS1_2'
    allowBlobPublicAccess: false
    allowSharedKeyAccess: true
    supportsHttpsTrafficOnly: true
    accessTier: storageConfig[environment].accessTier
    publicNetworkAccess: enablePrivateEndpoint ? 'Disabled' : 'Enabled'
    networkAcls: {
      bypass: 'AzureServices'
      defaultAction: enablePrivateEndpoint ? 'Deny' : 'Allow'
    }
  }
}

// Blob containers
resource applicationLogsContainer 'Microsoft.Storage/storageAccounts/blobServices/containers@2023-01-01' = {
  name: '${storageAccount.name}/default/application-logs'
  properties: {
    publicAccess: 'None'
    metadata: {
      purpose: 'Application log storage'
      environment: environment
    }
  }
}

resource backupsContainer 'Microsoft.Storage/storageAccounts/blobServices/containers@2023-01-01' = {
  name: '${storageAccount.name}/default/backups'
  properties: {
    publicAccess: 'None'
    metadata: {
      purpose: 'Database and application backups'
      environment: environment
    }
  }
}

resource artifactsContainer 'Microsoft.Storage/storageAccounts/blobServices/containers@2023-01-01' = {
  name: '${storageAccount.name}/default/artifacts'
  properties: {
    publicAccess: 'None'
    metadata: {
      purpose: 'CI/CD artifacts and deployment packages'
      environment: environment
    }
  }
}

resource configurationContainer 'Microsoft.Storage/storageAccounts/blobServices/containers@2023-01-01' = {
  name: '${storageAccount.name}/default/configuration'
  properties: {
    publicAccess: 'None'
    metadata: {
      purpose: 'Application configuration files'
      environment: environment
    }
  }
}

// Lifecycle management policy
resource lifecyclePolicy 'Microsoft.Storage/storageAccounts/managementPolicies@2023-01-01' = {
  parent: storageAccount
  name: 'default'
  properties: {
    policy: {
      rules: [
        {
          name: 'LogsRetentionPolicy'
          enabled: true
          type: 'Lifecycle'
          definition: {
            filters: {
              blobTypes: ['blockBlob']
              prefixMatch: ['application-logs/']
            }
            actions: {
              baseBlob: {
                tierToCool: {
                  daysAfterModificationGreaterThan: 30
                }
                tierToArchive: {
                  daysAfterModificationGreaterThan: 90
                }
                delete: {
                  daysAfterModificationGreaterThan: environment == 'prod' ? 365 : 90
                }
              }
            }
          }
        }
        {
          name: 'BackupsRetentionPolicy'
          enabled: true
          type: 'Lifecycle'
          definition: {
            filters: {
              blobTypes: ['blockBlob']
              prefixMatch: ['backups/']
            }
            actions: {
              baseBlob: {
                tierToCool: {
                  daysAfterModificationGreaterThan: 7
                }
                tierToArchive: {
                  daysAfterModificationGreaterThan: 30
                }
                delete: {
                  daysAfterModificationGreaterThan: environment == 'prod' ? 2555 : 365 // 7 years for prod, 1 year for others
                }
              }
            }
          }
        }
      ]
    }
  }
}

// Private DNS Zones for Storage Account
resource blobPrivateDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = if (enablePrivateEndpoint) {
  name: 'privatelink.blob.core.windows.net'
  location: 'global'
  tags: commonTags
}

resource filePrivateDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = if (enablePrivateEndpoint) {
  name: 'privatelink.file.core.windows.net'
  location: 'global'
  tags: commonTags
}

resource queuePrivateDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = if (enablePrivateEndpoint) {
  name: 'privatelink.queue.core.windows.net'
  location: 'global'
  tags: commonTags
}

resource tablePrivateDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = if (enablePrivateEndpoint) {
  name: 'privatelink.table.core.windows.net'
  location: 'global'
  tags: commonTags
}

// Link Private DNS Zones to VNet
resource blobPrivateDnsZoneLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = if (enablePrivateEndpoint) {
  parent: blobPrivateDnsZone
  name: '${storageAccountName}-blob-dns-link'
  location: 'global'
  properties: {
    virtualNetwork: { id: vnetId }
    registrationEnabled: false
  }
}

resource filePrivateDnsZoneLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = if (enablePrivateEndpoint) {
  parent: filePrivateDnsZone
  name: '${storageAccountName}-file-dns-link'
  location: 'global'
  properties: {
    virtualNetwork: { id: vnetId }
    registrationEnabled: false
  }
}

// Private Endpoints
resource blobPrivateEndpoint 'Microsoft.Network/privateEndpoints@2023-06-01' = if (enablePrivateEndpoint) {
  name: '${storageAccountName}-blob-pe'
  location: location
  tags: commonTags
  properties: {
    subnet: { id: privateEndpointSubnetId }
    privateLinkServiceConnections: [
      {
        name: '${storageAccountName}-blob-pe-connection'
        properties: {
          privateLinkServiceId: storageAccount.id
          groupIds: ['blob']
        }
      }
    ]
  }
}

resource filePrivateEndpoint 'Microsoft.Network/privateEndpoints@2023-06-01' = if (enablePrivateEndpoint) {
  name: '${storageAccountName}-file-pe'
  location: location
  tags: commonTags
  properties: {
    subnet: { id: privateEndpointSubnetId }
    privateLinkServiceConnections: [
      {
        name: '${storageAccountName}-file-pe-connection'
        properties: {
          privateLinkServiceId: storageAccount.id
          groupIds: ['file']
        }
      }
    ]
  }
}

// Private DNS Zone Groups
resource blobPrivateDnsZoneGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2023-06-01' = if (enablePrivateEndpoint) {
  parent: blobPrivateEndpoint
  name: 'default'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'blob'
        properties: { privateDnsZoneId: blobPrivateDnsZone.id }
      }
    ]
  }
}

resource filePrivateDnsZoneGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2023-06-01' = if (enablePrivateEndpoint) {
  parent: filePrivateEndpoint
  name: 'default'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'file'
        properties: { privateDnsZoneId: filePrivateDnsZone.id }
      }
    ]
  }
}

// Store storage connection string in Key Vault
resource keyVault 'Microsoft.KeyVault/vaults@2023-07-01' existing = {
  name: last(split(keyVaultId, '/'))
}

resource storageConnectionStringSecret 'Microsoft.KeyVault/vaults/secrets@2023-07-01' = {
  parent: keyVault
  name: 'StorageConnectionString'
  properties: {
    value: 'DefaultEndpointsProtocol=https;AccountName=${storageAccount.name};AccountKey=${storageAccount.listKeys().keys[0].value};EndpointSuffix=core.windows.net'
  }
}

@description('Storage Account resource ID')
output storageAccountId string = storageAccount.id

@description('Storage Account name')
output storageAccountName string = storageAccount.name

@description('Primary endpoints')
output primaryEndpoints object = storageAccount.properties.primaryEndpoints

@description('Container names')
output containerNames object = {
  applicationLogs: 'application-logs'
  backups: 'backups'
  artifacts: 'artifacts'
  configuration: 'configuration'
}
