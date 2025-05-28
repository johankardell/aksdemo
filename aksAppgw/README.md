# Azure AKS with Application Gateway Demo

This solution demonstrates how to deploy an Azure Kubernetes Service (AKS) cluster with an Azure Application Gateway as the frontend, using Bicep Infrastructure as Code.

## Architecture

The solution creates the following Azure resources:

```
┌─────────────────────────────────────────────────┐
│                Azure VNet                       │
│  ┌─────────────────┐  ┌─────────────────────┐   │
│  │ Application     │  │ AKS Subnet          │   │
│  │ Gateway Subnet  │  │ (10.0.1.0/24)       │   │
│  │ (10.0.2.0/24)   │  │                     │   │
│  │                 │  │ ┌─────────────────┐ │   │
│  │ ┌─────────────┐ │  │ │ NGINX Pods      │ │   │
│  │ │ App Gateway │─┼──┼─│ (LoadBalancer)  │ │   │
│  │ │ (Public IP) │ │  │ └─────────────────┘ │   │
│  │ └─────────────┘ │  │                     │   │
│  └─────────────────┘  └─────────────────────┘   │
└─────────────────────────────────────────────────┘
```

### Components

- **Virtual Network**: Isolated network with separate subnets for AKS and Application Gateway
- **Azure Kubernetes Service (AKS)**: Managed Kubernetes cluster with auto-scaling node pools
- **Application Gateway**: Layer 7 load balancer with public IP and health probes
- **NGINX Deployment**: Sample web application running on AKS
- **Log Analytics**: Monitoring and logging for the entire solution
- **Managed Identity**: Secure authentication for AKS to Azure resources

## Prerequisites

Before deploying this solution, ensure you have:

1. **Azure CLI** installed and configured
   ```bash
   az --version
   az login
   ```

2. **kubectl** for Kubernetes management
   ```bash
   kubectl version --client
   ```

3. **SSH Key Pair** for AKS node access
   ```bash
   ssh-keygen -t rsa -b 4096 -C "your-email@domain.com"
   ```

4. **Appropriate Azure permissions** to create resources in your subscription

## Quick Start

### 1. Clone and Navigate
```bash
git clone <your-repo>
cd aksAppgw
```

### 2. Update Parameters
Edit `parameters.json` with your specific values:

```json
{
  "environmentName": { "value": "dev" },
  "location": { "value": "Sweden Central" },
  "sshPublicKey": { "value": "your-ssh-public-key-here" }
}
```

### 3. Deploy Infrastructure
```bash
./deploy.sh [resource-group-name] [location]
```

Example:
```bash
./deploy.sh rg-aks-appgw-demo "Sweden Central"
```

### 4. Access Your Application
After deployment completes, access your NGINX application via the Application Gateway public IP:
```
http://<application-gateway-public-ip>
```

## Manual Deployment Steps

If you prefer to deploy manually:

### 1. Create Resource Group
```bash
az group create --name rg-aks-appgw-demo --location "Sweden Central"
```

### 2. Deploy Bicep Template
```bash
az deployment group create \
  --resource-group rg-aks-appgw-demo \
  --template-file main.bicep \
  --parameters @parameters.json
```

### 3. Configure kubectl
```bash
az aks get-credentials \
  --resource-group rg-aks-appgw-demo \
  --name <aks-cluster-name>
```

### 4. Deploy NGINX
```bash
kubectl apply -f manifests/nginx-deployment.yaml
```

### 5. Update Application Gateway Backend
```bash
# Get NGINX LoadBalancer IP
NGINX_IP=$(kubectl get service nginx-service -o jsonpath='{.status.loadBalancer.ingress[0].ip}')

# Update Application Gateway backend pool
az network application-gateway address-pool update \
  --resource-group rg-aks-appgw-demo \
  --gateway-name <app-gateway-name> \
  --name appGatewayBackendPool \
  --servers $NGINX_IP
```

## Project Structure

```
aksAppgw/
├── main.bicep                      # Main Bicep template
├── parameters.json                 # Deployment parameters
├── deploy.sh                      # Automated deployment script
├── terminate.sh                   # Cleanup script
├── README.md                      # This file
├── modules/                       # Bicep modules
│   ├── aks.bicep                 # AKS cluster configuration
│   ├── appGateway.bicep          # Application Gateway setup
│   ├── logAnalytics.bicep        # Log Analytics workspace
│   ├── managedIdentity.bicep     # Managed identity and RBAC
│   └── vnet.bicep                # Virtual network and subnets
└── manifests/                     # Kubernetes manifests
    └── nginx-deployment.yaml     # NGINX deployment and service
```

## Bicep Modules

### main.bicep
Orchestrates the deployment of all resources with proper dependencies and outputs.

### modules/vnet.bicep
- Creates VNet with address space 10.0.0.0/16
- AKS subnet (10.0.1.0/24) with Network Security Group
- Application Gateway subnet (10.0.2.0/24) with Network Security Group
- Proper routing and security rules

