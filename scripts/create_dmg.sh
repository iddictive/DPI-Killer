#!/bin/bash
# scripts/create_dmg.sh
set -euo pipefail

APP_NAME="DPIKiller"
APP_BUNDLE=".build.noindex/${APP_NAME}.app"
DMG_NAME="${APP_NAME}.dmg"

# Check if app exists
if [ ! -d "${APP_BUNDLE}" ]; then
    echo "Error: ${APP_BUNDLE} not found. Run build.sh first."
    exit 1
fi

echo "Creating DMG for ${APP_NAME}..."

# Remove old DMG if exists
rm -f "${DMG_NAME}"

# Create a temporary directory for the DMG structure
DMG_TEMP_DIR="dmg_temp"
rm -rf "${DMG_TEMP_DIR}"
mkdir -p "${DMG_TEMP_DIR}"

# Copy the app bundle
ditto "${APP_BUNDLE}" "${DMG_TEMP_DIR}/${APP_NAME}.app"

# Create a symlink to Applications
ln -s /Applications "${DMG_TEMP_DIR}/Applications"

# Create the DMG using -srcfolder (no mount required, perfect for CI)
hdiutil create -volname "${APP_NAME}" -srcfolder "${DMG_TEMP_DIR}" -ov -format UDZO "${DMG_NAME}"

# Cleanup
rm -rf "${DMG_TEMP_DIR}"

echo "Successfully created ${DMG_NAME}"
