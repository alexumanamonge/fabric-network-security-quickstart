targetScope = 'subscription'

@description('Resource group name.')
param name string

@description('Azure region for the resource group.')
param location string

resource resourceGroup 'Microsoft.Resources/resourceGroups@2024-03-01' = {
  name: name
  location: location
}

output name string = resourceGroup.name
output id string = resourceGroup.id
