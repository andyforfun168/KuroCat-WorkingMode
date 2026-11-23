#!/usr/bin/env bash
# Check the exact filenames promised by README before publishing a release.
set -euo pipefail
DIST="${1:-dist}"
cd "$DIST"
files=(
    KuroCat-macOS-universal.zip
    KuroCat-Windows-x64.exe
    KuroCat-Linux-amd64.deb
    KuroCat-Linux-x86_64.tar.gz
    KuroCat-Linux-arm64.deb
    KuroCat-Linux-arm64.tar.gz
)
for file in "${files[@]}"; do
    if [ ! -s "$file" ]; then
        echo "Missing or empty release asset: $file" >&2
        exit 1
    fi
done
unzip -tq KuroCat-macOS-universal.zip
unzip -Z1 KuroCat-macOS-universal.zip | grep -Fx 'KuroCat.app/Contents/MacOS/KuroCat'
file KuroCat-Windows-x64.exe | grep -E 'PE32\+.*x86-64'
for arch in amd64 arm64; do
    test "$(dpkg-deb -f "KuroCat-Linux-${arch}.deb" Architecture)" = "$arch"
    dpkg-deb -f "KuroCat-Linux-${arch}.deb" Package Version Architecture Depends
done
for arch in x86_64 arm64; do
    listing="$(tar -tzf "KuroCat-Linux-${arch}.tar.gz")"
    for entry in kurocat kurocat.desktop kurocat.svg LICENSE INSTALL.txt; do
        grep -Fx "$entry" <<< "$listing"
    done
done
sha256sum "${files[@]}" > SHA256SUMS.txt
sha256sum --check SHA256SUMS.txt
