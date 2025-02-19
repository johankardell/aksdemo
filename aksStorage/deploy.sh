# https://learn.microsoft.com/en-us/azure/storage/container-storage/use-container-storage-with-local-disk#5-deploy-a-pod-and-attach-a-persistent-volume

az extension add --name fleet --allow-preview true

export SUBSCRIPTION_ID=$(az account show --name one --query id -o tsv)
export SUBSCRIPTION_ID1=$(az account show --name one --query id -o tsv )
export SUBSCRIPTION_ID2=$(az account show --name two --query id -o tsv )
export SUBSCRIPTION_ID3=$(az account show --name three --query id -o tsv )
export SUBSCRIPTION_ID4=$(az account show --name four --query id -o tsv )
export SUBSCRIPTION_ID5=$(az account show --name five --query id -o tsv )

export RESOURCE_GROUP='rg-aks-fleet-demo'
export FLEET='demo-fleet'
export AKS_RESOURCE_GROUP='rg-aks-storage'
export AKS_CLUSTER_NAME_1='aks-storage-d8-nvme'
export AKS_CLUSTER_NAME_2='aks-storage-d16-temp'
export AKS_CLUSTER_NAME_3='aks-storage-l8-nvme'
export AKS_CLUSTER_NAME_4='aks-storage-l8-temp'
export AKS_CLUSTER_NAME_5='aks-storage-d8-temp'
export LOCATION='swedencentral'
export MEMBER_CLUSTER_ID_1=/subscriptions/${SUBSCRIPTION_ID1}/resourceGroups/${AKS_RESOURCE_GROUP}/providers/Microsoft.ContainerService/managedClusters/${AKS_CLUSTER_NAME_1}
export MEMBER_CLUSTER_ID_2=/subscriptions/${SUBSCRIPTION_ID2}/resourceGroups/${AKS_RESOURCE_GROUP}/providers/Microsoft.ContainerService/managedClusters/${AKS_CLUSTER_NAME_2}
export MEMBER_CLUSTER_ID_3=/subscriptions/${SUBSCRIPTION_ID3}/resourceGroups/${AKS_RESOURCE_GROUP}/providers/Microsoft.ContainerService/managedClusters/${AKS_CLUSTER_NAME_3}
export MEMBER_CLUSTER_ID_4=/subscriptions/${SUBSCRIPTION_ID4}/resourceGroups/${AKS_RESOURCE_GROUP}/providers/Microsoft.ContainerService/managedClusters/${AKS_CLUSTER_NAME_4}
export MEMBER_CLUSTER_ID_5=/subscriptions/${SUBSCRIPTION_ID5}/resourceGroups/${AKS_RESOURCE_GROUP}/providers/Microsoft.ContainerService/managedClusters/${AKS_CLUSTER_NAME_5}
export K8s_version='1.31' # Use older version and update via Fleet manager - or just use newer version

az account set --subscription $SUBSCRIPTION_ID
az group create --name ${RESOURCE_GROUP} --location $LOCATION
az fleet create --resource-group ${RESOURCE_GROUP} --name ${FLEET} --location $LOCATION --no-wait

(
    az group create --name ${AKS_RESOURCE_GROUP} --location $LOCATION --subscription $SUBSCRIPTION_ID1
    az aks create --resource-group $AKS_RESOURCE_GROUP --name $AKS_CLUSTER_NAME_1 --node-count 2 --kubernetes-version $K8s_version --ssh-access disabled --node-vm-size Standard_D4lds_v5 --node-osdisk-type Ephemeral --nodepool-taints "CriticalAddonsOnly=true:NoSchedule" --subscription $SUBSCRIPTION_ID1
    az aks nodepool add --resource-group $AKS_RESOURCE_GROUP --cluster-name $AKS_CLUSTER_NAME_1 --ssh-access disabled --name storage --node-count 3 --node-vm-size Standard_D8lds_v6 --os-type Linux --os-sku AzureLinux --subscription $SUBSCRIPTION_ID1
    az fleet member create --resource-group ${RESOURCE_GROUP} --fleet-name ${FLEET} --name ${AKS_CLUSTER_NAME_1} --member-cluster-id ${MEMBER_CLUSTER_ID_1} --subscription $SUBSCRIPTION_ID
    az aks update -n $AKS_CLUSTER_NAME_1 -g $AKS_RESOURCE_GROUP --enable-azure-container-storage ephemeralDisk --storage-pool-option nvme --azure-container-storage-nodepools storage --no-wait --subscription $SUBSCRIPTION_ID1
    az aks get-credentials -n $AKS_CLUSTER_NAME_1 -g $AKS_RESOURCE_GROUP --subscription $SUBSCRIPTION_ID1 --overwrite-existing
) &

