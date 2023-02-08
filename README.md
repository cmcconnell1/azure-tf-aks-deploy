# Azure-Terraform-Deployments


## Terraform deployed Azure infra using Github Actions
### Overview
- This project provides tools/utils for various critical and ongoing operational concerns including:
  - Terraform IAC deployments for multiple AKS clusters in multiple environments (Develop, Test, Stage, and Production) and tenants (Dev/Test and Production) in Azure.
  - GitHub Actions (GHA) based workflows (and Terraform wrapper scripts for Ops usage outside of GHA), using multiple Github environments for each distinct Azure AKS cluster (deploying into two separate Azure tenants).
  - Greenfield / First time only requirements setting up the (Azure Tenant based) environment (i.e. requisite service accounts, Terraform remote cloud bucket secure statefiles, etc)
  - scripts for showing the secrets/vars for the Azure Service Principal that drives/owns the automation.
  - scripts for showing the existing Azure Tenant based Service Principal roles.
  - supporting scripts and processes for Upgrading the Azure AKS clusters (and requisite pre-preparation etc)
  - scripts for running commands on the AKS nodes--yes, this is something we should never have to do but if your unlucky enough to have to work in Azure when they push our broken images globally that break all AKS nodes DNS (and they dont report this as an outage)...


![Architecture Diagram AKS deployment](assets/archdiagram_k8s.jpg?raw=true "Architecture Diagram AKS deployment")

## TL;DR:
  - Greenfield / First time _only_ requirements setting up the (Azure Tenant based) environment
    - __Dev/Test__ Tenant and associated Github Actions for the `develop` `stage` and `test` environments
    - `Azure-Pre-Reqs/Dev-Test-github-actions-greenfield-first-deploy-prep-only`
    - __Production__ Tenant and associated Github Actions for the `production` (and possibly future `production-green` and `production-blue`) environments.
    - `Azure-Pre-Reqs/Prod-github-actions-greenfield-first-deploy-prep-only`
  - For showing the secrets/vars for the Azure Service Principal that drives/owns the automation.
    - These secrets/vars are required for configuring the github actions/repos secrets and environments and for authorizing terraform to use the back-end provider for remote state, and automate/deploy to azure tenants, etc. 
    - we fetch the requisite vars/secrets with the environment's show script--i.e. (for `non-prod` which is `develop` up through and including `stage`):
    - this will show both the _non-sensitive_ vars and also fetch the _sensitive_ vars/secrets from the respective key vault.
    - __Dev/Test__
      - `./bin/Dev-Test-show-secrets-and-vars-for-github-repo-and-terraform-provider`
    - __Prod__
      - `./bin/Prod-show-secrets-and-vars-for-github-repo-and-terraform-provider`
  - For showing the existing Azure Tenant based Service Principal roles.
    - TODO: refactor the following two scripts using MS graph as Azure broke these utils with their recent migration to graph.
    - `bin/Dev-Test-show-service-principal-and-applications-roles`
    - `bin/Production-show-service-principal-and-applications-roles`

### Note that in the production environment the naming convention for resources is a bit different (shortened) due to azure keyvault naming limitations (only 24 chars)
- So we had to change the naming pattern for some resources in prod.
  - Instead of the expected pattern: `aks-productionaksterraform` --resource-group `rg-productionaksterraform`
  - we instead have: `aks-prodaksterraform` --resource-group `rg-prodaksterraform`
---
### Deploying / redeploying AKS clusters via Github Actions (GHA) after pre-requisites are done for the first-time/greenfield
- Deploy the requisite env's cluster
  - develop/env cluster:
  ```console
  gh workflow run DEVELOP_DEPLOY_AKS  --ref main
  az aks get-credentials --name aks-developaksterraform --resource-group rg-developaksterraform
  ```
  - test/env cluster:
  ```console
  gh workflow run TEST_DEPLOY_AKS  --ref main
  az aks get-credentials --name aks-testaksterraform --resource-group rg-testaksterraform
  ```
  - stage/env cluster:
  ```console
  gh workflow run STAGE_DEPLOY_AKS  --ref main
  az aks get-credentials --name aks-stageaksterraform --resource-group rg-stageaksterraform
  ```
  - production/env cluster:
  ```console
  gh workflow run PRODUCTION_DEPLOY_AKS  --ref main
  az aks get-credentials --name aks-prodaksterraform --resource-group rg-prodaksterraform
  ```

