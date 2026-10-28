#!/usr/bin/env bash
# install.sh — Hermes, a self-hosted personal agent (messaging + automation).
# This installs natively (Python venv + systemd), which is how a background
# agent realistically runs on a home box. No Docker image is assumed.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
source "$SCRIPT_DIR/lib/common.sh"; source "$SCRIPT_DIR/lib/detect.sh"
load_env; require_root

INSTALL_DIR="${HERMES_INSTALL_DIR:-/opt/hermes-agent}"
HERMES_HOME="${HERMES_HOME:-/root/.hermes}"
SERVICE_USER="${HERMES_SERVICE_USER:-root}"
SERVICE_NAME="hermes-gateway.service"

# --- install the agent -----------------------------------------------
if [ ! -x "$INSTALL_DIR/venv/bin/python" ]; then
  log_step "Creating venv + installing Hermes at $INSTALL_DIR"
  mkdir -p "$INSTALL_DIR"
  python3 -m venv "$INSTALL_DIR/venv"
  # Package source. Prefer a git repo, else PyPI. Set in .env:
  #   HERMES_PIP_SPEC="hermes-agent"  (PyPI)
  #   HERMES_PIP_SPEC="git+https://..." (from source)
  "$INSTALL_DIR/venv/bin/pip" install --upgrade "${HERMES_PIP_SPEC:-hermes-agent}"
else
  log_ok "Hermes already installed at $INSTALL_DIR"
fi

# --- systemd unit -----------------------------------------------------
log_step "Installing systemd unit"
sed -e "s|__INSTALL_DIR__|$INSTALL_DIR|g" \
    -e "s|__HERMES_HOME__|$HERMES_HOME|g" \
    -e "s|__SERVICE_USER__|$SERVICE_USER|g" \
    "$SCRIPT_DIR/templates/systemd/hermes-gateway.service" \
    > "/etc/systemd/system/$SERVICE_NAME"

systemctl daemon-reload
systemctl enable --now "$SERVICE_NAME"
systemctl --no-pager status "$SERVICE_NAME" --lines 8 || true

log_ok "Hermes gateway installed. First-time pairing/config lives in \$HERMES_HOME."
log_info "Hook up messaging gateways + model provider in $HERMES_HOME/.env — see docs/09-hermes.md"
