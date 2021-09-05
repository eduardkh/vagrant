ip route delete default
echo "ip route delete default"
ip route add 0.0.0.0/0 via 192.168.1.254
echo "ip route add 0.0.0.0/0 via 192.168.1.254"