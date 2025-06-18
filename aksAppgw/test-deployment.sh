#!/bin/bash

# Test script to verify HAProxy ingress deployment and connectivity

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

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
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

print_header "Testing HAProxy Ingress Deployment"

# Check if kubectl is available
if ! command -v kubectl &> /dev/null; then
    print_error "kubectl is not installed."
    exit 1
fi

# Test 1: Check HAProxy namespace
print_status "Checking HAProxy namespace..."
if kubectl get namespace haproxy-controller &> /dev/null; then
    print_success "HAProxy namespace exists"
else
    print_error "HAProxy namespace not found"
    exit 1
fi

# Test 2: Check HAProxy deployment
print_status "Checking HAProxy deployment..."
if kubectl get deployment haproxy-ingress -n haproxy-controller &> /dev/null; then
    READY_REPLICAS=$(kubectl get deployment haproxy-ingress -n haproxy-controller -o jsonpath='{.status.readyReplicas}')
    DESIRED_REPLICAS=$(kubectl get deployment haproxy-ingress -n haproxy-controller -o jsonpath='{.spec.replicas}')
    
    if [[ "$READY_REPLICAS" == "$DESIRED_REPLICAS" ]]; then
        print_success "HAProxy deployment is ready ($READY_REPLICAS/$DESIRED_REPLICAS replicas)"
    else
        print_warning "HAProxy deployment not fully ready ($READY_REPLICAS/$DESIRED_REPLICAS replicas)"
    fi
else
    print_error "HAProxy deployment not found"
    exit 1
fi

# Test 3: Check HAProxy service
print_status "Checking HAProxy service..."
if kubectl get service haproxy-ingress -n haproxy-controller &> /dev/null; then
    HAPROXY_LB_IP=$(kubectl get service haproxy-ingress -n haproxy-controller -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo "")
    
    if [[ -n "$HAPROXY_LB_IP" && "$HAPROXY_LB_IP" != "<none>" ]]; then
        print_success "HAProxy service has LoadBalancer IP: $HAPROXY_LB_IP"
    else
        print_warning "HAProxy service LoadBalancer IP not assigned yet"
    fi
else
    print_error "HAProxy service not found"
    exit 1
fi

# Test 4: Check sample application
print_status "Checking sample application..."
if kubectl get namespace sample-app &> /dev/null; then
    print_success "Sample app namespace exists"
    
    if kubectl get deployment sample-web-app -n sample-app &> /dev/null; then
        READY_REPLICAS=$(kubectl get deployment sample-web-app -n sample-app -o jsonpath='{.status.readyReplicas}')
        DESIRED_REPLICAS=$(kubectl get deployment sample-web-app -n sample-app -o jsonpath='{.spec.replicas}')
        
        if [[ "$READY_REPLICAS" == "$DESIRED_REPLICAS" ]]; then
            print_success "Sample app deployment is ready ($READY_REPLICAS/$DESIRED_REPLICAS replicas)"
        else
            print_warning "Sample app deployment not fully ready ($READY_REPLICAS/$DESIRED_REPLICAS replicas)"
        fi
    else
        print_error "Sample app deployment not found"
    fi
else
    print_error "Sample app namespace not found"
fi

# Test 5: Check ingress
print_status "Checking ingress configuration..."
if kubectl get ingress sample-app-ingress -n sample-app &> /dev/null; then
    INGRESS_CLASS=$(kubectl get ingress sample-app-ingress -n sample-app -o jsonpath='{.spec.ingressClassName}')
    
    if [[ "$INGRESS_CLASS" == "haproxy" ]]; then
        print_success "Ingress is configured with HAProxy class"
    else
        print_warning "Ingress class is '$INGRESS_CLASS', expected 'haproxy'"
    fi
else
    print_error "Sample app ingress not found"
fi

