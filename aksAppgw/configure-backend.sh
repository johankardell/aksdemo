#!/bin/bash
set -e

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_header() {
    echo -e "${BLUE}================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}================================${NC}"
}

# Configuration
RESOURCE_GROUP_NAME=${1:-"rg-aks-appgw-demo"}
APP_GATEWAY_NAME=${2}

if [[ -z "$RESOURCE_GROUP_NAME" ]]; then
    print_error "Usage: $0 <resource-group-name> [app-gateway-name]"
    print_error "Example: $0 rg-aks-appgw-demo"
    exit 1
fi

print_header "Configuring Application Gateway Backend"

# Check if Azure CLI is installed and logged in
if ! command -v az &> /dev/null; then
    print_error "Azure CLI is not installed."
    exit 1
fi

if ! az account show &> /dev/null; then
    print_error "Please log in to Azure CLI first: az login"
    exit 1
fi

# Check if kubectl is available
if ! command -v kubectl &> /dev/null; then
    print_error "kubectl is not installed. Please install it first."
    exit 1
fi

# Get Application Gateway name if not provided
if [[ -z "$APP_GATEWAY_NAME" ]]; then
    print_status "Looking for Application Gateway in resource group '$RESOURCE_GROUP_NAME'..."
    APP_GATEWAY_NAME=$(az network application-gateway list \
      --resource-group "$RESOURCE_GROUP_NAME" \
      --query '[0].name' -o tsv 2>/dev/null || echo "")
    
    if [[ -z "$APP_GATEWAY_NAME" ]]; then
        print_error "No Application Gateway found in resource group '$RESOURCE_GROUP_NAME'"
        exit 1
    fi
    
    print_status "Found Application Gateway: $APP_GATEWAY_NAME"
fi

# Check if NGINX service exists
print_status "Checking NGINX service in Kubernetes..."
if ! kubectl get service nginx-service &> /dev/null; then
    print_error "NGINX service 'nginx-service' not found. Please deploy NGINX first:"
    print_error "kubectl apply -f manifests/nginx-deployment.yaml"
    exit 1
fi

# Get NGINX LoadBalancer IP
print_status "Getting NGINX LoadBalancer IP..."
NGINX_LB_IP=""
for i in {1..12}; do
    NGINX_LB_IP=$(kubectl get service nginx-service -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo "")
    if [[ -n "$NGINX_LB_IP" && "$NGINX_LB_IP" != "<none>" ]]; then
        break
    fi
    print_status "Waiting for LoadBalancer IP assignment... (attempt $i/12)"
    sleep 10
done

if [[ -z "$NGINX_LB_IP" || "$NGINX_LB_IP" == "<none>" ]]; then
    print_error "LoadBalancer IP is not assigned yet. This may take a few minutes."
    print_error "Try running this script again in a few minutes, or check with:"
    print_error "kubectl get service nginx-service"
    exit 1
fi

print_status "NGINX LoadBalancer IP: $NGINX_LB_IP"

# Update Application Gateway backend pool
print_status "Updating Application Gateway backend pool..."
az network application-gateway address-pool update \
  --resource-group "$RESOURCE_GROUP_NAME" \
  --gateway-name "$APP_GATEWAY_NAME" \
  --name "appGatewayBackendPool" \
  --servers "$NGINX_LB_IP"

# Verify backend health
print_status "Checking backend health (this may take a minute)..."
sleep 30

HEALTH_STATUS=$(az network application-gateway show-backend-health \
  --resource-group "$RESOURCE_GROUP_NAME" \
  --name "$APP_GATEWAY_NAME" \
  --query 'backendAddressPools[0].backendHttpSettingsCollection[0].servers[0].health' -o tsv 2>/dev/null || echo "Unknown")

print_status "Backend health status: $HEALTH_STATUS"

# Get Application Gateway public IP
APP_GW_PUBLIC_IP=$(az network public-ip show \
  --resource-group "$RESOURCE_GROUP_NAME" \
  --name "$(az network application-gateway show --resource-group "$RESOURCE_GROUP_NAME" --name "$APP_GATEWAY_NAME" --query 'frontendIPConfigurations[0].publicIPAddress.id' -o tsv | xargs basename)" \
  --query 'ipAddress' -o tsv 2>/dev/null || echo "Unknown")

print_header "Configuration Complete"
print_status "Application Gateway backend pool updated successfully!"
echo ""
echo "Application Gateway: $APP_GATEWAY_NAME"
echo "Backend IP: $NGINX_LB_IP"
echo "Public IP: $APP_GW_PUBLIC_IP"
echo "Backend Health: $HEALTH_STATUS"
echo ""
print_status "You can now access your application at: http://$APP_GW_PUBLIC_IP"

if [[ "$HEALTH_STATUS" != "Healthy" ]]; then
    print_warning "Backend is not healthy yet. This is normal and may take a few minutes."
    print_warning "You can check the status later with:"
    echo "  az network application-gateway show-backend-health --resource-group $RESOURCE_GROUP_NAME --name $APP_GATEWAY_NAME"
fi
