extends Node

const HelperClass := preload("res://tests/smoke/world_save_load_smoke_helper.gd")

var _helper = null


func _ready() -> void:
	_helper = HelperClass.new(self)
	if not await _helper.begin_session("day_world_orders_claim_reload"):
		push_error("Failed to start DayWorld orders claim/reload smoke")
		_cleanup(true)
		return

	if not await _helper.open_orders_board():
		push_error("Orders claim/reload smoke could not open the orders board")
		_cleanup(true)
		return

	var initial_snapshot: Dictionary = _helper.snapshot()
	if not _assert_featured_titles(initial_snapshot, ["Lunch Rush", "Pantry Restock"], "Orders claim/reload smoke should start with the day-1 featured lead ordering"):
		return

	_mark_lunch_rush_ready()
	_helper.sync_daily_orders_progress()
	await _helper.await_frames(1)

	var ready_snapshot: Dictionary = _helper.snapshot()
	var economy_before_claim := _current_economy()
	var gold_before_claim := int(economy_before_claim.get("gold", 0))
	var reputation_before_claim := int(economy_before_claim.get("restaurant_reputation", 0))
	if not _require(int(ready_snapshot.get("day_world_orders_board_ready_count", 0)) >= 1, "Orders claim/reload smoke should surface at least one ready claim after simulated progress"):
		return
	var ordered_titles := _string_array(ready_snapshot.get("day_world_orders_board_ordered_titles", []))
	if not _require(not ordered_titles.is_empty() and ordered_titles[0] == "Lunch Rush", "Ready featured orders should float to the top of the rendered board order"):
		return

	var first_claim_result: Dictionary = _helper.claim_order_by_title("Lunch Rush")
	if not _require(bool(first_claim_result.get("ok", false)), "Orders claim/reload smoke should claim Lunch Rush once"):
		return
	await _helper.await_frames(1)

	var reward: Dictionary = first_claim_result.get("reward", {}) as Dictionary
	var claimed_snapshot: Dictionary = _helper.snapshot()
	var economy_after_claim := _current_economy()
	if not _require(int(economy_after_claim.get("gold", 0)) == gold_before_claim + int(reward.get("gold", 0)), "Claiming Lunch Rush should apply gold exactly once"):
		return
	if not _require(int(economy_after_claim.get("restaurant_reputation", 0)) == reputation_before_claim + int(reward.get("reputation", 0)), "Claiming Lunch Rush should apply reputation exactly once"):
		return
	if not _assert_featured_titles(claimed_snapshot, ["Lunch Rush", "Pantry Restock"], "Claiming a featured order should preserve the day-based featured lead strip"):
		return
	if not _require(int(claimed_snapshot.get("day_world_orders_board_ready_count", 0)) == 0, "Claiming a featured order should clear its ready-to-claim board count"):
		return
	var lunch_rush_card: Dictionary = _helper.find_order_card_by_title("Lunch Rush")
	if not _require(bool(lunch_rush_card.get("completed", false)) and not bool(lunch_rush_card.get("can_claim", false)), "Claimed featured orders should persist as completed and non-claimable"):
		return
	var second_claim_result: Dictionary = _helper.claim_order_by_title("Lunch Rush")
	if not _require(not bool(second_claim_result.get("ok", false)), "Claimed featured orders should not settle twice without reload"):
		return

	if not await _helper.close_orders_board():
		push_error("Orders claim/reload smoke could not close the orders board after the first claim")
		_cleanup(true)
		return
	if not await _helper.open_orders_board():
		push_error("Orders claim/reload smoke could not reopen the orders board after the first claim")
		_cleanup(true)
		return
	var reopened_snapshot: Dictionary = _helper.snapshot()
	if not _assert_featured_titles(reopened_snapshot, ["Lunch Rush", "Pantry Restock"], "Reopening the board should preserve the day-based featured lead strip"):
		return
	if not _require(int(reopened_snapshot.get("day_world_orders_board_ready_count", 0)) == 0, "Reopening the board should keep the claimable count cleared after settlement"):
		return

	_helper.save()
	if await _helper.reload_meta_root() == null:
		push_error("Orders claim/reload smoke failed to reload the meta loop")
		_cleanup(true)
		return
	if not await _helper.open_orders_board():
		push_error("Orders claim/reload smoke could not open the orders board after reload")
		_cleanup(true)
		return

	var reloaded_snapshot: Dictionary = _helper.snapshot()
	if not _assert_featured_titles(reloaded_snapshot, ["Lunch Rush", "Pantry Restock"], "Reloading after claim should preserve the day-based featured lead strip"):
		return
	if not _require(int(reloaded_snapshot.get("day_world_orders_board_ready_count", 0)) == 0, "Reloading after claim should keep the claimable count cleared"):
		return
	var reloaded_lunch_rush: Dictionary = _helper.find_order_card_by_title("Lunch Rush")
	if not _require(bool(reloaded_lunch_rush.get("completed", false)) and not bool(reloaded_lunch_rush.get("can_claim", false)), "Reloading after claim should preserve completed featured order state"):
		return
	var economy_before_reload_claim := _current_economy()
	var reloaded_claim_result: Dictionary = _helper.claim_order_by_title("Lunch Rush")
	if not _require(not bool(reloaded_claim_result.get("ok", false)), "Reloading after claim should not allow duplicate featured-order settlement"):
		return
	await _helper.await_frames(1)
	var economy_after_reload_claim := _current_economy()
	if not _require(int(economy_after_reload_claim.get("gold", 0)) == int(economy_before_reload_claim.get("gold", 0)), "Reloaded duplicate claims should not add extra gold"):
		return
	if not _require(int(economy_after_reload_claim.get("restaurant_reputation", 0)) == int(economy_before_reload_claim.get("restaurant_reputation", 0)), "Reloaded duplicate claims should not add extra reputation"):
		return

	print("Day World orders claim/reload smoke PASS")
	_cleanup(false)


