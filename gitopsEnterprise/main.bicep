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
var appgwname = 'appgw-gitopsEnterprise-demo'
var vmname = 'vm-ubuntu'

param adminIp string

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
    subnetid: vnetlz.outputs.akssubnetid
    aksidname: miname
    adminIp: adminIp
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
    workspaceid: la.outputs.id
  }
}

module appgw 'modules/appgw.bicep' = {
  scope: rg
  name: appgwname
  params: {
    appurl: '10.1.15.250'
    location: location
    name: appgwname
    subnetId: vnetlz.outputs.appgwsubnetid
  }
}
