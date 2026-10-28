#!/usr/bin/env bash
# install.sh — Vaultwarden (self-hosted password manager).
#
# Vaultwarden refuses to start without a valid DOMAIN (full URL, with protocol),
# and it must match how you actually reach it — so we derive it from TLS_MODE
# rather than assuming you have a public domain.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
source "$SCRIPT_DIR/lib/common.sh"; source "$SCRIPT_DIR/lib/storage.sh"
load_env; require_docker; ensure_storage
provision_storage vaultwarden >/dev/null

URL="$(public_url vaultwarden "${VAULTWARDEN_HTTP_PORT:-8000}")"
export VAULTWARDEN_DOMAIN="$URL"
set_env_var VAULTWARDEN_DOMAIN "$URL"

cd "$SCRIPT_DIR/services/vaultwarden"
docker compose up -d
log_ok "Vaultwarden installed: $URL"
log_info "Create your account on first visit, then disable signups (docs/80-security.md)."
log_info "Optional admin panel: set VAULTWARDEN_ADMIN_TOKEN in .env and re-run this module."
if [ "${TLS_MODE:-internal}" = "none" ]; then
  log_warn "TLS_MODE=none: Vaultwarden will start but the web vault cannot work without HTTPS."
fi