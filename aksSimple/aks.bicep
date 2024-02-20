param clusterName string
param location string = resourceGroup().location

@description('Disk size (in GB) to provision for each of the agent pool nodes. This value ranges from 0 to 1023. Specifying 0 will apply the default disk size for that agentVMSize.')
@minValue(0)
@maxValue(1023)
param osDiskSizeGB int = 0

param agentCount int = 3

param sysVMSize string = 'Standard_B2ms'

param appsVMSize string = 'Standard_D4as_v5'

@description('User name for the Linux Virtual Machines.')
param linuxAdminUsername string

param sshRSAPublicKey string

param dnsPrefix string

param logAnalyticsWorkspaceId string

param aksidname string
param managementIP string

var k8sVersion = '1.28.3'
var nodeVersion = '1.28.3'

resource aksid 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: aksidname
  location: location
}

resource aks 'Microsoft.ContainerService/managedClusters@2023-07-02-preview' = {
  name: clusterName
  location: location
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${aksid.id}': {}
    }
  }
  sku: {
    name: 'Base'
    tier: 'Standard'
  }
  properties: {
    dnsPrefix: dnsPrefix
    kubernetesVersion: k8sVersion
    nodeResourceGroup: 'rg-${clusterName}-infra'
    networkProfile: {
      networkPlugin: 'azure'
      networkPluginMode: 'dynamic'
      podCidr: '192.168.0.0/16'
    }
    disableLocalAccounts: true
    apiServerAccessProfile: {
      authorizedIPRanges: [
        managementIP
      ]
    }
    aadProfile: {
      managed: true
      enableAzureRBAC: true
      adminGroupObjectIDs: [
        'a9afb2ca-1ae6-46b2-b117-446156c81741' // aksadmins
      ]
    }
    agentPoolProfiles: [
      {
        name: 'system'
        osDiskSizeGB: osDiskSizeGB
        count: agentCount
        vmSize: sysVMSize
        osType: 'Linux'
        osSKU: 'AzureLinux'
        mode: 'System'
        enableAutoScaling: true
        orchestratorVersion: nodeVersion
        minCount: 1
        maxCount: 5
      }
      {
        name: 'apps'
        osDiskSizeGB: osDiskSizeGB
        count: agentCount
        vmSize: appsVMSize
        osType: 'Linux'
        osSKU: 'AzureLinux'
        mode: 'User'
        enableAutoScaling: true
        orchestratorVersion: nodeVersion
        minCount: 0
        maxCount: 10
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
    autoUpgradeProfile: {
      upgradeChannel: 'patch'
      nodeOSUpgradeChannel: 'NodeImage'
    }
    storageProfile: {
      diskCSIDriver: {
        enabled: true
      }
      fileCSIDriver: {
        enabled: true
      }
      snapshotController: {
        enabled: true
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

output akskubeletid string = aks.properties.identityProfile.kubeletidentity.objectId
