# 90 — Troubleshooting

The failures you're actually likely to hit, in rough order of frequency.

## First: get the facts

```bash
./manage.sh status                          # what's supposed to be up
docker ps -a --format '{{.Names}}\t{{.Status}}'   # what's actually up
docker logs --tail 50 <container>           # why it isn't
ss -tlnp | grep -E ':(80|443|3000|3001|3002|8000|8096) '
```

---

## Port already in use

`Error: bind: address already in use`

Something on the host owns the port. Find it:

```bash
sudo ss -tlnp | grep ':80 '
```

Then either stop that service, or override the port in `.env`
(`CADDY_HTTP_PORT=8080`) and re-run `./install.sh --services=caddy`.

## AdGuard won't start — port 53 in use

`systemd-resolved` owns `127.0.0.53:53` on most modern distros. Either:

- disable the stub listener in `/etc/systemd/resolved.conf` (`DNSStubListener=no`), then
  `sudo systemctl restart systemd-resolved`, or
- run AdGuard's DNS on a different port (`ADGUARD_DNS_PORT=5353`) — but then your DHCP
  server has to hand out that port, which most can't.

Full detail: [04 — DNS](04-dns.md).

## Certificate warnings — and Vaultwarden refusing to work

You're in `TLS_MODE=internal` and haven't installed Caddy's root cert on this device.
That's the whole cause of both symptoms.

```bash
docker cp caddy:/data/caddy/pki/authorities/local/root.crt ./caddy-root.crt
```

Install it per platform: [19 — TLS](19-tls.md). iOS needs the extra
*Certificate Trust Settings* toggle — installing the profile alone isn't enough.

**If the browser shows a name-resolution error instead of a cert warning**, the problem is
DNS, not TLS: `*.home.arpa` isn't pointing at your host. Add the AdGuard rewrite or
`/etc/hosts` entry.

## `*.home.arpa` doesn't resolve

- Is AdGuard running and is your device using it for DNS? `nslookup homepage.home.arpa`
  should answer.
- Did you add the **wildcard** rewrite (`*.home.arpa`), not a single hostname?
- On a device with its own VPN or DoH (iOS private relay, Firefox DoH, Chrome secure DNS),
  your rewrite can be bypassed. Disable DoH for the LAN.

## Can't reach qBittorrent / Radarr / Sonarr from another container

This is the single most common media-stack mistake. Those services run in
**gluetun's network namespace** (`network_mode: service:gluetun`), so:

| From | Use |
|---|---|
| inside that namespace (the app itself) | `localhost:<port>` |
| another container on the same Docker network | `gluetun:<port>` |
| outside the container — browser, Caddy | `<host-ip>:<port>` |

Using `<host-ip>` from a *sibling container* hairpins through gluetun's firewall and gets
`Connection reset by peer`. See [06 — Media stack](06-media-stack.md).

## Impersonation error / `permission denied` on the Docker socket

Running `docker` as a non-root user without group membership:

```bash
sudo usermod -aG docker "$USER"   # then log out and back in
```

`install.sh` itself needs `sudo` — it creates directories under `DATA_DIR` and runs compose.

## `docker compose` not found

You have the old v1 `docker-compose` binary. Install the **Compose v2 plugin** — every
script here calls `docker compose` (space, not hyphen).

## Everything is up but a service 502s through Caddy

Caddy proxies to `HOST_IP:<port>`. If `HOST_IP` in `.env` is stale (the machine's IP
changed), every site block points at nothing.

```bash
grep HOST_IP .env          # must be this machine's current LAN IP
ip -4 addr show | grep inet
./install.sh --services=caddy   # re-render after fixing
```

## A service doesn't come back after reboot

Compose sets `restart: unless-stopped`, which survives reboots **as long as Docker itself
starts on boot**:

```bash
sudo systemctl is-enabled docker
```

`hermes` is the exception — it's a systemd unit, so check
`systemctl status hermes`.

## Immich or Jellyfin is using all the RAM

- Immich ML indexing is the usual culprit: it runs on CPU without a GPU and is deliberately
  greedy. Let it finish, or set `GPU_MODE` if you have one.
- Jellyfin: check whether it's **transcoding**. If the client can direct-play, transcoding
  should stop. See the audio-track note in [07 — Jellyfin](07-jellyfin.md).
- Check the actual numbers: `docker stats --no-stream`.

## Disk full

Most common: Jellyfin/qBittorrent downloads, or Immich thumbnails, or unbounded container
logs.

```bash
df -h; du -sh ${DATA_DIR}/* | sort -h | tail
docker system df
```

Retention for backups is in `.env` (`BACKUP_DAILY/WEEKLY/MONTHLY`); media and photos have
no retention by design — that's yours to manage.

## Homepage loads but says "Host validation failed"

Homepage refuses hostnames not in `HOMEPAGE_ALLOWED_HOSTS`. Set it to your hostname (or
`*` on a trusted LAN) in `.env` and restart the container.

## `install.sh` says a required variable is missing

That's the design — `${VAR:?set in .env}` fails loudly instead of booting with a default.
Add the missing variable to `.env`. The error names it.

## I changed `.env` and nothing happened

Compose reads `.env` at container start. Most changes need a recreate:

```bash
cd services/<name> && docker compose up -d --force-recreate
# or
./manage.sh restart <name>
```

Changing `TLS_MODE` or adding modules also needs the Caddyfile regenerated:
`./install.sh --services=caddy`.

---

## Still stuck?

Collect this and you'll usually spot it yourself:

```bash
./manage.sh status > /tmp/sbp-debug.txt 2>&1
docker ps -a >> /tmp/sbp-debug.txt
docker compose version >> /tmp/sbp-debug.txt
grep -vE '(PASSWORD|TOKEN|KEY|SECRET)=' .env >> /tmp/sbp-debug.txt
```

That last line strips secrets before you share it — don't skip the `grep -v`.