
# Create NSG
az network nsg create \
    --resource-group $HUB_RG \
    --name $BASTION_NSG_NAME \
    --location $LOCATION

az network nsg rule create --name AllowHttpsInbound \
    --nsg-name $BASTION_NSG_NAME --priority 120 --resource-group $HUB_RG\
    --access Allow --protocol TCP --direction Inbound \
    --source-address-prefixes "Internet" \
    --source-port-ranges "*" \
    --destination-address-prefixes "*" \
    --destination-port-ranges "443"

az network nsg rule create --name AllowGatewayManagerInbound \
    --nsg-name $BASTION_NSG_NAME --priority 130 --resource-group $HUB_RG\
    --access Allow --protocol TCP --direction Inbound \
    --source-address-prefixes "GatewayManager" \
    --source-port-ranges "*" \
    --destination-address-prefixes "*" \
    --destination-port-ranges "443"

az network nsg rule create --name AllowAzureLoadBalancerInbound \
    --nsg-name $BASTION_NSG_NAME --priority 140 --resource-group $HUB_RG\
    --access Allow --protocol TCP --direction Inbound \
    --source-address-prefixes "AzureLoadBalancer" \
    --source-port-ranges "*" \
    --destination-address-prefixes "*" \
    --destination-port-ranges "443"

az network nsg rule create --name AllowBastionHostCommunication \
    --nsg-name $BASTION_NSG_NAME --priority 150 --resource-group $HUB_RG\
    --access Allow --protocol TCP --direction Inbound \
    --source-address-prefixes "VirtualNetwork" \
    --source-port-ranges "*" \
    --destination-address-prefixes "VirtualNetwork" \
    --destination-port-ranges 8080 5701


az network nsg rule create --name AllowSshRdpOutbound \
    --nsg-name $BASTION_NSG_NAME --priority 100 --resource-group $HUB_RG\
    --access Allow --protocol "*" --direction outbound \
    --source-address-prefixes "*" \
    --source-port-ranges "*" \
    --destination-address-prefixes "VirtualNetwork" \
    --destination-port-ranges 22 3389

az network nsg rule create --name AllowAzureCloudOutbound \
    --nsg-name $BASTION_NSG_NAME --priority 110 --resource-group $HUB_RG\
    --access Allow --protocol Tcp --direction outbound \
    --source-address-prefixes "*" \
    --source-port-ranges "*" \
    --destination-address-prefixes "AzureCloud" \
    --destination-port-ranges 443

az network nsg rule create --name AllowBastionCommunication \
    --nsg-name $BASTION_NSG_NAME --priority 120 --resource-group $HUB_RG\
    --access Allow --protocol "*" --direction outbound \
    --source-address-prefixes "VirtualNetwork" \
    --source-port-ranges "*" \
    --destination-address-prefixes "VirtualNetwork" \
    --destination-port-ranges 8080 5701

az network nsg rule create --name AllowHttpOutbound \
    --nsg-name $BASTION_NSG_NAME --priority 130 --resource-group $HUB_RG\
    --access Allow --protocol "*" --direction outbound \
    --source-address-prefixes "*" \
    --source-port-ranges "*" \
    --destination-address-prefixes "Internet" \
    --destination-port-ranges 80

az network nsg create \
    --resource-group $HUB_RG \
    --name $JUMPBOX_NSG_NAME \
    --location $LOCATION

az network nsg create \
    --resource-group $SPOKE_RG \
    --name $ENDPOINTS_NSG_NAME \
    --location $LOCATION

az network nsg create \
    --resource-group $SPOKE_RG \
    --name $LOADBALANCER_NSG_NAME \
    --location $LOCATION

az network nsg create \
    --resource-group $SPOKE_RG \
    --name $APPGW_NSG \
    --location $LOCATION

az network nsg rule create \
    --resource-group $SPOKE_RG \
    --nsg-name $APPGW_NSG \
    --name Allow-Internet-Inbound-HTTP-HTTPS \
    --priority 100 \
    --source-address-prefixes Internet \
    --destination-port-ranges 80 443 \
    --access Allow \
    --protocol Tcp \
    --description "Allow inbound traffic to port 80 and 443 to Application Gateway from client requests originating from the Internet"

az network nsg rule create \
    --resource-group $SPOKE_RG \
    --nsg-name $APPGW_NSG \
    --name Allow-GatewayManager-Inbound \
    --priority 110 \
    --source-address-prefixes "GatewayManager" \
    --destination-port-ranges 65200-65535 \
    --access Allow \
    --protocol Tcp \
    --description "Allow inbound traffic to ports 65200-65535 from GatewayManager service tag"


