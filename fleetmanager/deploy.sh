az extension add --name fleet --allow-preview true

export SUBSCRIPTION_ID=$(az account show --query id -o tsv)
export RESOURCE_GROUP='rg-aks-fleet-demo'
export FLEET='demo-fleet'
export AKS_CLUSTER_NAME_1='demo-aks-fleet-1'
export AKS_CLUSTER_NAME_2='demo-aks-fleet-2'
export AKS_CLUSTER_NAME_3='demo-aks-fleet-3'
export LOCATION='swedencentral'
export MEMBER_CLUSTER_ID_1=/subscriptions/${SUBSCRIPTION_ID}/resourceGroups/${RESOURCE_GROUP}/providers/Microsoft.ContainerService/managedClusters/${AKS_CLUSTER_NAME_1}
export MEMBER_CLUSTER_ID_2=/subscriptions/${SUBSCRIPTION_ID}/resourceGroups/${RESOURCE_GROUP}/providers/Microsoft.ContainerService/managedClusters/${AKS_CLUSTER_NAME_2}
export MEMBER_CLUSTER_ID_3=/subscriptions/${SUBSCRIPTION_ID}/resourceGroups/${RESOURCE_GROUP}/providers/Microsoft.ContainerService/managedClusters/${AKS_CLUSTER_NAME_3}

az group create --name ${RESOURCE_GROUP} --location $LOCATION

az fleet create --resource-group ${RESOURCE_GROUP} --name ${FLEET} --location $LOCATION --enable-hub

az aks create --resource-group $RESOURCE_GROUP --name $AKS_CLUSTER_NAME_1 --node-count 1 --generate-ssh-keys --kubernetes-version 1.27
az aks create --resource-group $RESOURCE_GROUP --name $AKS_CLUSTER_NAME_2 --node-count 1 --generate-ssh-keys --kubernetes-version 1.27
az aks create --resource-group $RESOURCE_GROUP --name $AKS_CLUSTER_NAME_3 --node-count 1 --generate-ssh-keys --kubernetes-version 1.27

az fleet member create --resource-group ${RESOURCE_GROUP} --fleet-name ${FLEET} --name ${AKS_CLUSTER_NAME_1} --member-cluster-id ${MEMBER_CLUSTER_ID_1}
az fleet member create --resource-group ${RESOURCE_GROUP} --fleet-name ${FLEET} --name ${AKS_CLUSTER_NAME_2} --member-cluster-id ${MEMBER_CLUSTER_ID_2}
az fleet member create --resource-group ${RESOURCE_GROUP} --fleet-name ${FLEET} --name ${AKS_CLUSTER_NAME_3} --member-cluster-id ${MEMBER_CLUSTER_ID_3}

# az group delete -n $RESOURCE_GROUP