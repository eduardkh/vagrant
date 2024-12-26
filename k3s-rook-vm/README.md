# k3s-rook-vm

> deploy rook

```bash
# Clone the Rook Repository
git clone --single-branch --branch v1.11.3 https://github.com/rook/rook.git
cd rook/deploy/examples

# Apply CRDs, Common Settings, and the Operator
kubectl create -f crds.yaml -f common.yaml -f operator.yaml

# Verify the Rook Operator
kubectl -n rook-ceph get pods

# add kubectl bash completion
sudo su
kubectl completion bash > /etc/bash_completion.d/kubectl
```

> configure rook

```yaml
apiVersion: ceph.rook.io/v1
kind: CephCluster
metadata:
  name: rook-ceph
  namespace: rook-ceph
spec:
  dataDirHostPath: /var/lib/rook # Directory on the host machine (create it!)
  mon:
    count: 1
    allowMultiplePerNode: true # Important for single-node k3s
  mgr:
    count: 1
  dashboard:
    enabled: true
  monitoring:
    enabled: true
  storage:
    useAllNodes: true
    useAllDevices: false # Important: Do NOT use all devices for testing in Vagrant
    deviceFilter: "" # Optional: Filter devices if needed
    config:
      databaseSizeMB: "1024"
      journalSizeMB: "1024"
```

```bash
kubectl -n rook-ceph get pods -w # Watch for pod status changes
kubectl -n rook-ceph logs -f $(kubectl -n rook-ceph get pod -l app=rook-ceph-operator -o jsonpath='{.items[0].metadata.name}') # Check operator logs
```
