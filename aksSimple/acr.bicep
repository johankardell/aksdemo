param acrName string
param location string
param aksid string

var acrPullRoleDefId = '7f951dda-4ed3-4680-a7ca-43fe172d538d'

resource acr 'Microsoft.ContainerRegistry/registries@2021-06-01-preview' = {
  name: acrName
  location: location
  sku: {
    name: 'Premium'
  }
  properties: {
    adminUserEnabled: false
  }
}

resource acrRoleAssignment 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  scope: acr
  name: guid(aksid, acrPullRoleDefId, acrName)
  properties: {
    principalId: aksid
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', acrPullRoleDefId)
  }
}
