# ingress-nginx 

https://docs.microsoft.com/en-us/azure/aks/csi-secrets-store-nginx-tls

Bind certificate to the application
https://learn.microsoft.com/en-us/azure/aks/csi-secrets-store-nginx-tls#bind-certificate-to-application
https://azure.github.io/secrets-store-csi-driver-provider-azure/docs/configurations/ingress-tls/#optional-deploy-aad-pod-identity

Application - The application deployment manifest declares and mounts the provider volume. Only when the application is deployed,
is the certificate made available in the cluster, and when the application is removed the secret is removed as well.
This scenario fits development teams who are responsible for the application’s security infrastructure and their integration with the cluster.

NOTES:
README.md
We import the ingress TLS certificate to the cluster via 'Ingress Controller' method
The actual managed identity in azure has the naming convention: 'id-{ENV}aksterraform-pod' i.e.: id-developaksterraform-pod
The AzureIdentityBinding for pods (i.e.: ingress-nginx/ingress-nginx-controller) MUST match the selector i.e.: set 'AAD_POD_IDENTITY_NAME:podidentity'


OVERVIEW steps 
to be done for each cert required for test env
- test-mycompany-com-chain
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

We then combine all three
`cat mycompany.com.pem intermedidate.pem ca.pem > mycompany.com.chain.pem`

Next convert from PEM format to PKCS12 format and 
Upload the cert chain file and create secret in the keyvault

i.e. for test env
`AZURE_KEY_VAULT_NAME=testAksKeyVault2022`

Convert/pack our pem format certs and key into binary PKCS12 format (with NO PASSWORD)
```console
openssl pkcs12 -export -in mycompany.com.chain.pem -inkey mycompany.com.key  -out mycompany-com-chain.pfx
az keyvault certificate import --vault-name $AZURE_KEY_VAULT_NAME  -n mycompany-com-chain  -f mycompany-com-chain.pfx
```

Validate all required certs exist in keyvault
```console
az keyvault certificate list --vault-name $AZURE_KEY_VAULT_NAME | grep '"id"' | egrep 'mycompany-com'
"id": "https://testakskeyvault2022.vault.azure.net/certificates/test-mycompany-com-chain",
"id": "https://testakskeyvault2022.vault.azure.net/certificates/mycompany-com-chain",
```
