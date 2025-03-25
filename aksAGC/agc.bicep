param location string = resourceGroup().location
param agcName string
param subnetid string

resource publicIp 'Microsoft.Network/publicIPAddresses@2022-09-01' = {
  name: 'pip-agc-aks'
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
  }
}

resource agc 'Microsoft.ServiceNetworking/trafficControllers@2024-05-01-preview' = {
  name: agcName
  location: location
  properties: {}
}

resource agcSnet 'Microsoft.ServiceNetworking/trafficControllers/associations@2024-05-01-preview' = {
  name: 'snet'
  parent: agc
  location: location
  properties: {
    associationType: 'subnets'
    subnet: {
      id: subnetid
    }
  }
}

resource agcFE 'Microsoft.ServiceNetworking/trafficControllers/frontends@2024-05-01-preview' = {
  name: 'fe'
  parent: agc
  location: location
  properties: {}
}
