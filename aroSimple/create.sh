az provider register --namespace Microsoft.RedHatOpenShift --wait
az provider register --namespace Microsoft.Compute --wait
az provider register --namespace Microsoft.Storage --wait
az provider register --namespace Microsoft.Authorization --wait

LOCATION=westeurope          
RESOURCEGROUP=aro-rg           
CLUSTER=cluster                
VIRTUALNETWORK=aro-vnet         

az group create --name $RESOURCEGROUP --location $LOCATION
az network vnet create --resource-group $RESOURCEGROUP --name $VIRTUALNETWORK --address-prefixes 10.0.0.0/22
az network vnet subnet create --resource-group $RESOURCEGROUP --vnet-name $VIRTUALNETWORK --name master-subnet --address-prefixes 10.0.0.0/23
az network vnet subnet create --resource-group $RESOURCEGROUP --vnet-name $VIRTUALNETWORK --name worker-subnet --address-prefixes 10.0.2.0/23

az aro create --resource-group $RESOURCEGROUP --name $CLUSTER --vnet $VIRTUALNETWORK --master-subnet master-subnet --worker-subnet worker-subnet --version 4.17.27
