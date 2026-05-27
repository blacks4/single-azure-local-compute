# Azure Local VM Module

This module creates one Azure Local Windows VM (Arc machine, NIC, VM instance, and optional data disks).

## Repeatable Usage Example

Use `for_each` to call the module repeatedly for multiple VMs.

```hcl
locals {
  vms = {
    vm01 = {
      vm_name                  = "vm01"
      custom_location_name     = "my-custom-location"
      logical_network_name     = "my-logical-network"
      image_name               = "my-image"
      admin_username           = "localadmin"
      admin_password           = "replace-me"
      cpu_count                = 4
      memory_mb                = 16384
      data_volume1_size_gb     = 128
      data_volume2_size_gb     = 0
      data_volume3_size_gb     = 0
      static_ip_address        = null
      storage_container_name   = null
      windows_time_zone        = "Eastern Standard Time"
      arc_http_proxy_url       = null
      arc_https_proxy_url      = null
      arc_no_proxy             = []
      additional_tags          = { environment = "dev" }
      image_resource_type      = "galleryimages"
      subscription_id          = null
    }
  }
}

module "azure_local_vm" {
  source   = "./module"
  for_each = local.vms

  azure_local_resource_group_name = var.azure_local_resource_group_name
  location                        = var.location

  vm_name                = each.value.vm_name
  custom_location_name   = each.value.custom_location_name
  logical_network_name   = each.value.logical_network_name
  image_name             = each.value.image_name
  image_resource_type    = each.value.image_resource_type
  admin_username         = each.value.admin_username
  admin_password         = each.value.admin_password
  cpu_count              = each.value.cpu_count
  memory_mb              = each.value.memory_mb
  data_volume1_size_gb   = each.value.data_volume1_size_gb
  data_volume2_size_gb   = each.value.data_volume2_size_gb
  data_volume3_size_gb   = each.value.data_volume3_size_gb
  static_ip_address      = each.value.static_ip_address
  storage_container_name = each.value.storage_container_name
  windows_time_zone      = each.value.windows_time_zone
  arc_http_proxy_url     = each.value.arc_http_proxy_url
  arc_https_proxy_url    = each.value.arc_https_proxy_url
  arc_no_proxy           = each.value.arc_no_proxy
  additional_tags        = each.value.additional_tags
  subscription_id        = each.value.subscription_id
}
```