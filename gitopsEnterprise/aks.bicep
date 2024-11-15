param location string = 'swedencentral'

var laName = 'la-gitopsEnterprise-demo'
var aksName = 'aks-gitopsEnterprise-demo'
var vnetLzName = 'vnet-lz-gitopsEnterprise-demo'
var miname = 'id-gitopsEnterprise-demo'
var privatednszonename = 'akszone.private.swedencentral.azmk8s.io'

param sshkey string

resource privatednszone 'Microsoft.Network/privateDnsZones@2024-06-01' existing = {
  name: privatednszonename
}

resource vnetlz 'Microsoft.Network/virtualNetworks@2024-03-01' existing = {
  name: vnetLzName
}

resource la 'Microsoft.OperationalInsights/workspaces@2022-10-01' existing = {
  name: laName
}

module aks 'modules/aks.bicep' = {
  name: aksName
  params: {
    location: location
    clusterName: aksName 
    dnsPrefix: aksName
    linuxAdminUsername: 'aksuser'
    sshRSAPublicKey: sshkey
    logAnalyticsWorkspaceId: la.id
    subnetid: vnetlz.properties.subnets[0].id
    aksidname: miname
    privateDnsZoneId: privatednszone.id
  }
}
