echo "192.168.1.155 dockervm" | sudo tee -a /etc/hosts
echo "hostname set to dockervm"
apt-get remove docker docker-engine docker.io containerd runc
echo "apt-get remove docker docker-engine docker.io containerd runc"
curl -fsSL https://get.docker.com -o get-docker.sh
echo "curl -fsSL https://get.docker.com -o get-docker.sh"
sh get-docker.sh
echo "sh get-docker.sh"