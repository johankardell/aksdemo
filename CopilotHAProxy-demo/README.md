# CopilotHAProxy AKS Demo

This sample demonstrates how to deploy Azure Kubernetes Service (AKS) with VNet injection, workload profile enabled, and HAProxy as an ingress controller to expose NGINX to the Internet.

## Architecture

This deployment creates:

- **Azure Kubernetes Service (AKS)** with VNet injection and workload profile enabled
- **Virtual Network** with dedicated subnet for AKS
- **HAProxy Ingress Controller** for external traffic routing
- **NGINX deployment** with 3 replicas using `nginx:latest`
- **Log Analytics workspace** for monitoring
- **Managed Identity** for AKS cluster authentication

### Workload Profile Features

The AKS cluster is configured with the following workload profile features:
- **Workload Identity** - Enables Azure AD workload identity for pods
- **KEDA Auto-scaler** - Kubernetes Event-driven Autoscaling for dynamic scaling
- **Auto-upgrade Profile** - Automatic Kubernetes and node OS updates
- **Azure Key Vault Secrets Provider** - Secure secrets management

## Quick Start

### Prerequisites

1. **Azure CLI** installed and logged in (`az login`)
2. **kubectl** installed for Kubernetes management
3. **SSH key pair** at `~/.ssh/id_rsa.pub` for node access
4. **Azure subscription** with sufficient permissions

### Deploy

```bash
# Clone the repository
git clone https://github.com/johankardell/aksdemo.git
cd aksdemo/CopilotHAProxy-demo

# Deploy with default settings
./deploy.sh

# Or deploy to a specific resource group and location
./deploy.sh "my-resource-group" "East US"
```

### Access Your Application

After deployment, the script will output the HAProxy LoadBalancer IP address. Access your application at:

```
http://<HAPROXY_LOADBALANCER_IP>
```

### Clean Up

```bash
# Delete all resources
./terminate.sh "rg-copilot-haproxy-demo"
```

## Project Structure

```
CopilotHAProxy-demo/
├── main.bicep                     # Main Bicep template
├── parameters.json                # Deployment parameters
├── deploy.sh                      # Automated deployment script
├── terminate.sh                   # Cleanup script
├── README.md                      # This file
├── modules/                       # Bicep modules
│   ├── aks.bicep                 # AKS cluster with workload profile
│   ├── vnet.bicep                # Virtual network with VNet injection
│   ├── logAnalytics.bicep        # Log Analytics workspace
│   └── managedIdentity.bicep     # Managed identity and RBAC
└── manifests/                     # Kubernetes manifests
    ├── haproxy-ingress.yaml      # HAProxy Ingress Controller
    ├── nginx-deployment.yaml     # NGINX deployment with 3 replicas
    └── nginx-ingress.yaml        # Ingress resource for NGINX
```

## Configuration

### Infrastructure Parameters

Modify `parameters.json` to customize the deployment:

```json
{
  "environmentName": { "value": "dev" },
  "kubernetesVersion": { "value": "1.31" },
  "systemNodeVmSize": { "value": "Standard_D2s_v5" },
  "userNodeVmSize": { "value": "Standard_D2s_v5" },
  "systemNodeCount": { "value": 1 },
  "userNodeCount": { "value": 2 }
}
```

### Network Configuration

The deployment uses the following network configuration:
- **VNet CIDR**: `10.1.0.0/16`
- **AKS Subnet**: `10.1.0.0/20`
- **Service CIDR**: `172.16.0.0/16`
- **Pod CIDR**: `192.168.0.0/16`

## Manual Deployment Steps

If you prefer to deploy manually:

### 1. Create Resource Group
```bash
az group create --name rg-copilot-haproxy-demo --location "Sweden Central"
```

### 2. Deploy Infrastructure
```bash
az deployment group create \
  --resource-group rg-copilot-haproxy-demo \
  --template-file main.bicep \
  --parameters @parameters.json \
  --parameters sshPublicKey="$(cat ~/.ssh/id_rsa.pub)"
```

### 3. Configure kubectl
```bash
az aks get-credentials \
  --resource-group rg-copilot-haproxy-demo \
  --name <aks-cluster-name>
```

