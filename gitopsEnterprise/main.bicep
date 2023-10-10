targetScope = 'subscription'

var rgName = 'rg-aks-gitopsEnterprise-demo'
param location string = 'swedencentral'
var laName = 'la-gitopsEnterprise-demo'
var aksName = 'aks-gitopsEnterprise-demo'

param sshkey string

resource rg 'Microsoft.Resources/resourceGroups@2023-07-01' = {
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
