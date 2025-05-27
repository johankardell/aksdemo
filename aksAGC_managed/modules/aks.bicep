param clusterName string
param location string = resourceGroup().location

@description('Disk size (in GB) to provision for each of the agent pool nodes. This value ranges from 0 to 1023. Specifying 0 will apply the default disk size for that agentVMSize.')
@minValue(0)
@maxValue(1023)
param osDiskSizeGB int = 0

param agentCount int = 3

param sysVMSize string = 'Standard_B2ms'
param appsVMSize string = 'Standard_B4ms'

@description('User name for the Linux Virtual Machines.')
param linuxAdminUsername string

param sshRSAPublicKey string

param dnsPrefix string

param logAnalyticsWorkspaceId string

param aksidname string
param managementIP string
param subnetid string

var k8sVersion = '1.31'
var nodeVersion = '1.31'

resource aksid 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' existing = {
  name: aksidname
}

resource aks 'Microsoft.ContainerService/managedClusters@2024-09-01' = {
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
        '1edf6441-ba72-4c12-af38-a71b56a37116' // aksadmins
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
        vnetSubnetID: subnetid
        nodeTaints: [
          'CriticalAddonsOnly=true:NoSchedule'
        ]
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
        vnetSubnetID: subnetid
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
    securityProfile: {
      imageCleaner: {
        enabled: true
        intervalHours: 168
      }
      workloadIdentity: {
        enabled: true
      }
    }
    oidcIssuerProfile: {
      enabled: true
    }
    workloadAutoScalerProfile: {
      keda: {
        enabled: true
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
