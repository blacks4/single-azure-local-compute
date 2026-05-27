data "azapi_client_config" "current" {}

data "azurerm_resource_group" "azure_local_vm_deployment" {
  name = var.azure_local_resource_group_name
}

locals {
  normalized_subscription_id = try(trimspace(var.subscription_id), "") != "" ? trimspace(var.subscription_id) : data.azapi_client_config.current.subscription_id

  custom_location_id = "/subscriptions/${local.normalized_subscription_id}/resourceGroups/${var.azure_local_resource_group_name}/providers/Microsoft.ExtendedLocation/customLocations/${var.custom_location_name}"
  logical_network_id = "/subscriptions/${local.normalized_subscription_id}/resourceGroups/${var.azure_local_resource_group_name}/providers/Microsoft.AzureStackHCI/logicalNetworks/${var.logical_network_name}"
  image_id           = "/subscriptions/${local.normalized_subscription_id}/resourceGroups/${var.azure_local_resource_group_name}/providers/microsoft.azurestackhci/${var.image_resource_type}/${var.image_name}"

  requested_storage_container_name = try(trimspace(var.storage_container_name), "") != "" ? trimspace(var.storage_container_name) : null
  discovered_storage_containers    = try(data.azapi_resource_list.storage_containers.output.storage_containers, [])

  discovered_storage_containers_for_scope = [
    for storage_container in local.discovered_storage_containers : storage_container
    if lower(try(storage_container.extendedLocationName, "")) == lower(local.custom_location_id)
  ]

  auto_selected_storage_container_name = length(local.discovered_storage_containers_for_scope) > 0 ? sort([
    for storage_container in local.discovered_storage_containers_for_scope : storage_container.name
  ])[0] : null

  effective_storage_container_name = local.requested_storage_container_name != null ? local.requested_storage_container_name : local.auto_selected_storage_container_name
  storage_container_id             = local.effective_storage_container_name != null ? "/subscriptions/${local.normalized_subscription_id}/resourceGroups/${var.azure_local_resource_group_name}/providers/Microsoft.AzureStackHCI/storageContainers/${local.effective_storage_container_name}" : null

  storage_selection_valid = local.effective_storage_container_name != null

  storage_selection_message = "No storage containers were discovered for custom location ${local.custom_location_id} in resource group ${var.azure_local_resource_group_name}. Set storage_container_name explicitly or verify storage containers for this custom location."

  vm_tags = merge(
    {
      managed_by = "terraform"
      workload   = "azure-local-vm"
    },
    var.additional_tags
  )

  nic_ip_configuration = {
    name = "ipconfig1"
    properties = merge(
      {
        subnet = {
          id = local.logical_network_id
        }
      },
      try(trimspace(var.static_ip_address), "") != "" ? {
        privateIPAddress = trimspace(var.static_ip_address)
      } : {}
    )
  }

  windows_configuration = {
    enableAutomaticUpdates = true
    provisionVMAgent       = true
    provisionVMConfigAgent = true
    timeZone               = var.windows_time_zone
  }

  normalized_arc_http_proxy_url  = try(trimspace(var.arc_http_proxy_url), "") != "" ? trimspace(var.arc_http_proxy_url) : null
  normalized_arc_https_proxy_url = try(trimspace(var.arc_https_proxy_url), "") != "" ? trimspace(var.arc_https_proxy_url) : null
  include_http_proxy_config      = local.normalized_arc_http_proxy_url != null || local.normalized_arc_https_proxy_url != null || length(var.arc_no_proxy) > 0

  data_volume_sizes_gb = {
    data_volume1 = var.data_volume1_size_gb
    data_volume2 = var.data_volume2_size_gb
    data_volume3 = var.data_volume3_size_gb
  }

  enabled_data_volumes = {
    for volume_name, volume_size_gb in local.data_volume_sizes_gb : volume_name => volume_size_gb
    if volume_size_gb > 0
  }

  vm_data_disks = [
    for volume_name in sort(keys(local.enabled_data_volumes)) : {
      id = azapi_resource.azure_local_data_disks[volume_name].id
    }
  ]

  vm_storage_profile = merge(
    {
      imageReference = {
        id = local.image_id
      }
      osDisk = {
        osType = "Windows"
      }
      vmConfigStoragePathId = local.storage_container_id
    },
    length(local.vm_data_disks) > 0 ? {
      dataDisks = local.vm_data_disks
    } : {}
  )
}

