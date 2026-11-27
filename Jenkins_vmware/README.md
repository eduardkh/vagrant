# Jenkins VMware lab

Run host commands from `Jenkins_vmware` in PowerShell. Windows is deferred.

| VM | CPU | RAM | IP |
| --- | ---: | ---: | --- |
| jenkins-controller | 4 | 8 GiB | 192.168.1.70 |
| jenkins-agent-linux | 2 | 4 GiB | 192.168.1.71 |

## Milestone 1 — VMware infrastructure

1. Selected `bento/rockylinux-9` version `202510.26.0` with `vmware_desktop`.
2. Created both VMs: `vagrant validate`, then `vagrant up --provider=vmware_desktop`.
3. Configured bridged IPs, gateway/DNS `192.168.1.254`, and NAT management access.
4. Verified hostnames, IPs, VM-to-VM traffic, internet access, and repeat provisioning.

**Result:** both VMs running; SELinux enforcing and firewalld active. DHCP exclusions remain unverified.

## Milestone 2 — Python and Ansible

1. Ran `.\milestone-2.ps1`; copied local `provision/` files into controller `/vagrant`.
2. Installed controller Python **3.14.10** with dnf; selected shell defaults with `alternatives`.
3. Installed **Ansible Core 2.22.0** with pip in a virtual environment; enabled completion.
4. Enrolled the controller SSH public key on the worker and pinned its host key.
5. Used **Ansible dnf tasks** to install matching worker Python and configure alternatives.
6. Verified Python parity, Ansible `ping`, sudo, and dnf; repeat playbook reported **zero changes**.

**Result:** milestone 2 passed on rebuilt VMs, 2026-11-25.

## Milestone 3 — Jenkins controller

1. Ran `.\milestone-3.ps1`; refreshed controller files and invoked Ansible.
2. Installed pinned **OpenJDK 25.0.5.1** and **Jenkins LTS 2.580.3** RPMs; verified the Jenkins signing key.
3. Added dnf version locks, service settings, and Jenkins directory permissions.
4. Enabled Jenkins at boot; allowed port **8080** from **192.168.1.0/24**.
5. Set controller executors to **0**; verified HTTP access and repeatability.

**Result (2026-11-27):** [Jenkins unlock screen](http://192.168.1.70:8080) reachable; both RPM locks verified; repeat run: **zero changes/failures**. Plugins and JCasC follow in milestones 4–5.
Packages currently use upstream repositories; internal mirroring is deferred.

## Where Ansible ran

On **jenkins-controller**, as **vagrant**, from **/vagrant/ansible**; controller uses a local connection, worker uses SSH.
Host wrappers invoke `milestone-2.sh --configure` or `milestone-3.sh`. After `vagrant ssh jenkins-controller`:

```bash
cd /vagrant/ansible
export ANSIBLE_CONFIG=/vagrant/ansible/ansible.cfg
ansible-playbook site.yaml                 # Milestone 2
ansible-playbook jenkins-controller.yaml   # Milestone 3
ansible all -m ansible.builtin.ping
ansible all --become -m ansible.builtin.command -a 'id -u'
```

## Rerun / inspect

- Refresh files and rerun: `.\milestone-2.ps1`.
- Refresh files and rerun Jenkins installation: `.\milestone-3.ps1`.
- After an intentional agent rebuild: `.\milestone-2.ps1 -ReenrollRebuiltAgent`.
- Enter controller: `vagrant ssh jenkins-controller`.
- Inside controller: `python3 --version`, `ansible --version`, or `bash /vagrant/milestone-2.sh --configure`.
- Pins (loaded automatically): [group_vars/all.json](provision/ansible/group_vars/all.json), [requirements.lock](provision/requirements.lock).
- Jenkins/Java pins and repository settings: [group_vars/controller.json](provision/ansible/group_vars/controller.json).
- Workflow: [shell script](provision/milestone-2.sh), [worker playbook](provision/ansible/site.yaml).

Python defaults use alternatives under `/usr/local/bin`; Rocky's Python 3.9 remains for OS tools.
For root commands needing the new Python, use `sudo /usr/local/bin/python3`.