func _assert_featured_titles(snapshot: Dictionary, expected_titles: Array[String], failure_prefix: String) -> bool:
	if not _require(bool(snapshot.get("day_world_orders_open", false)), "%s: orders board should be open" % failure_prefix):
		return false
	var featured_titles := _string_array(snapshot.get("day_world_orders_board_featured_titles", []))
	if not _require(featured_titles == expected_titles, "%s: featured titles should match" % failure_prefix):
		return false
	var expected_subtitle := _t("meta.orders.subtitle_featured", {"value": ", ".join(expected_titles)})
	if not _require(String(snapshot.get("day_world_orders_board_subtitle_text", "")) == expected_subtitle, "%s: board subtitle should match the rendered featured titles" % failure_prefix):
		return false
	var ordered_titles := _string_array(snapshot.get("day_world_orders_board_ordered_titles", []))
	if not _require(ordered_titles.size() >= expected_titles.size(), "%s: board ordering should expose the expected featured titles" % failure_prefix):
		return false
	for title_index in range(expected_titles.size()):
		if not _require(ordered_titles[title_index] == expected_titles[title_index], "%s: rendered order should start with the featured titles" % failure_prefix):
			return false
	return true

func _mark_lunch_rush_ready() -> void:
	var meta_progress: Dictionary = ProfileStore.get_meta_progress_state()
	var economy: Dictionary = (meta_progress.get("economy", {}) as Dictionary).duplicate(true)
	var sold_dishes: Dictionary = (economy.get("sold_dishes_stats", {}) as Dictionary).duplicate(true)
	sold_dishes["field_stew"] = maxi(1, int(sold_dishes.get("field_stew", 0)))
	economy["sold_dishes_stats"] = sold_dishes
	meta_progress["economy"] = economy
	ProfileStore.set_meta_progress_state(meta_progress)


func _current_economy() -> Dictionary:
	var meta_progress: Dictionary = ProfileStore.get_meta_progress_state()
	var economy_variant: Variant = meta_progress.get("economy", {})
	return (economy_variant as Dictionary).duplicate(true) if economy_variant is Dictionary else {}


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
		_helper.cleanup()
	get_tree().quit(1 if failed else 0)
