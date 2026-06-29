#!/usr/bin/env bash
# vim: et ts=2 syn=bash
#
# ZeroTier One in-container build script (PROPOSAL).
# Mounted into a Debian container by zerotier.sysext/create.sh and run as:
#   /install_root/build.sh <version> <uid:gid>
#
# Produces:  /install_root/usr/sbin/zerotier-one  (+ cli/idtool symlinks)
# create.sh then relocates these to /usr/bin for Flatcar.

set -euo pipefail

VER="${1#v}"          # ZeroTier tags are plain "1.14.2"; strip any leading v.
USER_GROUP="$2"       # chown outputs back to the host user.

export DEBIAN_FRONTEND=noninteractive
apt-get update
# Minimal toolchain to compile ZeroTier One (GCC >= 8 / clang >= 5 required).
apt-get install -y --no-install-recommends \
  build-essential clang make pkg-config \
  libssl-dev curl ca-certificates tar

# Install a modern, official Rust toolchain capable of reading Lockfile v4
curl --proto '=https' --tlsv1.2 -sSf https://rustup.rs | sh -s -- -y --default-toolchain stable
export PATH="/root/.cargo/bin:$PATH"

cd /tmp
# Build from the tagged GitHub source archive (no static binary is published).
curl -fsSL --retry 3 --retry-delay 5 \
  -o zerotier-src.tar.gz \
  "https://github.com/zerotier/ZeroTierOne/archive/refs/tags/${VER}.tar.gz"
mkdir -p src
tar --strip-components=1 -xf zerotier-src.tar.gz -C src
cd src

# Compile. ZeroTier's Linux makefile auto-detects clang/clang++ if present.
make -j"$(nproc)"

# `make install DESTDIR=...` writes /usr/sbin/zerotier-one + cli/idtool symlinks.
make install DESTDIR=/install_root

# Hand ownership of the produced tree back to the host build user.
chown -R "${USER_GROUP}" /install_root/usr
