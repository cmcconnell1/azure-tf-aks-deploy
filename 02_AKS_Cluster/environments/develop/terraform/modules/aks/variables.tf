variable "resource_group_name" {
  type        = string
  description = "Resource group name"
}

variable "app_name" {
  type        = string
  description = "Application name. Use only lowercase letters and numbers"
}

variable "location" {
  type        = string
  description = "Azure region where to create resources."
}

variable "virtual_network_name" {
  type        = string
  description = "Virtual network name. This service will create subnets in this network."
}

variable "acr_id" {
  type        = string
  description = "Azure container registry ID to pull images from."
}

variable "key_vault_id" {
  type        = string
  description = "Application key vault ID"
}

variable "log_analytics_id" {
  type        = string
  description = "log analytics ID"
}


### AKS configuration params ###
variable "kubernetes_version" {
  type = string
  description = "Version of your kubernetes node pool"
}

variable "vm_size_node_pool" {
  type = string
  description = "VM Size of your node pool"
}

variable "node_pool_min_count" {
  type = string
  description = "VM minimum amount of nodes for your node pool"
}

variable "node_pool_max_count" {
  type = string
  description = "VM maximum amount of nodes for your node pool"
}

# existing non-ephermal source keyvault to copy from
#variable "source_main_env_key_vault_name" {
#  type        = string
#  description = "name of the main source non-ephemeral and existing key vault"
#}
#variable "source_main_env_key_vault_resource_group" {
#  type        = string
#  description = "resource group of the source non-ephermal and existing key vault"
#}


### Helm Chart versions ###
variable "helm_pod_identity_version" {
  type        = string
  description = "Helm chart version of aad-pod-identity"
}

variable "helm_csi_secrets_version" {
  type        = string
  description = "Helm chart version of secrets-store-csi-driver-provider-azure"
}

variable "helm_keda_version" {
  type        = string
  description = "Helm chart version of KEDA"
}

variable "domain_name_label" {
  type        = string
  description = "Unique domain name label for AKS Cluster / Application Gateway"
  default     = ""
}

variable "azure_tenant_acr_registry_name" {
  type        = string
}
variable "azure_tenant_acr_registry_rg" {
  type        = string
}

