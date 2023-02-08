### General ###
variable "app_name" {
  type        = string
  description = "Application name. Use only lowercase letters and numbers"
}

variable "location" {
  type        = string
  description = "Azure region where to create resources."
  default     = ""
}

variable "domain_name_label" {
  type        = string
  description = "Unique domain name label for AKS Cluster / Application Gateway"
  default     = ""
}


### AKS configuration params ###
variable "kubernetes_version" {
  type        = string
  description = "Kubernetes version of the node pool"
  default     = ""
}

variable "vm_size_node_pool" {
  type        = string
  description = "VM Size of the node pool"
  default     = ""
}

variable "node_pool_min_count" {
  type        = string
  description = "VM minimum amount of nodes for the node pool"
  default     = ""
}

variable "node_pool_max_count" {
  type        = string
  description = "VM maximum amount of nodes for the node pool"
  default     = ""
}

### Helm Chart versions ###
variable "helm_pod_identity_version" {
  type        = string
  description = "Helm chart version of aad-pod-identity"
  default     = ""
}

variable "helm_csi_secrets_version" {
  type        = string
  description = "Helm chart version of secrets-store-csi-driver-provider-azure"
  default     = ""
}

variable "helm_agic_version" {
  type        = string
  description = "Helm chart version of ingress-azure-helm-package"
  default     = ""
}

variable "helm_keda_version" {
  type        = string
  description = "Helm chart version of keda helm package"
  default     = ""
}

#variable "storage_account_name" {
#  type        = string
#  description = "secure remote azure backend storage"
#}

#variable "key_vault_name" {
#  type        = string
#  description = "name of the key vault"
#  default = ""
#}
#variable "key_vault_resource_group" {
#  type        = string
#  description = "resource group of the key vault"
#}

#variable "source_main_env_key_vault_name" {
#  type        = string
#  description = "name of the main source non-ephemeral and existing key vault"
#}
#
#variable "source_main_env_key_vault_resource_group" {
#  type        = string
#  description = "resource group of the source non-ephermal and existing key vault"
#}

variable "azure_tenant_acr_registry_name" {
  type        = string
}
variable "azure_tenant_acr_registry_rg" {
  type        = string
}

