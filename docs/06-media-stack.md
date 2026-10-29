# 06 — Media stack

The download-automation stack: **gluetun** (VPN) + **qBittorrent**, **Radarr**,
**Sonarr**, **Prowlarr**, **Bazarr**, **FlareSolverr**, plus **Seerr**
(request portal, formerly Jellyseerr) and optional **decluttarr** (cleanup).

## Key idea: everything behind gluetun

All downloaders/providers share gluetun's network namespace (`network_mode:
service:gluetun`), so they egress through a **single VPN IP** and can't leak.
As a result they have **no network identity of their own** — address them by
context:

```
from inside that namespace ..... localhost:<port>
from another container on the
  same Docker network ........... gluetun:<port>
from outside (browser/Caddy) .... <host-ip>:<port>
```

> ⚠️ **Do not** use the host IP from a sibling container. It hairpin-NATs
> through gluetun's firewall and fails with `Connection reset by peer`.

## Port forwarding (VPN)

qBittorrent needs an inbound port forwarded by your VPN provider. Set the
forwarded port in `.env` (`VPN_PORT_FORWARDED`) so it's published on the host
and configured as qBittorrent's listening port. If your provider doesn't support
port forwarding, download automation still works — just slower/less reliable.

## Configure each app first-run

- **qBittorrent** : `http://<host>:8080` — set download paths to the shared
  `/downloads` mount and the forwarded listening port.
- **Prowlarr** → add indexers, then connect to Radarr/Sonarr.
- **Radarr/Sonarr** → map `root folder` to `/downloads`, set download client to
  qBittorrent (`gluetun`'s port if configuring from a sibling container).
- **Bazarr** → point at Radarr/Sonarr for subtitles.
- **Seerr** → connect to Radarr/Sonarr + Jellyfin.

## Seerr (formerly Jellyseerr / Overseerr)

The Jellyseerr and Overseerr teams merged into a single project, **Seerr**
(Feb 2026). Both old images (`fallenbagel/jellyseerr`, `sct/overseerr`) are
archived and get no further fixes — the blueprint now ships
`ghcr.io/seerr-team/seerr`, which supports Jellyfin, Emby and Plex from one
codebase.

Things that bite when migrating or deploying:

- **Auto-migration**: point Seerr at an existing Jellyseerr config dir and it
  migrates the database and settings on first start. Copy (don't move) the old
  `media/jellyseerr` dir so rollback is just reverting the image tag.
- **`init: true` is required** — the Seerr image no longer bundles an init
  process of its own; without it the container will not shut down cleanly.
- **Runs as the non-root `node` user (UID 1000)** and deliberately does not
  support `PUID`/`PGID`. The install script chowns the config dir; doing it by
  hand is `chown -R 1000:1000 <DATA_DIR>/media/seerr`.
- **Not behind gluetun.** Seerr talks to your media server on the LAN, so it
  publishes its own port (`SEERR_PORT`) — the gluetun service does not.
- The API is Jellyseerr-compatible, so existing Homepage `type: jellyseerr`
  widgets and API keys keep working.

## Decluttarr (optional cleanup)

Removes stalled / failed / orphaned downloads, blocklists them, and re-searches
for an alternative. Ships in the media stack (config rendered to
`services/media-stack/config/decluttarr.yaml` from
`templates/decluttarr/config.example.yaml`). **It runs standalone on the network
and reaches the gluetun-backed apps at `gluetun:<port>`** — fill in each app's
API key + the qBittorrent password in that config.

**Keep slow-download removal disabled** — its default threshold kills healthy
thin-swarm torrents. A job key with an empty value is ENABLED; comment it out to
disable.
