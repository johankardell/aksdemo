param location string = resourceGroup().location
param miname string

resource mi 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-07-31-preview' = {
  name: miname
  location: location
}
