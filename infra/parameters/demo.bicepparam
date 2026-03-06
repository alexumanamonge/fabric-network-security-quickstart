using '../main.bicep'

param projectPrefix = 'yourprefix-demo'

param hubLocation = 'eastus2'
param spokeLocation = 'westus3'

param hubRgName = '${projectPrefix}-hub-rg'
param spokeRgName = '${projectPrefix}-spk-rg'
param jumpboxRgName = '${projectPrefix}-jmp-rg'

param hubVnetName = '${projectPrefix}-hub-vnet'
param hubVnetAddressPrefix = '10.10.0.0/16'
param gatewaySubnetPrefix = '10.10.0.0/27'
param firewallSubnetPrefix = '10.10.0.64/26'
param bastionSubnetPrefix = '10.10.1.0/26'
param jumpboxSubnetPrefix = '10.10.2.0/24'

param spokeVnetName = '${projectPrefix}-fab-vnet'
param spokeVnetAddressPrefix = '10.20.0.0/16'
param fabricSubnetPrefix = '10.20.1.0/24'
param privateEndpointsSubnetPrefix = '10.20.2.0/24'

param privateDnsZoneNames = [
  'privatelink.fabric.microsoft.com'
]

param deployBastion = true
param deployJumpbox = true
param deployJumpboxNatGateway = true
param deployWorkspacePrivateLink = true

param jumpboxVmName = '${projectPrefix}-jmp-vm'
param jumpboxNatGatewayName = '${projectPrefix}-jmp-ngw'
param jumpboxNatPublicIpName = '${projectPrefix}-jmp-ngw-pip'
param jumpboxAdminUsername = 'azureuser'
param jumpboxAdminPassword = '<REPLACE-WITH-STRONG-PASSWORD>'

param fabricWorkspacePrivateLinkServiceName = '${projectPrefix}-fabric-ws-pls'
param fabricWorkspaceId = ''
param fabricWorkspacePrivateEndpointName = '${projectPrefix}-fabric-ws-pls-pe'

