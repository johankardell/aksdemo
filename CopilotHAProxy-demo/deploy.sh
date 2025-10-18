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
RESOURCE_GROUP_NAME=${1:-"rg-copilot-haproxy-demo"}
LOCATION=${2:-"Sweden Central"}
DEPLOYMENT_NAME="copilot-haproxy-deployment-$(date +%Y%m%d-%H%M%S)"

print_header "CopilotHAProxy AKS Demo Deployment"

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

# Check if kubectl is installed
if ! command -v kubectl &> /dev/null; then
    print_error "kubectl is not installed. Please install it first."
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

print_header "Getting AKS Credentials"
print_status "Configuring kubectl for AKS cluster '$AKS_CLUSTER_NAME'..."
az aks get-credentials \
  --resource-group "$RESOURCE_GROUP_NAME" \
  --name "$AKS_CLUSTER_NAME" \
  --overwrite-existing

# Verify cluster connection
print_status "Verifying cluster connection..."
kubectl cluster-info

print_header "Deploying HAProxy Ingress Controller"
print_status "Installing HAProxy Ingress Controller..."
kubectl apply -f manifests/haproxy-ingress.yaml

print_status "Waiting for HAProxy Ingress Controller to be ready..."
kubectl rollout status deployment/haproxy-ingress -n haproxy-controller --timeout=300s

print_header "Deploying NGINX Application"
print_status "Applying NGINX deployment..."
kubectl apply -f manifests/nginx-deployment.yaml

print_status "Waiting for NGINX deployment to be ready..."
kubectl rollout status deployment/nginx-deployment --timeout=300s

print_status "Creating Ingress resource..."
kubectl apply -f manifests/nginx-ingress.yaml

# Get the LoadBalancer IP for the HAProxy service
print_status "Waiting for HAProxy LoadBalancer IP assignment..."
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

print_header "Deployment Summary"
echo -e "${GREEN}✅ CopilotHAProxy demo deployed successfully!${NC}"
echo ""
echo "Resource Group: $RESOURCE_GROUP_NAME"
echo "AKS Cluster: $AKS_CLUSTER_NAME"
echo "HAProxy LoadBalancer IP: ${HAPROXY_LB_IP:-'<pending>'}"
echo ""

if [[ -n "$HAPROXY_LB_IP" && "$HAPROXY_LB_IP" != "<none>" ]]; then
    echo -e "${BLUE}🌐 Access your application:${NC}"
    echo "  Public URL: http://$HAPROXY_LB_IP"
else
    echo -e "${YELLOW}⏳ LoadBalancer IP is still pending. Check with:${NC}"
    echo "  kubectl get service haproxy-ingress -n haproxy-controller"
fi

echo ""
echo -e "${BLUE}🔧 Useful commands:${NC}"
echo "  Check pods: kubectl get pods --all-namespaces"
echo "  Check services: kubectl get services --all-namespaces"
echo "  View NGINX logs: kubectl logs -l app=nginx"
echo "  View HAProxy logs: kubectl logs -l app=haproxy-ingress -n haproxy-controller"
echo "  Scale NGINX: kubectl scale deployment nginx-deployment --replicas=5"
echo ""
echo -e "${BLUE}📊 Architecture highlights:${NC}"
echo "  ✓ AKS with VNet injection"
echo "  ✓ Workload profile enabled (workload identity, KEDA auto-scaler)"
echo "  ✓ HAProxy Ingress Controller"
echo "  ✓ NGINX with 3 replicas using nginx:latest"
echo "  ✓ Internet exposure through HAProxy LoadBalancer"
echo ""
echo -e "${BLUE}🗑️ To clean up:${NC}"
echo "  ./terminate.sh $RESOURCE_GROUP_NAME"

if [[ -z "$HAPROXY_LB_IP" || "$HAPROXY_LB_IP" == "<none>" ]]; then
    print_warning "Note: The LoadBalancer IP is still pending. It may take a few more minutes."
    echo "  Run this command periodically to check: kubectl get service haproxy-ingress -n haproxy-controller"
fi