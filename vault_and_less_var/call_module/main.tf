ephemeral "vault_kv_secret_v2" "vm_admin_credentials" {
  mount = var.vault_settings.kv2_mount
  name  = var.vault_settings.kv2_secret_path
}

module "azure_local_vm" {
  source   = "../module"
  for_each = var.compute_nodes

  azure_local_resource_group_name = var.global_settings.azure_local_resource_group_name
  location                        = var.global_settings.location
  site_type                       = var.global_settings.site_type

  vm_name                = each.key
  ad_domain              = each.value.ad_domain
  custom_location_name   = var.global_settings.custom_location_name
  logical_network_name   = var.global_settings.logical_network_name
  image_name             = var.global_settings.image_name
  image_resource_type    = var.global_settings.image_resource_type
  storage_container_name = var.global_settings.storage_container_name

  admin_username = tostring(ephemeral.vault_kv_secret_v2.vm_admin_credentials.data[var.vault_settings.admin_username_key])
  admin_password = tostring(ephemeral.vault_kv_secret_v2.vm_admin_credentials.data[var.vault_settings.admin_password_key])

  cpu_count            = each.value.processors
  memory_mb            = each.value.memory_mb
  data_volume1_size_gb = each.value.data_disk_1_size_gb
  data_volume2_size_gb = each.value.data_disk_2_size_gb
  data_volume3_size_gb = each.value.data_disk_3_size_gb
  static_ip_address    = each.value.private_ip
  windows_time_zone    = var.global_settings.windows_time_zone

  arc_http_proxy_url  = var.global_settings.arc_http_proxy_url
  arc_https_proxy_url = var.global_settings.arc_https_proxy_url
  arc_no_proxy        = var.global_settings.arc_no_proxy

  additional_tags = merge(var.global_settings.additional_tags, each.value.tags)
  subscription_id = var.global_settings.subscription_id

  global_extensions = var.global_extensions
}
