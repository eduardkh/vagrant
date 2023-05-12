# rocky8-elasticsearch

> DRIVER = virtualbox
> IMAGE = "generic/rocky8"
> VERSION = "4.2.10"
> MEM = 4GB

## manual install as root

> add elasticsearch repo

```bash
rpm --import https://artifacts.elastic.co/GPG-KEY-elasticsearch

echo '[elasticsearch]
name=Elasticsearch repository for 8.x packages
baseurl=https://artifacts.elastic.co/packages/8.x/yum
gpgcheck=1
gpgkey=https://artifacts.elastic.co/GPG-KEY-elasticsearch
enabled=0
autorefresh=1
type=rpm-md' > /etc/yum.repos.d/elasticsearch.repo
```

> install elasticsearch

```bash
dnf install --enablerepo=elasticsearch elasticsearch -y
```

> enable and start elasticsearch

```bash
systemctl daemon-reload
systemctl enable elasticsearch.service
systemctl start elasticsearch.service
```

> check service status

```bash
systemctl status elasticsearch.service
```

> change default superuser (elastic) password interactively

```bash
/usr/share/elasticsearch/bin/elasticsearch-reset-password -i -u elastic
```

> check elasticsearch service (curl)

```bash
curl --cacert /etc/elasticsearch/certs/http_ca.crt -u elastic https://localhost:9200
```
