param name string
param location string

resource vnet 'Microsoft.Network/virtualNetworks@2024-05-01' = {
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
          defaultOutboundAccess: false
          networkSecurityGroup: {
            id: nsgaks.id
          }
          routeTable: {
            id: routetableAKS.id
          }
        }
      }
      {
        name: 'iaas'
        properties: {
          addressPrefix: '10.1.16.0/24'
          defaultOutboundAccess: false
          networkSecurityGroup: {
            id: nsgiaas.id
          }
          routeTable: {
            id: routetableIaaS.id
          }
        }
      }
      {
        name: 'appgw'
        properties: {
          addressPrefix: '10.1.17.0/24'
          defaultOutboundAccess: false
          networkSecurityGroup: {
            id: nsgappgw.id
          }
          routeTable: {
            id: routetableAppgw.id
          }
        }
      }
    ]
  }
}

resource nsgaks 'Microsoft.Network/networkSecurityGroups@2024-05-01' = {
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

resource nsgiaas 'Microsoft.Network/networkSecurityGroups@2024-05-01' = {
  name: 'nsg-iaas'
  location: location
  properties: {
    securityRules: [
      {
        name: 'allow-ssh'
        properties: {
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

resource nsgappgw 'Microsoft.Network/networkSecurityGroups@2024-05-01' = {
  name: 'nsg-appgw'
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
      {
        name: 'allow-appgw-required'
        properties: {
          access: 'Allow'
          direction: 'Inbound'
          priority: 600
          protocol: 'Tcp'
          sourcePortRange: '*'
          sourceAddressPrefix: '*'
          destinationPortRange: '65200-65535'
          destinationAddressPrefix: '*'
        }
      }
    ]
  }
}

resource routetableAKS 'Microsoft.Network/routeTables@2024-05-01' = {
  name: 'rt-aks'
  location: location
  properties: {
    routes: [
      {
        name: 'default'
        properties: {
          addressPrefix: '0.0.0.0/0'
          nextHopType: 'VirtualAppliance'
          nextHopIpAddress: '10.0.0.4'
        }
      }
    ]
  }
}

resource routetableIaaS 'Microsoft.Network/routeTables@2024-05-01' = {
  name: 'rt-iaas'
  location: location
  properties: {
    routes: [
      {
        name: 'default'
        properties: {
          addressPrefix: '0.0.0.0/0'
          nextHopType: 'VirtualAppliance'
          nextHopIpAddress: '10.0.0.4'
        }
      }
    ]
  }
}

resource routetableAppgw 'Microsoft.Network/routeTables@2024-05-01' = {
  name: 'rt-appgw'
  location: location
  properties: {
    routes: []
  }
}

output akssubnetid string = vnet.properties.subnets[0].id
output iaassubnetid string = vnet.properties.subnets[1].id
output appgwsubnetid string = vnet.properties.subnets[2].id
output vnetid string = vnet.id
