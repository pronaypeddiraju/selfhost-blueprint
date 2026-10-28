# 17 — Scrutiny (disk health)

SMART monitoring with history, so a failing disk warns you weeks before it dies.

- **Port** `8081` · **RAM** ~100 MB · **Config** `${DATA_DIR}/scrutiny/`

## Why it's worth 100 MB

Every "my homelab lost my data" story has the same shape: a disk was reporting
reallocated sectors / pending sectors for weeks, and nobody looked. Scrutiny looks, keeps
the trend, and puts it on one page.

## How it works

The **omnibus** image runs three things in one container: a collector (reads SMART via
`smartctl`), the web UI, and an embedded InfluxDB for history.

It needs raw device access:

```yaml
devices_mount:
  - /dev:/dev:ro        # read-only; enough to read SMART
cap_add:
  - SYS_RAWIO
```

That's broad. **Narrow it once you know your disks** — replace the `/dev` mount with the
specific devices:

```yaml
    volumes:
      - /dev/sda:/dev/sda
      - /dev/sdb:/dev/sdb
```

## First run

- Takes a few minutes to appear. Devices show up under the web UI automatically.
- **NVMe** should work out of the box. **USB-attached** disks often don't — many USB-SATA
  bridges don't pass SMART through (`smartctl -d sat` may be needed, which the collector
  doesn't always guess).
- If a disk shows "unknown", it's almost always the bridge, not Scrutiny.

## Run the collector on the host instead

Scrutiny can split into a web container plus a host-side collector — useful if you don't
want `/dev` in a container at all. Not wired up in this module; the omnibus form is what's
tested.

## Reading it

- **Green:** attributes within historical norms.
- **Yellow:** a value is trending wrong (e.g. reallocated sectors > 0, or temperature
  climbing).
- **Red:** back up *now* and plan a replacement.

Don't wait for red on a disk holding data you can't re-download.

## Troubleshooting

- **No devices listed** → `/dev` mount didn't land, or the host has no SMART-capable disks.
  Check `docker logs scrutiny`.
- **"command not found: smartctl"** → you're using the slim image, not `-omnibus`.
- **Permission denied reading a device** → the container needs `SYS_RAWIO`; some hardened
  hosts also need the container to run privileged.