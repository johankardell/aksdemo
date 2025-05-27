targetScope = 'subscription'

var rgName = 'rg-aksAGC-managed'
param location string = deployment().location
var laName = 'la-agc-managed'
var aksName = 'aks-agc-managed'
var aksidname = 'id-aks-managed'

param sshkey string
param managementIP string

resource rg 'Microsoft.Resources/resourceGroups@2024-07-01' = {
  name: rgName
  location: location
}

module aksid 'modules/id.bicep' = {
  name: aksidname
  scope: rg
  params: {
    aksidname: aksidname
    location: location
  }
}

module la 'modules/logAnalytics.bicep' = {
  name: laName
  scope: rg
  params: {
    laName: laName
    location: location
  }
}

module vnet 'modules/vnet.bicep' = {
  scope: rg
  name: 'vnet'
  params: {
    name: aksName
    location: location
  }
}

module aks 'modules/aks.bicep' = {
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
    managementIP: managementIP
    subnetid: vnet.outputs.akssubnetid
  }
}

module rbac 'modules/rbac.bicep' = {
  scope: rg
  name: 'rbac'
  params: {
    name: aksid.name
    principalId: aksid.outputs.principalid
    roleDefinitionId: '4d97b98b-1d4f-4787-a291-c67834d212e7'
  }
}
