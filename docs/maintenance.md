# Maintenance

## Update

```bash
./scripts/update.sh       # Auto-detects Docker or native install
# or
make update               # Docker only
```

## Backup

```bash
./scripts/backup.sh                  # Backs up to ./backups/
./scripts/backup.sh /path/to/dest    # Custom backup location
make backup                          # Backs up to ./backups/
```

Backs up workspace data, config files, and `.env`. Keeps the last 10 backups automatically.

## Useful Commands

```bash
openclaw doctor --fix                                    # Check system health and fix common issues
openclaw status --all                                    # View status of all services
openclaw gateway --port 18789 --verbose                  # Start the gateway manually
openclaw agent --message "Your task here" --thinking high # Run an agent task
openclaw message send --to "+1234567890" --message "Hi"  # Send a message
```
