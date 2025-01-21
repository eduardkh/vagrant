sudo apt-get remove docker docker-engine docker.io containerd runc
echo "apt-get remove docker docker-engine docker.io containerd runc"
curl -fsSL https://get.docker.com -o get-docker.sh
echo "curl -fsSL https://get.docker.com -o get-docker.sh"
sudo sh get-docker.sh
echo "sh get-docker.sh"
sudo apt install python3-pip -y
echo "apt install python3-pip -y"