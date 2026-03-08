#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
GODOT_BIN="${GODOT_BIN:-godot}"

required_files=(
	"addons/gd-plug/plug.gd"
	"addons/gd-plug/LICENSE"
	"addons/dialogue_manager/plugin.cfg"
	"addons/quest_system/plugin.cfg"
	"plug.gd"
)

for path in "${required_files[@]}"; do
	if [[ ! -f "${ROOT_DIR}/${path}" ]]; then
		echo "[plugins] missing expected file: ${path}" >&2
		exit 1
	fi
done

echo "[plugins] required files present"
"${GODOT_BIN}" --headless --path "${ROOT_DIR}" --import
"${ROOT_DIR}/scripts/ci/run_headless_tests.sh" --skip-import
echo "[plugins] validation PASS"
