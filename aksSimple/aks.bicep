param clusterName string
param location string = resourceGroup().location

@description('Disk size (in GB) to provision for each of the agent pool nodes. This value ranges from 0 to 1023. Specifying 0 will apply the default disk size for that agentVMSize.')
@minValue(0)
@maxValue(1023)
param osDiskSizeGB int = 0

param agentCount int = 1

param sysVMSize string = 'Standard_B2s_v2'

@description('User name for the Linux Virtual Machines.')
param linuxAdminUsername string

param sshRSAPublicKey string

param dnsPrefix string

param logAnalyticsWorkspaceId string

param aksidname string
param managementIP string
param clusterAdminPrincipalId string

var k8sVersion = '1.36'
var aksRbacClusterAdminRoleDefinitionId = 'b1ff04bb-8a4e-4dc4-8eb5-8693973ce19b'
var aksClusterUserRoleDefinitionId = '4abbcc35-e782-43d8-92c5-2d3f1bd2253f'

resource aksid 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: aksidname
  location: location
}

resource aks 'Microsoft.ContainerService/managedClusters@2026-04-01' = {
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
      networkPluginMode: 'overlay'
      podCidr: '192.168.0.0/16'
      networkDataplane: 'cilium'
    }
    nodeProvisioningProfile: {
      mode: 'Auto'
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
        type: 'VirtualMachineScaleSets'
        osDiskSizeGB: osDiskSizeGB
        count: agentCount
        vmSize: sysVMSize
        osType: 'Linux'
        osSKU: 'AzureLinux3'
        mode: 'System'
        enableAutoScaling: false
        nodeTaints: [
          'CriticalAddonsOnly=true:NoSchedule'
        ]
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

resource clusterAdminRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(aks.id, clusterAdminPrincipalId, aksRbacClusterAdminRoleDefinitionId)
  scope: aks
  properties: {
    principalId: clusterAdminPrincipalId
    principalType: 'User'
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', aksRbacClusterAdminRoleDefinitionId)
  }
}

resource clusterUserRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(aks.id, clusterAdminPrincipalId, aksClusterUserRoleDefinitionId)
  scope: aks
  properties: {
    principalId: clusterAdminPrincipalId
    principalType: 'User'
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', aksClusterUserRoleDefinitionId)
  }
}

output akskubeletid string = aks.properties.identityProfile.kubeletidentity.objectId
