targetScope = 'subscription'

var rgName = 'rg-aks-containerinsights-demo'
var location = 'swedencentral'
var laName = 'la-containerinsights-demo'
var aksName = 'aks-containerinsights-demo'

param sshkey string

resource rg 'Microsoft.Resources/resourceGroups@2023-07-01' = {
  name: rgName
  location: location
}

module la 'logAnalytics.bicep' = {
  name: laName
  scope: resourceGroup(rgName)
  params: {
    laName: laName
    location: location
  }
}

module aks 'aks.bicep' = {
  scope: resourceGroup(rgName)
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
