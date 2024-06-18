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
AKS_SUBNET_NAME=aks-subnet
LOADBALANCER_SUBNET_NAME=loadbalancer-subnet
SPOKE_VNET_PREFIX=10.1.0.0/22 # IP address range of the Virtual network (VNet).
AKS_SUBNET_PREFIX=10.1.0.0/24 # IP address range of the AKS subnet
LOADBALANCER_SUBNET_PREFIX=10.1.1.0/28 # IP address range of the Loadbalancer subnet
APPGW_SUBNET_PREFIX=10.1.2.0/24 # IP address range of the Application Gateway subnet
ENDPOINTS_SUBNET_PREFIX=10.1.1.16/28 # IP address range of the Endpoints subnet

HUB_RG=rg-hub
SPOKE_RG=rg-spoke
LOCATION=eastus 
BASTION_NSG_NAME=Bastion_NSG
JUMPBOX_NSG_NAME=Jumpbox_NSG
AKS_NSG_NAME=Aks_NSG
ENDPOINTS_NSG_NAME=Endpoints_NSG
LOADBALANCER_NSG_NAME=Loadbalancer_NSG
APPGW_NSG=Appgw_NSG
FW_NAME=azure-firewall
APPGW_NAME=AppGateway
ROUTE_TABLE_NAME=spoke-rt
AKS_IDENTITY_NAME=aks-msi
JUMPBOX_VM_NAME=Jumpbox-VM
JUMPBOX_PASSWORD="changeme" # Change this
AKS_CLUSTER_NAME=private-aks
ACR_NAME=jkaksthehardway
STUDENT_NAME=johan
DNS_NAME=jkaksthehardway

az group create --name $HUB_RG --location $LOCATION
az group create --name $SPOKE_RG --location $LOCATION

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

az network nsg create \
    --resource-group $SPOKE_RG \
    --name $AKS_NSG_NAME \
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

az network vnet create \
    --resource-group $SPOKE_RG  \
    --name $SPOKE_VNET_NAME \
    --address-prefixes $SPOKE_VNET_PREFIX \
    --subnet-name $AKS_SUBNET_NAME \
    --subnet-prefixes $AKS_SUBNET_PREFIX \
	--network-security-group $AKS_NSG_NAME

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

az network public-ip create \
    --resource-group $HUB_RG  \
    --name Bastion-PIP \
    --sku Standard \
    --allocation-method Static

az vm create \
    --resource-group $HUB_RG \
    --name $JUMPBOX_VM_NAME \
    --image Ubuntu2204 \
    --admin-username azureuser \
    --admin-password $JUMPBOX_PASSWORD \
    --vnet-name $HUB_VNET_NAME \
    --subnet $JUMPBOX_SUBNET_NAME \
    --size Standard_B2s \
    --storage-sku Standard_LRS \
    --os-disk-name $JUMPBOX_VM_NAME-VM-osdisk \
    --os-disk-size-gb 128 \
    --public-ip-address "" \
    --nsg ""  

az network bastion create \
    --resource-group $HUB_RG \
    --name bastionhost \
    --public-ip-address Bastion-PIP \
    --vnet-name $HUB_VNET_NAME \
    --enable-tunneling \
    --enable-ip-connect \
    --location $LOCATION

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

az network firewall application-rule create -g $HUB_RG -f $FW_NAME --collection-name 'aksfwar' -n 'fqdn' --source-addresses '*' --protocols 'http=80' 'https=443' --fqdn-tags "AzureKubernetesService" --action allow --priority 100

az network route-table create \
    --resource-group $SPOKE_RG  \
    --name $ROUTE_TABLE_NAME

az network firewall show --resource-group $HUB_RG --name $FW_NAME |grep  privateIPAddress

FW_PRIVATE_IP=10.0.0.4

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
    --name $AKS_SUBNET_NAME \
    --route-table $ROUTE_TABLE_NAME

az identity create \
    --resource-group $SPOKE_RG \
    --name $AKS_IDENTITY_NAME-${STUDENT_NAME}

IDENTITY_ID=$(az identity show \
    --resource-group $SPOKE_RG \
    --name $AKS_IDENTITY_NAME-${STUDENT_NAME} \
    --query id \
    --output tsv)

