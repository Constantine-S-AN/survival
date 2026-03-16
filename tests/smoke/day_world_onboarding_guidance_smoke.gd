extends Node

const HelperClass := preload("res://tests/smoke/world_save_load_smoke_helper.gd")

var _helper = null


func _ready() -> void:
	_helper = HelperClass.new(self)
	if not await _helper.begin_session("day_world_onboarding_guidance"):
		push_error("Failed to start DayWorld onboarding guidance smoke")
		_cleanup(true)
		return

	if not await _assert_day_guidance(
		1,
		"meta.hub.guide_title_day1",
		["Field Stew", "night combat"],
		["Lunch Rush", "Pantry Restock"]
	):
		return

	if not await _advance_to_day_two():
		return
	if not await _assert_day_guidance(
		2,
		"meta.hub.guide_title_day2",
		["Water yesterday's crops", "Night haul matters now"],
		["Cold Storage", "Lunch Rush"]
	):
		return

	if not await _advance_to_day_three():
		return
	if not await _assert_day_guidance(
		3,
		"meta.hub.guide_title_day3",
		["Fresh stock", "night loot"],
		["Cold Storage", "Salt Request"]
	):
		return

	print("Day World onboarding guidance smoke PASS")
	_cleanup(false)


func _assert_day_guidance(current_day: int, guide_title_key: String, required_fragments: Array[String], expected_featured_titles: Array[String]) -> bool:
	var snapshot: Dictionary = _helper.snapshot()
	var expected_guide_title := _t(guide_title_key)
	if not _require(int(snapshot.get("current_day", 0)) == current_day, "Onboarding guidance smoke should reach day %d before checking guide state" % current_day):
		return false
	if not _require(String(snapshot.get("day_hub_guide_title", "")) == expected_guide_title, "Day %d should show the expected onboarding guide title" % current_day):
		return false
	if not _require(String(snapshot.get("day_world_hud_guide_title", "")) == expected_guide_title, "Day %d world HUD guide title should match the day hub guide title" % current_day):
		return false
	var guide_text := String(snapshot.get("day_hub_guide_text", ""))
	if not _require(String(snapshot.get("day_world_hud_guide_text", "")) == guide_text, "Day %d world HUD guide text should match the shared onboarding guide text" % current_day):
		return false
	var focus_text := String(snapshot.get("day_hub_guide_focus_text", ""))
	if not _require(not focus_text.is_empty(), "Day %d guide should expose a focused next-step line" % current_day):
		return false
	if not _require(String(snapshot.get("day_world_guide_focus_text", "")) == focus_text, "Day %d world focus line should stay aligned with the day hub guidance" % current_day):
		return false
	if not _require(String(snapshot.get("day_world_prompt_text", "")).find(focus_text) >= 0, "Day %d idle world prompt should surface the current guide focus" % current_day):
		return false
	for fragment in required_fragments:
		if not _require(guide_text.find(fragment) >= 0, "Day %d guide should still contain '%s'" % [current_day, fragment]):
			return false
	for featured_title in expected_featured_titles:
		if not _require(guide_text.find(featured_title) >= 0, "Day %d guide should still surface featured lead '%s'" % [current_day, featured_title]):
			return false

	if not await _helper.open_orders_board():
		push_error("Day %d onboarding guidance smoke could not open the orders board" % current_day)
		_cleanup(true)
		return false
	snapshot = _helper.snapshot()
	if not _assert_board_alignment(snapshot, expected_featured_titles, "Day %d board alignment should match the featured daily-order logic" % current_day):
		return false
	if not await _helper.close_orders_board():
		push_error("Day %d onboarding guidance smoke could not close the orders board" % current_day)
		_cleanup(true)
		return false
	return true


