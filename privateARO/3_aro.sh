az aro create \
  --resource-group $SPOKE_RG \
  --name $ARO_CLUSTER_NAME \
  --vnet $SPOKE_VNET_NAME \
  --master-subnet $ARO_SUBNET_MASTER_NAME \
  --worker-subnet $ARO_SUBNET_WORKER_NAME \
  --apiserver-visibility Private \
  --ingress-visibility Private \
  --outbound-type UserDefinedRouting \
  --master-vm-size Standard_D8as_v5 \
  --worker-vm-size Standard_D4as_v5

az acr create \
    --resource-group $SPOKE_RG \
    --name $ACR_NAME \
    --sku Premium \
    --admin-enabled false \
    --location $LOCATION \
    --allow-trusted-services false \
    --public-network-enabled false

az network private-dns zone create \
  --resource-group $SPOKE_RG \
  --name "privatelink.azurecr.io"

az network private-dns link vnet create \
  --resource-group $SPOKE_RG \
  --zone-name "privatelink.azurecr.io" \
  --name ACRDNSSpokeLink \
  --virtual-network $SPOKE_VNET_NAME \
  --registration-enabled false

HUB_VNET_ID=$(az network vnet show --resource-group $HUB_RG --name $HUB_VNET_NAME --query id --output tsv)

az network private-dns link vnet create \
  --resource-group $SPOKE_RG \
  --zone-name "privatelink.azurecr.io" \
  --name ACRDNSHubLink \
  --virtual-network $HUB_VNET_ID \
  --registration-enabled false

REGISTRY_ID=$(az acr show --name $ACR_NAME \
  --query 'id' --output tsv)

az network private-endpoint create \
    --name ACRPrivateEndpoint \
    --resource-group $SPOKE_RG \
    --vnet-name $SPOKE_VNET_NAME \
    --subnet $ENDPOINTS_SUBNET_NAME \
    --private-connection-resource-id $REGISTRY_ID \
    --group-ids registry \
    --connection-name PrivateACRConnection

NETWORK_INTERFACE_ID=$(az network private-endpoint show \
  --name ACRPrivateEndpoint \
  --resource-group $SPOKE_RG \
  --query 'networkInterfaces[0].id' \
  --output tsv)

az network nic show --ids $NETWORK_INTERFACE_ID |grep azurecr.io -B 7

az network private-dns record-set a create \
  --name $ACR_NAME \
  --zone-name privatelink.azurecr.io \
  --resource-group $SPOKE_RG

az network private-dns record-set a create \
  --name $ACR_NAME.$LOCATION.data \
  --zone-name privatelink.azurecr.io \
  --resource-group $SPOKE_RG

az network private-dns record-set a add-record \
  --record-set-name $ACR_NAME.$LOCATION.data \
  --zone-name privatelink.azurecr.io \
  --resource-group $SPOKE_RG \
  --ipv4-address 10.1.2.20

  az network private-dns record-set a add-record \
  --record-set-name $ACR_NAME \
  --zone-name privatelink.azurecr.io \
  --resource-group $SPOKE_RG \
  --ipv4-address 10.1.2.21
