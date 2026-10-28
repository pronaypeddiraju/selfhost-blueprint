#!/usr/bin/env bash
# manage.sh — start / stop / restart / status for installed services.
#
# Usage:
#   ./manage.sh status [service...]     default: all
#   ./manage.sh start <service...>
#   ./manage.sh stop  <service...>
#   ./manage.sh restart <service...>

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/common.sh"

ACTION="${1:-status}"; shift || true
SERVICES_DIR="$SCRIPT_DIR/services"

[ "$ACTION" = status ] || [ -n "${1:-}" ] || { log_err "Provide service name(s) for '$ACTION'."; exit 1; }

# Default to all services for status.
if [ "$ACTION" = status ] && [ $# -eq 0 ]; then
  if command -v docker >/dev/null 2>&1; then
    docker ps --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}' 2>/dev/null || true
    exit 0
  else
    log_warn "Docker not detected; showing nothing."
    exit 0
  fi
fi

for svc in "$@"; do
  dir="$SERVICES_DIR/$svc"
  [ -d "$dir" ] || { log_warn "No service module: $svc"; continue; }
  if [ -f "$dir/compose.yaml" ]; then
    log_step "$svc — $ACTION"
    (cd "$dir" && docker compose "$ACTION")
  else
    log_warn "$svc has no compose.yaml; skipping."
  fi
done
log_ok "Manage complete."
