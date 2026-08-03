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
| Terraform | `>= 1.5.0` |
| [azapi](https://registry.terraform.io/providers/Azure/azapi) | `~> 2.11` |
| [azurerm](https://registry.terraform.io/providers/hashicorp/azurerm) | `~> 5.0` |

---

## Usage

Call the module once per VM. Use `for_each` to deploy multiple VMs from a single map.

### Minimal example (DHCP, no data disks)

```hcl
module "azure_local_vm" {
  source = "./module_multiple"

  azure_local_resource_group_name = "my-hci-rg"
  location                        = "eastus"
  vm_name                         = "vm01"
  ad_domain                       = "corp.contoso.com"
  custom_location_name            = "my-custom-location"
  logical_network_name            = "my-logical-network"
  image_name                      = "ws2022-image"
  admin_username                  = "localadmin"
  admin_password                  = var.admin_password
}
```

### Full example with data disks, static IP, and proxy

```hcl
module "azure_local_vm" {
  source = "./module_multiple"

  azure_local_resource_group_name = "my-hci-rg"
  location                        = "eastus"
  vm_name                         = "vm01"
  ad_domain                       = "corp.contoso.com"
  custom_location_name            = "my-custom-location"
  logical_network_name            = "my-logical-network"
  image_name                      = "ws2022-image"
  image_resource_type             = "galleryimages"
  admin_username                  = "localadmin"
  admin_password                  = var.admin_password

  cpu_count = 4
  memory_mb = 16384

  data_volume1_size_gb = 128
  data_volume2_size_gb = 256
  data_volume3_size_gb = 0

  static_ip_address      = "10.0.1.50"
  storage_container_name = "my-storage-container"
  windows_time_zone      = "Eastern Standard Time"

  arc_http_proxy_url  = "http://proxy.corp.contoso.com:3128"
  arc_https_proxy_url = "http://proxy.corp.contoso.com:3128"
  arc_no_proxy        = ["localhost", "169.254.169.254"]

  additional_tags = {
    environment = "production"
    owner       = "platform-team"
  }
}
```

### Multi-VM example using `for_each`

```hcl
locals {
  vms = {
    vm01 = {
      vm_name              = "vm01"
      ad_domain            = "corp.contoso.com"
      cpu_count            = 4
      memory_mb            = 16384
      data_volume1_size_gb = 128
      data_volume2_size_gb = 0
      data_volume3_size_gb = 0
      static_ip_address    = null
      additional_tags      = { environment = "dev" }
    }
    vm02 = {
      vm_name              = "vm02"
      ad_domain            = "corp.contoso.com"
      cpu_count            = 2
      memory_mb            = 8192
      data_volume1_size_gb = 0
      data_volume2_size_gb = 0
      data_volume3_size_gb = 0
      static_ip_address    = "10.0.1.51"
      additional_tags      = { environment = "dev" }
    }
  }
}

module "azure_local_vm" {
  source   = "./module_multiple"
  for_each = local.vms

  azure_local_resource_group_name = var.azure_local_resource_group_name
  location                        = var.location
  custom_location_name            = var.custom_location_name
  logical_network_name            = var.logical_network_name
  image_name                      = var.image_name
  admin_username                  = var.admin_username
  admin_password                  = var.admin_password

  vm_name              = each.value.vm_name
  ad_domain            = each.value.ad_domain
  cpu_count            = each.value.cpu_count
  memory_mb            = each.value.memory_mb
  data_volume1_size_gb = each.value.data_volume1_size_gb
  data_volume2_size_gb = each.value.data_volume2_size_gb
  data_volume3_size_gb = each.value.data_volume3_size_gb
  static_ip_address    = each.value.static_ip_address
  additional_tags      = each.value.additional_tags
}
```

---

## Input Variables

### Required

| Name | Type | Description |
|------|------|-------------|
| `azure_local_resource_group_name` | `string` | Resource group containing the Azure Local cluster resources. |
| `location` | `string` | Azure region for control-plane resources (e.g. `"eastus"`). |
| `vm_name` | `string` | Name of the VM and backing Arc machine. |
| `ad_domain` | `string` | Active Directory domain associated with this VM. |
| `custom_location_name` | `string` | Name of the Azure Local custom location. |
| `logical_network_name` | `string` | Name of the Azure Local logical network to attach the NIC to. |
| `image_name` | `string` | Name of the Azure Local VM image. |
| `admin_username` | `string` | Local Windows administrator username. |
| `admin_password` | `string` | Local Windows administrator password. *(sensitive)* |

### Optional

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `subscription_id` | `string` | `null` | Subscription ID override. Defaults to the active Azure context subscription. |
| `image_resource_type` | `string` | `"galleryimages"` | Image resource type under `Microsoft.AzureStackHCI` (e.g. `"galleryimages"` or `"marketplaceGalleryImages"`). |
| `storage_container_name` | `string` | `null` | Storage container for VM config and data disks. Auto-selected from the custom location scope if omitted. |
| `cpu_count` | `number` | `2` | Number of vCPUs. |
| `memory_mb` | `number` | `8192` | RAM in MB. |
| `data_volume1_size_gb` | `number` | `0` | Size of data disk 1 in GB. Set to `0` to skip. |
| `data_volume2_size_gb` | `number` | `0` | Size of data disk 2 in GB. Set to `0` to skip. |
| `data_volume3_size_gb` | `number` | `0` | Size of data disk 3 in GB. Set to `0` to skip. |
| `static_ip_address` | `string` | `null` | Static private IP address. Leave `null` for DHCP. |
| `windows_time_zone` | `string` | `"Eastern Standard Time"` | Windows time zone ID applied at provisioning. |
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
- **Data disks use fixed provisioning** — all data disks are created as fixed (non-dynamic), Hyper-V Gen 2 VHDs.
- **Storage container auto-selection** — when `storage_container_name` is omitted, the module queries all `Microsoft.AzureStackHCI/storageContainers` in the resource group, filters to those scoped to the target custom location, and selects the first alphabetically. A `precondition` will fail at plan time if none are found.
- **Azure Hybrid Benefit / Activate Azure Benefits** — the `Microsoft.HybridCompute/machines/licenseProfiles` API used to set this requires an EA, MCA-E, or CSP subscription. It is **not supported on Pay-As-You-Go subscriptions** and will return `HCRP400` if attempted.
