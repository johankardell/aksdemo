#!/bin/bash
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
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
LOCATION=${2:-"Sweden Central"}
DEPLOYMENT_NAME="aks-appgw-deployment-$(date +%Y%m%d-%H%M%S)"

print_header "Azure AKS + Application Gateway Deployment"

# Check if Azure CLI is installed and logged in
print_status "Checking Azure CLI..."
if ! command -v az &> /dev/null; then
    print_error "Azure CLI is not installed. Please install it first."
    exit 1
fi

# Check if logged in
if ! az account show &> /dev/null; then
    print_error "Please log in to Azure CLI first: az login"
    exit 1
fi

# Get current subscription
SUBSCRIPTION_ID=$(az account show --query id -o tsv)
print_status "Using subscription: $SUBSCRIPTION_ID"

# Create resource group if it doesn't exist
print_status "Creating resource group '$RESOURCE_GROUP_NAME' in '$LOCATION'..."
az group create \
  --name "$RESOURCE_GROUP_NAME" \
  --location "$LOCATION" \
  --output table

# Deploy the Bicep template
print_header "Deploying Infrastructure"
print_status "Starting Bicep deployment..."

az deployment group create \
  --resource-group "$RESOURCE_GROUP_NAME" \
  --template-file main.bicep \
  --parameters @parameters.json \
  --parameters location="$LOCATION" \
  --parameters sshPublicKey="$(cat ~/.ssh/id_rsa.pub)" \
  --name "$DEPLOYMENT_NAME" \
  --verbose

# Get deployment outputs
print_status "Retrieving deployment outputs..."
AKS_CLUSTER_NAME=$(az deployment group show \
  --resource-group "$RESOURCE_GROUP_NAME" \
  --name "$DEPLOYMENT_NAME" \
  --query properties.outputs.aksClusterName.value -o tsv)

APP_GATEWAY_NAME=$(az deployment group show \
  --resource-group "$RESOURCE_GROUP_NAME" \
  --name "$DEPLOYMENT_NAME" \
  --query properties.outputs.appGatewayName.value -o tsv)

APP_GATEWAY_PUBLIC_IP=$(az deployment group show \
  --resource-group "$RESOURCE_GROUP_NAME" \
  --name "$DEPLOYMENT_NAME" \
  --query properties.outputs.appGatewayPublicIp.value -o tsv)

print_header "Getting AKS Credentials"
print_status "Configuring kubectl for AKS cluster '$AKS_CLUSTER_NAME'..."
az aks get-credentials \
  --resource-group "$RESOURCE_GROUP_NAME" \
  --name "$AKS_CLUSTER_NAME" \
  --overwrite-existing

# Verify cluster connection
print_status "Verifying cluster connection..."
kubectl cluster-info

print_header "Deploying HAProxy Ingress Controller to AKS"
print_status "Applying HAProxy manifests..."
kubectl apply -f manifests/haproxy-namespace.yaml
kubectl apply -f manifests/haproxy-rbac.yaml
kubectl apply -f manifests/haproxy-ingressclass.yaml
kubectl apply -f manifests/haproxy-configmap.yaml
kubectl apply -f manifests/haproxy-deployment.yaml

print_status "Waiting for HAProxy deployment to be ready..."
kubectl rollout status deployment/haproxy-ingress -n haproxy-controller --timeout=300s

print_header "Deploying Sample Application"
print_status "Applying sample application manifests..."
kubectl apply -f manifests/sample-app.yaml
kubectl apply -f manifests/sample-app-ingress.yaml

print_status "Waiting for sample application to be ready..."
kubectl rollout status deployment/sample-web-app -n sample-app --timeout=300s

# Get the LoadBalancer IP for the HAProxy service
print_status "Waiting for LoadBalancer IP assignment..."
sleep 30

HAPROXY_LB_IP=""
for i in {1..20}; do
    HAPROXY_LB_IP=$(kubectl get service haproxy-ingress -n haproxy-controller -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo "")
    if [[ -n "$HAPROXY_LB_IP" && "$HAPROXY_LB_IP" != "<none>" ]]; then
        break
    fi
    print_status "Waiting for LoadBalancer IP... (attempt $i/20)"
    sleep 15
done

if [[ -z "$HAPROXY_LB_IP" || "$HAPROXY_LB_IP" == "<none>" ]]; then
    print_warning "LoadBalancer IP not ready yet. You can check later with: kubectl get service haproxy-ingress -n haproxy-controller"
    HAPROXY_LB_IP="<pending>"
else
    print_status "HAProxy LoadBalancer IP: $HAPROXY_LB_IP"
    
    # Update Application Gateway backend pool with the HAProxy LoadBalancer IP
    print_status "Updating Application Gateway backend pool..."
    az network application-gateway address-pool update \
      --resource-group "$RESOURCE_GROUP_NAME" \
      --gateway-name "$APP_GATEWAY_NAME" \
      --name "appGatewayBackendPool" \
      --servers "$HAPROXY_LB_IP"
fi

print_header "Deployment Summary"
echo -e "${GREEN}✅ Infrastructure deployed successfully!${NC}"
echo ""
echo "Resource Group: $RESOURCE_GROUP_NAME"
echo "AKS Cluster: $AKS_CLUSTER_NAME"
echo "Application Gateway: $APP_GATEWAY_NAME"
echo "Application Gateway Public IP: $APP_GATEWAY_PUBLIC_IP"
echo "HAProxy LoadBalancer IP: $HAPROXY_LB_IP"
echo ""
echo -e "${BLUE}🌐 Access your application:${NC}"
echo "  Public URL: http://$APP_GATEWAY_PUBLIC_IP"
echo ""
echo -e "${BLUE}🔧 Useful commands:${NC}"
echo "  Check HAProxy pods: kubectl get pods -n haproxy-controller"
echo "  Check sample app pods: kubectl get pods -n sample-app"
echo "  Check services: kubectl get services -A"
echo "  Check ingress: kubectl get ingress -n sample-app"
echo "  View HAProxy logs: kubectl logs -n haproxy-controller deployment/haproxy-ingress"
echo "  View sample app logs: kubectl logs -n sample-app deployment/sample-web-app"
echo "  Scale sample app: kubectl scale deployment sample-web-app --replicas=5 -n sample-app"
echo ""
echo -e "${BLUE}🗑️ To clean up:${NC}"
echo "  ./terminate.sh $RESOURCE_GROUP_NAME"

if [[ "$HAPROXY_LB_IP" == "<pending>" ]]; then
    print_warning "Note: The LoadBalancer IP is still pending. Once it's assigned, update the Application Gateway:"
    echo "  HAPROXY_IP=\$(kubectl get service haproxy-ingress -n haproxy-controller -o jsonpath='{.status.loadBalancer.ingress[0].ip}')"
    echo "  az network application-gateway address-pool update --resource-group $RESOURCE_GROUP_NAME --gateway-name $APP_GATEWAY_NAME --name appGatewayBackendPool --servers \$HAPROXY_IP"
fi
