#!/bin/bash
# Build the audited macOS backend, never an ambient/root tracked binary.
set -euo pipefail
if [ "$#" -ne 1 ] || [ "$(uname -s)" != Darwin ]; then
    echo "Usage (macOS): $0 /absolute/output/ciadpi-binary" >&2
    exit 2
fi
case "$1" in /*) ;; *) echo "Output must be absolute" >&2; exit 2 ;; esac
OUTPUT="$1"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PIN=ba532298de7b28cfe854aea83d061369d13ca290
SHA=c7211cfc0729d213219be9b67d774e375d75ae53bbf18b6af1967f06919bbac4
WORK="$(mktemp -d "${TMPDIR:-/tmp}/spoof-ciadpi.XXXXXXXX")"
cleanup() { /bin/rm -rf "$WORK"; }
trap cleanup EXIT
trap 'exit 130' INT
trap 'exit 143' TERM
curl --fail --location --silent --show-error --connect-timeout 15 --max-time 60 \
    "https://codeload.github.com/hufrea/byedpi/tar.gz/$PIN" -o "$WORK/source.tar.gz"
printf '%s  %s\n' "$SHA" "$WORK/source.tar.gz" | shasum -a 256 -c -
tar -xzf "$WORK/source.tar.gz" -C "$WORK"
SOURCE="$WORK/byedpi-$PIN"
SDK="$(xcrun --sdk macosx --show-sdk-path)"
patch --batch --fuzz=0 -d "$SOURCE" -p1 < "$ROOT/Backends/ciadpi/async-dns.patch"
cp "$ROOT/Backends/ciadpi/async_dns.c" "$ROOT/Backends/ciadpi/async_dns.h" "$SOURCE/"
for ARCH in arm64 x86_64; do
    make -C "$SOURCE" clean >/dev/null
    make -C "$SOURCE" -j4 CC="$(xcrun --find clang)" \
        CFLAGS="-isysroot $SDK -arch $ARCH -mmacosx-version-min=13.0 -I. -std=c99 -O2 -Wall -Wextra -Wno-unused-parameter -Wno-unused -pedantic" \
        LDFLAGS="-isysroot $SDK -arch $ARCH -mmacosx-version-min=13.0 -pthread"
    cp "$SOURCE/ciadpi" "$WORK/ciadpi-$ARCH"
done
xcrun lipo -create "$WORK/ciadpi-arm64" "$WORK/ciadpi-x86_64" -output "$WORK/ciadpi"
mkdir -p "$(dirname "$OUTPUT")"
install -m 755 "$WORK/ciadpi" "$OUTPUT"
echo "Built ciadpi $PIN + macOS async DNS: $OUTPUT"
