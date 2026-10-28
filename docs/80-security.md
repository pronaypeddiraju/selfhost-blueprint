# 80 — Security checklist

Do this **before** you put real data on the stack. It takes 15 minutes.

---

## Threat model, honestly stated

This blueprint assumes: *the machine is on your own LAN, and the people on that LAN are
people you trust.* It is not hardened for a shared/guest/corporate network, and it is not
hardened for direct internet exposure.

What it **is** built for: not leaking your credentials, not shipping default passwords, and
not quietly opening ports.

What it is **not**: a defence against a hostile device on your own network. Anyone who can
reach `http://<host>:<port>` can see that service's login page. If that's unacceptable,
segment the network — don't expect the compose files to do it.

---

## 1. First-boot passwords — do these now

Every service below starts with either no auth or a well-known default. Change it the
first time you log in.

| Service | What to do |
|---|---|
| **AdGuard** | Set admin username + a strong password on first visit. Do not leave the setup page reachable. |
| **Vaultwarden** | Create your account **immediately** (first account is the admin), then set `SIGNUPS_ALLOWED=false` and restart. |
| **Jellyfin** | First-run wizard → create the admin account → *Dashboard → Users* to add others. Disable "allow remote connections" if LAN-only. |
| **Immich** | First-run admin signup → *Administration → Settings* → disable new signups once your household is in. |
| **Mealie** | First-run signup becomes admin. Then turn off open registration. |
| **Uptime Kuma** | Create the admin account on first visit. Leave no unauthenticated monitor dashboard. |
| **FileBrowser** | Change the default admin password, or create a new admin and delete `admin`. |
| **SilverBullet** | Auth is a single `user:password` in `.env` — set something long, and restart after changing. |
| **Homepage** | No auth at all. Treat the dashboard as public-to-your-LAN. |
| **Scrutiny** | No auth by default. LAN only. |
| **qBittorrent** | Change the temp/admin password. The default is a known one. |
| **Hermes** | **`TELEGRAM_ALLOWED_USERS` must be set before first start.** A bot token without an allowlist is an open shell for whoever finds the bot. |

## 2. Secrets model

- **Everything lives in `.env`.** It is git-ignored and mode 600. Never commit it, never
  paste it into a chat, never put it in a compose file.
- Required secrets use `${VAR:?set in .env}` — a missing one **fails the install loudly**
  rather than quietly booting with a default.
- Generate random values with `openssl rand -base64 24` (or `-hex 32`).
- **`./check-secrets.sh` before every commit.** It scans tracked files for token patterns,
  high-entropy strings, non-private IPs, and your personal identifier denylist.
- **Put your identifiers in `check-secrets.denylist`** (`cp check-secrets.denylist.example
  check-secrets.denylist`). It's git-ignored on purpose: the list of your hostnames and
  surnames must not be committed, or the tripwire becomes the leak. Patterns are `grep -E`,
  case-insensitive — add your domain, host nicknames, usernames, pool names, tailnet ID,
  surnames, and your real LAN subnet.
- If a secret ever does land in Git: rotate it first, *then* clean history
  (`git filter-repo`). Rotating is the part that actually matters — the leaked value is
  already public.

## 3. Exposure rules

- **No inbound ports. Ever.** Nothing in this repo needs one. `dns01` TLS uses DNS-01
  challenges, not inbound HTTP.
- **Remote access = private network.** Tailscale or WireGuard to the machine, then browse
  the service normally. Port-forwarding a self-hosted app is how home labs end up in
  botnet scans within hours.
- **`0.0.0.0` binds are LAN-wide, not localhost.** Every published port in these compose
  files is reachable from anything on your network. To restrict one, bind it to
  `127.0.0.1` and reach it through Caddy only.
- **A firewall is not included.** If you want one, that's your host's job (`ufw`, `nft`).
  The blueprint deliberately doesn't fight your OS's firewall.

## 4. Privileges you're granting

Know what each module can do beyond serving a web page:

- **`homepage`** mounts `/var/run/docker.sock` read-only. Read-only still exposes a lot of
  host metadata, and a compromise of that container is a compromise of your Docker
  control plane. Don't expose Homepage publicly.
- **`scrutiny`** gets `/dev` (read-only) and `SYS_RAWIO` to read SMART data. Narrow the
  `/dev` mount to your actual disks.
- **`hermes`** is an **agent with shell access by design**. That's the feature. It means:
  allowlist your own user ID, use a dedicated bot, and don't hand the same bot to people
  you don't trust with your server.
- **`media-stack`** runs qBittorrent as a non-root user inside the container; downloads
  land wherever you mounted them. Keep that path out of anything else's writable scope.

## 5. Updates

- **Image tags are pinned.** Nothing silently upgrades under you. That's a security
  property *and* a maintenance obligation: you have to upgrade deliberately.
- Before upgrading a major version of anything that stores data (Immich, Vaultwarden,
  Mealie), **take a backup and read the upstream release notes**. Immich in particular has
  had breaking schema migrations.
- `./manage.sh update` (where supported) pulls and recreates; check `./manage.sh status`
  after.

## 6. Backups are a security control

Ransomware and fat-fingers are indistinguishable from the outside. The `backups` module is
in every profile for a reason.

- Confirm it's actually running: `./manage.sh status backups` and look at the target
  directory.
- **Restore one file.** A backup you've never restored is a hope, not a backup.
  See [10 — Backups](10-backups.md).
- Keep one copy **off this machine**. Same-disk backups don't survive disk failure.

## 7. If something looks wrong

```bash
docker ps --format '{{.Names}}\t{{.Status}}\t{{.Ports}}'   # what's actually listening
ss -tlnp                                                    # host-level listeners
docker logs --tail 50 <container>                           # what it's saying
./check-secrets.sh --all                                    # did something leak?
```

Unexpected inbound connections, a container you didn't install, or a service suddenly
reachable from outside your LAN are all "shut it down and investigate" events.