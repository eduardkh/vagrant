ip route delete default
echo "ip route delete default"
sudo ip route add 0.0.0.0/0 via 10.200.15.254
echo "ip route add 0.0.0.0/0 via 10.200.15.255"