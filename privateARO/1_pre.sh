# https://learn.microsoft.com/en-us/azure/openshift/howto-create-private-cluster-4x

HUB_VNET_NAME=Hub_VNET
FW_SUBNET_NAME=AzureFirewallSubnet
BASTION_SUBNET_NAME=AzureBastionSubnet
HUB_VNET_PREFIX=10.0.0.0/22 # IP address range of the Virtual network (VNet).
BASTION_SUBNET_PREFIX=10.0.0.128/26 # IP address range of the Bastion subnet 
FW_SUBNET_PREFIX=10.0.0.0/26 # IP address range of the Firewall subnet
JUMPBOX_SUBNET_PREFIX=10.0.0.64/26 # IP address range of the Jumpbox subnet

SPOKE_VNET_NAME=Spoke_VNET
JUMPBOX_SUBNET_NAME=JumpboxSubnet
ENDPOINTS_SUBNET_NAME=endpoints-subnet
APPGW_SUBNET_NAME=app-gw-subnet
ARO_SUBNET_MASTER_NAME=aro-master-subnet
ARO_SUBNET_WORKER_NAME=aro-worker-subnet
LOADBALANCER_SUBNET_NAME=loadbalancer-subnet
SPOKE_VNET_PREFIX=10.1.0.0/22 # IP address range of the Virtual network (VNet).
ARO_SUBNET_MASTER_PREFIX=10.1.0.0/24 # IP address range of the ARO Master subnet
ARO_SUBNET_WORKER_PREFIX=10.1.1.0/24 # IP address range of the ARO Worker subnet
LOADBALANCER_SUBNET_PREFIX=10.1.2.0/28 # IP address range of the Loadbalancer subnet
APPGW_SUBNET_PREFIX=10.1.2.128/25 # IP address range of the Application Gateway subnet
ENDPOINTS_SUBNET_PREFIX=10.1.2.16/28 # IP address range of the Endpoints subnet

HUB_RG=rg-hub
SPOKE_RG=rg-spoke
LOCATION=swedencentral 
BASTION_NSG_NAME=Bastion_NSG
JUMPBOX_NSG_NAME=Jumpbox_NSG
ENDPOINTS_NSG_NAME=Endpoints_NSG
LOADBALANCER_NSG_NAME=Loadbalancer_NSG
APPGW_NSG=Appgw_NSG
FW_NAME=azure-firewall
APPGW_NAME=AppGateway
ROUTE_TABLE_NAME=spoke-rt
ARO_IDENTITY_NAME=aro-msi
JUMPBOX_LINUX_VM_NAME=Jumpbox-VM
JUMPBOX_WINDOWS_VM_NAME=jumpbox-winvm

JUMPBOX_PASSWORD="changeme" # Change this
ARO_CLUSTER_NAME=private-aro
ACR_NAME=jkarothehardway
STUDENT_NAME=johan
DNS_NAME=jkarothehardway

az provider register -n Microsoft.RedHatOpenShift --wait
az provider register -n Microsoft.Compute --wait
az provider register -n Microsoft.Network --wait
az provider register -n Microsoft.Storage --wait

az group create --name $HUB_RG --location $LOCATION
az group create --name $SPOKE_RG --location $LOCATION