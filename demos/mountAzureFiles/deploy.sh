#! /bin/bash

# Designed to be run on the aksAGC demo cluster

# Variables
RESOURCE_GROUP="rg-aksstorage-demo"
AKS_RESOURCE_GROUP="rg-aks-agc-demo"
STORAGE_ACCOUNT_NAME="mystorageaccount$RANDOM"
LOCATION="swedencentral"

# Create resource group
az group create --name $RESOURCE_GROUP --location $LOCATION

# Create storage account with access keys disabled
az storage account create \
    --name $STORAGE_ACCOUNT_NAME \
    --resource-group $RESOURCE_GROUP \
    --location $LOCATION \
    --sku Standard_LRS \
    --kind StorageV2 \
    --enable-hierarchical-namespace true \
    --allow-blob-public-access false \
    --min-tls-version TLS1_2 \
    --allow-shared-key-access false

az storage share create \
    --account-name $STORAGE_ACCOUNT_NAME \
    --name demo

# Assign Blob Storage Account Contributor role to the managed identity
MANAGED_IDENTITY_NAME="id-aks"
MANAGED_IDENTITY_ID=$(az identity show --name $MANAGED_IDENTITY_NAME --resource-group $AKS_RESOURCE_GROUP --query 'principalId' -o tsv)

az role assignment create \
    --assignee $MANAGED_IDENTITY_ID \
    --role "Storage File Data SMB Share Contributor" \
    --scope /subscriptions/$(az account show --query 'id' -o tsv)/resourceGroups/$RESOURCE_GROUP/providers/Microsoft.Storage/storageAccounts/$STORAGE_ACCOUNT_NAME

k create -f sa.yaml
k create -f sc.yaml
k create -f pv.yaml
k create -f pvc.yaml
k create -f pod.yaml
