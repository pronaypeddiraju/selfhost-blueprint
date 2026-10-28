# 10 — Backups

Three complementary layers. Install the automation with
`./install.sh --services=backups` (it detects ZFS vs directory).

## 1. Snapshots (ZFS) — `sanoid`/pruning

On ZFS, take regular snapshots and prune by retention (`BACKUP_DAILY/WEEKLY/
MONTHLY` in `.env`). The installed `/usr/local/bin/selfhost-retention.sh` is a
**safe scaffold** — review and fill in your prune logic before enabling in cron.
Datasets with lots of derived/cached data (e.g. photo ML thumbnails) get shorter
retention than precious data.

## 2. Container/config backups — `vzdump` (Proxmox)

`vzdump` dumps whole guests nightly. Keep the container **configs** too — they
are cheap and worth more than they seem (especially for a service whose config
is the real asset).

## 3. Cross-host replication — `zfs send`

Optional. Replicate precious datasets to a **second machine** periodically
(`zpool send` / `syncoid`). Replication is a great safety net as long as you
**actually test a restore** at least once — a replica you've never restored
isn't proven.

## Honest caveat

Local snapshots + same-building replication all fail together if the building
does. This blueprint ships **no offsite backup** by default — if your data
matters, add one (backup to a remote/cloud target). And remember: **recordings
of camera footage are high-churn and usually re-acquirable — don't burn backup
budget on them; their *config* is the thing worth protecting.**
