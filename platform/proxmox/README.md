# Proxmox platform module (optional)

This module is **only for people running Proxmox VE** who want the full
home-server experience: ZFS datasets + unprivileged LXC containers with bind
mounts. On a laptop or plain Linux server you don't need any of this — the
`services/*` modules run on Docker directly.

## Why containers?

Each service lives in its own unprivileged LXC with storage bind-mounted from a
ZFS dataset. This gives clean isolation per app, host-managed ZFS snapshots for
backups, and easy whole-guest backup with `vzdump`.

## Files

- `create-zfs-datasets.sh` — create the dataset tree under a pool.
- `create-lxc.sh` — create one unprivileged LXC with Docker + a bind mount.

## Typical flow

```bash
# 1. Create the ZFS dataset tree (adjust pool + paths first)
PLATFORM_POOL=yourpool bash platform/proxmox/create-zfs-datasets.sh

# 2. Create an LXC running Docker, then install services inside it
bash platform/proxmox/create-lxc.sh yourpool guestid your-lxc-name
```

Then, inside the LXC, run `./install.sh --services=...` for the apps you want.

## Notes / caveats

- Unprivileged LXCs map container UIDs to host UIDs with an offset; a
  bind-mount source must be `chown`ed on the **host** to the expected shifted
  UID (`100000 + <container-uid>`) before the container user can write to it.
- Enable `nesting=1` on a container if you'll run Docker-in-LXC.
- ZFS ARC is capped on the host (e.g. via `/etc/modprobe.d/zfs.conf`) to leave
  RAM for guests — tune to your hardware, this repo caps it by default.

See `docs/02-proxmox-baseline.md` for the full worked example.
