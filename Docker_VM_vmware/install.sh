echo "remove previous iterations of Docker if exists"
for pkg in docker.io docker-doc docker-compose docker-compose-v2 podman-docker containerd runc; do sudo apt-get remove $pkg; done
echo "remove previous iterations of Docker if exists - Done"

# https://docs.docker.com/engine/install/ubuntu/#install-using-the-convenience-script
echo "install Docker with convenience script"
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
echo "install Docker with convenience script - Done"

echo "install pip3"
sudo apt install python3-pip -y
echo "install pip3 - Done"

# Install using APT:
sudo apt install bash-completion -y