#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
GODOT_BIN="${GODOT_BIN:-godot}"
KEEP_GD_PLUG_CACHE="${KEEP_GD_PLUG_CACHE:-0}"

if ! command -v "${GODOT_BIN}" >/dev/null 2>&1; then
	echo "[plugins] missing Godot binary: ${GODOT_BIN}" >&2
	exit 127
fi

echo "[plugins] syncing vendored addons via gd-plug"
set +e
"${GODOT_BIN}" --headless --path "${ROOT_DIR}" -s res://plug.gd install force
gd_plug_exit=$?
set -e

if [[ "${gd_plug_exit}" -ne 0 && "${gd_plug_exit}" -ne 255 ]]; then
	exit "${gd_plug_exit}"
fi

if [[ "${KEEP_GD_PLUG_CACHE}" != "1" && -d "${ROOT_DIR}/.plugged" ]]; then
	rm -rf "${ROOT_DIR}/.plugged"
fi

echo "[plugins] sync complete"
