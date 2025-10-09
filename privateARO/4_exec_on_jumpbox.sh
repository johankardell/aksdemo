#Connect to Jumpbox through Bastion

az network bastion ssh --name bastionhost -g rg-hub --target-ip-address 10.0.0.69 --auth-type password --username azureuser

# Update apt repo
sudo apt update 
# Install Docker
sudo apt install docker.io -y
# Install azure CLI
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
# Install AKS CLI (kubectl)
sudo az aks install-cli
# Add user to Docker group
sudo usermod -aG docker $USER

az login
az account set --subscription "five"

wget https://mirror.openshift.com/pub/openshift-v4/clients/oc/latest/linux/oc.tar.gz
tar -xvf oc.tar.gz
sudo mv oc /usr/local/bin/
sudo chmod +x /usr/local/bin/oc

# Run pre.sh-script to set variables on jumpbox

az aro list-credentials \
  --name $ARO_CLUSTER_NAME \
  --resource-group $SPOKE_RG

az aro get-admin-kubeconfig   --name $ARO_CLUSTER_NAME   --resource-group $SPOKE_RG

export KUBECONFIG=~/

kubectl get nodes
