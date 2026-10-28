# 13 — Mealie (recipe manager)

Self-hosted recipe manager + meal planner. Install:
`./install.sh --services=mealie`, then complete the first-run admin setup at
`http://<host>:9925`.

## Config (in `.env`)

- `MEALIE_SECRET` — **required**. Generate: `openssl rand -base64 32`.
- `MEALIE_HTTP_PORT` — host port (default 9925).
- `BASE_URL` — set to your public URL if you expose it via Caddy (see
  docs/05); otherwise leave blank for LAN-only.
- `ALLOW_SIGNUP=false` — user accounts are admin-created (keep it that way).

## Storage

Backend is **SQLite** (single container — simplest, works on a laptop). Data
lives at `${DATA_DIR}/mealie`. For heavier/multi-user production use, switch to
the PostgreSQL backend (refer to the upstream Mealie docs) — the compose in
`services/mealie/compose.yaml` stays single-container to keep it portable.

## Pitfalls
- **Back up `MEALIE_SECRET`** and the data dir — losing `MEALIE_SECRET` can
  brick access to stored recipe data.
- If you change `MEALIE_HTTP_PORT` after first run, you must also update it if
  you put the URL in any linked services; the container port inside is always
  9000.
