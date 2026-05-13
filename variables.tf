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
