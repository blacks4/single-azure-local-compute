locals {
  # Hardcoded VM-specific inputs for this file.
  vm_name_0                = ""
  custom_location_name_0   = ""
  logical_network_name_0   = ""
  image_name_0             = ""
  image_resource_type_0    = "galleryImages"
  storage_container_name_0 = ""

  admin_username_0      = "replace-me-admin"
  admin_password_0      = "replace-me-password"
  cpu_count_0           = 2
  memory_mb_0           = 8192
  data_volume_size_gb_0 = 0
  db_volume_size_gb_0   = 0
  log_volume_size_gb_0  = 0
  static_ip_address_0   = ""
  windows_time_zone_0   = "Eastern Standard Time"

  custom_location_resource_group_0   = var.azure_local_resource_group_name
  logical_network_resource_group_0   = var.azure_local_resource_group_name
  image_resource_group_0             = var.azure_local_resource_group_name
  storage_container_resource_group_0 = var.azure_local_resource_group_name

  normalized_subscription_id_0 = data.azapi_client_config.current.subscription_id

  custom_location_id_0   = "/subscriptions/${local.normalized_subscription_id_0}/resourceGroups/${local.custom_location_resource_group_0}/providers/Microsoft.ExtendedLocation/customLocations/${local.custom_location_name_0}"
  logical_network_id_0   = "/subscriptions/${local.normalized_subscription_id_0}/resourceGroups/${local.logical_network_resource_group_0}/providers/Microsoft.AzureStackHCI/logicalNetworks/${local.logical_network_name_0}"
  image_id_0             = "/subscriptions/${local.normalized_subscription_id_0}/resourceGroups/${local.image_resource_group_0}/providers/Microsoft.AzureStackHCI/${local.image_resource_type_0}/${local.image_name_0}"
  storage_container_id_0 = "/subscriptions/${local.normalized_subscription_id_0}/resourceGroups/${local.storage_container_resource_group_0}/providers/Microsoft.AzureStackHCI/storageContainers/${local.storage_container_name_0}"

  vm_tags_0 = merge(
    {
      managed_by = "terraform"
      workload   = "azure-local-vm"
    },
    var.additional_tags
  )

  nic_ip_configuration_0 = {
    name = "ipconfig1"
    properties = {
      subnet = {
        id = local.logical_network_id_0
      }
      privateIPAddress = trimspace(local.static_ip_address_0)
    }
  }

  windows_configuration_0 = {
    enableAutomaticUpdates = true
    provisionVMAgent       = true
    provisionVMConfigAgent = true
    timeZone               = local.windows_time_zone_0
  }

  create_data_volume_0 = local.data_volume_size_gb_0 > 0
  create_db_volume_0   = local.db_volume_size_gb_0 > 0
  create_log_volume_0  = local.log_volume_size_gb_0 > 0

  optional_data_disks_0 = concat(
    local.create_data_volume_0 ? [
      {
        id = azapi_resource.azure_local_data_disk_0["enabled"].id
      }
    ] : [],
    local.create_db_volume_0 ? [
      {
        id = azapi_resource.azure_local_db_disk_0["enabled"].id
      }
    ] : [],
    local.create_log_volume_0 ? [
      {
        id = azapi_resource.azure_local_log_disk_0["enabled"].id
      }
    ] : []
  )

  vm_storage_profile_0 = merge(
    {
      imageReference = {
        id = local.image_id_0
      }
      osDisk = {
        osType = "Windows"
      }
      vmConfigStoragePathId = local.storage_container_id_0
    },
    length(local.optional_data_disks_0) > 0 ? {
      dataDisks = local.optional_data_disks_0
    } : {}
  )
}

resource "azapi_resource" "arc_machine_0" {
  type      = "Microsoft.HybridCompute/machines@2024-07-10"
  name      = local.vm_name_0
  parent_id = data.azurerm_resource_group.azure_local_vm_deployment.id
  location  = var.location
  tags      = local.vm_tags_0

  identity {
    type = "SystemAssigned"
  }

  body = {
    kind = "HCI"
  }
}

resource "azapi_resource" "azure_local_nic_0" {
  type                      = "Microsoft.AzureStackHCI/networkInterfaces@2024-01-01"
  name                      = "${local.vm_name_0}-nic"
  parent_id                 = data.azurerm_resource_group.azure_local_vm_deployment.id
  location                  = var.location
  schema_validation_enabled = false
  tags                      = local.vm_tags_0

  body = {
    extendedLocation = {
      type = "CustomLocation"
      name = local.custom_location_id_0
    }
    properties = {
      ipConfigurations = [local.nic_ip_configuration_0]
    }
  }
}

