# Simple AKS demo

This demo creates a single AKS cluster with a system node pool backed by a VMSS and a second user node pool named `apps` that uses AKS node auto-provisioning.

Key settings:
- `system` runs in `System` mode and is tainted with `CriticalAddonsOnly=true:NoSchedule` so only system workloads land there.
- `apps` runs in `User` mode and is configured with `nodeProvisioningMode: 'Auto'` so AKS can provision additional nodes on demand.
- The default system pool remains the control plane for cluster-critical workloads while app workloads can spill onto the auto-provisioned pool.

Deploy with:

```bash
az deployment sub create \
  --location <region> \
  --template-file main.bicep \
  --parameters sshkey="<ssh-public-key>" managementIP="<your-public-ip>/32" deployACR=true
```
