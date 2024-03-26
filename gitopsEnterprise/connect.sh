az extension add --name ssh
chmod 0700 ~/.ssh
chmod 0600 ~/.ssh/id_rsa
chmod 0600 ~/.ssh/id_rsa.pub

rg="rg-aks-gitopsEnterprise-demo"
vm="vm-ubuntu"
bastion="bastion-gitopsEnterprise-demo"
adminuser="azureuser"

vmid=$(az vm show -n $vm -g $rg --query id -o tsv)

az network bastion ssh --name $bastion --resource-group $rg --target-resource-id $vmid --auth-type ssh-key --username $adminuser --ssh-key ~/.ssh/id_rsa

# sudo apt update && sudo apt upgrade -y && sudo apt autoremove -y
# curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
# sudo az aks install-cli

# Get the tenant ID (where logged in)
# tenant_id=$(az account show --query tenantId -o tsv)
# echo "Tenant ID: $tenant_id"

# login to the tenant (do not add tenantid to public githubrepo)
# az login -t <tenantid>
# az account set -s aks
# az aks get-credentials -g rg-aks-gitopsEnterprise-demo -n aks-gitopsEnterprise-demo --format azure
# kubelogin convert-kubeconfig -l azurecli
# alias k=kubectl