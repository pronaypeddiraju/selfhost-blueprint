# 09 — Hermes (self-hosted agent)

Hermes is a self-hosted personal agent: you message it over **Telegram /
WhatsApp** and it answers, runs automations, and operates your server. This
module installs it **natively** (Python venv + systemd) rather than in Docker —
a background agent lives comfortably as a system service.

Install:

```bash
./configure.sh                                  # set HERMES_* in .env
./install.sh --services=hermes
```

This creates a venv at `/opt/hermes-agent`, writes a systemd unit
(`hermes-gateway.service`), and enables it. Template:
`templates/systemd/hermes-gateway.service`.

## Configuration (in `.env`, never committed)

- `HERMES_PROVIDER_API_KEY` — API key for your chosen model provider.
- `HERMES_TELEGRAM_BOT_TOKEN` / `HERMES_TELEGRAM_CHAT_ID` — messaging if you
  want Telegram.
- `HERMES_WHATSAPP_*` — for WhatsApp support.
- `HERMES_PIP_SPEC` — `hermes-agent` (PyPI) or a `git+https://...` source.

For full install/pairing/skill guidance, see the official Hermes Agent docs —
this module is a thin wrapper around them.

## Restarts

`systemctl restart hermes-gateway`. Note: a gateway process **cannot restart
itself from inside itself** — issue the restart from a separate SSH session.
