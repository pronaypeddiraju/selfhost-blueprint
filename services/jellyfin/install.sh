#!/usr/bin/env bash
# install.sh — Jellyfin media server (GPU-optional transcode)
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
source "$SCRIPT_DIR/lib/common.sh"; source "$SCRIPT_DIR/lib/detect.sh"; source "$SCRIPT_DIR/lib/storage.sh"
load_env; require_docker; ensure_storage
provision_storage jellyfin >/dev/null
resolve_gpu

cd "$SCRIPT_DIR/services/jellyfin"
if [ "$GPU_DETECT" = nvidia ] || [ "$GPU_DETECT" = intel ]; then
  log_info "GPU detected ($GPU_DETECT) — enabling hardware transcode."
fi
docker compose up -d
log_ok "Jellyfin installed: http://<host>:${JELLYFIN_HTTP_PORT:-8096}"
echo "  Enable hardware acceleration in Jellyfin Settings per docs/07-jellyfin.md"
