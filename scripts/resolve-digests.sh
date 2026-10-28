#!/usr/bin/env bash
# resolve-digests.sh — resolve image tags to immutable manifest digests.
# Used to (re)pin every image in the blueprint. Requires curl + python3 (stdlib only).
#
#   ./scripts/resolve-digests.sh adguard/adguardhome:latest ghcr.io/mealie-recipes/mealie:latest
#
# Prints:  <image>\t<sha256:...>
# No Docker daemon needed — pure registry API.
set -uo pipefail

ACCEPT="application/vnd.oci.image.index.v1+json,application/vnd.docker.distribution.manifest.list.v2+json,application/vnd.docker.distribution.manifest.v2+json,application/vnd.oci.image.manifest.v1+json"

resolve() {
  local image="$1" host repo tag token base
  local ref="${image%@*}"; ref="${ref%%:*}"
  # tag: text after the last ':' if it is not a registry port
  case "$image" in
    *:*/*) tag="${image##*:}" ;;
    *:*)   tag="${image##*:}" ;;
    *)     tag="latest" ;;
  esac
  case "$ref" in
    ghcr.io/*)        host="ghcr.io";    repo="${ref#ghcr.io/}" ;;
    lscr.io/*)        host="docker.io";  repo="${ref#lscr.io/}" ;;
    docker.io/*)      host="docker.io";  repo="${ref#docker.io/}" ;;
    */*)              host="docker.io";  repo="$ref" ;;
    *)                host="docker.io";  repo="library/$ref" ;;
  esac

  if [ "$host" = "ghcr.io" ]; then
    token=$(curl -sf "https://ghcr.io/token?service=ghcr.io&scope=repository:${repo}:pull" | python3 -c 'import json,sys;print(json.load(sys.stdin)["token"])') || { echo -e "${image}\tERROR\ttoken"; return; }
    base="https://ghcr.io/v2/${repo}"
  else
    token=$(curl -sf "https://auth.docker.io/token?service=registry.docker.io&scope=repository:${repo}:pull" | python3 -c 'import json,sys;print(json.load(sys.stdin)["token"])') || { echo -e "${image}\tERROR\ttoken"; return; }
    base="https://registry-1.docker.io/v2/${repo}"
  fi

  local digest
  digest=$(curl -sfI -H "Authorization: Bearer ${token}" -H "Accept: ${ACCEPT}" \
             "${base}/manifests/${tag}" \
             | tr -d '\r' | awk 'tolower($1)=="docker-content-digest:"{print $2}')
  if [ -n "${digest:-}" ]; then
    printf '%s\t%s\n' "$image" "$digest"
  else
    printf '%s\tERROR\tno digest (tag %s may not exist)\n' "$image" "$tag"
  fi
}

for img in "$@"; do resolve "$img"; done