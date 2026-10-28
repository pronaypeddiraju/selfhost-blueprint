# Selfhost Blueprint

**Stand up a self-hosted stack on a spare machine — in about 20 minutes.**

Modular blueprints for a real, working home server: DNS + ad-blocking, TLS, passwords,
photo backup, media, monitoring, backups and a dashboard. Pick the pieces you want; every
piece is a self-contained module with an install script, a compose file, and a doc that
explains the *why*.

Built from a real two-node homelab, then **fully anonymized** — there are no real
domains, IPs, hostnames, account names or credentials anywhere in this repo. Every value
is a placeholder you fill in, in one `.env` file, which is git-ignored.

---

## What this is (and isn't)

**It is:** an opinionated, tested set of modules that fit together — one reverse proxy,
one DNS layer, one backup story, one dashboard. You deploy a coherent stack, not 12
random compose files from 12 blogs.

**It isn't:** a hosted product, a web UI for installing apps, or beginner-friendly
click-ops. You need to be comfortable with a terminal, `docker`, and reading an error
message. There is no support contract — see [§Maintenance](#maintenance--support).

---

## What you need

- A **spare machine** — old laptop, mini-PC, NUC, or a Proxmox box. Linux (Debian/Ubuntu
  recommended; any distro with Docker works).
- **RAM:** 2 GB works for `minimal`. 4 GB is comfortable. 8 GB+ if you want the photo
  library or the media stack alongside it.
- **Disk:** 10 GB for `minimal`. Photos and media are why you buy disks.
- **Docker** — `bootstrap.sh` will offer to install it.
- *Optional:* a domain + Cloudflare account (only for public TLS), a VPN subscription
  (only for the media stack), an LLM API key (only for the agent).

Full detail: [docs/01-requirements.md](docs/01-requirements.md).

---

## Quick start

```bash
git clone <this-repo-url> selfhost && cd selfhost
./bootstrap.sh          # checks the machine, installs Docker if needed, writes .env, offers a profile
```

Prefer manual control?

```bash
./configure.sh                      # interactive .env scaffolding
./install.sh --list                 # what's available, grouped by tier
./install.sh --profile=minimal      # core stack (~1 GB RAM)
./manage.sh status                  # what's running
```

Then open the dashboard: **`http://<this-host>:3002`** (or `https://homepage.home.arpa`
with the default `TLS_MODE=internal`).

**Before you put anything real on it, read
[docs/80-security.md](docs/80-security.md)** — first-boot passwords, the root-cert
install step, and what "LAN-only" actually protects you from.

---

## Profiles

| Profile | What you get | ~RAM |
|---|---|---|
| `minimal` | AdGuard DNS · Caddy TLS · Vaultwarden · Uptime Kuma · backups · Homepage | ~1 GB |
| `photos` | minimal + **Immich** (photo/video backup) | ~3–4 GB |
| `media` | minimal + **Jellyfin** + the VPN download stack | ~3 GB |
| `everything` | all Tier 1 + Tier 2 | 6 GB+ |

`hermes` (the personal agent) is **never** installed by a profile — it needs your own API
key and Telegram bot, and it gets shell access to the box. Ask for it explicitly.

---

## Modules

**Tier 1 — core, safe default**
`adguard` · `caddy` · `vaultwarden` · `uptimekuma` · `backups` · `homepage`

**Tier 2 — opt-in, per-service needs**
`immich` · `jellyfin` · `media-stack` · `mealie` · `silverbullet` · `filebrowser` · `scrutiny`

**Tier 3 — advanced, read the doc first**
`hermes`

Per-module RAM, disk, ports and "skip this if…" notes:
[docs/20-service-catalog.md](docs/20-service-catalog.md).

---

## Three things worth knowing up front

1. **TLS is a choice, not a purchase.** `TLS_MODE=internal` (default) gives you real
   HTTPS on your LAN from Caddy's own CA — no domain needed. `dns01` upgrades you to a
   public wildcard cert when you have a domain. `none` exists for a quick look.
   See [docs/19-tls.md](docs/19-tls.md).
2. **Nothing is exposed to the internet.** No mode opens an inbound port. For access from
   outside your LAN, put the machine on a private network (Tailscale/WireGuard) rather
   than forwarding ports.
3. **Backups are part of the core.** The `backups` module is in every profile. A stack
   holding your photos with no backup is not a backup.

---

## Documentation

Start at [docs/README.md](docs/README.md). The short path:

- [01 — What you need](docs/01-requirements.md)
- [02 — Quickstart](docs/02-quickstart.md)
- [20 — Service catalog](docs/20-service-catalog.md)
- [80 — Security checklist](docs/80-security.md)
- [90 — Troubleshooting](docs/90-troubleshooting.md)

Optional: [03 — Proxmox baseline](docs/03-proxmox-baseline.md) — ⚠️ **experimental in
v1.0**, not yet validated on a fresh Proxmox host.

---

## Maintenance & support

This is a **snapshot**, refreshed on release (see `CHANGELOG.md` and the git tags), not a
continuously-updated product. Pinned image tags mean nothing silently upgrades under you;
upgrade deliberately.

What's in scope: the install scripts, the compose files, and the wiring between modules.
What's out of scope: debugging your specific hardware, your ISP, your disks, or a
third-party app's own configuration. Issues are welcome; there is no response-time
promise.

---

## Legal / acceptable use

Some modules automate downloading media over a VPN (`media-stack`). **You are responsible
for what you download and for complying with your provider's terms of service and the law
where you live.** This repo ships the plumbing, not a licence, and makes no claim that any
particular use is lawful. Same story for any account you log into with the `hermes` module.

---

## License

MIT — see [LICENSE](LICENSE).