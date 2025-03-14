sshKey=`cat ~/.ssh/id_rsa.pub`
IP="$(curl ipinfo.io/ip 2>/dev/null)"

az deployment sub create --location francecentral --template-file main.bicep -n aksAGC --parameters sshkey="$sshKey" managementIP=$IP

az aks get-credentials -g rg-aksAGC-managed -n aks-agc-managed --format azure --overwrite-existing
kubelogin convert-kubeconfig -l azurecli
