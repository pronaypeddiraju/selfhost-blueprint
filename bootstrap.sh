#!/usr/bin/env bash
# bootstrap.sh — one command from a bare machine to a running stack.
#
#   curl -fsSL <url>/bootstrap.sh | bash            (or: ./bootstrap.sh)
#
# What it does:
#   1. checks the machine is fit for purpose (OS, RAM, disk, arch)
#   2. installs Docker (and compose plugin) if missing — with your confirmation
#   3. generates .env interactively (delegates to configure.sh)
#   4. offers a profile, then runs install.sh
#
# It changes nothing outside this directory except a Docker install, and it
# always shows you what it is about to do first.

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

say()  { printf '\033[0;36m→\033[0m %s\n' "$*"; }
ok()   { printf '\033[0;32m[ ok ]\033[0m %s\n' "$*"; }
warn() { printf '\033[0;33m[warn]\033[0m %s\n' "$*" >&2; }
die()  { printf '\033[0;31m[err ]\033[0m %s\n' "$*" >&2; exit 1; }
ask()  { local a; read -r -p "$1 [y/N]: " a; [ "${a,,}" = "y" ] || [ "${a,,}" = "yes" ]; }

# --- 1. sanity -------------------------------------------------------------
say "Checking this machine..."
[ "$(uname -s)" = "Linux" ] || die "This blueprint targets Linux. On macOS/Windows use a VM or WSL2."

if [ -r /etc/os-release ]; then . /etc/os-release; ok "OS: ${PRETTY_NAME:-unknown}"; else warn "Unknown distro"; fi

RAM_MB=$(awk '/MemTotal/{printf "%d", $2/1024}' /proc/meminfo)
if [ "$RAM_MB" -lt 1900 ]; then
  die "Only ${RAM_MB} MB RAM. Tier 1 needs ~1 GB free; 4 GB total is a realistic floor."
elif [ "$RAM_MB" -lt 3900 ]; then
  warn "${RAM_MB} MB RAM — that's enough for 'minimal' only. Skip photos/media."
else
  ok "RAM: ${RAM_MB} MB"
fi

AVAIL_GB=$(df -Pk /var 2>/dev/null | awk 'NR==2{printf "%d", $4/1048576}')
[ -n "${AVAIL_GB:-}" ] && ok "Free space on /var: ${AVAIL_GB} GB"
[ "${AVAIL_GB:-0}" -lt 10 ] && warn "Less than 10 GB free — Immich/media will not fit."

# --- 2. docker -------------------------------------------------------------
if command -v docker >/dev/null 2>&1; then
  ok "Docker: $(docker --version)"
else
  warn "Docker is not installed."
  echo "  Install command that will run:"
  echo "    curl -fsSL https://get.docker.com | sh"
  ask "Install Docker now?" || die "Docker is required. Install it and re-run."
  curl -fsSL https://get.docker.com | sh
  ok "Docker installed"
fi
docker compose version >/dev/null 2>&1 || die "Docker Compose v2 plugin missing (docker compose). Install it and re-run."

if [ "$(id -u)" -ne 0 ]; then
  warn "Not running as root — install.sh needs root for Docker and data directories."
fi

# --- 3. .env ---------------------------------------------------------------
if [ -f .env ]; then
  ok ".env already exists — leaving it alone."
else
  say "Generating .env (interactive)"
  bash ./configure.sh
fi

# --- 4. profile ------------------------------------------------------------
echo
echo "Which bundle?"
echo "  1) minimal     DNS + TLS + passwords + monitoring + backups + dashboard  (~1 GB)"
echo "  2) photos      minimal + Immich photo backup                             (needs disk)"
echo "  3) media       minimal + Jellyfin + download automation                   (needs a VPN)"
echo "  4) everything  all Tier 1 + Tier 2"
echo "  5) custom      pick services yourself"
read -r -p "Choice [1]: " choice
case "${choice:-1}" in
  1) PROFILE=minimal ;;
  2) PROFILE=photos ;;
  3) PROFILE=media ;;
  4) PROFILE=everything ;;
  5) echo "Run: ./install.sh --list   then   ./install.sh --services=a,b,c"; exit 0 ;;
  *) die "Unknown choice" ;;
esac

say "About to install profile: $PROFILE"
ask "Proceed?" || die "Aborted — nothing was changed."
./install.sh --profile="$PROFILE"

echo
ok "Done. Open the dashboard on http://<this-host>:3002 (or https:// if TLS_MODE=internal)."
echo "  Next: read docs/80-security.md (first-boot passwords, cert install) and docs/02-quickstart.md."