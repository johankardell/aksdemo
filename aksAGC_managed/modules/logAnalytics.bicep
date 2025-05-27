targetScope = 'resourceGroup'

param laName string
param location string = resourceGroup().location

//create a log analytics workspace for container insights
resource law 'Microsoft.OperationalInsights/workspaces@2023-09-01' = {
  name: laName
  location: location
  properties: {
    sku: {
      name: 'PerGB2018'
    }
  }
}

output id string = law.id
