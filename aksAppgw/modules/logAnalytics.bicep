// Log Analytics workspace module
// Provides centralized logging and monitoring for AKS and Application Gateway

@description('Name of the Log Analytics workspace')
param name string

@description('Location for the workspace')
param location string = resourceGroup().location

@description('Environment name for tagging')
param environmentName string

@description('SKU for the Log Analytics workspace')
param sku string = 'PerGB2018'

@description('Data retention in days')
@minValue(30)
@maxValue(730)
param retentionInDays int = 30

// Log Analytics workspace
resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2023-09-01' = {
  name: name
  location: location
  tags: {
    Environment: environmentName
    Purpose: 'AKS and Application Gateway monitoring'
  }
  properties: {
    sku: {
      name: sku
    }
    retentionInDays: retentionInDays
    features: {
      enableLogAccessUsingOnlyResourcePermissions: true
    }
    workspaceCapping: {
      dailyQuotaGb: 1
    }
  }
}

// Outputs
output workspaceId string = logAnalyticsWorkspace.id
output workspaceName string = logAnalyticsWorkspace.name
output customerId string = logAnalyticsWorkspace.properties.customerId
