# 16 — SilverBullet (personal knowledge base)

A self-hosted note-taking app where **every page is a plain `.md` file on disk**.
No proprietary database or exporter-to-own — your vault is a directory of
Markdown you can grep, git, diff, and open in Obsidian/vim on day one.

Install: `./install.sh --services=silverbullet` (Docker).

## What it does
One container (`zefhemel/silverbullet`). The vault is bind-mounted:
`${DATA_DIR}/silverbullet:/space` (i.e. `templates/env.example` →
`DATA_DIR`). Pages you create in the web UI appear as files there immediately.

The only login is `SB_USER`, formatted `username:password` (set
`SILVERBULLET_USER` in `.env`). There is no multi-user story to speak of — it's
a single-space app.

## Pitfalls that bit us
- **`SB_SHELL_BACKEND=off` matters.** SilverBullet exposes a "shell" feature
  that runs arbitrary commands on the host. We set it `off` — unless you
  genuinely need it, leave it off; it's a large security surface for a personal
  notes box.
- **Don't chown the vault files, chown the *container's view* of them.** The
  service runs as a non-root user inside the container; if you write files into
  the vault from the host/root and set restrictive ownership, the web editor
  can't save them. Keep the bind-mount tree writable by the app user (in our
  homelab the files are owned by the mapped UID, and host-side writes `chown`
  to that same UID so the editor can keep editing).
- **Grep-ability is the superpower.** Because the vault is real Markdown, you
  can answer "what did we decide about X?" with a plain `grep -ri X <vault>` —
  no API needed. That's the whole reason to prefer this over a DB-backed wiki.

## Backups
Nothing special: the bind mount is just files. Include `${DATA_DIR}/silverbullet`
in your snapshot / directory-backup scope (docs/10).
