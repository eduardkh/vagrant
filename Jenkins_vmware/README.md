# Jenkins VMware lab

Milestone 1 creates two Rocky Linux 9 VMs. Windows is deferred until a VMware
Vagrant box is selected and downloaded. Milestone 2 bootstraps Python and
Ansible using the visible scripts below. Jenkins is not installed yet.

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

## Milestone 2: Python and Ansible bootstrap

Run from this directory in PowerShell:

```powershell
.\milestone-2.ps1
```

The host wrapper transfers the local `provision/` directory to `/vagrant` on
the controller, then runs the annotated `provision/milestone-2.sh`. The shell
script installs Python, pip Ansible, completion, and the controller SSH key;
`provision/ansible/site.yaml` installs matching Python on the Linux agent through
Ansible, then checks both machines. Windows remains deferred.

Python **3.14.10** is the newest Python available from these guests' enabled
Rocky repositories, checked on 2026-11-25. Both machines install matching
`python3.14` and `python3.14-pip` RPMs with dnf. Exact package versions and the
versioned executable are recorded in `provision/versions.env`.

`alternatives` manages `/usr/local/bin/python3` and `/usr/local/bin/python`,
selecting `/usr/bin/python3.14` as the default in login shells. The alternatives
group names are `python3` and `python`; inspect them with
`alternatives --display python3` or `alternatives --display python`.
Rocky 9 does not use alternatives for its RPM-owned `/usr/bin/python*` links,
so those paths remain intact. `/usr/bin/dnf` explicitly uses Python 3.9.
Rocky's sudo `secure_path` still selects `/usr/bin/python3` for `sudo python3`;
use `sudo /usr/local/bin/python3` when root commands need Python 3.14.10.
No Python source is downloaded or compiled, and no compiler packages are needed.

Ansible Core **2.22.0** and argcomplete **3.8.0** are installed with pip in
`/home/vagrant/.local/share/jenkins-lab/ansible`, using Python 3.14.10. User command
links are under `~/.local/bin`; shell PATH and completion are configured by the
script. Neither guest initially had an RPM Ansible package to uninstall. A
future conflicting RPM Ansible installation makes the script stop for review.
`provision/requirements.lock` pins the complete pip dependency set resolved and
tested on the controller, including Ansible's transitive dependencies.
Only builtin modules are needed at this milestone, so no collections are
installed yet. Windows collections will be pinned when Windows work begins.

The wrapper reads public keys through Vagrant's authenticated SSH connection.
It enrolls a dedicated controller public key on the agent and pins the agent's
Ed25519 host key. Strict SSH host checking stays enabled. The private key stays
in the controller's `~/.ssh`, outside the transferred directory. This POC uses
the box's existing `vagrant` account and passwordless sudo. A changed agent host
key stops enrollment until the new VM identity is verified.
After intentionally destroying and rebuilding the agent, use
`.\milestone-2.ps1 -ReenrollRebuiltAgent` to replace the old public-key pin with
the rebuilt VM's host key read through authenticated Vagrant SSH.

The local directory is **copied**, not live mounted. VMware shared folders fail
validation with the installed Vagrant 2.4.9 / VMware plugin 3.0.5 combination
(`usable?` argument mismatch). Vagrant file provisioning avoids changing global
plugins. Run the wrapper again after local edits; it refreshes the guest files
and reruns the bootstrap. Only `provision/` is transferred, never `.vagrant/`.
The ignored `provision/.runtime/` contains an enrolled host public key pin.

Inspect or rerun inside the controller:

```bash
vagrant ssh jenkins-controller
python3 --version
ansible --version
cd /vagrant/ansible
export ANSIBLE_CONFIG=/vagrant/ansible/ansible.cfg
ansible-inventory --graph
ansible all -m ansible.builtin.ping
ansible all --become -m ansible.builtin.command -a 'id -u'
bash /vagrant/milestone-2.sh --configure
```

The main script reads `versions.env` and passes the pinned RPMs, executable and
expected Python version to Ansible. The worker uses **native
`ansible.builtin.dnf` tasks** to install Python, command tasks to configure
alternatives, and a copy task to set login PATH. That bootstrap play explicitly
uses `/usr/bin/python3.9`, which has Rocky's dnf and SELinux bindings. The
validation play and subsequent automation use `/usr/local/bin/python3`.
No worker Python installer shell script is executed. No VM reload or reboot
is needed. Installing Python RPMs can update their OS library dependencies.

### Milestone 2 validation on rebuilt VMs, 2026-11-25

- The complete host wrapper passed using repository Python RPMs and pip Ansible.
- Both fresh login shells report `python` and `python3` as 3.14.10; RPM queries
  confirm matching Python and pip packages. `alternatives --display python3`
  selects `/usr/bin/python3.14` through `/etc/alternatives/python3`.
- The worker installed Python through `ansible.builtin.dnf`; no installer shell
  script or source build was used there. Both hosts have no `/opt/python` or
  `/usr/local/src/jenkins-lab` source-build directories.
- Ansible Core 2.22.0 runs on the controller with Python 3.14.10. Pip dependency
  checks passed. Both hosts return `pong`, execute sudo with UID 0, and run dnf.
- A repeat playbook run reported `changed=0`, `unreachable=0`, and `failed=0`
  on both hosts. SELinux remains enforcing and firewalld is active.
- Shell/PowerShell syntax checks, Vagrant validation, and `git diff --check`
  passed. Local runtime enrollment pins and generated VM keys remain ignored.

Upstream: [Rocky 9 family Python command behavior](https://docs.redhat.com/en/documentation/red_hat_enterprise_linux/9/html/considerations_in_adopting_rhel_9/assembly_dynamic-programming-languages-web-servers-database-servers_considerations-in-adopting-rhel-9),
[Ansible compatibility matrix](https://docs.ansible.com/projects/ansible-core/devel/reference_appendices/release_and_maintenance.html#ansible-core-support-matrix),
and [Ansible installation](https://docs.ansible.com/projects/ansible/latest/installation_guide/intro_installation.html).
