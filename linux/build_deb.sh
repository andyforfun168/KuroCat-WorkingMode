#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
VERSION="${1:-1.3.5}"
if [[ ! "$VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    echo "Expected a numeric release version such as 1.3.5" >&2
    exit 1
fi
ARCH="$(dpkg --print-architecture)"
PKG_DIR="$(mktemp -d)"
trap 'rm -rf "$PKG_DIR"' EXIT

if [ ! -x "$ROOT/kurocat" ]; then
    "$ROOT/build.sh"
fi

mkdir -p \
    "$PKG_DIR/DEBIAN" \
    "$PKG_DIR/usr/bin" \
    "$PKG_DIR/usr/share/doc/kurocat" \
    "$PKG_DIR/usr/share/applications" \
    "$PKG_DIR/usr/share/icons/hicolor/scalable/apps"

cp "$ROOT/kurocat" "$PKG_DIR/usr/bin/kurocat"
chmod 755 "$PKG_DIR/usr/bin/kurocat"
cp "$ROOT/kurocat.desktop" "$PKG_DIR/usr/share/applications/kurocat.desktop"
cp "$ROOT/kurocat.svg" "$PKG_DIR/usr/share/icons/hicolor/scalable/apps/kurocat.svg"
cp "$ROOT/../LICENSE" "$PKG_DIR/usr/share/doc/kurocat/copyright"

# Record the actual versioned shared-library requirements of this binary.
mkdir -p "$PKG_DIR/debian"
printf 'Source: kurocat\n\nPackage: kurocat\nArchitecture: any\n' > "$PKG_DIR/debian/control"
DEPENDS="$(cd "$PKG_DIR" && dpkg-shlibdeps -O -eusr/bin/kurocat | sed -n 's/^shlibs:Depends=//p')"
test -n "$DEPENDS"
rm -rf "$PKG_DIR/debian"

cat > "$PKG_DIR/DEBIAN/control" <<EOF
Package: kurocat
Version: ${VERSION}
Section: utils
Priority: optional
Architecture: ${ARCH}
Depends: ${DEPENDS}
Maintainer: andyforfun168 <https://github.com/andyforfun168/KuroCatAndy>
Homepage: https://github.com/andyforfun168/KuroCatAndy
Description: KuroCat native desktop keyboard & mouse cat pet
 Lightweight 60fps transparent desktop pet supporting full-state keyboard and
 mouse capture for typing and gaming (XInput2 + evdev), 2.5D head tracking,
 hunting dilated eyes, petting interactions, and Black/Siamese skins.
 Compatible with Ubuntu, Debian, Deepin, UnionTech UOS, and Kylin OS.
EOF

OUT_DEB="$ROOT/KuroCat-Linux-${ARCH}.deb"
dpkg-deb --build --root-owner-group "$PKG_DIR" "$OUT_DEB"
echo "==> Packaged Debian/UOS installer: $OUT_DEB ($(du -h "$OUT_DEB" | cut -f1))"
