locals {
  # Hardcoded VM-specific inputs for this file.
  vm_name_3                = ""
  custom_location_name_3   = ""
  logical_network_name_3   = ""
  image_name_3             = ""
  image_resource_type_3    = "galleryimages"
  storage_container_name_3 = ""

  admin_username_3       = "replace-me-admin"
  admin_password_3       = "replace-me-password"
  cpu_count_3            = 2
  memory_mb_3            = 8192
  data_volume1_size_gb_3 = 0
  data_volume2_size_gb_3 = 0
  data_volume3_size_gb_3 = 0
  static_ip_address_3    = ""
  windows_time_zone_3    = "Eastern Standard Time"

  # Optional proxy examples: http://proxy.company.local:8080, https://proxy.company.local:8443, ["127.0.0.1", ".company.local", "10.0.0.0/8"]
  arc_http_proxy_url_3  = ""
  arc_https_proxy_url_3 = ""
  arc_no_proxy_3        = []
}

module "azure_local_vm_3" {
  source = "./module"

  azure_local_resource_group_name = var.azure_local_resource_group_name
  location                        = var.location

  vm_name                = local.vm_name_3
  custom_location_name   = local.custom_location_name_3
  logical_network_name   = local.logical_network_name_3
  image_name             = local.image_name_3
  image_resource_type    = local.image_resource_type_3
  storage_container_name = local.storage_container_name_3

  admin_username = local.admin_username_3
  admin_password = local.admin_password_3

  cpu_count            = local.cpu_count_3
  memory_mb            = local.memory_mb_3
  data_volume1_size_gb = local.data_volume1_size_gb_3
  data_volume2_size_gb = local.data_volume2_size_gb_3
  data_volume3_size_gb = local.data_volume3_size_gb_3
  static_ip_address    = local.static_ip_address_3
  windows_time_zone    = local.windows_time_zone_3

  arc_http_proxy_url  = local.arc_http_proxy_url_3
  arc_https_proxy_url = local.arc_https_proxy_url_3
  arc_no_proxy        = local.arc_no_proxy_3

  additional_tags = var.additional_tags
  subscription_id = var.subscription_id
}