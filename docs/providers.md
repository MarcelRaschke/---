# AI Providers: Mistral & Gemma

OpenClaw follows a Bring-Your-Own-Model design. This scaffold ships ready to use **Mistral** and **Gemma** models three ways — pick one.

## Option A — Cloudflare Worker gateway (recommended)

A bundled Cloudflare Worker ([`cf-worker/`](../cf-worker/)) exposes an OpenAI-compatible endpoint backed by [Cloudflare Workers AI](https://developers.cloudflare.com/workers-ai/), which hosts both Mistral and Gemma. OpenClaw talks to the Worker with a single bearer token; your Cloudflare credentials stay in the Worker.

```
OpenClaw ──(bearer token)──▶ Worker ──(AI binding)──▶ Workers AI (Mistral / Gemma)
```

**Setup:**

1. Deploy the Worker:
   ```bash
   cd cf-worker
   npm install
   npx wrangler secret put GATEWAY_TOKEN   # choose a long random token
   npx wrangler deploy
   ```
2. In `.env`:
   ```bash
   CF_WORKER_URL=https://openclaw-ai-gateway.<subdomain>.workers.dev/v1
   CF_WORKER_TOKEN=<the token you just set>
   ```
3. In `config/openclaw.config.json5`, the `cloudflare` provider is already wired
   to these vars. Select `mistral-small` or `gemma-3-12b` as your model.

| Alias | Backing model |
|-------|---------------|
| `mistral-small` | `@cf/mistralai/mistral-small-3.1-24b-instruct` |
| `gemma-3-12b` | `@cf/google/gemma-3-12b-it` |

See [`cf-worker/README.md`](../cf-worker/README.md) for full details.

## Option B — Direct provider APIs

Skip Cloudflare and call each provider directly.

### Mistral (La Plateforme)

Mistral offers an OpenAI-compatible API.

```bash
# .env
MISTRAL_API_KEY=your-key   # from https://console.mistral.ai/api-keys
```

Enable the `mistral` provider block in `config/openclaw.config.json5`. Models:
`mistral-small-latest`, `mistral-large-latest`, etc.

### Gemma (Google AI Studio)

Gemma open models are served through Google's Gemini API surface.

```bash
# .env
GOOGLE_API_KEY=your-key    # from https://aistudio.google.com/apikey
```

Enable the `google` provider block. Models: `gemma-3-12b-it`, plus Gemini models.

## Option C — Local / offline via Ollama

Run Mistral and Gemma entirely on your own hardware — no API keys, no network.

```bash
ollama pull mistral
ollama pull gemma3
```

Enable the `ollama` provider block (points at `http://localhost:11434/v1`).

## Choosing

| | Cloudflare Worker | Direct API | Ollama |
|---|---|---|---|
| Keys in OpenClaw | one token | per-provider | none |
| Runs offline | no | no | yes |
| Ops overhead | deploy 1 Worker | none | run Ollama |
| Both Mistral + Gemma from one endpoint | yes | no | yes |

For most self-hosters, **Option A** gives the cleanest split of credentials and a single endpoint for both model families.