PRINCIPAL_ID=$(az identity show \
    --resource-group $SPOKE_RG \
    --name $AKS_IDENTITY_NAME-${STUDENT_NAME} \
    --query principalId \
    --output tsv)

RT_SCOPE=$(az network route-table show \
    --resource-group $SPOKE_RG \
    --name $ROUTE_TABLE_NAME  \
    --query id \
    --output tsv)

az role assignment create \
    --assignee $PRINCIPAL_ID\
    --scope $RT_SCOPE \
    --role "Network Contributor"

LB_SUBNET_SCOPE=$(az network vnet subnet list \
    --resource-group $SPOKE_RG \
    --vnet-name $SPOKE_VNET_NAME \
    --query "[?name=='$LOADBALANCER_SUBNET_NAME'].id" \
    --output tsv)

az role assignment create \
    --assignee $PRINCIPAL_ID \
    --scope $LB_SUBNET_SCOPE \
    --role "Network Contributor"

AKS_SUBNET_SCOPE=$(az network vnet subnet list \
    --resource-group $SPOKE_RG \
    --vnet-name $SPOKE_VNET_NAME \
    --query "[?name=='$AKS_SUBNET_NAME'].id" \
    --output tsv)

az aks create --resource-group $SPOKE_RG --node-count 2 --vnet-subnet-id $AKS_SUBNET_SCOPE --name $AKS_CLUSTER_NAME-${STUDENT_NAME} --enable-private-cluster --outbound-type userDefinedRouting --enable-oidc-issuer --enable-workload-identity --generate-ssh-keys --assign-identity $IDENTITY_ID --network-plugin azure --network-policy azure --disable-public-fqdn --zones 1 2 3

az aks nodepool add --resource-group $SPOKE_RG --cluster-name $AKS_CLUSTER_NAME-${STUDENT_NAME} --name userpool --node-count 3 --mode user --zones 1 2 3 --enable-cluster-autoscaler --min-count 1 --max-count 5

NODE_GROUP=$(az aks show --resource-group $SPOKE_RG --name $AKS_CLUSTER_NAME-${STUDENT_NAME} --query nodeResourceGroup -o tsv)
DNS_ZONE_NAME=$(az network private-dns zone list --resource-group $NODE_GROUP --query "[0].name" -o tsv)
HUB_VNET_ID=$(az network vnet show -g $HUB_RG -n $HUB_VNET_NAME --query id --output tsv)

az network private-dns link vnet create --name "hubnetdnsconfig" --registration-enabled false --resource-group $NODE_GROUP --virtual-network $HUB_VNET_ID --zone-name $DNS_ZONE_NAME 

# Connect to the jumpbox and run the following commands:

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
az account set --subscription "network"

SPOKE_RG=rg-spoke
AKS_CLUSTER_NAME=private-aks
STUDENT_NAME=johan

az aks get-credentials --resource-group $SPOKE_RG --name $AKS_CLUSTER_NAME-${STUDENT_NAME}

kubectl get nodes

## Back to workstation

az acr create \
    --resource-group $SPOKE_RG \
    --name $ACR_NAME \
    --sku Premium \
    --admin-enabled false \
    --location $LOCATION \
    --allow-trusted-services false \
    --public-network-enabled false

az network private-dns zone create \
  --resource-group $SPOKE_RG \
  --name "privatelink.azurecr.io"

az network private-dns link vnet create \
  --resource-group $SPOKE_RG \
  --zone-name "privatelink.azurecr.io" \
  --name ACRDNSSpokeLink \
  --virtual-network $SPOKE_VNET_NAME \
  --registration-enabled false

HUB_VNET_ID=$(az network vnet show --resource-group $HUB_RG --name $HUB_VNET_NAME --query id --output tsv)

az network private-dns link vnet create \
  --resource-group $SPOKE_RG \
  --zone-name "privatelink.azurecr.io" \
  --name ACRDNSHubLink \
  --virtual-network $HUB_VNET_ID \
  --registration-enabled false

REGISTRY_ID=$(az acr show --name $ACR_NAME \
  --query 'id' --output tsv)

az network private-endpoint create \
    --name ACRPrivateEndpoint \
    --resource-group $SPOKE_RG \
    --vnet-name $SPOKE_VNET_NAME \
    --subnet $ENDPOINTS_SUBNET_NAME \
    --private-connection-resource-id $REGISTRY_ID \
    --group-ids registry \
    --connection-name PrivateACRConnection

