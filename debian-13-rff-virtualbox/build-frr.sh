#!/bin/bash
set -euo pipefail
export DEBIAN_FRONTEND=noninteractive
export DEB_BUILD_PROFILES=pkg.frr.grpc
export DEB_BUILD_OPTIONS=parallel=2
version=10.7.1
commit=f8c0b08dcb0c78f9e42b9b86ae70b049e4e617c1
build=/opt/frr-build/$version

# Retire the binary repository configured by earlier provisioning.
rm -f /etc/apt/sources.list.d/frr.list
apt-get update
apt-get install -y build-essential git autoconf automake libtool devscripts \
  equivs fakeroot ca-certificates python3-grpcio python3-grpc-tools \
  traceroute iproute2 tcpdump jq ethtool
install -d -o vagrant -g vagrant "$build"
if [ ! -d "$build/frr/.git" ]; then
  runuser -u vagrant -- git clone --depth 1 --branch "frr-$version" \
    https://github.com/FRRouting/frr.git "$build/frr"
fi
cd "$build/frr"
test "$(git -c safe.directory="$build/frr" rev-parse HEAD)" = "$commit"
if [ ! -f "$build/complete" ]; then
  mk-build-deps --install --remove --build-profiles "$DEB_BUILD_PROFILES" \
    --tool 'apt-get -y --no-install-recommends' debian/control
  runuser -u vagrant -- ./bootstrap.sh
  runuser -u vagrant -- dpkg-buildpackage -b -uc -us -Ppkg.frr.grpc
  touch "$build/complete"
fi
apt-get install -y -o Dpkg::Options::=--force-confold \
  "$build"/frr_*.deb "$build"/frr-pythontools_*.deb "$build"/frr-grpc_*.deb
install -d /usr/local/share/frr-grpc
install -m 644 grpc/frr-northbound.proto /usr/local/share/frr-grpc/
python3 -m grpc_tools.protoc -I grpc --python_out=/usr/local/share/frr-grpc \
  --grpc_python_out=/usr/local/share/frr-grpc grpc/frr-northbound.proto
