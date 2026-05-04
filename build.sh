#!/bin/bash
set -euo pipefail
APP_NAME="DPIKiller"
APP_BUNDLE="${APP_NAME}.app"
VERSION_PREFIX="3.0"
DERIVED_DATA_DIR=".xcodebuild"
DERIVED_DATA_DIR="${DPIKILLER_DERIVED_DATA_DIR:-$DERIVED_DATA_DIR}"

detect_development_team() {
    security find-identity -v -p codesigning 2>/dev/null \
        | sed -n 's/.*Apple Development:.*(\([A-Z0-9]\{10\}\)).*/\1/p' \
        | head -n 1
}

update_version_in_plist() {
    local plist_path="$1"
    local full_version="$2"
    local build_num="$3"

    if [ -f "$plist_path" ] && command -v plutil >/dev/null 2>&1; then
        plutil -replace CFBundleShortVersionString -string "$full_version" "$plist_path" 2>/dev/null || true
        plutil -replace CFBundleVersion -string "$build_num" "$plist_path" 2>/dev/null || true
    fi
}

update_project_yml_versions() {
    local full_version="$1"
    local build_num="$2"

    python3 - "$full_version" "$build_num" <<'PY'
import pathlib
import re
import sys

full_version = sys.argv[1]
build_num = sys.argv[2]
path = pathlib.Path("project.yml")
text = path.read_text()
text = re.sub(r'(?m)^(\s*MARKETING_VERSION:\s*).+$', rf'\g<1>{full_version}', text, count=1)
text = re.sub(r'(?m)^(\s*CURRENT_PROJECT_VERSION:\s*).+$', rf'\g<1>{build_num}', text, count=1)
path.write_text(text)
PY
}

VERSION_FILE=".version"
if [ ! -f "$VERSION_FILE" ]; then
    echo "0" > "$VERSION_FILE"
fi

BUILD_NUM=$(cat "$VERSION_FILE")
if [ "${SKIP_VERSION_BUMP:-0}" != "1" ]; then
    BUILD_NUM=$((BUILD_NUM + 1))
    echo "$BUILD_NUM" > "$VERSION_FILE"
fi
FULL_VERSION="${VERSION_PREFIX}.${BUILD_NUM}"

# Sync version files for both the legacy bundle and the Xcode Packet Tunnel path.
update_version_in_plist "Info.plist" "$FULL_VERSION" "$BUILD_NUM"
update_version_in_plist "Xcode/DPIKiller-Info.plist" "$FULL_VERSION" "$BUILD_NUM"
update_version_in_plist "Extensions/PacketTunnel/Info.plist" "$FULL_VERSION" "$BUILD_NUM"
if [ -f "project.yml" ]; then
    update_project_yml_versions "$FULL_VERSION" "$BUILD_NUM"
fi

rm -rf "${APP_BUNDLE}"
rm -rf "${DERIVED_DATA_DIR}"

if command -v xcodegen >/dev/null 2>&1 && [ -f "project.yml" ]; then
    ./scripts/generate_xcode_project.sh >/dev/null

    xcodebuild_args=(
        -project DPIKiller.xcodeproj
        -scheme DPIKiller
        -configuration Release
        -derivedDataPath "${DERIVED_DATA_DIR}"
    )

    if [ "${DPIKILLER_SIGNED_BUILD:-0}" = "1" ]; then
        DEVELOPMENT_TEAM_VALUE="${DPIKILLER_DEVELOPMENT_TEAM:-$(detect_development_team)}"
        CODE_SIGN_IDENTITY_VALUE="${DPIKILLER_CODE_SIGN_IDENTITY:-Apple Development}"

        if [ -z "${DEVELOPMENT_TEAM_VALUE}" ]; then
            echo "Signed build requested, but no Apple Development team was detected."
            exit 1
        fi

        xcodebuild_args+=(
            -allowProvisioningUpdates
            CODE_SIGN_STYLE=Automatic
            DEVELOPMENT_TEAM="${DEVELOPMENT_TEAM_VALUE}"
            CODE_SIGN_IDENTITY="${CODE_SIGN_IDENTITY_VALUE}"
        )
    else
        xcodebuild_args+=(
            CODE_SIGNING_ALLOWED=NO
        )
    fi

    xcodebuild "${xcodebuild_args[@]}" build >/dev/null

    cp -R "${DERIVED_DATA_DIR}/Build/Products/Release/${APP_BUNDLE}" "${APP_BUNDLE}"

    embedded_appex="${APP_BUNDLE}/Contents/PlugIns/DPIKillerTunnel.appex"
    if [ -d "${embedded_appex}" ]; then
        mkdir -p "${APP_BUNDLE}/Contents/Library/SystemExtensions"
        rm -rf "${APP_BUNDLE}/Contents/Library/SystemExtensions/DPIKillerTunnel.systemextension"
        cp -R "${embedded_appex}" "${APP_BUNDLE}/Contents/Library/SystemExtensions/DPIKillerTunnel.systemextension"
    fi
else
    mkdir -p "${APP_BUNDLE}/Contents/MacOS"
    mkdir -p "${APP_BUNDLE}/Contents/Resources"

    swift_sources=("main.swift")
    while IFS= read -r file; do
        swift_sources+=("$file")
    done < <(find Sources -name '*.swift' | sort)

    MODULE_CACHE_DIR="${TMPDIR:-/tmp}/dpikiller-module-cache"
    mkdir -p "${MODULE_CACHE_DIR}"

    swiftc \
        -module-cache-path "${MODULE_CACHE_DIR}" \
        -o "${APP_BUNDLE}/Contents/MacOS/${APP_NAME}" \
        "${swift_sources[@]}" \
        -framework Cocoa \
        -framework Foundation \
        -framework WebKit \
        -framework Network \
        -framework NetworkExtension \
        -framework SystemExtensions

    cp Info.plist "${APP_BUNDLE}/Contents/Info.plist"
fi

mkdir -p "${APP_BUNDLE}/Contents/Resources"
mkdir -p "${APP_BUNDLE}/Contents/MacOS"
cp assets/AppIcon.icns "${APP_BUNDLE}/Contents/Resources/AppIcon.icns"
cp README.md "${APP_BUNDLE}/Contents/Resources/README.md"
mkdir -p "${APP_BUNDLE}/Contents/Resources/assets"
cp assets/banner.png "${APP_BUNDLE}/Contents/Resources/assets/banner.png"

# Copy optional bundled backends
if [ -f "ciadpi-binary" ]; then
    cp ciadpi-binary "${APP_BUNDLE}/Contents/MacOS/ciadpi-binary"
    chmod +x "${APP_BUNDLE}/Contents/MacOS/ciadpi-binary"
fi

if [ -f "spoofdpi-patched" ]; then
    cp spoofdpi-patched "${APP_BUNDLE}/Contents/MacOS/spoofdpi-binary"
    chmod +x "${APP_BUNDLE}/Contents/MacOS/spoofdpi-binary"
fi

echo "Build complete: ${APP_BUNDLE}"

if [[ "${1:-}" == "--dmg" ]]; then
    bash scripts/create_dmg.sh
fi

echo "To add to Login Items, run: osascript -e 'tell application \"System Events\" to make login item at end with properties {path:\"$(pwd)/${APP_BUNDLE}\", hidden:false}'"
