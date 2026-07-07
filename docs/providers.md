# AI Providers

OpenClaw follows a Bring-Your-Own-Model design. This scaffold ships ready to use four models via the Cloudflare Worker gateway — **Mistral Small**, **Gemma 3**, **Hermes SuperAgent**, and **π Coding Agent** — with Mistral and Gemma also available directly or locally. Pick one of the three connection methods below.

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
| `hermes-superagent` | `@hf/nousresearch/hermes-2-pro-mistral-7b` (function calling) |
| `pi-coding-agent` | `@cf/qwen/qwen2.5-coder-32b-instruct` (coding) |

### The four models

- **`mistral-small`** — Mistral Small 3.1 (24B). A strong, all-round instruct
  model with a 128K-token context window and vision support. The default; good
  balance of quality, speed, and cost for general chat and reasoning.
- **`gemma-3-12b`** — Google Gemma 3 (12B). Open-weight, multilingual (140+
  languages), 128K context, with vision. Lighter than Mistral Small — a fast,
  economical pick for everyday tasks and non-English use.
- **`hermes-superagent`** — Nous Research Hermes 2 Pro (Mistral 7B). Tuned for
  **function/tool calling and JSON mode**, which makes it the best fit for
  agentic workflows where the model must call skills and return structured
  output. (Cloudflare marks it deprecated 5/30/2026 — swap when it's removed.)
- **`pi-coding-agent`** — Qwen2.5-Coder (32B). A **code-specialized** model
  (32K context) for writing, explaining, and refactoring code across many
  languages. Reach for this on programming tasks; use the others for general chat.

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
