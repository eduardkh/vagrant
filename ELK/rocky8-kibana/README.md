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

> enter the token in kibana on rocky8-kibana

```bash
/usr/share/kibana/bin/kibana-setup --enrollment-token <TOKEN>

```

> install nginx

```bash
dnf install nginx -y
```

> allow HTTP and HTTPS traffic

```bash
firewall-cmd --list-all
firewall-cmd --zone=public --permanent --add-service=http
firewall-cmd --zone=public --permanent --add-service=https
firewall-cmd --reload

```

> create /etc/nginx/nginx.conf (reverse proxy)

```bash
cat > /etc/nginx/nginx.conf <<EOF
user nginx;
worker_processes auto;
error_log /var/log/nginx/error.log;
pid /run/nginx.pid;

events {
    worker_connections 1024;
}

http {
    log_format  main  '$remote_addr - $remote_user [$time_local] "$request" '
                      '$status $body_bytes_sent "$http_referer" '
                      '"$http_user_agent" "$http_x_forwarded_for"';

    access_log  /var/log/nginx/access.log  main;

    sendfile            on;
    tcp_nopush          on;
    tcp_nodelay         on;
    keepalive_timeout   65;
    types_hash_max_size 2048;

    include             /etc/nginx/mime.types;
    default_type        application/octet-stream;

    server {
        listen 80;
        server_name 192.168.1.151;

        location / {
            proxy_pass http://127.0.0.1:5601;
            proxy_set_header Host \$host;
            proxy_set_header X-Real-IP \$remote_addr;
        }
    }
}
EOF
```

> restart service and allow in selinux

```bash
sudo nginx -t
sudo systemctl start nginx
sudo systemctl enable nginx
setsebool -P httpd_can_network_connect 1
```

> install fleet (from kibana GUI)

```bash
# set endpoint (https://192.168.1.151:8220)
curl -L -O https://artifacts.elastic.co/downloads/beats/elastic-agent/elastic-agent-8.7.1-linux-x86_64.tar.gz
tar xzvf elastic-agent-8.7.1-linux-x86_64.tar.gz
cd elastic-agent-8.7.1-linux-x86_64
sudo ./elastic-agent install \
  --fleet-server-es=https://10.0.2.15:9200 \
  --fleet-server-service-token=<TOKEN> \
  --fleet-server-policy=fleet-server-policy \
  --fleet-server-es-ca-trusted-fingerprint=<FINGERPRINT>
```

> allow 8220 on host firewall

```bash
firewall-cmd --zone=public --permanent --add-port=8220/tcp
firewall-cmd --reload
```

> on agent (windows box)

```bash
$ProgressPreference = 'SilentlyContinue'
Invoke-WebRequest -Uri https://artifacts.elastic.co/downloads/beats/elastic-agent/elastic-agent-8.7.1-windows-x86_64.zip -OutFile elastic-agent-8.7.1-windows-x86_64.zip
Expand-Archive .\elastic-agent-8.7.1-windows-x86_64.zip -DestinationPath .
cd elastic-agent-8.7.1-windows-x86_64
.\elastic-agent.exe install --url=https://192.168.1.151:8220 --enrollment-token=<TOKEN>
```
