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

@description('Configure all linux machines with the SSH RSA public key string. Your key should include three parts, for example \'ssh-rsa AAAAB...snip...UcyupgH azureuser@linuxvm\'')
param sshRSAPublicKey string

param dnsPrefix string

param logAnalyticsWorkspaceId string

var k8sVersion = '1.27.3'

resource aks 'Microsoft.ContainerService/managedClusters@2023-07-02-preview' = {
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
      networkPluginMode: 'overlay'
      podCidr: '192.168.0.0/16'
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
        vmSize: agentVMSize
        osType: 'Linux'
        mode: 'System'
        enableAutoScaling: true
        orchestratorVersion: k8sVersion
        minCount: 1
        maxCount: 100
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
        count: agentCount
        vmSize: agentVMSize
        osType: 'Linux'
        mode: 'User'
        enableAutoScaling: true
        orchestratorVersion: k8sVersion
        minCount: 1
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

// https://samcogan.com/enable-aks-flux-extension-with-infrastructure-as-code/

resource flux 'Microsoft.KubernetesConfiguration/extensions@2023-05-01' = {
  name: 'flux'
  scope: aks
  properties: {
    extensionType: 'microsoft.flux'
    scope: {
      cluster: {
        releaseNamespace: 'flux-system'
      }
    }
    autoUpgradeMinorVersion: true
  }
}

// resource fluxConfig 'Microsoft.KubernetesConfiguration/fluxConfigurations@2023-05-01' = {
//   name: 'gitops-demo'
//   scope: aks
//   dependsOn: [
//     flux
//   ]
//   properties: {
//     scope: 'cluster'
//     namespace: 'gitops-demo'
//     sourceKind: 'GitRepository'
//     suspend: false
//     gitRepository: {
//       url: 'https://github.com/fluxcd/flux2-kustomize-helm-example'
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
//         path: './apps/staging'
//         dependsOn: [
//           'infra'
//         ]
//         timeoutInSeconds: 600
//         syncIntervalInSeconds: 600
//         retryIntervalInSeconds: 600
//         prune: true
//       }
//     }
//   }
// }


resource fluxConfig 'Microsoft.KubernetesConfiguration/fluxConfigurations@2023-05-01' = {
  name: 'flux-demo'
  scope: aks
  dependsOn: [
    flux
  ]
  properties: {
    scope: 'cluster'
    namespace: 'flux-demo'
    sourceKind: 'GitRepository'
    suspend: false
    gitRepository: {
      url: 'https://github.com/johankardell/flux-lab'
      timeoutInSeconds: 600
      syncIntervalInSeconds: 600
      repositoryRef: {
        branch: 'main'
      }

    }
    kustomizations: {
      infra: {
        path: './infrastructure'
        dependsOn: []
        timeoutInSeconds: 600
        syncIntervalInSeconds: 600
        prune: true
      }
      apps: {
        path: './apps'
        dependsOn: [
          'infra'
        ]
        timeoutInSeconds: 600
        syncIntervalInSeconds: 600
        prune: true
      }
    }
  }
}


output controlPlaneFQDN string = aks.properties.fqdn
