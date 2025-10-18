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

print_header "CopilotHAProxy Demo Cleanup"

if [[ -z "$RESOURCE_GROUP_NAME" ]]; then
    print_error "Please provide a resource group name as the first argument"
    print_error "Usage: ./terminate.sh <resource-group-name>"
    exit 1
fi

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

# Check if resource group exists
if ! az group show --name "$RESOURCE_GROUP_NAME" &> /dev/null; then
    print_warning "Resource group '$RESOURCE_GROUP_NAME' does not exist. Nothing to clean up."
    exit 0
fi

print_warning "This will DELETE the entire resource group '$RESOURCE_GROUP_NAME' and ALL resources within it."
print_warning "This action is IRREVERSIBLE!"
echo ""

# Ask for confirmation
read -p "Are you sure you want to continue? (type 'yes' to confirm): " confirmation

if [[ "$confirmation" != "yes" ]]; then
    print_status "Cleanup cancelled."
    exit 0
fi

print_status "Deleting resource group '$RESOURCE_GROUP_NAME'..."
az group delete \
  --name "$RESOURCE_GROUP_NAME" \
  --yes \
  --no-wait

print_header "Cleanup Summary"
echo -e "${GREEN}✅ Resource group deletion initiated!${NC}"
echo ""
echo "Resource Group: $RESOURCE_GROUP_NAME"
echo ""
echo -e "${BLUE}📋 Notes:${NC}"
echo "  • Deletion is running in the background (--no-wait flag used)"
echo "  • It may take several minutes to complete"
echo "  • All resources including AKS cluster, VNet, and monitoring will be removed"
echo ""
echo -e "${BLUE}🔍 To check deletion status:${NC}"
echo "  az group show --name $RESOURCE_GROUP_NAME"
echo ""
echo -e "${BLUE}🧹 Additional cleanup (if needed):${NC}"
echo "  • Remove kubectl context: kubectl config delete-context $RESOURCE_GROUP_NAME"
echo "  • Clean up local kubeconfig entries if needed"