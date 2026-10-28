# 85 — Image pins

Every container image in this repo is pinned to a **manifest digest**, so
`docker compose up` gives you exactly the bits that were tested — not whatever upstream
pushed to `:latest` this morning.

```
image: adguard/adguardhome:latest@sha256:aba9e3bf…
       └────── human-readable tag ──────┘└─ immutable ─┘
```

The tag stays in the reference for readability; the digest is what Docker actually
resolves.

## Why

- **Reproducible.** Two people installing the same release get the same containers.
- **No surprise upgrades.** A maintainer tagging a bad `:latest` can't break your box at
  3am.
- **Supply-chain honesty.** A digest can't be retagged. If upstream replaces the content,
  the pull fails instead of silently giving you something else.

The trade-off is real: **pins don't track security fixes.** You have to move them
deliberately. That's the point, but it's your job.

## What's pinned (v1.0.0, 2026-10-28)

| Module | Image | Tag |
|---|---|---|
| adguard | `adguard/adguardhome` | latest |
| caddy | `caddy` | 2 |
| vaultwarden | `vaultwarden/server` | latest |
| uptimekuma | `louislam/uptime-kuma` | 1 |
| homepage | `ghcr.io/gethomepage/homepage` | v1.2.0 |
| scrutiny | `ghcr.io/analogj/scrutiny` | v0.8.1-omnibus |
| immich | `ghcr.io/immich-app/immich-server` | release |
| immich | `ghcr.io/immich-app/immich-machine-learning` | release |
| immich | `ghcr.io/immich-app/postgres` | 14-vectorchord0.4.3-pgvectors0.2.0 |
| immich | `redis` | 6.2-alpine |
| jellyfin | `lscr.io/linuxserver/jellyfin` | latest |
| media-stack | `qmcgaw/gluetun` | latest |
| media-stack | `lscr.io/linuxserver/qbittorrent` | latest |
| media-stack | `lscr.io/linuxserver/radarr` | latest |
| media-stack | `lscr.io/linuxserver/sonarr` | latest |
| media-stack | `lscr.io/linuxserver/prowlarr` | latest |
| media-stack | `lscr.io/linuxserver/bazarr` | latest |
| media-stack | `ghcr.io/flaresolverr/flaresolverr` | latest |
| media-stack | `ghcr.io/manimatter/decluttarr` | latest |
| media-stack | `fallenbagel/jellyseerr` | latest |
| mealie | `ghcr.io/mealie-recipes/mealie` | latest |
| silverbullet | `zefhemel/silverbullet` | latest |
| filebrowser | `filebrowser/filebrowser` | v2.31.2 |

## Updating a pin

`scripts/resolve-digests.sh` talks to the registry APIs directly — no Docker daemon
needed.

```bash
./scripts/resolve-digests.sh adguard/adguardhome:latest
# adguard/adguardhome:latest   sha256:aba9e3bf…
```

Then edit the `image:` line and update the `# tag:` comment / the date. Procedure:

1. **Back up first** (especially Immich, Vaultwarden, Mealie — schema migrations).
2. Resolve the new digest.
3. Edit the compose file.
4. `./manage.sh restart <service>` and check logs.
5. Read upstream release notes for any major-version bump. Immich in particular has
   breaking changes that require a specific upgrade path.

## Why not Renovate/Dependabot

Both work well for apps, and you may prefer them once you've forked this. They're not
wired up here because pinning by digest plus a documented refresh procedure is honest about
the real obligation: **someone has to decide when to move.** A bot that opens PRs nobody
merges is theatre.