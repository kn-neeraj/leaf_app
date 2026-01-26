#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage: scripts/create_dmg_template.sh /path/to/Leaf.app

Creates a DMG layout template (.DS_Store + background) without Finder automation.
You will be asked to arrange the Finder window manually.
USAGE
}

APP_PATH="${1:-}"
if [[ -z "$APP_PATH" ]]; then
  usage
  exit 1
fi

if [[ ! -d "$APP_PATH" ]]; then
  echo "App bundle not found: $APP_PATH" >&2
  exit 1
fi

APP_BASENAME="$(basename "$APP_PATH")"
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TEMPLATE_DIR="$ROOT_DIR/scripts/dmg_template"

WORK_DIR="$(mktemp -d)"
STAGING_DIR="$WORK_DIR/staging"

cleanup() {
  set +e
  rm -rf "$WORK_DIR"
}
trap cleanup EXIT

generate_background() {
  local target="$1"
  python3 - "$target" <<'PY'
import struct
import zlib
import sys

width = 640
height = 400
top = (32, 34, 36)
bottom = (46, 50, 54)

def chunk(kind, data):
    return struct.pack(">I", len(data)) + kind + data + struct.pack(">I", zlib.crc32(kind + data) & 0xffffffff)

rows = []
for y in range(height):
    t = y / (height - 1) if height > 1 else 0
    r = int(top[0] + (bottom[0] - top[0]) * t)
    g = int(top[1] + (bottom[1] - top[1]) * t)
    b = int(top[2] + (bottom[2] - top[2]) * t)
    row = bytes([0]) + bytes([r, g, b]) * width
    rows.append(row)

raw = b"".join(rows)
ihdr = struct.pack(">IIBBBBB", width, height, 8, 2, 0, 0, 0)
png = b"\x89PNG\r\n\x1a\n" + chunk(b"IHDR", ihdr) + chunk(b"IDAT", zlib.compress(raw)) + chunk(b"IEND", b"")

with open(sys.argv[1], "wb") as f:
    f.write(png)
PY
}

mkdir -p "$STAGING_DIR/.background"
generate_background "$STAGING_DIR/.background/background.png"
ditto "$APP_PATH" "$STAGING_DIR/$APP_BASENAME"
ln -s /Applications "$STAGING_DIR/Applications"

echo "A Finder window will open. Arrange icons and set the background to:"
echo "  $STAGING_DIR/.background/background.png"
echo "Close the Finder window when done."
open "$STAGING_DIR"
read -r -p "Press Enter after the layout is done... " _

if [[ ! -f "$STAGING_DIR/.DS_Store" ]]; then
  echo "No .DS_Store found. Make sure the folder was opened in Finder." >&2
  exit 1
fi

mkdir -p "$TEMPLATE_DIR"
cp "$STAGING_DIR/.DS_Store" "$TEMPLATE_DIR/.DS_Store"
cp "$STAGING_DIR/.background/background.png" "$TEMPLATE_DIR/background.png"

echo "Template saved to: $TEMPLATE_DIR"
