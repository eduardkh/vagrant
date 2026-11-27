#!/usr/bin/env bash
# MILESTONE 3: pinned Java/Jenkins RPMs and controller health through Ansible.
set -euo pipefail
[[ $EUID -ne 0 ]] || { echo 'Run as vagrant, not root' >&2; exit 1; }
export PATH="$HOME/.local/bin:/usr/local/bin:$PATH"
export ANSIBLE_CONFIG=/vagrant/ansible/ansible.cfg
cd /vagrant/ansible
echo '[Milestone 3] Install and validate the Jenkins controller'
"$HOME/.local/share/jenkins-lab/ansible/bin/ansible-playbook" jenkins-controller.yaml
