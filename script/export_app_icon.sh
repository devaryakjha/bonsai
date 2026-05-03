#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ICON_DOCUMENT="$ROOT_DIR/Assets/AppIcon/Bonsai.icon"
ICON_JSON="$ICON_DOCUMENT/icon.json"
OUTPUT_ICNS="$ROOT_DIR/Assets/AppIcon/Bonsai.icns"
ICTOOL="/Applications/Xcode.app/Contents/Applications/Icon Composer.app/Contents/Executables/ictool"

usage() {
  cat >&2 <<USAGE
usage: script/export_app_icon.sh

Exports Assets/AppIcon/Bonsai.icns from the canonical Icon Composer document at
Assets/AppIcon/Bonsai.icon. The source .icon package is never modified.
USAGE
}

require_file() {
  local path="$1"
  if [[ ! -f "$path" ]]; then
    echo "missing required file: $path" >&2
    exit 1
  fi
}

case "${1:-}" in
  --help|-h|help)
    usage
    exit 0
    ;;
  "")
    ;;
  *)
    usage
    exit 2
    ;;
esac

require_file "$ICON_JSON"
require_file "$ICON_DOCUMENT/Assets/bonsai-worktree-topology.svg"
require_file "$ICON_DOCUMENT/Assets/bonsai-worktree-topology-dark.svg"
require_file "$ICTOOL"

if command -v jq >/dev/null; then
  if ! jq empty "$ICON_JSON" >/dev/null; then
    echo "invalid Icon Composer metadata: $ICON_JSON" >&2
    exit 1
  fi
fi

WORK_DIR="$(mktemp -d "${TMPDIR:-/tmp}/bonsai-app-icon.XXXXXX")"
ICONSET_DIR="$WORK_DIR/Bonsai.iconset"
mkdir -p "$ICONSET_DIR"
trap 'rm -rf "$WORK_DIR"' EXIT

export_icon() {
  local name="$1" width="$2" height="$3" scale="$4"
  "$ICTOOL" "$ICON_DOCUMENT" \
    --export-image \
    --output-file "$ICONSET_DIR/$name" \
    --platform macOS \
    --rendition Default \
    --width "$width" \
    --height "$height" \
    --scale "$scale" >/dev/null
}

export_icon icon_16x16.png 16 16 1
export_icon icon_16x16@2x.png 16 16 2
export_icon icon_32x32.png 32 32 1
export_icon icon_32x32@2x.png 32 32 2
export_icon icon_128x128.png 128 128 1
export_icon icon_128x128@2x.png 128 128 2
export_icon icon_256x256.png 256 256 1
export_icon icon_256x256@2x.png 256 256 2
export_icon icon_512x512.png 512 512 1
export_icon icon_512x512@2x.png 512 512 2

/usr/bin/iconutil -c icns "$ICONSET_DIR" -o "$OUTPUT_ICNS"
echo "Exported $OUTPUT_ICNS"
