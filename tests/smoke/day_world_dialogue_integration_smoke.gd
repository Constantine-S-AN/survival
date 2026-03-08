extends Node

const HelperClass := preload("res://tests/smoke/world_save_load_smoke_helper.gd")

var _helper = null


func _ready() -> void:
	_helper = HelperClass.new(self)
	if not await _helper.begin_session("day_world_dialogue_integration"):
		push_error("Failed to start DayWorld dialogue integration smoke")
		_cleanup(true)
		return

	if not await _plan_field_stew_menu():
		return

	var snapshot: Dictionary = _helper.snapshot()
	if not _require(String(snapshot.get("dialogue_day_hub_intro_candidate_id", "")) == "day_hub_intro", "Fresh day-1 world state should still surface the intro dialogue candidate"):
		return
	if not await _mark_seen_and_require("day_hub_intro"):
		return
	snapshot = _helper.snapshot()
	if not _require(String(snapshot.get("dialogue_day_hub_intro_candidate_id", "")) == "", "Seen day-1 intro dialogue should not replay inside the same world run"):
		return

	_helper.save()
	if await _helper.reload_meta_root() == null:
		push_error("Dialogue integration smoke failed to reload after intro seen-guard")
		_cleanup(true)
		return
	snapshot = _helper.snapshot()
	if not _require((snapshot.get("dialogue_seen_ids", []) as Array).has("day_hub_intro"), "Intro dialogue seen-guard should survive reload"):
		return
	if not _require(String(snapshot.get("dialogue_day_hub_intro_candidate_id", "")) == "", "Reloading after seeing the intro should not re-arm the intro dialogue"):
		return

	if not await _helper.wait_until_evening_via_world():
		push_error("Dialogue integration smoke could not reach evening for the first night run")
		_cleanup(true)
		return
	if not await _helper.open_night_departure():
		push_error("Dialogue integration smoke could not open the dock confirmation for the first night run")
		_cleanup(true)
		return
	if not await _helper.confirm_night_departure():
		push_error("Dialogue integration smoke could not depart for the first night run")
		_cleanup(true)
		return
	if not await _helper.complete_night({
		"exit_reason": "abandoned",
		"time_survived_sec": 30.0,
		"kills": 5,
		"seed": 424242
	}):
		push_error("Dialogue integration smoke could not enter the first return summary")
		_cleanup(true)
		return

	snapshot = _helper.snapshot()
	if not _require(String(snapshot.get("dialogue_return_summary_candidate_id", "")) == "return_summary_first_return", "First return summary should surface the first-return dialogue candidate"):
		return
	if not await _mark_seen_and_require("return_summary_first_return"):
		return

	_helper.save()
	if await _helper.reload_meta_root() == null:
		push_error("Dialogue integration smoke failed to reload while the first return summary was pending")
		_cleanup(true)
		return
	snapshot = _helper.snapshot()
	if not _require(String(snapshot.get("current_screen", "")) == "return_summary", "Reloading during the pending return summary should restore that overlay state"):
		return
	if not _require((snapshot.get("dialogue_seen_ids", []) as Array).has("return_summary_first_return"), "First-return dialogue seen-guard should survive reload"):
		return
	if not _require(String(snapshot.get("dialogue_return_summary_candidate_id", "")) != "return_summary_first_return", "Reloading the same pending summary should not replay the first-return dialogue"):
		return
	if not await _helper.continue_summary():
		push_error("Dialogue integration smoke could not continue from the first return summary")
		_cleanup(true)
		return

	if not await _open_restaurant_service_popup():
		return
	if not _require(bool(_helper.meta_root.call("debug_restaurant_request_service")), "Dialogue integration smoke should be able to trigger restaurant service from the worldified interior"):
		return
	await _helper.await_frames(1)

	snapshot = _helper.snapshot()
	if not _require(int(snapshot.get("current_day", 0)) == 2, "Restaurant dialogue integration should run on day 2 after the first return"):
		return
	if not _require(String(snapshot.get("dialogue_restaurant_candidate_id", "")) == "restaurant_special_customer_field_stew", "Day-2 field stew service should surface the special-customer dialogue candidate"):
		return
	if not await _mark_seen_and_require("restaurant_special_customer_field_stew"):
		return
	if not _require(bool(_helper.meta_root.call("debug_restaurant_close_popup")), "Dialogue integration smoke should close the restaurant summary popup after marking dialogue seen"):
		return
	await _helper.await_frames(1)
	if not _require(bool(_helper.meta_root.call("debug_restaurant_interact", "door")), "Dialogue integration smoke should return to the day hub from the restaurant interior"):
		return
	await _helper.await_frames(1)

	_helper.save()
	if await _helper.reload_meta_root() == null:
		push_error("Dialogue integration smoke failed to reload after the restaurant dialogue seen-guard")
		_cleanup(true)
		return
	if not _require(bool(_helper.meta_root.call("debug_day_world_interact", "restaurant")), "Dialogue integration smoke should reopen the restaurant after reload"):
		return
	await _helper.await_frames(1)

	snapshot = _helper.snapshot()
	if not _require((snapshot.get("dialogue_seen_ids", []) as Array).has("restaurant_special_customer_field_stew"), "Restaurant dialogue seen-guard should survive reload"):
		return
	if not _require(String(snapshot.get("dialogue_restaurant_candidate_id", "")) == "", "Reloading after the restaurant special-customer dialogue should not replay it"):
		return

	print("Day World dialogue integration smoke PASS")
	_cleanup(false)


