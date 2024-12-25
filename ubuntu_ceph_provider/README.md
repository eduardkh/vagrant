# Minikube ceph-node

> ceph side

```bash
# Bootstrap the Ceph cluster
sudo cephadm bootstrap --mon-ip $(hostname -I | awk '{print $1}')

# Display Ceph cluster status
sudo cephadm shell -- ceph status

# Ceph osd
sudo cephadm shell -- ceph osd tree
sudo cephadm shell -- ceph osd in osd.0
sudo cephadm shell -- ceph orch daemon add osd ceph-node:/dev/sda
# sudo cephadm shell --fsid <fsid> -- ceph orch daemon add osd ceph-node:/dev/sda

# Ceph pool
sudo cephadm shell -- ceph osd pool create mypool 128
sudo cephadm shell -- ceph osd pool ls
sudo cephadm shell -- ceph osd pool stats

# Retrieve the Ceph key for your client (e.g., client.kubernetes):
sudo cephadm shell -- ceph auth get-key client.kubernetes
```

> minikube side

```bash
minikube start --cpus=4 --memory=8192 --network-plugin=cni

# Apply the Ceph CSI manifests
kubectl apply -f https://raw.githubusercontent.com/ceph/ceph-csi/devel/deploy/rbd/kubernetes/csi-rbdplugin.yaml
kubectl apply -f https://raw.githubusercontent.com/ceph/ceph-csi/devel/deploy/rbd/kubernetes/csi-rbdplugin-provisioner.yaml



```
