# Podman Compose setup for Prometheus / Grafana and test node_exporter

Overview

- This folder contains Podman-based compose files to start the monitoring stack on the Prometheus VM and the node_exporter on the test VM.

Files

- `prometheus/docker-compose.yml` -> Prometheus + Grafana
- `prometheus/prometheus.yml` -> Prometheus config (scrapes testbox)
- `testbox/docker-compose.yml` -> node_exporter service

Quick start (on each VM)

1. Ensure `container-tools` is installed and working.
   - Example: `sudo dnf module install -y container-tools`
2. Install `podman-compose` (if not present):
   - Try `sudo dnf install -y podman-compose` or `pip3 install --user podman-compose`

Prometheus VM (run as vagrant user)

- cd /vagrant/Prometheus_rocky8_vmware/prometheus
- Validate config:
  `podman run --rm -v $(pwd)/prometheus.yml:/etc/prometheus/prometheus.yml:Z quay.io/prometheus/prometheus:v2.44.0 promtool check config /etc/prometheus/prometheus.yml`
- Start services:
  `podman-compose up -d`

Test VM (run as vagrant user)

- cd /vagrant/Prometheus_rocky8_vmware/testbox
- Start service:
  `podman-compose up -d`

Verification

- Node exporter: `curl http://192.168.1.155:9100/metrics`
- Prometheus targets: `curl http://192.168.1.154:9090/api/v1/targets`
- Grafana UI: http://192.168.1.154:3000 (default `admin`/`admin`)

Notes

- The Prometheus config mounts use `:Z` to ensure SELinux relabeling works under Podman on RHEL-like systems.
- Edit `prometheus/prometheus.yml` if you want to change scrape targets; then restart Prometheus or use the lifecycle endpoint to reload (Prometheus is started with `--web.enable-lifecycle`).
- If you prefer automation, I can add provisioning tasks to the `Vagrantfile` so these compose files are started automatically during `vagrant up`.