resource "azapi_resource" "azure_local_data_disk_0" {
  for_each                  = local.create_data_volume_0 ? { enabled = true } : {}
  type                      = "Microsoft.AzureStackHCI/virtualHardDisks@2024-01-01"
  name                      = "${local.vm_name_0}-datadisk01_0"
  parent_id                 = data.azurerm_resource_group.azure_local_vm_deployment.id
  location                  = var.location
  schema_validation_enabled = false
  tags                      = local.vm_tags_0

  body = {
    extendedLocation = {
      type = "CustomLocation"
      name = local.custom_location_id_0
    }
    properties = {
      containerId      = local.storage_container_id_0
      diskSizeGB       = local.data_volume_size_gb_0
      dynamic          = true
      hyperVGeneration = "V2"
    }
  }
}

resource "azapi_resource" "azure_local_db_disk_0" {
  for_each                  = local.create_db_volume_0 ? { enabled = true } : {}
  type                      = "Microsoft.AzureStackHCI/virtualHardDisks@2024-01-01"
  name                      = "${local.vm_name_0}-dbdisk01_0"
  parent_id                 = data.azurerm_resource_group.azure_local_vm_deployment.id
  location                  = var.location
  schema_validation_enabled = false
  tags                      = local.vm_tags_0

  body = {
    extendedLocation = {
      type = "CustomLocation"
      name = local.custom_location_id_0
    }
    properties = {
      containerId      = local.storage_container_id_0
      diskSizeGB       = local.db_volume_size_gb_0
      dynamic          = true
      hyperVGeneration = "V2"
    }
  }
}

resource "azapi_resource" "azure_local_log_disk_0" {
  for_each                  = local.create_log_volume_0 ? { enabled = true } : {}
  type                      = "Microsoft.AzureStackHCI/virtualHardDisks@2024-01-01"
  name                      = "${local.vm_name_0}-logdisk01_0"
  parent_id                 = data.azurerm_resource_group.azure_local_vm_deployment.id
  location                  = var.location
  schema_validation_enabled = false
  tags                      = local.vm_tags_0

  body = {
    extendedLocation = {
      type = "CustomLocation"
      name = local.custom_location_id_0
    }
    properties = {
      containerId      = local.storage_container_id_0
      diskSizeGB       = local.log_volume_size_gb_0
      dynamic          = true
      hyperVGeneration = "V2"
    }
  }
}

resource "azapi_resource" "azure_local_virtual_machine_0" {
  type                      = "Microsoft.AzureStackHCI/virtualMachineInstances@2024-01-01"
  name                      = "default"
  parent_id                 = azapi_resource.arc_machine_0.id
  schema_validation_enabled = false

  body = {
    extendedLocation = {
      type = "CustomLocation"
      name = local.custom_location_id_0
    }
    properties = {
      hardwareProfile = {
        vmSize     = "Custom"
        processors = local.cpu_count_0
        memoryMB   = local.memory_mb_0
      }
      osProfile = {
        adminUsername        = local.admin_username_0
        adminPassword        = local.admin_password_0
        computerName         = local.vm_name_0
        windowsConfiguration = local.windows_configuration_0
      }
      storageProfile = local.vm_storage_profile_0
      networkProfile = {
        networkInterfaces = [
          {
            id = azapi_resource.azure_local_nic_0.id
          }
        ]
      }
      securityProfile = {
        enableTPM = true
        uefiSettings = {
          secureBootEnabled = true
        }
      }
    }
  }
}

output "azure_local_vm_id_0" {
  description = "Resource ID of the created Azure Local VM instance."
  value       = azapi_resource.azure_local_virtual_machine_0.id
}

output "azure_local_vm_nic_id_0" {
  description = "Resource ID of the created Azure Local NIC."
  value       = azapi_resource.azure_local_nic_0.id
}

output "azure_local_vm_data_disk_id_0" {
  description = "Resource ID of the optional Azure Local data disk."
  value       = try(azapi_resource.azure_local_data_disk_0["enabled"].id, null)
}

output "azure_local_vm_db_disk_id_0" {
  description = "Resource ID of the optional Azure Local DB disk."
  value       = try(azapi_resource.azure_local_db_disk_0["enabled"].id, null)
}

output "azure_local_vm_log_disk_id_0" {
  description = "Resource ID of the optional Azure Local log disk."
  value       = try(azapi_resource.azure_local_log_disk_0["enabled"].id, null)
}
