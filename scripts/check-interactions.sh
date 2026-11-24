#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
CHECK_DIR="$(mktemp -d)"
trap 'rm -rf "$CHECK_DIR"' EXIT
python3 - "$ROOT" "$CHECK_DIR" <<'PY'
from pathlib import Path
import sys
root,out=map(Path,sys.argv[1:])
for p in (root/'Sources').glob('*.swift'):
    if p.name=='main.swift':continue
    source=p.read_text().replace('UserDefaults.standard','fixtureDefaults').replace('SkinLibrary.shared.skin(id: customSkin) ?? SkinSpec.builtIn(coatTheme)', 'SkinSpec.builtIn(coatTheme)')
    if p.name=='InputEngine.swift':source=source.replace('private(set) ','')
    (out/p.name).write_text(source)
(out/'main.swift').write_text((root/'tests/interactions/main.swift').read_text())
PY
swiftc -module-cache-path "$CHECK_DIR/cache" "$CHECK_DIR/"*.swift -o "$CHECK_DIR/check" \
 -framework AppKit -framework CoreGraphics -framework QuartzCore -framework IOKit -framework ApplicationServices
"$CHECK_DIR/check"
