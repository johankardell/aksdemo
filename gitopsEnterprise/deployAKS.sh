#prereq:
# az feature register --namespace Microsoft.ContainerService --name NetworkIsolatedClusterPreview
# az feature register --namespace "Microsoft.ContainerService" --name "NRGLockdownPreview"
# az provider register -n Microsoft.ContainerService

sshKey=`cat ~/.ssh/id_rsa.pub`
location="swedencentral"

IP="$(curl ipinfo.io/ip 2>/dev/null)"

# Will this kill AKS deployment? Yes. Keeping it here for memory.
# az group create -n rg-aks-gitopsEnterprise-demo-infra -l $location

az stack group create --resource-group rg-aks-gitopsEnterprise-demo --deny-settings-mode none --action-on-unmanage deleteAll --template-file aks.bicep -n gitopsEnterpriseAKS --yes --parameters sshkey="$sshKey" location="$location" 

