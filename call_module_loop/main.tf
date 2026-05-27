module "azure_local_vm" {
  source   = "../module_multiple"
  for_each = var.compute_nodes

  azure_local_resource_group_name = var.azure_local_resource_group_name
  location                        = var.location

  vm_name                = each.key
  custom_location_name   = var.custom_location_name
  logical_network_name   = var.logical_network_name
  image_name             = var.image_name
  image_resource_type    = var.image_resource_type
  storage_container_name = var.storage_container_name

  admin_username = var.admin_username
  admin_password = var.admin_password

  cpu_count            = each.value.processors
  memory_mb            = each.value.memory_mb
  data_volume1_size_gb = each.value.data_disk_1_size_gb
  data_volume2_size_gb = each.value.data_disk_2_size_gb
  data_volume3_size_gb = each.value.data_disk_3_size_gb
  static_ip_address    = each.value.private_ip
  windows_time_zone    = var.windows_time_zone

  arc_http_proxy_url  = var.arc_http_proxy_url
  arc_https_proxy_url = var.arc_https_proxy_url
  arc_no_proxy        = var.arc_no_proxy

  additional_tags = merge(var.additional_tags, each.value.tags)
  subscription_id = var.subscription_id
}
