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

## Security

### Skill Scanning

Community skills from [ClawHub](https://clawhub.ai/) should be treated as untrusted code. This scaffold includes two layers of defense:

**ClawShield** — CLI scanner that detects malicious patterns, data exfiltration, and prompt injection:

```bash
# Scan all installed skills
./scripts/scan-skills.sh

# Or scan directly
clawshield scan ./skills --threshold high
```

**Skill Defender** — a ClawHub skill that scans from within OpenClaw itself. Installed automatically by the setup script, or manually:

```bash
clawhub install itsclawdbro/skill-defender
```

### Sandbox Mode

Sandbox mode (`"mode": "docker"` in config) isolates skill execution in Docker containers, limiting file system and network access. Enabled by default in the example config.

### General Notes

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
