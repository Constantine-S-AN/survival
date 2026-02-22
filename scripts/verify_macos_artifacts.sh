#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DMG_PATH="${1:-$ROOT_DIR/dist/Survive-Neon-Sonar-macOS.dmg}"

if [[ "$DMG_PATH" != /* ]]; then
  DMG_PATH="$ROOT_DIR/$DMG_PATH"
fi

if [[ ! -f "$DMG_PATH" ]]; then
  echo "Error: DMG not found: $DMG_PATH"
  exit 1
fi

MOUNT_POINT="$(mktemp -d "${TMPDIR:-/tmp}/survive-dmg-mount.XXXXXX")"
ATTACHED=0

cleanup() {
  if [[ "$ATTACHED" -eq 1 ]]; then
    hdiutil detach "$MOUNT_POINT" -quiet >/dev/null 2>&1 || true
  fi
  rmdir "$MOUNT_POINT" >/dev/null 2>&1 || true
}
trap cleanup EXIT

hdiutil attach "$DMG_PATH" -readonly -nobrowse -mountpoint "$MOUNT_POINT" -quiet
ATTACHED=1

APP_COUNT="$(find "$MOUNT_POINT" -maxdepth 1 -name "*.app" | wc -l | tr -d ' ')"
if [[ "$APP_COUNT" -lt 1 ]]; then
  echo "Error: no .app bundle found in mounted DMG"
  exit 1
fi

if [[ ! -e "$MOUNT_POINT/Applications" ]]; then
  echo "Error: Applications alias/link missing in DMG root"
  exit 1
fi

if [[ -L "$MOUNT_POINT/Applications" ]]; then
  LINK_TARGET="$(readlink "$MOUNT_POINT/Applications")"
  if [[ "$LINK_TARGET" != "/Applications" ]]; then
    echo "Error: Applications link target is unexpected: $LINK_TARGET"
    exit 1
  fi
fi

if find "$MOUNT_POINT" -maxdepth 2 -name "*.command" | grep -q .; then
  echo "Error: .command file found in DMG"
  exit 1
fi

echo "Artifact verification passed: $DMG_PATH"
