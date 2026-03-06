targetScope = 'resourceGroup'

@description('Name of the Fabric private link service resource for workspace-level private access.')
param name string

@description('Microsoft Entra tenant ID to associate with this private link service.')
param tenantId string

@description('Fabric workspace ID (GUID) for workspace-level private link service.')
param workspaceId string

resource privateLinkService 'Microsoft.Fabric/privateLinkServicesForFabric@2024-06-01' = {
  name: name
  location: 'global'
  properties: {
    tenantId: tenantId
    workspaceId: workspaceId
  }
}

output privateLinkServiceId string = privateLinkService.id