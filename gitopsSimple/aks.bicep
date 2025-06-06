param clusterName string
param location string = resourceGroup().location

@description('Disk size (in GB) to provision for each of the agent pool nodes. This value ranges from 0 to 1023. Specifying 0 will apply the default disk size for that agentVMSize.')
@minValue(0)
@maxValue(1023)
param osDiskSizeGB int = 0

@description('The number of nodes for the cluster.')
@minValue(1)
@maxValue(50)
param agentCount int = 3

@description('The size of the Virtual Machine.')
param agentVMSize string = 'Standard_D4as_v5'

@description('User name for the Linux Virtual Machines.')
param linuxAdminUsername string

param sshRSAPublicKey string

param dnsPrefix string

param logAnalyticsWorkspaceId string

var k8sVersion = '1.28.3'
var nodeVersion = '1.28.3'

resource aks 'Microsoft.ContainerService/managedClusters@2024-09-01' = {
  name: clusterName
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  sku: {
    name: 'Base'
    tier: 'Standard'
  }
  properties: {
    dnsPrefix: dnsPrefix
    kubernetesVersion: k8sVersion
    nodeResourceGroup: 'rg-${clusterName}-infra'
    // disableLocalAccounts: true // breaks Flux
    networkProfile: {
      networkPlugin: 'azure'
      networkPluginMode: 'dynamic'
      podCidr: '192.168.0.0/16'
    }
    aadProfile: {
      managed: true
      enableAzureRBAC: true
      adminGroupObjectIDs: [
        '1edf6441-ba72-4c12-af38-a71b56a37116' // aksadmins
      ]
    }
    agentPoolProfiles: [
      {
        name: 'system'
        osDiskSizeGB: osDiskSizeGB
        count: agentCount
        vmSize: agentVMSize
        osType: 'Linux'
        mode: 'System'
        enableAutoScaling: true
        orchestratorVersion: nodeVersion
        minCount: 1
        maxCount: 100
      }
      {
        name: 'apps'
        osDiskSizeGB: osDiskSizeGB
        count: agentCount
        vmSize: agentVMSize
        osType: 'Linux'
        mode: 'User'
        enableAutoScaling: true
        orchestratorVersion: nodeVersion
        minCount: 0
        maxCount: 100
      }
    ]
    linuxProfile: {
      adminUsername: linuxAdminUsername
      ssh: {
        publicKeys: [
          {
            keyData: sshRSAPublicKey
          }
        ]
      }
    }
    addonProfiles: {
      omsagent: {
        enabled: true
        config: {
          logAnalyticsWorkspaceResourceID: logAnalyticsWorkspaceId
        }
      }
    }
  }
}

output controlPlaneFQDN string = aks.properties.fqdn
