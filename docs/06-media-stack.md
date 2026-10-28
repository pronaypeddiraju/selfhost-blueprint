# 06 — Media stack

The download-automation stack: **gluetun** (VPN) + **qBittorrent**, **Radarr**,
**Sonarr**, **Prowlarr**, **Bazarr**, **FlareSolverr**, plus **Jellyseerr**
(request portal) and optional **decluttarr** (cleanup).

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
- **Jellyseerr** → connect to Radarr/Sonarr + Jellyfin.

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
