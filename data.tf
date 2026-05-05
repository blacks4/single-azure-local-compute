data "azapi_client_config" "current" {}

data "azurerm_resource_group" "azure_local" {
  name = var.azure_local_resource_group_name
}

data "azurerm_resource_group" "azure_vm_inventory" {
  name = var.azure_vm_resource_group_name
}

locals {
  effective_image_resource_group_name = coalesce(var.image_resource_group_name, var.azure_local_resource_group_name)
}

data "azurerm_resource_group" "image_inventory" {
  name = local.effective_image_resource_group_name
}

data "azapi_resource_list" "resource_groups" {
  type      = "Microsoft.Resources/resourceGroups@2024-11-01"
  parent_id = "/subscriptions/${data.azapi_client_config.current.subscription_id}"

  response_export_values = {
    resource_groups = "value[].{name:name,id:id,location:location,tags:tags}"
  }
}

data "azapi_resource_list" "azure_virtual_machines" {
  type      = "Microsoft.Compute/virtualMachines@2024-11-01"
  parent_id = data.azurerm_resource_group.azure_vm_inventory.id

  response_export_values = {
    virtual_machines = "value[].{name:name,id:id,location:location,vmSize:properties.hardwareProfile.vmSize,osType:properties.storageProfile.osDisk.osType,provisioningState:properties.provisioningState}"
  }
}

data "azapi_resource_list" "azure_local_gallery_images" {
  type      = "Microsoft.AzureStackHCI/galleryImages@2024-01-01"
  parent_id = data.azurerm_resource_group.image_inventory.id

  response_export_values = {
    images = "value[].{name:name,id:id,location:location,osType:properties.osType,provisioningState:properties.provisioningState}"
  }
}

data "azapi_resource_list" "azure_local_marketplace_gallery_images" {
  type      = "Microsoft.AzureStackHCI/marketplaceGalleryImages@2024-01-01"
  parent_id = data.azurerm_resource_group.image_inventory.id

  response_export_values = {
    images = "value[].{name:name,id:id,location:location,provisioningState:properties.provisioningState}"
  }
}
