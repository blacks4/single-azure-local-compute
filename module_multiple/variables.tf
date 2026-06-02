variable "azure_local_resource_group_name" {
  description = "Resource group that contains Azure Local resources."
  type        = string
}

variable "location" {
  description = "Azure region for Azure Local control-plane resources."
  type        = string
}

variable "vm_name" {
  description = "Name of the Azure Local VM and backing Arc machine."
  type        = string
}

variable "ad_domain" {
  description = "Active Directory domain associated with this VM."
  type        = string
}

variable "custom_location_name" {
  description = "Name of the Azure Local custom location."
  type        = string
}

variable "logical_network_name" {
  description = "Name of the Azure Local logical network."
  type        = string
}

variable "image_name" {
  description = "Name of the Azure Local image."
  type        = string
}

variable "admin_username" {
  description = "Windows administrator username."
  type        = string
}

variable "admin_password" {
  description = "Windows administrator password."
  type        = string
  sensitive   = true
}

variable "subscription_id" {
  description = "Optional subscription ID override. Defaults to the active Azure context subscription."
  type        = string
  default     = null
}

variable "image_resource_type" {
  description = "Image resource type under Microsoft.AzureStackHCI."
  type        = string
  default     = "galleryimages"
}

variable "storage_container_name" {
  description = "Optional storage container name. If omitted, the module auto-selects one in the custom location scope."
  type        = string
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

variable "data_volume1_size_gb" {
  description = "Size of optional data volume 1 in GB. Set to 0 to disable."
  type        = number
  default     = 0
}

variable "data_volume2_size_gb" {
  description = "Size of optional data volume 2 in GB. Set to 0 to disable."
  type        = number
  default     = 0
}

variable "data_volume3_size_gb" {
  description = "Size of optional data volume 3 in GB. Set to 0 to disable."
  type        = number
  default     = 0
}

variable "static_ip_address" {
  description = "Optional static private IP address. Leave null for DHCP."
  type        = string
  default     = null
}

variable "windows_time_zone" {
  description = "Windows time zone ID."
  type        = string
  default     = "Eastern Standard Time"
}

variable "arc_http_proxy_url" {
  description = "Optional HTTP proxy URL for Arc guest connectivity."
  type        = string
  default     = null
}

variable "arc_https_proxy_url" {
  description = "Optional HTTPS proxy URL for Arc guest connectivity."
  type        = string
  default     = null
}

variable "arc_no_proxy" {
  description = "Optional no_proxy list for Arc guest connectivity."
  type        = list(string)
  default     = []
}

variable "additional_tags" {
  description = "Additional tags to apply to created resources."
  type        = map(string)
  default     = {}
}
