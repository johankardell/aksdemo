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

param sysVMSize string = 'Standard_B2ms'
param appsVMSize string = 'Standard_B4ms'
param linuxAdminUsername string
param sshRSAPublicKey string
param dnsPrefix string
param logAnalyticsWorkspaceId string
param aksidname string
param subnetid string
param privateDnsZoneId string

var k8sVersion = '1.31'
var nodeVersion = '1.31'

var aksadmingroup = '1edf6441-ba72-4c12-af38-a71b56a37116'

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
    nodeResourceGroupProfile: {
      restrictionLevel: 'ReadOnly'
    }
    kubernetesVersion: k8sVersion
    nodeResourceGroup: 'rg-${clusterName}-infra'
    // disableLocalAccounts: true // breaks Flux
    networkProfile: {
      networkPlugin: 'azure'
      networkPluginMode: 'overlay'
      outboundType: 'none' // preview functionality
      // outboundType: 'userDefinedRouting' // ingress egress via AZFW
      // outboundType: 'managedNATGateway' // doesn't seem to work. deployment fails. need to investigate.
      // outboundType: 'loadBalancer' // ingress via LB, egress via AZFW 
    }
    apiServerAccessProfile: {
      enablePrivateCluster: true
      privateDNSZone: privateDnsZoneId
      enablePrivateClusterPublicFQDN: false
      //disableRunCommand:true
    }
    aadProfile: {
      managed: true
      enableAzureRBAC: true
      tenantID: subscription().tenantId
      adminGroupObjectIDs: [
        aksadmingroup
      ]
    }
    identityProfile: {
      kubeletidentity: {
        resourceId: aksid.id
        clientId: aksid.properties.clientId
        objectId: aksid.properties.principalId
      }
    }
    agentPoolProfiles: [
      {
        name: 'system'
        osDiskSizeGB: osDiskSizeGB
        count: agentCount
        vmSize: sysVMSize
        osType: 'Linux'
        osSKU: 'Ubuntu' // AzureLinux not supported for Outboundtype: none
        mode: 'System'
        enableAutoScaling: true
        orchestratorVersion: nodeVersion
        minCount: 1
        maxCount: 3
        maxPods: 50
        vnetSubnetID: subnetid
        // availabilityZones: [
        //   '1'
        //   '2'
        //   '3'
        // ]
        // osDiskType: 'Ephemeral' //not supported by selected vm type
      }
      {
        name: 'apps'
        osDiskSizeGB: osDiskSizeGB
        count: 1
        vmSize: appsVMSize
        osType: 'Linux'
        osSKU: 'Ubuntu'
        mode: 'User'
        enableAutoScaling: true
        orchestratorVersion: nodeVersion
        minCount: 0
        maxCount: 5
        maxPods: 50
        vnetSubnetID: subnetid
        // availabilityZones: [
        //   '1'
        //   '2'
        //   '3'
        // ]
      }
      // {
      //   name: 'win'
      //   osDiskSizeGB: osDiskSizeGB
      //   count: 1
      //   vmSize: agentVMSize
      //   osType: 'Windows'
      //   osSKU: 'Windows2022'
      //   mode: 'User'
      //   enableAutoScaling: true
      //   orchestratorVersion: nodeVersion
      //   minCount: 1
      //   maxCount: 5
      //   maxPods: 50
      //   vnetSubnetID: subnetid
      // }
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

// https://samcogan.com/enable-aks-flux-extension-with-infrastructure-as-code/

// temporarily disable flux to make deployments faster
//
// resource flux 'Microsoft.KubernetesConfiguration/extensions@2023-05-01' = {
//   name: 'flux'
//   scope: aks
//   properties: {
//     extensionType: 'microsoft.flux'
//     scope: {
//       cluster: {
//         releaseNamespace: 'flux-system'
//       }
//     }
//     autoUpgradeMinorVersion: true
//   }
// }

// resource fluxConfig 'Microsoft.KubernetesConfiguration/fluxConfigurations@2023-05-01' = {
//   name: 'flux-demo'
//   scope: aks
//   dependsOn: [
//     flux
//   ]
//   properties: {
//     scope: 'cluster'
//     namespace: 'flux-demo'
//     sourceKind: 'GitRepository'
//     suspend: false
//     gitRepository: {
//       url: 'https://github.com/johankardell/flux-lab'
//       timeoutInSeconds: 600
//       syncIntervalInSeconds: 600
//       repositoryRef: {
//         branch: 'main'
//       }

//     }
//     kustomizations: {
//       infra: {
//         path: './infrastructure'
//         dependsOn: []
//         timeoutInSeconds: 600
//         syncIntervalInSeconds: 600
//         prune: true
//       }
//       apps: {
//         path: './apps'
//         dependsOn: [
//           'infra'
//         ]
//         timeoutInSeconds: 600
//         syncIntervalInSeconds: 600
//         prune: true
//       }
//     }
//   }
// }

// output controlPlaneFQDN string = aks.properties.fqdn
