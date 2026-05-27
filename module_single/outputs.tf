output "azure_local_vm_id" {
  description = "Resource ID of the created Azure Local VM instance."
  value       = azapi_resource.azure_local_virtual_machine.id
}

output "arc_machine_id" {
  description = "Resource ID of the created Arc machine."
  value       = azapi_resource.arc_machine.id
}

output "azure_local_vm_nic_id" {
  description = "Resource ID of the created Azure Local NIC."
  value       = azapi_resource.azure_local_nic.id
}

output "azure_local_vm_data_disk_ids" {
  description = "Resource IDs of optional Azure Local data disks keyed by volume name."
  value       = { for volume_name, disk in azapi_resource.azure_local_data_disks : volume_name => disk.id }
}

output "effective_storage_container_name" {
  description = "Storage container selected for VM config and data disks."
  value       = local.effective_storage_container_name
}