NETWORK_INTERFACE_ID=$(az network private-endpoint show \
  --name ACRPrivateEndpoint \
  --resource-group $SPOKE_RG \
  --query 'networkInterfaces[0].id' \
  --output tsv)

az network nic show --ids $NETWORK_INTERFACE_ID |grep azurecr.io -B 7

az network private-dns record-set a create \
  --name $ACR_NAME \
  --zone-name privatelink.azurecr.io \
  --resource-group $SPOKE_RG

az network private-dns record-set a create \
  --name $ACR_NAME.$LOCATION.data \
  --zone-name privatelink.azurecr.io \
  --resource-group $SPOKE_RG

az network private-dns record-set a add-record \
  --record-set-name $ACR_NAME.$LOCATION.data \
  --zone-name privatelink.azurecr.io \
  --resource-group $SPOKE_RG \
  --ipv4-address 10.1.1.20

  az network private-dns record-set a add-record \
  --record-set-name $ACR_NAME \
  --zone-name privatelink.azurecr.io \
  --resource-group $SPOKE_RG \
  --ipv4-address 10.1.1.21

az aks update \
    --resource-group $SPOKE_RG \
    --name $AKS_CLUSTER_NAME-${STUDENT_NAME} \
    --attach-acr $ACR_NAME

## On Jumpbox

az login
az account set --subscription network

vim Dockerfile

    FROM nginx
    EXPOSE 80

docker build --tag nginx .

docker tag nginx jkaksthehardway.azurecr.io/nginx

docker push jkaksthehardway.azurecr.io/nginx

vim test-pod.yaml
    apiVersion: v1
    kind: Pod
    metadata:
    name: internal-test-app
    labels:
        app: internal-test-app
    spec:
    containers:
    - name: nginx
        image: <ACR NAME>.azurecr.io/nginx
        ports:
        - containerPort: 80
    ---
    apiVersion: v1
    kind: Service
    metadata:
    name: internal-test-app-service
    annotations:
        service.beta.kubernetes.io/azure-load-balancer-internal: "true"
        service.beta.kubernetes.io/azure-load-balancer-internal-subnet: "loadbalancer-subnet"
    spec:
    type: LoadBalancer
    ports:
    - port: 80
    selector:
        app: internal-test-app

kubectl apply -f test-pod.yaml

# ...wait...

curl 10.1.1.4

## Back to workstation

az network public-ip create -g $SPOKE_RG -n AGPublicIPAddress --dns-name $DNS_NAME --allocation-method Static --sku Standard --location $LOCATION

az network application-gateway waf-policy create --name ApplicationGatewayWAFPolicy --resource-group $SPOKE_RG

az network public-ip show -g $SPOKE_RG -n AGPublicIPAddress --query dnsSettings.fqdn

openssl genrsa -out my.key 2048
openssl req -new -x509 -sha256 -key my.key -out my.crt -days 365
openssl pkcs12 -export -out my.pfx -inkey my.key -in my.crt -password pass:$JUMPBOX_PASSWORD

az network application-gateway create \
  --name AppGateway \
  --location $LOCATION \
  --resource-group $SPOKE_RG \
  --vnet-name $SPOKE_VNET_NAME \
  --subnet $APPGW_SUBNET_NAME \
  --capacity 1 \
  --sku WAF_v2 \
  --http-settings-cookie-based-affinity Disabled \
  --frontend-port 443 \
  --http-settings-port 80 \
  --http-settings-protocol Http \
  --priority "1" \
  --public-ip-address AGPublicIPAddress \
  --cert-file my.pfx \
  --cert-password "$JUMPBOX_PASSWORD" \
  --waf-policy ApplicationGatewayWAFPolicy \
  --servers 10.1.1.4

az network application-gateway probe create \
    --gateway-name $APPGW_NAME \
    --resource-group $SPOKE_RG \
    --name health-probe \
    --protocol Http \
    --path / \
    --interval 30 \
    --timeout 120 \
    --threshold 3 \
    --host 127.0.0.1

az network application-gateway http-settings update -g $SPOKE_RG --gateway-name $APPGW_NAME -n appGatewayBackendHttpSettings --probe health-probe


## Cleanup
# az group delete -n $HUB_RG
# az group delete -n $SPOKE_RG