# Loki + Promtail (Podman, Rocky Linux)

This document describes **how Loki was deployed on the server side** and **how Promtail was deployed on the client side** using Podman / Podman Compose on Rocky Linux (RHEL-like systems), including the exact troubleshooting steps required to make log ingestion work.

This README is intentionally **practical and reproducible**, based on a working setup.

---

## High-level architecture

```
[testbox VM]                         [prometheus VM]

/var/log/messages
        |
     promtail  ───────────────►  Loki (3100)
        |                              |
 node_exporter (9100)              Grafana (3000)
        |                              |
        └──────────────►  Prometheus (9090)
```

- **Loki** runs on the Prometheus VM
- **Promtail** runs on the testbox VM
- Logs are shipped via HTTP (`/loki/api/v1/push`)
- File-based logs only (`/var/log/messages`)

---

## Loki (server side)

### Location

Prometheus VM

### Purpose

- Store logs
- Index labels
- Serve queries to Grafana and direct API calls

### Loki configuration (`loki.yml`)

```yaml
auth_enabled: false

server:
  http_listen_port: 3100

common:
  path_prefix: /loki
  storage:
    filesystem:
      chunks_directory: /loki/chunks
      rules_directory: /loki/rules
  replication_factor: 1
  ring:
    kvstore:
      store: inmemory

schema_config:
  configs:
    - from: 2023-01-01
      store: boltdb-shipper
      object_store: filesystem
      schema: v11
      index:
        prefix: index_
        period: 24h
```

This is a **single-binary Loki** using local filesystem storage (perfect for labs and VMs).

### Verify Loki health

```bash
curl http://127.0.0.1:3100/ready
```

Expected:

```
ready
```

---

## Promtail (client side)

### Location

Testbox VM

### Purpose

- Read local log files
- Attach labels
- Push logs to Loki

### What we scrape

- **File-based logs**
- Primary file:
  - `/var/log/messages`

We explicitly **do NOT use journald** in this setup to avoid systemd/container ABI complexity.

---

## Promtail configuration (`promtail.yml`)

```yaml
server:
  http_listen_port: 9080
  grpc_listen_port: 0

positions:
  filename: /tmp/positions.yaml

clients:
  - url: http://192.168.1.154:3100/loki/api/v1/push

scrape_configs:
  - job_name: varlogs
    static_configs:
      - targets:
          - localhost
        labels:
          job: varlogs
          host: testbox
          __path__: /var/log/messages
```

---

## Promtail container (Podman Compose)

**Important: this must run as root** to read system logs.

```yaml
promtail:
  image: grafana/promtail:2.9.4
  user: root
  command: -config.file=/etc/promtail/promtail.yml
  volumes:
    - ./promtail.yml:/etc/promtail/promtail.yml:Z
    - /var/log/messages:/var/log/messages:ro,Z
  restart: unless-stopped
```

### Why `:Z` matters (SELinux)

On Rocky / RHEL systems:

- `/var/log/messages` is labeled `var_log_t`
- Containers **cannot read it without relabeling**

Without `:Z`:

- Promtail starts
- No errors
- **Zero logs ingested**

This was the root cause of most issues.

---

## Running Promtail

```bash
sudo podman-compose up -d
```

Check logs:

```bash
sudo podman logs testbox_promtail_1
```

You should see:

```
Adding target "/var/log/messages"
```

---

## Generating test logs

On the testbox VM:

```bash
sudo logger "LOKI FILE TEST A"
sudo logger "LOKI FILE TEST B"
sudo logger "LOKI FILE TEST C"
```

Verify locally:

```bash
sudo tail -n 10 /var/log/messages
```

---

## Verifying logs reached Loki

### Direct Loki API query (authoritative)

Run on the **Prometheus VM**:

```bash
curl -G "http://127.0.0.1:3100/loki/api/v1/query" \
  --data-urlencode 'query={job="varlogs"} |= "LOKI FILE TEST"' \
  --data-urlencode 'limit=20'
```

If this returns data, Loki ingestion is working.

---

## Grafana verification

1. Open Grafana
2. Go to **Explore**
3. Select **Loki** datasource
4. Query:

```logql
{job="varlogs"}
```

Optional filter:

```logql
{job="varlogs"} |= "LOKI FILE TEST"
```

Ensure time range is **Last 5–15 minutes**.

---

## Troubleshooting checklist

### Promtail side

```bash
sudo podman logs testbox_promtail_1
```

Inside container:

```bash
sudo podman exec -it testbox_promtail_1 sh
ls -lah /var/log/messages
tail -n 5 /var/log/messages
```

If this fails → SELinux relabeling is missing.

---

### Loki side

```bash
curl http://127.0.0.1:3100/ready
podman logs prometheus_loki_1 | tail -n 50
```

---

## Key lessons

- Root inside a container is **not enough** on RHEL
- SELinux silently blocks log ingestion
- File-based logs are the simplest Loki integration
- Always verify Loki via its HTTP API, not just Grafana

---

## Future improvements

- Scrape multiple files (`secure`, `cron`)
- Add per-file labels
- Persist Loki data to object storage
- Replace promtail with Grafana Agent
