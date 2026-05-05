# Azure Local Single VM Terraform

This repository contains Terraform for two related tasks:

1. Read-only inventory checks against Azure.
2. Creation of a single Windows VM on Azure Local.

The configuration uses:

- `azurerm` for standard Azure resource group lookups.
- `azapi` for Azure and Azure Local resource discovery and VM deployment.

## Files

- `data.tf`: Read-only discovery of resource groups, Azure VMs in a specified resource group, and Azure Local VM images.
- `main.tf`: Creation of a Windows Azure Local VM, NIC, Arc machine, and thick-provisioned OS disk.
- `variables.tf`: Input variable definitions.
- `outputs.tf`: Data and resource outputs.
- `terraform.tfvars.example`: Example input values.
- `versions.tf`: Terraform and provider requirements.

## What `data.tf` retrieves

`data.tf` performs the following lookups:

- All resource groups in the current subscription.
- All Azure IaaS VMs in `azure_vm_resource_group_name`.
- All Azure Local `galleryImages` in the selected image resource group.
- All Azure Local `marketplaceGalleryImages` in the selected image resource group.

This is useful for validating that your Azure credentials have read access before attempting VM creation.

## Minimal inputs for read-only testing

If you want to test credentials with read-only lookups only, the minimum required variables are:

```hcl
azure_local_resource_group_name = "rg-azure-local"
azure_vm_resource_group_name    = "rg-azure-vms"
```

Optional:

```hcl
image_resource_group_name = "rg-azure-local-images"
```

If `image_resource_group_name` is omitted, it defaults to `azure_local_resource_group_name`.

## Read-only workflow

To run only the data lookups:

1. Temporarily remove or rename `main.tf`.
2. Remove, rename, or comment out the resource-based outputs in `outputs.tf`:
   - `azure_local_vm_id`
   - `azure_local_os_disk_id`
   - `azure_local_nic_id`
3. Keep `data.tf`, `variables.tf`, `versions.tf`, and the data-related outputs.
4. Provide the required values in `terraform.tfvars`.
5. Run:

```bash
terraform init
terraform plan
```

If the plan succeeds and the data sources resolve, your credentials have at least the read permissions needed for inventory.

## VM creation workflow

Once read-only access is confirmed, restore `main.tf` and the resource outputs, then populate the VM-specific variables.

Important inputs for VM creation include:

- `vm_name`: Used for the Azure Local VM name, Arc machine name, and Windows hostname.
- `location`: Azure region for the control-plane resources.
- `custom_location_id`: Azure Local custom location resource ID.
- `logical_network_id`: Azure Local network the VM NIC will attach to.
- `image_id`: Windows Azure Local image resource ID.
- `os_disk_storage_container_id`: Storage container for the OS disk.
- `admin_username`
- `admin_password`
- `processor_count`
- `memory_mb`
- `c_drive_size_gb`

## Windows-specific behavior

This configuration is Windows-only.

- `windows_time_zone` should be a Windows time zone ID string.
- For New York / Eastern time, use:

```hcl
windows_time_zone = "Eastern Standard Time"
```

## Storage and memory behavior

- RAM is fixed using `memory_mb`.
- The Windows OS disk is explicitly created as thick provisioned with `dynamic = false`.
- The `C:` drive size is controlled by `c_drive_size_gb`.

## Notes on Azure Local resources

The VM deployment model uses:

- `Microsoft.HybridCompute/machines` as the Arc machine resource.
- `Microsoft.AzureStackHCI/virtualMachineInstances` as the actual Azure Local VM definition.
- `Microsoft.AzureStackHCI/networkInterfaces` for the VM NIC.
- `Microsoft.AzureStackHCI/virtualHardDisks` for the thick-provisioned OS disk.

## Example commands

Initialize providers:

```bash
terraform init
```

Validate configuration:

```bash
terraform validate
```

Format files:

```bash
terraform fmt -recursive
```

Plan the deployment:

```bash
terraform plan
```
