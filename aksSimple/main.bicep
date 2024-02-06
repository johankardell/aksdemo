targetScope = 'subscription'

var rgName = 'rg-aks-simple-demo'
param location string = 'swedencentral'
var laName = 'la-simple-demo'
var aksName = 'aks-simple-demo'
var acrName = 'jkacrsimpledemo'
var aksidname = 'id-aks'

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
    aksidname: aksidname
  }
}

module acr 'acr.bicep' = {
  scope: rg
  name: acrName
  params: {
    acrName: acrName
    location: location
    aksid: aks.outputs.akskubeletid
  }
  dependsOn: [
    aks
  ]
}
