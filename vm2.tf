locals {
  # Hardcoded VM-specific inputs for this file.
  vm_name_2                = ""
  custom_location_name_2   = ""
  logical_network_name_2   = ""
  image_name_2             = ""
  image_resource_type_2    = "galleryImages"
  storage_container_name_2 = ""

  admin_username_2      = "replace-me-admin"
  admin_password_2      = "replace-me-password"
  cpu_count_2           = 2
  memory_mb_2           = 8192
  data_volume1_size_gb_2 = 0
  data_volume2_size_gb_2 = 0
  data_volume3_size_gb_2 = 0
  static_ip_address_2   = ""
  windows_time_zone_2   = "Eastern Standard Time"
  # Optional proxy examples: http://proxy.company.local:8080, https://proxy.company.local:8443, ["127.0.0.1", ".company.local", "10.0.0.0/8"]
  arc_http_proxy_url_2  = ""
  arc_https_proxy_url_2 = ""
  arc_no_proxy_2        = []

  custom_location_resource_group_2   = var.azure_local_resource_group_name
  logical_network_resource_group_2   = var.azure_local_resource_group_name
  image_resource_group_2             = var.azure_local_resource_group_name
  storage_container_resource_group_2 = var.azure_local_resource_group_name

  normalized_subscription_id_2 = data.azapi_client_config.current.subscription_id

  custom_location_id_2   = "/subscriptions/${local.normalized_subscription_id_2}/resourceGroups/${local.custom_location_resource_group_2}/providers/Microsoft.ExtendedLocation/customLocations/${local.custom_location_name_2}"
  logical_network_id_2   = "/subscriptions/${local.normalized_subscription_id_2}/resourceGroups/${local.logical_network_resource_group_2}/providers/Microsoft.AzureStackHCI/logicalNetworks/${local.logical_network_name_2}"
  image_id_2             = "/subscriptions/${local.normalized_subscription_id_2}/resourceGroups/${local.image_resource_group_2}/providers/Microsoft.AzureStackHCI/${local.image_resource_type_2}/${local.image_name_2}"

  requested_storage_container_name_2 = try(trimspace(local.storage_container_name_2), "") != "" ? trimspace(local.storage_container_name_2) : null
  discovered_storage_containers_2    = try(data.azapi_resource_list.storage_containers_2.output.storage_containers, [])

  discovered_storage_containers_for_scope_2 = [
    for storage_container in local.discovered_storage_containers_2 : storage_container
    if lower(try(storage_container.extendedLocationName, "")) == lower(local.custom_location_id_2)
  ]

  auto_selected_storage_container_name_2 = length(local.discovered_storage_containers_for_scope_2) > 0 ? sort([
    for storage_container in local.discovered_storage_containers_for_scope_2 : storage_container.name
  ])[0] : null

  effective_storage_container_name_2 = local.requested_storage_container_name_2 != null ? local.requested_storage_container_name_2 : local.auto_selected_storage_container_name_2
  storage_container_id_2             = local.effective_storage_container_name_2 != null ? "/subscriptions/${local.normalized_subscription_id_2}/resourceGroups/${local.storage_container_resource_group_2}/providers/Microsoft.AzureStackHCI/storageContainers/${local.effective_storage_container_name_2}" : null

  storage_selection_valid_2 = local.effective_storage_container_name_2 != null

  storage_selection_message_2 = "No storage containers were discovered for custom location ${local.custom_location_id_2} in resource group ${local.storage_container_resource_group_2}. Set storage_container_name_2 explicitly or verify storage containers for this custom location."

  vm_tags_2 = merge(
    {
      managed_by = "terraform"
      workload   = "azure-local-vm"
    },
    var.additional_tags
  )

  nic_ip_configuration_2 = {
    name = "ipconfig1"
    properties = {
      subnet = {
        id = local.logical_network_id_2
      }
      privateIPAddress = trimspace(local.static_ip_address_2)
    }
  }

  windows_configuration_2 = {
    enableAutomaticUpdates = true
    provisionVMAgent       = true
    provisionVMConfigAgent = true
    timeZone               = local.windows_time_zone_2
  }

  normalized_arc_http_proxy_url_2  = try(trimspace(local.arc_http_proxy_url_2), "") != "" ? trimspace(local.arc_http_proxy_url_2) : null
  normalized_arc_https_proxy_url_2 = try(trimspace(local.arc_https_proxy_url_2), "") != "" ? trimspace(local.arc_https_proxy_url_2) : null
  include_http_proxy_config_2      = local.normalized_arc_http_proxy_url_2 != null || local.normalized_arc_https_proxy_url_2 != null || length(local.arc_no_proxy_2) > 0

  data_volume_sizes_gb_2 = {
    data_volume1 = local.data_volume1_size_gb_2
    data_volume2 = local.data_volume2_size_gb_2
    data_volume3 = local.data_volume3_size_gb_2
  }

  enabled_data_volumes_2 = {
    for volume_name, volume_size_gb in local.data_volume_sizes_gb_2 : volume_name => volume_size_gb
    if volume_size_gb > 0
  }

  vm_data_disks_2 = [
    for volume_name in sort(keys(local.enabled_data_volumes_2)) : {
      id = azapi_resource.azure_local_data_disks_2[volume_name].id
    }
  ]

  vm_storage_profile_2 = merge(
    {
      imageReference = {
        id = local.image_id_2
      }
      osDisk = {
        osType = "Windows"
      }
      vmConfigStoragePathId = local.storage_container_id_2
    },
    length(local.vm_data_disks_2) > 0 ? {
      dataDisks = local.vm_data_disks_2
    } : {}
  )
}

