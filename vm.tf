variable "create_vm" {
  description = "Whether to create a single Azure Local Windows VM."
  type        = bool
  default     = false
}

variable "subscription_id" {
  description = "Optional subscription ID override. Defaults to the active Azure CLI / provider context subscription."
  type        = string
  default     = null
}

variable "location" {
  description = "Azure region for Azure Local control-plane resources."
  type        = string
  default     = null
}

variable "vm_name" {
  description = "Name of the Azure Local VM and backing Arc machine."
  type        = string
  default     = null
}

variable "custom_location_name" {
  description = "Name of the Azure Local custom location."
  type        = string
  default     = null
}

variable "custom_location_resource_group_name" {
  description = "Optional resource group for the custom location. Defaults to azure_local_resource_group_name."
  type        = string
  default     = null
}

variable "logical_network_name" {
  description = "Name of the Azure Local logical network."
  type        = string
  default     = null
}

variable "logical_network_resource_group_name" {
  description = "Optional resource group for the logical network. Defaults to azure_local_resource_group_name."
  type        = string
  default     = null
}

variable "image_name" {
  description = "Name of the Azure Local image."
  type        = string
  default     = null
}

variable "image_resource_group_name" {
  description = "Optional resource group for the Azure Local image. Defaults to azure_local_resource_group_name."
  type        = string
  default     = null
}

variable "image_resource_type" {
  description = "Image resource type under Microsoft.AzureStackHCI."
  type        = string
  default     = "marketplaceGalleryImages"
}

variable "storage_container_name" {
  description = "Optional name of the Azure Local storage container for VM configuration and disks. If omitted and exactly one container exists in scope, Terraform selects it automatically."
  type        = string
  default     = null
}

variable "storage_container_resource_group_name" {
  description = "Optional resource group for the storage container. Defaults to azure_local_resource_group_name."
  type        = string
  default     = null
}

variable "admin_username" {
  description = "Windows administrator username."
  type        = string
  default     = null
}

variable "admin_password" {
  description = "Windows administrator password."
  type        = string
  sensitive   = true
  default     = null
}

variable "cpu_count" {
  description = "Number of vCPUs for the VM."
  type        = number
  default     = 2
}

variable "memory_mb" {
  description = "Fixed RAM allocation in MB."
  type        = number
  default     = 8192
}

variable "static_ip_address" {
  description = "Optional static private IP address. Leave null for DHCP."
  type        = string
  default     = null
}

variable "c_drive_size_gb" {
  description = "Windows C: drive size in GB."
  type        = number
  default     = 127
}

variable "enable_d_drive" {
  description = "Whether to create and attach an additional data disk for a D: drive."
  type        = bool
  default     = false
}

variable "d_drive_size_gb" {
  description = "Size of the optional D: drive in GB."
  type        = number
  default     = 128
}

variable "windows_time_zone" {
  description = "Optional Windows time zone ID."
  type        = string
  default     = "Eastern Standard Time"
}

variable "additional_tags" {
  description = "Additional tags to apply to all created Azure Local VM resources."
  type        = map(string)
  default     = {}
}

