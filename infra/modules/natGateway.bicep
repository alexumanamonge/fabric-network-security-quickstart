targetScope = 'resourceGroup'

@description('Azure region for NAT Gateway resources.')
param location string

@description('NAT Gateway name.')
param natGatewayName string

@description('Public IP name used by NAT Gateway.')
param publicIpName string

resource natPublicIp 'Microsoft.Network/publicIPAddresses@2023-09-01' = {
  name: publicIpName
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
  }
}

resource natGateway 'Microsoft.Network/natGateways@2023-09-01' = {
  name: natGatewayName
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIpAddresses: [
      {
        id: natPublicIp.id
      }
    ]
    idleTimeoutInMinutes: 10
  }
}

output natGatewayId string = natGateway.id