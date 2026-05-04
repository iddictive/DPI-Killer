#!/bin/bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"

APP_NAME="DPIKiller.app"
OUTPUT_APP="${DPIKILLER_LOCAL_SIGNED_APP:-/tmp/DPIKiller-local-signed.app}"
SIGNING_IDENTITY="${DPIKILLER_SIGNING_IDENTITY:-}"

detect_identity() {
    security find-identity -v -p codesigning 2>/dev/null \
        | awk -F'"' '/Apple Development:/ && $0 !~ /CSSMERR_TP_CERT_REVOKED/ { print $2; exit }'
}

if [ -z "$SIGNING_IDENTITY" ]; then
    SIGNING_IDENTITY="$(detect_identity)"
fi

if [ -z "$SIGNING_IDENTITY" ]; then
    echo "No Apple Development signing identity was found in the keychain."
    exit 1
fi

echo "Building unsigned app bundle..."
DPIKILLER_DERIVED_DATA_DIR="${DPIKILLER_DERIVED_DATA_DIR:-/tmp/dpikiller-local-unsigned}" \
SKIP_VERSION_BUMP="${SKIP_VERSION_BUMP:-1}" ./build.sh >/dev/null

rm -rf "$OUTPUT_APP"
cp -R "$APP_NAME" "$OUTPUT_APP"
find "$OUTPUT_APP" -exec xattr -c {} +

rm -rf "$OUTPUT_APP/Contents/Library/SystemExtensions"

APPEX_PATH="$OUTPUT_APP/Contents/PlugIns/DPIKillerTunnel.appex"
if [ ! -d "$APPEX_PATH" ]; then
    echo "Embedded Packet Tunnel extension is missing."
    exit 1
fi

echo "Signing Packet Tunnel app extension with:"
echo "  $SIGNING_IDENTITY"
codesign --force --sign "$SIGNING_IDENTITY" --timestamp=none \
    --entitlements "Extensions/PacketTunnel/PacketTunnel.entitlements" \
    "$APPEX_PATH"

echo "Signing app bundle..."
codesign --force --sign "$SIGNING_IDENTITY" --timestamp=none \
    --entitlements "DPIKiller.entitlements" \
    "$OUTPUT_APP"

codesign --verify --deep --strict --verbose=2 "$OUTPUT_APP"

echo
echo "Signed local VPN build:"
echo "  $OUTPUT_APP"
echo
echo "App entitlements:"
codesign -d --entitlements :- "$OUTPUT_APP" 2>/dev/null
echo
echo "Tunnel entitlements:"
codesign -d --entitlements :- "$APPEX_PATH" 2>/dev/null