### modules/aks.bicep
- AKS cluster with Azure CNI networking
- System node pool (1 node) and user node pool (2 nodes)
- Auto-scaling enabled (1-10 nodes)
- Integration with Log Analytics and Azure Monitor
- Workload identity and managed identity support

### modules/appGateway.bicep
- Application Gateway v2 with auto-scaling
- Public IP with DNS label
- Health probes for backend monitoring
- HTTP routing rules and backend pools
- Ready for SSL termination (can be extended)

### modules/managedIdentity.bicep
- User-assigned managed identity for AKS
- Network Contributor and Managed Identity Operator role assignments
- Secure authentication without service principals

### modules/logAnalytics.bicep
- Log Analytics workspace for monitoring
- Container insights solution
- Retention and data collection configuration

## Kubernetes Manifests

### nginx-deployment.yaml
- NGINX deployment with 3 replicas
- LoadBalancer service for internal exposure
- ConfigMap with custom HTML page
- Health checks and resource limits
- Restricted access from Application Gateway subnet

## Configuration Options

### Scaling
Modify node counts in `parameters.json`:
```json
{
  "systemNodeCount": { "value": 1 },
  "userNodeCount": { "value": 3 }
}
```

Or scale at runtime:
```bash
az aks scale --resource-group rg-aks-appgw-demo --name <cluster-name> --node-count 5
```

### VM Sizes
Update VM sizes for cost optimization:
```json
{
  "systemNodeVmSize": { "value": "Standard_D2s_v5" },
  "userNodeVmSize": { "value": "Standard_D4s_v5" }
}
```

### Kubernetes Version
Specify AKS version:
```json
{
  "kubernetesVersion": { "value": "1.30.6" }
}
```

## Monitoring and Troubleshooting

### View Deployment Status
```bash
# Check deployment status
az deployment group show \
  --resource-group rg-aks-appgw-demo \
  --name <deployment-name>

# Check AKS cluster status
kubectl get nodes
kubectl get pods --all-namespaces
```

### Application Gateway Health
```bash
# Check backend pool health
az network application-gateway show-backend-health \
  --resource-group rg-aks-appgw-demo \
  --name <app-gateway-name>
```

### NGINX Service Status
```bash
# Check service and endpoints
kubectl get service nginx-service
kubectl get endpoints nginx-service
kubectl describe service nginx-service
```

### Logs and Diagnostics
```bash
# View pod logs
kubectl logs -l app=nginx

# Describe problematic pods
kubectl describe pod <pod-name>

# Check events
kubectl get events --sort-by='.lastTimestamp'
```

## Security Considerations

This solution implements several security best practices:

1. **Network Isolation**: Separate subnets for AKS and Application Gateway
2. **Managed Identity**: No service principal credentials stored
3. **RBAC**: Minimal required permissions assigned
4. **Network Security Groups**: Restrict traffic between subnets
5. **Private Networking**: AKS nodes in private subnet
6. **Health Monitoring**: Comprehensive health checks and monitoring

## Cost Optimization

- **Node Auto-scaling**: Automatically scales based on demand
- **Burstable VM Series**: Use Standard_B series for dev/test environments
- **Reserved Instances**: Consider reservations for production workloads
- **Spot Instances**: Use spot node pools for fault-tolerant workloads

## Production Considerations

For production deployments, consider:

1. **SSL/TLS Termination**: Configure HTTPS listeners on Application Gateway
2. **Custom Domain**: Use Azure DNS or custom domain names
3. **WAF Protection**: Enable Web Application Firewall on Application Gateway
4. **Backup Strategy**: Implement backup for persistent volumes
5. **Disaster Recovery**: Multi-region deployment with traffic manager
6. **Secrets Management**: Use Azure Key Vault for sensitive data
7. **GitOps**: Implement GitOps with Azure Arc or Flux

## Cleanup

To remove all resources:

```bash
./terminate.sh rg-aks-appgw-demo
```

Or manually:
```bash
az group delete --name rg-aks-appgw-demo --yes --no-wait
```

## Troubleshooting Common Issues

### Application Gateway Cannot Reach Backend
1. Check NGINX service LoadBalancer IP assignment
2. Verify Application Gateway backend pool configuration
3. Ensure Network Security Group rules allow traffic
4. Check health probe configuration

### AKS Nodes Not Starting
1. Verify subnet has sufficient IP addresses
2. Check Node Resource Group permissions
3. Review AKS cluster logs in Azure portal

### kubectl Connection Issues
1. Ensure you have the latest AKS credentials:
   ```bash
   az aks get-credentials --resource-group <rg> --name <cluster> --overwrite-existing
   ```
2. Check your kubeconfig context:
   ```bash
   kubectl config current-context
   ```

## Support and Contributing

For issues and questions:
1. Check Azure AKS documentation
2. Review Application Gateway troubleshooting guides
3. Use `kubectl describe` and `kubectl logs` for Kubernetes issues
4. Enable diagnostic settings for detailed logging

## License

This project is licensed under the MIT License. See LICENSE file for details.
