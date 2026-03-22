# OpenClaw Deployment Scaffold

A ready-to-use starter kit for deploying [OpenClaw](https://openclaw.ai/), the open-source personal AI assistant that runs on your own devices.

## Prerequisites

- **Node.js** 24+ (or 22.16+) — for native installation
- **Docker & Docker Compose** — for containerized deployment (optional)
- **API Key** from a supported AI provider (Anthropic, OpenAI, Google Gemini, or use [Ollama](https://ollama.ai/) for local/offline operation)

## Quick Start

### Option A: Native (npm)

```bash
npm install -g openclaw@latest
openclaw onboard --install-daemon
```

### Option B: Docker

```bash
cp .env.example .env
# Edit .env and add your API key(s)
docker compose up -d
```

### Option C: Setup Script

```bash
chmod +x scripts/setup.sh
./scripts/setup.sh
```

The setup script checks prerequisites, creates configuration files, and guides you through either native or Docker installation.

## Configuration

### Environment Variables

Copy the example environment file and fill in your API keys:

```bash
cp .env.example .env
```

See [`.env.example`](.env.example) for all available variables and their descriptions.

### OpenClaw Config

An example configuration file is provided at [`config/openclaw.config.example.json5`](config/openclaw.config.example.json5). To use it:

```bash
cp config/openclaw.config.example.json5 config/openclaw.config.json5
# Edit the file to match your setup
```

## Available Integrations

OpenClaw supports communication through channels you already use:

| Channel | Status |
|---------|--------|
| WhatsApp | Supported (via Baileys) |
| Telegram | Supported (via grammY) |
| Slack | Supported (via Bolt) |
| Discord | Supported (via discord.js) |
| Signal | Supported (via signal-cli) |
| Google Chat | Supported |
| iMessage | Supported (macOS) |
| Microsoft Teams | Supported |
| Matrix | Supported |
| IRC | Supported |

## Makefile Commands

If you have `make` installed, use these shortcuts:

```bash
make setup      # Create .env and workspace directory
make start      # Start via Docker Compose
make stop       # Stop containers
make restart    # Restart containers
make logs       # Tail logs
make status     # Show container status
make health     # Check gateway health endpoint
make update     # Pull latest image and restart
make clean      # Remove containers and workspace (destructive)
```

## Production Deployment

For production use with TLS, use the production overlay:

```bash
# Place your TLS certificates
mkdir -p nginx/certs
cp /path/to/fullchain.pem nginx/certs/
cp /path/to/privkey.pem nginx/certs/

# Start with production config
docker compose -f docker-compose.yml -f docker-compose.prod.yml up -d
```

This adds an nginx reverse proxy with HTTPS, restricts OpenClaw to localhost binding, and configures log rotation. See [`nginx/nginx.conf`](nginx/nginx.conf) for the proxy configuration.

## Maintenance

### Update

```bash
./scripts/update.sh       # Auto-detects Docker or native install
# or
make update               # Docker only
```

### Backup

```bash
./scripts/backup.sh                  # Backs up to ./backups/
./scripts/backup.sh /path/to/dest    # Custom backup location
```

Keeps the last 10 backups automatically.

## Useful Commands

```bash
# Check system health and fix common issues
openclaw doctor --fix

# View status of all services
openclaw status --all

# Start the gateway manually
openclaw gateway --port 18789 --verbose

# Run an agent task
openclaw agent --message "Your task here" --thinking high

# Send a message through a connected channel
openclaw message send --to "+1234567890" --message "Hello from OpenClaw"
```

## Monitoring

Optional Prometheus + Grafana stack for observability:

```bash
docker compose -f docker-compose.yml -f docker-compose.monitoring.yml up -d
```

- **Grafana**: http://localhost:3000 (admin/admin)
- **Prometheus**: http://localhost:9090

## Diagnostics

Run the built-in doctor script to check your setup:

```bash
./scripts/doctor.sh
```

Checks: `.env` configuration, API keys, Docker/Node.js availability, port status, gateway health, and security posture.

## Alternative: Caddy (Auto-TLS)

Instead of nginx, use [Caddy](https://caddyserver.com/) for automatic HTTPS:

```bash
# Edit Caddyfile — replace your-domain.example.com with your domain
caddy run --config Caddyfile
```

Caddy automatically obtains and renews Let's Encrypt certificates.

## Systemd Service (Linux)

For native installs on Linux, a systemd unit file is included:

```bash
sudo cp systemd/openclaw.service /etc/systemd/system/
sudo useradd -r -m -s /bin/bash openclaw  # if user doesn't exist
sudo systemctl daemon-reload
sudo systemctl enable --now openclaw
journalctl -u openclaw -f  # view logs
```

## CI/CD

GitHub Actions workflows are included in `.github/workflows/`:

- **`validate.yml`** — validates Docker Compose files, nginx config, shell scripts, and checks `.env.example` for leaked secrets on push/PR
- **`healthcheck.yml`** — scheduled health check (every 6 hours) that spins up OpenClaw in Docker and verifies endpoints

## Troubleshooting

| Problem | Solution |
|---------|----------|
| Gateway won't start | Run `./scripts/doctor.sh` to diagnose |
| Port 18789 already in use | Change `OPENCLAW_GATEWAY_PORT` in `.env` |
| Docker permission denied | Add your user to the docker group: `sudo usermod -aG docker $USER` |
| Container keeps restarting | Check logs: `make logs` or `docker compose logs` |
| Health check fails | Verify API key is set and valid in `.env` |
| WebSocket disconnects | Ensure `proxy_read_timeout` is high in nginx config |
| Bind mount permission errors | The Docker image runs as uid 1000. Fix with: `chown -R 1000:1000 workspace/` |
| Can't reach gateway from LAN | Set `OPENCLAW_GATEWAY_BIND=lan` in `.env` |
| `alpine/openclaw:latest` broken | Try `alpine/openclaw:main` as a fallback |

## Security Notes

- **Never commit `.env`** — it contains your API keys. The `.gitignore` already excludes it.
- **Bind gateway to localhost** in production. Use a reverse proxy (nginx, Caddy) with TLS for remote access.
- Use `SecretRef` for API keys in shared/team environments.
- Review the [official security docs](https://docs.openclaw.ai/security) for production hardening.

## Resources

- [Official Website](https://openclaw.ai/)
- [Documentation](https://docs.openclaw.ai)
- [GitHub Repository](https://github.com/openclaw/openclaw)
- [Getting Started Guide](https://docs.openclaw.ai/start/getting-started)

## License

[MIT](LICENSE)
