extends Node


func _ready() -> void:
	var daily_orders: Node = get_node_or_null("/root/DailyOrders")
	if daily_orders == null:
		push_error("DailyOrders autoload missing")
		get_tree().quit(1)
		return
	if ProfileStore == null:
		push_error("ProfileStore autoload missing")
		get_tree().quit(1)
		return
	var session_id := "daily_orders_refresh_%d" % int(Time.get_ticks_usec() % 1000000)
	ProfileStore.begin_test_session(session_id, true)
	ProfileStore.load_profile("diver", "map_trench_lab")
	daily_orders.call("_reset_runtime_state")
	await get_tree().process_frame
	var cards := _get_cards(daily_orders)
	if cards.is_empty():
		push_error("Daily orders failed to initialize before refresh test setup")
		_cleanup(daily_orders)
		return
	var meta_progress := ProfileStore.get_meta_progress_state()
	var gold_before := int((meta_progress.get("economy", {}) as Dictionary).get("gold", 0))
	var reputation_before := int((meta_progress.get("economy", {}) as Dictionary).get("restaurant_reputation", 0))
	var economy: Dictionary = (meta_progress.get("economy", {}) as Dictionary).duplicate(true)
	var sold_dishes: Dictionary = (economy.get("sold_dishes_stats", {}) as Dictionary).duplicate(true)
	sold_dishes["field_stew"] = maxi(0, int(sold_dishes.get("field_stew", 0))) + 1
	economy["sold_dishes_stats"] = sold_dishes
	meta_progress["economy"] = economy
	var inventory: Dictionary = (meta_progress.get("inventory", {}) as Dictionary).duplicate(true)
	var materials: Dictionary = (inventory.get("materials", {}) as Dictionary).duplicate(true)
	materials["wheat"] = maxi(0, int(materials.get("wheat", 0))) + 1
	inventory["materials"] = materials
	meta_progress["inventory"] = inventory
	ProfileStore.set_meta_progress_state(meta_progress)
	daily_orders.call("_sync_progress")
	cards = _get_cards(daily_orders)
	var stew_card := _get_card(cards, 101)
	var wheat_card := _get_card(cards, 102)
	if not bool(stew_card.get("can_claim", false)):
		push_error("Day 1 completed order was not ready before refresh")
		_cleanup(daily_orders)
		return
	if String(wheat_card.get("progress_text", "")) != "1/2":
		push_error("Day 1 partial progress did not register before refresh")
		_cleanup(daily_orders)
		return
	meta_progress = ProfileStore.get_meta_progress_state()
	var day_state: Dictionary = (meta_progress.get("day_state", {}) as Dictionary).duplicate(true)
	day_state["current_day"] = int(day_state.get("current_day", 1)) + 1
	meta_progress["day_state"] = day_state
	ProfileStore.set_meta_progress_state(meta_progress)
	daily_orders.call("_sync_progress")
	cards = _get_cards(daily_orders)
	stew_card = _get_card(cards, 101)
	wheat_card = _get_card(cards, 102)
	var gold_after_refresh := int((ProfileStore.get_meta_progress_state().get("economy", {}) as Dictionary).get("gold", 0))
	if gold_after_refresh != gold_before + 6:
		push_error("Completed previous-day orders did not auto-claim exactly once on rollover")
		_cleanup(daily_orders)
		return
	var reputation_after_refresh := int((ProfileStore.get_meta_progress_state().get("economy", {}) as Dictionary).get("restaurant_reputation", 0))
	if reputation_after_refresh != reputation_before + 1:
		push_error("Previous-day non-gold rewards did not auto-claim exactly once on rollover")
		_cleanup(daily_orders)
		return
	if bool(stew_card.get("completed", false)) or bool(stew_card.get("can_claim", false)):
		push_error("Previous-day completion state leaked into the refreshed board")
		_cleanup(daily_orders)
		return
	if String(wheat_card.get("progress_text", "")) != "0/2":
		push_error("Partial progress did not reset on the new day")
		_cleanup(daily_orders)
		return
	var saved_state := ProfileStore.get_daily_orders_state()
	if int(saved_state.get("current_day", 0)) != int(day_state.get("current_day", 0)):
		push_error("Daily order state did not advance to the refreshed day")
		_cleanup(daily_orders)
		return
	daily_orders.call("_reset_runtime_state")
	ProfileStore.load_profile("diver", "map_trench_lab")
	await get_tree().process_frame
	cards = _get_cards(daily_orders)
	stew_card = _get_card(cards, 101)
	wheat_card = _get_card(cards, 102)
	var gold_after_reload := int((ProfileStore.get_meta_progress_state().get("economy", {}) as Dictionary).get("gold", 0))
	if gold_after_reload != gold_after_refresh:
		push_error("Reload duplicated an auto-claimed rollover reward")
		_cleanup(daily_orders)
		return
	var reputation_after_reload := int((ProfileStore.get_meta_progress_state().get("economy", {}) as Dictionary).get("restaurant_reputation", 0))
	if reputation_after_reload != reputation_after_refresh:
		push_error("Reload duplicated or lost a rollover non-gold reward")
		_cleanup(daily_orders)
		return
	if bool(stew_card.get("completed", false)) or bool(stew_card.get("can_claim", false)):
		push_error("Reload unexpectedly rerolled the board into a previous-day completed state")
		_cleanup(daily_orders)
		return
	if String(wheat_card.get("progress_text", "")) != "0/2":
		push_error("Reload did not preserve the refreshed board state")
		_cleanup(daily_orders)
		return
	print("Daily orders refresh smoke PASS")
	_cleanup(daily_orders, false)
	get_tree().quit()


func _get_cards(daily_orders: Node) -> Array:
	var cards_variant: Variant = daily_orders.call("get_order_cards")
	if cards_variant is Array:
		return cards_variant as Array
	return []


func _get_card(cards: Array, order_id: int) -> Dictionary:
	for card_variant in cards:
		if not (card_variant is Dictionary):
			continue
		var card: Dictionary = card_variant
		if int(card.get("id", 0)) == order_id:
			return card
	return {}


func _cleanup(daily_orders: Node, failed: bool = true) -> void:
	daily_orders.call("_reset_runtime_state")
	if ProfileStore != null:
		ProfileStore.end_test_session(true)
	if failed:
		get_tree().quit(1)
