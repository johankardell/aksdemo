

# az identity create \
#     --resource-group $SPOKE_RG \
#     --name $AKS_IDENTITY_NAME-${STUDENT_NAME}

# IDENTITY_ID=$(az identity show \
#     --resource-group $SPOKE_RG \
#     --name $AKS_IDENTITY_NAME-${STUDENT_NAME} \
#     --query id \
#     --output tsv)

# PRINCIPAL_ID=$(az identity show \
#     --resource-group $SPOKE_RG \
#     --name $AKS_IDENTITY_NAME-${STUDENT_NAME} \
#     --query principalId \
#     --output tsv)

# RT_SCOPE=$(az network route-table show \
#     --resource-group $SPOKE_RG \
#     --name $ROUTE_TABLE_NAME  \
#     --query id \
#     --output tsv)

# az role assignment create \
#     --assignee $PRINCIPAL_ID\
#     --scope $RT_SCOPE \
#     --role "Network Contributor"

# LB_SUBNET_SCOPE=$(az network vnet subnet list \
#     --resource-group $SPOKE_RG \
#     --vnet-name $SPOKE_VNET_NAME \
#     --query "[?name=='$LOADBALANCER_SUBNET_NAME'].id" \
#     --output tsv)

# az role assignment create \
#     --assignee $PRINCIPAL_ID \
#     --scope $LB_SUBNET_SCOPE \
#     --role "Network Contributor"

# AKS_SUBNET_SCOPE=$(az network vnet subnet list \
#     --resource-group $SPOKE_RG \
#     --vnet-name $SPOKE_VNET_NAME \
#     --query "[?name=='$AKS_SUBNET_NAME'].id" \
#     --output tsv)

# az aks create --resource-group $SPOKE_RG --node-count 2 --vnet-subnet-id $AKS_SUBNET_SCOPE --name $AKS_CLUSTER_NAME-${STUDENT_NAME} --enable-private-cluster --outbound-type userDefinedRouting --enable-oidc-issuer --enable-workload-identity --generate-ssh-keys --assign-identity $IDENTITY_ID --network-plugin azure --network-policy azure --disable-public-fqdn --zones 1 2 3

# az aks nodepool add --resource-group $SPOKE_RG --cluster-name $AKS_CLUSTER_NAME-${STUDENT_NAME} --name userpool --node-count 3 --mode user --zones 1 2 3 --enable-cluster-autoscaler --min-count 1 --max-count 5

# NODE_GROUP=$(az aks show --resource-group $SPOKE_RG --name $AKS_CLUSTER_NAME-${STUDENT_NAME} --query nodeResourceGroup -o tsv)
DNS_ZONE_NAME=$(az network private-dns zone list --resource-group $NODE_GROUP --query "[0].name" -o tsv)
HUB_VNET_ID=$(az network vnet show -g $HUB_RG -n $HUB_VNET_NAME --query id --output tsv)

az network private-dns link vnet create --name "hubnetdnsconfig" --registration-enabled false --resource-group $NODE_GROUP --virtual-network $HUB_VNET_ID --zone-name $DNS_ZONE_NAME 

# # Connect to the jumpbox and run the following commands:

# # Update apt repo
# sudo apt update 
# # Install Docker
# sudo apt install docker.io -y
# # Install azure CLI
# curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
# # Install AKS CLI (kubectl)
# sudo az aks install-cli
# # Add user to Docker group
# sudo usermod -aG docker $USER

# az login
# az account set --subscription "network"

# SPOKE_RG=rg-spoke
# AKS_CLUSTER_NAME=private-aks
# STUDENT_NAME=johan

# az aks get-credentials --resource-group $SPOKE_RG --name $AKS_CLUSTER_NAME-${STUDENT_NAME}

# kubectl get nodes

# ## Back to workstation

# az acr create \
#     --resource-group $SPOKE_RG \
#     --name $ACR_NAME \
#     --sku Premium \
#     --admin-enabled false \
#     --location $LOCATION \
#     --allow-trusted-services false \
#     --public-network-enabled false

# az network private-dns zone create \
#   --resource-group $SPOKE_RG \
#   --name "privatelink.azurecr.io"

# az network private-dns link vnet create \
#   --resource-group $SPOKE_RG \
#   --zone-name "privatelink.azurecr.io" \
#   --name ACRDNSSpokeLink \
#   --virtual-network $SPOKE_VNET_NAME \
#   --registration-enabled false

# HUB_VNET_ID=$(az network vnet show --resource-group $HUB_RG --name $HUB_VNET_NAME --query id --output tsv)

# az network private-dns link vnet create \
#   --resource-group $SPOKE_RG \
#   --zone-name "privatelink.azurecr.io" \
#   --name ACRDNSHubLink \
#   --virtual-network $HUB_VNET_ID \
#   --registration-enabled false

# REGISTRY_ID=$(az acr show --name $ACR_NAME \
#   --query 'id' --output tsv)

