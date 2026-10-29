# 01 — What you need

## Hardware floor

| Profile | RAM | Disk | Notes |
|---|---|---|---|
| `minimal` | 2 GB | 10 GB | Comfortable at 2 GB; works at 1.5 GB if nothing else runs here |
| `photos` | 4 GB | + your photo library | Immich ML runs CPU-only without a GPU and will eat 1.5–2 GB while indexing |
| `media` | 4 GB | + media library | Jellyfin transcodes on CPU if there's no GPU; direct play costs almost nothing |
| `everything` | 8 GB | + libraries | Everything above, at once |

Real-world reference: the homelab this came from runs the full core stack in well under
1 GB, and Immich is by far the hungriest single service.

**Any x86_64 or arm64 Linux machine works.** Old laptop, NUC, mini-PC, a VM, even a
Raspberry Pi 4 for `minimal` (arm64 images are used by every Tier 1 module).

## Operating system

- Debian 12/13 or Ubuntu 22.04/24.04 are what this is tested on.
- **systemd is assumed** (the `hermes` module installs a systemd unit; `backups` uses
  timers/cron).
- Docker Engine 24+ with the **Compose v2 plugin** (`docker compose`, not
  `docker-compose`). `bootstrap.sh` offers to install it.

### Ports that must be free

`80` and `443` (Caddy). If something already owns them — a NAS web UI, an ISP router's
admin page on this machine, another proxy — either stop it or set `CADDY_HTTP_PORT` /
`CADDY_HTTPS_PORT` and use those instead.

Also avoid: `3000` (AdGuard), `3001` (Uptime Kuma), `3002` (Homepage), `3030`
(SilverBullet), `8000` (Vaultwarden), `8080` (qBittorrent), `8081` (Scrutiny), `8082`
(FileBrowser), `8096` (Jellyfin),
`9925` (Mealie), `2283` (Immich), and the *arr ports `7878/8989/9696/6767/5055`.

All of these are overridable in `.env` — see [20 — Service catalog](20-service-catalog.md).

## Network

- A **static IP or DHCP reservation** for the machine. Everything points at this address;
  if it moves, your bookmarks and DNS rewrites break.
- A LAN you trust. The default posture is "this is on my own network" — see
  [80 — Security](80-security.md).

## Optional, per module

| You want | You'll need |
|---|---|
| Public TLS (`TLS_MODE=dns01`) | A domain + a Cloudflare API token with DNS-edit rights |
| `media-stack` | A **VPN subscription that supports WireGuard** (the stack routes all downloads through it) and indexer credentials |
| `hermes` | An LLM provider API key (OpenRouter, Anthropic, etc.) and a Telegram bot token from @BotFather |
| `frigate`-style camera work | *(not in v1.0 — removed; see the roadmap)* |
| Remote access from outside your LAN | Tailscale or WireGuard. **Do not port-forward.** |

## What this doesn't need

- No domain is required. The default TLS mode is local.
- No cloud account, no subscription, no licence key for any Tier 1/2 module.
- No GPU. Everything degrades to CPU; a GPU only makes Immich indexing and Jellyfin
  transcoding faster.