data "azapi_resource_list" "storage_containers" {
  type      = "Microsoft.AzureStackHCI/storageContainers@2024-01-01"
  parent_id = "/subscriptions/${local.normalized_subscription_id}/resourceGroups/${var.azure_local_resource_group_name}"

  response_export_values = {
    storage_containers = "value[].{name:name,id:id,extendedLocationName:extendedLocation.name}"
  }
}

resource "azapi_resource" "arc_machine" {
  type      = "Microsoft.HybridCompute/machines@2024-07-10"
  name      = var.vm_name
  parent_id = data.azurerm_resource_group.azure_local_vm_deployment.id
  location  = var.location
  tags      = local.vm_tags

  identity {
    type = "SystemAssigned"
  }

  body = {
    kind = "HCI"
  }
}

resource "azapi_resource" "azure_local_nic" {
  type                      = "Microsoft.AzureStackHCI/networkInterfaces@2024-01-01"
  name                      = "${var.vm_name}-nic"
  parent_id                 = data.azurerm_resource_group.azure_local_vm_deployment.id
  location                  = var.location
  schema_validation_enabled = false
  tags                      = local.vm_tags

  body = {
    extendedLocation = {
      type = "CustomLocation"
      name = local.custom_location_id
    }
    properties = {
      ipConfigurations = [local.nic_ip_configuration]
    }
  }
}

resource "azapi_resource" "azure_local_data_disks" {
  for_each                  = local.enabled_data_volumes
  type                      = "Microsoft.AzureStackHCI/virtualHardDisks@2024-01-01"
  name                      = "${var.vm_name}-${replace(each.key, "_", "-")}"
  parent_id                 = data.azurerm_resource_group.azure_local_vm_deployment.id
  location                  = var.location
  schema_validation_enabled = false
  tags                      = local.vm_tags

  lifecycle {
    precondition {
      condition     = local.storage_selection_valid
      error_message = local.storage_selection_message
    }
  }

  body = {
    extendedLocation = {
      type = "CustomLocation"
      name = local.custom_location_id
    }
    properties = {
      containerId      = local.storage_container_id
      diskSizeGB       = each.value
      dynamic          = false
      hyperVGeneration = "V2"
    }
  }
}

resource "azapi_resource" "azure_local_virtual_machine" {
  type                      = "Microsoft.AzureStackHCI/virtualMachineInstances@2024-01-01"
  name                      = "default"
  parent_id                 = azapi_resource.arc_machine.id
  schema_validation_enabled = false

  lifecycle {
    precondition {
      condition     = local.storage_selection_valid
      error_message = local.storage_selection_message
    }
  }

  body = {
    extendedLocation = {
      type = "CustomLocation"
      name = local.custom_location_id
    }
    properties = merge({
      hardwareProfile = {
        vmSize     = "Custom"
        processors = var.cpu_count
        memoryMB   = var.memory_mb
      }
      osProfile = {
        adminUsername        = var.admin_username
        adminPassword        = var.admin_password
        computerName         = var.vm_name
        windowsConfiguration = local.windows_configuration
      }
      storageProfile = local.vm_storage_profile
      networkProfile = {
        networkInterfaces = [
          {
            id = azapi_resource.azure_local_nic.id
          }
        ]
      }
      securityProfile = {
        enableTPM = true
        uefiSettings = {
          secureBootEnabled = true
        }
      }
      }, local.include_http_proxy_config ? {
      httpProxyConfig = merge(
        local.normalized_arc_http_proxy_url != null ? {
          httpProxy = local.normalized_arc_http_proxy_url
        } : {},
        local.normalized_arc_https_proxy_url != null ? {
          httpsProxy = local.normalized_arc_https_proxy_url
        } : {},
        length(var.arc_no_proxy) > 0 ? {
          noProxy = var.arc_no_proxy
        } : {}
      )
    } : {})
  }
}