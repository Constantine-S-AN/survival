#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
GODOT_BIN="${GODOT_BIN:-godot}"
QUIT_AFTER="${QUIT_AFTER:-10}"
DO_IMPORT=1

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

if [[ "${DO_IMPORT}" -eq 1 ]]; then
	echo "[plugin-tests] import"
	"${GODOT_BIN}" --headless --path "${ROOT_DIR}" --import
fi

for scene in "${SCENES[@]}"; do
	echo "[plugin-tests] ${scene}"
	"${GODOT_BIN}" --headless --path "${ROOT_DIR}" "${scene}" --quit-after "${QUIT_AFTER}"
done

echo "[plugin-tests] PASS"
