targetScope = 'subscription'

param location string = 'swedencentral'

var rgName = 'rg-aks-gitopsEnterprise-demo'
var laName = 'la-gitopsEnterprise-demo'
var vnetLzName = 'vnet-lz-gitopsEnterprise-demo'
var vnetHubName = 'vnet-hub-gitopsEnterprise-demo'
var bastionName = 'bastion-gitopsEnterprise-demo'
var miname = 'id-gitopsEnterprise-demo'
var azfwname = 'azfw-gitopsEnterprise-demo'
var appgwname = 'appgw-gitopsEnterprise-demo'
var vmname = 'vm-ubuntu'
var privatednszonename = 'akszone.private.swedencentral.azmk8s.io'

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

module bastion 'modules/bastion.bicep' = {
  name: bastionName
  scope: rg
  params: {
    location: location
    name: bastionName
    subnetid: vnethub.outputs.bastionsubnetid
  }
}

module vm 'modules/vm.bicep' = {
  name: vmname
  scope: rg
  params: {
    location: location
    name: vmname
    subnetId: vnetlz.outputs.iaassubnetid
    publicKey: sshkey
    adminUsername: 'azureuser'
  }
}

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

module aksmi 'modules/aksmi.bicep' = {
  scope: rg
  name: miname
  params: {
    aksidname: miname
    location: location
  }
}

module privatednszone 'modules/privatednszone.bicep' = {
  scope: rg
  name: 'privatednszone'
  params: {
    aksidname: miname
    vnetId: vnetlz.outputs.vnetid
    privateDnsZoneName: privatednszonename
    vnetname: vnetLzName
  }
  dependsOn: [
    aksmi
  ]
}

module azfw 'modules/azurefirewall.bicep' = {
  scope: rg
  name: azfwname
  params: {
    firewallName: azfwname 
    firewallSubnetId: vnethub.outputs.firewallsubnetid
    firewallManagementSubnetId: vnethub.outputs.firewallmanagementsubnetid
    location:location
    workspaceid: la.outputs.id
  }
}

// Switch to Appgw for containers?
// module appgw 'modules/appgw.bicep' = {
//   scope: rg
//   name: appgwname
//   params: {
//     appurl: '10.1.15.250'
//     location: location
//     name: appgwname
//     subnetId: vnetlz.outputs.appgwsubnetid
//   }
// }
