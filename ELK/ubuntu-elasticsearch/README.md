# rocky8-elasticsearch

> DRIVER = virtualbox
> IMAGE = "generic/rocky8"
> VERSION = "4.2.10"
> MEM = 4GB

## manual install as root

> in vagrant only (set default gateway on routed interface e.g. eth1)

```bash
# as root
nmcli connection modify System\ eth0 ipv4.never-default yes # unset D.G on eth0
nmcli connection modify System\ eth1 ipv4.gateway 192.168.1.254 # set D.G on eth1
nmcli connection modify System\ eth1 ipv4.route-metric 0 # lower metric is better
reboot now
ip route show # after restart
```

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

> set and check jvm heap size

```bash
echo '-Xms4g
-Xmx4g' > /etc/elasticsearch/jvm.options.d/memory.options
systemctl restart elasticsearch.service
curl --cacert /etc/elasticsearch/certs/http_ca.crt https://elastic:password@localhost:9200
curl --cacert /etc/elasticsearch/certs/http_ca.crt https://elastic:password@localhost:9200/_nodes/_all/jvm?pretty
```

> change elasticsearch.yml

```bash
sed -i.bak \
-e 's/^#node.name: node-1$/node.name: rocky8-elasticsearch01/' \
-e 's/^#network.host: 192.168.0.1$/network.host: 192.168.1.151/' \
-e 's/^#transport.host: 0.0.0.0$/transport.host: 192.168.1.151/' \
-e 's/^http.host: 0.0.0.0$/http.host: 192.168.1.151/' \
-e 's/^#http.port: 9200$/http.port: 9200/' \
/etc/elasticsearch/elasticsearch.yml

diff /etc/elasticsearch/elasticsearch.yml.bak /etc/elasticsearch/elasticsearch.yml

systemctl restart elasticsearch.service
systemctl status elasticsearch.service
curl --cacert /etc/elasticsearch/certs/http_ca.crt https://elastic:password@localhost:9200
curl --cacert /etc/elasticsearch/certs/http_ca.crt https://elastic:password@192.168.1.151:9200/_cat/nodes
```

> Generate enrollment token for Kibana

```bash
/usr/share/elasticsearch/bin/elasticsearch-create-enrollment-token -f -s kibana --url "https://192.168.1.151:9200"
```
