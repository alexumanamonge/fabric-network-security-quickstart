targetScope = 'resourceGroup'

@description('Azure region for jumpbox resources.')
param location string

@description('Jumpbox VM name.')
param vmName string

@description('NIC name for jumpbox VM.')
param nicName string

@description('OS disk name for jumpbox VM.')
param osDiskName string

@description('Admin username for jumpbox VM.')
param adminUsername string

@secure()
@description('Admin password for jumpbox VM.')
param adminPassword string

@description('Subnet resource ID for jumpbox NIC.')
param subnetId string

@description('Jumpbox VM size.')
param vmSize string = 'Standard_B2s'

resource jumpboxNic 'Microsoft.Network/networkInterfaces@2023-09-01' = {
  name: nicName
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          subnet: {
            id: subnetId
          }
          privateIPAllocationMethod: 'Dynamic'
        }
      }
    ]
  }
}

resource jumpboxVm 'Microsoft.Compute/virtualMachines@2023-09-01' = {
  name: vmName
  location: location
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    osProfile: {
      computerName: vmName
      adminUsername: adminUsername
      adminPassword: adminPassword
      windowsConfiguration: {
        enableAutomaticUpdates: true
        provisionVMAgent: true
      }
    }
    storageProfile: {
      imageReference: {
        publisher: 'MicrosoftWindowsServer'
        offer: 'WindowsServer'
        sku: '2022-datacenter-azure-edition'
        version: 'latest'
      }
      osDisk: {
        name: osDiskName
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: 'Premium_LRS'
        }
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: jumpboxNic.id
        }
      ]
    }
  }
}

output vmId string = jumpboxVm.id