(
    az group create --name ${AKS_RESOURCE_GROUP} --location $LOCATION --subscription $SUBSCRIPTION_ID2
    az aks create --resource-group $AKS_RESOURCE_GROUP --name $AKS_CLUSTER_NAME_2 --node-count 2 --kubernetes-version $K8s_version --ssh-access disabled --node-vm-size Standard_D4lds_v5 --node-osdisk-type Ephemeral --nodepool-taints "CriticalAddonsOnly=true:NoSchedule" --subscription $SUBSCRIPTION_ID2
    az aks nodepool add --resource-group $AKS_RESOURCE_GROUP --cluster-name $AKS_CLUSTER_NAME_2 --ssh-access disabled --name storage --node-count 3 --node-vm-size Standard_D16ads_v5 --os-type Linux --os-sku AzureLinux --subscription $SUBSCRIPTION_ID2
    az fleet member create --resource-group ${RESOURCE_GROUP} --fleet-name ${FLEET} --name ${AKS_CLUSTER_NAME_2} --member-cluster-id ${MEMBER_CLUSTER_ID_2} --subscription $SUBSCRIPTION_ID
    az aks update -n $AKS_CLUSTER_NAME_2 -g $AKS_RESOURCE_GROUP --enable-azure-container-storage ephemeralDisk --storage-pool-option temp --azure-container-storage-nodepools storage --no-wait --subscription $SUBSCRIPTION_ID2
    az aks get-credentials -n $AKS_CLUSTER_NAME_2 -g $AKS_RESOURCE_GROUP --subscription $SUBSCRIPTION_ID2 --overwrite-existing
) &

(
    az group create --name ${AKS_RESOURCE_GROUP} --location $LOCATION --subscription $SUBSCRIPTION_ID3
    az aks create --resource-group $AKS_RESOURCE_GROUP --name $AKS_CLUSTER_NAME_3 --node-count 2 --kubernetes-version $K8s_version --ssh-access disabled --node-vm-size Standard_D4lds_v5 --node-osdisk-type Ephemeral --nodepool-taints "CriticalAddonsOnly=true:NoSchedule" --subscription $SUBSCRIPTION_ID3
    az aks nodepool add --resource-group $AKS_RESOURCE_GROUP --cluster-name $AKS_CLUSTER_NAME_3 --ssh-access disabled --name storage --node-count 3 --node-vm-size Standard_L8s_v3 --os-type Linux --os-sku AzureLinux --subscription $SUBSCRIPTION_ID3
    az fleet member create --resource-group ${RESOURCE_GROUP} --fleet-name ${FLEET} --name ${AKS_CLUSTER_NAME_3} --member-cluster-id ${MEMBER_CLUSTER_ID_3} --subscription $SUBSCRIPTION_ID
    az aks update -n $AKS_CLUSTER_NAME_3 -g $AKS_RESOURCE_GROUP --enable-azure-container-storage ephemeralDisk --storage-pool-option nvme --azure-container-storage-nodepools storage --no-wait --subscription $SUBSCRIPTION_ID3
    az aks get-credentials -n $AKS_CLUSTER_NAME_3 -g $AKS_RESOURCE_GROUP --subscription $SUBSCRIPTION_ID3 --overwrite-existing
) &

