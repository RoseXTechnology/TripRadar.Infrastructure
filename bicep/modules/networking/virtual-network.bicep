@description('Virtual Network configuration for TripRadar infrastructure')

targetScope = 'resourceGroup'

@description('The name of the virtual network')
param vnetName string

@description('The location for all resources')
param location string = resourceGroup().location

@description('The address space of the virtual network')
param addressSpace string = '10.0.0.0/16'

@description('Environment type (dev, staging, prod)')
@allowed(['dev', 'staging', 'prod'])
param environment string

@description('Application name for resource tagging')
param appName string

@description('Subnet configurations')
param subnets array = [
  {
    name: 'container-subnet'
    addressPrefix: '10.0.1.0/24'
    delegation: 'Microsoft.App/environments'
  }
  {
    name: 'database-subnet'
    addressPrefix: '10.0.2.0/24'
    delegation: 'Microsoft.DBforPostgreSQL/flexibleServers'
  }
  {
    name: 'appgateway-subnet'
    addressPrefix: '10.0.3.0/24'
    delegation: null
  }
  {
    name: 'private-endpoint-subnet'
    addressPrefix: '10.0.4.0/24'
    delegation: null
  }
]

var commonTags = {
  Environment: environment
  Application: appName
  ManagedBy: 'Bicep'
  CostCenter: environment == 'prod' ? 'Production' : 'Development'
}

// Network Security Groups
resource containerNsg 'Microsoft.Network/networkSecurityGroups@2023-06-01' = {
  name: '${vnetName}-container-nsg'
  location: location
  tags: commonTags
  properties: {
    securityRules: [
      {
        name: 'AllowHTTPS'
        properties: {
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '443'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 1000
          direction: 'Inbound'
        }
      }
      {
        name: 'AllowHTTP'
        properties: {
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '80'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 1010
          direction: 'Inbound'
        }
      }
    ]
  }
}

resource databaseNsg 'Microsoft.Network/networkSecurityGroups@2023-06-01' = {
  name: '${vnetName}-database-nsg'
  location: location
  tags: commonTags
  properties: {
    securityRules: [
      {
        name: 'AllowPostgreSQL'
        properties: {
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '5432'
          sourceAddressPrefix: '10.0.1.0/24'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 1000
          direction: 'Inbound'
        }
      }
    ]
  }
}

resource appGatewayNsg 'Microsoft.Network/networkSecurityGroups@2023-06-01' = {
  name: '${vnetName}-appgateway-nsg'
  location: location
  tags: commonTags
  properties: {
    securityRules: [
      {
        name: 'AllowGatewayManager'
        properties: {
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '65200-65535'
          sourceAddressPrefix: 'GatewayManager'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 1000
          direction: 'Inbound'
        }
      }
      {
        name: 'AllowHTTPS'
        properties: {
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '443'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 1010
          direction: 'Inbound'
        }
      }
      {
        name: 'AllowHTTP'
        properties: {
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '80'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 1020
          direction: 'Inbound'
        }
      }
    ]
  }
}

// Virtual Network
resource vnet 'Microsoft.Network/virtualNetworks@2023-06-01' = {
  name: vnetName
  location: location
  tags: commonTags
  properties: {
    addressSpace: {
      addressPrefixes: [addressSpace]
    }
    subnets: [for subnet in subnets: {
      name: subnet.name
      properties: {
        addressPrefix: subnet.addressPrefix
        networkSecurityGroup: subnet.name == 'container-subnet' ? { id: containerNsg.id } : 
                              subnet.name == 'database-subnet' ? { id: databaseNsg.id } :
                              subnet.name == 'appgateway-subnet' ? { id: appGatewayNsg.id } : null
        delegations: subnet.delegation != null ? [
          {
            name: 'delegation'
            properties: {
              serviceName: subnet.delegation
            }
          }
        ] : []
        privateEndpointNetworkPolicies: subnet.name == 'private-endpoint-subnet' ? 'Disabled' : 'Enabled'
        privateLinkServiceNetworkPolicies: subnet.name == 'private-endpoint-subnet' ? 'Disabled' : 'Enabled'
      }
    }]
  }
}

@description('Virtual Network resource ID')
output vnetId string = vnet.id

@description('Virtual Network name')
output vnetName string = vnet.name

@description('Subnet IDs')
output subnetIds object = {
  containerSubnet: vnet.properties.subnets[0].id
  databaseSubnet: vnet.properties.subnets[1].id
  appGatewaySubnet: vnet.properties.subnets[2].id
  privateEndpointSubnet: vnet.properties.subnets[3].id
}

@description('Network Security Group IDs')
output nsgIds object = {
  containerNsg: containerNsg.id
  databaseNsg: databaseNsg.id
  appGatewayNsg: appGatewayNsg.id
}
