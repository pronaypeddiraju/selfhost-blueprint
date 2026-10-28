# 02 — Quickstart

Bare machine to a running, HTTPS-reachable stack in about 20 minutes.

## 0. Before you start (2 min)

- Machine has a **static IP / DHCP reservation** — note it down (e.g. `192.168.1.50`).
- Ports **80** and **443** are free. `ss -tlnp | grep -E ':(80|443) '` shows any squatter.
- You can `sudo` on the box.

## 1. Get the code

```bash
git clone <this-repo-url> selfhost
cd selfhost
```

## 2. Bootstrap (5 min)

```bash
./bootstrap.sh
```

It will:
1. sanity-check the machine (OS, RAM, free disk, Docker/Compose)
2. offer to install Docker if missing — nothing is installed without asking
3. run `configure.sh` to write your `.env`
4. offer a profile (`minimal` / `photos` / `media` / `everything`) and install it

Prompts you'll be asked, and what to answer:

| Prompt | Answer |
|---|---|
| Public domain | **leave blank** unless you're doing `TLS_MODE=dns01` |
| TLS mode | **`internal`** (default) — real HTTPS on your LAN, no domain |
| Host LAN IP | the machine's IP from step 0 |
| LAN subnet | e.g. `192.168.1.0/24` |
| Timezone | `America/New_York`, `Europe/London`, … |
| Storage backend | `dir` on a laptop/spare box; `zfs` only on Proxmox |
| Data directory | `/srv/selfhost` is a good default |

## 3. Point DNS at it (2 min)

With `TLS_MODE=internal` the services live at `*.home.arpa`. Either:

**a) Use AdGuard (recommended — it's already installed):** AdGuard admin → *Filters* →
*DNS rewrites* → add `*.home.arpa` → `<your host IP>`.

**b) Or skip DNS:** add lines to `/etc/hosts` on the machine you're browsing from:

```
192.168.1.50  homepage.home.arpa adguard.home.arpa vault.home.arpa jellyfin.home.arpa
```

## 4. Trust the cert (3 min, once per device)

`internal` mode uses Caddy's own CA, so each device needs its root certificate — otherwise
you get scary warnings (and Vaultwarden won't work).

```bash
# on the server, copy the root cert somewhere you can fetch it
docker cp caddy:/data/caddy/pki/authorities/local/root.crt ./caddy-root.crt
```

- **Linux:** copy to `/usr/local/share/ca-certificates/` then `sudo update-ca-certificates`
- **Windows:** double-click → *Install Certificate* → *Local Machine* → *Trusted Root*
- **macOS:** Keychain Access → *System* → drag it in → set to *Always Trust*
- **iOS:** AirDrop it → Settings → *Profile Downloaded* → Install → then
  *General → About → Certificate Trust Settings* → enable full trust
- **Android:** Settings → Security → Encryption & credentials → Install a certificate → CA

Full walkthrough: [19 — TLS modes](19-tls.md).

## 5. Log in and change every default password

Open `https://homepage.home.arpa`. The dashboard has tiles for what you installed; each
tile links to its service.

Then work through [80 — Security](80-security.md) — every service that ships with a
default admin, and what to set it to, is listed there.

## 6. Manage it

```bash
./manage.sh status          # what's up
./manage.sh restart immich  # one service
./manage.sh logs caddy      # tail logs
./manage.sh down            # stop everything (keeps data)
```

## Where to go next

- **Add a module later:** `./install.sh --services=mealie` — it re-renders the Caddyfile.
- **Turn on the media stack:** set your VPN + indexer values in `.env`, then
  `./install.sh --profile=media`. Read [06 — Media stack](06-media-stack.md) first.
- **Backups:** confirm the `backups` module is running and **actually restore one file**
  — [10 — Backups](10-backups.md).
- **Broken?** [90 — Troubleshooting](90-troubleshooting.md) covers the top failures.

## The Proxmox path

If you'd rather isolate each module in its own LXC on a Proxmox host, read
[03 — Proxmox baseline](03-proxmox-baseline.md). ⚠️ **Experimental in v1.0** — the LXC
scripts have not been validated against a fresh Proxmox host yet. The single-machine path
above is the supported one.