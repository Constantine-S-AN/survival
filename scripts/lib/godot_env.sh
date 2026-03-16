#!/usr/bin/env bash

if [[ -n "${_SURVIVE_GODOT_ENV_SH:-}" ]]; then
	return 0
fi
_SURVIVE_GODOT_ENV_SH=1

resolve_godot_bin() {
	local requested="${1:-}"
	local candidate=""
	if [[ -n "${requested}" ]]; then
		if command -v "${requested}" >/dev/null 2>&1; then
			command -v "${requested}"
			return 0
		fi
		if [[ -x "${requested}" ]]; then
			printf '%s\n' "${requested}"
			return 0
		fi
		echo "[godot] requested executable not found: ${requested}" >&2
		echo "[godot] set GODOT_BIN=/path/to/Godot or install godot/godot4 on PATH" >&2
		return 127
	fi

	local -a candidates=(
		"godot"
		"godot4"
		"/Applications/Godot.app/Contents/MacOS/Godot"
		"${HOME}/Applications/Godot.app/Contents/MacOS/Godot"
	)
	for candidate in "${candidates[@]}"; do
		if command -v "${candidate}" >/dev/null 2>&1; then
			command -v "${candidate}"
			return 0
		fi
		if [[ -x "${candidate}" ]]; then
			printf '%s\n' "${candidate}"
			return 0
		fi
	done

	echo "[godot] Godot executable not found" >&2
	echo "[godot] searched PATH entries 'godot'/'godot4' and the standard macOS app bundle path" >&2
	echo "[godot] set GODOT_BIN=/path/to/Godot to override autodiscovery" >&2
	return 127
}
