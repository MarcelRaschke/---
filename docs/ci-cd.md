# CI/CD

GitHub Actions workflows are included in `.github/workflows/`.

## Workflows

### `validate.yml`

Runs on push/PR when compose, nginx, config, or script files change. Checks:

- Docker Compose file validity (base + prod overlay)
- nginx config syntax
- Shell script linting via ShellCheck
- `.env.example` scanned for accidentally committed secrets

### `healthcheck.yml`

Scheduled every 6 hours (and manual trigger). Spins up OpenClaw in Docker, verifies the `/healthz` and `/readyz` endpoints, then tears down.
