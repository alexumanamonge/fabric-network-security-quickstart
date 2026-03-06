targetScope = 'resourceGroup'

@description('Private endpoint name.')
param privateEndpointName string

@description('Region for private endpoint.')
param location string

@description('Subnet ID for private endpoint NIC placement.')
param subnetId string

@description('Resource ID of private link service resource.')
param privateLinkServiceResourceId string

@description('Private DNS zone IDs for private link integration.')
param privateDnsZoneIds array

resource privateEndpoint 'Microsoft.Network/privateEndpoints@2023-09-01' = {
  name: privateEndpointName
  location: location
  properties: {
    subnet: {
      id: subnetId
    }
    privateLinkServiceConnections: [
      {
        name: '${privateEndpointName}-workspace'
        properties: {
          privateLinkServiceId: privateLinkServiceResourceId
          groupIds: [
            'workspace'
          ]
          requestMessage: 'Workspace-level Fabric private endpoint connection'
        }
      }
    ]
  }
}

resource privateDnsZoneGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2023-09-01' = {
  name: '${privateEndpoint.name}/default'
  properties: {
    privateDnsZoneConfigs: [
      for (privateDnsZoneId, i) in privateDnsZoneIds: {
        name: 'zone-${i + 1}'
        properties: {
          privateDnsZoneId: privateDnsZoneId
        }
      }
    ]
  }
}

output privateEndpointId string = privateEndpoint.id