echo "192.168.1.155 dockervm" | sudo tee -a /etc/hosts
echo "hostname set to dockervm"
apt-get remove docker docker-engine docker.io containerd runc
echo "apt-get remove docker docker-engine docker.io containerd runc"
curl -fsSL https://get.docker.com -o get-docker.sh
echo "curl -fsSL https://get.docker.com -o get-docker.sh"
sh get-docker.sh
echo "sh get-docker.sh"
curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose
curl -L https://raw.githubusercontent.com/docker/compose/1.29.2/contrib/completion/bash/docker-compose -o /etc/bash_completion.d/docker-compose
echo "added docker-compose"