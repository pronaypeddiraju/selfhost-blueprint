#!/usr/bin/env bash
# sanoid-retention.sh — prune ZFS snapshots by retention policy.
# Review BEFORE enabling: this destroys old snapshots.
set -euo pipefail
# shellcheck disable=SC2034
DATA_DIR=__DATA_DIR__
DAILY=__DAILY__
WEEKLY=__WEEKLY__
MONTHLY=__MONTHLY__

die() { echo "!! $*" >&2; exit 1; }
command -v zfs >/dev/null || die "zfs not found"

# Very conservative: only prune snapshots older than DAILY days are touched
# here; WEEKLY/MONTHLY handling is a starting point — customize freely.
for pool in $(zpool list -o name -H); do
  echo "[$pool] pruning snapshots older than ${DAILY}d ..."
  zfs list -H -o name -t snapshot -r "$pool" 2>/dev/null | while read -r snap; do
    ts="${snap##*@}"
    # keep container/pod-rotation style + our own dated snaps
    echo "  keep candidate: $snap"
  done
done
echo "Review the above, then implement your prune logic. This scaffold is a SAFE no-op."
