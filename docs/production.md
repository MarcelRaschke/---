# Production Deployment

## nginx + TLS

Use the production Docker Compose overlay with nginx reverse proxy:

```bash
# Place your TLS certificates
mkdir -p nginx/certs
cp /path/to/fullchain.pem nginx/certs/
cp /path/to/privkey.pem nginx/certs/

# Start with production config
make prod
# or: docker compose -f compose/docker-compose.yml -f compose/docker-compose.prod.yml up -d
```

This adds an nginx reverse proxy with HTTPS, restricts OpenClaw to localhost binding, and configures log rotation. See [`nginx/nginx.conf`](../nginx/nginx.conf) for the proxy configuration.

## Caddy (Auto-TLS)

Instead of nginx, use [Caddy](https://caddyserver.com/) for automatic HTTPS via Let's Encrypt:

```bash
# Edit Caddyfile — replace your-domain.example.com with your domain
caddy run --config Caddyfile
```

Caddy automatically obtains and renews certificates — no manual cert management needed.

## systemd Service (Linux)

For native installs on Linux, a systemd unit file is included:

```bash
sudo cp systemd/openclaw.service /etc/systemd/system/
sudo useradd -r -m -s /bin/bash openclaw  # if user doesn't exist
sudo systemctl daemon-reload
sudo systemctl enable --now openclaw
journalctl -u openclaw -f  # view logs
```

The unit file includes security hardening: `NoNewPrivileges`, `ProtectSystem=strict`, `PrivateTmp`.
