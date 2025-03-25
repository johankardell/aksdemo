az feature register --namespace Microsoft.ContainerService --name EnableAPIServerVnetIntegrationPreview
az feature register --namespace Microsoft.ContainerService --name NRGLockdownPreview
az feature register --namespace Microsoft.ContainerService --name SafeguardsPreview
az feature register --namespace Microsoft.ContainerService --name NodeAutoProvisioningPreview
az feature register --namespace Microsoft.ContainerService --name DisableSSHPreview
az feature register --namespace Microsoft.ContainerService --name AutomaticSKUPreview

az feature show --namespace Microsoft.ContainerService --name AutomaticSKUPreview

az group create -n rg-aksauto -l swedencentral
az aks create --resource-group rg-aksauto --name aksauto --sku automatic --ssh-access disabled

az aks get-credentials -g rg-aksauto -n aksauto --format azure
kubelogin convert-kubeconfig -l azurecli

kubectl get nodes -o custom-columns=NAME:.metadata.name,INSTANCE-TYPE:.metadata.labels.node\\.kubernetes\\.io/instance-type,ZONE:.metadata.labels.topology\\.kubernetes\\.io/zone