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

## Before you start (important)

1. You need an Azure subscription where you can create resource groups, networking, VM, and private endpoint resources.
2. You need a Microsoft Fabric workspace ID (GUID).
3. Choose a short custom prefix (for example `contoso-demo`).
4. Use a strong password for the jumpbox VM.

## Expected deployment time

- Typical end-to-end deployment time: **15 to 30 minutes**.
- First-time deployments in a subscription can take longer (for example, provider registration delays).
- If it runs longer than expected, check deployment status in Portal under **Deployments** for your subscription.

## Estimated cost (important)

This quickstart deploys billable resources. For most environments, the biggest cost drivers are:

- Azure Bastion (Basic SKU)
- Jumpbox VM + managed OS disk
- NAT Gateway + Standard Public IP

Additional smaller charges may apply for private endpoint and private DNS resources.

To avoid unnecessary charges:

- Run this in a non-production subscription.
- Delete resources when finished using the **Cleanup** section below.
- Use the [Azure Pricing Calculator](https://azure.microsoft.com/pricing/calculator/) to estimate cost in your regions before deployment.

## Option A (recommended): Deploy with the Azure Portal button

This is the easiest path if you are new to Bicep/Azure IaC.

[![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Falexumanamonge%2Ffabric-network-security-quickstart%2Fmain%2Finfra%2Fmain.json)

### Portal steps

1. Click the button above.
2. In Azure Portal, review/enter at least these parameters:
   - `projectPrefix` = your custom prefix (example: `contoso-demo`)
   - `hubLocation` and `spokeLocation`
   - `fabricWorkspaceId` = your Fabric workspace GUID
   - `jumpboxAdminPassword` = strong password
3. Select the subscription.
4. Click **Review + create**, then **Create**.

## Option B: Deploy with Azure CLI

Use this option if you prefer terminal commands.

### Step 1 - Sign in and choose subscription

```powershell
az login
az account set --subscription <subscription-id>
```

### Step 2 - Update parameter file

Open `infra/parameters/demo.bicepparam` and set:

- `projectPrefix`
- `fabricWorkspaceId`
- (Optional) `hubLocation` / `spokeLocation`

Keep `jumpboxAdminPassword` as placeholder in the file and pass the real password in CLI.

### Step 3 - Deploy

```powershell
az deployment sub create `
  --name <your-prefix>-fabric-net `
  --location eastus `
  --template-file ./infra/main.bicep `
  --parameters ./infra/parameters/demo.bicepparam `
  --parameters jumpboxAdminPassword='<strong-password>'
```

## Validate deployment

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

## Cleanup

```powershell
az deployment sub delete --name <your-prefix>-fabric-net
az group delete -n <your-prefix>-demo-hub-rg --yes --no-wait
az group delete -n <your-prefix>-demo-spk-rg --yes --no-wait
az group delete -n <your-prefix>-demo-jmp-rg --yes --no-wait
```

## Troubleshooting

- **Deploy button says template is not publicly accessible**:
  - The template URL must be `raw.githubusercontent.com` and the repo/branch/path must exist.
  - This README already points to a public template URL in this repository.
  - If you fork or rename the repo, update the button URL accordingly.
- **Deployment fails on Fabric workspace private link**:
  - Check `fabricWorkspaceId` is a valid workspace GUID in your tenant.
- **Deployment fails on password requirement**:
  - Use a stronger `jumpboxAdminPassword` that meets Windows complexity requirements.