# Create VNets and subnets

az network vnet create \
    --resource-group $HUB_RG  \
    --name $HUB_VNET_NAME \
    --address-prefixes $HUB_VNET_PREFIX \
    --subnet-name $BASTION_SUBNET_NAME \
    --subnet-prefixes $BASTION_SUBNET_PREFIX \
    --network-security-group $BASTION_NSG_NAME

az network vnet subnet create \
    --resource-group $HUB_RG  \
    --vnet-name $HUB_VNET_NAME \
    --name $FW_SUBNET_NAME \
    --address-prefixes $FW_SUBNET_PREFIX

az network vnet subnet create \
    --resource-group $HUB_RG  \
    --vnet-name $HUB_VNET_NAME \
    --name $JUMPBOX_SUBNET_NAME \
    --address-prefixes $JUMPBOX_SUBNET_PREFIX \
    --network-security-group $JUMPBOX_NSG_NAME

az network vnet create \
    --resource-group $SPOKE_RG  \
    --name $SPOKE_VNET_NAME \
    --address-prefixes $SPOKE_VNET_PREFIX \
    --subnet-name $ARO_MASTER_SUBNET_NAME \
    --subnet-prefixes $ARO_SUBNET_MASTER_PREFIX

az network vnet subnet create \
    --resource-group $SPOKE_RG  \
    --vnet-name $SPOKE_VNET_NAME  \
    --name $ARO_WORKER_SUBNET_NAME \
    --address-prefixes $ARO_SUBNET_WORKER_PREFIX

az network vnet subnet create \
    --resource-group $SPOKE_RG  \
    --vnet-name $SPOKE_VNET_NAME  \
    --name $ENDPOINTS_SUBNET_NAME \
    --address-prefixes $ENDPOINTS_SUBNET_PREFIX \
	--network-security-group $ENDPOINTS_NSG_NAME

az network vnet subnet create \
    --resource-group $SPOKE_RG  \
    --vnet-name $SPOKE_VNET_NAME \
    --name $LOADBALANCER_SUBNET_NAME \
    --address-prefixes $LOADBALANCER_SUBNET_PREFIX \
	--network-security-group $LOADBALANCER_NSG_NAME

az network vnet subnet create \
    --resource-group $SPOKE_RG  \
    --vnet-name $SPOKE_VNET_NAME \
    --name $APPGW_SUBNET_NAME \
    --address-prefixes $APPGW_SUBNET_PREFIX \
	--network-security-group $APPGW_NSG


# Peering

SPOKE_VNET_ID=$(az network vnet show --resource-group $SPOKE_RG --name $SPOKE_VNET_NAME --query id --output tsv)
HUB_VNET_ID=$(az network vnet show --resource-group $HUB_RG --name $HUB_VNET_NAME --query id --output tsv)

az network vnet peering create \
    --resource-group $HUB_RG  \
    --name hub-to-spoke \
    --vnet-name $HUB_VNET_NAME \
    --remote-vnet $SPOKE_VNET_ID \
    --allow-vnet-access

az network vnet peering create \
    --resource-group $SPOKE_RG  \
    --name spoke-to-hub \
    --vnet-name $SPOKE_VNET_NAME \
    --remote-vnet $HUB_VNET_ID \
    --allow-vnet-access

# Create Bastion

az network public-ip create \
    --resource-group $HUB_RG  \
    --name Bastion-PIP \
    --sku Standard \
    --allocation-method Static

az network bastion create \
    --resource-group $HUB_RG \
    --name bastionhost \
    --public-ip-address Bastion-PIP \
    --vnet-name $HUB_VNET_NAME \
    --enable-tunneling \
    --enable-ip-connect \
    --location $LOCATION

az vm create \
    --resource-group $HUB_RG \
    --name $JUMPBOX_LINUX_VM_NAME \
    --image Ubuntu2204 \
    --admin-username azureuser \
    --admin-password $JUMPBOX_PASSWORD \
    --vnet-name $HUB_VNET_NAME \
    --subnet $JUMPBOX_SUBNET_NAME \
    --size Standard_B2s \
    --storage-sku Standard_LRS \
    --os-disk-name $JUMPBOX_VM_NAME-osdisk \
    --os-disk-size-gb 128 \
    --public-ip-address "" \
    --nsg ""  

