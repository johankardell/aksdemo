// Managed Identity module
// Creates a user-assigned managed identity for AKS cluster

@description('Name of the managed identity')
param name string

@description('Location for the managed identity')
param location string = resourceGroup().location

@description('Environment name for tagging')
param environmentName string

// User-assigned managed identity for AKS
resource managedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: name
  location: location
  tags: {
    Environment: environmentName
    Purpose: 'AKS cluster identity'
  }
}

// Network Contributor role assignment for AKS subnet access
resource networkContributorRole 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(managedIdentity.id, resourceGroup().id, 'Network Contributor')
  scope: resourceGroup()
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '4d97b98b-1d4f-4787-a291-c67834d212e7') // Network Contributor
    principalId: managedIdentity.properties.principalId
    principalType: 'ServicePrincipal'
  }
}

// Managed Identity Operator role for AKS to use the identity
resource managedIdentityOperatorRole 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(managedIdentity.id, resourceGroup().id, 'Managed Identity Operator')
  scope: managedIdentity
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'f1a07417-d97a-45cb-824c-7a7467783830') // Managed Identity Operator
    principalId: managedIdentity.properties.principalId
    principalType: 'ServicePrincipal'
  }
}

// Outputs
output identityId string = managedIdentity.id
output principalId string = managedIdentity.properties.principalId
output clientId string = managedIdentity.properties.clientId
output name string = managedIdentity.name
