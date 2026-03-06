# Fabric Network Security Quickstart

Reusable, modular Bicep quickstart to deploy a private, demo-ready hub-spoke baseline for Microsoft Fabric workspace private link scenarios.

## What this deploys

- Hub-spoke topology with regional separation.
- Three resource groups:
  - Hub RG
  - Spoke RG
  - Jumpbox RG
- Hub vNet with:
  - `GatewaySubnet` (reserved)
  - `AzureFirewallSubnet` (reserved)
  - `AzureBastionSubnet`
  - `snet-jumpbox` (optionally NAT-associated)
- Spoke vNet with:
  - `snet-fabric`
  - `snet-private-endpoints`
- Bidirectional vNet peering.
- Private DNS zone(s) linked to hub and spoke.
- Azure Bastion in hub RG.
- Windows jumpbox VM in jumpbox RG (no public IP).
- NAT Gateway + Public IP for jumpbox outbound internet.
- Fabric workspace private link service + private endpoint (`groupIds = ["workspace"]`).

## Architecture

See [docs/architecture.mmd](docs/architecture.mmd).

## Project structure

- `infra/main.bicep` - subscription-scope orchestration
- `infra/modules/resourceGroup.bicep` - reusable RG module
- `infra/modules/hubNetwork.bicep` - hub vNet and subnets
- `infra/modules/spokeNetwork.bicep` - spoke vNet and subnets
- `infra/modules/vnetPeering.bicep` - reusable vNet peering
- `infra/modules/privateDns.bicep` - private DNS zones and links
- `infra/modules/bastion.bicep` - Bastion + public IP
- `infra/modules/jumpboxVm.bicep` - jumpbox VM + NIC
- `infra/modules/natGateway.bicep` - NAT gateway + public IP
- `infra/modules/fabricWorkspacePrivateLinkService.bicep` - Fabric workspace private link service
- `infra/modules/fabricPrivateEndpoint.bicep` - private endpoint + DNS zone group
- `infra/parameters/demo.bicepparam` - demo starter parameters

## Naming

- Use your own prefix via `projectPrefix`.
- Suggested pattern: `<your-prefix>-demo`.
- Example resulting names:
  - `<your-prefix>-demo-hub-rg`
  - `<your-prefix>-demo-spk-rg`
  - `<your-prefix>-demo-jmp-rg`

## Security first

- `infra/parameters/demo.bicepparam` contains a password placeholder by default.
- Replace `jumpboxAdminPassword` with a strong password before deployment, or pass it at deploy time.
- Do not commit real secrets to source control.

## Deploy (Azure CLI)

```powershell
az login
az account set --subscription <subscription-id>

az deployment sub create `
  --name <your-prefix>-fabric-net `
  --location eastus `
  --template-file ./infra/main.bicep `
  --parameters ./infra/parameters/demo.bicepparam `
  --parameters jumpboxAdminPassword='<strong-password>'
```

### Required parameter checks

Before running deployment, verify in `infra/parameters/demo.bicepparam`:

- `fabricWorkspaceId` is set to your Fabric workspace GUID.
- `hubLocation` and `spokeLocation` are valid for your subscription.

## Validate after deployment

```powershell
az deployment sub show --name <your-prefix>-fabric-net --query properties.provisioningState -o tsv

az network private-endpoint show `
  -g <your-prefix>-demo-spk-rg `
  -n <your-prefix>-demo-fabric-ws-pls-pe `
  --query "{state:provisioningState,status:privateLinkServiceConnections[0].privateLinkServiceConnectionState.status,groupIds:privateLinkServiceConnections[0].groupIds}" -o json

az network vnet subnet show `
  -g <your-prefix>-demo-hub-rg `
  --vnet-name <your-prefix>-demo-hub-vnet `
  -n snet-jumpbox `
  --query "{subnet:name,natGatewayId:natGateway.id}" -o json
```

## Teardown

```powershell
az deployment sub delete --name <your-prefix>-fabric-net
az group delete -n <your-prefix>-demo-hub-rg --yes --no-wait
az group delete -n <your-prefix>-demo-spk-rg --yes --no-wait
az group delete -n <your-prefix>-demo-jmp-rg --yes --no-wait
```

## Deploy to Azure button (optional)

Build ARM JSON from Bicep:

```powershell
az bicep build --file ./infra/main.bicep --outfile ./infra/main.json
```

Then update `<your-org>` and `<your-repo>`:

[![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2F<your-org>%2F<your-repo>%2Fmain%2Finfra%2Fmain.json)
