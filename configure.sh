#!/usr/bin/env bash
# configure.sh — interactively scaffold a .env from templates/env.example.
# Copies only the "required" placeholders, prompting for values where helpful.
# Never writes secrets you don't explicitly type — and .env is git-ignored.

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/common.sh"
source "$SCRIPT_DIR/lib/detect.sh"

ENV_SRC="$SCRIPT_DIR/templates/env.example"
ENV_DST="$SCRIPT_DIR/.env"

# --- safe detection so defaults are sensible -------------------------------
detect_all
HOST_IP_SUGGEST="$(hostname -I 2>/dev/null | awk '{print $1}')"

if [ -f "$ENV_DST" ]; then
  log_warn ".env already exists at $ENV_DST"
  confirm "Overwrite it (your values will be replaced)? " && cp "$ENV_SRC" "$ENV_DST" || die "Aborted."
else
  cp "$ENV_SRC" "$ENV_DST"
  log_info "Created $ENV_DST from template."
fi

# --- prompt for the most important values ----------------------------------
echo
log_step "Setting key values (you can edit .env later for the rest)"
replace_var() { # key, value
  sed -i "s|^$1=.*|$1=$2|" "$ENV_DST"
}

val="$(prompt_default "Public domain (blank for LAN-only)" "${APP_DOMAIN:-}")"; replace_var APP_DOMAIN "$val"
echo "  TLS_MODE=none     — plain HTTP. Fastest, but Vaultwarden will not work."
echo "  TLS_MODE=internal — Caddy local CA, https://<svc>.home.arpa. No domain needed. (recommended)"
echo "  TLS_MODE=dns01    — wildcard cert via Cloudflare. Needs the domain above."
val="$(prompt_default "TLS mode (none|internal|dns01)" "internal")";          replace_var TLS_MODE "$val"
val="$(prompt_default "Host LAN IP" "${HOST_IP_SUGGEST:-}")";               replace_var HOST_IP "$val"
val="$(prompt_default "LAN subnet/CIDR" "${LAN_SUBNET:-}")";                replace_var LAN_SUBNET "$val"
val="$(prompt_default "Timezone" "${TZ:-UTC}")";                            replace_var TZ "$val"
val="$(prompt_default "Storage backend (zfs|dir)" "$STORAGE_DETECT")";       replace_var STORAGE_TYPE "$val"
val="$(prompt_default "Data directory" "${DATA_DIR:-/srv/selfhost}")";      replace_var DATA_DIR "$val"
val="$(prompt_default "GPU mode (auto|nvidia|intel|none)" "${GPU_MODE:-auto}")"; replace_var GPU_MODE "$val"

echo
log_ok "Configured. Review $ENV_DST, fill in required secrets (tokens, DB passwords), then run: ./install.sh --list"
