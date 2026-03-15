extends Node

const HelperClass := preload("res://tests/smoke/world_save_load_smoke_helper.gd")

var _helper = null


func _ready() -> void:
	_helper = HelperClass.new(self)
	if not await _helper.begin_session("day_world_night_completion"):
		push_error("Failed to start DayWorld night completion smoke")
		_cleanup(true)
		return

	if not _require(await _helper.reach_evening_via_farm_loop(), "Night completion smoke should reach evening through the day world farm loop"):
		return
	if not _require(await _helper.open_night_departure(), "Night completion smoke should open the dock departure confirmation"):
		return
	if not _require(await _helper.confirm_night_departure(), "Night completion smoke should launch the real NightRun"):
		return
	if not _require(not (await _helper.wait_for_night_room("camp")).is_empty(), "Night completion smoke should boot into the deterministic start room"):
		return
	if not _require(await _helper.finish_night_run_via_completion([2, 0]), "Night completion smoke should finish a real boss-clear route"):
		return

	var summary_snapshot: Dictionary = _helper.snapshot()
	var summary_payload: Dictionary = summary_snapshot.get("return_summary_payload", {})
	var raw_summary: Dictionary = summary_payload.get("raw_summary", {})
	if not _require(String(summary_snapshot.get("current_screen", "")) == "return_summary", "Night completion smoke should land in the return summary overlay"):
		return
	if not _require(String(summary_payload.get("exit_reason", "")) == "completed", "Night completion smoke should preserve the completed outcome from the real night run"):
		return
	if not _require(bool(raw_summary.get("dungeon_boss_cleared", false)), "Night completion smoke should preserve boss-clear metadata from the real night run"):
		return
	if not _require(String(raw_summary.get("dungeon_last_room_id", "")) == "apex_guardian", "Night completion smoke should preserve the completed boss-room id"):
		return
	if not _require((raw_summary.get("dungeon_room_path", []) as Array).has("apex_guardian"), "Night completion smoke should preserve the real room path through the boss floor"):
		return
	if not _require(int((raw_summary.get("dungeon_boss_bonus_materials", {}) as Dictionary).get("kitchen_blueprint_fragment", 0)) >= 1, "Night completion smoke should preserve boss bonus carryover materials"):
		return

	var summary_day := int(summary_snapshot.get("current_day", 0))
	if not _require(await _helper.continue_summary(), "Night completion smoke should settle the completed run summary"):
		return
	var next_day_snapshot: Dictionary = _helper.snapshot()
	if not _require(String(next_day_snapshot.get("current_screen", "")) == "day_hub", "Night completion smoke should return to the day hub after continuing the summary"):
		return
	if not _require(int(next_day_snapshot.get("current_day", 0)) == summary_day + 1, "Night completion smoke should advance exactly one day after the completed run"):
		return
	if not _require(String(next_day_snapshot.get("phase", "")) == "morning", "Night completion smoke should restore the next morning phase after the completed run"):
		return

	print("Day World night completion smoke PASS")
	_cleanup(false)


func _require(condition: bool, message: String) -> bool:
	if condition:
		return true
	push_error(message)
	_cleanup(true)
	return false


func _cleanup(failed: bool = true) -> void:
	if _helper != null:
		_helper.cleanup()
	get_tree().quit(1 if failed else 0)
