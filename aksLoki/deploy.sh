# az extension add --name aks-preview

CLUSTER_NAME="aks-loki"
RESOURCE_GROUP_NAME="rg-aks-loki"
SYS_NODEPOOL_NAME="system"
APPS_POOL_NAME="apps"
LOKI_POOL_NAME="loki"
WINDOWS_POOL_NAME="win"
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
    --nodepool-name $SYS_NODEPOOL_NAME \
    --os-sku AzureLinux \
    --node-vm-size Standard_B4ms

az aks nodepool update \
    --cluster-name $CLUSTER_NAME \
    --resource-group $RESOURCE_GROUP_NAME \
    --name $SYS_NODEPOOL_NAME \
    --node-taints CriticalAddonsOnly=true:NoSchedule

az aks nodepool add \
    --cluster-name $CLUSTER_NAME \
    --resource-group $RESOURCE_GROUP_NAME \
    --name $APPS_POOL_NAME \
    --min-count 0 \
    --max-count 5 \
    --enable-cluster-autoscaler \
    --node-vm-size standard_d4ads_v5 \
    --node-osdisk-size 120 \
    --ssh-access disabled \
    --max-pods 250 \
    --labels nginx="true" \
    --os-sku AzureLinux \
    --no-wait

az aks nodepool add \
    --cluster-name $CLUSTER_NAME \
    --resource-group $RESOURCE_GROUP_NAME \
    --name $LOKI_POOL_NAME \
    --node-count 3 \
    --node-vm-size standard_d4ads_v5 \
    --node-osdisk-size 120 \
    --ssh-access disabled \
    --max-pods 250 \
    --labels loki="true" \
    --zones 1 2 3 \
    --os-sku AzureLinux \
    --no-wait

# az aks nodepool add \
#     --cluster-name $CLUSTER_NAME \
#     --resource-group $RESOURCE_GROUP_NAME \
#     --name $WINDOWS_POOL_NAME \
#     --node-count 1 \
#     --node-vm-size standard_d4ads_v5 \
#     --node-osdisk-size 250 \
#     --os-type Windows \
#     --os-sku Windows2022 \
#     --max-pods 250 \
#     --node-taints windows=true:NoSchedule \
#     --no-wait

KUBELET_CLIENT_ID=$(az aks show --resource-group $RESOURCE_GROUP_NAME --name $CLUSTER_NAME --query identityProfile.kubeletidentity.clientId -o tsv)
KUBELET_OBJECT_ID=$(az aks show --resource-group $RESOURCE_GROUP_NAME --name $CLUSTER_NAME --query identityProfile.kubeletidentity.objectId -o tsv)

# Update in argocd-demo repo with correct KUBELET_CLIENT_ID
echo $KUBELET_CLIENT_ID

az role assignment create \
    --assignee-object-id "$KUBELET_OBJECT_ID" \
    --role "Storage Blob Data Contributor" \
    --scope "$(az storage account show --name "$SA_NAME" --resource-group "$SA_RG" --subscription "$SA_SUB" --query id --output tsv)"

az aks get-credentials -g "${RESOURCE_GROUP_NAME}" -n ${CLUSTER_NAME} --format azure --overwrite-existing
kubelogin convert-kubeconfig -l azurecli

#ArgoCD
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

argocdPwd=$(k get secret -n argocd argocd-initial-admin-secret -o json | jq .data.password -r | base64 -d)
echo $argocdPwd 

k port-forward svc/argocd-server -n argocd 8080:443
argocd login localhost:8080 --username admin --password $argocdPwd

# Demo app, just to have something simple and minimal. Has nothing to do with Loki.
argocd app create nginx \
    --repo https://github.com/johankardell/argocd-demo \
    --path ./nginx/ \
    --dest-namespace nginx \
    --dest-server https://kubernetes.default.svc \
    --sync-policy automated \
    --sync-option CreateNamespace=true

# Grafana without pvc
# argocd app create grafana \
#     --repo https://grafana.github.io/helm-charts \
#     --helm-chart grafana \
#     --revision 8.5.8 \
#     --dest-namespace grafana \
#     --dest-server https://kubernetes.default.svc \
#     --sync-policy automated \
#     --sync-option CreateNamespace=true

argocd app create grafana-pvc \
    --repo https://github.com/johankardell/argocd-demo \
    --path ./grafana-pvc/ \
    --dest-namespace grafana-pvc \
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

# Has nothing to do with Loki
# argocd app create aspnet \
#     --repo https://github.com/johankardell/argocd-demo \
#     --path ./aspnet/ \
#     --dest-namespace aspnet \
#     --dest-server https://kubernetes.default.svc \
#     --sync-policy automated \
#     --sync-option CreateNamespace=true

# Grafana (default user admin/admin) - no pvc
grafanaPwd=$(k get secret -n grafana grafana -o json | jq '.data.["admin-password"]' -r | base64 -d)
echo $grafanaPwd
k port-forward svc/grafana -n grafana 3000:80

# Add Loki as source in Grafana: http://loki-gateway.loki.svc

argocd app delete aspnet -y
argocd app delete fluentbit-helm -y
argocd app delete logger -y
argocd app delete loki-helm -y
argocd app delete grafana-pvc -y
argocd app delete nginx -y
argocd app delete grafana -y


