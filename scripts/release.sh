#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."

VERSION="${1:-}"
VERSION="${VERSION#v}"
NOTES="${2:-}"
if [[ ! "$VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] || [ ! -f "$NOTES" ]; then
    echo "Usage: DPIKILLER_LOCAL_SIGN_IDENTITY=<identity> bash scripts/release.sh <version> <notes-file>"
    exit 1
fi
: "${DPIKILLER_LOCAL_SIGN_IDENTITY:?A signed release is required to preserve network helper access}"
if [ "$(git branch --show-current)" != main ] || [ -n "$(git status --porcelain)" ]; then
    echo "Release requires a clean, committed main checkout."
    exit 1
fi
source scripts/version.sh
if [ "$(current_source_version Info.plist)" != "$VERSION" ]; then
    echo "Commit version $VERSION in the source before releasing."
    exit 1
fi
REPOSITORY="$(gh repo view --json nameWithOwner --jq .nameWithOwner)"
if [ "$REPOSITORY" != "iddictive/DPI-Killer" ]; then
    echo "Unexpected release repository: $REPOSITORY"
    exit 1
fi
git fetch origin main --tags
if [ "$(git rev-list --count HEAD..origin/main)" != 0 ]; then
    echo "Remote main changed; integrate it before releasing."
    exit 1
fi
if git rev-parse --verify "refs/tags/v$VERSION" >/dev/null 2>&1; then
    echo "Tag v$VERSION already exists; refusing to replace it."
    exit 1
fi
DPIKILLER_VERSION="$VERSION" SKIP_VERSION_BUMP=1 bash build.sh
codesign --verify --deep --strict .build.noindex/DPIKiller.app
codesign --verify --strict .build.noindex/DPIKiller.app/Contents/Library/HelperTools/DPIKillerNetworkHelper
if [ -n "$(git status --porcelain)" ]; then
    echo "Build changed tracked source; commit and retry before publishing."
    exit 1
fi
bash scripts/create_dmg.sh
hdiutil verify DPIKiller.dmg
git tag -a "v$VERSION" -m "DPI Killer $VERSION"
git push origin main "v$VERSION"
gh release create "v$VERSION" DPIKiller.dmg --verify-tag --draft \
    --title "DPI Killer v$VERSION" --notes-file "$NOTES"
echo "Draft uploaded. Verify the downloaded DMG and installed app before publishing it."
