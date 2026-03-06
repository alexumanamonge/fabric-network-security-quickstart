targetScope = 'resourceGroup'

@description('Azure region for spoke network resources.')
param location string

@description('Spoke vNet name.')
param vnetName string

@description('Spoke vNet CIDR range.')
param vnetAddressPrefix string

@description('Fabric subnet CIDR.')
param fabricSubnetPrefix string

@description('Private Endpoints subnet CIDR placeholder.')
param privateEndpointsSubnetPrefix string

resource spokeVnet 'Microsoft.Network/virtualNetworks@2023-09-01' = {
  name: vnetName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        vnetAddressPrefix
      ]
    }
    subnets: [
      {
        name: 'snet-fabric'
        properties: {
          addressPrefix: fabricSubnetPrefix
        }
      }
      {
        name: 'snet-private-endpoints'
        properties: {
          addressPrefix: privateEndpointsSubnetPrefix
          privateEndpointNetworkPolicies: 'Disabled'
        }
      }
    ]
  }
}

output vnetId string = spokeVnet.id
output privateEndpointsSubnetId string = '${spokeVnet.id}/subnets/snet-private-endpoints'
