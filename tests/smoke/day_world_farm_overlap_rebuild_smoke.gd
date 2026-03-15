extends Node

const HelperClass := preload("res://tests/smoke/world_save_load_smoke_helper.gd")

var _helper = null


func _ready() -> void:
	_helper = HelperClass.new(self)
	if not await _helper.begin_session("day_world_farm_overlap_rebuild"):
		push_error("Failed to start DayWorld farm overlap rebuild smoke")
		_cleanup(true)
		return

	if not _require(bool(_helper.meta_root.call("debug_day_world_snap_player_to_zone", "farm_plot_0")), "Farm overlap smoke should be able to place the player on plot 0"):
		return
	await _await_physics_frames(2)
	var snapshot: Dictionary = _helper.snapshot()
	if not _require(String(snapshot.get("day_world_focus_id", "")) == "farm_plot_0", "Farm overlap smoke should lock player focus onto plot 0 before farm actions"):
		return

	if not await _apply_overlap_farm_action("till", "", "Farm overlap smoke should allow tilling plot 0 while the player is overlapping it"):
		return
	if not await _apply_overlap_farm_action("plant", "wheat_seed", "Farm overlap smoke should allow planting plot 0 while the player is overlapping it"):
		return
	if not await _apply_overlap_farm_action("water", "", "Farm overlap smoke should allow watering plot 0 while the player is overlapping it"):
		return

	snapshot = _helper.snapshot()
	var plots: Array = snapshot.get("farm_plots", [])
	var plot0: Dictionary = plots[0] as Dictionary if not plots.is_empty() else {}
	var current_day := int(snapshot.get("current_day", 1))
	if not _require(not plot0.is_empty() and bool(plot0.get("tilled", false)), "Farm overlap smoke should keep plot 0 tilled after rebuild-heavy farm actions"):
		return
	if not _require(String(plot0.get("seed_id", "")) == "wheat_seed", "Farm overlap smoke should preserve the planted seed after rebuild-heavy farm actions"):
		return
	if not _require(int(plot0.get("watered_day", 0)) == current_day, "Farm overlap smoke should preserve watering on the current day after rebuild-heavy farm actions"):
		return
	if not _require(String(snapshot.get("day_world_focus_id", "")) == "farm_plot_0", "Farm overlap smoke should recover focus onto plot 0 after repeated rebuilds"):
		return

	print("Day World farm overlap rebuild smoke PASS")
	_cleanup(false)


func _apply_overlap_farm_action(action_id: String, seed_id: String, failure_prefix: String) -> bool:
	if not _require(bool(_helper.meta_root.call("debug_day_world_select_farm_tool", action_id, seed_id)), "%s: missing tool selection" % failure_prefix):
		return false
	if action_id == "plant":
		var selected_snapshot: Dictionary = _helper.snapshot()
		if not _require(String(selected_snapshot.get("day_world_selected_farm_tool_seed_id", "")) == seed_id, "%s: selected seed id should stay aligned with the hotbar state" % failure_prefix):
			return false
	if not _require(bool(_helper.meta_root.call("debug_day_world_interact_farm_plot", 0)), "%s: farm interaction should succeed" % failure_prefix):
		return false
	await _await_physics_frames(2)
	var snapshot: Dictionary = _helper.snapshot()
	if not _require(String(snapshot.get("day_world_focus_id", "")) == "farm_plot_0", "%s: focus should recover onto plot 0 after the rebuild" % failure_prefix):
		return false
	return true


func _await_physics_frames(frame_count: int) -> void:
	for _i in range(frame_count):
		await get_tree().physics_frame
	await get_tree().process_frame


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
