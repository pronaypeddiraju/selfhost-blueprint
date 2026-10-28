#!/usr/bin/env bash
# install.sh — Uptime Kuma (uptime monitoring + status page)
# NOTE: this installs the Docker variant (portable). Our homelab runs it
# natively via systemd — see docs/14-uptimekuma.md for the native option.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
source "$SCRIPT_DIR/lib/common.sh"; source "$SCRIPT_DIR/lib/storage.sh"
load_env; require_docker; ensure_storage
provision_storage uptimekuma >/dev/null

cd "$SCRIPT_DIR/services/uptimekuma"
docker compose up -d
log_ok "Uptime Kuma installed: http://<host>:${UPTIMEKUMA_HTTP_PORT:-3001}"
log_info "Create your admin account on first visit, then add monitors + a notification channel."
