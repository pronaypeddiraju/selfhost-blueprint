# 00 — Architecture (conceptual)

This blueprint is intentionally hardware- and topology-agnostic. You can run
everything on one machine (a laptop or a small server) or spread across
several. The design makes that a non-decision for the person using it.

## Logical layers

```
┌─────────────────────────────────────────────────────────────┐
│   Clients (phone / laptop / browser / messaging apps)        │
└───────────────┬───────────────────────────────┬─────────────┘
                │ public internet                │ LAN
┌───────────────▼────────────┐   ┌───────────────▼──────────────┐
│  Reverse proxy (Caddy)     │   │   Local DNS (AdGuard)        │
│   TLS + hostname routing   │   │   ad-block + name resolution │
└───────────────┬────────────┘   └───────────────┬──────────────┘
                │                                │
┌───────────────▼────────────────────────────────▼──────────────┐
│              Docker + shared network                            │
│  ┌─────────┐ ┌─────────┐ ┌─────────┐ ┌─────────┐               │
│  │ Media   │ │ Immich  │ │Jellyfin │ │ Mealie  │   ... (pick   │
│  │ stack   │ │ photos  │ │ video   │ │ recipes │      any)     │
│  └─────────┘ └─────────┘ └─────────┘ └─────────┘               │
└──────────────────────────────┬─────────────────────────────────┘
                               │
                    ┌──────────▼──────────┐
                    │  Storage (ZFS or    │
                    │  plain directory)   │
                    └─────────────────────┘
```

## Three TLS modes (you pick — see [19 — TLS](19-tls.md))

1. **`internal`** *(default)*: Caddy runs its own local CA and issues certs for
   `*.home.arpa`. Real HTTPS on your LAN, **no domain needed**. You install Caddy's
   root cert once per device.
2. **`dns01`**: a real wildcard cert for a domain you own, via a DNS-01 challenge
   (Cloudflare). No inbound ports, works off-LAN, no cert installs. Needs `APP_DOMAIN`
   + `CLOUDFLARE_API_TOKEN`.
3. **`none`**: plain HTTP. Quickest preview; **Vaultwarden will not work**.

## Two storage models (you pick)

- **Plain directory** (`STORAGE_TYPE=dir`) — works on any machine.
- **ZFS datasets** (`STORAGE_TYPE=zfs`, Proxmox module) — for snapshot-based
  backups and a more production-grade home server.

## GPU: detect or degrade

Immich ML and Jellyfin transcode each **enable GPU
acceleration only if a compatible GPU is detected**, and otherwise run fine on
CPU. This is what makes the blueprint work on a laptop *and* on a GPU server.
