# OpenClaw Deployment Scaffold

A ready-to-use starter kit for deploying [OpenClaw](https://openclaw.ai/), the open-source personal AI assistant that runs on your own devices.

## Prerequisites

- **Node.js** 24+ (or 22.16+) — for native installation
- **Docker & Docker Compose** 2.20+ — for containerized deployment (optional)
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
./scripts/setup.sh
```

The setup script checks prerequisites, creates configuration files, and guides you through either native or Docker installation.

## Configuration

Copy the example files and fill in your values:

```bash
cp .env.example .env
cp config/openclaw.config.example.json5 config/openclaw.config.json5
```

See [`.env.example`](.env.example) for all environment variables. The example
config is wired for **Mistral** and **Gemma** models — see
[docs/providers.md](docs/providers.md) for the three ways to connect them
(Cloudflare Worker gateway, direct provider APIs, or local Ollama).

## Integrations

| Channel | Library |
|---------|---------|
| WhatsApp | Baileys |
| Telegram | grammY |
| Slack | Bolt |
| Discord | discord.js |
| Signal | signal-cli |
| Google Chat, iMessage, Teams, Matrix, IRC | Built-in |

## Makefile

```bash
make setup        # Create .env and workspace directory
make start        # Start via Docker Compose
make stop         # Stop containers
make restart      # Restart containers
make logs         # Tail logs
make status       # Show container status
make health       # Check gateway health endpoint
make update       # Pull latest image and restart
make prod         # Start with production overlay (nginx + TLS)
make monitoring   # Start with monitoring overlay (Prometheus + Grafana)
make doctor       # Run diagnostics
make backup       # Backup workspace and config
make clean        # Remove containers and workspace (destructive)
```

## Security

- **Never commit `.env`** — it contains API keys. The `.gitignore` already excludes it.
- **Bind gateway to localhost** in production. Use a reverse proxy with TLS for remote access.
- Use `SecretRef` for API keys in shared/team environments.

## Documentation

- [AI Providers](docs/providers.md) — Mistral & Gemma via Cloudflare Worker, direct API, or Ollama
- [Cloudflare Worker Gateway](cf-worker/README.md) — OpenAI-compatible Workers AI proxy
- [Production Deployment](docs/production.md) — nginx, Caddy, systemd
- [Monitoring](docs/monitoring.md) — Prometheus + Grafana
- [CI/CD](docs/ci-cd.md) — GitHub Actions workflows
- [Maintenance](docs/maintenance.md) — update, backup, useful commands
- [Troubleshooting](docs/troubleshooting.md) — common issues and fixes

## Resources

- [Official Website](https://openclaw.ai/)
- [Documentation](https://docs.openclaw.ai)
- [GitHub Repository](https://github.com/openclaw/openclaw)
- [Getting Started Guide](https://docs.openclaw.ai/start/getting-started)

## License

[MIT](LICENSE)