### 4. Deploy HAProxy Ingress Controller
```bash
kubectl apply -f manifests/haproxy-ingress.yaml
```

### 5. Deploy NGINX Application
```bash
kubectl apply -f manifests/nginx-deployment.yaml
kubectl apply -f manifests/nginx-ingress.yaml
```

## Useful Commands

### Cluster Management
```bash
# Get cluster info
kubectl cluster-info

# View all pods
kubectl get pods --all-namespaces

# View all services
kubectl get services --all-namespaces

# Get HAProxy LoadBalancer IP
kubectl get service haproxy-ingress -n haproxy-controller
```

### Application Management
```bash
# Scale NGINX deployment
kubectl scale deployment nginx-deployment --replicas=5

# View NGINX logs
kubectl logs -l app=nginx

# View HAProxy logs
kubectl logs -l app=haproxy-ingress -n haproxy-controller

# Check ingress status
kubectl get ingress nginx-ingress
```

### Monitoring
```bash
# Check node status
kubectl get nodes

# View resource usage
kubectl top nodes
kubectl top pods

# Check HAProxy stats (if stats port is exposed)
kubectl port-forward -n haproxy-controller service/haproxy-ingress 1024:1024
# Then visit http://localhost:1024/stats
```

## Key Features Demonstrated

### 1. VNet Injection
- AKS cluster deployed into a custom virtual network
- Dedicated subnet for AKS nodes
- Network security groups for traffic control

### 2. Workload Profile Enabled
- **Workload Identity**: Secure authentication for workloads
- **KEDA Auto-scaler**: Event-driven autoscaling capabilities
- **Auto-upgrade Profile**: Automated cluster and node updates
- **Key Vault Integration**: Secure secrets management

### 3. HAProxy Ingress Controller
- Industry-standard load balancer and reverse proxy
- High-performance traffic routing
- LoadBalancer service for Internet exposure
- Custom configuration through ConfigMaps

### 4. NGINX Application
- 3 replicas for high availability
- Using `nginx:latest` as specified
- Custom welcome page showing architecture
- Health checks and resource limits

## Troubleshooting

### Common Issues

1. **LoadBalancer IP Pending**
   ```bash
   # Check service status
   kubectl get service haproxy-ingress -n haproxy-controller
   
   # Check Azure Load Balancer
   az network lb list --resource-group MC_*
   ```

2. **Pods Not Starting**
   ```bash
   # Check pod status and events
   kubectl describe pod <pod-name>
   kubectl get events --sort-by=.metadata.creationTimestamp
   ```

3. **Ingress Not Working**
   ```bash
   # Check ingress controller logs
   kubectl logs -l app=haproxy-ingress -n haproxy-controller
   
   # Verify ingress resource
   kubectl describe ingress nginx-ingress
   ```

### Logs and Debugging

```bash
# HAProxy Ingress Controller logs
kubectl logs -f deployment/haproxy-ingress -n haproxy-controller

# NGINX application logs
kubectl logs -f deployment/nginx-deployment

# Check all events
kubectl get events --sort-by=.metadata.creationTimestamp --all-namespaces
```

## Cost Optimization

To reduce costs during testing:

1. **Scale down nodes**:
   ```bash
   az aks scale --resource-group rg-copilot-haproxy-demo \
     --name <cluster-name> --node-count 1
   ```

2. **Use smaller VM sizes** in `parameters.json`:
   ```json
   {
     "systemNodeVmSize": { "value": "Standard_B2s" },
     "userNodeVmSize": { "value": "Standard_B2s" }
   }
   ```

3. **Delete when not in use**:
   ```bash
   ./terminate.sh rg-copilot-haproxy-demo
   ```

## Security Considerations

- **Network Security Groups** control traffic flow
- **Managed Identity** eliminates need for service principals
- **Workload Identity** provides secure pod authentication
- **Private networking** through VNet injection
- **RBAC** enabled on AKS cluster

## Contributing

This sample is part of the [aksdemo repository](https://github.com/johankardell/aksdemo). Feel free to contribute improvements or report issues.

## License

This project is licensed under the terms specified in the main repository.