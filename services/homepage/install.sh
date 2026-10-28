#!/usr/bin/env bash
# install.sh — Homepage (the dashboard / front door for everything else)
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
source "$SCRIPT_DIR/lib/common.sh"; source "$SCRIPT_DIR/lib/storage.sh"
load_env; require_docker; ensure_storage
provision_storage homepage >/dev/null

# Seed the two files Homepage needs, without overwriting an existing setup.
CFG="$DATA_DIR/homepage/config"
mkdir -p "$CFG"
if [ ! -f "$CFG/settings.yaml" ]; then
  cat > "$CFG/settings.yaml" <<'YAML'
title: Home
theme: dark
color: slate
headerStyle: boxed
layout:
  Media:
    style: row
    columns: 3
  Services:
    style: row
    columns: 3
YAML
fi
if [ ! -f "$CFG/bookmarks.yaml" ]; then
  printf -- '- Services:\n    - Placeholder:\n        - href: http://localhost\n          description: edit config/bookmarks.yaml\n' > "$CFG/bookmarks.yaml"
fi
if [ ! -f "$CFG/services.yaml" ]; then
  printf -- '- Services:\n    - Placeholder:\n        - name: Edit me\n          href: http://localhost\n          description: edit config/services.yaml\n' > "$CFG/services.yaml"
fi

cd "$SCRIPT_DIR/services/homepage"
docker compose up -d
log_ok "Homepage installed: http://<host>:${HOMEPAGE_HTTP_PORT:-3002}"
log_info "Edit ${CFG}/{services,bookmarks,widgets}.yaml to add your own tiles."