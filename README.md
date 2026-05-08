# Azure Local Single VM Terraform

This repo has two jobs:

1. Read-only Azure and Azure Local inventory lookups in [data.tf](/Users/stevetractenberg/fpl/single-azure-local-compute/data.tf:1)
2. Optional creation of one Azure Local Windows VM in [vm.tf](/Users/stevetractenberg/fpl/single-azure-local-compute/vm.tf:1)

The providers are configured in [terraform.tf](/Users/stevetractenberg/fpl/single-azure-local-compute/terraform.tf:1).

## Files

- [terraform.tf](/Users/stevetractenberg/fpl/single-azure-local-compute/terraform.tf:1): Terraform and provider configuration
- [data.tf](/Users/stevetractenberg/fpl/single-azure-local-compute/data.tf:1): read-only inventory lookups and outputs
- [vm.tf](/Users/stevetractenberg/fpl/single-azure-local-compute/vm.tf:1): optional single-VM deployment resources and outputs
- [data.auto.tfvars](/Users/stevetractenberg/fpl/single-azure-local-compute/data.auto.tfvars:1): auto-loaded inputs for inventory lookups
- [vm.auto.tfvars](/Users/stevetractenberg/fpl/single-azure-local-compute/vm.auto.tfvars:1): auto-loaded VM input template

## Auto-Loaded Variable Files

Terraform auto-loads only these patterns:

- `terraform.tfvars`
- `terraform.tfvars.json`
- `*.auto.tfvars`
- `*.auto.tfvars.json`

## Authentication

Authenticate with Azure before planning or applying:

```bash
az login
az account set --subscription <subscription-id>
terraform init
```

If `subscription_id = null`, the VM code uses the currently selected Azure subscription from your active Azure auth context.

## Inventory Mode

The read-only lookups in [data.tf](/Users/stevetractenberg/fpl/single-azure-local-compute/data.tf:1) are organized as four sections:

1. All resource groups in the current subscription
2. Azure Local custom locations in `azure_local_resource_group_name`
3. Azure Local VMs in `azure_local_resource_group_name`
4. Full details for one Azure Local VM

Current default inputs for inventory are in [data.auto.tfvars](/Users/stevetractenberg/fpl/single-azure-local-compute/data.auto.tfvars:1):

```hcl
azure_local_resource_group_name = "hci-cluster-rg"
azure_local_vm_name             = "example-azure-local-vm"
```

Run inventory:

```bash
terraform plan
```

## VM Deployment Mode

The single-VM deployment path lives in [vm.tf](/Users/stevetractenberg/fpl/single-azure-local-compute/vm.tf:1).

VM creation is controlled by:

```hcl
create_vm = false
```

in [vm.auto.tfvars](/Users/stevetractenberg/fpl/single-azure-local-compute/vm.auto.tfvars:5).

Set it to `true` when you actually want Terraform to create the VM.

Plan or apply:

```bash
terraform plan
terraform apply
```

## VM Inputs

The main deployment inputs are:

- `azure_local_resource_group_name`: resource group that contains the Azure Local resources
- `location`: Azure region for the control-plane resources
- `vm_name`: name of the Azure Local VM and Arc machine
- `custom_location_name`: Azure Local custom location name
- `logical_network_name`: Azure Local logical network name
- `image_name`: Azure Local VM image name
- `image_resource_type`: usually `galleryImages` for images created from a local share
- `admin_username`
- `admin_password`
- `cpu_count`
- `memory_mb`
- `static_ip_address`
- `c_drive_size_gb`
- `enable_d_drive`
- `d_drive_size_gb`
- `additional_tags`

Example shape from [vm.auto.tfvars](/Users/stevetractenberg/fpl/single-azure-local-compute/vm.auto.tfvars:1):

```hcl
create_vm = true

azure_local_resource_group_name = "hci-cluster-rg"
location                        = "eastus"
vm_name                         = "example-azure-local-vm"
subscription_id                 = null
custom_location_name            = "my-custom-location"
logical_network_name            = "my-logical-network"
image_name                      = "winServer2022-01"
image_resource_type             = "galleryImages"
storage_container_name          = null

admin_username = "azurelocaladmin"
admin_password = "ReplaceWithAStrongPassword123!"

cpu_count         = 4
memory_mb         = 16384
static_ip_address = "192.168.1.25"
c_drive_size_gb   = 127

enable_d_drive  = false
d_drive_size_gb = 256

additional_tags = {
  environment = "dev"
  owner       = "engineering"
}
```

## Azure Local-Specific Notes

### `custom_location_name`

This is the name of the Azure resource of type:

```text
Microsoft.ExtendedLocation/customLocations
```

It is the deployment target for Azure Local VM resources. If you do not know it, use section 2 of [data.tf](/Users/stevetractenberg/fpl/single-azure-local-compute/data.tf:29) to discover it.

### `image_resource_type`

If the image was created from a local share, use:

```hcl
image_resource_type = "galleryImages"
```

Marketplace-backed images use `marketplaceGalleryImages`.

### `storage_container_name`

You can usually leave this as `null`.

The VM code will:

- use the explicit value if you set `storage_container_name`
- auto-select the container if exactly one storage container exists in scope
- fail with a clear error listing valid names if multiple storage containers exist and no name was provided
- fail if no storage containers are found

This is lower-level than the Azure portal UI, where the equivalent behavior often appears as "storage path allocation method = choose automatically".

## Validation

Useful commands:

```bash
terraform fmt
terraform validate
terraform plan
```
