targetScope = 'subscription'

param location string = 'swedencentral'

var rgName = 'rg-aks-gitopsEnterprise-demo'
var laName = 'la-gitopsEnterprise-demo'
var aksName = 'aks-gitopsEnterprise-demo'
var vnetLzName = 'vnet-lz-gitopsEnterprise-demo'
var vnetHubName = 'vnet-hub-gitopsEnterprise-demo'
var bastionName = 'bastion-gitopsEnterprise-demo'
var miname = 'id-gitopsEnterprise-demo'
var azfwname = 'azfw-gitopsEnterprise-demo'

param sshkey string

resource rg 'Microsoft.Resources/resourceGroups@2023-07-01' = {
  name: rgName
  location: location
}

module la 'modules/logAnalytics.bicep' = {
  name: laName
  scope: rg
  params: {
    laName: laName
    location: location
  }
}

module vnethub 'modules/vnet-hub.bicep' = {
  scope: rg
  name: vnetHubName
  params: {
    location: location
    name: vnetHubName
  }
}

module vnetlz 'modules/vnet-lz.bicep' = {
  scope: rg
  name: vnetLzName
  params: {
    location: location
    name: vnetLzName
  }
}

// module bastion 'modules/bastion.bicep' = {
//   name: bastionName
//   scope: rg
//   params: {
//     location: location
//     name: bastionName
//     subnetid: vnethub.outputs.bastionsubnetid
//   }
// }

module vnetpeering 'modules/vnet-peering.bicep' = {
  scope: rg
  dependsOn: [
    vnethub
    vnetlz
  ]
  name: 'vnet-peering'
  params: {
    hubname: vnetHubName
    lzname: vnetLzName
  }
}

module mi 'modules/identity.bicep' = {
  scope: rg
  name: miname
  params: {
    miname: miname
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
    subnetid: vnetlz.outputs.subnetid
  }
}

module azfw 'modules/azurefirewall.bicep' = {
  scope: rg
  name: azfwname
  params: {
    firewallName: azfwname 
    firewallSubnetId: vnethub.outputs.firewallsubnetid
    firewallManagementSubnetId: vnethub.outputs.firewallmanagementsubnetid
    location:location
  }
}
