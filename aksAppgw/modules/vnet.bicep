// Virtual Network module
// Creates VNet with separate subnets for AKS and Application Gateway

@description('Name of the virtual network')
param name string

@description('Location for the virtual network')
param location string = resourceGroup().location

@description('Environment name for tagging')
param environmentName string

@description('Virtual network address space')
param vnetAddressPrefix string = '10.0.0.0/16'

@description('AKS subnet address prefix')
param aksSubnetPrefix string = '10.0.1.0/24'

@description('Application Gateway subnet address prefix')
param appGatewaySubnetPrefix string = '10.0.2.0/24'

// Network Security Group for AKS subnet
resource aksNsg 'Microsoft.Network/networkSecurityGroups@2024-05-01' = {
  name: '${name}-aks-nsg'
  location: location
  tags: {
    Environment: environmentName
    Purpose: 'AKS subnet security'
  }
  properties: {
    securityRules: [
      {
        name: 'AllowAKSInternal'
        properties: {
          priority: 100
          direction: 'Inbound'
          access: 'Allow'
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: aksSubnetPrefix
          destinationAddressPrefix: aksSubnetPrefix
        }
      }
      {
        name: 'AllowApplicationGateway'
        properties: {
          priority: 110
          direction: 'Inbound'
          access: 'Allow'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '80'
          sourceAddressPrefix: appGatewaySubnetPrefix
          destinationAddressPrefix: aksSubnetPrefix
        }
      }
      {
        name: 'AllowApplicationGatewayHTTPS'
        properties: {
          priority: 120
          direction: 'Inbound'
          access: 'Allow'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '443'
          sourceAddressPrefix: appGatewaySubnetPrefix
          destinationAddressPrefix: aksSubnetPrefix
        }
      }
    ]
  }
}

// Network Security Group for Application Gateway subnet
resource appGwNsg 'Microsoft.Network/networkSecurityGroups@2024-05-01' = {
  name: '${name}-appgw-nsg'
  location: location
  tags: {
    Environment: environmentName
    Purpose: 'Application Gateway subnet security'
  }
  properties: {
    securityRules: [
      {
        name: 'AllowHTTP'
        properties: {
          priority: 100
          direction: 'Inbound'
          access: 'Allow'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '80'
          sourceAddressPrefix: 'Internet'
          destinationAddressPrefix: '*'
        }
      }
      {
        name: 'AllowHTTPS'
        properties: {
          priority: 110
          direction: 'Inbound'
          access: 'Allow'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '443'
          sourceAddressPrefix: 'Internet'
          destinationAddressPrefix: '*'
        }
      }
      {
        name: 'AllowApplicationGatewayV2'
        properties: {
          priority: 120
          direction: 'Inbound'
          access: 'Allow'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '65200-65535'
          sourceAddressPrefix: 'GatewayManager'
          destinationAddressPrefix: '*'
        }
      }
    ]
  }
}

// Virtual Network
resource vnet 'Microsoft.Network/virtualNetworks@2024-05-01' = {
  name: name
  location: location
  tags: {
    Environment: environmentName
    Purpose: 'AKS and Application Gateway networking'
  }
  properties: {
    addressSpace: {
      addressPrefixes: [
        vnetAddressPrefix
      ]
    }
    subnets: [
      {
        name: 'aks-subnet'
        properties: {
          addressPrefix: aksSubnetPrefix
          networkSecurityGroup: {
            id: aksNsg.id
          }
          privateEndpointNetworkPolicies: 'Disabled'
          privateLinkServiceNetworkPolicies: 'Disabled'
        }
      }
      {
        name: 'appgw-subnet'
        properties: {
          addressPrefix: appGatewaySubnetPrefix
          networkSecurityGroup: {
            id: appGwNsg.id
          }
          privateEndpointNetworkPolicies: 'Disabled'
          privateLinkServiceNetworkPolicies: 'Disabled'
        }
      }
    ]
  }
}

// Outputs
output vnetId string = vnet.id
output vnetName string = vnet.name
output aksSubnetId string = vnet.properties.subnets[0].id
output appGatewaySubnetId string = vnet.properties.subnets[1].id
output aksSubnetName string = vnet.properties.subnets[0].name
output appGatewaySubnetName string = vnet.properties.subnets[1].name
