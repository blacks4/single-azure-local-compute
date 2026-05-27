output "azure_local_vm_ids" {
  description = "Resource IDs of created Azure Local VM instances keyed by hostname."
  value       = { for hostname, vm in module.azure_local_vm : hostname => vm.azure_local_vm_id }
}

output "azure_local_vm_nic_ids" {
  description = "Resource IDs of created Azure Local NICs keyed by hostname."
  value       = { for hostname, vm in module.azure_local_vm : hostname => vm.azure_local_vm_nic_id }
}

output "arc_machine_ids" {
  description = "Resource IDs of created Arc machines keyed by hostname."
  value       = { for hostname, vm in module.azure_local_vm : hostname => vm.arc_machine_id }
}