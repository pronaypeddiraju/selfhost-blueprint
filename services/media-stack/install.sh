#!/usr/bin/env bash
# install.sh — Media stack: gluetun (VPN) + qBittorrent + Radarr/Sonarr/Prowlarr/
# Bazarr/Flaresolverr + optional Jellyseerr + decluttarr.
# All downloaders/providers share gluetun's network namespace for a single VPN IP.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
source "$SCRIPT_DIR/lib/common.sh"; source "$SCRIPT_DIR/lib/detect.sh"; source "$SCRIPT_DIR/lib/storage.sh"
load_env; require_docker; ensure_storage

require_var VPN_PROVIDER
require_var VPN_PRIVATE_KEY

for sub in qbittorrent radarr sonarr prowlarr bazarr flaresolverr jellyseerr decluttarr; do
  provision_storage "media/$sub" >/dev/null
done

# Render decluttarr config from the sanitized template.
mkdir -p "$SCRIPT_DIR/services/media-stack/config" "$DATA_DIR/media/decluttarr/logs"
cp "$SCRIPT_DIR/templates/decluttarr/config.example.yaml" \
   "$SCRIPT_DIR/services/media-stack/config/decluttarr.yaml"

cd "$SCRIPT_DIR/services/media-stack"
docker compose up -d
log_ok "Media stack installed. Configure apps behind gluetun: see docs/06-media-stack.md"
echo "  qBittorrent  -> http://<host>:${QBIT_HTTP_PORT:-8080}"
echo "  Radarr       -> http://<host>:${RADARR_PORT:-7878}"
echo "  Sonarr       -> http://<host>:${SONARR_PORT:-8989}"
echo "  Prowlarr     -> http://<host>:${PROWLARR_PORT:-9696}"
echo "  Bazarr       -> http://<host>:${BAZARR_PORT:-6767}"
echo "  Jellyseerr   -> http://<host>:${JELLYSEERR_PORT:-5055}"