func _assert_board_alignment(snapshot: Dictionary, expected_featured_titles: Array[String], failure_prefix: String) -> bool:
	if not _require(bool(snapshot.get("day_world_orders_open", false)), "%s: orders board should be open" % failure_prefix):
		return false
	if not _require(String(snapshot.get("day_world_orders_board_title_text", "")) == _t("meta.orders.title"), "%s: board title should stay aligned" % failure_prefix):
		return false
	var featured_titles := _string_array(snapshot.get("day_world_orders_board_featured_titles", []))
	if not _require(featured_titles == expected_featured_titles, "%s: featured board leads should match the expected top priorities" % failure_prefix):
		return false
	var ordered_titles := _string_array(snapshot.get("day_world_orders_board_ordered_titles", []))
	if not _require(ordered_titles.size() >= expected_featured_titles.size(), "%s: board should list enough ordered titles to validate lead ordering" % failure_prefix):
		return false
	for title_index in range(expected_featured_titles.size()):
		if not _require(ordered_titles[title_index] == expected_featured_titles[title_index], "%s: board ordering should begin with the featured starter leads" % failure_prefix):
			return false
	var expected_subtitle := _t("meta.orders.subtitle_featured", {"value": ", ".join(expected_featured_titles)})
	if not _require(String(snapshot.get("day_world_orders_board_subtitle_text", "")) == expected_subtitle, "%s: board subtitle should match the featured lead list" % failure_prefix):
		return false
	var ready_count := int(snapshot.get("day_world_orders_board_ready_count", 0))
	var featured_count := int(snapshot.get("day_world_orders_board_featured_count", 0))
	var expected_summary := _t("meta.orders.summary_featured", {
		"active": ordered_titles.size(),
		"ready": ready_count,
		"featured": featured_count
	})
	return _require(String(snapshot.get("day_world_orders_board_summary_text", "")) == expected_summary, "%s: board summary should stay aligned with the rendered counts" % failure_prefix)


func _advance_to_day_two() -> bool:
	if not await _helper.reach_evening_via_farm_loop():
		push_error("Onboarding guidance smoke could not reach evening on day 1")
		_cleanup(true)
		return false
	if not await _helper.open_night_departure():
		push_error("Onboarding guidance smoke could not open the dock confirmation on day 1")
		_cleanup(true)
		return false
	if not await _helper.confirm_night_departure():
		push_error("Onboarding guidance smoke could not depart for the first night run")
		_cleanup(true)
		return false
	if not await _helper.complete_night({
		"exit_reason": "abandoned",
		"time_survived_sec": 30.0,
		"kills": 5,
		"seed": 424242
	}):
		push_error("Onboarding guidance smoke could not complete the first return summary state")
		_cleanup(true)
		return false
	if not await _helper.continue_summary():
		push_error("Onboarding guidance smoke could not continue from the first return summary")
		_cleanup(true)
		return false
	var snapshot: Dictionary = _helper.snapshot()
	if not _require(bool(snapshot.get("day_world_arrival_banner_visible", false)), "Day 2 should briefly surface the next-day handoff banner"):
		return false
	if not _require(String(snapshot.get("day_world_arrival_banner_body_text", "")).find("Water yesterday's crops") >= 0, "Day 2 handoff banner should point at the carry-over farm step"):
		return false
	return int(_helper.snapshot().get("current_day", 0)) == 2


func _advance_to_day_three() -> bool:
	if not await _helper.wait_until_evening_via_world():
		push_error("Onboarding guidance smoke could not reach evening on day 2")
		_cleanup(true)
		return false
	if not await _helper.open_night_departure():
		push_error("Onboarding guidance smoke could not open the dock confirmation on day 2")
		_cleanup(true)
		return false
	if not await _helper.confirm_night_departure():
		push_error("Onboarding guidance smoke could not depart for the second night run")
		_cleanup(true)
		return false
	if not await _helper.complete_night({
		"exit_reason": "completed",
		"time_survived_sec": 92.0,
		"kills": 18,
		"seed": 424243
	}):
		push_error("Onboarding guidance smoke could not complete the second return summary state")
		_cleanup(true)
		return false
	if not await _helper.continue_summary():
		push_error("Onboarding guidance smoke could not continue from the second return summary")
		_cleanup(true)
		return false
	var snapshot: Dictionary = _helper.snapshot()
	if not _require(bool(snapshot.get("day_world_arrival_banner_visible", false)), "Day 3 should briefly surface the next-day handoff banner"):
		return false
	var arrival_banner_text := String(snapshot.get("day_world_arrival_banner_body_text", ""))
	if not _require(
		arrival_banner_text.find("Harvest first") >= 0
		or arrival_banner_text.find("Fresh stock") >= 0
		or arrival_banner_text.find("plate") >= 0,
		"Day 3 handoff banner should point at the first harvest payoff or the resulting stock-routing step"
	):
		return false
	return int(_helper.snapshot().get("current_day", 0)) == 3


func _string_array(items_variant: Variant) -> Array[String]:
	var output: Array[String] = []
	if not (items_variant is Array):
		return output
	for item_variant in (items_variant as Array):
		output.append(String(item_variant).strip_edges())
	return output


func _t(key: String, args: Dictionary = {}) -> String:
	if Localization == null or not Localization.has_method("t"):
		return key
	return String(Localization.call("t", key, args))


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
