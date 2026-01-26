#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage: scripts/build_dmg.sh [--template|--finder|--manual] [--volname NAME] /path/to/Leaf.app [output.dmg]

Builds a polished "drag to Applications" DMG with a custom layout.
By default, uses a template layout if available; otherwise uses Finder automation.
Manual mode opens the mounted DMG and pauses so you can arrange it yourself.

Template files live in scripts/dmg_template (created by scripts/create_dmg_template.sh).
USAGE
}

MODE="auto"
VOLNAME=""
while [[ "$#" -gt 0 ]]; do
  case "$1" in
    --template)
      MODE="template"
      shift
      ;;
    --finder)
      MODE="finder"
      shift
      ;;
    --manual)
      MODE="manual"
      shift
      ;;
    --volname)
      VOLNAME="${2:-}"
      if [[ -z "$VOLNAME" ]]; then
        echo "Missing value for --volname" >&2
        exit 1
      fi
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    --*)
      echo "Unknown option: $1" >&2
      usage
      exit 1
      ;;
    *)
      break
      ;;
  esac
done

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
APP_NAME="${APP_BASENAME%.app}"
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUTPUT_DMG="${2:-$ROOT_DIR/${APP_NAME}-$(date +%Y%m%d-%H%M).dmg}"
TEMPLATE_DIR="$ROOT_DIR/scripts/dmg_template"
TEMPLATE_DS_STORE="$TEMPLATE_DIR/.DS_Store"
TEMPLATE_BG="$TEMPLATE_DIR/background.png"
VOLNAME="${VOLNAME:-$APP_NAME}"

if [[ "$MODE" == "auto" ]]; then
  if [[ -f "$TEMPLATE_DS_STORE" ]]; then
    MODE="template"
  else
    MODE="finder"
  fi
fi

if [[ "$MODE" == "template" && ! -f "$TEMPLATE_DS_STORE" ]]; then
  echo "Template .DS_Store not found at: $TEMPLATE_DS_STORE" >&2
  echo "Create one with: scripts/create_dmg_template.sh \"$APP_PATH\"" >&2
  exit 1
fi

WORK_DIR="$(mktemp -d)"
STAGING_DIR="$WORK_DIR/staging"
MOUNT_DIR="$WORK_DIR/mount"
DMG_RW="$WORK_DIR/${APP_NAME}-rw.dmg"

cleanup() {
  set +e
  if mount | grep -q "$MOUNT_DIR"; then
    hdiutil detach "$MOUNT_DIR" >/dev/null 2>&1
  fi
  rm -rf "$WORK_DIR"
}
trap cleanup EXIT

mkdir -p "$STAGING_DIR/.background"

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

if [[ -f "$TEMPLATE_BG" ]]; then
  cp "$TEMPLATE_BG" "$STAGING_DIR/.background/background.png"
else
  generate_background "$STAGING_DIR/.background/background.png"
fi

mkdir -p "$STAGING_DIR"
ditto "$APP_PATH" "$STAGING_DIR/$APP_BASENAME"
if [[ ! -e "$STAGING_DIR/Applications" ]]; then
  ln -s /Applications "$STAGING_DIR/Applications"
fi

if [[ "$MODE" == "template" ]]; then
  cp "$TEMPLATE_DS_STORE" "$STAGING_DIR/.DS_Store"
  hdiutil create -volname "$VOLNAME" -srcfolder "$STAGING_DIR" -ov -format UDZO "$OUTPUT_DMG" >/dev/null
  echo "Created DMG: $OUTPUT_DMG"
  exit 0
fi

hdiutil create -volname "$VOLNAME" -srcfolder "$STAGING_DIR" -ov -format UDRW "$DMG_RW" >/dev/null
mkdir -p "$MOUNT_DIR"
hdiutil attach "$DMG_RW" -mountpoint "$MOUNT_DIR" -readwrite -nobrowse -noverify -noautoopen >/dev/null

sleep 1
if [[ "$MODE" == "manual" ]]; then
  echo "Mounted DMG at: $MOUNT_DIR"
  echo "Arrange the Finder window, then close it and press Enter here."
  echo "Background image path: $MOUNT_DIR/.background/background.png"
  open "$MOUNT_DIR"
  read -r -p "Press Enter to continue... " _
  sync
  hdiutil detach "$MOUNT_DIR" >/dev/null
  hdiutil convert "$DMG_RW" -format UDZO -o "$OUTPUT_DMG" -ov >/dev/null
  echo "Created DMG: $OUTPUT_DMG"
  exit 0
fi

osascript <<EOF
tell application "Finder"
  set dmgFolder to POSIX file "${MOUNT_DIR}" as alias
  open dmgFolder
  set dmgWindow to container window of dmgFolder
  delay 0.7
  set current view of dmgWindow to icon view
  set toolbar visible of dmgWindow to false
  set statusbar visible of dmgWindow to false
  set bounds of dmgWindow to {100, 100, 740, 500}
  set viewOptions to icon view options of dmgWindow
  set arrangement of viewOptions to not arranged
  set icon size of viewOptions to 128
  set bgFile to POSIX file "${MOUNT_DIR}/.background/background.png"
  set background picture of viewOptions to bgFile
  delay 0.5
  set position of item "${APP_BASENAME}" of dmgWindow to {170, 210}
  if not (exists item "Applications" of dmgWindow) then
    set appAlias to make new alias file at dmgWindow to POSIX file "/Applications"
    set name of appAlias to "Applications"
    delay 0.2
  end if
  set position of item "Applications" of dmgWindow to {470, 210}
  update without registering applications
  delay 1
  close dmgWindow
end tell
EOF

sync
hdiutil detach "$MOUNT_DIR" >/dev/null
hdiutil convert "$DMG_RW" -format UDZO -o "$OUTPUT_DMG" -ov >/dev/null

echo "Created DMG: $OUTPUT_DMG"
