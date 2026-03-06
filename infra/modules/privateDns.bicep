targetScope = 'resourceGroup'

@description('Private DNS zone names.')
param zoneNames array

@description('Virtual network IDs to link to each private DNS zone.')
param virtualNetworkIds array

resource zones 'Microsoft.Network/privateDnsZones@2020-06-01' = [for zoneName in zoneNames: {
  name: zoneName
  location: 'global'
}]

resource hubLinks 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = [for zoneName in zoneNames: {
  name: '${zoneName}/link-1'
  location: 'global'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: virtualNetworkIds[0]
    }
  }
  dependsOn: [
    zones
  ]
}]

resource spokeLinks 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = [for zoneName in zoneNames: if (length(virtualNetworkIds) > 1) {
  name: '${zoneName}/link-2'
  location: 'global'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: virtualNetworkIds[1]
    }
  }
  dependsOn: [
    zones
  ]
}]

output zoneIds array = [for (zoneName, i) in zoneNames: zones[i].id]
