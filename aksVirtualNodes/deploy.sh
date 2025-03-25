az provider register --namespace Microsoft.ContainerInstance

az group create -n rg-vnodes -l swedencentral

az network vnet create --resource-group rg-vnodes --name vnet-aks-vnodes --address-prefixes 10.0.0.0/8 --subnet-name aks --subnet-prefix 10.240.0.0/16
az network vnet subnet create --resource-group rg-vnodes --vnet-name vnet-aks-vnodes --name vnodes --address-prefixes 10.241.0.0/16
subnet_id="$(az network vnet subnet show --resource-group rg-vnodes --vnet-name vnet-aks-vnodes --name aks --query id -o tsv)"
az network nsg create --resource-group rg-vnodes --name nsg-aks

az network nsg rule create --resource-group rg-vnodes --nsg-name nsg-aks --name allow-http --priority 100 \
    --access Allow --protocol Tcp --direction Inbound --source-address-prefixes Internet --source-port-ranges '*' \
    --destination-address-prefixes '*' --destination-port-ranges 80

az network vnet subnet update --resource-group rg-vnodes --vnet-name vnet-aks-vnodes --name aks --network-security-group nsg-aks
az network vnet subnet update --resource-group rg-vnodes --vnet-name vnet-aks-vnodes --name vnodes --network-security-group nsg-aks

az aks create --resource-group rg-vnodes --name aks-vnodes --node-count 5 --network-plugin azure --vnet-subnet-id $subnet_id --ssh-access disabled

az aks enable-addons --resource-group rg-vnodes --name aks-vnodes --addons virtual-node --subnet-name vnodes

az aks get-credentials -g rg-vnodes -n aks-vnodes --format azure
kubelogin convert-kubeconfig -l azurecli

kubectl apply -f deploy.yaml