#### TODO refactor/add auto DNS updates
- The best method is to follow the azure / AKS docs here:
  - [See: Customize CoreDNS with Azure Kubernetes Service](https://learn.microsoft.com/en-us/azure/aks/coredns-custom)
- But note could also just update the Github Actions workflows with a few az commands--see the placeholder in the `DEVELOP_DEPLOY` workflow for a hack-around if needed.
  - To get the public IP which should be used for all services in the cluster
      ```console
      EXTERNAL_IP=$(kubectl get svc -n ingress-nginx | grep 'LoadBalancer' | awk '{print$4}') && echo "EXTERNAL_IP: $EXTERNAL_IP"
      ```
      - Then update azure DNS zones
        - Note: To modify one 'A' record, from IP address 1.2.3.4 to IP address 5.6.7.8:
          ```console
          az network dns record-set a add-record --resource-group $DNS_ZONE_RESOURCE_GROUP --zone-name contoso.com --record-set-name www --ipv4-address 5.6.7.8
          az network dns record-set a remove-record --resource-group $DNS_ZONE_RESOURCE_GROUP --zone-name contoso.com --record-set-name www --ipv4-address 1.2.3.4
          # add the additional commands here...
          ```

### Upgrading AKS clusters and their nodepools
- Always check the docs first [Upgrade an Azure Kubernetes Service (AKS) cluster](https://learn.microsoft.com/en-us/azure/aks/upgrade-cluster?tabs=azure-cli)
  - __"When you upgrade a supported AKS cluster, Kubernetes minor versions can't be skipped. All upgrades must be performed sequentially by major version number. For example, upgrades between 1.14.x -> 1.15.x or 1.15.x -> 1.16.x are allowed, however 1.14.x -> 1.16.x is not allowed."__
- Determine the correct version for the cluster and the region (ensure that AKS version is available)
  ```console
  ./bin/show-supported-aks-versions-in-region

  fetching supported AKS cluster versions from Azure regions

  REGION: westus
  [
    "1.22.11",
    "1.22.15",
    "1.23.8",
    "1.23.12",
    "1.24.3",
    "1.24.6",
    "1.25.2"
  ]
  ```
  - Note: other regions skipped here.

- Now determine the current clusters AKS and nodepool versions by running `./bin/show-aks-cluster-versions`
  ```console
  ./bin/show-aks-cluster-versions

  CLUSTER_NAME: aks-developaksterraform

  NAME                          STATUS   ROLES   AGE     VERSION   INTERNAL-IP   EXTERNAL-IP   OS-IMAGE             KERNEL-VERSION      CONTAINER-RUNTIME
  aks-aks-24838650-vmss00000s   Ready    agent   3h47m   v1.24.6   10.100.1.33   <none>        Ubuntu 22.04.1 LTS   5.15.0-1022-azure   containerd://1.6.4+azure-4
  aks-aks-24838650-vmss00000t   Ready    agent   3h44m   v1.24.6   10.100.1.4    <none>        Ubuntu 22.04.1 LTS   5.15.0-1022-azure   containerd://1.6.4+azure-4
  aks-aks-24838650-vmss00000v   Ready    agent   3h29m   v1.24.6   10.100.1.62   <none>        Ubuntu 22.04.1 LTS   5.15.0-1022-azure   containerd://1.6.4+azure-4
  aks-aks-24838650-vmss00000w   Ready    agent   3h29m   v1.24.6   10.100.1.91   <none>        Ubuntu 22.04.1 LTS   5.15.0-1022-azure   containerd://1.6.4+azure-4

  Client Version: v1.25.0
  Kustomize Version: v4.5.7
  Server Version: v1.24.6

  The AKS cluster: aks-developaksterraform nodepool version is: 1.24.6
  ```

- Now simply increment the environment/cluster $env.tfvars file to only be one minor release above current cluster version:
- i.e.: `kubernetes_version = "1.25.2"`
  - ./environments/develop/develop.tfvars
  - ./environments/test/test.tfvars
  - ./environments/stage/stage.tfvars
  - ./environments/production/production.tfvars
- Then re-run the `$ENV_DEPLOY_AKS` workflow as shown above in Deploying / redeploying clusters section.

### Optional: Using wrapper scripts to execute Terraform (provided for Ops testing and troubleshooting)
- Note in the production environment we disable the auto-approve in the `DESTROY` terraform wrapper script.
- These scripts will also use the requisite service principal (az login and still use the remote az state, etc.)
- Helpful for rapid dev, testing, troubleshooting, etc. These exist for all four main environments.
  ```console
  tree azure-tf-deploy/02_AKS_Cluster/environments/production/terraform/bin
    ├── DESTROY
    ├── apply
    ├── init
    ├── keyvault-test
    ├── plan
    └── show
  ```

#### Dev/Test Tenant and Associated githubactions workflow required metadata/config
- Show existing requisite (non-secret--for those look in the specified azure key vault) configs/var
```console
cd azure-tf-deploy && ./bin/Dev-Test-show-secrets-and-vars-for-github-repo-and-terraform-provider

Show our key/value pairs from the deployment outfile: ./Azure-Pre-Reqs/devtestgithubactions-vars
########################################
KEY: DATE_TAG VALUE: 2022.03.03.12.42.17
KEY: ENV VALUE: devtest
KEY: SUBSCRIPTION_ID VALUE: xxxxxxxxxx
KEY: MY_RANDOM VALUE: 29003
KEY: LOCATION VALUE: westus
KEY: RESOURCE_GROUP VALUE: devtestdevops
KEY: STORAGE_ACCOUNT_NAME VALUE: devtestdevops29003
KEY: CONTAINER_NAME VALUE: devtestdevopstfstate
KEY: ENV_TAG VALUE: environment=devtestdevops
KEY: SP_NAME VALUE: devtestdevops
KEY: AZURE_KEY_VAULT_NAME VALUE: devtestdevops
<SNIP>
```

## Project Organization

**02_AKS_Cluster:**
- The first `caller` workflow `02_AKS_Cluster` will call and trigger a reusable workflow `az_tf_plan` and create a foundational terraform deployment `PLAN` based on the repository `path: ./02_AKS_Cluster` containing the terraform ROOT module/configuration of an Azure Resource Group and key vault. The plan artifacts are validated, compressed and uploaded into the workflow artifacts, the caller workflow `02_AKS_Cluster` will then call and trigger the second reusable workflow `az_tf_apply` that will download and decompress the `PLAN` artifact and trigger the deployment based on the plan. (Also demonstrated is how to use GitHub Environments to do multi staged environment based deployments with approvals - Optional)

**03_etc_etc:**
- Placeholder: Possibly create more terraform root modules/configurations to deploy more resources in a non-monolithic way here...

## Architecture
The architecture consists of the following components:

__Public IP__ —
 Public IP addresses enable Azure resources to communicate to Internet and public-facing Azure services.

__Azure Kubernetes Service (AKS)__ —
AKS is an Azure service that deploys a managed Kubernetes cluster.

__Virtual Network__ —
An Azure Virtual Network (VNet) is used to securely communicate between AKS and Application Gateway and control all outbound connections.

__Virtual Network subnets__ —
Application Gateway and AKS are deployed in their own subnets within the same virtual network.

__External Data Sources__ —
Microservices are typically stateless and write state to external data stores, such as CosmosDB.

__Azure Key Vault__ —
Azure Key Vault is a cloud service for securely storing and accessing secrets and certificates.

__Pod Identity__ —
Pod Identity enables Kubernetes applications to access cloud resources securely with Azure Active Directory.

__Azure Active Directory__ —
Azure Active Directory (Azure AD) is Microsoft's cloud-based identity and access management service. Pod Identity uses Azure AD to create and manage other Azure resources such as Azure Application Gateway and Azure Key Vault.

__Azure Container Registry__ —
Container Registry is used to store private Docker images, which are deployed to the cluster. AKS can authenticate with Container Registry using its Azure AD identity.

__KEDA__ —
KEDA is a Kubernetes-based Event Driven Autoscaler that (horizontally) scales a container by adding additional pods based on the number of events needing to be processed.

__Azure Key Vault Provider for Secrets Store__
- [Azure/secrets-store-csi-driver-provider-azure](https://github.com/Azure/secrets-store-csi-driver-provider-azure)
Azure Key Vault provider for Secrets Store CSI Driver allows you to get secret contents stored in an Azure Key Vault instance and use the Secrets Store CSI driver interface to mount them into Kubernetes pods.

  - Features
    * Mounts secrets/keys/certs to pod using a CSI Inline volume
    * Supports mounting multiple secrets store objects as a single volume
    * Supports multiple secrets stores as providers. Multiple providers can run in the same cluster simultaneously.
    * Supports pod portability with the SecretProviderClass CRD
    * Supports Linux and Windows containers
    * __Supports sync with Kubernetes Secrets__
    * Supports auto rotation of secrets

## Input Variables
- Note for most/all settings see the env-specific vars file--i.e.: develop.tfvars, test.tfvars, etc.

| Name | Description | Default |
|------|-------------|---------|
| `app_name` | Application name (used as suffix in all resources) | see env vars file |
| `location` | Azure region where to create resources | see env vars file |
| `domain_name_label` | Unique domain name label for AKS Cluster | see env vars file |
| `kubernetes_version` | Kubernetes version of the node pool | see env vars file currently 1.24.6 |
| `vm_size_node_pool` | VM Size of the node pool | see vm_size_node_pool in env vars file |
| `node_pool_min_count` | VM minimum amount of nodes for the node pool | 2 |
| `node_pool_max_count` | VM maximum amount of nodes for the node pool | 4 |
| `helm_pod_identity_version` | Helm chart version of aad-pod-identity | see env vars file |
| `helm_csi_secrets_version` | Helm chart version of secrets-store-csi-driver-provider-azure | see env vars file |
| `helm_agic_version` | Helm chart version of ingress-azure-helm-package | see env vars file |
| `helm_keda_version` | Helm chart version of keda helm package | see env vars file |

## Output variables
| Name | Description |
|------|-------------|
| `aks_name` | Name of the AKS cluster |
| `appgw_name` | Not currently in use due to it lacking maturity and most options that all other ingress options provide |
| `appgw_fqdn` | Currently unused until it matures and gets more features |
| `acr_name` | Name of the ephemeral and env/cluster-specific Azure Container Registry that is deployed along with the AKS cluster |
| `keyvault_name` | Name of the ephemeral and env/cluster-specific Azure Key Vault |
| `log_analytics_name` | Name of the Log Analytics workspace |
| `vnet_name` | Name of the Virtual Network |
| `rg_name` | Name of the Resource Group |

## Terraform Details
- For all environments, the storage account is for the terraform containers (which store their terraform state files)
  - [Dev/Test Storage Account: devtestdevops29003 Containers](https://portal.azure.com/#@mycompany.net/resource/subscriptions/xxxxxxxxxxxxxxx/resourceGroups/devtestdevops/providers/Microsoft.Storage/storageAccounts/devtestdevops29003/containersList)
    - Currently we should have the following containers:
      - develop-aks-cluster-tfstate 
      - stage-aks-cluster-tfstate
      - test-aks-cluster-tfstate
  - [Production Storage Account: proddevops10381 Containers](https://portal.azure.com/#@mviproduction.onmicrosoft.com/resource/subscriptions/xxxxxxxxxxxxxxx/resourceGroups/proddevops/providers/Microsoft.Storage/storageAccounts/proddevops10381/overview)
      - Currently we should have the following container:
        - production-aks-cluster-tfstate

# References / Credits, etc.
- This project based its Terraform modules which were initially from [Bart Jensons older and now possibly? deprecated repo](https://github.com/bart-jansen/terraform-aks-appgw-acr-keyvault-loganalytics)
