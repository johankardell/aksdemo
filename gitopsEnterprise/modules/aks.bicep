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

@description('User name for the Linux Virtual Machines.')
param linuxAdminUsername string

@description('Configure all linux machines with the SSH RSA public key string. Your key should include three parts, for example \'ssh-rsa AAAAB...snip...UcyupgH azureuser@linuxvm\'')
param sshRSAPublicKey string

param dnsPrefix string

param logAnalyticsWorkspaceId string

param aksidname string
param managementIP string

param subnetid string

var k8sVersion = '1.28.5'
var nodeVersion = '1.28.3'

resource aksid 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: aksidname
  location: location
}

resource aks 'Microsoft.ContainerService/managedClusters@2023-10-02-preview' = {
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
    // disableLocalAccounts: true // breaks Flux
    // should be enabled, but I change IP too often
    // apiServerAccessProfile: {
    //   authorizedIPRanges: [
    //     managementIP
    //   ]
    // }
    networkProfile: {
      networkPlugin: 'azure'
      networkPluginMode: 'overlay'
      outboundType: 'loadBalancer'
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
        osSKU: 'AzureLinux'
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

output controlPlaneFQDN string = aks.properties.fqdn
