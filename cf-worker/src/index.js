/**
 * OpenClaw AI Gateway — Cloudflare Worker
 *
 * Exposes an OpenAI-compatible API (/v1/chat/completions, /v1/models) backed by
 * Cloudflare Workers AI. This lets OpenClaw talk to Mistral and Gemma models
 * through a single stable endpoint without embedding your Cloudflare account ID
 * or API token in OpenClaw's config — the Worker's AI binding handles that.
 *
 * OpenClaw points its "openai" provider baseUrl at this Worker and authenticates
 * with a bearer token you set via `wrangler secret put GATEWAY_TOKEN`.
 */

// Friendly alias -> Cloudflare Workers AI model ID.
// Add or change entries here to expose more models.
const MODEL_ALIASES = {
  "mistral-small": "@cf/mistralai/mistral-small-3.1-24b-instruct",
  "mistral-small-3.1-24b-instruct": "@cf/mistralai/mistral-small-3.1-24b-instruct",
  "gemma-3-12b": "@cf/google/gemma-3-12b-it",
  "gemma-3-12b-it": "@cf/google/gemma-3-12b-it",
};

const DEFAULT_MODEL = "mistral-small";

function corsHeaders() {
  return {
    "Access-Control-Allow-Origin": "*",
    "Access-Control-Allow-Methods": "GET, POST, OPTIONS",
    "Access-Control-Allow-Headers": "Content-Type, Authorization",
  };
}

function json(body, status = 200, extraHeaders = {}) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "Content-Type": "application/json", ...corsHeaders(), ...extraHeaders },
  });
}

function errorResponse(message, status = 400, type = "invalid_request_error") {
  return json({ error: { message, type } }, status);
}

// Constant-time-ish bearer token check.
function isAuthorized(request, env) {
  if (!env.GATEWAY_TOKEN) return true; // no token configured => open (dev only)
  const auth = request.headers.get("Authorization") || "";
  const token = auth.startsWith("Bearer ") ? auth.slice(7) : "";
  return token.length > 0 && token === env.GATEWAY_TOKEN;
}

function resolveModel(requested) {
  if (!requested) return MODEL_ALIASES[DEFAULT_MODEL];
  return MODEL_ALIASES[requested] || (requested.startsWith("@cf/") ? requested : null);
}

// A pseudo-unique id without Date.now()/Math.random() (unavailable in some runtimes
// is not a concern in Workers, but keep it deterministic-friendly).
function completionId() {
  return "chatcmpl-" + crypto.randomUUID();
}

function nowSeconds() {
  return Math.floor(Date.now() / 1000);
}

async function handleModels(env) {
  const seen = new Set();
  const data = [];
  for (const alias of Object.keys(MODEL_ALIASES)) {
    const id = MODEL_ALIASES[alias];
    if (seen.has(alias)) continue;
    seen.add(alias);
    data.push({ id: alias, object: "model", created: 0, owned_by: "cloudflare-workers-ai", cf_model: id });
  }
  return json({ object: "list", data });
}

async function handleChatCompletions(request, env) {
  let payload;
  try {
    payload = await request.json();
  } catch {
    return errorResponse("Request body must be valid JSON");
  }

  const model = resolveModel(payload.model);
  if (!model) {
    return errorResponse(
      `Unknown model '${payload.model}'. Known aliases: ${Object.keys(MODEL_ALIASES).join(", ")}`,
      404,
      "model_not_found"
    );
  }

  const messages = Array.isArray(payload.messages) ? payload.messages : [];
  if (messages.length === 0) {
    return errorResponse("'messages' must be a non-empty array");
  }

  const runOpts = {
    messages,
    max_tokens: payload.max_tokens ?? 1024,
  };
  if (typeof payload.temperature === "number") runOpts.temperature = payload.temperature;
  if (typeof payload.top_p === "number") runOpts.top_p = payload.top_p;

  const stream = payload.stream === true;
  const id = completionId();
  const created = nowSeconds();

  if (stream) {
    runOpts.stream = true;
    const aiStream = await env.AI.run(model, runOpts);
    const openaiStream = toOpenAIStream(aiStream, { id, created, model: payload.model || DEFAULT_MODEL });
    return new Response(openaiStream, {
      headers: {
        "Content-Type": "text/event-stream",
        "Cache-Control": "no-cache",
        Connection: "keep-alive",
        ...corsHeaders(),
      },
    });
  }

  const result = await env.AI.run(model, runOpts);
  const text = typeof result === "string" ? result : result.response ?? "";
  return json({
    id,
    object: "chat.completion",
    created,
    model: payload.model || DEFAULT_MODEL,
    choices: [
      {
        index: 0,
        message: { role: "assistant", content: text },
        finish_reason: "stop",
      },
    ],
    usage: result.usage ?? { prompt_tokens: 0, completion_tokens: 0, total_tokens: 0 },
  });
}

/**
 * Transform a Workers AI SSE stream (`data: {"response":"..."}` ... `data: [DONE]`)
 * into an OpenAI chat.completion.chunk SSE stream.
 */
function toOpenAIStream(aiStream, meta) {
  const encoder = new TextEncoder();
  const decoder = new TextDecoder();
  let buffer = "";
  let sentRole = false;

  const chunk = (delta, finish_reason = null) =>
    `data: ${JSON.stringify({
      id: meta.id,
      object: "chat.completion.chunk",
      created: meta.created,
      model: meta.model,
      choices: [{ index: 0, delta, finish_reason }],
    })}\n\n`;

  return new ReadableStream({
    async start(controller) {
      const reader = aiStream.getReader();
      try {
        while (true) {
          const { done, value } = await reader.read();
          if (done) break;
          buffer += decoder.decode(value, { stream: true });

          let idx;
          while ((idx = buffer.indexOf("\n")) !== -1) {
            const line = buffer.slice(0, idx).trim();
            buffer = buffer.slice(idx + 1);
            if (!line.startsWith("data:")) continue;
            const data = line.slice(5).trim();
            if (data === "[DONE]") continue;
            try {
              const parsed = JSON.parse(data);
              const token = parsed.response ?? "";
              if (token === "") continue;
              if (!sentRole) {
                controller.enqueue(encoder.encode(chunk({ role: "assistant", content: token })));
                sentRole = true;
              } else {
                controller.enqueue(encoder.encode(chunk({ content: token })));
              }
            } catch {
              // ignore malformed partial lines
            }
          }
        }
        controller.enqueue(encoder.encode(chunk({}, "stop")));
        controller.enqueue(encoder.encode("data: [DONE]\n\n"));
      } catch (err) {
        controller.error(err);
        return;
      }
      controller.close();
    },
  });
}

export default {
  async fetch(request, env) {
    const url = new URL(request.url);

    if (request.method === "OPTIONS") {
      return new Response(null, { status: 204, headers: corsHeaders() });
    }

    // Unauthenticated health check.
    if (url.pathname === "/healthz") {
      return json({ status: "ok" });
    }

    if (!isAuthorized(request, env)) {
      return errorResponse("Missing or invalid bearer token", 401, "authentication_error");
    }

    if (url.pathname === "/v1/models" && request.method === "GET") {
      return handleModels(env);
    }

    if (url.pathname === "/v1/chat/completions" && request.method === "POST") {
      return handleChatCompletions(request, env);
    }

    return errorResponse(`No route for ${request.method} ${url.pathname}`, 404, "not_found");
  },
};
