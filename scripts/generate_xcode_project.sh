#!/bin/bash
set -euo pipefail

if ! command -v xcodegen >/dev/null 2>&1; then
    echo "xcodegen is required. Install it with: brew install xcodegen" >&2
    exit 1
fi

xcodegen generate

python3 - <<'PY'
from pathlib import Path

path = Path("DPIKiller.xcodeproj/project.pbxproj")
text = path.read_text()
needle = 'SystemCapabilities = "[\\"com.apple.NetworkExtensions\\": [\\"enabled\\": 1]]";'
replacement = """SystemCapabilities = {
\t\t\t\t\t\t\tcom.apple.NetworkExtensions = {
\t\t\t\t\t\t\t\tenabled = 1;
\t\t\t\t\t\t\t};
\t\t\t\t\t\t};"""
if needle in text:
    text = text.replace(needle, replacement)
    path.write_text(text)
PY

echo "Generated DPIKiller.xcodeproj"
