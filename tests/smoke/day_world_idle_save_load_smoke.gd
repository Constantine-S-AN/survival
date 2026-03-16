extends Node

const HelperClass := preload("res://tests/smoke/world_save_load_smoke_helper.gd")

var _helper = null


func _ready() -> void:
	_helper = HelperClass.new(self)
	if not await _helper.begin_session("day_world_idle_save_load"):
		push_error("Failed to start DayWorld idle save/load smoke")
		_cleanup(true)
		return

	var snapshot_before: Dictionary = _helper.snapshot()
	if not _require(String(snapshot_before.get("current_screen", "")) == "day_hub", "Idle save/load should start in the day world hub state"):
		return
	if not _require(int(snapshot_before.get("current_day", 0)) == 1, "Idle save/load should start on day 1"):
		return
	if not _require(String(snapshot_before.get("phase", "")) == "morning", "Idle save/load should start in the morning phase"):
		return
	if not _require(String(snapshot_before.get("day_world_selected_hotbar_id", "")) == "hand", "Idle save/load should start with the hand hotbar slot selected"):
		return
	if not _require(not bool(snapshot_before.get("day_world_orders_open", false)), "Idle save/load should start with the orders board closed"):
		return
	if not _require(not bool(snapshot_before.get("day_world_night_popup_open", false)), "Idle save/load should start with the dock confirmation closed"):
		return
	if not _require(not bool(snapshot_before.get("day_world_night_ready", false)), "Idle save/load should start before the dock becomes night-ready"):
		return
	if not _require(not bool(snapshot_before.get("pending_summary", false)), "Idle save/load should not start with a pending return summary"):
		return

	var player_position_before: Vector2 = snapshot_before.get("day_world_player_position", Vector2.ZERO)
	var visible_pickups_before: Array = (snapshot_before.get("day_world_visible_pickup_ids", []) as Array).duplicate(true)
	var inventory_before: Dictionary = (snapshot_before.get("inventory_materials", {}) as Dictionary).duplicate(true)
	var gold_before := int(snapshot_before.get("gold", 0))
	var stamina_before := int(snapshot_before.get("stamina", 0))

	_helper.save()
	if await _helper.reload_meta_root() == null:
		push_error("Failed to reload DayWorld idle save/load smoke")
		_cleanup(true)
		return

	var snapshot_after: Dictionary = _helper.snapshot()
	if not _require(String(snapshot_after.get("current_screen", "")) == "day_hub", "Idle save/load should restore the overworld context"):
		return
	if not _require(int(snapshot_after.get("current_day", 0)) == 1, "Idle save/load should preserve the current day"):
		return
	if not _require(String(snapshot_after.get("phase", "")) == "morning", "Idle save/load should preserve the current phase"):
		return
	if not _require(String(snapshot_after.get("day_world_selected_hotbar_id", "")) == "hand", "Idle save/load should preserve the default hotbar selection"):
		return
	if not _require(snapshot_after.get("inventory_materials", {}) == inventory_before, "Idle save/load should preserve shared inventory state"):
		return
	if not _require(int(snapshot_after.get("gold", 0)) == gold_before, "Idle save/load should preserve shared gold state"):
		return
	if not _require(int(snapshot_after.get("stamina", 0)) == stamina_before, "Idle save/load should preserve stamina state"):
		return
	if not _require(snapshot_after.get("day_world_visible_pickup_ids", []) == visible_pickups_before, "Idle save/load should preserve visible world pickups"):
		return
	if not _require(player_position_before.distance_to(snapshot_after.get("day_world_player_position", Vector2.ZERO)) <= 0.1, "Idle save/load should restore the day world player context safely"):
		return
	if not _require(not bool(snapshot_after.get("day_world_orders_open", false)), "Idle save/load should keep the orders board safely closed after reload"):
		return
	if not _require(not bool(snapshot_after.get("day_world_night_popup_open", false)), "Idle save/load should keep the dock confirmation safely closed after reload"):
		return
	if not _require(not bool(snapshot_after.get("day_world_night_ready", false)), "Idle save/load should preserve dock readiness state"):
		return
	if not _require(not bool(snapshot_after.get("night_active", false)), "Idle save/load should not launch night combat while reloading the overworld"):
		return
	if not _require(not bool(snapshot_after.get("pending_summary", false)), "Idle save/load should not create a return summary while reloading the overworld"):
		return

	print("Day World idle save/load smoke PASS")
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
