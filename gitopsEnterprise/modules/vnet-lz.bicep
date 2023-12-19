param name string
param location string

resource vnet 'Microsoft.Network/virtualNetworks@2023-06-01' = {
  name: name
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.1.0.0/16'
      ]
    }
    subnets: [
      {
        name: 'aks'
        properties: {
          addressPrefix: '10.1.0.0/20'
          networkSecurityGroup: {
            id: nsgaks.id
          }
        }
      }
      {
        name: 'iaas'
        properties: {
          addressPrefix: '10.1.16.0/24'
          networkSecurityGroup: {
            id: nsgiaas.id
          }
        }
      }
    ]
  }
}

resource nsgaks 'Microsoft.Network/networkSecurityGroups@2023-06-01' = {
  name: 'nsg-aks'
  location: location
  properties:{
    securityRules:[
      {
        name: 'allow-http'
        properties:{
          access: 'Allow'
          direction: 'Inbound'
          priority: 500
          protocol: 'Tcp'
          sourcePortRange: '*'
          sourceAddressPrefix: '*'
          destinationPortRange: '80'
          destinationAddressPrefix: '*'
        }
      }
    ]
  }
}

resource nsgiaas 'Microsoft.Network/networkSecurityGroups@2023-06-01' = {
  name: 'nsg-iaas'
  location: location
  properties:{
    securityRules:[
      {
        name: 'allow-ssh'
        properties:{
          access: 'Allow'
          direction: 'Inbound'
          priority: 500
          protocol: 'Tcp'
          sourcePortRange: '*'
          sourceAddressPrefix: '*'
          destinationPortRange: '22'
          destinationAddressPrefix: '*'
        }
      }
    ]
  }
}

output subnetid string = vnet.properties.subnets[0].id
