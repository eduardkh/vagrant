#!/usr/bin/env bash
set -euo pipefail

echo "==> Disable firewall (dev only)"
sudo systemctl stop firewalld || true
sudo systemctl disable firewalld || true
sudo systemctl mask firewalld || true

echo "==> Set SELinux to permissive (runtime + persistent)"
if selinuxenabled; then
  sudo setenforce 0 || true
  sudo sed -ri 's/^SELINUX=.*/SELINUX=permissive/' /etc/selinux/config
fi

# echo "==> Updating the System"
# sudo dnf update -y

echo "==> Install Podman & compose"
sudo dnf -y install epel-release
sudo dnf -y install podman podman-compose
sudo systemctl enable --now podman
podman --version

echo "==> Install Helm"
sudo dnf -y install helm

echo "==> Install jq"
sudo dnf -y install jq

echo "==> Install Node.js (LTS)"
sudo dnf -y module reset nodejs
sudo dnf -y module enable nodejs:20      # or :22 if available
sudo dnf -y install nodejs

echo "==> Install Git and Make"
sudo dnf -y install git make

echo "==> Install zsh (via your repo Makefile)"
git clone https://github.com/eduardkh/linux.git
cd linux/install-zsh/
make rocky
cd - >/dev/null || true

echo "==> Helm zsh completion (keep original behavior; safe under bash)"
# Your original line (works if running under zsh with $fpath set):
set +u +e
helm completion zsh > "${fpath[1]}/_helm" 2>/dev/null || true
set -euo pipefail
# Fallback for bash environments where $fpath is unset:
if [ ! -f /usr/share/zsh/site-functions/_helm ]; then
  sudo mkdir -p /usr/share/zsh/site-functions
  helm completion zsh | sudo tee /usr/share/zsh/site-functions/_helm >/dev/null
fi

echo "==> Done."
