extends Node

const HelperClass := preload("res://tests/smoke/world_save_load_smoke_helper.gd")

var _helper = null


func _ready() -> void:
	_helper = HelperClass.new(self)
	if not await _helper.begin_session("restaurant_world_gating"):
		push_error("Failed to start restaurant world gating smoke")
		_cleanup(true)
		return

	if not _require(bool(_helper.meta_root.call("debug_day_world_attempt_interact", "restaurant")), "Restaurant entrance should open once from the world"):
		return
	if not _require(not bool(_helper.meta_root.call("debug_day_world_attempt_interact", "restaurant")), "Repeated world input should not retrigger the restaurant entrance after the transition starts"):
		return
	await _helper.await_frames(1)

	var restaurant_snapshot: Dictionary = _helper.snapshot()
	if not _require(String(restaurant_snapshot.get("current_screen", "")) == "restaurant", "Restaurant entrance should land inside the restaurant interior"):
		return

	if not _require(bool(_helper.meta_root.call("debug_restaurant_attempt_interact", "menu")), "Restaurant menu station should open from the interior once"):
		return
	await _helper.await_frames(1)

	var menu_snapshot: Dictionary = _helper.snapshot()
	if not _require(String(menu_snapshot.get("restaurant_world_popup", "")) == "menu", "Restaurant menu interaction should open the planning popup"):
		return
	if not _require(not bool(_helper.meta_root.call("debug_restaurant_attempt_interact", "menu")), "Restaurant menu popup should block repeated station input while it is open"):
		return
	if not _require(not bool(_helper.meta_root.call("debug_restaurant_attempt_interact", "prep")), "Restaurant menu popup should block other interior stations behind the overlay"):
		return
	if not _require(not bool(_helper.meta_root.call("debug_restaurant_attempt_interact", "door")), "Restaurant menu popup should block the exit door behind the overlay"):
		return
	if not _require(bool(_helper.meta_root.call("debug_restaurant_toggle_recipe", "field_stew")), "Restaurant menu popup should still allow planning the starter service recipe"):
		return

	await _helper.await_frames(1)
	var planned_snapshot: Dictionary = _helper.snapshot()
	if not _require((planned_snapshot.get("restaurant_menu_ids", []) as Array).has("field_stew"), "Restaurant menu popup should persist the selected service recipe"):
		return

	if not _require(bool(_helper.meta_root.call("debug_restaurant_close_popup")), "Restaurant menu popup should support closing cleanly"):
		return
	await _helper.await_frames(1)

	if not _require(bool(_helper.meta_root.call("debug_restaurant_attempt_interact", "service")), "Restaurant service station should reopen after the menu popup closes"):
		return
	await _helper.await_frames(1)

	var service_snapshot: Dictionary = _helper.snapshot()
	var gold_before_service := int(service_snapshot.get("gold", 0))
	if not _require(String(service_snapshot.get("restaurant_world_popup", "")) == "service", "Restaurant service station should open the service popup"):
		return
	if not _require(bool(service_snapshot.get("restaurant_service_button_enabled", false)), "Restaurant service popup should enable service when the menu is valid"):
		return
	if not _require(bool(_helper.meta_root.call("debug_restaurant_request_service")), "Restaurant service should settle once from the service popup"):
		return
	if not _require(not bool(_helper.meta_root.call("debug_restaurant_request_service")), "Restaurant service should not settle twice from repeated input spam"):
		return
	await _helper.await_frames(1)

	var summary_snapshot: Dictionary = _helper.snapshot()
	if not _require(String(summary_snapshot.get("restaurant_world_popup", "")) == "summary", "Restaurant service should surface the post-service summary popup"):
		return
	if not _require(int(summary_snapshot.get("restaurant_last_service_day", 0)) == int(summary_snapshot.get("current_day", 0)), "Restaurant service should record the served day exactly once"):
		return
	if not _require(int(summary_snapshot.get("gold", 0)) > gold_before_service, "Restaurant service should award gold through the worldified interior flow"):
		return
	if not _require(not bool(_helper.meta_root.call("debug_restaurant_attempt_interact", "door")), "Restaurant summary popup should block the exit door behind the overlay"):
		return

	if not _require(bool(_helper.meta_root.call("debug_restaurant_close_popup")), "Restaurant summary popup should support closing cleanly"):
		return
	await _helper.await_frames(1)

	if not _require(bool(_helper.meta_root.call("debug_restaurant_attempt_interact", "service")), "Restaurant service station should still be reachable after the summary closes"):
		return
	await _helper.await_frames(1)

	var closed_service_snapshot: Dictionary = _helper.snapshot()
	if not _require(String(closed_service_snapshot.get("restaurant_world_popup", "")) == "service", "Restaurant service station should reopen the service popup after the summary closes"):
		return
	if not _require(not bool(closed_service_snapshot.get("restaurant_service_button_enabled", false)), "Restaurant service popup should show service as closed for the rest of the day"):
		return
	if not _require(not bool(_helper.meta_root.call("debug_restaurant_request_service")), "Restaurant service should stay one-shot even after reopening the station"):
		return
	if not _require(bool(_helper.meta_root.call("debug_restaurant_close_popup")), "Closed-for-the-day service popup should support closing cleanly"):
		return
	await _helper.await_frames(1)

	if not _require(bool(_helper.meta_root.call("debug_restaurant_attempt_interact", "door")), "Closing restaurant overlays should restore interior exit input"):
		return
	await _helper.await_frames(1)

	var exit_snapshot: Dictionary = _helper.snapshot()
	if not _require(String(exit_snapshot.get("current_screen", "")) == "day_hub", "Restaurant exit should return to the day world after overlays close"):
		return

	print("Restaurant world gating smoke PASS")
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
