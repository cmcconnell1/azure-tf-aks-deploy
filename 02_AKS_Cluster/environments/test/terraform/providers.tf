
variable "ARM_TENANT_ID" {}
variable "ARM_CLIENT_ID" {}
variable "ARM_CLIENT_SECRET" {}
variable "ARM_SUBSCRIPTION_ID" {}

terraform {
  # Set the terraform required version
  # https://registry.terraform.io/providers/hashicorp/azurerm/latest
  required_version = "1.2.6"

  # Register common providers
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "2.99.0"
    }

    helm = {
      source  = "hashicorp/helm"
      version = "2.6.0"
    }

    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.12.1"
    }
  }

  backend "azurerm" {
      resource_group_name  = "devtestdevops"
      storage_account_name = "devtestdevops29003"
      container_name       = "test-aks-cluster-tfstate"
      key                  = "test-aks-cluster-tfstate"
  }
}

# Configure the Azure Provider
provider "azurerm" {

  skip_provider_registration = true

  subscription_id = var.ARM_SUBSCRIPTION_ID
  client_id       = var.ARM_CLIENT_ID
  client_secret   = var.ARM_CLIENT_SECRET
  tenant_id       = var.ARM_TENANT_ID

  features {
    key_vault { 
      recover_soft_deleted_key_vaults = true 
      purge_soft_delete_on_destroy = true 
    } 
  }
}

# Data
# Provides client_id, tenant_id, subscription_id and object_id variables
data "azurerm_client_config" "current" {}
