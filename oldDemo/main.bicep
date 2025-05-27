targetScope = 'subscription'

var rgName = 'test'
param location string = 'swedencentral'
param sshkey string

var aksName = 'aks-test'

resource rg 'Microsoft.Resources/resourceGroups@2024-07-01' = {
  name: rgName
  location: location
}

module aks 'modules/aks.bicep' = {
  scope: resourceGroup(rg.name)
  name: aksName
  params: {
    location: location
    linuxAdminUsername: 'demo' 
    sshRSAPublicKey: sshkey
    clusterName: aksName
    dnsPrefix: aksName
  }
}
