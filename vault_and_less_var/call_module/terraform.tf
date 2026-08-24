terraform {
  required_version = ">= 1.11.0, < 2.0.0"

  required_providers {
    azapi = {
      source  = "Azure/azapi"
      version = "~> 2.11"
    }

    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 5.0"
    }

    vault = {
      source  = "hashicorp/vault"
      version = "~> 5.0"
    }
  }
}

provider "azurerm" {
  features {}
}

provider "azapi" {}

provider "vault" {
  address   = var.vault_settings.address
  namespace = var.vault_settings.namespace
}