# az network private-endpoint create \
#     --name ACRPrivateEndpoint \
#     --resource-group $SPOKE_RG \
#     --vnet-name $SPOKE_VNET_NAME \
#     --subnet $ENDPOINTS_SUBNET_NAME \
#     --private-connection-resource-id $REGISTRY_ID \
#     --group-ids registry \
#     --connection-name PrivateACRConnection

# NETWORK_INTERFACE_ID=$(az network private-endpoint show \
#   --name ACRPrivateEndpoint \
#   --resource-group $SPOKE_RG \
#   --query 'networkInterfaces[0].id' \
#   --output tsv)

# az network nic show --ids $NETWORK_INTERFACE_ID |grep azurecr.io -B 7

# az network private-dns record-set a create \
#   --name $ACR_NAME \
#   --zone-name privatelink.azurecr.io \
#   --resource-group $SPOKE_RG

# az network private-dns record-set a create \
#   --name $ACR_NAME.$LOCATION.data \
#   --zone-name privatelink.azurecr.io \
#   --resource-group $SPOKE_RG

# az network private-dns record-set a add-record \
#   --record-set-name $ACR_NAME.$LOCATION.data \
#   --zone-name privatelink.azurecr.io \
#   --resource-group $SPOKE_RG \
#   --ipv4-address 10.1.1.20

#   az network private-dns record-set a add-record \
#   --record-set-name $ACR_NAME \
#   --zone-name privatelink.azurecr.io \
#   --resource-group $SPOKE_RG \
#   --ipv4-address 10.1.1.21

# az aks update \
#     --resource-group $SPOKE_RG \
#     --name $AKS_CLUSTER_NAME-${STUDENT_NAME} \
#     --attach-acr $ACR_NAME

## On Jumpbox

# az login
# az account set --subscription network

# vim Dockerfile

#     FROM nginx
#     EXPOSE 80

# docker build --tag nginx .

# docker tag nginx jkaksthehardway.azurecr.io/nginx

# docker push jkaksthehardway.azurecr.io/nginx

# vim test-pod.yaml
#     apiVersion: v1
#     kind: Pod
#     metadata:
#     name: internal-test-app
#     labels:
#         app: internal-test-app
#     spec:
#     containers:
#     - name: nginx
#         image: <ACR NAME>.azurecr.io/nginx
#         ports:
#         - containerPort: 80
#     ---
#     apiVersion: v1
#     kind: Service
#     metadata:
#     name: internal-test-app-service
#     annotations:
#         service.beta.kubernetes.io/azure-load-balancer-internal: "true"
#         service.beta.kubernetes.io/azure-load-balancer-internal-subnet: "loadbalancer-subnet"
#     spec:
#     type: LoadBalancer
#     ports:
#     - port: 80
#     selector:
#         app: internal-test-app

# kubectl apply -f test-pod.yaml

# # ...wait...

# curl 10.1.1.4

# ## Back to workstation

# az network public-ip create -g $SPOKE_RG -n AGPublicIPAddress --dns-name $DNS_NAME --allocation-method Static --sku Standard --location $LOCATION

# az network application-gateway waf-policy create --name ApplicationGatewayWAFPolicy --resource-group $SPOKE_RG

# az network public-ip show -g $SPOKE_RG -n AGPublicIPAddress --query dnsSettings.fqdn

# openssl genrsa -out my.key 2048
# openssl req -new -x509 -sha256 -key my.key -out my.crt -days 365
# openssl pkcs12 -export -out my.pfx -inkey my.key -in my.crt -password pass:$JUMPBOX_PASSWORD

# az network application-gateway create \
#   --name AppGateway \
#   --location $LOCATION \
#   --resource-group $SPOKE_RG \
#   --vnet-name $SPOKE_VNET_NAME \
#   --subnet $APPGW_SUBNET_NAME \
#   --capacity 1 \
#   --sku WAF_v2 \
#   --http-settings-cookie-based-affinity Disabled \
#   --frontend-port 443 \
#   --http-settings-port 80 \
#   --http-settings-protocol Http \
#   --priority "1" \
#   --public-ip-address AGPublicIPAddress \
#   --cert-file my.pfx \
#   --cert-password "$JUMPBOX_PASSWORD" \
#   --waf-policy ApplicationGatewayWAFPolicy \
#   --servers 10.1.1.4

# az network application-gateway probe create \
#     --gateway-name $APPGW_NAME \
#     --resource-group $SPOKE_RG \
#     --name health-probe \
#     --protocol Http \
#     --path / \
#     --interval 30 \
#     --timeout 120 \
#     --threshold 3 \
#     --host 127.0.0.1

# az network application-gateway http-settings update -g $SPOKE_RG --gateway-name $APPGW_NAME -n appGatewayBackendHttpSettings --probe health-probe


## Cleanup
# az group delete -n $HUB_RG
# az group delete -n $SPOKE_RG