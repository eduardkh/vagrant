#!/usr/bin/env bash
# MILESTONE 2: controller Python, pip Ansible, completion, SSH identity, and
# Ansible-driven worker Python parity. Run as vagrant, NOT root.
# The host wrapper milestone-2.ps1 handles the initial authenticated key exchange.
set -euo pipefail
[[ $EUID -ne 0 ]] || { echo 'Run as vagrant, not root' >&2; exit 1; }
cd /vagrant
source ./versions.env
export PATH="$HOME/.local/bin:/usr/local/bin:$PATH"
venv=$HOME/.local/share/jenkins-lab/ansible
mode=${1:---configure}

case "$mode" in
  --prepare)
    echo '[Milestone 2 / 1] Install current Python on the controller'
    sudo bash /vagrant/install-python.sh "$PYTHON_RPM" "$PYTHON_PIP_RPM" "$PYTHON_BIN"

    echo '[Milestone 2 / 2] Install pinned Ansible and argcomplete with pip'
    # Inspection found no RPM Ansible installed. Refuse mixed installations if
    # one appears later; removal should be reviewed rather than removing deps.
    if rpm -q ansible-core >/dev/null 2>&1 || rpm -q ansible >/dev/null 2>&1; then
      echo 'Remove the RPM Ansible installation before continuing' >&2
      exit 1
    fi
    "$PYTHON_BIN" -m venv "$venv"
    requirements=/vagrant/requirements.txt
    [[ ! -f /vagrant/requirements.lock ]] || requirements=/vagrant/requirements.lock
    "$venv/bin/python" -m pip install --disable-pip-version-check -r "$requirements"
    "$venv/bin/python" -m pip check
    install -d -m 0755 "$HOME/.local/bin"
    for tool in ansible ansible-config ansible-console ansible-doc ansible-galaxy ansible-inventory ansible-playbook ansible-pull ansible-vault; do
      ln -sfn "$venv/bin/$tool" "$HOME/.local/bin/$tool"
    done
    # Keep login and interactive shells usable without manually activating venv.
    path_line='export PATH="$HOME/.local/bin:/usr/local/bin:$PATH"'
    for profile in "$HOME/.bashrc" "$HOME/.bash_profile"; do
      touch "$profile"
      grep -qxF "$path_line" "$profile" || printf '\n# Milestone 2: Python and Ansible\n%s\n' "$path_line" >> "$profile"
    done
    "$venv/bin/activate-global-python-argcomplete" --user

    echo '[Milestone 2 / 3] Generate controller SSH identity; private key stays here'
    install -d -m 0700 "$HOME/.ssh"
    if [[ ! -f "$HOME/.ssh/jenkins_lab_ed25519" ]]; then
      ssh-keygen -q -t ed25519 -N '' -C jenkins-lab-controller \
        -f "$HOME/.ssh/jenkins_lab_ed25519"
    fi
    chmod 0600 "$HOME/.ssh/jenkins_lab_ed25519"
    "$venv/bin/ansible" --version
    echo '[Milestone 2] Ready for authenticated enrollment by the host wrapper'
    ;;
  --configure)
    echo '[Milestone 2 / 4] Use the agent host key verified through Vagrant SSH'
    [[ -s /vagrant/.runtime/agent-known-hosts ]] || { echo 'Run milestone-2.ps1 first' >&2; exit 1; }
    install -m 0600 /vagrant/.runtime/agent-known-hosts "$HOME/.ssh/jenkins_lab_known_hosts"
    # Explicit config path keeps behavior independent of the working directory
    # and works if this directory is changed to a shared folder in the future.
    export ANSIBLE_CONFIG=/vagrant/ansible/ansible.cfg
    cd /vagrant/ansible
    echo '[Milestone 2 / 5] Use Ansible to install the SAME Python on the worker'
    "$venv/bin/ansible-playbook" site.yaml \
      -e "lab_python_version=$PYTHON_VERSION" -e "lab_python_bin=$PYTHON_BIN" \
      -e "lab_python_rpm=$PYTHON_RPM" -e "lab_python_pip_rpm=$PYTHON_PIP_RPM"
    echo '[Milestone 2 / 6] Verify local + SSH module execution and sudo'
    "$venv/bin/ansible" all -m ansible.builtin.ping
    "$venv/bin/ansible" all --become -m ansible.builtin.command -a 'id -u'
    ;;
  *) echo 'Usage: bash /vagrant/milestone-2.sh --prepare|--configure' >&2; exit 2 ;;
esac
