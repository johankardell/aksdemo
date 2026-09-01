# Simple AKS demo

This demo creates a single AKS Standard cluster with a system node pool backed by a VMSS and cluster-level AKS node auto-provisioning (NAP) for application workloads.

Key settings:
- `system` runs in `System` mode and is tainted with `CriticalAddonsOnly=true:NoSchedule` so only system workloads land there.
- `nodeProvisioningProfile.mode` is set to `Auto`, allowing AKS to create and manage workload nodes through NAP.
- Cluster autoscaler is disabled on the declared system pool because NAP owns node provisioning for the cluster.
- The system pool uses Azure Linux 3, while NAP selects workload VM sizes dynamically from the available regional quota.
- Kubernetes is pinned to the latest supported minor version configured by the template; AKS selects the current patch release and follows the `patch` auto-upgrade channel.
- During deployment, the signed-in Azure user receives the AKS RBAC Cluster Admin and Cluster User roles scoped to the cluster.

Azure Linux 4.0 is currently preview-only and isn't supported as an AKS node pool `osSku`, so the template remains on `AzureLinux3`.

Deploy with:

```bash
az deployment sub create \
  --location <region> \
  --template-file main.bicep \
  --parameters sshkey="<ssh-public-key>" managementIP="<your-public-ip>/32" deployACR=true
```
