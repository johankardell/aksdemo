CLUSTER_NAME="aks-loki"
RESOURCE_GROUP_NAME="rg-aks-loki"

az group create --name $RESOURCE_GROUP_NAME --location swedencentral
az aks create --name $CLUSTER_NAME --resource-group $RESOURCE_GROUP_NAME --node-provisioning-mode Auto --network-plugin azure --network-plugin-mode overlay --network-dataplane cilium --kubernetes-version 1.31.1 --ssh-access disabled --node-vm-size Standard_B2ms
#az aks update --name $CLUSTER_NAME --resource-group $RESOURCE_GROUP_NAME --node-provisioning-mode Auto
az aks nodepool add --cluster-name $CLUSTER_NAME --resource-group $RESOURCE_GROUP_NAME --name apps --node-count 0 --node-vm-size Standard_D4s_v5 --node-osdisk-size 30 --ssh-access disabled --max-pods 250

az aks get-credentials -g "${RESOURCE_GROUP_NAME}" -n ${CLUSTER_NAME} --format azure --overwrite-existing
kubelogin convert-kubeconfig -l azurecli

#ArgoCD
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

pwd=$(k get secret -n argocd argocd-initial-admin-secret -o json | jq .data.password -r | base64 -d)

k port-forward svc/argocd-server -n argocd 8080:443
argocd login localhost:8080 --username admin --password $pwd

argocd app create nginx --repo https://github.com/johankardell/argocd-demo --path ./nginx/ --dest-namespace nginx-demo --dest-server https://kubernetes.default.svc --sync-policy manual