#!/usr/bin/env bash
# tar-backup.sh — nightly tar backup of DATA_DIR to BACKUP_DIR with rotation.
set -euo pipefail
DATA_DIR=__DATA_DIR__
BACKUP_DIR=__BACKUP_DIR__
KEEP=7

stamp="$(date +%Y%m%d-%H%M%S)"
out="$BACKUP_DIR/data-$stamp.tar.gz"
mkdir -p "$BACKUP_DIR"
tar -czf "$out" -C "$(dirname "$DATA_DIR")" "$(basename "$DATA_DIR")"
# rotate: keep only latest $KEEP
ls -1t "$BACKUP_DIR"/data-*.tar.gz 2>/dev/null | tail -n +$((KEEP + 1)) | xargs -r rm -f
echo "Backup written: $out (retained $KEEP)"
