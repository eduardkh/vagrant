# echo "==>Updating the System"
# sudo dnf update -y

echo "==>install podman"
sudo dnf install podman -y

echo "==>Enable podman service"
sudo systemctl enable --now podman

echo "==>Check podman version"
podman --version

echo "==>Install Git and Make"
sudo dnf install git -y
sudo dnf install make -y

echo "==>Install Node.js"
sudo dnf install nodejs -y

echo "==>Install zsh"
git clone https://github.com/eduardkh/linux.git
cd linux/install-zsh/
make rocky