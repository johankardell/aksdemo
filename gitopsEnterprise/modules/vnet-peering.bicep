param hubname string
param lzname string

resource hub 'Microsoft.Network/virtualNetworks@2024-05-01' existing = {
  name: hubname
}

resource lz 'Microsoft.Network/virtualNetworks@2024-05-01' existing = {
  name: lzname
}

resource hubtolz 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2024-05-01' = {
  name: 'hub-to-lz'
  parent: hub
  properties: {
    allowVirtualNetworkAccess: true
    allowForwardedTraffic: true
    allowGatewayTransit: false
    useRemoteGateways: false
    remoteVirtualNetwork: {
      id: lz.id
    }
  }
}

resource lztohub 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2024-05-01' = {
  name: 'lz-to-hub'
  parent: lz
  properties: {
    allowVirtualNetworkAccess: true
    allowForwardedTraffic: true
    allowGatewayTransit: false
    useRemoteGateways: false
    remoteVirtualNetwork: {
      id: hub.id
    }
  }
}
