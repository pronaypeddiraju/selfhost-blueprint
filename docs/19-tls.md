# 19 — TLS modes

Caddy fronts every service. How it gets certificates is `TLS_MODE`, and it's the single
most consequential setting in your `.env`.

```
none | internal | dns01        # default: internal
```

---

## `none` — plain HTTP

Caddy proxies on port 80. No certificates, nothing to install.

- **Fastest way to see if the whole thing works.**
- **Vaultwarden does not work** in this mode: the web vault needs WebCrypto, which browsers
  only expose on secure origins, and Bitwarden mobile clients refuse plain HTTP.
- Passwords and session cookies cross your LAN in clear text.
- `Caddyfile` site blocks become `http://<svc>.home.arpa` and only work if DNS resolves and
  the browser doesn't force HTTPS.

Use it to debug, then switch away.

## `internal` — Caddy's own CA (default, recommended)

Caddy mints its own root CA and issues certs for `*.home.arpa` (RFC 8375 — reserved for
home networks, so it can never collide with a real domain).

- Real HTTPS, real hostnames, **no domain purchase, no Cloudflare account**.
- Nothing leaves your LAN. No inbound ports, no ACME traffic.
- **Cost:** you install Caddy's root certificate once on every device that browses the
  stack. Skip it and you get certificate warnings — and Vaultwarden refuses to work.

### Install the root cert

Get it off the server:

```bash
docker cp caddy:/data/caddy/pki/authorities/local/root.crt ./caddy-root.crt
```

Then per platform:

| Platform | Steps |
|---|---|
| **Linux** (Debian/Ubuntu) | `sudo cp caddy-root.crt /usr/local/share/ca-certificates/` then `sudo update-ca-certificates` |
| **Windows** | Double-click → *Install Certificate* → *Local Machine* → *Place in: Trusted Root Certification Authorities* |
| **macOS** | Open in Keychain Access → *System* keychain → drag in → double-click → *Trust: Always Trust* |
| **iOS/iPadOS** | AirDrop/AirDrop the file → Settings → *Profile Downloaded* → Install → then **General → About → Certificate Trust Settings** → toggle full trust |
| **Android** | Copy to device → Settings → Security → *Encryption & credentials* → *Install a certificate* → *CA certificate* |
| **Firefox** | Uses its own store: Settings → Privacy & Security → Certificates → *View Certificates* → Authorities → Import |

Verify: `curl -v https://homepage.home.arpa 2>&1 | grep -i 'SSL certificate verify'`
should say *ok*.

### DNS is the other half

`*.home.arpa` has to resolve. Either add a wildcard DNS rewrite in AdGuard
(*Filters → DNS rewrites* → `*.home.arpa` → host IP), or put entries in each client's
`/etc/hosts`. Without one of those, you'll get name-resolution errors, not TLS errors —
worth knowing the difference.

## `dns01` — public wildcard certificate

Caddy gets a real `*.yourdomain.com` wildcard from Let's Encrypt using a **Cloudflare
DNS-01** challenge. That means:

- **No inbound ports.** DNS-01 proves control by creating a TXT record, so this works
  behind CGNAT and with no port forwarding.
- **No cert installs** on any device, ever, and it works from any network — cellular
  included, once DNS points at you.
- **Needs:** `APP_DOMAIN` set to a domain you control, and `CLOUDFLARE_API_TOKEN` with
  `Zone:DNS:Edit` on that zone.

Site blocks become `https://<svc>.yourdomain.com`.

> **DNS still has to point at your host.** DNS-01 only issues the cert. You still need
> `*.yourdomain.com → <LAN IP>` (split-horizon DNS in AdGuard is the usual answer) or the
> names resolve to Cloudflare and nothing loads.

---

## Switching modes later

1. Edit `TLS_MODE` in `.env`.
2. Re-run `./install.sh --services=caddy` — it regenerates the Caddyfile.
3. If you moved *to* `internal`, install the root cert on your devices.
4. If you moved *away from* `internal`, the old root cert on your devices is now harmless
   but useless — you can remove it.

## What none of these modes do

- They don't expose anything to the internet. `dns01` is outbound-only.
- They don't authenticate users. Caddy has no login; authentication is each service's job
  (Vaultwarden's master password, Jellyfin users, etc.). If you want a single front-door
  login, that's a forward-auth setup — out of scope for v1.0.
- They don't make a service safe to expose publicly. Don't port-forward. Use Tailscale or
  WireGuard for remote access — see [80 — Security](80-security.md).