# NOTE disregard terraform warnings about vars not in use in terraform code
# we use the tfvars file for setting vars for other non-terraform resources including k8s/ingress etc.

### PHASE-2
# NOTE: why the wonky long names?
#   the Container Registry needs to be globally unique
#   the resource group needs to be globally unique
#   the keyvault name might already be in use
#   etc.

#--------------------------------------------------------------
# General
#--------------------------------------------------------------
app_name = "testaksterraform"
location = "westus3"

# this coorelates to the actual environment: develop, test, stage, production
domain_name_label = "test"

#--------------------------------------------------------------
# vars for reference only for environment scripts, etc.
# cluster/env ephermeal key vault 
#--------------------------------------------------------------
# These vars will be dynamically created and used within terraform modules/code
# i.e. we do NOT control the naming of the associated terraform generated resources here.
# comes from root/main: "rg-${var.app_name}"
tf_generated_key_vault_name = "kv-testaksterraform"
tf_generated_resource_group = "rg-testaksterraform"

#--------------------------------------------------------------
# AKS configuration params
#--------------------------------------------------------------
# !NOTE! splunk-connect-for-k8s is broken on 1.24.6 and later so we had to downgrade the new clusters
kubernetes_version = "1.24.3"
# https://docs.microsoft.com/en-us/azure/virtual-machines/dv3-dsv3-series
vm_size_node_pool = "Standard_D4_v3"
node_pool_min_count = "2"
# temp set node_pool min/max to null for upgrade only then change back
node_pool_max_count = "4"

#--------------------------------------------------------------
# Helm Chart versions
#--------------------------------------------------------------
# https://artifacthub.io/packages/helm/aad-pod-identity/aad-pod-identity
helm_pod_identity_version = "4.1.10"
# Note the dynamically generated name of the pod identity (in azure) will be "id-${ENV}aksterraform-pod"

# https://github.com/Azure/secrets-store-csi-driver-provider-azure/tree/master/charts/csi-secrets-store-provider-azure
helm_csi_secrets_version = "1.3.0"

# Not currently in use
# Azure Application Gateway Ingress Controller for Kubernetes (AGIC) 
# https://azure.github.io/application-gateway-kubernetes-ingress/how-tos/helm-upgrade/
# helm repo add \
#     application-gateway-kubernetes-ingress \
#     https://appgwingress.blob.core.windows.net/ingress-azure-helm-package/
# helm search repo -l application-gateway-kubernetes-ingress
helm_agic_version = "1.4.0"

# https://github.com/kedacore/charts
# https://github.com/kedacore/charts/releases/latest
# helm repo add kedacore https://kedacore.github.io/charts
# helm search repo kedacore
# helm search repo kedacore | grep 'keda '
helm_keda_version = "2.8.2"

azure_tenant_acr_registry_name = "yourContainerRegistry"
azure_tenant_acr_registry_rg = "yourAcrRg"

# ingress-nginx
# https://github.com/kubernetes/ingress-nginx/releases 
# https://github.com/kubernetes/ingress-nginx/tree/main/charts/ingress-nginx
# https://docs.microsoft.com/en-us/azure/aks/ingress-basic?tabs=azure-cli#import-the-images-used-by-the-helm-chart-into-your-acr
# https://learn.microsoft.com/en-us/azure/aks/kubernetes-helm # for WTF versions do we use for these
# NOTE: to get these values we pull the chart down and look at the default values in the values.yaml file
ingress_nginx_azure_tenant_id = "xxxxxxxxxxxxxxx"
ingress_nginx_namespace = "ingress-nginx"
ingress_nginx_source_registry = "k8s.gcr.io"
ingress_nginx_controller_registry = "yourContainerRegistry.azurecr.io"
ingress_nginx_controller_image = "ingress-nginx/controller"
ingress_nginx_controller_tag = "v1.5.1"
ingress_nginx_patch_image = "ingress-nginx/kube-webhook-certgen"
ingress_nginx_patch_tag = "v1.3.0"
ingress_nginx_defaultbackend_image = "defaultbackend-amd64"
ingress_nginx_defaultbackend_tag = "1.5"
ingress_nginx_helm_chart_release = "4.4.0"
ingress_nginx_controller_replicacount = "2"

# NOTES:
# We import the ingress TLS certificate to the cluster via 'Ingress Controller' method
# The actual managed identity in azure has the naming convention: 
# 'id-{ENV}aksterraform-pod' i.e.: id-testaksterraform-pod
# NOTE: THIS identity must have Get,List access to the existing env-specific keyvaults--i.e.  testAksKeyVault2022 and for other envs their requisite env-specific keyvault
# The AzureIdentityBinding for pods (i.e.: ingress-nginx/ingress-nginx-controller) MUST match the selector i.e.: set 'AAD_POD_IDENTITY_NAME:podidentity'
# Add access to the env-specific keyvault required for the Pod Identity to have access to the keyvault to create the environment/services secrets/certificates (TLS)
#
# To allow access to the env-specific keyvault required for the Pod Identity to have access to the keyvault to create the environment/services secrets/certificates (TLS)
# the Pod Identity
# for test:       id-testaksterraform-pod
#
# needs to have access the Resource / Keyvault
# for test:       testAksKeyVault2022 kv-testaksterraform
#aad_pod_identity_name = "podidentity"
#existing_keyvault_id="/subscriptions/xxxxxxxxxxxxxxx/resourceGroups/testAksKeyVault2022/providers/Microsoft.KeyVault/vaults/testAksKeyVault2022"

ingress_nginx_primary_akv_name = "testAksKeyVault2022"
# primary cert for subdomain the new order
ingress_nginx_primary_cert_name = "test-mycompany-com-chain"
# secondary cert for top-level legacy support until migrated
ingress_nginx_secondary_cert_name = "mycompany-com-chain"
