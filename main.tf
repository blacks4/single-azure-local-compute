locals {
  nic_ip_configuration = {
    name = "ipconfig1"
    properties = merge(
      {
        subnet = {
          id = var.logical_network_id
        }
      },
      var.private_ip_address == null ? {} : {
        privateIPAddress = var.private_ip_address
      }
    )
  }

  hardware_profile = merge(
    {
      vmSize     = "Custom"
      processors = var.processor_count
      memoryMB   = var.memory_mb
    }
  )

  windows_configuration = merge(
    {
      enableAutomaticUpdates = var.windows_enable_automatic_updates
      provisionVMAgent       = var.provision_vm_agent
      provisionVMConfigAgent = var.provision_vm_config_agent
    },
    var.windows_time_zone == null ? {} : {
      timeZone = var.windows_time_zone
    }
  )

  os_profile = merge(
    {
      adminUsername        = var.admin_username
      adminPassword        = var.admin_password
      computerName         = var.vm_name
      windowsConfiguration = local.windows_configuration
    }
  )

  vm_properties = merge(
    {
      hardwareProfile = local.hardware_profile
      osProfile       = local.os_profile
      storageProfile = {
        osDisk = {
          id     = azapi_resource.azure_local_os_disk.id
          osType = "Windows"
        }
      }
      networkProfile = {
        networkInterfaces = [
          {
            id = azapi_resource.azure_local_nic.id
          }
        ]
      }
    },
    (var.secure_boot_enabled || var.enable_tpm || var.security_type != null) ? {
      securityProfile = merge(
        {
          enableTPM = var.enable_tpm
          uefiSettings = {
            secureBootEnabled = var.secure_boot_enabled
          }
        },
        var.security_type == null ? {} : {
          securityType = var.security_type
        }
      )
    } : {},
    var.placement_zone == null ? {} : {
      placementProfile = {
        zone                  = var.placement_zone
        strictPlacementPolicy = var.strict_placement_policy
      }
    }
  )
}

resource "azapi_resource" "azure_local_os_disk" {
  type                      = "Microsoft.AzureStackHCI/virtualHardDisks@2026-02-01-preview"
  name                      = "${var.vm_name}-osdisk"
  parent_id                 = data.azurerm_resource_group.azure_local.id
  location                  = var.location
  schema_validation_enabled = false
  tags                      = var.tags

  body = {
    extendedLocation = {
      type = "CustomLocation"
      name = var.custom_location_id
    }
    properties = {
      containerId      = var.os_disk_storage_container_id
      createFromLocal  = false
      diskFileFormat   = "vhdx"
      diskSizeGB       = var.c_drive_size_gb
      dynamic          = false
      hyperVGeneration = var.os_disk_hyperv_generation
      creationData = {
        createOption     = "Copy"
        sourceResourceId = var.image_id
      }
    }
  }
}

resource "azapi_resource" "arc_machine" {
  type      = "Microsoft.HybridCompute/machines@2024-07-10"
  name      = var.vm_name
  parent_id = data.azurerm_resource_group.azure_local.id
  location  = var.location
  tags      = var.tags

  identity {
    type = "SystemAssigned"
  }

  body = {
    kind = "HCI"
  }
}

resource "azapi_resource" "azure_local_nic" {
  type                      = "Microsoft.AzureStackHCI/networkInterfaces@2024-01-01"
  name                      = "nic-${var.vm_name}"
  parent_id                 = data.azurerm_resource_group.azure_local.id
  location                  = var.location
  schema_validation_enabled = false
  tags                      = var.tags

  body = {
    extendedLocation = {
      type = "CustomLocation"
      name = var.custom_location_id
    }
    properties = {
      ipConfigurations = [local.nic_ip_configuration]
    }
  }
}

resource "azapi_resource" "azure_local_virtual_machine" {
  type                      = "Microsoft.AzureStackHCI/virtualMachineInstances@2024-01-01"
  name                      = "default"
  parent_id                 = azapi_resource.arc_machine.id
  schema_validation_enabled = false

  body = {
    extendedLocation = {
      type = "CustomLocation"
      name = var.custom_location_id
    }
    properties = local.vm_properties
  }
}
