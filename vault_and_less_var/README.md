# Azure Local VM Terraform Wrapper Changes

This workspace contains:

- `module/`: the reusable Terraform module that creates Azure Local VM resources.
- `call_module/`: the caller configuration that loops over VM definitions and invokes `module`.

## Variable Reorganization

The caller configuration in `call_module/` was reorganized so VM-specific values are separated from shared deployment settings.

Top-level caller variables are now:

- `global_settings`: shared settings used for all Azure Local VMs.
- `global_extensions`: reserved global extension settings for future module capabilities.
- `vault_settings`: Vault connection and KV v2 secret lookup settings.
- `compute_nodes`: per-VM Azure Local settings keyed by VM hostname.

Shared Azure Local settings moved into `global_settings`, including:

- `subscription_id`
- `azure_local_resource_group_name`
- `location`
- `site_type`
- `custom_location_name`
- `logical_network_name`
- `image_name`
- `image_resource_type`
- `storage_container_name`
- Arc proxy settings
- Windows time zone
- shared tags

`site_type` must be one of:

- `battery`
- `battery-solar`
- `battery-wind`
- `solar`
- `wind`

VM-specific settings remain in `compute_nodes`, including:

- private IP address
- AD domain
- CPU count
- memory
- optional data disk sizes
- per-VM tags

## Future Extension Point

`global_extensions` is intentionally reserved and currently unused:

```hcl
global_extensions = {}
```

This gives HCP Terraform workspaces a stable global extension variable now. Future module versions can use nested keys under this object for site-wide or workspace-wide capabilities without requiring a new top-level HCP Terraform workspace variable.

## Vault Credential Lookup

The caller now retrieves the VM administrator username and password from HashiCorp Vault instead of accepting them as direct Terraform input variables.

Vault settings are configured with the `vault_settings` variable:

```hcl
vault_settings = {
  address             = "https://vault.example.com:8200"
  namespace           = "admin"
  kv2_mount           = "kv"
  kv2_secret_path     = "azure-local/vm-admin"
  admin_username_key  = "admin_username"
  admin_password_key  = "admin_password"
}
```

The Vault KV v2 secret is read by `ephemeral.vault_kv_secret_v2.vm_admin_credentials` in `call_module/main.tf`. This avoids storing the fetched secret values in Terraform state or plan files.

The secret is expected to contain fields matching `admin_username_key` and `admin_password_key`. By default, those field names are:

- `admin_username`
- `admin_password`

The credentials are passed into the child module through ephemeral module variables. The Azure Local VM resource sends them to ARM through AzAPI `sensitive_body`, which is a write-only argument and is not stored in Terraform state.

The AzAPI `sensitive_body_version` values are intentionally fixed in the module. This means Terraform uses the Vault values at VM creation time, but later Vault secret changes do not cause Terraform to update, destroy, or recreate the Azure Local VM.

Vault authentication is intentionally not modeled as a Terraform variable. Use the normal Vault provider authentication mechanisms, such as `VAULT_TOKEN`, or another supported provider auth method.

## Module Call Update

The caller now invokes the local module at:

```hcl
source = "../module"
```

The module interface itself is mostly unchanged. The caller maps the reorganized inputs back into the module's existing variables.

## Thin Provisioning For Optional Data Disks

The optional Azure Local data disks are created in `module/main.tf` with:

```hcl
dynamic = true
```

This is set on the `Microsoft.AzureStackHCI/virtualHardDisks@2024-01-01` resource. The `dynamic` property enables dynamic sizing for the virtual hard disk, which is the Azure Local setting corresponding to thin-style provisioning.

Previously, these optional data disks used:

```hcl
dynamic = false
```

That created fixed-size disks.

## Validation

The updated Terraform configuration was formatted and validated from `call_module/`:

```sh
terraform fmt
terraform validate
```

Validation passed successfully.
