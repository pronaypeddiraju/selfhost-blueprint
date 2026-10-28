#!/usr/bin/env bash
# install.sh — SilverBullet, a personal knowledge base.
# Plain-Markdown vault: every page is a .md file on disk, so the whole space is
# grep-able, git-diffable, and openable in Obsidian/vim. Data lives in
# ${DATA_DIR}/silverbullet (bind-mounted as /space inside the container).
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
source "$SCRIPT_DIR/lib/common.sh"; source "$SCRIPT_DIR/lib/storage.sh"
load_env; require_docker; ensure_storage
require_var SILVERBULLET_USER   # SB_USER "username:password" for the web editor
provision_storage silverbullet >/dev/null

cd "$SCRIPT_DIR/services/silverbullet"
docker compose up -d
log_ok "SilverBullet installed: http://<host>:${SILVERBULLET_HTTP_PORT:-3000}"
log_info "Pages are plain .md in ${DATA_DIR}/silverbullet — back them up / grep them / open in Obsidian."
