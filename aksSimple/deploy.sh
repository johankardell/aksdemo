sshKey=`cat ~/.ssh/id_rsa.pub`
IP="$(curl ipinfo.io/ip 2>/dev/null)"

# az stack sub create --deny-settings-mode none --delete-all --location swedencentral --template-file main.bicep -n aksSimple --parameters sshkey="$sshKey" --yes

az deployment sub create --location swedencentral --template-file main.bicep -n aksSimple --parameters sshkey="$sshKey" managementIP=$IP

az aks get-credentials -g rg-aks-simple-demo -n aks-simple-demo --format azure --overwrite-existing
kubelogin convert-kubeconfig -l azurecli