(
    az group create --name ${AKS_RESOURCE_GROUP} --location $LOCATION --subscription $SUBSCRIPTION_ID4
    az aks create --resource-group $AKS_RESOURCE_GROUP --name $AKS_CLUSTER_NAME_4 --node-count 2 --kubernetes-version $K8s_version --ssh-access disabled --node-vm-size Standard_D4lds_v5 --node-osdisk-type Ephemeral --nodepool-taints "CriticalAddonsOnly=true:NoSchedule" --subscription $SUBSCRIPTION_ID4
    az aks nodepool add --resource-group $AKS_RESOURCE_GROUP --cluster-name $AKS_CLUSTER_NAME_4 --ssh-access disabled --name storage --node-count 3 --node-vm-size Standard_L8s_v3 --os-type Linux --os-sku AzureLinux --subscription $SUBSCRIPTION_ID4
    az fleet member create --resource-group ${RESOURCE_GROUP} --fleet-name ${FLEET} --name ${AKS_CLUSTER_NAME_4} --member-cluster-id ${MEMBER_CLUSTER_ID_4} --subscription $SUBSCRIPTION_ID
    az aks update -n $AKS_CLUSTER_NAME_4 -g $AKS_RESOURCE_GROUP --enable-azure-container-storage ephemeralDisk --storage-pool-option temp --azure-container-storage-nodepools storage --no-wait --subscription $SUBSCRIPTION_ID4
    az aks get-credentials -n $AKS_CLUSTER_NAME_4 -g $AKS_RESOURCE_GROUP --subscription $SUBSCRIPTION_ID4 --overwrite-existing
) &

(
    az group create --name ${AKS_RESOURCE_GROUP} --location $LOCATION --subscription $SUBSCRIPTION_ID5
    az aks create --resource-group $AKS_RESOURCE_GROUP --name $AKS_CLUSTER_NAME_5 --node-count 2 --kubernetes-version $K8s_version --ssh-access disabled --node-vm-size Standard_D4lds_v5 --node-osdisk-type Ephemeral --nodepool-taints "CriticalAddonsOnly=true:NoSchedule" --subscription $SUBSCRIPTION_ID5
    az aks nodepool add --resource-group $AKS_RESOURCE_GROUP --cluster-name $AKS_CLUSTER_NAME_5 --ssh-access disabled --name storage --node-count 3 --node-vm-size Standard_D8ads_v5 --os-type Linux --os-sku AzureLinux --subscription $SUBSCRIPTION_ID5
    az fleet member create --resource-group ${RESOURCE_GROUP} --fleet-name ${FLEET} --name ${AKS_CLUSTER_NAME_5} --member-cluster-id ${MEMBER_CLUSTER_ID_5} --subscription $SUBSCRIPTION_ID
    az aks update -n $AKS_CLUSTER_NAME_5 -g $AKS_RESOURCE_GROUP --enable-azure-container-storage ephemeralDisk --storage-pool-option temp --azure-container-storage-nodepools storage --no-wait --subscription $SUBSCRIPTION_ID5
    az aks get-credentials -n $AKS_CLUSTER_NAME_5 -g $AKS_RESOURCE_GROUP --subscription $SUBSCRIPTION_ID5 --overwrite-existing
) &

wait

# apply the correct K8s manifest to each cluster. NVME or Temp.

# benchmark - the manifests deploys a pod named fiopod. Exec into it and run.
k exec -it fiopod -- /bin/bash
apt update && apt install -y fio
fio --name=benchtest --size=800m --filename=/volume/test --direct=1 --rw=randrw --ioengine=libaio --bs=4k --iodepth=16 --numjobs=8 --time_based --runtime=60



# when done - delete everything

az account set --subscription $SUBSCRIPTION_ID
az group delete -n $RESOURCE_GROUP --no-wait

az account set --subscription $SUBSCRIPTION_ID1
az group delete -n $AKS_RESOURCE_GROUP --no-wait

az account set --subscription $SUBSCRIPTION_ID2
az group delete -n $AKS_RESOURCE_GROUP --no-wait

az account set --subscription $SUBSCRIPTION_ID3
az group delete -n $AKS_RESOURCE_GROUP --no-wait

az account set --subscription $SUBSCRIPTION_ID4
az group delete -n $AKS_RESOURCE_GROUP --no-wait

az account set --subscription $SUBSCRIPTION_ID5
az group delete -n $AKS_RESOURCE_GROUP --no-wait
