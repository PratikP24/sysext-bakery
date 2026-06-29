#!/usr/bin/env bash
# vim: et ts=2 syn=bash
#
# ZeroTier One system extension (PROPOSAL — corrected bakery-format recipe).
#
# Place this directory as  <bakery-clone>/zerotier.sysext/  and build with:
#   ./bakery.sh create zerotier 1.14.2 --sysupdate true
#
# Rationale for build-from-source:
#   ZeroTier publishes NO static x86_64 Linux binary tarball. The official
#   download page recommends `curl https://install.zerotier.com | bash` plus
#   distro packages; download.zerotier.com/RELEASES/<ver>/dist/ holds only
#   Windows .msi / macOS .pkg / Android .apk and per-distro subdirs.
#   (Verified 2026-06-18.) The bakery-native pattern for "no upstream static
#   binary" is to compile inside an ephemeral container — exactly what
#   keepalived.sysext/create.sh does. We use Debian (glibc) to match Flatcar's
#   glibc userland.
#
# `make install DESTDIR=...` puts the binary at /usr/sbin/zerotier-one with
#   zerotier-cli / zerotier-idtool symlinks (verified against make-linux.mk).
#   On Flatcar /usr/sbin is a symlink to /usr/bin, so we relocate to /usr/bin.

# Reload service units on merge so systemd sees zerotier-one.service.
RELOAD_SERVICES_ON_MERGE="true"

# ZeroTier tags upstream as plain "1.14.2" (no leading v).
EXTENSION_VERSION_MATCH_PATTERN='[.0-9]+'

function list_available_versions() {
  # ZeroTier publishes GitHub releases tagged like "1.14.2".
  list_github_releases "zerotier" "ZeroTierOne"
}
# --

function populate_sysext_root() {
  local sysextroot="$1"
  local arch="$2"
  local version="$3"

  local img_arch="$(arch_transform 'x86-64' 'amd64' "$arch")"
  img_arch="$(arch_transform 'arm64' 'arm64/v8' "$img_arch")"

  announce "Building ZeroTier ${version} for ${arch} (Debian container)"

  local user_group="$(id -u):$(id -g)"
  local image="docker.io/debian:bookworm"

  # build.sh is mounted into the container and compiles ZeroTier from the
  # tagged source tarball, then `make install` into /install_root.
  echo "${scriptroot}/zerotier.sysext/build.sh => $(pwd)"
  
  cp "${scriptroot}/zerotier.sysext/build.sh" .
  cp "${scriptroot}/zerotier.sysext/build.sh" "$(pwd)/build.sh"
  chmod +x "$(pwd)/build.sh"
  ls -l "$(pwd)/build.sh"

  docker run --rm -i \
    -v "$(pwd)":/install_root \
    --platform "linux/${img_arch}" \
    --pull always \
    "${image}" \
    /install_root/build.sh "${version}" "${user_group}"

  # ZeroTier's make install lands binaries in /usr/sbin; Flatcar's /usr/sbin
  # is a symlink to /usr/bin, so relocate (same fix keepalived.sysext uses).
  mkdir -p usr/bin
  mv usr/sbin/zerotier-one usr/bin/zerotier-one
  # Re-create the cli / idtool symlinks pointing at the relocated binary.
  ln -sf zerotier-one usr/bin/zerotier-cli
  ln -sf zerotier-one usr/bin/zerotier-idtool
  rm -rf usr/sbin

  # Ship a systemd service + auto-start Upholds drop-in from files/ (copied by
  # bakery before this function runs). Nothing else to do for units here.

  cp -aR usr "${sysextroot}/"
}
# --
