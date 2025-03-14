param aksidname string
param location string

resource aksid 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: aksidname
  location: location
}

output clientid string = aksid.properties.clientId
output principalid string = aksid.properties.principalId
