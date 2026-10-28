# 21 — Homepage (dashboard)

The front door. One page with a tile per service, plus live widgets.

- **Port** `3002` · **RAM** ~100 MB · **Config** `${DATA_DIR}/homepage/config/`

## What you get

`install.sh` seeds three files so the dashboard isn't blank:

| File | What it controls |
|---|---|
| `settings.yaml` | title, theme, layout, and the group/column structure |
| `services.yaml` | the actual tiles — name, href, description, icon |
| `bookmarks.yaml` | a second tab for links that aren't services |

Edit them on disk (they're plain YAML) and the UI updates within a second — no restart.

## Adding a tile

```yaml
# services.yaml
- Media:
    - Jellyfin:
        href: https://jellyfin.home.arpa
        description: Movies & TV
    - Immich:
        href: https://immich.home.arpa
        description: Photos
```

Groups in `settings.yaml` control the layout rows; a group with no tiles just doesn't
render.

## Widgets

Homepage can show live data (container status, disk usage, qBittorrent queue, Jellyfin
"now playing"). Container-status widgets use the mounted Docker socket:

```yaml
- Docker:
    widget:
      type: docker
      url: unix:/var/run/docker.sock
```

Service widgets need that service's API key — put them in `widgets.yaml`, **not** in
`services.yaml`.

## The security bit

This container has `/var/run/docker.sock` mounted **read-only**. Read-only is not
"harmless": it exposes a lot about the host and the Docker control plane. Two consequences:

1. **Never expose Homepage to the internet.**
2. If you'd rather not mount the socket at all, delete that volume line from
   `compose.yaml` — you lose container-status widgets and everything else works.

`HOMEPAGE_ALLOWED_HOSTS` exists because Homepage rejects unknown `Host` headers
(DNS-rebinding protection). Set it to the hostname(s) you actually use. `*` is fine on a
trusted LAN; it is not fine on a shared network.

## Troubleshooting

- **Blank page / "host validation failed"** → `HOMEPAGE_ALLOWED_HOSTS` doesn't include the
  hostname in your address bar.
- **Tiles are missing** → YAML indentation. Homepage silently skips a malformed group; check
  `docker logs homepage` for a parse error.
- **Widget shows "API error"** → wrong key, or the widget can't reach the service. Widgets
  run server-side, inside the container, so use service names / host IPs that container can
  actually reach.