#!/usr/bin/env bash
# MILESTONE 5: validate JCasC separately, then load desired settings on controller.
set -euo pipefail
[[ $EUID -ne 0 ]] || { echo 'Run as vagrant, not root' >&2; exit 1; }
export PATH="$HOME/.local/bin:/usr/local/bin:$PATH"
export ANSIBLE_CONFIG=/vagrant/ansible/ansible.cfg
cd /vagrant/ansible
echo '[Milestone 5] Validate and apply Jenkins Configuration as Code'
"$HOME/.local/share/jenkins-lab/ansible/bin/ansible-playbook" jenkins-jcasc.yaml
