#!/usr/bin/env bash
# lib/detect.sh — capability detection. Designed so scripts NEVER assume the
# target machine's hardware or environment. All functions set globals and are
# safe to source multiple times.

# --- Platform --------------------------------------------------------------
# Sets PLATFORM_AUTODETECT. Proxmox has /etc/pve, systemd 'pve-cluster'.
detect_platform() {
  if [ -d /etc/pve ]; then
    PLATFORM_AUTODETECT=proxmox
  elif [ -f /etc/os-release ] && grep -qiE 'debian|ubuntu' /etc/os-release; then
    PLATFORM_AUTODETECT=linux
  else
    PLATFORM_AUTODETECT=linux
  fi
  export PLATFORM_AUTODETECT
}

# --- GPU -------------------------------------------------------------------
# Sets GPU_DETECT: nvidia | intel | none (intel = i915 render node present).
detect_gpu() {
  GPU_DETECT=none
  if [ -e /dev/nvidiactl ] || command -v nvidia-smi >/dev/null 2>&1; then
    GPU_DETECT=nvidia
  elif [ -e /dev/dri/renderD128 ]; then
    GPU_DETECT=intel
  fi
  export GPU_DETECT
}

# Resolve the requested GPU_MODE against what's actually present.
# GPU_MODE: auto (default) | nvidia | intel | none
resolve_gpu() {
  detect_gpu
  case "${GPU_MODE:-auto}" in
    auto)   : ;;                     # keep GPU_DETECT
    nvidia) [ "$GPU_DETECT" = nvidia ] || { GPU_DETECT=nvidia; log_warn "nvidia requested but not detected"; } ;;
    intel)  [ "$GPU_DETECT" = intel ]  || { GPU_DETECT=intel;  log_warn "intel requested but not detected"; } ;;
    none)   GPU_DETECT=none ;;
    *)      log_warn "Unknown GPU_MODE '$GPU_MODE'; defaulting to auto" ;;
  esac
  export GPU_DETECT
}

# --- Storage ---------------------------------------------------------------
# Sets STORAGE_DETECT: zfs | dir. ZFS exists if 'zfs' binary + 'zpool' work.
detect_storage() {
  STORAGE_DETECT=dir
  if command -v zfs >/dev/null 2>&1 && command -v zpool >/dev/null 2>&1 \
     && zpool list >/dev/null 2>&1; then
    STORAGE_DETECT=zfs
  fi
  export STORAGE_DETECT
}

# --- OS / init -------------------------------------------------------------
detect_init() {
  INIT=systemd
  [ -d /run/systemd/system ] || INIT=other
  export INIT
}

# Convenience: run all detection.
detect_all() {
  detect_platform
  resolve_gpu
  detect_storage
  detect_init
}
