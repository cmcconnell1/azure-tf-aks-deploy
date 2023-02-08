# ingress-nginx 

Bind certificate to ingress controller this is def the more complicated pattern
https://docs.microsoft.com/en-us/azure/aks/csi-secrets-store-nginx-tls#bind-certificate-to-ingress-controller

Ingress Controller - The ingress deployment is modified to declare and mount the provider volume. The secret is imported when ingress pods are created. 
The applications pods have no access to the TLS certificate. This scenario fits scenarios where one team (for example, IT) 
manages and creates infrastructure and networking components (including HTTPS TLS certificates) and other teams manage application lifecycle. 
In this case, ingress is specific to a single namespace/workload and is deployed in the same namespace as the application.

OVERVIEW steps 
to be done for each cert required for develop env
- develop-mycompany-com-chain
- mycompany-com-chain

Pre-requisites 
  Compiled wildcard (with key, intermediate and root chain) TLS certificate
  Imported certificate to AKV
      ```console
      cp ./.orig-files/STAR_mycompany_com.crt mycompany.com.pem
      cp ./.orig-files/mycompany.com.key mycompany.com.key
      cp ./.orig-files/SectigoRSADomainValidationSecureServerCA.crt intermedidate.pem
      cp ./.orig-files/AAACertificateServices.crt ca.pem
      ```

We then combine all three to make this one develop_mycompany_chain.pem
`cat mycompany.com.pem intermedidate.pem ca.pem > mycompany.com.chain.pem`

Next convert from PEM format to PKCS12 format and 
Upload the cert chain file and create secret in the keyvault

i.e. for develop env
`AZURE_KEY_VAULT_NAME=developAksKeyVault2022`

Convert/pack our pem format certs and key into binary PKCS12 format (with NO PASSWORD)
```console
openssl pkcs12 -export -in mycompany.com.chain.pem -inkey mycompany.com.key  -out mycompany-com-chain.pfx
az keyvault certificate import --vault-name $AZURE_KEY_VAULT_NAME  -n mycompany-com-chain  -f mycompany-com-chain.pfx
```

Validate all required certs exist in keyvault
```console
az keyvault certificate list --vault-name $AZURE_KEY_VAULT_NAME | grep '"id"' | egrep 'mycompany-com'
"id": "https://developakskeyvault2022.vault.azure.net/certificates/develop-mycompany-com-chain",
"id": "https://developakskeyvault2022.vault.azure.net/certificates/mycompany-com-chain",
```