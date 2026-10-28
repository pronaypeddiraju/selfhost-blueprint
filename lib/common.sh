#!/usr/bin/env bash
# lib/common.sh — shared helpers: env loading, logging, validation.
# Intentional: this file is designed to be `source`d, not executed.

# ANSI colors (no-op when not a TTY).
if [ -t 1 ]; then
  # shellcheck disable=SC2034  # C_DIM is part of the palette (kept for consistency)
  C_INFO='\033[0;36m'; C_OK='\033[0;32m'; C_WARN='\033[0;33m'
  C_ERR='\033[0;31m'; C_DIM='\033[0;2m'; C_RESET='\033[0m'
else
  C_INFO=''; C_OK=''; C_WARN=''; C_ERR=''; C_DIM=''; C_RESET=''
fi

log_info()  { printf "${C_INFO}[info]${C_RESET} %s\n" "$*"; }
log_ok()    { printf "${C_OK}[ ok ]${C_RESET} %s\n" "$*"; }
log_warn()  { printf "${C_WARN}[warn]${C_RESET} %s\n" "$*" >&2; }
log_err()   { printf "${C_ERR}[err ]${C_RESET} %s\n" "$*" >&2; }
log_step()  { printf "\n${C_INFO}→ ${C_RESET}%s\n" "$*"; }

die() {
  log_err "$*"
  exit 1
}

# Resolve the repo root (this file lives at <root>/lib/common.sh).
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Load .env into the environment if present.
load_env() {
  local env_file="$REPO_ROOT/.env"
  if [ -f "$env_file" ]; then
    set -a
    # shellcheck disable=SC1090
    source "$env_file"
    set +a
  else
    log_warn "No .env found. Run ./configure.sh or copy templates/env.example to .env"
  fi
}

# Require a variable to be non-empty (with a friendly name).
require_var() {
  local name="$1"
  local val="${!name:-}"
  if [ -z "$val" ]; then
    die "Required variable $name is not set in .env (see templates/env.example)"
  fi
}

# Require root.
require_root() {
  [ "$(id -u)" -eq 0 ] || die "This step must run as root."
}

# Prompt with a default; echoes the chosen value.
prompt_default() {
  local msg="$1" default="$2" answer
  read -r -p "$msg [$default]: " answer
  echo "${answer:-$default}"
}

# Confirm an action (yes/no). Returns 0 on yes.
confirm() {
  local msg="$1"
  read -r -p "$msg [y/N]: " ans
  case "${ans,,}" in
    y|yes) return 0 ;;
    *) return 1 ;;
  esac
}

# Detect Docker. Sets DOCKER_OK=1 and prints version, else DOCKER_OK=0.
require_docker() {
  if command -v docker >/dev/null 2>&1; then
    log_ok "Docker found: $(docker --version)"
    return 0
  else
    log_warn "Docker is not installed. Install Docker first (docs/01-requirements.md)."
    return 1
  fi
}

# ---------------------------------------------------------------------------
# Resolve the URL a service is reachable on, honouring TLS_MODE. Used by modules
# that must know their own public identity (Vaultwarden DOMAIN, Mealie BASE_URL).
#   public_url <label> [port-for-none-mode]
# ---------------------------------------------------------------------------
public_url() {
  local sub="$1" port="${2:-}"
  case "${TLS_MODE:-internal}" in
    dns01)    printf 'https://%s.%s' "$sub" "${APP_DOMAIN:?APP_DOMAIN must be set for TLS_MODE=dns01}" ;;
    none)     printf 'http://%s%s' "${HOST_IP:-localhost}" "${port:+:$port}" ;;
    *)        printf 'https://%s.%s' "$sub" "${BASE_DOMAIN:-home.arpa}" ;;
  esac
}

# Set (or replace) a key in .env, idempotently.
set_env_var() {
  local key="$1" val="$2" env_file="$REPO_ROOT/.env"
  [ -f "$env_file" ] || { log_warn "no .env to update ($key)"; return 0; }
  if grep -qE "^${key}=" "$env_file"; then
    # shell-safe replacement without sed's delimiter headaches
    local tmp; tmp="$(mktemp)"
    awk -v k="$key" -v v="$val" 'BEGIN{FS=OFS="="} $1==k{print k"="v; next} {print}' "$env_file" > "$tmp"
    cat "$tmp" > "$env_file"; rm -f "$tmp"
  else
    printf '%s=%s\n' "$key" "$val" >> "$env_file"
  fi
}
