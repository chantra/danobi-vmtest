#!/bin/bash
#
# Build a release version of vmtest for a list of architectures.
# The resulting binaries will be copied in the current directory and named vmtest-<arch>.
#
# This script assumes it is run on a Debian based system.
#
# Run this on your root host inside vmtest repository.
#
# Usage:
#   ./scripts/build_release.sh
#   ./scripts/build_kernel.sh x86_64 aarch64

set -eu


function gnu_to_debian() {
    # Funtion to convert an architecture in Debian to its GNU equivalent,
    # e.g amd64 -> x86_64
    # CPUTABLE contains a list of debian_arch\tgnu_arch per line
    # Compare of the first field matches and print the second one.
    awk -v gnu_arch="$1" '$2 ~ gnu_arch {print $1}' /usr/share/dpkg/cputable
}

ARCHS=(x86_64 aarch64 s390x)

if [[ $# -gt 0 ]]
then
    ARCHS=("$@")
fi

# Install the required toolchain for cross-compilation
X_ARCHS=()
for arch in "${ARCHS[@]}"; do
    if [[ "${arch}" == "$(uname -m)" ]]; then
        continue
    fi
    X_ARCHS+=("${arch}")
done
ARCHS_TO_EXPAND=$(IFS=, ; echo "${X_ARCHS[*]}")
eval sudo apt install -y "gcc-{${ARCHS_TO_EXPAND//_/-}}-linux-gnu"
eval rustup target add "{${ARCHS_TO_EXPAND}}-unknown-linux-gnu"

for arch in "${ARCHS[@]}"; do
    # Compile the binary
    RUSTFLAGS="-C target-feature=+crt-static -C linker=/usr/bin/${arch}-linux-gnu-gcc" cargo build --release --target "${arch}-unknown-linux-gnu"
    cp "./target/${arch}-unknown-linux-gnu/release/vmtest" "./vmtest-$(gnu_to_debian "${arch}")"
done
