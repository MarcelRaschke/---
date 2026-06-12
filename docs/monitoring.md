# Monitoring

Optional Prometheus + Grafana stack for observability.

## Quick Start

```bash
make monitoring
# or: docker compose -f compose/docker-compose.yml -f compose/docker-compose.monitoring.yml up -d
```

## Access

- **Grafana**: http://localhost:3000 (default: admin/admin)
- **Prometheus**: http://localhost:9090

## Configuration

Prometheus scrape config is at [`monitoring/prometheus.yml`](../monitoring/prometheus.yml). It polls the OpenClaw gateway health endpoint every 15 seconds.

To add custom Grafana dashboards, mount them into the Grafana container or import them through the UI.
