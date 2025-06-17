// Virtual Network module for HAProxy AKS demo
// Creates VNet with subnet for AKS with VNet injection

@description('Name of the virtual network')
param name string

@description('Location for the virtual network')
param location string = resourceGroup().location

@description('Environment name for tagging')
param environmentName string

@description('Virtual network address space')
param vnetAddressPrefix string = '10.1.0.0/16'

@description('AKS subnet address prefix')
param aksSubnetPrefix string = '10.1.0.0/20'

// Network Security Group for AKS subnet
resource aksNsg 'Microsoft.Network/networkSecurityGroups@2024-05-01' = {
  name: '${name}-aks-nsg'
  location: location
  tags: {
    Environment: environmentName
    Purpose: 'AKS subnet security for HAProxy demo'
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
        name: 'AllowHTTPInbound'
        properties: {
          priority: 110
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
        name: 'AllowHTTPSInbound'
        properties: {
          priority: 120
          direction: 'Inbound'
          access: 'Allow'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '443'
          sourceAddressPrefix: 'Internet'
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
    Purpose: 'AKS VNet injection for HAProxy demo'
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
        }
      }
    ]
  }
}

// Outputs
output vnetId string = vnet.id
output aksSubnetId string = vnet.properties.subnets[0].id