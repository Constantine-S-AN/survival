#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DEFAULT_OUTPUT="$ROOT_DIR/dist/Survive-Neon-Sonar-macOS.dmg"

APP_INPUT="${1:-}"
if [[ -z "$APP_INPUT" ]]; then
  echo "Usage: $0 <path-to-app-bundle> [output-dmg-path]"
  echo "Example: $0 exports/macos/Survive-Neon-Sonar.app"
  exit 1
fi

if [[ "$APP_INPUT" != *.app ]]; then
  echo "Error: input must point to a .app bundle: $APP_INPUT"
  exit 1
fi

if [[ ! -d "$APP_INPUT" ]]; then
  echo "Error: app bundle does not exist: $APP_INPUT"
  exit 1
fi

OUTPUT_DMG="${2:-$DEFAULT_OUTPUT}"
if [[ "$OUTPUT_DMG" != /* ]]; then
  OUTPUT_DMG="$ROOT_DIR/$OUTPUT_DMG"
fi

APP_ABS="$(cd "$(dirname "$APP_INPUT")" && pwd)/$(basename "$APP_INPUT")"
OUTPUT_DIR="$(dirname "$OUTPUT_DMG")"
mkdir -p "$OUTPUT_DIR"

STAGE_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/survive-dmg-stage.XXXXXX")"
STAGE_DIR="$STAGE_ROOT/stage"
mkdir -p "$STAGE_DIR"

cleanup() {
  rm -rf "$STAGE_ROOT"
}
trap cleanup EXIT

cp -R "$APP_ABS" "$STAGE_DIR/"
ln -s /Applications "$STAGE_DIR/Applications"

if find "$STAGE_DIR" -maxdepth 2 -name "*.command" | grep -q .; then
  echo "Error: staging unexpectedly contains .command files"
  exit 1
fi

rm -f "$OUTPUT_DMG"
VOLUME_NAME="Survive Neon Sonar"
hdiutil create \
  -volname "$VOLUME_NAME" \
  -srcfolder "$STAGE_DIR" \
  -ov \
  -format UDZO \
  "$OUTPUT_DMG" >/dev/null

echo "DMG created: $OUTPUT_DMG"
