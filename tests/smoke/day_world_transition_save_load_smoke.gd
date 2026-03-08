extends Node

const HelperClass := preload("res://tests/smoke/world_save_load_smoke_helper.gd")

var _helper = null


func _ready() -> void:
	_helper = HelperClass.new(self)
	if not await _helper.begin_session("day_world_transition_save_load"):
		push_error("Failed to start DayWorld transition save/load smoke")
		_cleanup(true)
		return

	if not await _reach_evening():
		return
	if not _require(bool(_helper.meta_root.call("debug_day_world_interact", "night")), "Transition save/load should open the dock confirmation from the day world"):
		return
	await _helper.await_frames(1)

	var departure_snapshot_before: Dictionary = _helper.snapshot()
	if not _require(String(departure_snapshot_before.get("current_screen", "")) == "day_hub", "Transition save/load should save pre-departure from the overworld context"):
		return
	if not _require(String(departure_snapshot_before.get("phase", "")) == "evening", "Transition save/load should reach evening before pre-departure save"):
		return
	if not _require(bool(departure_snapshot_before.get("day_world_night_ready", false)), "Transition save/load should capture dock readiness before departure"):
		return
	if not _require(bool(departure_snapshot_before.get("day_world_dock_gate_open", false)), "Transition save/load should capture the open dock gate before departure"):
		return
	if not _require(bool(departure_snapshot_before.get("day_world_night_popup_open", false)), "Transition save/load should capture the dock confirmation popup state"):
		return
	if not _require(not bool(departure_snapshot_before.get("night_active", false)), "Transition save/load should not auto-launch night combat while saving pre-departure"):
		return

	var departure_inventory_before: Dictionary = (departure_snapshot_before.get("inventory_materials", {}) as Dictionary).duplicate(true)
	var departure_gold_before := int(departure_snapshot_before.get("gold", 0))
	var departure_stamina_before := int(departure_snapshot_before.get("stamina", 0))

	_helper.save()
	if await _helper.reload_meta_root() == null:
		push_error("Failed to reload DayWorld transition save/load smoke at pre-departure")
		_cleanup(true)
		return

	var departure_snapshot_after: Dictionary = _helper.snapshot()
	if not _require(String(departure_snapshot_after.get("current_screen", "")) == "day_hub", "Transition save/load should restore the overworld context before departure"):
		return
	if not _require(String(departure_snapshot_after.get("phase", "")) == "evening", "Transition save/load should preserve the evening phase before departure"):
		return
	if not _require(bool(departure_snapshot_after.get("day_world_night_ready", false)), "Transition save/load should preserve night departure eligibility after reload"):
		return
	if not _require(bool(departure_snapshot_after.get("day_world_dock_gate_open", false)), "Transition save/load should preserve the open dock gate after reload"):
		return
	if not _require(bool(departure_snapshot_after.get("day_world_night_popup_open", false)), "Transition save/load should restore the dock confirmation popup safely"):
		return
	if not _require(int(departure_snapshot_after.get("gold", 0)) == departure_gold_before, "Transition save/load should not alter gold while restoring pre-departure state"):
		return
	if not _require(int(departure_snapshot_after.get("stamina", 0)) == departure_stamina_before, "Transition save/load should preserve stamina while restoring pre-departure state"):
		return
	if not _require(departure_snapshot_after.get("inventory_materials", {}) == departure_inventory_before, "Transition save/load should preserve inventory while restoring pre-departure state"):
		return
	if not _require(not bool(departure_snapshot_after.get("night_active", false)), "Transition save/load should not auto-launch night combat after reload"):
		return

	if not _require(bool(_helper.meta_root.call("debug_day_world_confirm_night_departure")), "Transition save/load should still allow departing after restoring pre-departure state"):
		return
	await get_tree().create_timer(0.8).timeout
	var night_snapshot: Dictionary = _helper.snapshot()
	if not _require(String(night_snapshot.get("current_screen", "")) == "night", "Transition save/load should launch the night run after confirming restored departure"):
		return

	_helper.meta_root.call("debug_complete_active_night", {
		"exit_reason": "completed",
		"time_survived_sec": 88.0,
		"kills": 16,
		"seed": 525252
	})
	await _helper.await_frames(2)

	var summary_snapshot_before: Dictionary = _helper.snapshot()
	var summary_payload_before: Dictionary = summary_snapshot_before.get("return_summary_payload", {})
	if not _require(String(summary_snapshot_before.get("current_screen", "")) == "return_summary", "Transition save/load should save from the return summary context"):
		return
	if not _require(bool(summary_snapshot_before.get("pending_summary", false)), "Transition save/load should capture the pending return summary flag"):
		return
	if not _require(bool(summary_snapshot_before.get("day_world_overlay_blocked", false)), "Transition save/load should capture the blocked day world overlay behind the summary"):
		return
	if not _require(String(summary_snapshot_before.get("phase", "")) == "night", "Transition save/load should preserve the night phase while the summary is pending"):
		return

	var summary_gold_before := int(summary_snapshot_before.get("gold", 0))
	var summary_inventory_before: Dictionary = (summary_snapshot_before.get("inventory_materials", {}) as Dictionary).duplicate(true)
	var summary_day_before := int(summary_snapshot_before.get("current_day", 0))

	_helper.save()
	if await _helper.reload_meta_root() == null:
		push_error("Failed to reload DayWorld transition save/load smoke at return summary")
		_cleanup(true)
		return

	var summary_snapshot_after: Dictionary = _helper.snapshot()
	var summary_payload_after: Dictionary = summary_snapshot_after.get("return_summary_payload", {})
	if not _require(String(summary_snapshot_after.get("current_screen", "")) == "return_summary", "Transition save/load should restore the return summary context"):
		return
	if not _require(bool(summary_snapshot_after.get("pending_summary", false)), "Transition save/load should preserve the pending return summary flag after reload"):
		return
	if not _require(bool(summary_snapshot_after.get("day_world_overlay_blocked", false)), "Transition save/load should preserve the blocked overlay behind the return summary"):
		return
	if not _require(int(summary_snapshot_after.get("gold", 0)) == summary_gold_before, "Transition save/load should not duplicate night rewards after reload"):
		return
	if not _require(summary_snapshot_after.get("inventory_materials", {}) == summary_inventory_before, "Transition save/load should not duplicate night loot after reload"):
		return
	if not _require(int(summary_snapshot_after.get("current_day", 0)) == summary_day_before, "Transition save/load should preserve the current day while the summary is pending"):
		return
	if not _require(int(summary_payload_after.get("gold_reward", 0)) == int(summary_payload_before.get("gold_reward", 0)), "Transition save/load should preserve the summary gold reward payload"):
		return
	if not _require(summary_payload_after.get("materials_reward", {}) == summary_payload_before.get("materials_reward", {}), "Transition save/load should preserve the summary material reward payload"):
		return

	_helper.meta_root.call("debug_continue_summary")
	await _helper.await_frames(1)
	var continue_snapshot: Dictionary = _helper.snapshot()
	if not _require(String(continue_snapshot.get("current_screen", "")) == "day_hub", "Transition save/load should return to the overworld after continuing the summary"):
		return
	if not _require(int(continue_snapshot.get("current_day", 0)) == summary_day_before + 1, "Transition save/load should advance the day exactly once after continuing the restored summary"):
		return
	if not _require(int(continue_snapshot.get("gold", 0)) == summary_gold_before, "Transition save/load should not apply night rewards a second time when continuing the restored summary"):
		return
	if not _require(continue_snapshot.get("inventory_materials", {}) == summary_inventory_before, "Transition save/load should not duplicate night loot when continuing the restored summary"):
		return
	if not _require(not bool(continue_snapshot.get("pending_summary", false)), "Transition save/load should clear the pending summary flag after continuing"):
		return

	print("Day World transition save/load smoke PASS")
	_cleanup(false)


