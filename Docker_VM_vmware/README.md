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

## Using GNS3 with VMWare

Follow these steps to set up GNS3 on VMWare:

1. **Set GNS3 VM to a Bridged Network**: Open the VMWare settings for the GNS3 virtual machine. Go to the network adapter settings and change the network connection type to "Bridged". This allows your GNS3 VM to operate as a separate device on your network, rather than being behind the host's network interface (NAT).

2. **Connect the Cisco Router to the Cloud Component**: Launch GNS3 and drag a Cisco router onto your workspace. Also, drag the Cloud component (representing the GNS3 VM) onto the workspace. Use the 'Add a Link' button or the Ctrl+L shortcut to connect one of the Cisco router interfaces (e.g., FastEthernet0/0) to the Cloud component (eth0).

3. **Configure the Cisco Router's IP Address**: Open the console for the Cisco router. Enter the configuration mode by typing `configure terminal` (or `conf t` for short). Set the IP address for the router interface by typing the commands `interface FastEthernet0/0`, `ip address [your_IP_address] [subnet_mask]`, and `no shutdown`. Replace `[your_IP_address]` and `[subnet_mask]` with your chosen IP address and subnet mask.

4. **Test the Connection**: From the host machine, try pinging the IP address you assigned to the Cisco router interface. If the setup is correct, you should see the pings being successful, indicating that the host machine can successfully communicate with the Cisco router through the GNS3 VM.

> **Note**: Remember to replace placeholders like `[your_IP_address]` and `[subnet_mask]` with the actual values based on your network configuration.
