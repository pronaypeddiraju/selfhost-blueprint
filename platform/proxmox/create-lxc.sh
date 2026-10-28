#!/usr/bin/env bash
# create-lxc.sh — create a Debian unprivileged LXC with Docker inside,
# bind-mounting a ZFS dataset for service data.
#
# Usage:
#   ./create-lxc.sh <pool> <vm_id> <name> <source_dataset> <mountpoint>
# Example:
#   ./create-lxc.sh mypool 110 media /mypool/media /var/lib/media
set -euo pipefail

# shellcheck disable=SC2034  # POOL documents the required pool arg (storage uses SRC path)
POOL="${1:?pool}"; VID="${2:?vm_id}"; NAME="${3:?name}"
SRC="${4:?source dataset path}"; MP="${5:?container mountpoint}"

command -v pct >/dev/null || { echo "pct not found — is this a Proxmox node?"; exit 1; }

TEMPLATE="debian-12-standard_12.2-1_amd64.tar.zst"   # adjust to a cached template
if ! pveam list local | grep -q "$TEMPLATE"; then
  echo "Template $TEMPLATE not cached. Downloading: pveam download local $TEMPLATE"
  pveam download local "$TEMPLATE" || exit 1
fi

# Ensure the bind source exists.
[ -d "$SRC" ] || { echo "Bind source $SRC missing — create datasets first."; exit 1; }

pct create "$VID" "local:vztmpl/$TEMPLATE" \
  --hostname "$NAME" \
  --cores 2 --memory 2048 --swap 512 \
  --storage local-lvm \
  --rootfs local-lvm:8 \
  --net0 name=eth0,bridge=vmbr0 \
  --features nesting=1 \
  --unprivileged 1 \
  --mp0 "$SRC,mp=$MP"

echo "Starting container ..."
pct start "$VID"
echo "Installing Docker inside ..."
pct exec "$VID" -- bash -c 'apt-get update && apt-get install -y docker.io docker-compose-v2'
echo "Done. chown the bind mount host-side for the container's shifted uid, then run ./install.sh inside."
