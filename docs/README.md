# Documentation

Read in this order. Numbers are stable IDs, not a strict sequence — follow the path.

## Getting it running

| Doc | What it's for |
|---|---|
| [01 — What you need](01-requirements.md) | Hardware floor, OS, software, optional accounts |
| [02 — Quickstart](02-quickstart.md) | Bare machine → running stack, step by step |
| [20 — Service catalog](20-service-catalog.md) | Every module: what it does, RAM/disk, port, "skip this if…" |

## Core concepts

| Doc | What it's for |
|---|---|
| [00 — Architecture](00-architecture.md) | How the pieces fit; what talks to what |
| [19 — TLS modes](19-tls.md) | `none` vs `internal` vs `dns01`, and installing Caddy's root cert |
| [04 — DNS / AdGuard](04-dns.md) | Local DNS, ad-blocking, and friendly hostnames |
| [05 — Reverse proxy](05-reverse-proxy.md) | Caddy site blocks, upstreams, regeneration |

## Per-service

| Doc | Service |
|---|---|
| [21 — Homepage](21-homepage.md) | Dashboard / front door |
| [09 — Hermes](09-hermes.md) | Personal agent — bring your own key, read the security note |
| [08 — Immich](08-immich.md) | Photo/video backup |
| [07 — Jellyfin](07-jellyfin.md) | Media server |
| [06 — Media stack](06-media-stack.md) | VPN + download automation (*arr) |
| [13 — Mealie](13-mealie.md) | Recipes & meal planning |
| [16 — SilverBullet](16-silverbullet.md) | Markdown knowledge base |
| [18 — FileBrowser](18-filebrowser.md) | Web file manager |
| [17 — Scrutiny](17-scrutiny.md) | Disk health / SMART |
| [14 — Uptime Kuma](14-uptimekuma.md) | Uptime monitoring |
| [10 — Backups](10-backups.md) | Snapshots/retention, restore testing |

## Operating it

| Doc | What it's for |
|---|---|
| [80 — Security checklist](80-security.md) | First-boot passwords, secrets model, exposure rules |
| [85 — Image pins](85-image-pins.md) | Why every image is digest-pinned, and how to move a pin |
| [90 — Troubleshooting](90-troubleshooting.md) | The failures you're actually likely to hit |

## Optional / advanced

| Doc | What it's for |
|---|---|
| [03 — Proxmox baseline](03-proxmox-baseline.md) | ⚠️ **Experimental in v1.0** — LXC + ZFS. Not yet validated on a fresh host. |

Each doc explains the **why**, calls out the pitfalls we actually hit, and points at the
scripts that implement it.