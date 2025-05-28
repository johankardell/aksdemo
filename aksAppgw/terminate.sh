#!/bin/bash
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
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

if [[ -z "$RESOURCE_GROUP_NAME" ]]; then
    print_error "Usage: $0 <resource-group-name>"
    exit 1
fi

print_header "Cleaning up Azure Resources"

# Check if Azure CLI is installed and logged in
if ! command -v az &> /dev/null; then
    print_error "Azure CLI is not installed."
    exit 1
fi

if ! az account show &> /dev/null; then
    print_error "Please log in to Azure CLI first: az login"
    exit 1
fi

# Check if resource group exists
if ! az group exists --name "$RESOURCE_GROUP_NAME" &> /dev/null; then
    print_warning "Resource group '$RESOURCE_GROUP_NAME' does not exist."
    exit 0
fi

print_warning "This will delete ALL resources in the resource group '$RESOURCE_GROUP_NAME'"
read -p "Are you sure you want to continue? (y/N): " -n 1 -r
echo

if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    print_status "Cancelling cleanup."
    exit 0
fi

print_status "Deleting resource group '$RESOURCE_GROUP_NAME'..."
az group delete \
  --name "$RESOURCE_GROUP_NAME" \
  --yes \
  --no-wait

print_status "Resource group deletion initiated. This may take several minutes to complete."
print_status "You can check the status with: az group show --name '$RESOURCE_GROUP_NAME'"
