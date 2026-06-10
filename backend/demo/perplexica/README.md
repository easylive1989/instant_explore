# Perplexica narration-augmentation spike (local only)

A throwaway local stack to evaluate whether feeding **Perplexica** web
research into the `narration` prompt produces richer stories than the
current Wikipedia + Wikidata sources — especially for places where
Wikipedia is thin.

- **Perplexica** (`:3000`) — self-hosted AI web-search engine
  (SearxNG + an LLM). The `itzcrazykns1337/vane:latest` full image
  bundles SearxNG.
- **freellmapi** (`:3001`) — OpenAI-compatible proxy aggregating free
  LLM tiers. Provides both `/v1/chat/completions` and `/v1/embeddings`,
  which is exactly what Perplexica needs (chat model **and** embedding
  model).

This stack is **not** part of the production deployment
(`backend/docker-compose.yml`). Nothing here is wired into the running
backend; only `scripts/perplexica_demo.py` talks to it.

## 1. Start the services

```bash
cd backend/demo/perplexica
cp .env.example .env
# put `openssl rand -hex 32` output into ENCRYPTION_KEY in .env
docker compose up -d
```

## 2. One-time manual setup (cannot be automated)

### a. freellmapi — get an API key

1. Open <http://localhost:3001> and create the admin login.
2. Add at least one free provider (e.g. Google Gemini, Groq) following
   the dashboard instructions, including one that offers **embeddings**.
3. Copy the unified `freellmapi-…` API key.

### b. Perplexica — add a custom OpenAI provider (chat model only)

Perplexica ships with **local Transformers embedding models** built in
(`all-MiniLM-L6-v2`, etc.), so you only need to supply a **chat** model.

1. Open <http://localhost:3000> → Settings.
2. Add a **custom OpenAI-compatible provider**:
   - Base URL: `http://host.docker.internal:3001/v1`
   - API key: the `freellmapi-…` key from step (a)
3. Select a **chat model** from that provider (the embedding model can
   stay on the built-in Transformers provider).

### c. Confirm the API is reachable

```bash
curl http://localhost:3001/v1/models                 # freellmapi up
curl http://localhost:3000/api/providers             # returns providerId(s)
curl -X POST http://localhost:3000/api/search \
  -H 'Content-Type: application/json' \
  -d '{"chatModel":{"providerId":"<uuid>","key":"<model>"},
       "embeddingModel":{"providerId":"<uuid>","key":"<model>"},
       "sources":["web"],"query":"Who was Vincent van Gogh","stream":false}'
```

`scripts/perplexica_demo.py` resolves the `providerId`/`key` itself via
`/api/providers`, so you don't need to hard-code the UUIDs — you only
need step (b) done so a provider exists.

## 3. Run the comparison

```bash
cd backend
# In backend/.env, optionally set PERPLEXICA_URL (defaults to localhost:3000).
uv run python -m scripts.perplexica_demo --no-gemini            # just web research
uv run python -m scripts.perplexica_demo --language zh-TW       # full story compare
uv run python -m scripts.perplexica_demo \
    --place "Some obscure place" --wikidata-id Q12345 --location "City, Country"
```

## Troubleshooting

- **Every Perplexica route returns 500 / "Internal Server Error"** — almost
  always *another process is already listening on host port 3000* (e.g. a
  stray `next dev`). On macOS `localhost` resolves to IPv6 first, so the
  stray process answers instead of Docker. Check with
  `lsof -nP -iTCP:3000 -sTCP:LISTEN` and stop the offender, then
  `docker compose up -d perplexica`.
- **Host can't reach the app even though the container is "Up"** — Next.js
  standalone binds to `$HOSTNAME`, which Docker auto-sets to the container
  id, making it unreachable through the published port. The compose file
  pins `HOSTNAME=0.0.0.0` to fix this; don't remove it.

## Notes / caveats

- Free LLM tiers and SearxNG upstreams can rate-limit; flaky results are
  expected for a spike.
- Perplexica runs its **own** LLM to synthesise an answer before Gemini
  rewrites it → two LLM calls per story. Fine for evaluation; a real
  rollout must weigh the cost.
- Web research is treated as **lower-authority supplementary** material
  in the prompt (`[4]` block in `shared/story_prompt.py`); Wikipedia /
  Wikidata remain authoritative.
