targetScope = 'resourceGroup'

@description('Azure region for hub network resources.')
param location string

@description('Hub vNet name.')
param vnetName string

@description('Hub vNet CIDR range.')
param vnetAddressPrefix string

@description('Reserve GatewaySubnet for future gateway deployment.')
param reserveGatewaySubnet bool = true

@description('Reserve AzureFirewallSubnet for future firewall deployment.')
param reserveFirewallSubnet bool = true

@description('Gateway subnet CIDR.')
param gatewaySubnetPrefix string

@description('Firewall subnet CIDR.')
param firewallSubnetPrefix string

@description('Azure Bastion subnet CIDR.')
param bastionSubnetPrefix string

@description('Jumpbox subnet CIDR.')
param jumpboxSubnetPrefix string

@description('Optional NAT Gateway resource ID to associate to jumpbox subnet for outbound internet access.')
param jumpboxNatGatewayId string = ''

resource hubVnet 'Microsoft.Network/virtualNetworks@2023-09-01' = {
  name: vnetName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        vnetAddressPrefix
      ]
    }
    subnets: concat(
      reserveGatewaySubnet
        ? [
            {
              name: 'GatewaySubnet'
              properties: {
                addressPrefix: gatewaySubnetPrefix
              }
            }
          ]
        : [],
      reserveFirewallSubnet
        ? [
            {
              name: 'AzureFirewallSubnet'
              properties: {
                addressPrefix: firewallSubnetPrefix
              }
            }
          ]
        : [],
      [
        {
          name: 'AzureBastionSubnet'
          properties: {
            addressPrefix: bastionSubnetPrefix
          }
        }
        {
          name: 'snet-jumpbox'
          properties: union(
            {
              addressPrefix: jumpboxSubnetPrefix
            },
            empty(jumpboxNatGatewayId)
              ? {}
              : {
                  natGateway: {
                    id: jumpboxNatGatewayId
                  }
                }
          )
        }
      ]
    )
  }
}

output vnetId string = hubVnet.id
output jumpboxSubnetId string = '${hubVnet.id}/subnets/snet-jumpbox'
