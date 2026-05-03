#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ICON_DOCUMENT="$ROOT_DIR/Assets/AppIcon/Bonsai.icon"
ICON_JSON="$ICON_DOCUMENT/icon.json"
OUTPUT_ICNS="$ROOT_DIR/Assets/AppIcon/Bonsai.icns"
ICTOOL="/Applications/Xcode.app/Contents/Applications/Icon Composer.app/Contents/Executables/ictool"
MACOS_ICON_LIVE_AREA_NUMERATOR=55
MACOS_ICON_LIVE_AREA_DENOMINATOR=64

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
PAD_ICON_CANVAS="$WORK_DIR/pad_icon_canvas"
mkdir -p "$ICONSET_DIR"
trap 'rm -rf "$WORK_DIR"' EXIT

cat >"$WORK_DIR/pad_icon_canvas.swift" <<'SWIFT'
import AppKit
import Foundation

guard CommandLine.arguments.count == 4 else {
  FileHandle.standardError.write(Data("usage: pad_icon_canvas <source> <destination> <canvas-pixels>\n".utf8))
  exit(2)
}

let sourceURL = URL(filePath: CommandLine.arguments[1])
let destinationURL = URL(filePath: CommandLine.arguments[2])
guard let canvasPixels = Int(CommandLine.arguments[3]), canvasPixels > 0 else {
  FileHandle.standardError.write(Data("invalid canvas size\n".utf8))
  exit(2)
}

guard let sourceImage = NSImage(contentsOf: sourceURL),
      let sourceCGImage = sourceImage.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
  FileHandle.standardError.write(Data("could not read rendered inner icon: \(sourceURL.path)\n".utf8))
  exit(1)
}

guard let context = CGContext(
  data: nil,
  width: canvasPixels,
  height: canvasPixels,
  bitsPerComponent: 8,
  bytesPerRow: 0,
  space: CGColorSpaceCreateDeviceRGB(),
  bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
) else {
  FileHandle.standardError.write(Data("could not create icon canvas\n".utf8))
  exit(1)
}

context.clear(CGRect(x: 0, y: 0, width: canvasPixels, height: canvasPixels))
let x = (canvasPixels - sourceCGImage.width) / 2
let y = (canvasPixels - sourceCGImage.height) / 2
context.draw(
  sourceCGImage,
  in: CGRect(x: x, y: y, width: sourceCGImage.width, height: sourceCGImage.height)
)

guard let canvasImage = context.makeImage(),
      let png = NSBitmapImageRep(cgImage: canvasImage).representation(using: .png, properties: [:]) else {
  FileHandle.standardError.write(Data("could not encode icon canvas\n".utf8))
  exit(1)
}

try png.write(to: destinationURL)
SWIFT
swiftc "$WORK_DIR/pad_icon_canvas.swift" -o "$PAD_ICON_CANVAS"

export_icon() {
  local name="$1" width="$2" height="$3" scale="$4"
  local canvas_pixels inner_pixels inner_width inner_height rendered_icon
  canvas_pixels=$((width * scale))
  inner_pixels=$(((canvas_pixels * MACOS_ICON_LIVE_AREA_NUMERATOR + MACOS_ICON_LIVE_AREA_DENOMINATOR / 2) / MACOS_ICON_LIVE_AREA_DENOMINATOR))
  inner_width=$(((inner_pixels + scale / 2) / scale))
  inner_height="$inner_width"
  rendered_icon="$WORK_DIR/rendered-$name"

  "$ICTOOL" "$ICON_DOCUMENT" \
    --export-image \
    --output-file "$rendered_icon" \
    --platform macOS \
    --rendition Default \
    --width "$inner_width" \
    --height "$inner_height" \
    --scale "$scale" >/dev/null

  "$PAD_ICON_CANVAS" "$rendered_icon" "$ICONSET_DIR/$name" "$canvas_pixels"
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
