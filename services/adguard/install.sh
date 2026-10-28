#!/usr/bin/env bash
# install.sh — AdGuard Home (local DNS / ad-blocking)
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
source "$SCRIPT_DIR/lib/common.sh"; source "$SCRIPT_DIR/lib/detect.sh"; source "$SCRIPT_DIR/lib/storage.sh"
load_env; require_docker; ensure_storage
provision_storage adguard >/dev/null
cd "$SCRIPT_DIR/services/adguard"
docker compose up -d
log_ok "AdGuard Home installed. Open its admin UI after fill-in: http://<host>:${ADGUARD_HTTP_PORT:-3000}"
log_info "Now create the DNS rewrites for your services in the AdGuard UI — see docs/04-dns.md"
