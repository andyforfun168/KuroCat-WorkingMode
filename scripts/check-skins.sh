#!/usr/bin/env bash
# Native renderer regression and action sheets; never launches the app or changes settings.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
CHECK_DIR="$(mktemp -d)"
trap 'rm -rf "$CHECK_DIR"' EXIT
python3 "$ROOT/scripts/generate-coat-patterns.py" --check
python3 - "$ROOT" "$CHECK_DIR" <<'PY'
from pathlib import Path
import subprocess,sys
root,out=map(Path,sys.argv[1:])
p=(root/'Sources/CatPhysics.swift').read_text().replace('private(set) ','')
(out/'CatPhysics.swift').write_text(p)
sources=[('LegacyRenderer',subprocess.check_output(['git','-C',str(root),'show','be51bdcd8fd43fb5ac07ab330a5ac98241fad3ef:Sources/CatRenderer.swift'],text=True)),('CurrentRenderer',(root/'Sources/CatRenderer.swift').read_text())]
for name,revision in [('OccludedMuzzleRenderer','cdc3c67cc7c728dc8cb3e5678806fff904e31825'),('PointyChinRenderer','3bcec7df3386ce9b3ed1eb4e0ee088f6cb22f451')]:
 source=subprocess.check_output(['git','-C',str(root),'show',revision+':Sources/CatRenderer.swift'],text=True)
 source=source.replace('CoatPatterns',name+'Patterns').replace('CoatMark',name+'Mark')
 sources.append((name,source))
 patterns=subprocess.check_output(['git','-C',str(root),'show',revision+':Sources/CoatPatterns.swift'],text=True)
 patterns=patterns.replace('CoatPatterns',name+'Patterns').replace('CoatMark',name+'Mark')
 (out/(name+'Patterns.swift')).write_text(patterns)
for name,source in sources:
 source=source.replace('enum CatRenderer {','enum '+name+' {').replace('CatSettings.shared','RenderSettings.shared')
 source=source.replace('private static func coatMarkPoint','static func coatMarkPoint')
 if name!='CurrentRenderer':source=source.replace('CatHitZone',name+'CatHitZone')
 (out/(name+'.swift')).write_text(source)
PY
swiftc -module-cache-path "$CHECK_DIR/cache" \
 "$CHECK_DIR/OccludedMuzzleRendererPatterns.swift" "$CHECK_DIR/PointyChinRendererPatterns.swift" "$ROOT/Sources/KeyMap.swift" "$ROOT/Sources/InputEngine.swift" "$ROOT/Sources/CoatPatterns.swift" \
 "$CHECK_DIR/CatPhysics.swift" "$CHECK_DIR/LegacyRenderer.swift" "$CHECK_DIR/OccludedMuzzleRenderer.swift" "$CHECK_DIR/PointyChinRenderer.swift" "$CHECK_DIR/CurrentRenderer.swift" \
 "$ROOT/tests/skins/main.swift" -o "$CHECK_DIR/check" \
 -framework AppKit -framework CoreGraphics -framework QuartzCore -framework IOKit -framework ApplicationServices
"$CHECK_DIR/check" "${1:-$CHECK_DIR}"
