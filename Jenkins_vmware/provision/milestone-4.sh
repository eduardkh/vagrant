#!/usr/bin/env bash
# MILESTONE 4: pinned plugin resolution/deployment and English UI through Ansible.
set -euo pipefail
[[ $EUID -ne 0 ]] || { echo 'Run as vagrant, not root' >&2; exit 1; }
export PATH="$HOME/.local/bin:/usr/local/bin:$PATH"
export ANSIBLE_CONFIG=/vagrant/ansible/ansible.cfg
cd /vagrant/ansible
echo '[Milestone 4] Resolve, deploy and verify plugins; enforce English UI'
"$HOME/.local/share/jenkins-lab/ansible/bin/ansible-playbook" jenkins-plugins.yaml
