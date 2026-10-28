# 03 — Proxmox baseline (optional)

> ⚠️ **Experimental in v1.0.** The `platform/proxmox/` scripts (`create-lxc.sh`,
> `create-zfs-datasets.sh`) have **not** been validated against a fresh Proxmox host.
> Expect to debug them. The supported path is a single Linux machine — see
> [02 — Quickstart](02-quickstart.md).

For a dedicated home server, Proxmox VE + ZFS gives clean per-app isolation and
snapshot-based backups. This is **optional** — the `services/*` modules run the
same on plain Docker.

## Storage: host-managed ZFS + bind mounts

Create ZFS datasets for each service's data, then bind-mount them into an LXC:

```
platform/proxmox/create-zfs-datasets.sh   # create the dataset tree
platform/proxmox/create-lxc.sh pool vid name /path/dataset /container/mount
```

This keeps the data **on the host pool** (not inside the container), so ZFS
snapshots (`sanoid`) and host backups (`vzdump`) cover it.

## Critical gotchas (learned in production)

1. **Unprivileged LXC UID shifting.** Container-uid N maps to host-uid
   `100000+N`. A fresh bind-mount source is host-root-owned, so it appears as
   `nobody` inside the CT and even CT-root can't write. `chown` the source **on
   the host** to `100000+<container-uid>` first (e.g. `100000+1000=101000`,
   `100000+999=100999` — watch the arithmetic).
2. **Enable `nesting=1`** on a CT that will run Docker inside.
3. **Cap ZFS ARC** on the host (`/etc/modprobe.d/zfs.conf`) so ZFS doesn't eat
   all the RAM you'd rather give to guests. Tune to your hardware.
4. **GPU-passthrough CTs can fail after a kernel upgrade**: Docker/NVIDIA inside
   needs DKMS matching the *running* kernel. If a GPU container won't start
   after a reboot, check `dkms status` vs `uname -r`.
5. Watch **host RAM headroom.** VMs hard-reserve RAM; LXCs are caps. Keep some
   headroom or a memory-hungry guest can stall the host's storage layer.
