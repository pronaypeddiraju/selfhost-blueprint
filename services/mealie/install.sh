#!/usr/bin/env bash
# install.sh — Mealie (self-hosted recipe manager + meal planner)
#
# Mealie bakes BASE_URL into invite links and redirects, so it has to match how
# you actually reach it. Derived from TLS_MODE, like Vaultwarden's DOMAIN.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
source "$SCRIPT_DIR/lib/common.sh"; source "$SCRIPT_DIR/lib/storage.sh"
load_env; require_docker; ensure_storage
require_var MEALIE_SECRET
provision_storage mealie >/dev/null

URL="$(public_url mealie "${MEALIE_HTTP_PORT:-9925}")"
export MEALIE_BASE_URL="$URL"
set_env_var MEALIE_BASE_URL "$URL"

cd "$SCRIPT_DIR/services/mealie"
docker compose up -d
log_ok "Mealie installed: $URL"
log_info "First account created in the web UI becomes the admin."
log_info "If you change TLS_MODE later, re-run: ./install.sh --services=mealie"