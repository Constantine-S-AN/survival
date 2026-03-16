#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
source "${ROOT_DIR}/scripts/lib/godot_env.sh"
GODOT_BIN="$(resolve_godot_bin "${GODOT_BIN:-}")"
LOG_DIR="${ROOT_DIR}/tmp/logs"
QUIT_AFTER="${QUIT_AFTER:-3600}"
DO_IMPORT=1
ENGINE_FAILURE_REGEX="${ENGINE_FAILURE_REGEX:-^(SCRIPT ERROR:|SCRIPT WARNING:|ERROR:|WARNING:|SHADER ERROR:|FATAL:|Leaked instance:|ObjectDB instances leaked at exit|Orphan StringName:|StringName: [0-9]+ unclaimed string names at exit\\.)}"
ALLOW_ENGINE_FAILURE_REGEX="${ALLOW_ENGINE_FAILURE_REGEX:-\\[profile\\] profile parse failed, attempting backup restore:}"
SCENE_PASS_REGEX="${SCENE_PASS_REGEX:-PASS}"
RUN_ID="$(date +%Y%m%d_%H%M%S)_${RANDOM}"
RUN_LOG_DIR="${LOG_DIR}/plugin_focused_${RUN_ID}"

SCENES=(
	"res://tests/smoke/DialogueManagerSmoke.tscn"
	"res://tests/smoke/DayHubIntroDialogueSmoke.tscn"
	"res://tests/smoke/ReturnSummaryDialogueSmoke.tscn"
	"res://tests/smoke/RestaurantDialogueSmoke.tscn"
	"res://tests/smoke/DayWorldShellSmoke.tscn"
	"res://tests/smoke/DayWorldOnboardingGuidanceSmoke.tscn"
	"res://tests/smoke/DayWorldOrdersClaimReloadSmoke.tscn"
	"res://tests/smoke/DayWorldDialogueIntegrationSmoke.tscn"
	"res://tests/smoke/DayWorldPhaseCueSmoke.tscn"
	"res://tests/smoke/DayWorldModalGatingSmoke.tscn"
	"res://tests/smoke/DayWorldTransitionGatingSmoke.tscn"
	"res://tests/smoke/DayWorldIdleSaveLoadSmoke.tscn"
	"res://tests/smoke/DayWorldFarmOverlapRebuildSmoke.tscn"
	"res://tests/smoke/DayWorldFarmSaveLoadSmoke.tscn"
	"res://tests/smoke/DayWorldPhaseSaveLoadSmoke.tscn"
	"res://tests/smoke/DayWorldTransitionSaveLoadSmoke.tscn"
	"res://tests/smoke/DayWorldNightCompletionSmoke.tscn"
	"res://tests/smoke/NightInterruptedReentrySmoke.tscn"
	"res://tests/smoke/RestaurantWorldShellSmoke.tscn"
	"res://tests/smoke/RestaurantWorldGatingSmoke.tscn"
	"res://tests/smoke/RestaurantInteriorSaveLoadSmoke.tscn"
	"res://tests/smoke/ShopWorldShellSmoke.tscn"
	"res://tests/smoke/ShopWorldGatingSmoke.tscn"
	"res://tests/smoke/ShopInteriorSaveLoadSmoke.tscn"
	"res://tests/smoke/QuestSystemDailyOrdersSmoke.tscn"
	"res://tests/smoke/DailyOrdersProgressSmoke.tscn"
	"res://tests/smoke/DailyOrdersPersistenceSmoke.tscn"
	"res://tests/smoke/DailyOrdersRefreshSmoke.tscn"
	"res://tests/ui/t10_modifiers_effect_runner.tscn"
)

for arg in "$@"; do
	case "$arg" in
		--skip-import)
			DO_IMPORT=0
			;;
		*)
			echo "Unknown argument: $arg" >&2
			exit 2
			;;
	esac
done

mkdir -p "${RUN_LOG_DIR}"

if [[ "${DO_IMPORT}" -eq 1 ]]; then
	echo "[plugin-tests] import"
	"${GODOT_BIN}" --headless --path "${ROOT_DIR}" --import >"${RUN_LOG_DIR}/import.log" 2>&1
fi

for scene in "${SCENES[@]}"; do
	echo "[plugin-tests] ${scene}"
	scene_name="$(basename "${scene}" .tscn)"
	scene_log="${RUN_LOG_DIR}/${scene_name}.log"
	set +e
	"${GODOT_BIN}" --headless --path "${ROOT_DIR}" "${scene}" --quit-after "${QUIT_AFTER}" >"${scene_log}" 2>&1
	scene_exit=$?
	set -e
	if [[ ${scene_exit} -ne 0 ]]; then
		echo "[plugin-tests] scene failed: ${scene} (exit=${scene_exit})" >&2
		tail -n 120 "${scene_log}" >&2 || true
		exit ${scene_exit}
	fi
	if ! grep -qE "${SCENE_PASS_REGEX}" "${scene_log}"; then
		echo "[plugin-tests] scene did not emit a PASS marker: ${scene}" >&2
		tail -n 120 "${scene_log}" >&2 || true
		exit 1
	fi
	scene_failures=""
	if [[ -n "${ALLOW_ENGINE_FAILURE_REGEX}" ]]; then
		scene_failures="$(grep -nE "${ENGINE_FAILURE_REGEX}" "${scene_log}" | grep -Ev "${ALLOW_ENGINE_FAILURE_REGEX}" || true)"
	else
		scene_failures="$(grep -nE "${ENGINE_FAILURE_REGEX}" "${scene_log}" || true)"
	fi
	if [[ -n "${scene_failures}" ]]; then
		echo "[plugin-tests] engine/runtime failures detected for ${scene}" >&2
		echo "${scene_failures}" | head -n 120 >&2
		exit 1
	fi
	tail -n 20 "${scene_log}" || true
done

echo "[plugin-tests] PASS"
