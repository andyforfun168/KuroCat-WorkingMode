#!/usr/bin/env bash
# Keep the README's ./build.sh entry point stable.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")" && pwd)"
exec bash "$ROOT/scripts/build-macos.sh" "$@"
