param name string
param principalId string
param roleDefinitionId string

resource rbac 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(name, roleDefinitionId)
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', roleDefinitionId)
    principalId: principalId
    principalType: 'ServicePrincipal'
  }
}
