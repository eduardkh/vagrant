# Jenkins VMware lab

Milestone 1 creates two Rocky Linux 9 VMs. Windows is deferred until a VMware
Vagrant box is selected and downloaded. Ansible installation and repository
transfer are deferred to milestone 2; Jenkins is not installed yet.

| Machine | vCPU | RAM (MiB) | Bridged address |
| --- | ---: | ---: | --- |
| jenkins-controller | 4 | 8192 | 192.168.1.70/24 |
| jenkins-agent-linux | 2 | 4096 | 192.168.1.71/24 |

Uses installed `bento/rockylinux-9` version `202510.26.0` for `vmware_desktop`.
Host inspection found Vagrant 2.4.9, vagrant-vmware-desktop 3.0.5, VMware
Workstation 17.6.3, and a running Vagrant VMware Utility service.

The bridge defaults to `Intel(R) Ethernet Controller (3) I225-V` (host alias
`Ethernet`). Gateway and DNS default to `192.168.1.254`. The bridged route has
metric 10; Vagrant's NAT management NIC retains its DHCP address and a route
at metric 500. Route metrics prefer the bridge and allow NAT when that route
is removed; they do not detect an upstream gateway outage. SELinux and firewall
settings are left as supplied by the box.

Ensure `.70` and `.71` are available and excluded from DHCP allocation before
using these defaults. Configure VMware VMnet0 to bridge to the active Ethernet
adapter if automatic bridging selects the wrong physical interface.

From this directory in PowerShell:

```powershell
vagrant validate
vagrant up --provider=vmware_desktop
vagrant status
vagrant ssh jenkins-controller
```

Settings can be overridden with environment variables before running Vagrant:

```powershell
$env:JENKINS_BRIDGE = 'Intel(R) Ethernet Controller (3) I225-V'
$env:JENKINS_CONTROLLER_IP = '192.168.1.70'
$env:JENKINS_LINUX_IP = '192.168.1.71'
$env:JENKINS_PREFIX = '24'
$env:JENKINS_GATEWAY = '192.168.1.254'
$env:JENKINS_DNS = '192.168.1.254'
$env:JENKINS_CONTROLLER_MEMORY = '8192'
$env:JENKINS_CONTROLLER_CPUS = '4'
$env:JENKINS_LINUX_MEMORY = '4096'
$env:JENKINS_LINUX_CPUS = '2'
```

Keep the same overrides for subsequent commands. DNS accepts space-separated
IPv4 addresses. Network changes to existing VMs require `vagrant provision`;
resource or physical bridge changes require `vagrant reload --provision`.
The network provisioner is safe to repeat and maintains a single managed
`/etc/hosts` block for the two Linux machines.

Validate both guests with:

```powershell
vagrant ssh jenkins-controller -c 'cat /etc/rocky-release; hostname; ip -4 address; ip -4 route; getent hosts jenkins-agent-linux; ping -c 3 jenkins-agent-linux; curl --fail --head --max-time 20 https://download.rockylinux.org'
vagrant ssh jenkins-agent-linux -c 'cat /etc/rocky-release; hostname; ip -4 address; ip -4 route; getent hosts jenkins-controller; ping -c 3 jenkins-controller; curl --fail --head --max-time 20 https://download.rockylinux.org'
```

Run `vagrant provision` again and repeat validation to check repeatability.
VM state and generated SSH keys under `.vagrant/` are ignored by the parent
repository. Do not destroy the lab without explicit approval.

## Validation recorded on 2026-11-25

- `ruby -c Vagrantfile` and `vagrant validate` passed.
- `vagrant up --provider=vmware_desktop` created and started both guests.
- Both report Rocky Linux 9.6 and the expected hostnames and bridged addresses.
- Both have bridged default routes at metric 10 and NAT routes at metric 500.
- `vagrant provision` passed on both existing guests; each retained one managed
  hosts block, the same bridged address, and working NAT SSH access.
- Each guest resolved and pinged the other by hostname with no packet loss.
- Each guest fetched `https://download.rockylinux.org` with HTTP 200 and normal
  TLS verification; SELinux reports `Enforcing` and firewalld is active.
- DHCP exclusions for the chosen static IPs have not been verified. No reboot
  persistence or automatic outage failover test was performed.

Networking and provider configuration follow the [Vagrant public network
documentation](https://developer.hashicorp.com/vagrant/docs/networking/public_network)
and [VMware provider configuration](https://developer.hashicorp.com/vagrant/docs/providers/vmware/configuration).
