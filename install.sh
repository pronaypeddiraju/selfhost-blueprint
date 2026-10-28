#!/usr/bin/env bash
# install.sh — the pick-and-choose installer.
#
# Usage:
#   ./install.sh --list                     list available services + profiles
#   ./install.sh --profile=minimal          install a curated bundle (see below)
#   ./install.sh --services=adguard,caddy   install an explicit subset
#   ./install.sh adguard caddy              (positional also works)
#   ./install.sh --all                      everything in Tier 1 + Tier 2
#   ./install.sh --all --with-advanced      ...plus Tier 3 (Hermes)
#
# Profiles:
#   minimal     adguard caddy vaultwarden uptimekuma backups homepage
#   photos      minimal + immich
#   media       minimal + jellyfin media-stack
#   everything  minimal + immich jellyfin media-stack mealie silverbullet
#               filebrowser scrutiny
#
# Tiers are a support contract, not a ranking:
#   Tier 1 = core, safe default.  Tier 2 = opt-in, per-service hardware/disk
#   needs.  Tier 3 = advanced; never installed implicitly, may need paid
#   credentials or extra hardware, and expects you to read its doc first.

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/common.sh"
source "$SCRIPT_DIR/lib/detect.sh"

SERVICES_DIR="$SCRIPT_DIR/services"
TIER1="adguard caddy vaultwarden uptimekuma backups homepage"
TIER2="immich jellyfin media-stack mealie silverbullet filebrowser scrutiny"
TIER3="hermes"
ALL_SERVICES="$(find "$SERVICES_DIR" -mindepth 1 -maxdepth 1 -type d -printf '%f\n' | sort)"
SELECTED=""
WITH_ADVANCED=0

profile_services() {
  case "$1" in
    minimal)    echo "$TIER1" ;;
    photos)     echo "$TIER1 immich" ;;
    media)      echo "$TIER1 jellyfin media-stack" ;;
    everything) echo "$TIER1 $TIER2" ;;
    *) return 1 ;;
  esac
}

describe() {
  local s="$1" desc="tier"
  [ -f "$SERVICES_DIR/$s/description" ] && desc="$(cat "$SERVICES_DIR/$s/description")"
  printf "  %-14s %s\n" "$s" "$desc"
}

# --- argument parsing ------------------------------------------------------
while [ $# -gt 0 ]; do
  case "$1" in
    --list)
      echo "Profiles:"
      echo "  minimal     core only — DNS, TLS, passwords, monitoring, backups, dashboard"
      echo "  photos      minimal + Immich"
      echo "  media       minimal + Jellyfin + download automation"
      echo "  everything  all Tier 1 + Tier 2"
      echo
      echo "Tier 1 — core (safe default):"
      for s in $TIER1; do describe "$s"; done
      echo
      echo "Tier 2 — opt-in:"
      for s in $TIER2; do describe "$s"; done
      echo
      echo "Tier 3 — advanced (never implicit; read the doc first):"
      for s in $TIER3; do describe "$s"; done
      exit 0 ;;
    --profile=*)  SELECTED="$(profile_services "${1#--profile=}")" || die "Unknown profile: ${1#--profile=}" ;;
    --all)        SELECTED="$TIER1 $TIER2" ;;
    --with-advanced) WITH_ADVANCED=1 ;;
    --services=*) SELECTED="${1#--services=}" ;;
    -h|--help)    sed -n '2,29p' "$0"; exit 0 ;;
    *)            SELECTED="$SELECTED $1" ;;
  esac
  shift
done

# Explicitly asking for a Tier 3 module is the same as --with-advanced.
case " $SELECTED " in *" hermes "*) WITH_ADVANCED=1 ;; esac
[ "$WITH_ADVANCED" -eq 1 ] && SELECTED="$SELECTED $TIER3"

if [ -z "${SELECTED// /}" ]; then
  log_err "No services selected. Use --list, --profile=<name>, --services=a,b,c, or --all"
  exit 1
fi

# --- expand aliases / normalize --------------------------------------------
SELECTED="$(echo "$SELECTED" | tr ',' ' ' | tr -s ' ')"
log_info "Requested: $(echo "$SELECTED" | xargs)"

# --- dependency resolution -------------------------------------------------
# Build the install PLAN = selected services + all transitive dependencies.
# Iterate to a fixpoint: keep every selected service, add each service's
# declared deps, dedupe, repeat until nothing new is added.
PLAN="$SELECTED"
for _ in $(seq 1 10); do
  ADD=""
  for svc in $PLAN; do
    if [ -f "$SERVICES_DIR/$svc/depends" ]; then
      ADD="$ADD $(cat "$SERVICES_DIR/$svc/depends")"
    fi
  done
  NEW="$(echo "$PLAN $ADD" | tr ' ' '\n' | sort -u | tr '\n' ' ')"
  [ "$NEW" = "$PLAN" ] && break
  PLAN="$NEW"
done

# --- validate all selected services exist -----------------------------------
for svc in $PLAN; do
  [ -d "$SERVICES_DIR/$svc" ] || die "Unknown service: $svc (see ./install.sh --list)"
done

# --- environment ------------------------------------------------------------
load_env
detect_all

echo; log_step "Install plan (in order):"
for svc in $PLAN; do
  case " $TIER3 " in *" $svc "*) log_info "  - $svc  (advanced)" ;; *) log_info "  - $svc" ;; esac
done
echo
log_info "TLS mode: ${TLS_MODE:-internal}"
confirm "Proceed with installation?" || die "Aborted."

require_root
require_docker || die "Docker is required for these services."

# --- run each module --------------------------------------------------------
for svc in $PLAN; do
  log_step "Installing: $svc"
  bash "$SERVICES_DIR/$svc/install.sh" || die "Install of '$svc' failed."
  log_ok "Done: $svc"
done

log_ok "All requested services installed."

# Caddy's config has to be rendered *after* everything else exists, otherwise it
# would only know about the services that were already running. Re-run it last.
case " $PLAN " in
  *" caddy "*)
    log_step "Re-rendering the Caddyfile for everything now running"
    bash "$SERVICES_DIR/caddy/install.sh" || log_warn "Caddy re-render failed — run ./install.sh --services=caddy"
    ;;
esac

log_info "Manage them with ./manage.sh (e.g. ./manage.sh status)"
log_info "Security checklist for what you just installed: docs/80-security.md"