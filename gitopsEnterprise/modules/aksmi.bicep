param aksidname string
param location string

var managedIdentityOperatorDefId = 'f1a07417-d97a-45cb-824c-7a7467783830' // Managed Identity Operator
var contributorRoleDefId= 'b24988ac-6180-42a0-ab88-20f7382dd24c' // Contributor

resource aksid 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: aksidname
  location: location
}

resource miOperatorRbac 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  scope: resourceGroup()
  name: guid(aksid.id, managedIdentityOperatorDefId, aksidname)
  properties: {
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', managedIdentityOperatorDefId)
    principalId: aksid.properties.principalId
    principalType: 'ServicePrincipal'
  }
}

resource rgRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(aksid.id, contributorRoleDefId, aksidname)
  properties: {
    principalId: aksid.properties.principalId
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', contributorRoleDefId)
  }
}
