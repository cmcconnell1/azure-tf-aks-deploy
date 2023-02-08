# Create a resource group for this deployment
module "resource_group" {
  source = "./modules/resource_group"

  location = var.location
  name     = "rg-${var.app_name}"
}

# Create a common key vault to store application secrets
module "keyvault" {
  source = "./modules/key_vault"

  name                = "kv-${var.app_name}"
  location            = var.location
  resource_group_name = module.resource_group.name
  #existing_keyvault_id = var.existing_keyvault_id

  # Config
  enabled_for_deployment          = "true"
  enabled_for_disk_encryption     = "true"
  enabled_for_template_deployment = "true"
}

# Create the Azure Container Registry
module "acr" {
  source = "./modules/acr"

  name                = "acr${var.app_name}"
  resource_group_name = module.resource_group.name
  location            = var.location
}

# Key Vault Secrets - ACR username & password
module "kv_secret_docker_password" {
  source = "./modules/key_vault_secret"

  name         = "acr-docker-password"
  value        = module.acr.registry_password
  key_vault_id = module.keyvault.key_vault_id

  depends_on = [module.keyvault.azurerm_key_vault_access_policy]
}

module "kv_secret_docker_username" {
  source = "./modules/key_vault_secret"

  name         = "acr-docker-username"
  value        = module.acr.registry_username
  key_vault_id = module.keyvault.key_vault_id

  depends_on = [module.keyvault.azurerm_key_vault_access_policy]
}

# Create virtual network
module "vnet" {
  source = "./modules/vnet"

  name                = "vnet-${var.app_name}"
  resource_group_name = module.resource_group.name
  location            = var.location
}

# Create Log Analytics Insights #
module "log_analytics" {
  source = "./modules/log_analytics"

  app_name            = var.app_name
  resource_group_name = module.resource_group.name
  location            = var.location
}

# Create AKS Cluster
module "aks" {
  source = "./modules/aks"

  resource_group_name  = module.resource_group.name
  app_name             = var.app_name
  location             = var.location
  virtual_network_name = module.vnet.name

  acr_id           = module.acr.id
  log_analytics_id = module.log_analytics.id
  
  # this is the ephemeral clusters keyvault
  key_vault_id     = module.keyvault.key_vault_id

  # this is the pre-existing and env-specific keyvault that we copy secrets/certs from to the ephereal cluster keyvault
  #source_main_env_key_vault_name = var.source_main_env_key_vault_name
  #source_main_env_key_vault_resource_group = var.source_main_env_key_vault_resource_group

  ### AKS configuration params ###
  kubernetes_version  = var.kubernetes_version
  vm_size_node_pool   = var.vm_size_node_pool
  node_pool_min_count = var.node_pool_min_count
  node_pool_max_count = var.node_pool_max_count

  ### Helm Chart versions ###
  helm_pod_identity_version = var.helm_pod_identity_version
  helm_csi_secrets_version  = var.helm_csi_secrets_version
  helm_keda_version         = var.helm_keda_version

  azure_tenant_acr_registry_rg = var.azure_tenant_acr_registry_rg
  azure_tenant_acr_registry_name = var.azure_tenant_acr_registry_name

  #helm_agic_version = var.helm_agic_version
}
