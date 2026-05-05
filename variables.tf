variable "location" {
  description = "Azure region for the resource group-backed control plane resources."
  type        = string
}

variable "azure_local_resource_group_name" {
  description = "Resource group that contains the Azure Local resources and where the VM will be created."
  type        = string
}

variable "azure_vm_resource_group_name" {
  description = "Azure resource group whose Azure IaaS VMs should be inventoried in data.tf."
  type        = string
}

variable "image_resource_group_name" {
  description = "Optional resource group that contains Azure Local gallery or marketplace gallery images. Defaults to azure_local_resource_group_name."
  type        = string
  default     = null
}

variable "vm_name" {
  description = "Name for the Azure Local VM, backing Arc machine, and Windows hostname."
  type        = string
}

variable "custom_location_id" {
  description = "Resource ID of the Azure Local custom location."
  type        = string
}

variable "logical_network_id" {
  description = "Resource ID of the Azure Local logical network to place the VM NIC on."
  type        = string
}

variable "image_id" {
  description = "Resource ID of the Windows Azure Local image to deploy from. This can point to either a galleryImages or marketplaceGalleryImages resource."
  type        = string
}

variable "os_disk_storage_container_id" {
  description = "Resource ID of the Azure Local storage container that will hold the Windows OS disk."
  type        = string
}

variable "admin_username" {
  description = "Administrator username for the guest OS."
  type        = string
}

variable "admin_password" {
  description = "Administrator password for the guest OS."
  type        = string
  sensitive   = true
}

variable "processor_count" {
  description = "Number of vCPUs for the Azure Local VM."
  type        = number
  default     = 2
}

variable "memory_mb" {
  description = "Fixed memory assignment in MB."
  type        = number
  default     = 8192
}

variable "c_drive_size_gb" {
  description = "Size of the Windows C: volume / OS disk in GB."
  type        = number
  default     = 127
}

variable "os_disk_hyperv_generation" {
  description = "Hyper-V generation for the Windows OS disk."
  type        = string
  default     = "V2"
}

variable "private_ip_address" {
  description = "Optional static private IP on the Azure Local logical network. Leave null for DHCP/dynamic allocation."
  type        = string
  default     = null
}

variable "provision_vm_agent" {
  description = "Whether to provision the Azure Local guest agent."
  type        = bool
  default     = true
}

variable "provision_vm_config_agent" {
  description = "Whether to provision the Azure Arc VM config agent."
  type        = bool
  default     = true
}

variable "windows_enable_automatic_updates" {
  description = "Whether to enable automatic updates for Windows guests."
  type        = bool
  default     = true
}

variable "windows_time_zone" {
  description = "Optional Windows guest time zone."
  type        = string
  default     = null
}

variable "secure_boot_enabled" {
  description = "Whether to enable UEFI secure boot."
  type        = bool
  default     = true
}

variable "enable_tpm" {
  description = "Whether to enable TPM for the guest."
  type        = bool
  default     = true
}

variable "security_type" {
  description = "Optional Azure Local VM security type. Set to TrustedLaunch or ConfidentialVM when required by the image and host."
  type        = string
  default     = null
}

variable "placement_zone" {
  description = "Optional Azure Local placement zone."
  type        = string
  default     = null
}

variable "strict_placement_policy" {
  description = "Whether VM failover must remain within the selected zone."
  type        = bool
  default     = false
}

variable "tags" {
  description = "Optional tags applied to created resources."
  type        = map(string)
  default     = {}
}
