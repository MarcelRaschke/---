# Troubleshooting

## Diagnostics

Run the built-in doctor script:

```bash
make doctor
# or: ./scripts/doctor.sh
```

Checks `.env` configuration, API keys, Docker/Node.js availability, port status, gateway health, and security posture.

## Common Issues

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
