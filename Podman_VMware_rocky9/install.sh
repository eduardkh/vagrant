# echo "==>Updating the System"
# sudo dnf update -y

echo "==>install podman"
sudo dnf install podman -y

echo "==>Enable podman service"
sudo systemctl enable --now podman

echo "==>Check podman version"
podman --version

echo "==>Install Helm"
sudo dnf install helm -y
helm completion zsh > "${fpath[1]}/_helm"

echo "==>Install jq"
sudo dnf install jq -y

echo "==>Install Node.js"
sudo dnf module reset nodejs -y
sudo dnf module enable nodejs:20 -y        # or :22 if available
sudo dnf install -y nodejs

echo "==>Install Git and Make"
sudo dnf install git -y
sudo dnf install make -y

echo "==>Install zsh"
git clone https://github.com/eduardkh/linux.git
cd linux/install-zsh/
make rocky