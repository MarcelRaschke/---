.PHONY: help setup start stop restart logs status health update clean

help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2}'

setup: ## Run initial setup (creates .env, workspace dir)
	@test -f .env || cp .env.example .env && echo "Created .env — edit it with your API keys"
	@mkdir -p workspace
	@echo "Setup complete. Run 'make start' to launch."

start: ## Start OpenClaw via Docker Compose
	docker compose up -d
	@echo "Waiting for health check..."
	@sleep 5
	@docker compose ps

stop: ## Stop OpenClaw
	docker compose down

restart: ## Restart OpenClaw
	docker compose restart

logs: ## Tail OpenClaw logs
	docker compose logs -f --tail=100

status: ## Show container status
	docker compose ps

health: ## Check gateway health endpoint
	@curl -fsS http://127.0.0.1:$${OPENCLAW_GATEWAY_PORT:-18789}/healthz && echo " OK" || echo " UNHEALTHY"

update: ## Pull latest image and restart
	docker compose pull
	docker compose up -d
	@echo "Updated to latest image."

clean: ## Remove workspace data and containers (DESTRUCTIVE)
	@echo "This will remove all containers and workspace data."
	@read -p "Are you sure? [y/N] " confirm && [ "$$confirm" = y ] || exit 1
	docker compose down -v
	rm -rf workspace
