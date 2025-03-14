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
        name: 'agc'
        properties: {
          addressPrefix: '10.1.16.0/24'
          delegations: [
            {
              name: 'Microsoft.ServiceNetworking/trafficControllers'
              properties: {
                serviceName: 'Microsoft.ServiceNetworking/trafficControllers'
              }
            }
          ]
        }
      }
    ]
  }
}

resource nsgaks 'Microsoft.Network/networkSecurityGroups@2023-06-01' = {
  name: 'nsg-aks'
  location: location
  properties: {
    securityRules: [
      {
        name: 'allow-http'
        properties: {
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


output akssubnetid string = vnet.properties.subnets[0].id
output vnetid string = vnet.id
