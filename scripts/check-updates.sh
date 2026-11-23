#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
CHECK_DIR="$(mktemp -d)"
trap 'rm -rf "$CHECK_DIR"' EXIT
c++ -std=c++17 "$ROOT/tests/updates/main.cpp" -o "$CHECK_DIR/cpp-check"
"$CHECK_DIR/cpp-check"
if [[ "$(uname -s)" == Darwin ]]; then
 swiftc -module-cache-path "$CHECK_DIR/cache" "$ROOT/Sources/UpdateChecker.swift" "$ROOT/tests/updates/main.swift" -framework AppKit -o "$CHECK_DIR/swift-check"
 "$CHECK_DIR/swift-check"
fi
python3 - "$ROOT" <<'PY'
from pathlib import Path
import plistlib,re,sys
r=Path(sys.argv[1]);v=plistlib.loads((r/'Resources/Info.plist').read_bytes())['CFBundleShortVersionString']
s=(r/'shared/UpdateVersion.hpp').read_text();assert f'CurrentVersion[] = "{v}"' in s,'Update version and bundle version differ'
print('PASS: updater version matches application bundle:',v)
PY
