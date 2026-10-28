#!/usr/bin/env bash
# install.sh — Immich (self-hosted photo/video backup, with GPU-optional ML)
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
source "$SCRIPT_DIR/lib/common.sh"; source "$SCRIPT_DIR/lib/detect.sh"; source "$SCRIPT_DIR/lib/storage.sh"
load_env; require_docker; ensure_storage

require_var IMMICH_DB_PASSWORD
resolve_gpu
for sub in uploads library machine_learning database backup; do
  provision_storage "immich/$sub" >/dev/null
done

cd "$SCRIPT_DIR/services/immich"
if [ "$GPU_DETECT" = none ]; then
  sed -i 's/^\(\s*devices:\).*$/  \1/' compose.yaml 2>/dev/null || true
  log_info "No GPU detected — running Immich ML on CPU."
else
  log_info "GPU detected ($GPU_DETECT) — machine-learning service will use it."
fi

docker compose up -d
log_ok "Immich installed. First-run setup: docs/08-immich.md"
