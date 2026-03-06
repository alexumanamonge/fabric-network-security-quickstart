targetScope = 'subscription'

@description('Project naming prefix. Suggested pattern: <your-prefix>-demo.')
param projectPrefix string = 'yourprefix-demo'

@description('Hub region (for hub vNet, Bastion, and jumpbox).')
param hubLocation string

@description('Spoke region (for Fabric networking vNet).')
param spokeLocation string

@description('Hub resource group name.')
param hubRgName string = '${projectPrefix}-hub-rg'

@description('Spoke resource group name.')
param spokeRgName string = '${projectPrefix}-spk-rg'

@description('Jumpbox resource group name.')
param jumpboxRgName string = '${projectPrefix}-jmp-rg'

@description('Hub subscription ID. Keep equal to current subscription for v1.')
param hubSubscriptionId string = subscription().subscriptionId

@description('Spoke subscription ID. Keep equal to current subscription for v1.')
param spokeSubscriptionId string = subscription().subscriptionId

@description('Jumpbox subscription ID. Keep equal to current subscription for v1.')
param jumpboxSubscriptionId string = subscription().subscriptionId

@description('Hub vNet name.')
param hubVnetName string = '${projectPrefix}-hub-vnet'

@description('Hub vNet CIDR range.')
param hubVnetAddressPrefix string = '10.10.0.0/16'

@description('Gateway subnet CIDR (reserved only in v1).')
param gatewaySubnetPrefix string = '10.10.0.0/27'

@description('Azure Firewall subnet CIDR (reserved only in v1).')
param firewallSubnetPrefix string = '10.10.0.64/26'

@description('Azure Bastion subnet CIDR.')
param bastionSubnetPrefix string = '10.10.1.0/26'

@description('Jumpbox subnet CIDR.')
param jumpboxSubnetPrefix string = '10.10.2.0/24'

@description('Spoke vNet name.')
param spokeVnetName string = '${projectPrefix}-fab-vnet'

@description('Spoke vNet CIDR range.')
param spokeVnetAddressPrefix string = '10.20.0.0/16'

@description('Fabric subnet CIDR.')
param fabricSubnetPrefix string = '10.20.1.0/24'

@description('Private Endpoints subnet CIDR placeholder.')
param privateEndpointsSubnetPrefix string = '10.20.2.0/24'

@description('Private DNS zones to create and link to hub and spoke vNets. Update as needed for your Fabric scenario.')
param privateDnsZoneNames array = [
  'privatelink.fabric.microsoft.com'
]

@description('Deploy Azure Bastion in hub vNet.')
param deployBastion bool = true

@description('Deploy jumpbox VM in hub region, in dedicated jumpbox resource group.')
param deployJumpbox bool = true

@description('Deploy NAT Gateway for outbound internet access from jumpbox subnet.')
param deployJumpboxNatGateway bool = true

@description('Deploy workspace-level Fabric private link resources.')
param deployWorkspacePrivateLink bool = true

@description('Jumpbox VM name.')
param jumpboxVmName string = '${projectPrefix}-jmp-vm'

@description('NAT Gateway name for jumpbox subnet egress.')
param jumpboxNatGatewayName string = '${projectPrefix}-jmp-ngw'

@description('Public IP name for jumpbox NAT Gateway.')
param jumpboxNatPublicIpName string = '${projectPrefix}-jmp-ngw-pip'

@description('Name of Microsoft.Fabric/privateLinkServicesForFabric resource for workspace-level private link.')
param fabricWorkspacePrivateLinkServiceName string = '${projectPrefix}-fabric-ws-pls'

@description('Fabric workspace ID (GUID) for workspace-level private link service.')
param fabricWorkspaceId string = ''

@description('Name of private endpoint for workspace-level Fabric private link.')
param fabricWorkspacePrivateEndpointName string = '${projectPrefix}-fabric-ws-pls-pe'

@description('Jumpbox admin username.')
param jumpboxAdminUsername string = 'azureuser'

@secure()
@description('Jumpbox admin password (Windows VM).')
param jumpboxAdminPassword string

module hubRg './modules/resourceGroup.bicep' = {
  name: 'deploy-hub-rg'
  scope: subscription(hubSubscriptionId)
  params: {
    name: hubRgName
    location: hubLocation
  }
}

module spokeRg './modules/resourceGroup.bicep' = {
  name: 'deploy-spoke-rg'
  scope: subscription(spokeSubscriptionId)
  params: {
    name: spokeRgName
    location: spokeLocation
  }
}

module jumpboxRg './modules/resourceGroup.bicep' = {
  name: 'deploy-jumpbox-rg'
  scope: subscription(jumpboxSubscriptionId)
  params: {
    name: jumpboxRgName
    location: hubLocation
  }
}

module jumpboxNatGateway './modules/natGateway.bicep' = if (deployJumpboxNatGateway) {
  name: 'deploy-jumpbox-nat-gateway'
  scope: resourceGroup(hubSubscriptionId, hubRgName)
  params: {
    location: hubLocation
    natGatewayName: jumpboxNatGatewayName
    publicIpName: jumpboxNatPublicIpName
  }
  dependsOn: [
    hubRg
  ]
}