locals {
  vm_enabled = var.create_vm

  normalized_subscription_id = var.subscription_id != null && trimspace(var.subscription_id) != "" ? trimspace(var.subscription_id) : data.azapi_client_config.current.subscription_id

  normalized_custom_location_resource_group_name   = var.custom_location_resource_group_name != null && trimspace(var.custom_location_resource_group_name) != "" ? trimspace(var.custom_location_resource_group_name) : var.azure_local_resource_group_name
  normalized_logical_network_resource_group_name   = var.logical_network_resource_group_name != null && trimspace(var.logical_network_resource_group_name) != "" ? trimspace(var.logical_network_resource_group_name) : var.azure_local_resource_group_name
  normalized_image_resource_group_name             = var.image_resource_group_name != null && trimspace(var.image_resource_group_name) != "" ? trimspace(var.image_resource_group_name) : var.azure_local_resource_group_name
  normalized_storage_container_resource_group_name = var.storage_container_resource_group_name != null && trimspace(var.storage_container_resource_group_name) != "" ? trimspace(var.storage_container_resource_group_name) : var.azure_local_resource_group_name

  custom_location_id               = local.normalized_custom_location_resource_group_name != null && var.custom_location_name != null && trimspace(var.custom_location_name) != "" ? "/subscriptions/${local.normalized_subscription_id}/resourceGroups/${local.normalized_custom_location_resource_group_name}/providers/Microsoft.ExtendedLocation/customLocations/${trimspace(var.custom_location_name)}" : null
  logical_network_id               = local.normalized_logical_network_resource_group_name != null && var.logical_network_name != null && trimspace(var.logical_network_name) != "" ? "/subscriptions/${local.normalized_subscription_id}/resourceGroups/${local.normalized_logical_network_resource_group_name}/providers/Microsoft.AzureStackHCI/logicalNetworks/${trimspace(var.logical_network_name)}" : null
  image_id                         = local.normalized_image_resource_group_name != null && var.image_name != null && trimspace(var.image_name) != "" ? "/subscriptions/${local.normalized_subscription_id}/resourceGroups/${local.normalized_image_resource_group_name}/providers/Microsoft.AzureStackHCI/${var.image_resource_type}/${trimspace(var.image_name)}" : null
  requested_storage_container_name = var.storage_container_name != null && trimspace(var.storage_container_name) != "" ? trimspace(var.storage_container_name) : null
  discovered_storage_containers    = try(data.azapi_resource_list.azure_local_storage_containers[0].output.storage_containers, [])
  discovered_storage_container_names = [
    for container in local.discovered_storage_containers : container.name
  ]
  auto_selected_storage_container_name = length(local.discovered_storage_containers) == 1 ? local.discovered_storage_containers[0].name : null
  effective_storage_container_name     = local.requested_storage_container_name != null ? local.requested_storage_container_name : local.auto_selected_storage_container_name
  storage_container_id                 = local.normalized_storage_container_resource_group_name != null && local.effective_storage_container_name != null ? "/subscriptions/${local.normalized_subscription_id}/resourceGroups/${local.normalized_storage_container_resource_group_name}/providers/Microsoft.AzureStackHCI/storageContainers/${local.effective_storage_container_name}" : null

  vm_tags = merge(
    {
      managed_by = "terraform"
      workload   = "azure-local-vm"
    },
    var.additional_tags
  )

  missing_vm_inputs = local.vm_enabled ? compact([
    var.azure_local_resource_group_name == null || trimspace(var.azure_local_resource_group_name) == "" ? "azure_local_resource_group_name" : null,
    var.location == null || trimspace(var.location) == "" ? "location" : null,
    var.vm_name == null || trimspace(var.vm_name) == "" ? "vm_name" : null,
    local.custom_location_id == null ? "custom_location_name" : null,
    local.logical_network_id == null ? "logical_network_name" : null,
    local.image_id == null ? "image_name" : null,
    var.admin_username == null || trimspace(var.admin_username) == "" ? "admin_username" : null,
    var.admin_password == null || trimspace(var.admin_password) == "" ? "admin_password" : null,
  ]) : []

  vm_precondition_message                = "Missing required VM inputs: ${join(", ", local.missing_vm_inputs)}"
  storage_container_precondition_message = local.requested_storage_container_name == null && length(local.discovered_storage_containers) > 1 ? "Multiple Azure Local storage containers were found in resource group ${local.normalized_storage_container_resource_group_name}. Set storage_container_name to one of: ${join(", ", local.discovered_storage_container_names)}" : "No Azure Local storage containers were found in resource group ${local.normalized_storage_container_resource_group_name}."

  nic_ip_configuration = {
    name = "ipconfig1"
    properties = merge(
      {
        subnet = {
          id = local.logical_network_id
        }
      },
      var.static_ip_address == null || trimspace(var.static_ip_address) == "" ? {} : {
        privateIPAddress = trimspace(var.static_ip_address)
      }
    )
  }

  windows_configuration = {
    enableAutomaticUpdates = true
    provisionVMAgent       = true
    provisionVMConfigAgent = true
    timeZone               = var.windows_time_zone
  }

  vm_storage_profile = local.vm_enabled ? merge(
    {
      osDisk = {
        id     = azapi_resource.azure_local_os_disk[0].id
        osType = "Windows"
      }
      vmConfigStoragePathId = local.storage_container_id
    },
    var.enable_d_drive ? {
      dataDisks = [
        {
          id = azapi_resource.azure_local_data_disk[0].id
        }
      ]
    } : {}
  ) : null
}

data "azurerm_resource_group" "azure_local_vm_deployment" {
  count = local.vm_enabled ? 1 : 0
  name  = var.azure_local_resource_group_name
}

data "azapi_resource_list" "azure_local_storage_containers" {
  count     = local.vm_enabled && local.normalized_storage_container_resource_group_name != null ? 1 : 0
  type      = "Microsoft.AzureStackHCI/storageContainers@2024-01-01"
  parent_id = "/subscriptions/${local.normalized_subscription_id}/resourceGroups/${local.normalized_storage_container_resource_group_name}"

  response_export_values = {
    storage_containers = "value[].{name:name,id:id}"
  }
}