az vm create \
    --resource-group $HUB_RG \
    --name $JUMPBOX_WINDOWS_VM_NAME \
    --image Win2022Datacenter \
    --admin-username azureuser \
    --admin-password $JUMPBOX_PASSWORD \
    --vnet-name $HUB_VNET_NAME \
    --subnet $JUMPBOX_SUBNET_NAME \
    --size Standard_B4ms \
    --storage-sku Standard_LRS \
    --os-disk-name $JUMPBOX_WINDOWS_VM_NAME-osdisk \
    --os-disk-size-gb 128 \
    --public-ip-address "" \
    --nsg "" 

# Create Azure Firewall

az network firewall create \
    --resource-group $HUB_RG \
    --name $FW_NAME \
    --location $LOCATION \
    --vnet-name $HUB_VNET_NAME \
    --enable-dns-proxy true

az network public-ip create \
    --name fw-pip \
    --resource-group $HUB_RG \
    --location $LOCATION \
    --allocation-method static \
    --sku standard

az network firewall ip-config create \
    --firewall-name $FW_NAME \
    --name FW-config \
    --public-ip-address fw-pip \
    --resource-group $HUB_RG \
    --vnet-name $HUB_VNET_NAME

az network firewall update \
    --name $FW_NAME \
    --resource-group $HUB_RG 

az network firewall network-rule create -g $HUB_RG -f $FW_NAME --collection-name 'aksfwnr' -n 'apiudp' --protocols 'UDP' --source-addresses '*' --destination-addresses "AzureCloud.$LOCATION" --destination-ports 1194 --action allow --priority 100
az network firewall network-rule create -g $HUB_RG -f $FW_NAME --collection-name 'aksfwnr' -n 'apitcp' --protocols 'TCP' --source-addresses '*' --destination-addresses "AzureCloud.$LOCATION" --destination-ports 9000
az network firewall network-rule create -g $HUB_RG -f $FW_NAME --collection-name 'aksfwnr' -n 'time' --protocols 'UDP' --source-addresses '*' --destination-fqdns 'ntp.ubuntu.com' --destination-ports 123

az network firewall application-rule create -g $HUB_RG -f $FW_NAME --collection-name 'required' -n 'aro' --source-addresses '*' --protocols 'https=443' --target-fqdns arosvc.azurecr.io arosvc.swedencentral.data.azurecr.io management.azure.com login.microsoftonline.com "*.monitor.core.windows.net" "*.monitoring.core.windows.net" "*.blob.core.windows.net" "*.servicebus.windows.net" "*.table.core.windows.net" --action allow --priority 100
az network firewall application-rule create -g $HUB_RG -f $FW_NAME --collection-name 'optional' -n 'aro' --source-addresses '*' --protocols 'https=443' --target-fqdns registry.redhat.io quay.io cdn.quay.io cdn01.quay.io cdn02.quay.io cdn03.quay.io access.redhat.com registry.access.redhat.com registry.connect.redhat.com api.openshift.com mirror.openshift.com --action allow --priority 101
az network firewall application-rule create -g $HUB_RG -f $FW_NAME --collection-name 'docker' -n 'aro' --source-addresses '*' --protocols 'https=443' --target-fqdns hub.docker.com registry-1.docker.io production.cloudflare.docker.com auth.docker.io --action allow --priority 110


az network route-table create \
    --resource-group $SPOKE_RG  \
    --name $ROUTE_TABLE_NAME

az network firewall show --resource-group $HUB_RG --name $FW_NAME |grep  privateIPAddress

FW_PRIVATE_IP=10.0.0.4

# Create route table

az network route-table route create \
    --resource-group $SPOKE_RG  \
    --name default-route \
    --route-table-name $ROUTE_TABLE_NAME \
    --address-prefix 0.0.0.0/0 \
    --next-hop-type VirtualAppliance \
    --next-hop-ip-address $FW_PRIVATE_IP

az network vnet subnet update \
    --resource-group $SPOKE_RG  \
    --vnet-name $SPOKE_VNET_NAME \
    --name $ARO_SUBNET_MASTER_NAME \
    --route-table $ROUTE_TABLE_NAME

az network vnet subnet update \
    --resource-group $SPOKE_RG  \
    --vnet-name $SPOKE_VNET_NAME \
    --name $ARO_SUBNET_WORKER_NAME \
    --route-table $ROUTE_TABLE_NAME

# DNS_ZONE_NAME=$(az network private-dns zone list --resource-group $NODE_GROUP --query "[0].name" -o tsv)
# HUB_VNET_ID=$(az network vnet show -g $HUB_RG -n $HUB_VNET_NAME --query id --output tsv)

# az network private-dns link vnet create --name "hubnetdnsconfig" --registration-enabled false --resource-group $NODE_GROUP --virtual-network $HUB_VNET_ID --zone-name $DNS_ZONE_NAME 
