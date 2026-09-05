# Debian 13 FRR lab

Three VirtualBox routers share the host-only network `192.168.56.0/24`:

| Machine | Private address |
| --- | --- |
| router1 | 192.168.56.11 |
| router2 | 192.168.56.12 |
| router3 | 192.168.56.13 |

Each keeps its default NAT adapter for downloads and Vagrant SSH. Requires
Vagrant, VirtualBox and 3 GiB of RAM available for the guests.

Run from this directory:

```powershell
vagrant up --provider=virtualbox
vagrant ssh router1
```

Provisioning installs FRR and frr-pythontools from the official frr-10.7
repository and all requested diagnostic tools. It persists IPv4/IPv6 forwarding,
enables zebra, bgpd, ospfd and staticd, and enables FRR at boot. It checks service
health, daemon processes and forwarding settings on each guest.

The shared IPv4 subnet provides direct connectivity. BGP peers, OSPF areas,
static routes and IPv6 addresses are not preconfigured. Configure routing using
`sudo vtysh` and save with `write memory`. Reprovisioning preserves routing
configuration and other daemon settings.

Verify all pairs and FRR:

```powershell
vagrant status
vagrant ssh router1 -c "ping -c 3 192.168.56.12 && ping -c 3 192.168.56.13"
vagrant ssh router2 -c "ping -c 3 192.168.56.11 && ping -c 3 192.168.56.13"
vagrant ssh router3 -c "ping -c 3 192.168.56.11 && ping -c 3 192.168.56.12"
vagrant ssh router1 -c "sudo vtysh -c 'show version'"
vagrant ssh router2 -c "sudo vtysh -c 'show version'"
vagrant ssh router3 -c "sudo vtysh -c 'show version'"
```

Rerun setup using `vagrant provision`. After network changes, use
`vagrant reload --provision`. If this subnet conflicts with an existing network,
change all three addresses together in the Vagrantfile.

```bash
sudo vtysh

debian# show version
debian# show ip route
debian# show interface
debian# configure terminal
debian(config)# router bgp 65001
```
