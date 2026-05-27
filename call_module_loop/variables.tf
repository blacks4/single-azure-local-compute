variable "azure_local_resource_group_name" {
  description = "Resource group that contains Azure Local resources."
  type        = string
}

variable "location" {
  description = "Azure region for Azure Local control-plane resources."
  type        = string
}

variable "subscription_id" {
  description = "Optional subscription ID override. Defaults to the active Azure context subscription."
  type        = string
  default     = null
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

variable "admin_username" {
  description = "Windows administrator username used for all VMs in compute_nodes."
  type        = string
}

variable "admin_password" {
  description = "Windows administrator password used for all VMs in compute_nodes."
  type        = string
  sensitive   = true
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
  description = "Global tags merged with each node's tags."
  type        = map(string)
  default     = {}
}

variable "compute_nodes" {
  description = "VM definitions keyed by VM hostname."
  type = map(object({
    private_ip          = string
    processors          = number
    memory_mb           = number
    data_disk_1_size_gb = number
    data_disk_2_size_gb = number
    data_disk_3_size_gb = number
    tags                = optional(map(string), {})
  }))
}
