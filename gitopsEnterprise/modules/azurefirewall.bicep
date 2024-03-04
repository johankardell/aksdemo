param firewallName string
param location string
param firewallSubnetId string
param firewallManagementSubnetId string

resource publicIP 'Microsoft.Network/publicIPAddresses@2023-09-01' = {
  name: '${firewallName}-pip'
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
    publicIPAddressVersion: 'IPv4'
  }
}

resource publicIPManagement 'Microsoft.Network/publicIPAddresses@2023-09-01' = {
  name: '${firewallName}-mgmt-pip'
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
    publicIPAddressVersion: 'IPv4'
  }
}

resource firewallPolicy 'Microsoft.Network/firewallPolicies@2020-11-01' = {
  name: '${firewallName}-policy'
  location: location
  properties: {
    threatIntelMode: 'Alert'
  }
}

resource firewall 'Microsoft.Network/azureFirewalls@2023-09-01' = {
  name: firewallName
  location: location
  properties: {
    sku: {
      name: 'AZFW_VNet'
      tier: 'Basic'
    }
    threatIntelMode: 'Alert'
    managementIpConfiguration: {
      name: 'managementIpConfig'
      properties: {
        subnet: {
          id: firewallManagementSubnetId
        }
        publicIPAddress: {
          id: publicIPManagement.id
        }
      }
    }
    ipConfigurations: [
      {
        name: 'ipconfig'
        properties: {
          publicIPAddress: {
            id: publicIP.id
          }
          subnet: {
            id: firewallSubnetId
          }
        }
      }
    ]
  }
}
