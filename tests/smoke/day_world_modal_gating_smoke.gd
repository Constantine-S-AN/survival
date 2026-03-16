extends Node

const HelperClass := preload("res://tests/smoke/world_save_load_smoke_helper.gd")

var _helper = null


func _ready() -> void:
	_helper = HelperClass.new(self)
	if not await _helper.begin_session("day_world_modal_gating"):
		push_error("Failed to start DayWorld modal gating smoke")
		_cleanup(true)
		return

	if not _require(bool(_helper.meta_root.call("debug_day_world_select_farm_tool", "till")), "DayWorld gating smoke should expose the till tool"):
		return
	if not _require(bool(_helper.meta_root.call("debug_day_world_interact_farm_plot", 0)), "DayWorld gating smoke should allow tilling plot 0 once"):
		return
	await _helper.await_frames(1)

	var first_till_snapshot: Dictionary = _helper.snapshot()
	var plot0_after_till: Dictionary = _plot_at(first_till_snapshot, 0)
	var budget_after_till := int(first_till_snapshot.get("action_budget", 0))
	if not _require(bool(plot0_after_till.get("tilled", false)), "DayWorld gating smoke should record the first till action on plot 0"):
		return
	_helper.meta_root.call("debug_day_world_interact_farm_plot", 0)
	await _helper.await_frames(1)

	var duplicate_till_snapshot: Dictionary = _helper.snapshot()
	var plot0_after_duplicate: Dictionary = _plot_at(duplicate_till_snapshot, 0)
	if not _require(int(duplicate_till_snapshot.get("action_budget", 0)) == budget_after_till, "Repeated farm input should not spend the daytime budget twice"):
		return
	if not _require(bool(plot0_after_duplicate.get("tilled", false)) and String(plot0_after_duplicate.get("seed_id", "")).is_empty(), "Repeated farm input should not change the tilled plot into a duplicate planted state"):
		return

	_mark_lunch_rush_ready()
	_helper.sync_daily_orders_progress()
	var lunch_rush_ready: Dictionary = _helper.find_order_card_by_title("Lunch Rush")
	if not _require(bool(lunch_rush_ready.get("can_claim", false)), "DayWorld gating smoke should make Lunch Rush claimable before opening the orders board"):
		return

	if not _require(bool(_helper.meta_root.call("debug_day_world_interact", "orders")), "DayWorld gating smoke should open the in-world orders board"):
		return
	await _helper.await_frames(1)

	var orders_snapshot: Dictionary = _helper.snapshot()
	if not _require(bool(orders_snapshot.get("day_world_orders_open", false)), "DayWorld gating smoke should report the orders board as open"):
		return
	if not _require(not bool(_helper.meta_root.call("debug_day_world_attempt_interact", "orders")), "Orders board should block repeated world input while it is open"):
		return
	if not _require(not bool(_helper.meta_root.call("debug_day_world_attempt_interact", "restaurant")), "Orders board should block world entrance interactions behind the overlay"):
		return
	if not _require(not bool(_helper.meta_root.call("debug_day_world_attempt_interact", "farm_plot_0")), "Orders board should block farm interactions behind the overlay"):
		return

	var progress_before_claim: Dictionary = ProfileStore.get_meta_progress_state()
	var economy_before_claim: Dictionary = progress_before_claim.get("economy", {}) as Dictionary
	var gold_before_claim := int(economy_before_claim.get("gold", 0))
	var reputation_before_claim := int(economy_before_claim.get("restaurant_reputation", 0))
	var first_claim_result: Dictionary = _helper.claim_order_by_title("Lunch Rush")
	if not _require(bool(first_claim_result.get("ok", false)), "Orders board should be able to claim Lunch Rush once"):
		return
	await _helper.await_frames(1)

	var reward: Dictionary = first_claim_result.get("reward", {}) as Dictionary
	var progress_after_claim: Dictionary = ProfileStore.get_meta_progress_state()
	var economy_after_claim: Dictionary = progress_after_claim.get("economy", {}) as Dictionary
	var lunch_rush_after_claim: Dictionary = _helper.find_order_card_by_title("Lunch Rush")
	if not _require(int(economy_after_claim.get("gold", 0)) == gold_before_claim + int(reward.get("gold", 0)), "Orders claim should apply the gold reward exactly once"):
		return
	if not _require(int(economy_after_claim.get("restaurant_reputation", 0)) == reputation_before_claim + int(reward.get("reputation", 0)), "Orders claim should apply the reputation reward exactly once"):
		return
	if not _require(bool(lunch_rush_after_claim.get("completed", false)) and not bool(lunch_rush_after_claim.get("can_claim", false)), "Orders claim should complete Lunch Rush and clear its claimable state"):
		return

	var second_claim_result: Dictionary = _helper.claim_order_by_title("Lunch Rush")
	if not _require(not bool(second_claim_result.get("ok", false)), "Orders board should not allow claiming Lunch Rush twice"):
		return
	await _helper.await_frames(1)

	var progress_after_second_claim: Dictionary = ProfileStore.get_meta_progress_state()
	var economy_after_second_claim: Dictionary = progress_after_second_claim.get("economy", {}) as Dictionary
	if not _require(int(economy_after_second_claim.get("gold", 0)) == int(economy_after_claim.get("gold", 0)), "Duplicate order claims should not add extra gold"):
		return
	if not _require(int(economy_after_second_claim.get("restaurant_reputation", 0)) == int(economy_after_claim.get("restaurant_reputation", 0)), "Duplicate order claims should not add extra reputation"):
		return

	if not _require(bool(_helper.meta_root.call("debug_day_world_close_orders_board")), "DayWorld gating smoke should close the orders board through its explicit close path"):
		return
	await _helper.await_frames(1)

	var closed_orders_snapshot: Dictionary = _helper.snapshot()
	if not _require(not bool(closed_orders_snapshot.get("day_world_orders_open", false)), "Closing the orders board should restore the world view cleanly"):
		return
	if not _require(bool(_helper.meta_root.call("debug_day_world_attempt_interact", "restaurant")), "Closing the orders board should restore world entrance input"):
		return
	await _helper.await_frames(1)

	var restaurant_snapshot: Dictionary = _helper.snapshot()
	if not _require(String(restaurant_snapshot.get("current_screen", "")) == "restaurant", "Restored world input should allow the restaurant entrance to open normally"):
		return

	print("Day World modal gating smoke PASS")
	_cleanup(false)


func _plot_at(snapshot: Dictionary, plot_index: int) -> Dictionary:
	var plots_variant: Variant = snapshot.get("farm_plots", [])
	if not (plots_variant is Array):
		return {}
	var plots := plots_variant as Array
	if plot_index < 0 or plot_index >= plots.size():
		return {}
	return plots[plot_index] as Dictionary if plots[plot_index] is Dictionary else {}


func _mark_lunch_rush_ready() -> void:
	var meta_progress: Dictionary = ProfileStore.get_meta_progress_state()
	var economy: Dictionary = (meta_progress.get("economy", {}) as Dictionary).duplicate(true)
	var sold_dishes: Dictionary = (economy.get("sold_dishes_stats", {}) as Dictionary).duplicate(true)
	sold_dishes["field_stew"] = maxi(1, int(sold_dishes.get("field_stew", 0)))
	economy["sold_dishes_stats"] = sold_dishes
	meta_progress["economy"] = economy
	ProfileStore.set_meta_progress_state(meta_progress)


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