resource "azapi_resource" "azure_local_os_disk" {
  count                     = local.vm_enabled ? 1 : 0
  type                      = "Microsoft.AzureStackHCI/virtualHardDisks@2026-02-01-preview"
  name                      = "${var.vm_name}-osdisk"
  parent_id                 = data.azurerm_resource_group.azure_local_vm_deployment[0].id
  location                  = var.location
  schema_validation_enabled = false
  tags                      = local.vm_tags

  lifecycle {
    precondition {
      condition     = length(local.missing_vm_inputs) == 0
      error_message = local.vm_precondition_message
    }
    precondition {
      condition     = local.requested_storage_container_name != null || length(local.discovered_storage_containers) == 1
      error_message = local.storage_container_precondition_message
    }
  }

  body = {
    extendedLocation = {
      type = "CustomLocation"
      name = local.custom_location_id
    }
    properties = {
      containerId      = local.storage_container_id
      createFromLocal  = false
      diskFileFormat   = "vhdx"
      diskSizeGB       = var.c_drive_size_gb
      dynamic          = false
      hyperVGeneration = "V2"
      creationData = {
        createOption     = "Copy"
        sourceResourceId = local.image_id
      }
    }
  }
}

resource "azapi_resource" "azure_local_data_disk" {
  count                     = local.vm_enabled && var.enable_d_drive ? 1 : 0
  type                      = "Microsoft.AzureStackHCI/virtualHardDisks@2026-02-01-preview"
  name                      = "${var.vm_name}-datadisk01"
  parent_id                 = data.azurerm_resource_group.azure_local_vm_deployment[0].id
  location                  = var.location
  schema_validation_enabled = false
  tags                      = local.vm_tags

  lifecycle {
    precondition {
      condition     = length(local.missing_vm_inputs) == 0
      error_message = local.vm_precondition_message
    }
    precondition {
      condition     = local.requested_storage_container_name != null || length(local.discovered_storage_containers) == 1
      error_message = local.storage_container_precondition_message
    }
  }

  body = {
    extendedLocation = {
      type = "CustomLocation"
      name = local.custom_location_id
    }
    properties = {
      containerId      = local.storage_container_id
      createFromLocal  = false
      diskFileFormat   = "vhdx"
      diskSizeGB       = var.d_drive_size_gb
      dynamic          = false
      hyperVGeneration = "V2"
      creationData = {
        createOption = "Empty"
      }
    }
  }
}

resource "azapi_resource" "arc_machine" {
  count     = local.vm_enabled ? 1 : 0
  type      = "Microsoft.HybridCompute/machines@2024-07-10"
  name      = var.vm_name
  parent_id = data.azurerm_resource_group.azure_local_vm_deployment[0].id
  location  = var.location
  tags      = local.vm_tags

  lifecycle {
    precondition {
      condition     = length(local.missing_vm_inputs) == 0
      error_message = local.vm_precondition_message
    }
    precondition {
      condition     = local.requested_storage_container_name != null || length(local.discovered_storage_containers) == 1
      error_message = local.storage_container_precondition_message
    }
  }

  identity {
    type = "SystemAssigned"
  }

  body = {
    kind = "HCI"
  }
}

resource "azapi_resource" "azure_local_nic" {
  count                     = local.vm_enabled ? 1 : 0
  type                      = "Microsoft.AzureStackHCI/networkInterfaces@2024-01-01"
  name                      = "nic-${var.vm_name}"
  parent_id                 = data.azurerm_resource_group.azure_local_vm_deployment[0].id
  location                  = var.location
  schema_validation_enabled = false
  tags                      = local.vm_tags

  lifecycle {
    precondition {
      condition     = length(local.missing_vm_inputs) == 0
      error_message = local.vm_precondition_message
    }
    precondition {
      condition     = local.requested_storage_container_name != null || length(local.discovered_storage_containers) == 1
      error_message = local.storage_container_precondition_message
    }
  }

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

resource "azapi_resource" "azure_local_virtual_machine" {
  count                     = local.vm_enabled ? 1 : 0
  type                      = "Microsoft.AzureStackHCI/virtualMachineInstances@2024-01-01"
  name                      = "default"
  parent_id                 = azapi_resource.arc_machine[0].id
  schema_validation_enabled = false

  lifecycle {
    precondition {
      condition     = length(local.missing_vm_inputs) == 0
      error_message = local.vm_precondition_message
    }
    precondition {
      condition     = local.requested_storage_container_name != null || length(local.discovered_storage_containers) == 1
      error_message = local.storage_container_precondition_message
    }
  }

  body = {
    extendedLocation = {
      type = "CustomLocation"
      name = local.custom_location_id
    }
    properties = {
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
            id = azapi_resource.azure_local_nic[0].id
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

output "azure_local_vm_id" {
  description = "Resource ID of the created Azure Local VM instance."
  value       = try(azapi_resource.azure_local_virtual_machine[0].id, null)
}

output "azure_local_vm_os_disk_id" {
  description = "Resource ID of the created Azure Local OS disk."
  value       = try(azapi_resource.azure_local_os_disk[0].id, null)
}

output "azure_local_vm_data_disk_id" {
  description = "Resource ID of the optional Azure Local data disk."
  value       = try(azapi_resource.azure_local_data_disk[0].id, null)
}

output "azure_local_vm_nic_id" {
  description = "Resource ID of the created Azure Local NIC."
  value       = try(azapi_resource.azure_local_nic[0].id, null)
}
