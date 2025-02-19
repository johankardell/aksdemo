# az extension add --name aks-preview

CLUSTER_NAME="aks-istio"
RESOURCE_GROUP_NAME="rg-aks-istio"
SYS_NODEPOOL_NAME="system"
APPS_POOL_NAME="apps"

az group create \
    --name $RESOURCE_GROUP_NAME \
    --location swedencentral

az aks create \
    --name $CLUSTER_NAME \
    --resource-group $RESOURCE_GROUP_NAME \
    --network-plugin azure \
    --network-plugin-mode overlay \
    --kubernetes-version 1.31 \
    --ssh-access disabled \
    --enable-image-cleaner \
    --nodepool-name $SYS_NODEPOOL_NAME \
    --os-sku AzureLinux \
    --node-vm-size standard_d4ads_v5

az aks nodepool add \
    --cluster-name $CLUSTER_NAME \
    --resource-group $RESOURCE_GROUP_NAME \
    --name $APPS_POOL_NAME \
    --min-count 0 \
    --max-count 5 \
    --enable-cluster-autoscaler \
    --node-vm-size standard_d4ads_v5 \
    --node-osdisk-size 120 \
    --ssh-access disabled \
    --max-pods 250 \
    --os-sku AzureLinux \
    --no-wait

az aks nodepool update \
    --cluster-name $CLUSTER_NAME \
    --resource-group $RESOURCE_GROUP_NAME \
    --name $SYS_NODEPOOL_NAME \
    --node-taints CriticalAddonsOnly=true:NoSchedule

az aks mesh enable \
    --revision asm-1-23 \
    --resource-group $RESOURCE_GROUP_NAME \
    --name $CLUSTER_NAME

az aks mesh enable-ingress-gateway \
    --ingress-gateway-type External \
    --resource-group $RESOURCE_GROUP_NAME \
    --name $CLUSTER_NAME

az aks get-credentials -g "${RESOURCE_GROUP_NAME}" -n ${CLUSTER_NAME} --format azure --overwrite-existing
kubelogin convert-kubeconfig -l azurecli

kubectl create namespace demo
kubectl label namespace demo istio-injection=disabled

# az group delete --name $RESOURCE_GROUP_NAME --no-wait