#!/bin/bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"

TEAM_ID="${DPIKILLER_TEAM_ID:-${1:-}}"
SIGNING_IDENTITY="${DPIKILLER_SIGNING_IDENTITY:-${2:-}}"
PROFILE_SPECIFIER="${DPIKILLER_PROFILE_SPECIFIER:-${3:-}}"
DERIVED_DATA_PATH="${DPIKILLER_SIGNED_DERIVED_DATA:-/tmp/dpikiller-signed}"

if [ -z "$TEAM_ID" ] || [ -z "$SIGNING_IDENTITY" ]; then
    cat <<'EOF'
Usage:
  DPIKILLER_TEAM_ID=XXXXXXXXXX \
  DPIKILLER_SIGNING_IDENTITY="Developer ID Application: Example (XXXXXXXXXX)" \
  DPIKILLER_PROFILE_SPECIFIER="Your Network Extension Profile" \
  ./scripts/build_signed_vpn_app.sh

Or pass arguments:
  ./scripts/build_signed_vpn_app.sh <TEAM_ID> "<SIGNING_IDENTITY>" ["PROFILE_SPECIFIER"]
EOF
    exit 1
fi

if ! command -v xcodegen >/dev/null 2>&1; then
    echo "xcodegen is required."
    exit 1
fi

if ! command -v xcodebuild >/dev/null 2>&1; then
    echo "xcodebuild is required."
    exit 1
fi

if ! security find-identity -v -p codesigning 2>/dev/null | grep -Fq "$SIGNING_IDENTITY"; then
    echo "Signing identity not found in keychain:"
    echo "  $SIGNING_IDENTITY"
    exit 1
fi

APP_ENTITLEMENTS="DPIKiller.developer-id.entitlements"
TUNNEL_ENTITLEMENTS="Extensions/PacketTunnel/PacketTunnel.developer-id.entitlements"

if ! plutil -extract "com.apple.developer.networking.networkextension" xml1 -o - "$APP_ENTITLEMENTS" 2>/dev/null | grep -Fq "packet-tunnel-provider-systemextension"; then
    echo "$APP_ENTITLEMENTS is missing packet-tunnel-provider-systemextension."
    exit 1
fi

if ! plutil -extract "com.apple.developer.networking.networkextension" xml1 -o - "$TUNNEL_ENTITLEMENTS" 2>/dev/null | grep -Fq "packet-tunnel-provider-systemextension"; then
    echo "$TUNNEL_ENTITLEMENTS is missing packet-tunnel-provider-systemextension."
    exit 1
fi

restore_entitlements() {
    if [ -n "${TMP_APP_ENTITLEMENTS:-}" ] && [ -f "${TMP_APP_ENTITLEMENTS}" ]; then
        cp "${TMP_APP_ENTITLEMENTS}" DPIKiller.entitlements
        rm -f "${TMP_APP_ENTITLEMENTS}"
    fi
    if [ -n "${TMP_TUNNEL_ENTITLEMENTS:-}" ] && [ -f "${TMP_TUNNEL_ENTITLEMENTS}" ]; then
        cp "${TMP_TUNNEL_ENTITLEMENTS}" Extensions/PacketTunnel/PacketTunnel.entitlements
        rm -f "${TMP_TUNNEL_ENTITLEMENTS}"
    fi
}

TMP_APP_ENTITLEMENTS="$(mktemp)"
TMP_TUNNEL_ENTITLEMENTS="$(mktemp)"
cp DPIKiller.entitlements "${TMP_APP_ENTITLEMENTS}"
cp Extensions/PacketTunnel/PacketTunnel.entitlements "${TMP_TUNNEL_ENTITLEMENTS}"
trap restore_entitlements EXIT

cp "$APP_ENTITLEMENTS" DPIKiller.entitlements
cp "$TUNNEL_ENTITLEMENTS" Extensions/PacketTunnel/PacketTunnel.entitlements

./scripts/generate_xcode_project.sh >/dev/null
rm -rf "$DERIVED_DATA_PATH"

xcodebuild_args=(
    -project DPIKiller.xcodeproj
    -scheme DPIKiller
    -configuration Release
    -derivedDataPath "$DERIVED_DATA_PATH"
    CODE_SIGNING_ALLOWED=YES
    CODE_SIGN_STYLE=Manual
    DEVELOPMENT_TEAM="$TEAM_ID"
    CODE_SIGN_IDENTITY="$SIGNING_IDENTITY"
)

if [ -n "$PROFILE_SPECIFIER" ]; then
    xcodebuild_args+=(PROVISIONING_PROFILE_SPECIFIER="$PROFILE_SPECIFIER")
else
    xcodebuild_args+=(PROVISIONING_PROFILE_SPECIFIER="")
fi

echo "Building signed VPN bundle..."
echo "  TEAM_ID=$TEAM_ID"
echo "  SIGNING_IDENTITY=$SIGNING_IDENTITY"
if [ -n "$PROFILE_SPECIFIER" ]; then
    echo "  PROFILE_SPECIFIER=$PROFILE_SPECIFIER"
fi

xcodebuild "${xcodebuild_args[@]}" build

APP_PATH="$DERIVED_DATA_PATH/Build/Products/Release/DPIKiller.app"
if [ ! -d "$APP_PATH" ]; then
    echo "Signed app was not produced."
    exit 1
fi

echo "Signed app built:"
echo "  $APP_PATH"
echo
echo "Next checks:"
echo "  codesign -d --entitlements :- \"$APP_PATH\""
echo "  systemextensionsctl list | grep DPIKiller"
