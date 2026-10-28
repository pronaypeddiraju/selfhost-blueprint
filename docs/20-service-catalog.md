# 20 — Service catalog

Every module, what it costs, and whether you should install it. RAM figures are
steady-state on a quiet system; indexing/sync spikes are noted.

Ports are defaults — all are overridable in `.env`.

---

## Tier 1 — core

### `adguard` — DNS + ad-blocking
- **RAM** ~100 MB · **Port** 3000 (UI), 53 (DNS)
- **Does:** local DNS for your whole network, network-wide ad/tracker blocking, and the
  DNS rewrites that make `*.home.arpa` hostnames work.
- **Skip if** your router already blocks ads and you're happy typing IPs. If you skip it,
  you'll need `/etc/hosts` entries for every service.
- **Gotcha:** something else on the box may already own port 53 (`systemd-resolved`).
  See [04 — DNS](04-dns.md).

### `caddy` — reverse proxy + TLS
- **RAM** ~50 MB · **Ports** 80, 443
- **Does:** one front door and real HTTPS for everything, with the TLS mode you chose.
  Regenerates its config from the modules you have installed.
- **Skip if** you genuinely don't mind `http://ip:port` for every service — but then
  **Vaultwarden won't work** and nothing gets a hostname.

### `vaultwarden` — password manager
- **RAM** ~50 MB · **Port** 8000
- **Does:** Bitwarden-compatible server. The reason to have it: unique passwords for
  every other service here.
- **Needs TLS.** The web vault uses WebCrypto, which browsers only allow on secure
  contexts — `TLS_MODE=none` breaks it, and Bitwarden mobile clients refuse plain HTTP.
- **First boot:** create the account immediately, then disable signups.

### `uptimekuma` — uptime monitoring
- **RAM** ~150 MB · **Port** 3001
- **Does:** "is anything down?" with notification channels (email, ntfy, Telegram…).
- **Skip if** you'll never look at it — an unwatched monitor is worse than none, because
  it teaches you to ignore alerts.

### `backups` — snapshots / retention
- **RAM** negligible · **Disk** = whatever you retain
- **Does:** ZFS snapshots when `STORAGE_TYPE=zfs`, tar-based rotation on plain
  directories. Daily/weekly/monthly retention from `.env`.
- **Never skip this.** It's in every profile deliberately.

### `homepage` — dashboard
- **RAM** ~100 MB · **Port** 3002
- **Does:** one page with a tile per service, plus live widgets (container status, disk,
  weather, whatever). This is what makes the stack feel like a product.
- **Note:** mounts the Docker socket **read-only** for container-status widgets. That's a
  real privilege — don't expose Homepage to the internet.

---

## Tier 2 — opt-in

### `immich` — photo/video backup
- **RAM** 2–4 GB (ML is the hog) · **Disk** = your library · **Port** 2283
- **Does:** Google-Photos-style backup, faces, search, mobile auto-upload.
- **The big one.** If you install one Tier 2 service, install this — and make sure
  `backups` covers it *before* your library lands.
- **No GPU?** Works, just slower indexing. `GPU_MODE=auto` detects what you have.

### `jellyfin` — media server
- **RAM** 0.5–1 GB · **Disk** = your media · **Port** 8096
- **Does:** your own Netflix. Direct play costs almost nothing; transcoding is CPU/GPU
  heavy.
- **Skip if** you don't have a media library yet. You can add it later.

### `media-stack` — VPN + download automation
- **RAM** ~2 GB total · **Ports** 8080 (qBittorrent), 7878/8989/9696/6767, 5055 (Jellyseerr)
- **Does:** gluetun (WireGuard VPN) + qBittorrent + Prowlarr/Radarr/Sonarr/Bazarr +
  FlareSolverr + Decluttarr + Jellyseerr, all egressing through the VPN.
- **Needs:** a VPN subscription with WireGuard config, indexer accounts.
- **Read [06 — Media stack](06-media-stack.md) before installing** — the
  `network_mode: service:gluetun` pattern is the #1 source of "why can't I reach
  qBittorrent" confusion.
- **You are responsible for what you download.** See the legal note in the README.

### `mealie` — recipes & meal planning
- **RAM** ~250 MB · **Port** 9925
- **Does:** recipe scraper, meal planner, shopping lists.
- **Cheapest "family actually uses it" module here.**

### `silverbullet` — markdown knowledge base
- **RAM** ~50 MB · **Port** 3000
- **Does:** notes as plain `.md` files on disk, edited in the browser. Grep-able, syncable,
  Obsidian-compatible.
- **Skip if** you already have a notes app you like.

### `filebrowser` — web file manager
- **RAM** ~30 MB · **Port** 8080
- **Does:** browse/download/upload files in the browser, with per-user scopes.
- **Bind it read-only to your backups** if you expose it at all — a mis-click shouldn't be
  able to delete the thing that saves you.

### `scrutiny` — disk health
- **RAM** ~100 MB · **Port** 8081
- **Does:** SMART attributes with history, so a dying disk warns you instead of surprising
  you.
- **Note:** needs raw block-device access (`/dev`, `SYS_RAWIO`). Narrow the `/dev` mount in
  `compose.yaml` to your real disks once you know them.
- **The best value-per-megabyte module in the repo.** See [17 — Scrutiny](17-scrutiny.md).

---

## Tier 3 — advanced

### `hermes` — self-hosted personal agent
- **RAM** ~0.5–1 GB · **Port** none (it's a messaging bot)
- **Does:** an always-on agent you talk to over Telegram/WhatsApp that can run commands,
  schedule jobs, and answer questions about your own systems.
- **Needs:** your own LLM API key, your own bot token, and **a mandatory allowlist** —
  this agent gets shell access to your box by design.
- **Costs money after install** (API usage, a few dollars a month at light use).
- **Ships the installer only** — no persona, memory, cron jobs or skills. Yours starts
  blank.

---

## Deliberately not included in v1.0

`frigate` (NVR — needs cameras + storage) · `paperless` (document DMS — five containers) ·
`lore` (niche VCS) · finance/budget tooling · an app-store UI. They exist in the private
upstream and may come back in a later release; see `CHANGELOG.md`.