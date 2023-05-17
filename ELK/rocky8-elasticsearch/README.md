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
# or
curl --cacert /etc/elasticsearch/certs/http_ca.crt -u elastic:password https://localhost:9200
# or
curl --cacert /etc/elasticsearch/certs/http_ca.crt https://elastic:password@localhost:9200
```

> Generate enrollment token for Kibana

```bash
/usr/share/elasticsearch/bin/elasticsearch-create-enrollment-token -s kibana --url https://192.168.1.151:9200
```

> set and check jvm heap size

```bash
echo '-Xms4g
-Xmx4g' > /etc/elasticsearch/jvm.options.d/memory.options

systemctl restart elasticsearch.service

curl --cacert /etc/elasticsearch/certs/http_ca.crt https://elastic:password@localhost:9200/_nodes/_all/jvm?pretty
```
