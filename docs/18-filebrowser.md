# 18 — FileBrowser (web file manager)

A lightweight, single-binary web file manager. Point it at any folder on the
host and browse/upload/download from a browser — useful when you want read/write
or read-only access to data directories (media, document consume folders, a
knowledge vault) without shelling in.

Install: `./install.sh --services=filebrowser` (Docker).

## What it does
One container (`filebrowser/filebrowser`). The `command` sets the browse root to
`/data`, and the `volumes` bind whatever host folders you want exposed under
`/data/<name>`. Edit `compose.yaml` to adjust the map; mark anything sensitive
`:ro` (read-only) so a UI mistake can't destroy data:

```yaml
volumes:
  - ${DATA_DIR}/media:/data/media:ro          # read-only
  - ${DATA_DIR}/documents:/data/documents     # writable (drop files in)
```

The app DB (users, prefs) is the only state FileBrowser owns — it lives in
`${DATA_DIR}/filebrowser/db/filebrowser.db`. It's not worth much to back up
(recreatable), but it's tiny so no harm including it.

## Pitfalls that bit us
- **First-run default is admin/admin.** On first boot the UI logs in as
  `admin`/`admin`. **Change it immediately** — FileBrowser is a chokepoint onto
  your data. If you expose it beyond LAN, put it behind the reverse proxy with
  auth (see docs/05) and never the default creds.
- **The `--root /data` + volume mapping is the whole config.** There's no
  per-folder ACL UI; a bind mount is either fully visible (and `:ro` or not).
  Design your volume list as your permission model.
- **Don't bind the container's own data dir into `/data`.** Keep `/database`
  for the app DB and reserve `/data` for the folders you actually want to
  browse, or the UI shows its own internals.

## When to use it vs SMB/NFS
FileBrowser is great for occasional browser access and giving a non-technical
person a URL. If you need to mount shares from your OS, you want SMB/NFS —
see docs/10 for the backup-share pattern.
