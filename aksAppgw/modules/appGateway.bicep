// Application Gateway module with AKS backend integration

@description('Application Gateway name')
param name string

@description('Location for all resources')
param location string = resourceGroup().location

@description('Environment name (e.g., dev, test, prod)')
param environmentName string

@description('Subnet ID for Application Gateway')
param subnetId string

@description('Public IP name for Application Gateway')
param publicIpName string = '${name}-pip'

@description('SKU for Application Gateway')
param skuName string = 'WAF_v2'

@description('SKU tier for Application Gateway')
param skuTier string = 'WAF_v2'

@description('Minimum capacity for autoscaling')
param minCapacity int = 1

@description('Maximum capacity for autoscaling')
param maxCapacity int = 10

@description('WAF policy mode (Detection or Prevention)')
param wafMode string = 'Prevention'

@description('WAF policy state (Enabled or Disabled)')
param wafState string = 'Enabled'

@description('WAF rule set type')
param wafRuleSetType string = 'OWASP'

@description('WAF rule set version')
param wafRuleSetVersion string = '3.2'

@description('Backend pool IP addresses (AKS internal load balancer)')
param backendPoolIps array = []

// Variables
var frontendPort = 80
var backendPort = 80
var cookieBasedAffinity = 'Disabled'

// Public IP for Application Gateway
resource publicIp 'Microsoft.Network/publicIPAddresses@2024-05-01' = {
  name: publicIpName
  location: location
  sku: {
    name: 'Standard'
    tier: 'Regional'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
    dnsSettings: {
      domainNameLabel: toLower('${name}-${environmentName}-${uniqueString(resourceGroup().id)}')
    }
  }
  tags: {
    Environment: environmentName
    Purpose: 'Application Gateway'
  }
}

// Application Gateway
resource applicationGateway 'Microsoft.Network/applicationGateways@2024-05-01' = {
  name: name
  location: location
  properties: {
    sku: {
      name: skuName
      tier: skuTier
    }
    gatewayIPConfigurations: [
      {
        name: 'appGatewayIpConfig'
        properties: {
          subnet: {
            id: subnetId
          }
        }
      }
    ]
    frontendIPConfigurations: [
      {
        name: 'appGatewayFrontendIP'
        properties: {
          publicIPAddress: {
            id: publicIp.id
          }
        }
      }
    ]
    frontendPorts: [
      {
        name: 'appGatewayFrontendPort'
        properties: {
          port: frontendPort
        }
      }
    ]
    backendAddressPools: [
      {
        name: 'appGatewayBackendPool'
        properties: {
          backendAddresses: [for ip in backendPoolIps: {
            ipAddress: ip
          }]
        }
      }
    ]
    backendHttpSettingsCollection: [
      {
        name: 'appGatewayBackendHttpSettings'
        properties: {
          port: backendPort
          protocol: 'Http'
          cookieBasedAffinity: cookieBasedAffinity
          pickHostNameFromBackendAddress: true
          requestTimeout: 30
          probe: {
            id: resourceId('Microsoft.Network/applicationGateways/probes', name, 'defaultProbe')
          }
        }
      }
    ]
    httpListeners: [
      {
        name: 'appGatewayHttpListener'
        properties: {
          frontendIPConfiguration: {
            id: resourceId('Microsoft.Network/applicationGateways/frontendIPConfigurations', name, 'appGatewayFrontendIP')
          }
          frontendPort: {
            id: resourceId('Microsoft.Network/applicationGateways/frontendPorts', name, 'appGatewayFrontendPort')
          }
          protocol: 'Http'
        }
      }
    ]
    requestRoutingRules: [
      {
        name: 'appGatewayRoutingRule'
        properties: {
          ruleType: 'Basic'
          priority: 1000
          httpListener: {
            id: resourceId('Microsoft.Network/applicationGateways/httpListeners', name, 'appGatewayHttpListener')
          }
          backendAddressPool: {
            id: resourceId('Microsoft.Network/applicationGateways/backendAddressPools', name, 'appGatewayBackendPool')
          }
          backendHttpSettings: {
            id: resourceId('Microsoft.Network/applicationGateways/backendHttpSettingsCollection', name, 'appGatewayBackendHttpSettings')
          }
        }
      }
    ]
    probes: [
      {
        name: 'defaultProbe'
        properties: {
          protocol: 'Http'
          path: '/'
          interval: 30
          timeout: 30
          unhealthyThreshold: 3
          pickHostNameFromBackendHttpSettings: true
          minServers: 0
          match: {
            statusCodes: [
              '200-399'
            ]
          }
        }
      }
    ]
    enableHttp2: false
    autoscaleConfiguration: {
      minCapacity: minCapacity
      maxCapacity: maxCapacity
    }
    webApplicationFirewallConfiguration: {
      enabled: wafState == 'Enabled'
      firewallMode: wafMode
      ruleSetType: wafRuleSetType
      ruleSetVersion: wafRuleSetVersion
      disabledRuleGroups: []
      requestBodyCheck: true
      maxRequestBodySizeInKb: 128
      fileUploadLimitInMb: 100
    }
  }
  tags: {
    Environment: environmentName
    Purpose: 'Application Gateway'
  }
}

// Outputs
@description('Application Gateway name')
output appGatewayName string = applicationGateway.name

@description('Application Gateway resource ID')
output appGatewayId string = applicationGateway.id

@description('Public IP address')
output publicIpAddress string = publicIp.properties.ipAddress

@description('Public IP FQDN')
output publicIpFqdn string = publicIp.properties.dnsSettings.fqdn

@description('Backend pool name for AKS integration')
output backendPoolName string = 'appGatewayBackendPool'

@description('WAF mode configuration')
output wafMode string = wafMode

@description('WAF state configuration')
output wafState string = wafState
