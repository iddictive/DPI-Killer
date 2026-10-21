#!/bin/bash
set -euo pipefail
APP_NAME="DPIKiller"
APP_BUNDLE_NAME="${APP_NAME}.app"
APP_BUNDLE=".build.noindex/${APP_BUNDLE_NAME}"
DERIVED_DATA_DIR=".xcodebuild"
DERIVED_DATA_DIR="${DPIKILLER_DERIVED_DATA_DIR:-$DERIVED_DATA_DIR}"

detect_development_team() {
    security find-identity -v -p codesigning 2>/dev/null \
        | sed -n 's/.*Apple Development:.*(\([A-Z0-9]\{10\}\)).*/\1/p' \
        | head -n 1
}

source scripts/version.sh
if [ -z "${DPIKILLER_VERSION:-}" ]; then
    if [ "${SKIP_VERSION_BUMP:-0}" = "1" ]; then
        export DPIKILLER_BUMP_VERSION=0
    else
        export DPIKILLER_BUMP_VERSION=1
    fi
fi
FULL_VERSION="$(resolve_dpikiller_version "Info.plist")"

mkdir -p .build.noindex
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

    cp -R "${DERIVED_DATA_DIR}/Build/Products/Release/${APP_BUNDLE_NAME}" "${APP_BUNDLE}"

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
        -framework SystemExtensions \
        -framework ServiceManagement

    helper_sources=(
        Helpers/NetworkSettings/main.swift
        Sources/Shared/NetworkSettingsProtocol.swift
        Sources/Services/SystemProxyController.swift
        Sources/Core/BypassEngine.swift
        Sources/Core/SettingsModels.swift
        Sources/Core/Localization.swift
        Sources/Core/Logging.swift
    )
    mkdir -p "${APP_BUNDLE}/Contents/Library/HelperTools"
    swiftc -D DPIKILLER_NETWORK_HELPER \
        -module-cache-path "${MODULE_CACHE_DIR}" \
        -o "${APP_BUNDLE}/Contents/Library/HelperTools/DPIKillerNetworkHelper" \
        "${helper_sources[@]}" \
        -framework Foundation -framework SystemConfiguration -framework Security

    cp Info.plist "${APP_BUNDLE}/Contents/Info.plist"
fi

mkdir -p "${APP_BUNDLE}/Contents/Library/LaunchDaemons"
cp Helpers/NetworkSettings/com.antigravity.DPIKiller.NetworkHelper.plist \
    "${APP_BUNDLE}/Contents/Library/LaunchDaemons/"

mkdir -p "${APP_BUNDLE}/Contents/Resources"
mkdir -p "${APP_BUNDLE}/Contents/MacOS"
cp assets/AppIcon.icns "${APP_BUNDLE}/Contents/Resources/AppIcon.icns"
cp README.md "${APP_BUNDLE}/Contents/Resources/README.md"
mkdir -p "${APP_BUNDLE}/Contents/Resources/assets"
cp assets/banner.png "${APP_BUNDLE}/Contents/Resources/assets/banner.png"

# The app and CI consume the same pinned, repaired engine recipe.
bash scripts/build_ciadpi.sh "$PWD/${APP_BUNDLE}/Contents/MacOS/ciadpi-binary"
cp Backends/ciadpi/LICENSE "${APP_BUNDLE}/Contents/Resources/ciadpi-LICENSE"

if [ -f "spoofdpi-patched" ]; then
    cp spoofdpi-patched "${APP_BUNDLE}/Contents/MacOS/spoofdpi-binary"
    chmod +x "${APP_BUNDLE}/Contents/MacOS/spoofdpi-binary"
fi

if [ -n "${DPIKILLER_LOCAL_SIGN_IDENTITY:-}" ]; then
    /usr/libexec/PlistBuddy -c 'Add :DPIKillerLocalNetworkHelper bool true' "${APP_BUNDLE}/Contents/Info.plist"
    codesign --force --sign "${DPIKILLER_LOCAL_SIGN_IDENTITY}" \
        --identifier com.antigravity.DPIKiller.NetworkHelper \
        "${APP_BUNDLE}/Contents/Library/HelperTools/DPIKillerNetworkHelper"
    codesign --force --sign "${DPIKILLER_LOCAL_SIGN_IDENTITY}" \
        "${APP_BUNDLE}/Contents/MacOS/ciadpi-binary"
    codesign --force --deep --sign "${DPIKILLER_LOCAL_SIGN_IDENTITY}" "${APP_BUNDLE}"
    codesign --verify --deep --strict "${APP_BUNDLE}"
fi

echo "Build complete: ${APP_BUNDLE}"

if [[ "${1:-}" == "--dmg" ]]; then
    bash scripts/create_dmg.sh
fi

echo "To add to Login Items, run: osascript -e 'tell application \"System Events\" to make login item at end with properties {path:\"$(pwd)/${APP_BUNDLE}\", hidden:false}'"
