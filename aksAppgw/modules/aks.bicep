// AKS cluster module
// Creates an AKS cluster with system and user node pools

@description('Name of the AKS cluster')
param name string

@description('Location for the AKS cluster')
param location string = resourceGroup().location

@description('Environment name for tagging')
param environmentName string

@description('Kubernetes version')
param kubernetesVersion string

@description('VM size for system nodes')
param systemNodeVmSize string

@description('VM size for user nodes')
param userNodeVmSize string

@description('Number of system nodes')
@minValue(1)
@maxValue(10)
param systemNodeCount int

@description('Number of user nodes')
@minValue(1)
@maxValue(50)
param userNodeCount int

@description('Admin username for SSH')
param adminUsername string

@description('SSH public key')
@secure()
param sshPublicKey string

@description('Subnet ID for AKS nodes')
param subnetId string

@description('Log Analytics workspace ID')
param logAnalyticsWorkspaceId string

@description('Managed identity ID')
param managedIdentityId string

@description('DNS prefix for the cluster')
param dnsPrefix string = name

// AKS cluster
resource aksCluster 'Microsoft.ContainerService/managedClusters@2024-09-01' = {
  name: name
  location: location
  tags: {
    Environment: environmentName
    Purpose: 'AKS cluster with Application Gateway integration'
  }
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${managedIdentityId}': {}
    }
  }
  sku: {
    name: 'Base'
    tier: 'Standard'
  }
  properties: {
    dnsPrefix: dnsPrefix
    kubernetesVersion: kubernetesVersion
    enableRBAC: true
    networkProfile: {
      networkPlugin: 'azure'
      networkPolicy: 'azure'
      serviceCidr: '172.16.0.0/16'
      dnsServiceIP: '172.16.0.10'
      loadBalancerSku: 'Standard'
    }
    agentPoolProfiles: [
      {
        name: 'system'
        count: systemNodeCount
        vmSize: systemNodeVmSize
        osDiskSizeGB: 128
        osType: 'Linux'
        mode: 'System'
        type: 'VirtualMachineScaleSets'
        vnetSubnetID: subnetId
        maxPods: 30
        enableAutoScaling: true
        minCount: 1
        maxCount: 5
        nodeLabels: {
          'node-type': 'system'
        }
        nodeTaints: [
          'CriticalAddonsOnly=true:NoSchedule'
        ]
      }
    ]
    linuxProfile: {
      adminUsername: adminUsername
      ssh: {
        publicKeys: [
          {
            keyData: sshPublicKey
          }
        ]
      }
    }
    addonProfiles: {
      omsAgent: {
        enabled: true
        config: {
          logAnalyticsWorkspaceResourceID: logAnalyticsWorkspaceId
        }
      }
      azureKeyvaultSecretsProvider: {
        enabled: true
        config: {
          enableSecretRotation: 'true'
        }
      }
      ingressApplicationGateway: {
        enabled: false // We'll configure this manually for better control
      }
    }
    autoScalerProfile: {
      'scale-down-delay-after-add': '10m'
      'scale-down-unneeded-time': '10m'
      'scale-down-utilization-threshold': '0.5'
    }
    securityProfile: {
      workloadIdentity: {
        enabled: true
      }
    }
    oidcIssuerProfile: {
      enabled: true
    }
  }
}

// User node pool for application workloads
resource userNodePool 'Microsoft.ContainerService/managedClusters/agentPools@2024-09-01' = {
  parent: aksCluster
  name: 'user'
  properties: {
    count: userNodeCount
    vmSize: userNodeVmSize
    osDiskSizeGB: 128
    osType: 'Linux'
    mode: 'User'
    type: 'VirtualMachineScaleSets'
    vnetSubnetID: subnetId
    maxPods: 30
    enableAutoScaling: true
    minCount: 1
    maxCount: 10
    nodeLabels: {
      'node-type': 'user'
    }
  }
}

// Outputs
output clusterName string = aksCluster.name
output clusterId string = aksCluster.id
output fqdn string = aksCluster.properties.fqdn
output kubeletIdentityObjectId string = aksCluster.properties.identityProfile.kubeletidentity.objectId
output kubeletIdentityClientId string = aksCluster.properties.identityProfile.kubeletidentity.clientId
output oidcIssuerUrl string = aksCluster.properties.oidcIssuerProfile.issuerURL
