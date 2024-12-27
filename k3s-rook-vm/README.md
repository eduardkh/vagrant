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

```bash
# Prepare the Disk (sdb)
sudo wipefs -a /dev/sdb
lsblk

# Clone the Rook Repository
git clone --single-branch --branch v1.11.3 https://github.com/rook/rook.git
cd rook/deploy/examples

# Apply Rook Resources
kubectl apply -f crds.yaml
kubectl apply -f common.yaml
kubectl apply -f operator.yaml

kubectl -n rook-ceph get pods -w # Watch for pod status changes
```

```yaml
apiVersion: ceph.rook.io/v1
kind: CephCluster
metadata:
  name: rook-ceph
  namespace: rook-ceph
spec:
  dataDirHostPath: /var/lib/rook
  cephVersion:
    image: quay.io/ceph/ceph:v17.2.5 # Ensure this matches your Ceph version
  mon:
    count: 1
    allowMultiplePerNode: true
  mgr:
    count: 1
  dashboard:
    enabled: true
  monitoring:
    enabled: false # Disable monitoring if not required
  network:
    hostNetwork: false
  storage:
    useAllNodes: true
    useAllDevices: false
    devices:
      - name: "sdb" # Specify the raw disk
    config:
      databaseSizeMB: "1024"
      journalSizeMB: "1024"
```

```bash
vi ceph-cluster.yaml # paste yaml file
kubectl apply -f ceph-cluster.yaml
kubectl -n rook-ceph get pods -w

```
