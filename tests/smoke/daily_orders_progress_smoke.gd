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
	var session_id := "daily_orders_progress_%d" % int(Time.get_ticks_usec() % 1000000)
	ProfileStore.begin_test_session(session_id, true)
	ProfileStore.load_profile("diver", "map_trench_lab")
	daily_orders.call("_reset_runtime_state")
	await get_tree().process_frame
	var cards := _get_cards(daily_orders)
	if String(_get_card(cards, 104).get("progress_text", "")) != "0/2":
		push_error("Restaurant order did not start with clean progress")
		_cleanup(daily_orders)
		return
	if String(_get_card(cards, 102).get("progress_text", "")) != "0/2":
		push_error("Farm order did not start with clean progress")
		_cleanup(daily_orders)
		return
	var meta_progress := ProfileStore.get_meta_progress_state()
	var economy: Dictionary = (meta_progress.get("economy", {}) as Dictionary).duplicate(true)
	var sold_dishes: Dictionary = (economy.get("sold_dishes_stats", {}) as Dictionary).duplicate(true)
	sold_dishes["herb_tea"] = maxi(0, int(sold_dishes.get("herb_tea", 0))) + 1
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
	var herb_tea_card := _get_card(cards, 104)
	var wheat_card := _get_card(cards, 102)
	if String(herb_tea_card.get("progress_text", "")) != "1/2" or bool(herb_tea_card.get("can_claim", false)):
		push_error("Restaurant order did not update partial dish-sale progress correctly")
		_cleanup(daily_orders)
		return
	if String(wheat_card.get("progress_text", "")) != "1/2" or bool(wheat_card.get("can_claim", false)):
		push_error("Farm order did not update partial material-gain progress correctly")
		_cleanup(daily_orders)
		return
	meta_progress = ProfileStore.get_meta_progress_state()
	economy = (meta_progress.get("economy", {}) as Dictionary).duplicate(true)
	sold_dishes = (economy.get("sold_dishes_stats", {}) as Dictionary).duplicate(true)
	sold_dishes["herb_tea"] = maxi(0, int(sold_dishes.get("herb_tea", 0))) + 1
	economy["sold_dishes_stats"] = sold_dishes
	meta_progress["economy"] = economy
	inventory = (meta_progress.get("inventory", {}) as Dictionary).duplicate(true)
	materials = (inventory.get("materials", {}) as Dictionary).duplicate(true)
	materials["wheat"] = maxi(0, int(materials.get("wheat", 0))) + 1
	inventory["materials"] = materials
	meta_progress["inventory"] = inventory
	ProfileStore.set_meta_progress_state(meta_progress)
	daily_orders.call("_sync_progress")
	cards = _get_cards(daily_orders)
	herb_tea_card = _get_card(cards, 104)
	wheat_card = _get_card(cards, 102)
	if String(herb_tea_card.get("progress_text", "")) != "2/2" or not bool(herb_tea_card.get("can_claim", false)):
		push_error("Restaurant order did not reach a claimable completed state")
		_cleanup(daily_orders)
		return
	if String(wheat_card.get("progress_text", "")) != "2/2" or not bool(wheat_card.get("can_claim", false)):
		push_error("Farm order did not reach a claimable completed state")
		_cleanup(daily_orders)
		return
	print("Daily orders progress smoke PASS")
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