module hubNetwork './modules/hubNetwork.bicep' = {
  name: 'deploy-hub-network'
  scope: resourceGroup(hubSubscriptionId, hubRgName)
  params: {
    location: hubLocation
    vnetName: hubVnetName
    vnetAddressPrefix: hubVnetAddressPrefix
    gatewaySubnetPrefix: gatewaySubnetPrefix
    firewallSubnetPrefix: firewallSubnetPrefix
    bastionSubnetPrefix: bastionSubnetPrefix
    jumpboxSubnetPrefix: jumpboxSubnetPrefix
    jumpboxNatGatewayId: deployJumpboxNatGateway ? jumpboxNatGateway.outputs.natGatewayId : ''
    reserveGatewaySubnet: true
    reserveFirewallSubnet: true
  }
  dependsOn: [
    hubRg
    jumpboxNatGateway
  ]
}

module spokeNetwork './modules/spokeNetwork.bicep' = {
  name: 'deploy-spoke-network'
  scope: resourceGroup(spokeSubscriptionId, spokeRgName)
  params: {
    location: spokeLocation
    vnetName: spokeVnetName
    vnetAddressPrefix: spokeVnetAddressPrefix
    fabricSubnetPrefix: fabricSubnetPrefix
    privateEndpointsSubnetPrefix: privateEndpointsSubnetPrefix
  }
  dependsOn: [
    spokeRg
  ]
}

module hubToSpokePeering './modules/vnetPeering.bicep' = {
  name: 'deploy-hub-to-spoke-peering'
  scope: resourceGroup(hubSubscriptionId, hubRgName)
  params: {
    localVnetName: hubVnetName
    remoteVnetId: spokeNetwork.outputs.vnetId
    peeringName: '${projectPrefix}-hub-to-spk'
    allowGatewayTransit: true
  }
  dependsOn: [
    hubNetwork
    spokeNetwork
  ]
}

module spokeToHubPeering './modules/vnetPeering.bicep' = {
  name: 'deploy-spoke-to-hub-peering'
  scope: resourceGroup(spokeSubscriptionId, spokeRgName)
  params: {
    localVnetName: spokeVnetName
    remoteVnetId: hubNetwork.outputs.vnetId
    peeringName: '${projectPrefix}-spk-to-hub'
    useRemoteGateways: false
  }
  dependsOn: [
    hubToSpokePeering
  ]
}

module privateDns './modules/privateDns.bicep' = {
  name: 'deploy-private-dns'
  scope: resourceGroup(hubSubscriptionId, hubRgName)
  params: {
    zoneNames: privateDnsZoneNames
    virtualNetworkIds: [
      hubNetwork.outputs.vnetId
      spokeNetwork.outputs.vnetId
    ]
  }
  dependsOn: [
    hubToSpokePeering
    spokeToHubPeering
  ]
}

module fabricWorkspacePrivateLinkService './modules/fabricWorkspacePrivateLinkService.bicep' = if (deployWorkspacePrivateLink) {
  name: 'deploy-fabric-workspace-private-link-service'
  scope: resourceGroup(hubSubscriptionId, hubRgName)
  params: {
    name: fabricWorkspacePrivateLinkServiceName
    tenantId: tenant().tenantId
    workspaceId: fabricWorkspaceId
  }
  dependsOn: [
    hubRg
  ]
}

module bastion './modules/bastion.bicep' = if (deployBastion) {
  name: 'deploy-bastion'
  scope: resourceGroup(hubSubscriptionId, hubRgName)
  params: {
    location: hubLocation
    vnetName: hubVnetName
    bastionName: '${projectPrefix}-bst'
    publicIpName: '${projectPrefix}-bst-pip'
  }
  dependsOn: [
    hubNetwork
  ]
}

module jumpbox './modules/jumpboxVm.bicep' = if (deployJumpbox) {
  name: 'deploy-jumpbox'
  scope: resourceGroup(jumpboxSubscriptionId, jumpboxRgName)
  params: {
    location: hubLocation
    vmName: jumpboxVmName
    adminUsername: jumpboxAdminUsername
    adminPassword: jumpboxAdminPassword
    subnetId: hubNetwork.outputs.jumpboxSubnetId
    nicName: '${projectPrefix}-jmp-nic'
    osDiskName: '${projectPrefix}-jmp-os'
  }
  dependsOn: [
    jumpboxRg
    hubNetwork
  ]
}

module fabricWorkspacePrivateEndpoint './modules/fabricPrivateEndpoint.bicep' = if (deployWorkspacePrivateLink) {
  name: 'deploy-fabric-workspace-private-endpoint'
  scope: resourceGroup(spokeSubscriptionId, spokeRgName)
  params: {
    privateEndpointName: fabricWorkspacePrivateEndpointName
    location: spokeLocation
    subnetId: spokeNetwork.outputs.privateEndpointsSubnetId
    privateLinkServiceResourceId: fabricWorkspacePrivateLinkService.outputs.privateLinkServiceId
    privateDnsZoneIds: privateDns.outputs.zoneIds
  }
  dependsOn: [
    spokeNetwork
    privateDns
    fabricWorkspacePrivateLinkService
  ]
}

output hubVnetId string = hubNetwork.outputs.vnetId
output spokeVnetId string = spokeNetwork.outputs.vnetId
output jumpboxVmId string = deployJumpbox ? jumpbox.outputs.vmId : ''
output fabricPrivateEndpointId string = deployWorkspacePrivateLink ? fabricWorkspacePrivateEndpoint.outputs.privateEndpointId : ''
