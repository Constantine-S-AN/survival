extends Node

const HelperClass := preload("res://tests/smoke/world_save_load_smoke_helper.gd")

var _helper = null


func _ready() -> void:
	_helper = HelperClass.new(self)
	if not await _helper.begin_session("restaurant_interior_save_load"):
		push_error("Failed to start restaurant interior save/load smoke")
		_cleanup(true)
		return

	if not _require(bool(_helper.meta_root.call("debug_day_world_interact", "restaurant")), "Restaurant save/load should open the worldified restaurant interior"):
		return
	await _helper.await_frames(1)
	if not _require(bool(_helper.meta_root.call("debug_restaurant_interact", "menu")), "Restaurant save/load should open the menu popup from the interior flow"):
		return
	await _helper.await_frames(1)
	if not _require(bool(_helper.meta_root.call("debug_restaurant_toggle_recipe", "field_stew")), "Restaurant save/load should allow planning Field Stew before service"):
		return
	await _helper.await_frames(1)
	if not _require(bool(_helper.meta_root.call("debug_restaurant_interact", "service")), "Restaurant save/load should open the service popup from the interior flow"):
		return
	await _helper.await_frames(1)
	if not _require(bool(_helper.meta_root.call("debug_restaurant_request_service")), "Restaurant save/load should be able to complete a service before saving"):
		return
	await _helper.await_frames(1)
	_helper.sync_daily_orders_progress()

	var snapshot_before: Dictionary = _helper.snapshot()
	var lunch_rush_before: Dictionary = _helper.find_order_card_by_title("Lunch Rush")
	if not _require(String(snapshot_before.get("current_screen", "")) == "restaurant", "Restaurant save/load should save from inside the restaurant interior"):
		return
	if not _require(String(snapshot_before.get("restaurant_world_popup", "")) == "summary", "Restaurant save/load should capture the post-service summary popup state"):
		return
	if not _require(int(snapshot_before.get("restaurant_last_service_day", 0)) == int(snapshot_before.get("current_day", 0)), "Restaurant save/load should capture the completed service day"):
		return
	if not _require(int((snapshot_before.get("sold_dishes_stats", {}) as Dictionary).get("field_stew", 0)) >= 1, "Restaurant save/load should capture sold dish stats after service"):
		return
	if not _require(not String(snapshot_before.get("restaurant_result_title", "")).strip_edges().is_empty(), "Restaurant save/load should capture the summary title after service"):
		return
	if not _require(bool(lunch_rush_before.get("can_claim", false)), "Restaurant save/load should surface Lunch Rush as ready after service without claiming it"):
		return

	var inventory_before: Dictionary = (snapshot_before.get("inventory_materials", {}) as Dictionary).duplicate(true)
	var gold_before := int(snapshot_before.get("gold", 0))
	var stamina_before := int(snapshot_before.get("stamina", 0))
	var phase_before := String(snapshot_before.get("phase", ""))
	var service_day_before := int(snapshot_before.get("restaurant_last_service_day", 0))
	var result_title_before := String(snapshot_before.get("restaurant_result_title", ""))
	var sold_stats_before: Dictionary = (snapshot_before.get("sold_dishes_stats", {}) as Dictionary).duplicate(true)

	_helper.save()
	if await _helper.reload_meta_root() == null:
		push_error("Failed to reload restaurant interior save/load smoke")
		_cleanup(true)
		return

	_helper.sync_daily_orders_progress()
	var snapshot_after: Dictionary = _helper.snapshot()
	var lunch_rush_after: Dictionary = _helper.find_order_card_by_title("Lunch Rush")
	if not _require(String(snapshot_after.get("current_screen", "")) == "restaurant", "Restaurant save/load should restore the restaurant interior context"):
		return
	if not _require(String(snapshot_after.get("restaurant_world_popup", "")) == "summary", "Restaurant save/load should restore the interior summary popup safely"):
		return
	if not _require(String(snapshot_after.get("phase", "")) == phase_before, "Restaurant save/load should preserve the current phase after service"):
		return
	if not _require(int(snapshot_after.get("stamina", 0)) == stamina_before, "Restaurant save/load should preserve stamina after service"):
		return
	if not _require(int(snapshot_after.get("gold", 0)) == gold_before, "Restaurant save/load should not duplicate gold rewards after reload"):
		return
	if not _require(snapshot_after.get("inventory_materials", {}) == inventory_before, "Restaurant save/load should not duplicate or re-consume ingredients after reload"):
		return
	if not _require(int(snapshot_after.get("restaurant_last_service_day", 0)) == service_day_before, "Restaurant save/load should preserve the service day without replaying service settlement"):
		return
	if not _require(snapshot_after.get("sold_dishes_stats", {}) == sold_stats_before, "Restaurant save/load should preserve sold dish stats without replaying service settlement"):
		return
	if not _require(String(snapshot_after.get("restaurant_result_title", "")) == result_title_before, "Restaurant save/load should preserve the visible summary title"):
		return
	if not _require(bool(lunch_rush_after.get("can_claim", false)), "Restaurant save/load should preserve ready daily-order progress without auto-claiming it"):
		return

	if not _require(bool(_helper.meta_root.call("debug_restaurant_interact", "service")), "Restaurant save/load should still allow checking the service station after reload"):
		return
	await _helper.await_frames(1)
	var service_popup_snapshot: Dictionary = _helper.snapshot()
	if not _require(String(service_popup_snapshot.get("restaurant_world_popup", "")) == "service", "Restaurant save/load should reopen the service popup safely after reload"):
		return
	if not _require(not bool(service_popup_snapshot.get("restaurant_service_button_enabled", true)), "Restaurant save/load should keep service closed for the day after reload"):
		return
	if not _require(not bool(_helper.meta_root.call("debug_restaurant_request_service")), "Restaurant save/load should not allow duplicate service settlement after reload"):
		return

	print("Restaurant interior save/load smoke PASS")
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
