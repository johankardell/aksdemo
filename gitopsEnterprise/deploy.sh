sshKey=`cat ~/.ssh/id_rsa.pub`
IP="$(curl ipinfo.io/ip 2>/dev/null)"

## Deployment stack
az stack sub create --deny-settings-mode none --delete-all --location swedencentral --template-file main.bicep -n gitopsEnterprise --parameters sshkey="$sshKey" adminIp="$IP" --yes

# az aks get-credentials -g rg-aks-gitopsEnterprise-demo -n aks-gitopsEnterprise-demo --format azure
# kubelogin convert-kubeconfig -l azurecli
