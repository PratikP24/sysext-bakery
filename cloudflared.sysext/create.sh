#!/usr/bin/env bash
# vim: et ts=2 syn=bash
#
# Cloudflared (Cloudflare Tunnel) system extension (PROPOSAL — bakery format).
#
# Place this directory as  <bakery-clone>/cloudflared.sysext/  and build with:
#   ./bakery.sh create cloudflared 2026.6.1 --sysupdate true
#
# Cloudflared publishes a self-contained static x86_64 binary as a GitHub
# release asset, so this is a simple download recipe (modeled on
# docker-compose.sysext/create.sh). Asset names (verified 2026-06-18):
#   cloudflared-linux-amd64        (x86_64)
#   cloudflared-linux-arm64        (arm64)
# under https://github.com/cloudflare/cloudflared/releases/download/<tag>/

RELOAD_SERVICES_ON_MERGE="true"

# Cloudflared tags are calendar-versioned, e.g. "2026.6.1" (no leading v).
EXTENSION_VERSION_MATCH_PATTERN='[.0-9]+'

function list_available_versions() {
  list_github_releases "cloudflare" "cloudflared"
}
# --

function populate_sysext_root() {
  local sysextroot="$1"
  local arch="$2"
  local version="$3"

  # Cloudflared release assets use amd64 / arm64 identifiers.
  local rel_arch="$(arch_transform 'x86-64' 'amd64' "$arch")"

  mkdir -p "${sysextroot}/usr/bin"
  curl --parallel --fail --silent --show-error --location \
    -o "${sysextroot}/usr/bin/cloudflared" \
    "https://github.com/cloudflare/cloudflared/releases/download/${version}/cloudflared-linux-${rel_arch}"
  chmod +x "${sysextroot}/usr/bin/cloudflared"

  # Static service unit + (optional) auto-start drop-in are shipped from files/
  # and copied by the bakery before this function runs.
}
# --
