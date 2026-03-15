extends Node

const HelperClass := preload("res://tests/smoke/world_save_load_smoke_helper.gd")

var _helper = null


func _ready() -> void:
	_helper = HelperClass.new(self)
	if not await _helper.begin_session("night_interrupted_reentry"):
		push_error("Failed to start night interrupted reentry smoke")
		_cleanup(true)
		return

	if not await _helper.reach_evening_via_farm_loop():
		push_error("Night interrupted reentry smoke failed to reach evening")
		_cleanup(true)
		return
	if not await _helper.open_night_departure():
		push_error("Night interrupted reentry smoke failed to open departure")
		_cleanup(true)
		return
	if not await _helper.confirm_night_departure():
		push_error("Night interrupted reentry smoke failed to launch night")
		_cleanup(true)
		return

	var night_snapshot_before: Dictionary = _helper.snapshot()
	if not _require(String(night_snapshot_before.get("current_screen", "")) == "night", "Interrupted reentry should save while the night run is active"):
		return
	if not _require(String(night_snapshot_before.get("phase", "")) == "night", "Interrupted reentry should preserve the night phase before reload"):
		return
	if not _require(not bool(night_snapshot_before.get("pending_summary", false)), "Interrupted reentry should not already have a return summary before reload"):
		return

	var interrupted_day := int(night_snapshot_before.get("current_day", 0))
	var interrupted_gold := int(night_snapshot_before.get("gold", 0))
	var interrupted_inventory: Dictionary = (night_snapshot_before.get("inventory_materials", {}) as Dictionary).duplicate(true)

	_helper.save()
	if await _helper.reload_meta_root() == null:
		push_error("Failed to reload interrupted night reentry smoke")
		_cleanup(true)
		return

	var recovered_snapshot: Dictionary = _helper.snapshot()
	var recovered_payload: Dictionary = recovered_snapshot.get("return_summary_payload", {})
	var raw_summary: Dictionary = recovered_payload.get("raw_summary", {})
	if not _require(String(recovered_snapshot.get("current_screen", "")) == "return_summary", "Interrupted reentry should recover into the return summary flow"):
		return
	if not _require(bool(recovered_snapshot.get("pending_summary", false)), "Interrupted reentry should synthesize a pending return summary after reload"):
		return
	if not _require(not bool(recovered_snapshot.get("night_active", false)), "Interrupted reentry should not leave a live night session after reload"):
		return
	if not _require(int(recovered_snapshot.get("current_day", 0)) == interrupted_day, "Interrupted reentry should keep the same day while the summary is pending"):
		return
	if not _require(String(recovered_snapshot.get("phase", "")) == "night", "Interrupted reentry should preserve the night phase until the summary continues"):
		return
	if not _require(int(recovered_snapshot.get("gold", 0)) == interrupted_gold, "Interrupted reentry should not grant gold before the recovery summary resolves"):
		return
	if not _require(recovered_snapshot.get("inventory_materials", {}) == interrupted_inventory, "Interrupted reentry should not inject night loot on recovery"):
		return
	if not _require(String(recovered_payload.get("exit_reason", "")) == "abandoned", "Interrupted reentry should recover as an abandoned run outcome"):
		return
	if not _require(bool(raw_summary.get("dungeon_interrupted", false)), "Interrupted reentry should mark the recovered summary as interrupted"):
		return
	if not _require(int(recovered_payload.get("gold_reward", -1)) == 0, "Interrupted reentry should not issue a run-end gold reward"):
		return
	if not _require((recovered_payload.get("materials_reward", {}) as Dictionary).is_empty(), "Interrupted reentry should not issue run-end materials"):
		return

	if not await _helper.continue_summary():
		push_error("Interrupted reentry smoke failed to continue the recovered summary")
		_cleanup(true)
		return

	var final_snapshot: Dictionary = _helper.snapshot()
	if not _require(String(final_snapshot.get("current_screen", "")) == "day_hub", "Interrupted reentry should return to the day hub after continuing the summary"):
		return
	if not _require(int(final_snapshot.get("current_day", 0)) == interrupted_day + 1, "Interrupted reentry should advance the day exactly once after recovery"):
		return
	if not _require(String(final_snapshot.get("phase", "")) == "morning", "Interrupted reentry should start the next day in the morning phase"):
		return
	if not _require(int(final_snapshot.get("gold", 0)) == interrupted_gold, "Interrupted reentry should not add delayed gold after continuing the summary"):
		return
	if not _require(final_snapshot.get("inventory_materials", {}) == interrupted_inventory, "Interrupted reentry should not add delayed materials after continuing the summary"):
		return
	if not _require(not bool(final_snapshot.get("pending_summary", false)), "Interrupted reentry should clear the pending summary after continuing"):
		return

	print("Night interrupted reentry smoke PASS")
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
