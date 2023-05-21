# ubuntu-elasticsearch

> DRIVER = virtualbox
> IMAGE = generic/ubuntu2204
> VERSION = "4.2.16"
> MEM = 4GB

## elasticsearch (manual install as root)

> in vagrant only (set default gateway on routed interface e.g. eth1)

```bash
# as root
nmcli connection modify System\ eth0 ipv4.never-default yes # unset D.G on eth0
nmcli connection modify System\ eth1 ipv4.gateway 192.168.1.254 # set D.G on eth1
nmcli connection modify System\ eth1 ipv4.route-metric 0 # lower metric is better
reboot now
ip route show # after restart
```

> add and install elasticsearch repo

```bash
wget -qO - https://artifacts.elastic.co/GPG-KEY-elasticsearch | sudo gpg --dearmor -o /usr/share/keyrings/elasticsearch-keyring.gpg
apt-get install apt-transport-https
echo "deb [signed-by=/usr/share/keyrings/elasticsearch-keyring.gpg] https://artifacts.elastic.co/packages/8.x/apt stable main" | sudo tee /etc/apt/sources.list.d/elastic-8.x.list
apt-get update && sudo apt-get install elasticsearch

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
curl --cacert /etc/elasticsearch/certs/http_ca.crt -u elastic https://192.168.1.151:9200
# or
curl --cacert /etc/elasticsearch/certs/http_ca.crt -u elastic:password https://192.168.1.151:9200
# or
curl --cacert /etc/elasticsearch/certs/http_ca.crt https://elastic:password@192.168.1.151:9200
```

> set and check jvm heap size (optional)

```bash
echo '-Xms4g
-Xmx4g' > /etc/elasticsearch/jvm.options.d/memory.options
systemctl restart elasticsearch.service
curl --cacert /etc/elasticsearch/certs/http_ca.crt https://elastic:password@192.168.1.151:9200
curl --cacert /etc/elasticsearch/certs/http_ca.crt https://elastic:password@192.168.1.151:9200/_nodes/_all/jvm?pretty
```

> change elasticsearch.yml

```bash
sed -i.bak \
-e 's/^#node.name: node-1$/node.name: ubuntu-elasticsearch01/' \
-e 's/^#network.host: 192.168.0.1$/network.host: 192.168.1.151/' \
-e 's/^#transport.host: 0.0.0.0$/transport.host: 192.168.1.151/' \
-e 's/^http.host: 0.0.0.0$/http.host: 192.168.1.151/' \
-e 's/^#http.port: 9200$/http.port: 9200/' \
/etc/elasticsearch/elasticsearch.yml

diff /etc/elasticsearch/elasticsearch.yml.bak /etc/elasticsearch/elasticsearch.yml

systemctl restart elasticsearch.service
systemctl status elasticsearch.service
curl --cacert /etc/elasticsearch/certs/http_ca.crt https://elastic:password@192.168.1.151:9200
curl --cacert /etc/elasticsearch/certs/http_ca.crt https://elastic:password@192.168.1.151:9200/_cat/nodes
```

### kibana

> install kibana

```bash
apt-get update && apt-get install kibana
```

> enable and start kibana

```bash
systemctl daemon-reload
systemctl enable kibana.service
systemctl start kibana.service
systemctl status kibana.service
```

> Generate enrollment token for Kibana

```bash
/usr/share/elasticsearch/bin/elasticsearch-create-enrollment-token -f -s kibana --url "https://192.168.1.151:9200"
```

> enter the token in kibana-setup

```bash
/usr/share/kibana/bin/kibana-setup --enrollment-token <TOKEN>
```

> install nginx and check status

```bash
apt-get install nginx -y
systemctl status nginx.service
```

> update /etc/nginx/nginx.conf (reverse proxy)

```bash
cat > /etc/nginx/nginx.conf <<EOF
user www-data;
worker_processes auto;
pid /run/nginx.pid;
include /etc/nginx/modules-enabled/*.conf;

events {
    worker_connections 1024;
}

http {
    sendfile on;
    tcp_nopush on;
    tcp_nodelay on;
    keepalive_timeout 65;
    types_hash_max_size 2048;

    include /etc/nginx/mime.types;
    default_type application/octet-stream;

    access_log /var/log/nginx/access.log;
    error_log /var/log/nginx/error.log;

    gzip on;
    gzip_disable "msie6";

    server {
        listen 80;
        server_name _;

        location / {
            proxy_pass http://127.0.0.1:5601;
            proxy_set_header Host \$host;
            proxy_set_header X-Real-IP \$remote_addr;
        }
    }
}
EOF

systemctl restart nginx.service
```

> kibana-verification-code

```bash
/usr/share/kibana/bin/kibana-verification-code
```

> Encryption keys

```bash
# generate
/usr/share/kibana/bin/kibana-encryption-keys generate
# place in kibana.yml
echo 'KEYS' >> /etc/kibana/kibana.yml
```
