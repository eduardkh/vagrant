#!/usr/bin/env bash
# MILESTONE 6: provision worker, define SSH node in JCasC, verify a real pipeline.
set -euo pipefail
[[ $EUID -ne 0 ]] || { echo 'Run as vagrant, not root' >&2; exit 1; }
export PATH="$HOME/.local/bin:/usr/local/bin:$PATH"
export ANSIBLE_CONFIG=/vagrant/ansible/ansible.cfg
cd /vagrant/ansible
echo '[Milestone 6] Connect the Linux Jenkins agent using dedicated SSH credentials'
"$HOME/.local/share/jenkins-lab/ansible/bin/ansible-playbook" jenkins-linux-agent.yaml
