@description('Azure Cache for Redis for TripRadar application caching')

targetScope = 'resourceGroup'

@description('The name of the Redis cache')
param redisCacheName string

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

// Environment-specific SKU configuration
var skuConfig = {
  dev: {
    name: 'Basic'
    family: 'C'
    capacity: 0
  }
  staging: {
    name: 'Standard'
    family: 'C'
    capacity: 1
  }
  prod: {
    name: 'Premium'
    family: 'P'
    capacity: 2
  }
}

// Redis Cache
resource redisCache 'Microsoft.Cache/redis@2023-08-01' = {
  name: redisCacheName
  location: location
  tags: commonTags
  properties: {
    sku: skuConfig[environment]
    redisConfiguration: {
      'maxmemory-reserved': environment == 'prod' ? '200' : '50'
      'maxfragmentationmemory-reserved': environment == 'prod' ? '200' : '50'
      'maxmemory-policy': 'allkeys-lru'
    }
    enableNonSslPort: false
    minimumTlsVersion: '1.2'
    publicNetworkAccess: enablePrivateEndpoint ? 'Disabled' : 'Enabled'
    redisVersion: '6.0'
  }
}

// Private DNS Zone for Redis
resource redisPrivateDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = if (enablePrivateEndpoint) {
  name: 'privatelink.redis.cache.windows.net'
  location: 'global'
  tags: commonTags
}

// Link Private DNS Zone to VNet
resource redisPrivateDnsZoneLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = if (enablePrivateEndpoint) {
  parent: redisPrivateDnsZone
  name: '${redisCacheName}-dns-link'
  location: 'global'
  properties: {
    virtualNetwork: {
      id: vnetId
    }
    registrationEnabled: false
  }
}

// Private Endpoint for Redis
resource redisPrivateEndpoint 'Microsoft.Network/privateEndpoints@2023-06-01' = if (enablePrivateEndpoint) {
  name: '${redisCacheName}-pe'
  location: location
  tags: commonTags
  properties: {
    subnet: {
      id: privateEndpointSubnetId
    }
    privateLinkServiceConnections: [
      {
        name: '${redisCacheName}-pe-connection'
        properties: {
          privateLinkServiceId: redisCache.id
          groupIds: ['redisCache']
        }
      }
    ]
  }
}

// Private DNS Zone Group
resource redisPrivateDnsZoneGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2023-06-01' = if (enablePrivateEndpoint) {
  parent: redisPrivateEndpoint
  name: 'default'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'redis'
        properties: {
          privateDnsZoneId: redisPrivateDnsZone.id
        }
      }
    ]
  }
}

// Store Redis connection string in Key Vault
resource keyVault 'Microsoft.KeyVault/vaults@2023-07-01' existing = {
  name: last(split(keyVaultId, '/'))
}

resource redisConnectionStringSecret 'Microsoft.KeyVault/vaults/secrets@2023-07-01' = {
  parent: keyVault
  name: 'RedisConnectionString'
  properties: {
    value: '${redisCache.properties.hostName}:${redisCache.properties.sslPort},password=${redisCache.listKeys().primaryKey},ssl=True,abortConnect=False'
  }
}

resource redisPrimaryKeySecret 'Microsoft.KeyVault/vaults/secrets@2023-07-01' = {
  parent: keyVault
  name: 'RedisPrimaryKey'
  properties: {
    value: redisCache.listKeys().primaryKey
  }
}

@description('Redis Cache resource ID')
output redisCacheId string = redisCache.id

@description('Redis Cache name')
output redisCacheName string = redisCache.name

@description('Redis Cache hostname')
output redisHostName string = redisCache.properties.hostName

@description('Redis Cache port')
output redisPort int = redisCache.properties.port

@description('Redis Cache SSL port')
output redisSslPort int = redisCache.properties.sslPort

@description('Private DNS Zone resource ID')
output privateDnsZoneId string = enablePrivateEndpoint ? redisPrivateDnsZone.id : ''
