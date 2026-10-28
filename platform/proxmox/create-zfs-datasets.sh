#!/usr/bin/env bash
# create-zfs-datasets.sh — create the ZFS dataset tree the services expect.
# Usage: PLATFORM_POOL=yourpool ./create-zfs-datasets.sh
set -euo pipefail
PLATFORM_POOL="${PLATFORM_POOL:?set PLATFORM_POOL to your ZFS pool (e.g. tank)}"
command -v zfs >/dev/null || { echo "zfs not found"; exit 1; }

DATASETS=(data immich backups appdata media downloads)
for ds in "${DATASETS[@]}"; do
  if zfs list -o name -H "$PLATFORM_POOL/$ds" >/dev/null 2>&1; then
    echo "exists: $PLATFORM_POOL/$ds"
  else
    zfs create -o recordsize=1M "$PLATFORM_POOL/$ds"
    echo "created: $PLATFORM_POOL/$ds (recordsize=1M)"
  fi
done
echo "Done. Mountpoints live under /$PLATFORM_POOL/<name>."
