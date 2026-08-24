# Azure Local VM Module

Terraform module that creates a single Windows VM on an **Azure Local (Azure Stack HCI)** cluster. Each call provisions:

- `Microsoft.HybridCompute/machines` — Arc machine (HCI kind, system-assigned identity)
- `Microsoft.AzureStackHCI/networkInterfaces` — NIC attached to the target logical network
- `Microsoft.AzureStackHCI/virtualMachineInstances` — VM instance parented to the Arc machine
- `Microsoft.AzureStackHCI/virtualHardDisks` — up to three optional data disks (zero = disabled)

Storage container selection is automatic (first alphabetical container scoped to the custom location) unless overridden with `storage_container_name`.

---

## Requirements

| Name | Version |
|------|---------|
| Terraform | `>= 1.11.0, < 2.0.0` |
| [azapi](https://registry.terraform.io/providers/Azure/azapi) | `~> 2.11` |
| [azurerm](https://registry.terraform.io/providers/hashicorp/azurerm) | `~> 5.0` |

---

## Usage

This child module creates one Azure Local VM per module call. In this repository, the supported entry point is `call_module/`, which calls this module once for each item in `compute_nodes`.

Use the root caller unless you are intentionally consuming this child module directly:

```hcl
module "azure_local_vm" {
  source   = "../module"
  for_each = var.compute_nodes

  azure_local_resource_group_name = var.global_settings.azure_local_resource_group_name
  location                        = var.global_settings.location
  site_type                       = var.global_settings.site_type
  custom_location_name            = var.global_settings.custom_location_name
  logical_network_name            = var.global_settings.logical_network_name
  image_name                      = var.global_settings.image_name

  vm_name              = each.key
  ad_domain            = each.value.ad_domain
  cpu_count            = each.value.processors
  memory_mb            = each.value.memory_mb
  data_volume1_size_gb = each.value.data_disk_1_size_gb
  data_volume2_size_gb = each.value.data_disk_2_size_gb
  data_volume3_size_gb = each.value.data_disk_3_size_gb
  static_ip_address    = each.value.private_ip
}
```

---

## Input Variables

### Required By The Supported Caller

| Name | Type | Description |
|------|------|-------------|
| `azure_local_resource_group_name` | `string` | Resource group containing the Azure Local cluster resources. |
| `location` | `string` | Azure region for control-plane resources (e.g. `"eastus"`). |
| `site_type` | `string` | Site type. Must be one of `battery`, `battery-solar`, `battery-wind`, `solar`, or `wind`. |
| `vm_name` | `string` | Name of the VM and backing Arc machine. |
| `ad_domain` | `string` | Active Directory domain associated with this VM. |
| `custom_location_name` | `string` | Name of the Azure Local custom location. |
| `logical_network_name` | `string` | Name of the Azure Local logical network to attach the NIC to. |
| `image_name` | `string` | Name of the Azure Local VM image. |
| `admin_username` | `string` | Local Windows administrator username. *(sensitive, ephemeral)* |
| `admin_password` | `string` | Local Windows administrator password. *(sensitive, ephemeral)* |
| `subscription_id` | `string` | Subscription ID used for Azure Local resource IDs. |
| `cpu_count` | `number` | Number of vCPUs. |
| `memory_mb` | `number` | RAM in MB. |
| `data_volume1_size_gb` | `number` | Size of data disk 1 in GB. Set to `0` to skip. |
| `data_volume2_size_gb` | `number` | Size of data disk 2 in GB. Set to `0` to skip. |
| `data_volume3_size_gb` | `number` | Size of data disk 3 in GB. Set to `0` to skip. |
| `static_ip_address` | `string` | Static private IP address. |
| `windows_time_zone` | `string` | Windows time zone ID applied at provisioning. |

These variables have defaults in the child module, but the supported `call_module/` wrapper supplies them from required `global_settings` or `compute_nodes` fields. Treat them as required when using this repository's caller.

### Optional In The Supported Caller

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `image_resource_type` | `string` | `"galleryimages"` | Image resource type under `Microsoft.AzureStackHCI` (e.g. `"galleryimages"` or `"marketplaceGalleryImages"`). |
| `storage_container_name` | `string` | `null` | Storage container for VM config and data disks. Auto-selected from the custom location scope if omitted. |
| `global_extensions` | `any` | `{}` | Reserved global extension settings for future module capabilities. Currently unused. |
| `arc_http_proxy_url` | `string` | `null` | HTTP proxy URL for Arc guest agent connectivity. |
| `arc_https_proxy_url` | `string` | `null` | HTTPS proxy URL for Arc guest agent connectivity. |
| `arc_no_proxy` | `list(string)` | `[]` | Hosts/CIDRs excluded from proxy routing for the Arc guest agent. |
| `additional_tags` | `map(string)` | `{}` | Additional tags applied to all created resources. |

---

## Outputs

| Name | Description |
|------|-------------|
| `azure_local_vm_id` | Resource ID of the `virtualMachineInstances` resource. |
| `arc_machine_id` | Resource ID of the `Microsoft.HybridCompute/machines` Arc machine. |
| `azure_local_vm_nic_id` | Resource ID of the network interface. |
| `azure_local_vm_data_disk_ids` | Map of data disk resource IDs keyed by volume name (`data`, `data2`, `data3`). Empty map if no data disks are configured. |
| `effective_storage_container_name` | Name of the storage container used for VM config and data disks (auto-selected or explicitly set). |
| `vm_hostname` | VM hostname as provided to the module. |
| `ad_domain` | AD domain as provided to the module. |
| `vm_hostname_and_ad_domain` | Object containing both `hostname` and `ad_domain`. |

---

## Notes

- **Windows Server is always enabled** — `provisionVMAgent`, `provisionVMConfigAgent`, and `enableAutomaticUpdates` are always set to `true`.
- **Secure Boot and vTPM are always enabled** — the `securityProfile` is hardcoded with `secureBootEnabled = true` and `enableTPM = true`.
- **Data disks use dynamic provisioning** — all data disks are created as dynamic, Hyper-V Gen 2 VHDs.
- **Administrator credentials are write-only and build-time only** — `admin_username` and `admin_password` are sent through AzAPI `sensitive_body` and are not stored in Terraform state. The `sensitive_body_version` values are fixed so Vault secret changes do not update, destroy, or recreate the VM.
- **Storage container auto-selection** — when `storage_container_name` is omitted, the module queries all `Microsoft.AzureStackHCI/storageContainers` in the resource group, filters to those scoped to the target custom location, and selects the first alphabetically. A `precondition` will fail at plan time if none are found.
- **Azure Hybrid Benefit / Activate Azure Benefits** — the `Microsoft.HybridCompute/machines/licenseProfiles` API used to set this requires an EA, MCA-E, or CSP subscription. It is **not supported on Pay-As-You-Go subscriptions** and will return `HCRP400` if attempted.
