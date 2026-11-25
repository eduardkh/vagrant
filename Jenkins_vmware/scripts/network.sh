#!/usr/bin/env bash
set -euo pipefail

wan_ip=$1
wan_prefix=$2
wan_gateway=$3
wan_dns=$4
controller_ip=$5
agent_ip=$6

# Exclude our existing bridged profile on repeat provisioning: its preferred
# default route must not cause the management and bridge NICs to swap roles.
bridge_dev=$(nmcli -g GENERAL.DEVICES connection show jenkins-bridge 2>/dev/null || true)
mgmt_dev=$(ip -4 route show default | awk -v bridge="$bridge_dev" '$5 != bridge { print $5; exit }')
[[ -n "$mgmt_dev" ]] || { echo "No NAT management interface found" >&2; exit 1; }
mapfile -t wan_devices < <(nmcli -t -f DEVICE,TYPE device status |
  awk -F: -v mgmt="$mgmt_dev" '$2 == "ethernet" && $1 != mgmt { print $1 }')
[[ ${#wan_devices[@]} -eq 1 ]] || { echo "Expected exactly one bridged ethernet interface" >&2; exit 1; }
wan_dev=${wan_devices[0]}
mgmt_uuid=$(nmcli -g GENERAL.CON-UUID device show "$mgmt_dev")
wan_uuid=$(nmcli -g GENERAL.CON-UUID device show "$wan_dev")
[[ -n "$mgmt_uuid" && "$mgmt_uuid" != -- ]] || { echo "Missing NAT connection" >&2; exit 1; }

if [[ -z "$wan_uuid" || "$wan_uuid" == -- ]]; then
  if nmcli connection show jenkins-bridge >/dev/null 2>&1; then
    wan_uuid=$(nmcli -g connection.uuid connection show jenkins-bridge)
  else
    nmcli connection add type ethernet con-name jenkins-bridge ifname "$wan_dev"
    wan_uuid=$(nmcli -g connection.uuid connection show jenkins-bridge)
  fi
fi

nmcli connection modify uuid "$wan_uuid" \
  connection.id jenkins-bridge connection.autoconnect yes \
  connection.interface-name "$wan_dev" \
  ipv4.method manual ipv4.addresses "$wan_ip/$wan_prefix" \
  ipv4.gateway "$wan_gateway" ipv4.dns "$wan_dns" \
  ipv4.ignore-auto-dns yes ipv4.never-default no ipv4.route-metric 10
nmcli connection modify uuid "$mgmt_uuid" \
  connection.autoconnect yes ipv4.route-metric 500
nmcli connection up uuid "$wan_uuid"
# Reapply the route metric without disconnecting the SSH management interface.
nmcli device reapply "$mgmt_dev"

# Replace only our own managed block, so provisioning never appends duplicates.
sed -i '/^# BEGIN jenkins-lab$/,/^# END jenkins-lab$/d' /etc/hosts
cat >> /etc/hosts <<EOF
# BEGIN jenkins-lab
$controller_ip jenkins-controller
$agent_ip jenkins-agent-linux
# END jenkins-lab
EOF

hostnamectl --static
ip -4 address show dev "$wan_dev"
ip -4 route show default
