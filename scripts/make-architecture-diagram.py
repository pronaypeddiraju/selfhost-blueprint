#!/usr/bin/env python3
"""Generate docs/images/architecture.svg for the selfhost-blueprint README.

Deliberately parameterised: the service chips come from one list, so updating the
diagram is a one-line change rather than hand-editing SVG coordinates.
"""
from xml.sax.saxutils import escape

W, H = 1200, 700
BG = "#0d1117"
CARD = "#161b22"
CARD2 = "#1c2430"
BORDER = "#30363d"
TEXT = "#c9d1d9"
DIM = "#8b949e"
ACCENT = "#58a6ff"
GREEN = "#3fb950"

chips = [
    ("Immich", "photos", "#7c5cff"),
    ("Jellyfin", "media", "#a855f7"),
    ("Media stack", "VPN + *arr", "#f0883e"),
    ("Mealie", "recipes", "#e3b341"),
    ("SilverBullet", "notes", "#58a6ff"),
    ("Vaultwarden", "passwords", "#3b82f6"),
    ("Homepage", "dashboard", "#3fb950"),
    ("Uptime Kuma", "monitoring", "#2dd4bf"),
    ("Scrutiny", "disk health", "#f85149"),
    ("FileBrowser", "files", "#60a5fa"),
]

out = []
a = out.append
a(f'<svg xmlns="http://www.w3.org/2000/svg" width="{W}" height="{H}" viewBox="0 0 {W} {H}" '
  f'font-family="ui-sans-serif,-apple-system,Segoe UI,Roboto,Helvetica,Arial,sans-serif">')
a(f'<rect width="{W}" height="{H}" rx="14" fill="{BG}"/>')

a(f'<text x="44" y="52" fill="{TEXT}" font-size="25" font-weight="600">Selfhost Blueprint</text>')
a(f'<text x="44" y="78" fill="{DIM}" font-size="15">one spare machine · Docker · pick only the services you want</text>')

# ---- clients ----
a(f'<rect x="44" y="112" width="252" height="96" rx="10" fill="{CARD}" stroke="{BORDER}"/>')
a(f'<text x="66" y="145" fill="{TEXT}" font-size="16" font-weight="600">Your devices</text>')
a(f'<text x="66" y="170" fill="{DIM}" font-size="13">browser · phone · TV</text>')
a(f'<text x="66" y="192" fill="{DIM}" font-size="13">LAN or Tailscale</text>')

# arrow clients -> machine
a(f'<path d="M300 160 H336" stroke="{ACCENT}" stroke-width="2" stroke-dasharray="4 4"/>')
a(f'<path d="M330 154 L338 160 L330 166 Z" fill="{ACCENT}"/>')

# ---- machine ----
a(f'<rect x="340" y="100" width="820" height="560" rx="12" fill="{CARD}" stroke="{BORDER}"/>')
a(f'<text x="364" y="130" fill="{DIM}" font-size="12" letter-spacing="1.4">SPARE MACHINE · DOCKER</text>')

# ---- edge: caddy + adguard ----
a(f'<rect x="364" y="144" width="378" height="74" rx="9" fill="{CARD2}" stroke="{BORDER}"/>')
a(f'<text x="384" y="173" fill="{TEXT}" font-size="15" font-weight="600">Caddy</text>')
a(f'<text x="384" y="196" fill="{DIM}" font-size="13">HTTPS + one hostname per service</text>')

a(f'<rect x="758" y="144" width="378" height="74" rx="9" fill="{CARD2}" stroke="{BORDER}"/>')
a(f'<text x="778" y="173" fill="{TEXT}" font-size="15" font-weight="600">AdGuard Home</text>')
a(f'<text x="778" y="196" fill="{DIM}" font-size="13">network DNS + ad-blocking</text>')

a(f'<text x="364" y="256" fill="{DIM}" font-size="12" letter-spacing="1.4">SERVICES — INSTALL ANY SUBSET</text>')

# ---- service chips 5 x 2 ----
cw, ch, gap = 147, 66, 14
x0, y0 = 364, 270
for i, (name, sub, colour) in enumerate(chips):
    col, row = i % 5, i // 5
    x = x0 + col * (cw + gap)
    y = y0 + row * (ch + 14)
    a(f'<rect x="{x}" y="{y}" width="{cw}" height="{ch}" rx="9" fill="{CARD2}" stroke="{BORDER}"/>')
    a(f'<circle cx="{x + 16}" cy="{y + 22}" r="4" fill="{colour}"/>')
    a(f'<text x="{x + 28}" y="{y + 27}" fill="{TEXT}" font-size="12.5" font-weight="600">{escape(name)}</text>')
    a(f'<text x="{x + 14}" y="{y + 50}" fill="{DIM}" font-size="11.5">{escape(sub)}</text>')

# ---- storage ----
a(f'<rect x="364" y="438" width="772" height="62" rx="9" fill="{CARD2}" stroke="{BORDER}"/>')
a(f'<text x="384" y="464" fill="{TEXT}" font-size="14" font-weight="600">One data directory</text>')
a(f'<text x="384" y="486" fill="{DIM}" font-size="12.5">/srv/selfhost  ·  or ZFS datasets on Proxmox</text>')
a(f'<text x="1116" y="474" fill="{DIM}" font-size="12.5" text-anchor="end">plain disk or ZFS</text>')

# ---- backups ----
a(f'<rect x="364" y="514" width="772" height="62" rx="9" fill="{CARD2}" stroke="{BORDER}"/>')
a(f'<circle cx="372" cy="532" r="4" fill="{GREEN}"/>')
a(f'<text x="386" y="537" fill="{TEXT}" font-size="14" font-weight="600">backups</text>')
a(f'<text x="384" y="560" fill="{DIM}" font-size="12.5">snapshots + retention, installed with every profile</text>')
a(f'<text x="1116" y="550" fill="{DIM}" font-size="12.5" text-anchor="end">keep a copy off this machine</text>')

# ---- footer notes ----
a(f'<text x="364" y="612" fill="{DIM}" font-size="12.5">No inbound ports · TLS via Caddy\'s local CA (no domain needed) · secrets only in .env</text>')

a('</svg>')

open("/root/shots/architecture.svg", "w").write("\n".join(out))
print("written /root/shots/architecture.svg")