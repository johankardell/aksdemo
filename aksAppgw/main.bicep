// Main Bicep template for AKS with Application Gateway
// This template creates a VNet with separate subnets for AKS and App Gateway,
// deploys an AKS cluster, Application Gateway, and configures NGINX backend

targetScope = 'resourceGroup'

@description('The location where all resources will be deployed')
param location string = resourceGroup().location

@description('Environment name (e.g., dev, test, prod)')
param environmentName string = 'dev'

@description('Base name for all resources')
param baseName string = 'aksappgw'

@description('Kubernetes version for AKS cluster')
param kubernetesVersion string = '1.31'

@description('VM size for AKS system node pool')
param systemNodeVmSize string = 'Standard_B2ms'

@description('VM size for AKS user node pool')
param userNodeVmSize string = 'Standard_B4ms'

@description('Number of nodes in the system node pool')
@minValue(1)
@maxValue(10)
param systemNodeCount int = 2

@description('Number of nodes in the user node pool')
@minValue(1)
@maxValue(50)
param userNodeCount int = 3

@description('Admin username for SSH access to nodes')
param adminUsername string = 'azureuser'

@description('SSH public key for node access')
@secure()
param sshPublicKey string

@description('WAF policy mode (Detection or Prevention)')
@allowed(['Detection', 'Prevention'])
param wafMode string = 'Prevention'

@description('WAF policy state (Enabled or Disabled)')
@allowed(['Enabled', 'Disabled'])
param wafState string = 'Enabled'

@description('Service CIDR for Kubernetes services')
param serviceCidr string = '172.16.0.0/16'

@description('Pod CIDR for overlay networking')
param podCidr string = '192.168.0.0/16'

@description('Maximum pods per node (overlay mode supports up to 250)')
@minValue(30)
@maxValue(250)
param maxPods int = 250

// Variables for resource naming
var resourceNames = {
  vnet: '${baseName}-vnet-${environmentName}'
  aks: '${baseName}-aks-${environmentName}'
  appGateway: '${baseName}-appgw-${environmentName}'
  logAnalytics: '${baseName}-logs-${environmentName}'
  managedIdentity: '${baseName}-identity-${environmentName}'
  publicIp: '${baseName}-pip-${environmentName}'
}

// Deploy Log Analytics workspace for monitoring
module logAnalytics 'modules/logAnalytics.bicep' = {
  name: 'logAnalytics-deployment'
  params: {
    name: resourceNames.logAnalytics
    location: location
    environmentName: environmentName
  }
}

// Deploy managed identity for AKS
module managedIdentity 'modules/managedIdentity.bicep' = {
  name: 'managedIdentity-deployment'
  params: {
    name: resourceNames.managedIdentity
    location: location
    environmentName: environmentName
  }
}

// Deploy VNet with subnets for AKS and Application Gateway
module vnet 'modules/vnet.bicep' = {
  name: 'vnet-deployment'
  params: {
    name: resourceNames.vnet
    location: location
    environmentName: environmentName
  }
}

// Deploy AKS cluster
module aks 'modules/aks.bicep' = {
  name: 'aks-deployment'
  params: {
    name: resourceNames.aks
    location: location
    environmentName: environmentName
    kubernetesVersion: kubernetesVersion
    systemNodeVmSize: systemNodeVmSize
    userNodeVmSize: userNodeVmSize
    systemNodeCount: systemNodeCount
    userNodeCount: userNodeCount
    adminUsername: adminUsername
    sshPublicKey: sshPublicKey
    subnetId: vnet.outputs.aksSubnetId
    logAnalyticsWorkspaceId: logAnalytics.outputs.workspaceId
    managedIdentityId: managedIdentity.outputs.identityId
    serviceCidr: serviceCidr
    podCidr: podCidr
    maxPods: maxPods
  }
}

// Deploy Application Gateway
module appGateway 'modules/appGateway.bicep' = {
  name: 'appGateway-deployment'
  params: {
    name: resourceNames.appGateway
    publicIpName: resourceNames.publicIp
    location: location
    environmentName: environmentName
    subnetId: vnet.outputs.appGatewaySubnetId
    wafMode: wafMode
    wafState: wafState
  }
}

// Outputs for reference
output vnetId string = vnet.outputs.vnetId
output aksClusterName string = aks.outputs.clusterName
output appGatewayName string = appGateway.outputs.appGatewayName
output appGatewayPublicIp string = appGateway.outputs.publicIpAddress
output managedIdentityClientId string = managedIdentity.outputs.clientId

// Output the kubectl command to connect to the cluster
output aksGetCredentialsCommand string = 'az aks get-credentials --resource-group ${resourceGroup().name} --name ${aks.outputs.clusterName}'