func _reach_evening() -> bool:
	if not _require(bool(_helper.meta_root.call("debug_day_world_select_farm_tool", "till")), "Transition save/load should expose the till tool before reaching evening"):
		return false
	if not _require(bool(_helper.meta_root.call("debug_day_world_interact_farm_plot", 0)), "Transition save/load should allow tilling plot 0 before reaching evening"):
		return false
	await _helper.await_frames(1)
	if not _require(bool(_helper.meta_root.call("debug_day_world_select_farm_tool", "plant", "wheat_seed")), "Transition save/load should allow selecting wheat seed before reaching evening"):
		return false
	if not _require(bool(_helper.meta_root.call("debug_day_world_interact_farm_plot", 0)), "Transition save/load should allow planting plot 0 before reaching evening"):
		return false
	await _helper.await_frames(1)
	if not _require(bool(_helper.meta_root.call("debug_day_world_select_farm_tool", "water")), "Transition save/load should allow selecting the watering can before reaching evening"):
		return false
	if not _require(bool(_helper.meta_root.call("debug_day_world_interact_farm_plot", 0)), "Transition save/load should allow watering plot 0 before reaching evening"):
		return false
	await _helper.await_frames(1)
	var snapshot: Dictionary = _helper.snapshot()
	return _require(String(snapshot.get("phase", "")) == "evening", "Transition save/load should reach the evening phase through the day world flow")


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
