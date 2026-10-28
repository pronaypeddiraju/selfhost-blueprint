# Changelog

All notable changes to this blueprint. Versions are git tags; this file is the human
summary.

## v1.0.0 — first public release

**Scope.** 14 modules in three tiers, built for a **single spare Linux machine** with
Docker. This is a deliberate narrowing of the private upstream this was extracted from.

### Added
- `bootstrap.sh` — machine sanity check, Docker install offer, `.env` generation, profile
  picker, install. One command from bare box to running stack.
- **Profiles:** `minimal`, `photos`, `media`, `everything`, plus explicit `--with-advanced`.
- **Tiered module list** in `install.sh --list`, with Tier 3 (advanced) never installed
  implicitly.
- **`TLS_MODE` ladder** — `none` / `internal` (default) / `dns01`. `internal` gives real
  HTTPS on a LAN with **no domain purchase** (Caddy local CA, `*.home.arpa`).
- **Caddyfile is now generated** from the modules you actually installed, instead of a
  commented-out skeleton.
- Modules: **`homepage`** (dashboard) and **`scrutiny`** (disk health).
- **Author-identifier denylist** in `check-secrets.sh` — a tripwire, not a one-time scan.
- Docs: `01-requirements`, `02-quickstart` (single-machine, 20 min), `19-tls`,
  `20-service-catalog`, `80-security`, `90-troubleshooting`, `17-scrutiny`, `21-homepage`.

### Removed
- **Finance** (`actual`, `ghostfolio`, `actual-ai`) — out of scope for this repo.
- **`frigate`** — needs cameras and storage; revisit in a later release.
- **`paperless`** — five containers, disproportionate support surface.
- **`lore`** — niche VCS, the only non-HTTP module.
- All references to the above from scripts, docs, `.env`, and CI.

### Changed
- `docs/03-proxmox-baseline.md` is now explicitly **experimental** and untested in v1.0;
  the Proxmox module still ships but is not part of the validation matrix.
- `install.sh` treats the tier list as a support contract, not a ranking.
- `configure.sh` prompts for `TLS_MODE` and warns that `none` breaks Vaultwarden.
- README rewritten as a front door: hardware floor, 3-command quickstart, what's in/out of
  scope, and the legal note for the media stack.

### Known limitations
- **`media` and `photos` profiles were not installed during validation** — `media-stack`
  requires a real WireGuard VPN subscription, so only its compose file is validated.
  `minimal` is the validated path.
- Proxmox LXC scripts unvalidated (see above).
- `internal` TLS requires installing a root cert per device.
- No single-sign-on / forward-auth.
- No offsite backup automation (the `backups` module is local; ship a copy elsewhere
  yourself).
- Image tags are pinned at release time and are not auto-bumped.

### Validation (Phase 3, 2026-10-28)
Run on a **fresh Debian 13 container** (2 vCPU / 2 GB / 8 GB disk, Docker 29.9.2,
Compose v5.6.1) as the "spare machine" proxy:

| Step | Result |
|---|---|
| `./install.sh --profile=minimal` from a wiped state | ✅ 5 containers up, 4 Caddy site blocks |
| HTTPS via Caddy local CA (`internal` mode) | ✅ homepage 200, vaultwarden 200, uptimekuma 302, adguard 302; certs issued for all 4 |
| Cert generation | ✅ root + intermediate present in `/data/caddy/pki/authorities/local/` |
| `./manage.sh status` | ✅ correct output |
| **Reboot** (`pct reboot`) | ✅ all containers returned via `restart: unless-stopped`; HTTPS still 200 |
| `check-secrets.sh --all` | ✅ clean |
| All 12 compose files (`docker compose config -q`) | ✅ valid |
| All pinned digests resolvable (HUB / GHCR / LSCR) | ✅ |

**Three real bugs found and fixed by this test** — the reason the gate exists:
1. `HERMES_WHATSAPP_*=` in `templates/env.example` was not a valid shell assignment;
   sourcing `.env` aborted the whole install.
2. `vaultwarden` crash-looped: `DOMAIN=https://${APP_DOMAIN}` is empty without a public
   domain. Now derived from `TLS_MODE` (`public_url`) and written back to `.env`.
   `mealie`'s `BASE_URL` had the identical bug.
3. A per-site `import tls_policy` snippet only got a certificate for the **first** site
   block. Fixed by setting the policy globally (`local_certs` / `acme_dns` /
   `auto_https off`) — and by reloading Caddy after regeneration, since the container
   runs without `--watch` and never noticed the new file.

### Not included, by decision
Portainer · Honcho · open-webui · Fab claimer · IPTV/Dispatcharr · any app-store UI ·
any finance tooling.