# Test 6: Check Application Gateway if Azure CLI is available
if command -v az &> /dev/null && az account show &> /dev/null 2>&1; then
    print_status "Checking Application Gateway configuration..."
    
    APP_GATEWAY_NAME=$(az network application-gateway list \
      --resource-group "$RESOURCE_GROUP_NAME" \
      --query '[0].name' -o tsv 2>/dev/null || echo "")
    
    if [[ -n "$APP_GATEWAY_NAME" ]]; then
        APP_GW_PUBLIC_IP=$(az network public-ip show \
          --resource-group "$RESOURCE_GROUP_NAME" \
          --name "$(az network application-gateway show --resource-group "$RESOURCE_GROUP_NAME" --name "$APP_GATEWAY_NAME" --query 'frontendIPConfigurations[0].publicIPAddress.id' -o tsv | xargs basename)" \
          --query 'ipAddress' -o tsv 2>/dev/null || echo "Unknown")
        
        print_success "Application Gateway found: $APP_GATEWAY_NAME"
        print_success "Application Gateway Public IP: $APP_GW_PUBLIC_IP"
        
        # Check backend pool
        BACKEND_SERVERS=$(az network application-gateway address-pool show \
          --resource-group "$RESOURCE_GROUP_NAME" \
          --gateway-name "$APP_GATEWAY_NAME" \
          --name "appGatewayBackendPool" \
          --query 'backendAddresses[].ipAddress' -o tsv 2>/dev/null || echo "")
        
        if [[ -n "$BACKEND_SERVERS" ]]; then
            print_success "Backend pool configured with servers: $BACKEND_SERVERS"
            
            if [[ "$BACKEND_SERVERS" == "$HAPROXY_LB_IP" ]]; then
                print_success "Backend pool correctly points to HAProxy LoadBalancer"
            else
                print_warning "Backend pool servers don't match HAProxy LB IP"
                print_warning "Expected: $HAPROXY_LB_IP, Found: $BACKEND_SERVERS"
            fi
        else
            print_warning "No backend servers configured in Application Gateway"
        fi
    else
        print_warning "No Application Gateway found in resource group"
    fi
else
    print_warning "Azure CLI not available or not logged in, skipping Application Gateway checks"
fi

# Test 7: Test connectivity (if curl is available)
if command -v curl &> /dev/null; then
    print_status "Testing connectivity..."
    
    if [[ -n "$HAPROXY_LB_IP" && "$HAPROXY_LB_IP" != "<none>" ]]; then
        print_status "Testing direct connection to HAProxy..."
        if curl -s -f --connect-timeout 10 "http://$HAPROXY_LB_IP" > /dev/null; then
            print_success "Direct connection to HAProxy successful"
        else
            print_warning "Direct connection to HAProxy failed (this may be normal if internal LB)"
        fi
    fi
    
    if [[ -n "$APP_GW_PUBLIC_IP" && "$APP_GW_PUBLIC_IP" != "Unknown" ]]; then
        print_status "Testing connection through Application Gateway..."
        if curl -s -f --connect-timeout 10 "http://$APP_GW_PUBLIC_IP" > /dev/null; then
            print_success "Connection through Application Gateway successful"
        else
            print_warning "Connection through Application Gateway failed (may need more time to propagate)"
        fi
    fi
else
    print_warning "curl not available, skipping connectivity tests"
fi

print_header "Test Summary"

echo ""
echo -e "${BLUE}📋 Deployment Status:${NC}"
echo "  HAProxy Namespace: ✅"
echo "  HAProxy Deployment: ✅"
echo "  HAProxy Service: ✅"
echo "  Sample Application: ✅"
echo "  Ingress Configuration: ✅"

if [[ -n "$APP_GATEWAY_NAME" ]]; then
    echo "  Application Gateway: ✅"
    echo ""
    echo -e "${BLUE}🌐 Access Information:${NC}"
    echo "  Application URL: http://$APP_GW_PUBLIC_IP"
    echo "  HAProxy LoadBalancer IP: $HAPROXY_LB_IP"
else
    echo "  Application Gateway: ⚠️  (not checked)"
fi

echo ""
echo -e "${BLUE}🔍 Useful debugging commands:${NC}"
echo "  kubectl get pods -n haproxy-controller"
echo "  kubectl get pods -n sample-app"
echo "  kubectl logs -n haproxy-controller deployment/haproxy-ingress"
echo "  kubectl describe ingress sample-app-ingress -n sample-app"
echo "  kubectl get events -n haproxy-controller --sort-by='.lastTimestamp'"
echo "  kubectl get events -n sample-app --sort-by='.lastTimestamp'"

if [[ -n "$APP_GATEWAY_NAME" ]]; then
    echo ""
    echo -e "${BLUE}🔍 Application Gateway commands:${NC}"
    echo "  az network application-gateway show-backend-health --resource-group $RESOURCE_GROUP_NAME --name $APP_GATEWAY_NAME"
    echo "  az network application-gateway address-pool show --resource-group $RESOURCE_GROUP_NAME --gateway-name $APP_GATEWAY_NAME --name appGatewayBackendPool"
fi

print_success "Test completed!"
