targetScope = 'resourceGroup'

@description('Name of the local virtual network in this resource group.')
param localVnetName string

@description('Resource ID of remote virtual network.')
param remoteVnetId string

@description('Peering resource name.')
param peeringName string

param allowVirtualNetworkAccess bool = true
param allowForwardedTraffic bool = true
param allowGatewayTransit bool = false
param useRemoteGateways bool = false

resource localVnet 'Microsoft.Network/virtualNetworks@2023-09-01' existing = {
  name: localVnetName
}

resource peering 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2023-09-01' = {
  name: '${localVnet.name}/${peeringName}'
  properties: {
    remoteVirtualNetwork: {
      id: remoteVnetId
    }
    allowVirtualNetworkAccess: allowVirtualNetworkAccess
    allowForwardedTraffic: allowForwardedTraffic
    allowGatewayTransit: allowGatewayTransit
    useRemoteGateways: useRemoteGateways
  }
}

output peeringId string = peering.id
