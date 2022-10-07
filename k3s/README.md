# k3s on vagrant VM

> install

```bash
curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC='--write-kubeconfig-mode=644 --node-ip=192.168.1.155 --flannel-iface=eth1' sh -
```

> check install

```bash
kubectl get all -A
```

> run sample app from [here](https://dev.to/fransafu/the-first-experience-with-k3s-lightweight-kubernetes-deploy-your-first-app-44ea)

```bash
kubectl apply -f simple-rest-golang-dep.yaml
kubectl apply -f simple-rest-golang-svc.yaml
kubectl apply -f simple-rest-golang-ingress.yaml
```

> uninstall

```bash
/usr/local/bin/k3s-uninstall.sh
```
