variable "azure_local_resource_group_name" {
  description = "Resource group that contains the Azure Local VM inventory to query."
  type        = string
}

variable "azure_local_vm_name" {
  description = "Name of the Azure Local VM / Arc machine to inspect."
  type        = string
}

data "azapi_client_config" "current" {}

# Section 1: Retrieve all resource groups in the current subscription.
# Comment out this section if you only want to run the resource-group-scoped
# or single-VM lookups below.

data "azapi_resource_list" "resource_groups" {
  type      = "Microsoft.Resources/subscriptions/resourceGroups@2021-04-01"
  parent_id = "/subscriptions/${data.azapi_client_config.current.subscription_id}"

  response_export_values = ["value"]
}

output "resource_groups" {
  description = "Section 1 output: all resource groups in the current subscription."
  value       = try(data.azapi_resource_list.resource_groups.output.value, [])
}

# Section 2: Specify one resource group, then retrieve all Azure Local custom
# locations in that resource group. These are the deployment targets used by
# Azure Local VM resources.
# Comment out this section if you only want the subscription-wide resource
# group list or the VM inventory / single-VM lookups below.

data "azurerm_resource_group" "custom_locations_scope" {
  name = var.azure_local_resource_group_name
}

data "azapi_resource_list" "custom_locations" {
  type      = "Microsoft.ExtendedLocation/customLocations@2021-08-15"
  parent_id = data.azurerm_resource_group.custom_locations_scope.id

  response_export_values = ["value"]
}

output "azure_local_custom_locations_in_resource_group" {
  description = "Section 2 output: all Azure Local custom locations found in the selected resource group."
  value = [
    for location in try(data.azapi_resource_list.custom_locations.output.value, []) : {
      name               = try(location.name, null)
      id                 = try(location.id, null)
      location           = try(location.location, null)
      host_resource_id   = try(location.properties.hostResourceId, null)
      namespace          = try(location.properties.namespace, null)
      provisioning_state = try(location.properties.provisioningState, null)
    }
  ]
}

# Section 3: Specify one resource group, then retrieve all Azure Local VMs
# (HybridCompute machines with kind == HCI) in that resource group.
# Comment out this section if you only want the subscription-wide resource
# group list, custom locations, or the single-VM lookup below.

data "azurerm_resource_group" "azure_local_vms_scope" {
  name = var.azure_local_resource_group_name
}

data "azapi_resource_list" "azure_local_vms" {
  type      = "Microsoft.HybridCompute/machines@2024-07-10"
  parent_id = data.azurerm_resource_group.azure_local_vms_scope.id

  response_export_values = ["value"]
}

output "azure_local_vms_in_resource_group" {
  description = "Section 3 output: all Azure Local VMs found in the selected resource group."
  value = [
    for vm in try(data.azapi_resource_list.azure_local_vms.output.value, []) : vm
    if try(vm.kind, null) == "HCI"
  ]
}

# Section 4: Specify one Azure Local VM, then retrieve all available data
# about that VM, including the Arc machine resource and its backing Azure
# Local virtualMachineInstances/default resource.
# Comment out this section if you only want the resource group list or the
# custom-location / resource-group-scoped VM inventory above.

# data "azurerm_resource_group" "azure_local_vm_scope" {
#   name = var.azure_local_resource_group_name
# }

# data "azapi_resource" "azure_local_vm" {
#   type      = "Microsoft.HybridCompute/machines@2024-07-10"
#   name      = var.azure_local_vm_name
#   parent_id = data.azurerm_resource_group.azure_local_vm_scope.id

#   response_export_values = ["*"]
# }

# data "azapi_resource" "azure_local_vm_instance" {
#   type      = "Microsoft.AzureStackHCI/virtualMachineInstances@2024-01-01"
#   name      = "default"
#   parent_id = data.azapi_resource.azure_local_vm.id

#   response_export_values = ["*"]
# }

# output "azure_local_vm_details" {
#   description = "Section 4 output: full details for the selected Azure Local VM."
#   value = {
#     arc_machine = data.azapi_resource.azure_local_vm.output
#     vm_instance = data.azapi_resource.azure_local_vm_instance.output
#     resource_id = data.azapi_resource.azure_local_vm.id
#     vm_name     = data.azapi_resource.azure_local_vm.name
#     rg_name     = data.azurerm_resource_group.azure_local_vm_scope.name
#   }
# }
