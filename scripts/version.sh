#!/bin/bash

set -euo pipefail

DPIKILLER_VERSION_PREFIX="${DPIKILLER_VERSION_PREFIX:-4.0}"

plist_get() {
    local plist=$1
    local key=$2
    /usr/libexec/PlistBuddy -c "Print :$key" "$plist" 2>/dev/null || true
}

plist_set() {
    local plist=$1
    local key=$2
    local value=$3
    /usr/libexec/PlistBuddy -c "Set :$key $value" "$plist" 2>/dev/null || \
        /usr/libexec/PlistBuddy -c "Add :$key string $value" "$plist"
}

version_sort_key() {
    local version=${1#v}
    local major minor patch
    IFS='.' read -r major minor patch _ <<< "$version"

    [[ "$major" =~ ^[0-9]+$ ]] || major=0
    [[ "$minor" =~ ^[0-9]+$ ]] || minor=0
    [[ "$patch" =~ ^[0-9]+$ ]] || patch=0

    printf "%08d.%08d.%08d\n" "$major" "$minor" "$patch"
}

version_patch() {
    local version=${1#v}
    local major minor patch
    IFS='.' read -r major minor patch _ <<< "$version"
    [[ "$patch" =~ ^[0-9]+$ ]] || patch=0
    echo "$patch"
}

normalize_dpikiller_version() {
    local version=${1#v}

    if [[ "$version" =~ ^[0-9]+$ ]]; then
        echo "${DPIKILLER_VERSION_PREFIX}.${version}"
        return
    fi

    if [[ "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        echo "$version"
        return
    fi

    echo "${DPIKILLER_VERSION_PREFIX}.0"
}

next_dpikiller_version() {
    local current
    local major minor patch

    current="$(normalize_dpikiller_version "${1:-}")"
    IFS='.' read -r major minor patch _ <<< "$current"

    [[ "$major" =~ ^[0-9]+$ ]] || major=3
    [[ "$minor" =~ ^[0-9]+$ ]] || minor=0
    [[ "$patch" =~ ^[0-9]+$ ]] || patch=0

    if [ "$major" -lt 3 ]; then
        major=3
        minor=0
        patch=0
    fi

    echo "$major.$minor.$((patch + 1))"
}

max_dpikiller_version() {
    local first
    local second

    first="$(normalize_dpikiller_version "${1:-}")"
    second="$(normalize_dpikiller_version "${2:-}")"

    if [[ "$(version_sort_key "$second")" > "$(version_sort_key "$first")" ]]; then
        echo "$second"
    else
        echo "$first"
    fi
}

latest_dpikiller_tag_version() {
    git tag -l "v${DPIKILLER_VERSION_PREFIX}.*" 2>/dev/null \
        | sed 's/^v//' \
        | awk -F. '$1 ~ /^[0-9]+$/ && $2 ~ /^[0-9]+$/ && $3 ~ /^[0-9]+$/ { print }' \
        | sort -t. -k1,1n -k2,2n -k3,3n \
        | tail -n 1
}

current_source_version() {
    local plist=$1
    local current

    current="$(plist_get "$plist" "CFBundleShortVersionString")"
    if [ -z "$current" ] && [ -f ".version" ]; then
        current="$(cat .version)"
    fi

    normalize_dpikiller_version "${current:-0}"
}

next_release_version() {
    local plist=$1
    local current
    local latest_tag
    local base

    current="$(current_source_version "$plist")"
    latest_tag="$(latest_dpikiller_tag_version)"
    base="$(max_dpikiller_version "$current" "${latest_tag:-}")"

    if [ -z "$latest_tag" ]; then
        echo "$current"
        return
    fi

    if [ -n "$latest_tag" ] &&
        [ "$(max_dpikiller_version "$current" "$latest_tag")" = "$current" ] &&
        [[ "$(version_sort_key "$current")" > "$(version_sort_key "$latest_tag")" ]]; then
        echo "$current"
    else
        next_dpikiller_version "$base"
    fi
}

update_project_yml_versions() {
    local full_version=$1
    local build_num=$2

    [ -f "project.yml" ] || return 0

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

resolve_dpikiller_version() {
    local plist=${1:-Info.plist}
    local version
    local build_num

    if [ -n "${DPIKILLER_VERSION:-}" ]; then
        version="$(normalize_dpikiller_version "$DPIKILLER_VERSION")"
    elif [ "${DPIKILLER_BUMP_VERSION:-0}" = "1" ]; then
        version="$(next_release_version "$plist")"
    else
        version="$(current_source_version "$plist")"
    fi

    build_num="$version"

    plist_set "Info.plist" "CFBundleShortVersionString" "$version"
    plist_set "Info.plist" "CFBundleVersion" "$build_num"
    [ -f "Xcode/DPIKiller-Info.plist" ] && plist_set "Xcode/DPIKiller-Info.plist" "CFBundleShortVersionString" '$(MARKETING_VERSION)'
    [ -f "Xcode/DPIKiller-Info.plist" ] && plist_set "Xcode/DPIKiller-Info.plist" "CFBundleVersion" '$(CURRENT_PROJECT_VERSION)'
    [ -f "Extensions/PacketTunnel/Info.plist" ] && plist_set "Extensions/PacketTunnel/Info.plist" "CFBundleShortVersionString" '$(MARKETING_VERSION)'
    [ -f "Extensions/PacketTunnel/Info.plist" ] && plist_set "Extensions/PacketTunnel/Info.plist" "CFBundleVersion" '$(CURRENT_PROJECT_VERSION)'
    update_project_yml_versions "$version" "$build_num"

    if [ "${DPIKILLER_WRITE_VERSION_FILE:-1}" = "1" ]; then
        echo "$build_num" > .version
    fi

    echo "$version"
}
