param privateDnsZoneName string
param vnetId string 
param aksidname string
param vnetname string

var privateDnsContributorRoleDefId = 'b12aa53e-6015-4669-85d0-8515ebb3ae7f'

resource aksid 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' existing = {
  name: aksidname
}


resource privateDNSZone 'Microsoft.Network/privateDnsZones@2024-06-01' = {
  name: privateDnsZoneName
  location: 'global'
}

resource setPrivateDnsZoneRbac 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  scope: privateDNSZone
  name: guid(aksid.id, privateDnsContributorRoleDefId, privateDNSZone.name)
  properties: {
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', privateDnsContributorRoleDefId)
    principalId: aksid.properties.principalId
    principalType: 'ServicePrincipal'
  }
}


resource privateDnslink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2024-06-01' = {
  parent: privateDNSZone
  name: '${privateDnsZoneName}-link-vnet-${vnetname}'
  location: 'global'
  properties: {
    registrationEnabled: contains(privateDnsZoneName,vnetname) ? true : false 
    virtualNetwork: {
      id: vnetId
    }
  }
}

output privateDNSZoneId string = privateDNSZone.id
output privateDNSZoneName string = privateDNSZone.name
