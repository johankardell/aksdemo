sshKey=`cat ~/.ssh/id_rsa.pub`

az stack sub create --deny-settings-mode none --delete-all --location swedencentral --template-file main.bicep -n aksSimple --parameters sshkey="$sshKey" --yes

az aks get-credentials -g rg-aks-simple-demo -n aks-simple-demo --format azure
kubelogin convert-kubeconfig -l azurecli
