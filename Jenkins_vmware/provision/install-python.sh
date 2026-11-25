#!/usr/bin/env bash
# MILESTONE 2: controller bootstrap using Rocky's dnf Python packages.
# The worker uses native Ansible dnf tasks in ansible/site.yaml.
set -euo pipefail
python_rpm=${1:?Pinned Python RPM required}
pip_rpm=${2:?Pinned pip RPM required}
python_bin=${3:?Versioned Python executable required}
[[ $EUID -eq 0 ]] || { echo 'Run this installer as root' >&2; exit 1; }

# M2.1: Repository packages only. No source download or compilation.
echo "[Milestone 2] Installing $python_rpm and $pip_rpm with dnf"
dnf install -q -y "$python_rpm" "$pip_rpm" bash-completion

# M2.2: Alternatives manages administrator defaults. Rocky's RPM-owned
# /usr/bin/python* remain intact; dnf explicitly uses /usr/bin/python3.9.
alternatives --install /usr/local/bin/python3 python3 "$python_bin" 314
alternatives --set python3 "$python_bin"
alternatives --install /usr/local/bin/python python "$python_bin" 314
alternatives --set python "$python_bin"
cat > /etc/profile.d/jenkins-python.sh <<'EOF'
# Milestone 2: prefer alternatives-managed Python in login shells.
export PATH=/usr/local/bin:$PATH
EOF
"$python_bin" -c 'import ssl, sqlite3, ctypes, bz2, lzma, readline, venv'
/usr/local/bin/python3 --version
/usr/bin/dnf --version >/dev/null
