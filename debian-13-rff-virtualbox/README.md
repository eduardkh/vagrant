# Debian 13 FRR lab

Three VirtualBox routers share the host-only network `192.168.56.0/24`:

| Machine | Private address |
| --- | --- |
| router1 | 192.168.56.11 |
| router2 | 192.168.56.12 |
| router3 | 192.168.56.13 |

Each keeps its default NAT adapter for downloads and Vagrant SSH. Requires
Vagrant, VirtualBox and 12 GiB of RAM available for the guests.

Run from this directory:

```powershell
vagrant up --provider=virtualbox
vagrant ssh router1
```

Provisioning builds pinned FRR 10.7.1 source into Debian packages with the
`pkg.frr.grpc` profile, which passes `--enable-grpc`. It installs `frr`,
`frr-pythontools` and `frr-grpc`, preserving existing configuration files.
Each guest has 4 GiB RAM and two CPUs for compilation. The first build takes
considerably longer than a binary installation; successful builds are cached
under `/opt/frr-build/10.7.1` in each guest. Remove the `complete` marker there
to rebuild. Build dependencies and source are retained for inspection.

Provisioning persists IPv4/IPv6 forwarding, enables zebra, bgpd, ospfd and
staticd, and checks service health, daemon processes, forwarding and actual
gRPC GetCapabilities calls.

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

## gRPC access

FRR's experimental northbound API uses `frr.Northbound`, not gNMI. Each
daemon has its own localhost endpoint and exposes only its supported YANG
models; enabling gRPC does not make every CLI command available as an RPC.
Check `supported_modules` in the capabilities output before configuring a
protocol. YANG notifications are not supported.

| Daemon | Guest localhost port |
| --- | --- |
| zebra | 50051 |
| bgpd | 50052 |
| ospfd | 50053 |
| staticd | 50054 |

Run the supplied read-only client inside a guest:

```powershell
vagrant ssh router1 -c "python3 /vagrant/check-grpc.py"
```

The matching protobuf schema and generated Python bindings are installed in
`/usr/local/share/frr-grpc`. To access zebra from a host client, keep this SSH
tunnel open (use another local port for simultaneous tunnels to other routers):

```powershell
vagrant ssh router1 -- -N -L 50051:127.0.0.1:50051
```

Connect to `127.0.0.1:50051` with plaintext gRPC through the tunnel. For example,
inside the guest, with grpcurl installed, supply the schema explicitly:

```bash
grpcurl -plaintext -import-path /usr/local/share/frr-grpc \
  -proto frr-northbound.proto -d '{}' 127.0.0.1:50051 frr.Northbound/GetCapabilities
```

References: [FRR gRPC runtime configuration](https://docs.frrouting.org/en/latest/grpc.html)
and [Debian build profiles](https://docs.frrouting.org/projects/dev-guide/en/latest/packaging-debian.html).

```powershell
# frr-northbound.proto location
https://github.com/FRRouting/frr/tree/master/grpc

# in windows (for postman or grpcurl)
vagrant ssh router1 -- -N -L 50051:127.0.0.1:50051 # with vagrant
ssh -L 50051:127.0.0.1:50051 vagrant@192.168.56.11 # or with ssh

# test with grpcurl
go install github.com/fullstorydev/grpcurl/cmd/grpcurl@latest

grpcurl \
	-plaintext \
	-emit-defaults \
	-proto '/C:/Users/ekhiaev/Desktop/frr/frr/grpc/frr-northbound.proto' \
	-import-path '/C:/Users/ekhiaev/Desktop/frr/frr/grpc' \
	'localhost:50051' \
	frr.Northbound.GetCapabilities

```
