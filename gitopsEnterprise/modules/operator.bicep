var managedIdentityOperatorDefId = 'f1a07417-d97a-45cb-824c-7a7467783830' // Managed Identity Operator
var uami object

resource rbac 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(umi.id, managedIdentityOperatorDefId, name)
  properties: {
    principalId: 
    roleDefinitionId: 
  }
}