data "azapi_resource_list" "storage_containers_2" {
  type      = "Microsoft.AzureStackHCI/storageContainers@2024-01-01"
  parent_id = "/subscriptions/${local.normalized_subscription_id_2}/resourceGroups/${local.storage_container_resource_group_2}"

  response_export_values = {
    storage_containers = "value[].{name:name,id:id,extendedLocationName:extendedLocation.name}"
  }
}

resource "azapi_resource" "arc_machine_2" {
  type      = "Microsoft.HybridCompute/machines@2024-07-10"
  name      = local.vm_name_2
  parent_id = data.azurerm_resource_group.azure_local_vm_deployment.id
  location  = var.location
  tags      = local.vm_tags_2

  identity {
    type = "SystemAssigned"
  }

  body = {
    kind = "HCI"
  }
}

resource "azapi_resource" "azure_local_nic_2" {
  type                      = "Microsoft.AzureStackHCI/networkInterfaces@2024-01-01"
  name                      = "${local.vm_name_2}-nic"
  parent_id                 = data.azurerm_resource_group.azure_local_vm_deployment.id
  location                  = var.location
  schema_validation_enabled = false
  tags                      = local.vm_tags_2

  body = {
    extendedLocation = {
      type = "CustomLocation"
      name = local.custom_location_id_2
    }
    properties = {
      ipConfigurations = [local.nic_ip_configuration_2]
    }
  }
}

resource "azapi_resource" "azure_local_data_disks_2" {
  for_each                  = local.enabled_data_volumes_2
  type                      = "Microsoft.AzureStackHCI/virtualHardDisks@2024-01-01"
  name                      = "${local.vm_name_2}-${replace(each.key, "_", "-")}-2"
  parent_id                 = data.azurerm_resource_group.azure_local_vm_deployment.id
  location                  = var.location
  schema_validation_enabled = false
  tags                      = local.vm_tags_2

  lifecycle {
    precondition {
      condition     = local.storage_selection_valid_2
      error_message = local.storage_selection_message_2
    }
  }

  body = {
    extendedLocation = {
      type = "CustomLocation"
      name = local.custom_location_id_2
    }
    properties = {
      containerId      = local.storage_container_id_2
      diskSizeGB       = each.value
      dynamic          = true
      hyperVGeneration = "V2"
    }
  }
}

resource "azapi_resource" "azure_local_virtual_machine_2" {
  type                      = "Microsoft.AzureStackHCI/virtualMachineInstances@2024-01-01"
  name                      = "default"
  parent_id                 = azapi_resource.arc_machine_2.id
  schema_validation_enabled = false

  lifecycle {
    precondition {
      condition     = local.storage_selection_valid_2
      error_message = local.storage_selection_message_2
    }
  }

  body = {
    extendedLocation = {
      type = "CustomLocation"
      name = local.custom_location_id_2
    }
    properties = merge({
      hardwareProfile = {
        vmSize     = "Custom"
        processors = local.cpu_count_2
        memoryMB   = local.memory_mb_2
      }
      osProfile = {
        adminUsername        = local.admin_username_2
        adminPassword        = local.admin_password_2
        computerName         = local.vm_name_2
        windowsConfiguration = local.windows_configuration_2
      }
      storageProfile = local.vm_storage_profile_2
      networkProfile = {
        networkInterfaces = [
          {
            id = azapi_resource.azure_local_nic_2.id
          }
        ]
      }
      securityProfile = {
        enableTPM = true
        uefiSettings = {
          secureBootEnabled = true
        }
      }
    }, local.include_http_proxy_config_2 ? {
      httpProxyConfig = merge(
        local.normalized_arc_http_proxy_url_2 != null ? {
          httpProxy = local.normalized_arc_http_proxy_url_2
        } : {},
        local.normalized_arc_https_proxy_url_2 != null ? {
          httpsProxy = local.normalized_arc_https_proxy_url_2
        } : {},
        length(local.arc_no_proxy_2) > 0 ? {
          noProxy = local.arc_no_proxy_2
        } : {}
      )
    } : {})
  }
}

output "azure_local_vm_id_2" {
  description = "Resource ID of the created Azure Local VM instance."
  value       = azapi_resource.azure_local_virtual_machine_2.id
}

output "azure_local_vm_nic_id_2" {
  description = "Resource ID of the created Azure Local NIC."
  value       = azapi_resource.azure_local_nic_2.id
}

output "azure_local_vm_data_disk_id_2" {
  description = "Resource IDs of optional Azure Local data disks keyed by volume name."
  value       = { for volume_name, disk in azapi_resource.azure_local_data_disks_2 : volume_name => disk.id }
}
