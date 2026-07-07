# OpenClaw AI Gateway (Cloudflare Worker)

An OpenAI-compatible API gateway backed by [Cloudflare Workers AI](https://developers.cloudflare.com/workers-ai/). It lets OpenClaw use **Mistral** and **Gemma** models through one stable endpoint — without putting your Cloudflare account ID or API token in OpenClaw's config. The Worker's `AI` binding handles Cloudflare auth; OpenClaw authenticates to the Worker with a bearer token you control.

```
OpenClaw ──(bearer token)──▶ Worker ──(AI binding)──▶ Workers AI (Mistral / Gemma)
```

## Models

| Alias (use in OpenClaw) | Cloudflare Workers AI model |
|-------------------------|-----------------------------|
| `mistral-small` | `@cf/mistralai/mistral-small-3.1-24b-instruct` |
| `gemma-3-12b` | `@cf/google/gemma-3-12b-it` |

Add or change aliases in [`src/index.js`](src/index.js) (`MODEL_ALIASES`). You can also pass a raw `@cf/...` ID directly.

## Endpoints

- `POST /v1/chat/completions` — OpenAI-compatible chat completions (streaming and non-streaming)
- `GET /v1/models` — list exposed aliases
- `GET /healthz` — unauthenticated health check

## Deploy

Prerequisites: a Cloudflare account and [Wrangler](https://developers.cloudflare.com/workers/wrangler/install-and-update/).

```bash
cd cf-worker
npm install

# Set the bearer token OpenClaw will use (store as a secret, never commit it)
npx wrangler secret put GATEWAY_TOKEN

# Deploy
npx wrangler deploy
```

Wrangler prints your Worker URL, e.g. `https://openclaw-ai-gateway.<your-subdomain>.workers.dev`.

## Local development

```bash
cp .dev.vars.example .dev.vars   # then edit GATEWAY_TOKEN
npm run dev                       # http://localhost:8787
```

Test it:

```bash
curl http://localhost:8787/v1/chat/completions \
  -H "Authorization: Bearer $GATEWAY_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "mistral-small",
    "messages": [{"role": "user", "content": "Say hello in one sentence."}]
  }'
```

## Point OpenClaw at the Worker

In `.env`:

```bash
CF_WORKER_URL=https://openclaw-ai-gateway.<your-subdomain>.workers.dev/v1
CF_WORKER_TOKEN=the-token-you-set-with-wrangler-secret
```

In `config/openclaw.config.json5`, use the OpenAI-compatible provider with `baseUrl` set to the Worker (see the repo's [`config/openclaw.config.example.json5`](../config/openclaw.config.example.json5)). Then select `mistral-small` or `gemma-3-12b` as your model.

## Notes

- **Pricing**: Workers AI is billed per-token / per-request by Cloudflare. See their [pricing](https://developers.cloudflare.com/workers-ai/platform/pricing/).
- **Auth**: If `GATEWAY_TOKEN` is unset, the Worker runs open — only acceptable for local dev. Always set it in production.
- **Streaming**: `"stream": true` is supported; the Worker converts Workers AI's SSE format into OpenAI `chat.completion.chunk` events.
