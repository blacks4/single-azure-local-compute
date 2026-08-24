variable "global_settings" {
  description = "Settings shared by all Azure Local VMs."
  type = object({
    azure_local_resource_group_name = string
    location                        = string
    subscription_id                 = string
    site_type                       = string

    custom_location_name   = string
    logical_network_name   = string
    image_name             = string
    image_resource_type    = optional(string, "galleryimages")
    storage_container_name = optional(string)

    windows_time_zone   = optional(string, "Eastern Standard Time")
    arc_http_proxy_url  = optional(string)
    arc_https_proxy_url = optional(string)
    arc_no_proxy        = optional(list(string), [])
    additional_tags     = optional(map(string), {})
  })

  validation {
    condition     = contains(["battery", "battery-solar", "battery-wind", "solar", "wind"], var.global_settings.site_type)
    error_message = "global_settings.site_type must be one of: battery, battery-solar, battery-wind, solar, wind."
  }
}

variable "global_extensions" {
  description = "Reserved global extension settings for future module capabilities. Currently unused."
  type        = any
  default     = {}
}

variable "vault_settings" {
  description = "Vault settings used to retrieve Azure Local VM administrator credentials."
  type = object({
    address            = string
    namespace          = optional(string)
    kv2_mount          = string
    kv2_secret_path    = string
    admin_username_key = optional(string, "admin_username")
    admin_password_key = optional(string, "admin_password")
  })
}

variable "compute_nodes" {
  description = "Azure Local VM definitions keyed by VM hostname."
  type = map(object({
    private_ip          = string
    ad_domain           = string
    processors          = number
    memory_mb           = number
    data_disk_1_size_gb = number
    data_disk_2_size_gb = number
    data_disk_3_size_gb = number
    tags                = optional(map(string), {})
  }))
}
