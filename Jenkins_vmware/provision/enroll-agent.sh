#!/usr/bin/env bash
# MILESTONE 2: run as vagrant through Vagrant's authenticated management SSH.
# Only the controller's PUBLIC key crosses the host transfer directory.
set -euo pipefail
key_file=${1:?Controller public key file required}
key=$(cat "$key_file")
[[ "$key" == ssh-ed25519\ * ]] || { echo 'Expected an Ed25519 public key' >&2; exit 1; }
install -d -m 0700 "$HOME/.ssh"
touch "$HOME/.ssh/authorized_keys"
chmod 0600 "$HOME/.ssh/authorized_keys"
if ! grep -qxF "$key" "$HOME/.ssh/authorized_keys"; then
  printf '%s\n' "$key" >> "$HOME/.ssh/authorized_keys"
fi
restorecon -R "$HOME/.ssh"
echo '[Milestone 2] Controller public key enrolled on Linux agent'
