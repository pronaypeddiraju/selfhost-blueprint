#!/usr/bin/env bash
# install.sh — Backups & retention.
# - ZFS hosts: installs a snapshot-pruning script (sanoid-style) + optional
#   cross-host replication via zfs send.
# - Directory hosts: installs a simple tar + retention job.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
source "$SCRIPT_DIR/lib/common.sh"; source "$SCRIPT_DIR/lib/detect.sh"; source "$SCRIPT_DIR/lib/storage.sh"
load_env; require_root

detect_storage
BACKUP_DIR="${BACKUP_DIR:-$DATA_DIR/backups}"
mkdir -p "$BACKUP_DIR"

case "$STORAGE_DETECT:$STORAGE_TYPE" in
  zfs:*)
    log_step "ZFS detected — installing snapshot retention script"
    sed -e "s|__DATA_DIR__|$DATA_DIR|g" \
        -e "s|__DAILY__|${BACKUP_DAILY:-14}|g" \
        -e "s|__WEEKLY__|${BACKUP_WEEKLY:-4}|g" \
        -e "s|__MONTHLY__|${BACKUP_MONTHLY:-6}|g" \
        "$SCRIPT_DIR/templates/systemd/sanoid-retention.sh" \
        > /usr/local/bin/selfhost-retention.sh
    chmod +x /usr/local/bin/selfhost-retention.sh
    log_info "Template installed at /usr/local/bin/selfhost-retention.sh — review, then add to cron."
    ;;
  *)
    log_step "Directory storage — installing tar backup script"
    sed -e "s|__DATA_DIR__|$DATA_DIR|g" \
        -e "s|__BACKUP_DIR__|$BACKUP_DIR|g" \
        "$SCRIPT_DIR/templates/systemd/tar-backup.sh" \
        > /usr/local/bin/selfhost-tar-backup.sh
    chmod +x /usr/local/bin/selfhost-tar-backup.sh
    log_info "Template installed. Add to cron, e.g.:"
    echo "  0 3 * * * /usr/local/bin/selfhost-tar-backup.sh"
    ;;
esac
log_ok "Backups configured. See docs/10-backups.md"
