output "resource_groups" {
  description = "All resource groups in the current subscription."
  value       = data.azapi_resource_list.resource_groups.output.resource_groups
}

output "azure_virtual_machines_in_resource_group" {
  description = "All Azure IaaS VMs found in var.azure_vm_resource_group_name."
  value       = data.azapi_resource_list.azure_virtual_machines.output.virtual_machines
}

output "azure_local_vm_images" {
  description = "Azure Local gallery and marketplace gallery images found in the selected image resource group."
  value = concat(
    data.azapi_resource_list.azure_local_gallery_images.output.images,
    data.azapi_resource_list.azure_local_marketplace_gallery_images.output.images
  )
}

output "azure_local_vm_id" {
  description = "Resource ID of the created Azure Local virtual machine instance."
  value       = azapi_resource.azure_local_virtual_machine.id
}

output "azure_local_os_disk_id" {
  description = "Resource ID of the created Azure Local thick-provisioned Windows OS disk."
  value       = azapi_resource.azure_local_os_disk.id
}

output "azure_local_nic_id" {
  description = "Resource ID of the created Azure Local NIC."
  value       = azapi_resource.azure_local_nic.id
}
