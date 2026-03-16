extends Node

const HelperClass := preload("res://tests/smoke/world_save_load_smoke_helper.gd")

var _helper = null


func _ready() -> void:
	_helper = HelperClass.new(self)
	if not await _helper.begin_session("day_world_farm_save_load"):
		push_error("Failed to start DayWorld farm save/load smoke")
		_cleanup(true)
		return

	if not _require(bool(_helper.meta_root.call("debug_day_world_select_farm_tool", "till")), "Farm save/load should expose the till tool in the day world"):
		return
	if not _require(bool(_helper.meta_root.call("debug_day_world_interact_farm_plot", 0)), "Farm save/load should allow tilling plot 0 in the day world"):
		return
	await _helper.await_frames(1)
	if not _require(bool(_helper.meta_root.call("debug_day_world_select_farm_tool", "plant", "wheat_seed")), "Farm save/load should allow selecting a seed tool in the day world"):
		return
	if not _require(bool(_helper.meta_root.call("debug_day_world_interact_farm_plot", 0)), "Farm save/load should allow planting plot 0 in the day world"):
		return
	await _helper.await_frames(1)
	if not _require(bool(_helper.meta_root.call("debug_day_world_select_farm_tool", "water")), "Farm save/load should allow selecting the watering can in the day world"):
		return
	await _helper.await_frames(1)

	var snapshot_before: Dictionary = _helper.snapshot()
	var plots_before: Array = snapshot_before.get("farm_plots", [])
	var plot0_before: Dictionary = plots_before[0] as Dictionary if not plots_before.is_empty() else {}
	if not _require(String(snapshot_before.get("current_screen", "")) == "day_hub", "Farm save/load should keep the player in the day world context"):
		return
	if not _require(String(snapshot_before.get("day_world_selected_hotbar_id", "")) == "water", "Farm save/load should capture the selected day world tool"):
		return
	if not _require(String(snapshot_before.get("day_world_selected_farm_tool_action_id", "")) == "water", "Farm save/load should preserve the selected farm action id"):
		return
	if not _require(not plot0_before.is_empty() and String(plot0_before.get("seed_id", "")) == "wheat_seed", "Farm save/load should capture the planted crop state"):
		return
	if not _require(bool(plot0_before.get("tilled", false)), "Farm save/load should capture the tilled plot state"):
		return
	if not _require(int(plot0_before.get("watered_day", 0)) == 0, "Farm save/load should not mark the plot watered before the watering action happens"):
		return

	var inventory_before: Dictionary = (snapshot_before.get("inventory_materials", {}) as Dictionary).duplicate(true)
	var gold_before := int(snapshot_before.get("gold", 0))
	var stamina_before := int(snapshot_before.get("stamina", 0))
	var phase_before := String(snapshot_before.get("phase", ""))
	var action_budget_before := int(snapshot_before.get("action_budget", 0))

	_helper.save()
	if await _helper.reload_meta_root() == null:
		push_error("Failed to reload DayWorld farm save/load smoke")
		_cleanup(true)
		return

	var snapshot_after: Dictionary = _helper.snapshot()
	var plots_after: Array = snapshot_after.get("farm_plots", [])
	var plot0_after: Dictionary = plots_after[0] as Dictionary if not plots_after.is_empty() else {}
	if not _require(String(snapshot_after.get("current_screen", "")) == "day_hub", "Farm save/load should restore the overworld context after reload"):
		return
	if not _require(String(snapshot_after.get("phase", "")) == phase_before, "Farm save/load should preserve the daytime phase after farm work"):
		return
	if not _require(int(snapshot_after.get("action_budget", 0)) == action_budget_before, "Farm save/load should preserve the remaining daytime budget after farm work"):
		return
	if not _require(int(snapshot_after.get("stamina", 0)) == stamina_before, "Farm save/load should preserve stamina after farm work"):
		return
	if not _require(int(snapshot_after.get("gold", 0)) == gold_before, "Farm save/load should preserve shared gold state after farm work"):
		return
	if not _require(snapshot_after.get("inventory_materials", {}) == inventory_before, "Farm save/load should not duplicate or lose inventory while restoring farm state"):
		return
	if not _require(String(snapshot_after.get("day_world_selected_hotbar_id", "")) == "water", "Farm save/load should restore the selected day world hotbar slot"):
		return
	if not _require(String(snapshot_after.get("day_world_selected_farm_tool_action_id", "")) == "water", "Farm save/load should restore the selected farm action id"):
		return
	if not _require(not plot0_after.is_empty() and String(plot0_after.get("seed_id", "")) == "wheat_seed", "Farm save/load should restore the planted crop state safely"):
		return
	if not _require(bool(plot0_after.get("tilled", false)), "Farm save/load should restore the tilled plot state safely"):
		return
	if not _require(int(plot0_after.get("watered_day", 0)) == 0, "Farm save/load should not advance farm state during reload"):
		return
	if not _require(not bool(snapshot_after.get("day_world_orders_open", false)), "Farm save/load should restore with compact overlays safely closed"):
		return
	if not _require(not bool(snapshot_after.get("day_world_night_popup_open", false)), "Farm save/load should keep the dock confirmation safely closed after reload"):
		return
	if not _require(not bool(snapshot_after.get("pending_summary", false)), "Farm save/load should not create a return summary while restoring farm work"):
		return

	print("Day World farm save/load smoke PASS")
	_cleanup(false)


func _require(condition: bool, message: String) -> bool:
	if condition:
		return true
	push_error(message)
	_cleanup(true)
	return false


func _cleanup(failed: bool = true) -> void:
	if _helper != null:
		_helper.cleanup_and_quit(1 if failed else 0)
		return
	get_tree().quit(1 if failed else 0)
