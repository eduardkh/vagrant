# rocky8-kibana

> DRIVER = virtualbox
> IMAGE = "generic/rocky8"
> VERSION = "4.2.10"
> MEM = 4GB

## manual install as root

> add elasticsearch repo

```bash
rpm --import https://artifacts.elastic.co/GPG-KEY-elasticsearch

echo '[kibana-8.x]
name=Kibana repository for 8.x packages
baseurl=https://artifacts.elastic.co/packages/8.x/yum
gpgcheck=1
gpgkey=https://artifacts.elastic.co/GPG-KEY-elasticsearch
enabled=1
autorefresh=1
type=rpm-md' > /etc/yum.repos.d/kibana.repo
```

> install kibana

```bash
dnf install kibana -y
```

> enable and start kibana

```bash
systemctl daemon-reload
systemctl enable kibana.service
systemctl start kibana.service
```

> check service status

```bash
systemctl status kibana.service
```

> install nginx

```bash
dnf install nginx -y
```
