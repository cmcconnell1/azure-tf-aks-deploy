# Subnet
resource "azurerm_subnet" "aks_subnet" {
  name                 = "snet-${var.app_name}-aks"
  resource_group_name  = var.resource_group_name
  virtual_network_name = var.virtual_network_name
  address_prefixes     = ["10.100.1.0/24"]
}

# Subnet permission
resource "azurerm_role_assignment" "aks_subnet_rbac" {
  scope                = azurerm_subnet.aks_subnet.id
  role_definition_name = "Network Contributor"
  principal_id         = azurerm_kubernetes_cluster.aks.kubelet_identity.0.object_id
}

# Allow the AKS to pull images from ACR
resource "azurerm_role_assignment" "aks_acr_pull_role_ephemeral_acr" {
  scope                = var.acr_id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_kubernetes_cluster.aks.kubelet_identity[0].object_id
}

# grant access to the existing azure tenants ACR (i.e. we have two: one for dev/test and one for prod)
data "azurerm_container_registry" "acr_name" {
  name = var.azure_tenant_acr_registry_name
  resource_group_name = var.azure_tenant_acr_registry_rg
}

resource "azurerm_role_assignment" "aks_acr_pull_role_tenant_acr" {
  scope                = data.azurerm_container_registry.acr_name.id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_kubernetes_cluster.aks.kubelet_identity[0].object_id
  #skip_service_principal_aad_check = true
}

# Kubernetes Service
resource "azurerm_kubernetes_cluster" "aks" {
  name                = "aks-${var.app_name}"
  location            = var.location
  resource_group_name = var.resource_group_name
  dns_prefix          = "aks-${var.app_name}"
  kubernetes_version  = var.kubernetes_version

  default_node_pool {
    type                = "VirtualMachineScaleSets"
    name                = "aks${var.domain_name_label}"
    vm_size             = var.vm_size_node_pool
    os_disk_size_gb     = 50
    vnet_subnet_id      = azurerm_subnet.aks_subnet.id
    enable_auto_scaling = true
    min_count           = var.node_pool_min_count
    max_count           = var.node_pool_max_count
    orchestrator_version = var.kubernetes_version
  }

  network_profile {
    network_plugin = "azure"
  }

  identity {
    type = "SystemAssigned"
  }

  # TODO: this broke in the azure provider even on our version that was working before
  # WTH did they change this to? where this goes now tf docs are not clear
  # https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/kubernetes_cluster#oms_agent
  #oms_agent {
  #  enabled                    = true
  #  log_analytics_workspace_id = var.log_analytics_id
  #}

  tags = {
    environment = var.domain_name_label
    managed_by = "terraform"
    project = "azure-tf-deploy"
  }
}

