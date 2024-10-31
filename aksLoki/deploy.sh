CLUSTER_NAME="aks-loki"
RESOURCE_GROUP_NAME="rg-aks-loki"
APPS_POOL_NAME="apps"
SA_NAME="jklokidemo"
SA_RG="rg-aks-loki"
SA_SUB=$(az account show --name four --query id -o tsv)

az group create --name $RESOURCE_GROUP_NAME --location swedencentral

az aks create \
    --name $CLUSTER_NAME \
    --resource-group $RESOURCE_GROUP_NAME \
    --network-plugin azure \
    --network-plugin-mode overlay \
    --kubernetes-version 1.31.1 \
    --ssh-access disabled \
    --enable-image-cleaner \
    --node-vm-size Standard_B4ms

az aks nodepool add \
    --cluster-name $CLUSTER_NAME \
    --resource-group $RESOURCE_GROUP_NAME \
    --name $APPS_POOL_NAME \
    --node-count 3 \
    --node-vm-size Standard_D4s_v5 \
    --node-osdisk-size 30 \
    --ssh-access disabled \
    --max-pods 250 \
    --labels loki="true"

MI_ID=$(az aks show --resource-group $RESOURCE_GROUP_NAME --name $CLUSTER_NAME --query identityProfile.kubeletidentity.clientId -o tsv)
az role assignment create \
    --assignee $MI_ID \
    --role "Storage Blob Data Contributor" \
    --scope $(az storage account show --name $SA_NAME --resource-group $SA_RG --subscription $SA_SUB --query id --output tsv)

az aks get-credentials -g "${RESOURCE_GROUP_NAME}" -n ${CLUSTER_NAME} --format azure --overwrite-existing
kubelogin convert-kubeconfig -l azurecli

#ArgoCD
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

pwd=$(k get secret -n argocd argocd-initial-admin-secret -o json | jq .data.password -r | base64 -d)

k port-forward svc/argocd-server -n argocd 8080:443
argocd login localhost:8080 --username admin --password $pwd

# Demo app, just to have something simple and minimal. Has nothing to do with Loki.
argocd app create nginx \
    --repo https://github.com/johankardell/argocd-demo \
    --path ./nginx/ \
    --dest-namespace nginx-demo \
    --dest-server https://kubernetes.default.svc \
    --sync-policy automated \
    --sync-option CreateNamespace=true

argocd app create grafana \
    --repo https://grafana.github.io/helm-charts \
    --helm-chart grafana \
    --revision 8.5.8 \
    --dest-namespace grafana \
    --dest-server https://kubernetes.default.svc \
    --sync-policy automated \
    --sync-option CreateNamespace=true

argocd app create loki-helm \
    --repo https://github.com/johankardell/argocd-demo \
    --path ./loki/ \
    --dest-namespace loki \
    --dest-server https://kubernetes.default.svc \
    --sync-policy automated \
    --sync-option CreateNamespace=true

argocd app create fluentbit-helm \
    --repo https://github.com/johankardell/argocd-demo \
    --path ./fluentbit/ \
    --dest-namespace fluentbit \
    --dest-server https://kubernetes.default.svc \
    --sync-policy automated \
    --sync-option CreateNamespace=true

argocd app create logger \
    --repo https://github.com/johankardell/argocd-demo \
    --path ./logger/ \
    --dest-namespace logger \
    --dest-server https://kubernetes.default.svc \
    --sync-policy automated \
    --sync-option CreateNamespace=true

# Grafana (default user admin)
k get secret -n grafana grafana -o json | jq '.data.["admin-password"]' -r | base64 -d
k port-forward svc/grafana -n grafana 3000:80
# Add Loki as source in Grafana: http://loki-gateway.loki.svc

# Run sample app that generates logs
k run logger --image chentex/random-logger:latest
