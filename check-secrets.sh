#!/usr/bin/env bash
# check-secrets.sh — pre-commit scanner.
#
# Scans all files that git would track and flags anything that looks like a
# leaked secret or a real identifier we must not share. Exit code 0 = clean,
# 1 = something to fix before pushing. Run before every push.
#
#   ./check-secrets.sh            # scan tracked files
#   ./check-secrets.sh --all      # also scan untracked files

set -uo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR" || exit 1

ALL=0; [ "${1:-}" = --all ] && ALL=1

# Files to scan: everything git tracks (or all files if --all), excluding
# binaries. This intentionally does NOT include .env.
if [ "$ALL" = 1 ]; then
  FILES="$(find . -type f \
    ! -path './.git/*' ! -path './.gitignore' \
    ! -name '*.png' ! -name '*.jpg' ! -name '*.gif' ! -name '*.pdf' \
    -print 2>/dev/null)"
else
  FILES="$(git ls-files 2>/dev/null)"
fi

[ -n "$FILES" ] || { echo "No files to scan."; exit 0; }

DIED=0

# --- pattern sets ------------------------------------------------------------
SECRET_PATTERNS=(
  '(ghp|gho|ghu|ghs|ghr)_[A-Za-z0-9]{20,}'        # GitHub tokens
  'AKIA[0-9A-Z]{16}'                               # AWS access key
  'xox[baprs]-[A-Za-z0-9-]{10,}'                   # Slack tokens
  'sk-[A-Za-z0-9]{20,}'                            # OpenAI-style
  '(api[_-]?key|secret|passwd|password|token)["'"'"']?\s*[:=]\s*["'"'"'][^"'"'"']{12,}'
  'BEGIN (RSA |EC |OPENSSH )?PRIVATE KEY'
  'Bearer [A-Za-z0-9._-]{20,}'
  'wp_[A-Za-z0-9]{15,}'                            # WordPress
)

IDENTIFIER_PATTERNS=(
  # Real public/globally-routable IPv4 (private ranges are allowed as docs).
  '\b([0-9]{1,3}\.){3}[0-9]{1,3}\b'
  # Anything that looks like a real hostname+FQDN pattern we must not leak.
  # (Placeholders like YOUR_DOMAIN / example.com are fine.)
)
# shellcheck disable=SC2034  # IDENTIFIER_PATTERNS documents intent; IPv4 handled inline below

# --- author denylist ---------------------------------------------------------
# Your real identifiers must never appear in a public repo — including, ironically,
# inside this file. So the list itself is NOT shipped: it lives in
# `check-secrets.denylist` (git-ignored), one pattern per line, # for comments.
#
#   cp check-secrets.denylist.example check-secrets.denylist
#   $EDITOR check-secrets.denylist      # add your domain, hostnames, usernames,
#                                       # pool names, tailnet ID, surnames...
#
# Checked case-insensitively against every tracked file.
DENYLIST_FILE="$SCRIPT_DIR/check-secrets.denylist"
DENYLIST_PATTERNS=()
if [ -f "$DENYLIST_FILE" ]; then
  while IFS= read -r _line; do
    case "${_line:-}" in ''|\#*) continue ;; esac
    DENYLIST_PATTERNS+=("$_line")
  done < "$DENYLIST_FILE"
  echo "denylist: $(echo "${#DENYLIST_PATTERNS[@]}") pattern(s) loaded from check-secrets.denylist"
else
  echo "denylist: none (copy check-secrets.denylist.example -> check-secrets.denylist)"
fi

# We only hard-flag IPv4 that is NOT in a private/documentation range, to allow
# examples like 192.168.x, 10.x, 172.16-31.x, 127.x, and documentation meta
# ranges (192.0.2.0/24 TEST-NET etc.).
is_private_or_doc_ip() {
  local ip="$1"
  awk -v ip="$ip" 'BEGIN{
    split(ip,a,"."); o=a[1]
    # private/doc heuristics
    if (o==0) exit 0    # 0.0.0.0/8 "this network" (wildcard bind address)
    if (o==10) exit 0
    if (o==127) exit 0
    if (o==192 && a[2]==168) exit 0
    if (o==172 && a[2]>=16 && a[2]<=31) exit 0
    if (o==192 && a[2]==0 && a[3]==2) exit 0   # TEST-NET-1
    if (o==198 && a[2]==51 && a[3]==100) exit 0
    if (o==203 && a[2]==0 && a[3]==113) exit 0
    exit 1
  }'
}

report() { echo "  $1:$2: $3"; DIED=1; }

echo "Scanning $(echo "$FILES" | wc -l) file(s) ..."

while IFS= read -r f; do
  [ -r "$f" ] || continue

  # --- author denylist (skip the list itself; it *contains* the patterns) ---
  case "$(basename "$f")" in
    check-secrets.denylist*) : ;;
    *)
      for pat in "${DENYLIST_PATTERNS[@]:-}"; do
        [ -n "$pat" ] || continue
        while IFS=: read -r ln rest; do
          [ -n "$ln" ] && report "$f" "$ln" "author identifier on denylist ($pat)"
        done < <(grep -inE -- "$pat" "$f" 2>/dev/null | head -3)
      done ;;
  esac

  # --- secrets ---
  for pat in "${SECRET_PATTERNS[@]}"; do
    while IFS=: read -r ln rest; do
      [ -n "$ln" ] && report "$f" "$ln" "possible secret pattern"
    done < <(grep -E "$pat" "$f" 2>/dev/null | head -5)
  done

  # --- identifiers (IPv4) ---
  while IFS=: read -r ln ip; do
    [ -n "$ln" ] || continue
    if ! is_private_or_doc_ip "$ip"; then
      report "$f" "$ln" "non-private IPv4 -> $ip"
    fi
  done < <(grep -onE '([0-9]{1,3}\.){3}[0-9]{1,3}' "$f" 2>/dev/null | head -10)
done <<< "$FILES"

if [ "$DIED" = 1 ]; then
  echo
  echo "!! Possible leaks found. Fix them before pushing. If a match is a"
  echo "   legitimate private-range example, it was already allowed by the filter."
  exit 1
fi
echo "check-secrets: clean  ✓"
exit 0
