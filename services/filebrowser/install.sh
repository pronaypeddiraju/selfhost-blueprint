#!/usr/bin/env bash
# install.sh — FileBrowser, a lightweight web file manager.
# Exposes whatever host folders you bind under /data. First-run admin password
# is printed to the container log (see 18-filebrowser.md); change it in the UI.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
source "$SCRIPT_DIR/lib/common.sh"; source "$SCRIPT_DIR/lib/storage.sh"
load_env; require_docker; ensure_storage
provision_storage filebrowser >/dev/null
mkdir -p "${DATA_DIR}/filebrowser/db"

cd "$SCRIPT_DIR/services/filebrowser"
docker compose up -d
log_ok "FileBrowser installed: http://<host>:${FILEBROWSER_HTTP_PORT:-8080}"
log_info "Default login is admin/admin on first boot — change it. Edit compose.yaml to bind more folders."
