#!/usr/bin/env bash
# install.sh — Scrutiny (drive health / SMART monitoring)
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
source "$SCRIPT_DIR/lib/common.sh"; source "$SCRIPT_DIR/lib/storage.sh"
load_env; require_docker; ensure_storage
provision_storage scrutiny >/dev/null

# Scrutiny needs raw block-device access to read SMART counters.
if [ ! -e /dev/sda ] && [ ! -e /dev/nvme0 ]; then
  log_warn "No /dev/sda or /dev/nvme0 found — Scrutiny may show no devices."
fi
log_info "Reads SMART via /dev (read-only) + SYS_RAWIO. Narrow the /dev mount in compose.yaml to your real disks."

cd "$SCRIPT_DIR/services/scrutiny"
docker compose up -d
log_ok "Scrutiny installed: http://<host>:${SCRUTINY_HTTP_PORT:-8081}"
log_info "First start takes a few minutes; disk list appears under the Web UI."