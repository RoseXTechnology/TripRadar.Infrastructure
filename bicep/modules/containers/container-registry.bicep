@description('Azure Container Registry for TripRadar application container images')

targetScope = 'resourceGroup'

@description('The name of the container registry')
param registryName string

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

@description('Managed Identity principal ID for ACR access')
param managedIdentityPrincipalId string

var commonTags = {
  Environment: environment
  Application: appName
  ManagedBy: 'Bicep'
  CostCenter: environment == 'prod' ? 'Production' : 'Development'
}

// Environment-specific SKU configuration
var skuConfig = {
  dev: 'Basic'
  staging: 'Standard'
  prod: 'Premium'
}

// Container Registry
resource containerRegistry 'Microsoft.ContainerRegistry/registries@2023-07-01' = {
  name: registryName
  location: location
  tags: commonTags
  sku: {
    name: skuConfig[environment]
  }
  properties: {
    adminUserEnabled: false
    networkRuleSet: {
      defaultAction: enablePrivateEndpoint ? 'Deny' : 'Allow'
      ipRules: []
    }
    policies: {
      quarantinePolicy: {
        status: environment == 'prod' ? 'enabled' : 'disabled'
      }
      trustPolicy: {
        type: 'Notary'
        status: environment == 'prod' ? 'enabled' : 'disabled'
      }
      retentionPolicy: {
        days: environment == 'prod' ? 30 : 7
        status: 'enabled'
      }
      exportPolicy: {
        status: 'enabled'
      }
    }
    encryption: {
      status: 'disabled'
    }
    dataEndpointEnabled: environment == 'prod'
    publicNetworkAccess: enablePrivateEndpoint ? 'Disabled' : 'Enabled'
    zoneRedundancy: environment == 'prod' ? 'Enabled' : 'Disabled'
  }
  identity: {
    type: 'SystemAssigned'
  }
}

// Role assignment for managed identity to pull images
resource acrPullRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(containerRegistry.id, managedIdentityPrincipalId, 'AcrPull')
  scope: containerRegistry
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '7f951dda-4ed3-4680-a7ca-43fe172d538d') // AcrPull
    principalId: managedIdentityPrincipalId
    principalType: 'ServicePrincipal'
  }
}

// Private DNS Zone for Container Registry
resource acrPrivateDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = if (enablePrivateEndpoint) {
  name: 'privatelink.azurecr.io'
  location: 'global'
  tags: commonTags
}

// Link Private DNS Zone to VNet
resource acrPrivateDnsZoneLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = if (enablePrivateEndpoint) {
  parent: acrPrivateDnsZone
  name: '${registryName}-dns-link'
  location: 'global'
  properties: {
    virtualNetwork: {
      id: vnetId
    }
    registrationEnabled: false
  }
}

// Private Endpoint for Container Registry
resource acrPrivateEndpoint 'Microsoft.Network/privateEndpoints@2023-06-01' = if (enablePrivateEndpoint) {
  name: '${registryName}-pe'
  location: location
  tags: commonTags
  properties: {
    subnet: {
      id: privateEndpointSubnetId
    }
    privateLinkServiceConnections: [
      {
        name: '${registryName}-pe-connection'
        properties: {
          privateLinkServiceId: containerRegistry.id
          groupIds: ['registry']
        }
      }
    ]
  }
}

// Private DNS Zone Group
resource acrPrivateDnsZoneGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2023-06-01' = if (enablePrivateEndpoint) {
  parent: acrPrivateEndpoint
  name: 'default'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'registry'
        properties: {
          privateDnsZoneId: acrPrivateDnsZone.id
        }
      }
    ]
  }
}

// Store ACR details in Key Vault
resource keyVault 'Microsoft.KeyVault/vaults@2023-07-01' existing = {
  name: last(split(keyVaultId, '/'))
}

resource acrLoginServerSecret 'Microsoft.KeyVault/vaults/secrets@2023-07-01' = {
  parent: keyVault
  name: 'ACR-LoginServer'
  properties: {
    value: containerRegistry.properties.loginServer
  }
}

// Replication for production (geo-redundancy)
resource replication 'Microsoft.ContainerRegistry/registries/replications@2023-07-01' = if (environment == 'prod') {
  parent: containerRegistry
  name: 'westeurope'
  location: 'West Europe'
  properties: {
    regionEndpointEnabled: true
    zoneRedundancy: 'Enabled'
  }
}

@description('Container Registry resource ID')
output registryId string = containerRegistry.id

@description('Container Registry name')
output registryName string = containerRegistry.name

@description('Container Registry login server')
output loginServer string = containerRegistry.properties.loginServer

@description('Container Registry system assigned identity principal ID')
output registryPrincipalId string = containerRegistry.identity.principalId

@description('Private DNS Zone resource ID')
output privateDnsZoneId string = enablePrivateEndpoint ? acrPrivateDnsZone.id : ''
