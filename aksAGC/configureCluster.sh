# Connect to cluster
az aks get-credentials -g rg-aks-agc-demo -n aks-agc-demo --format azure --overwrite-existing
kubelogin convert-kubeconfig -l azurecli

# Setup dapr
dapr init -k --enable-ha=true

# Install Kured
latest=$(curl -s https://api.github.com/repos/kubereboot/kured/releases | jq -r '.[0].tag_name')
kubectl apply -f "https://github.com/kubereboot/kured/releases/download/$latest/kured-$latest-dockerhub.yaml"
