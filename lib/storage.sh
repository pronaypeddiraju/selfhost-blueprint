#!/usr/bin/env bash
# lib/storage.sh — storage abstraction for ZFS vs directory backends.
# All service installs allocate data through these helpers, so the same service
# script works on a ZFS home server and a plain laptop directory.
# Self-contained: pulls in detect.sh so detect_storage() is always available
# regardless of which modules the caller chose to source.
REPO_ROOT="${REPO_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
# shellcheck disable=SC1091
source "$REPO_ROOT/lib/detect.sh"

# Resolve DATA_DIR into a canonical, writable location. Creates it if needed.
# For zfs: DATA_DIR is a mountpoint (we assume the caller set up datasets).
# For dir: DATA_DIR is a plain path we mkdir -p.
ensure_storage() {
  detect_storage
  : "${DATA_DIR:=/srv/selfhost}"
  case "$STORAGE_DETECT:$STORAGE_TYPE" in
    zfs:zfs|zfs:)
      mkdir -p "$DATA_DIR" || die "Cannot create $DATA_DIR"
      ;;
    *:dir|*:)
      mkdir -p "$DATA_DIR" || die "Cannot create $DATA_DIR"
      # chmod +g for group-writable shared trees; not required.
      ;;
    *)
      die "STORAGE_TYPE '$STORAGE_TYPE' not supported on this host"
      ;;
  esac
  export DATA_DIR
  log_ok "Storage ready at $DATA_DIR (backend: $STORAGE_DETECT)"
}

# Create a named data volume/dataset for a service.
# Usage: provision_storage <service_name>
#  - zfs:   zfs create <parent>/<name>  (best-effort; ok if exists)
#  - dir:   mkdir -p $DATA_DIR/<name>
provision_storage() {
  local name="$1"
  [ -n "$name" ] || die "provision_storage requires a service name"
  case "$STORAGE_DETECT:$STORAGE_TYPE" in
    zfs:*)
      # Simplest portable approach: ensure a single dataset directory exists.
      zfs create -o recordsize=1M "${DATA_DIR%/}/$name" 2>/dev/null \
        || mkdir -p "$DATA_DIR/$name"
      ;;
    *)
      mkdir -p "$DATA_DIR/$name"
      ;;
  esac
  log_ok "Provisioned storage: $DATA_DIR/$name"
  echo "$DATA_DIR/$name"
}

# Path helper: print the absolute data path for a service.
service_data_dir() {
  echo "${DATA_DIR:-/srv/selfhost}/$1"
}
