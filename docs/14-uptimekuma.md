# 14 — Uptime Kuma (monitoring)

Uptime monitoring + status page for all your services. Install:
`./install.sh --services=uptimekuma`, then create your admin account and add
monitors. UI on `http://<host>:3001`.

## Two ways to run it

**Docker (this module's default)** — `services/uptimekuma/compose.yaml`, one
container, data in `${DATA_DIR}/uptimekuma`.

**Native (systemd) — how our homelab actually runs it.** It's a Node app; the
unit is a plain service:

```
WorkingDirectory=/opt/uptime-kuma
ExecStart=/usr/bin/npm start        # listens on :3001
```

Data lives under `/opt/uptime-kuma/data`. Both modes are equivalent —
choose whichever fits your host (native is lighter if you already run Node,
Docker is more isolated/portable elsewhere).

## Tips
- Configure **notifications** (Telegram/email/webhook) as you add monitors, or
  they'll silently stay passive.
- The config is a SQLite DB under the data dir — it's the thing worth backing
  up; the monitor *list* is cheap to recreate but you'll want the notification
  wiring preserved.
- Don't point Uptime Kuma at so many targets that its probes count as your
  only monitoring source of truth — combine with a lightweight host
  resource-alert for memory/disk (see docs/10).
