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

# 1. Download the explicit compiled x86_64 rustup installer binary directly from the source assets CDN
curl -fsSL --retry 3 --retry-delay 5 \
  -o /tmp/rustup-init \
  https://rust-lang.org

# 2. Grant execution rights and run the setup flags directly without standard shell wrapper pipes
chmod +x /tmp/rustup-init
/tmp/rustup-init -y --default-toolchain stable --profile minimal

# 3. Clean up the installer binary and map the freshly minted environment paths
rm /tmp/rustup-init
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
