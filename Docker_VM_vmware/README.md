# Docker_VM_vmware

```bash
# Docker_VM
## DRIVER = virtualbox
## IMAGE = "generic/ubuntu2204"
## VERSION = "4.1.8"
## MEM = 4GB
```

> Install Vagrant VMware Utility

```bash
https://developer.hashicorp.com/vagrant/downloads/vmware
```

> Install Vagrant VMware Plugin

```bash
set VAGRANT_DISABLE_SSL_VERIFY=true
vagrant plugin install vagrant-vmware-desktop
# or
vagrant plugin install --plugin-clean-sources --plugin-source https://rubygems.org vagrant-vmware-desktop
vagrant plugin list
```

> Use VMware Provider

```bash
vagrant up --provider=vmware_desktop
```
