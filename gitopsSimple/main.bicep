targetScope = 'subscription'

var rgName = 'rg-aks-gitopsSimple-demo'
param location string = 'swedencentral'
var laName = 'la-gitopsSimple-demo'
var aksName = 'aks-gitopsSimple-demo'

param sshkey string

resource rg 'Microsoft.Resources/resourceGroups@2024-07-01' = {
  name: rgName
  location: location
}

module la 'logAnalytics.bicep' = {
  name: laName
  scope: rg
  params: {
    laName: laName
    location: location
  }
}

module aks 'aks.bicep' = {
  scope: rg
  name: aksName
  params: {
    location: location
    clusterName: aksName 
    dnsPrefix: aksName
    linuxAdminUsername: 'aksuser'
    sshRSAPublicKey: sshkey
    logAnalyticsWorkspaceId: la.outputs.id
  }
}
