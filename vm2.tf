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
  data_volume_size_gb_2 = 0
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
  storage_container_id_2 = "/subscriptions/${local.normalized_subscription_id_2}/resourceGroups/${local.storage_container_resource_group_2}/providers/Microsoft.AzureStackHCI/storageContainers/${local.storage_container_name_2}"

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

  create_data_volume_2 = local.data_volume_size_gb_2 > 0

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
    local.create_data_volume_2 ? {
      dataDisks = [
        {
          id = azapi_resource.azure_local_data_disk_2["enabled"].id
        }
      ]
    } : {}
  )
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

resource "azapi_resource" "azure_local_data_disk_2" {
  for_each                  = local.create_data_volume_2 ? { enabled = true } : {}
  type                      = "Microsoft.AzureStackHCI/virtualHardDisks@2024-01-01"
  name                      = "${local.vm_name_2}-datadisk01_2"
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
      containerId      = local.storage_container_id_2
      diskSizeGB       = local.data_volume_size_gb_2
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
  description = "Resource ID of the optional Azure Local data disk."
  value       = try(azapi_resource.azure_local_data_disk_2["enabled"].id, null)
}