func _plan_field_stew_menu() -> bool:
	if not _require(bool(_helper.meta_root.call("debug_day_world_interact", "restaurant")), "Dialogue integration smoke should open the restaurant from the day world before planning the menu"):
		return false
	await _helper.await_frames(1)
	if not _require(bool(_helper.meta_root.call("debug_restaurant_interact", "menu")), "Dialogue integration smoke should open the menu board from the restaurant interior"):
		return false
	await _helper.await_frames(1)
	if not _require(bool(_helper.meta_root.call("debug_restaurant_toggle_recipe", "field_stew")), "Dialogue integration smoke should add Field Stew to the planned menu"):
		return false
	await _helper.await_frames(1)
	var snapshot: Dictionary = _helper.snapshot()
	if not _require((snapshot.get("restaurant_menu_ids", []) as Array).has("field_stew"), "Dialogue integration smoke should persist the planned Field Stew recipe before the first return"):
		return false
	if not _require(bool(_helper.meta_root.call("debug_restaurant_interact", "door")), "Dialogue integration smoke should return to the day hub after planning the menu"):
		return false
	await _helper.await_frames(1)
	return true


func _open_restaurant_service_popup() -> bool:
	if not _require(bool(_helper.meta_root.call("debug_day_world_interact", "restaurant")), "Dialogue integration smoke should reopen the restaurant on day 2"):
		return false
	await _helper.await_frames(1)
	if not _require(bool(_helper.meta_root.call("debug_restaurant_interact", "service")), "Dialogue integration smoke should open the service counter from the restaurant interior"):
		return false
	await _helper.await_frames(1)
	var snapshot: Dictionary = _helper.snapshot()
	if not _require(String(snapshot.get("restaurant_world_popup", "")) == "service", "Dialogue integration smoke should reach the restaurant service popup before service"):
		return false
	return _require(bool(snapshot.get("restaurant_service_button_enabled", false)), "Dialogue integration smoke should keep the service button enabled for the day-2 field stew run")


func _mark_seen_and_require(dialogue_id: String) -> bool:
	if not _require(bool(_helper.meta_root.call("debug_mark_dialogue_seen", dialogue_id)), "Dialogue integration smoke should be able to persist seen dialogue '%s'" % dialogue_id):
		return false
	await _helper.await_frames(1)
	return _require((_helper.snapshot().get("dialogue_seen_ids", []) as Array).has(dialogue_id), "Dialogue integration smoke should record '%s' in the seen-dialogue state" % dialogue_id)


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
