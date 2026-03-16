#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
source "${ROOT_DIR}/scripts/lib/godot_env.sh"
GODOT_BIN="$(resolve_godot_bin "${GODOT_BIN:-}")"
KEEP_GD_PLUG_CACHE="${KEEP_GD_PLUG_CACHE:-0}"

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
