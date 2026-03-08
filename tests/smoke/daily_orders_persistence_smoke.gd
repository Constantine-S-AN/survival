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
	var session_id := "daily_orders_persistence_%d" % int(Time.get_ticks_usec() % 1000000)
	ProfileStore.begin_test_session(session_id, true)
	ProfileStore.load_profile("diver", "map_trench_lab")
	daily_orders.call("_reset_runtime_state")
	await get_tree().process_frame
	var cards := _get_cards(daily_orders)
	if cards.size() != 12:
		push_error("Expected 12 daily orders in the persistence smoke test")
		_cleanup(daily_orders)
		return
	if not bool(_get_card(cards, 101).get("featured", false)) or not bool(_get_card(cards, 102).get("featured", false)):
		push_error("Day 1 starter orders were not surfaced as featured leads")
		_cleanup(daily_orders)
		return
	var meta_progress: Dictionary = ProfileStore.get_meta_progress_state()
	var gold_before := int((meta_progress.get("economy", {}) as Dictionary).get("gold", 0))
	var reputation_before := int((meta_progress.get("economy", {}) as Dictionary).get("restaurant_reputation", 0))
	var inventory_before: Dictionary = (meta_progress.get("inventory", {}) as Dictionary).duplicate(true)
	var materials_before: Dictionary = (inventory_before.get("materials", {}) as Dictionary).duplicate(true)
	var wheat_before := int(materials_before.get("wheat", 0))
	var reef_salt_before := int(materials_before.get("reef_salt", 0))
	var unlocked_seeds_before: Array = (inventory_before.get("unlocked_seeds", []) as Array).duplicate()
	var economy: Dictionary = (meta_progress.get("economy", {}) as Dictionary).duplicate(true)
	var sold_dishes: Dictionary = (economy.get("sold_dishes_stats", {}) as Dictionary).duplicate(true)
	sold_dishes["field_stew"] = maxi(0, int(sold_dishes.get("field_stew", 0))) + 1
	economy["sold_dishes_stats"] = sold_dishes
	meta_progress["economy"] = economy
	var inventory: Dictionary = (meta_progress.get("inventory", {}) as Dictionary).duplicate(true)
	var materials: Dictionary = (inventory.get("materials", {}) as Dictionary).duplicate(true)
	materials["wheat"] = maxi(0, int(materials.get("wheat", 0))) + 2
	materials["reef_salt"] = maxi(0, int(materials.get("reef_salt", 0))) + 1
	inventory["materials"] = materials
	meta_progress["inventory"] = inventory
	ProfileStore.set_meta_progress_state(meta_progress)
	daily_orders.call("_sync_progress")
	cards = _get_cards(daily_orders)
	if not String(_get_card(cards, 101).get("reward_text", "")).contains("reputation"):
		push_error("Restaurant order reward text did not expose reputation reward details")
		_cleanup(daily_orders)
		return
	if not String(_get_card(cards, 102).get("reward_text", "")).contains("Wheat"):
		push_error("Farm order reward text did not expose material reward details")
		_cleanup(daily_orders)
		return
	if not String(_get_card(cards, 103).get("reward_text", "")).contains("Unlock"):
		push_error("Night order reward text did not expose seed unlock reward details")
		_cleanup(daily_orders)
		return
	if not bool(_get_card(cards, 101).get("can_claim", false)):
		push_error("Field Stew order did not become claimable after simulated sales")
		_cleanup(daily_orders)
		return
	if not bool(_get_card(cards, 102).get("can_claim", false)):
		push_error("Wheat order did not become claimable after simulated farm gain")
		_cleanup(daily_orders)
		return
	if not bool(_get_card(cards, 103).get("can_claim", false)):
		push_error("Reef Salt order did not become claimable after simulated night loot")
		_cleanup(daily_orders)
		return
	var total_reward := 0
	for order_id in [101, 102, 103]:
		var result: Dictionary = daily_orders.call("claim_order", order_id)
		if not bool(result.get("ok", false)):
			push_error("Failed to claim expected ready daily order %d" % order_id)
			_cleanup(daily_orders)
			return
		var reward: Dictionary = result.get("reward", {})
		total_reward += int(reward.get("gold", 0))
	var updated_meta_progress := ProfileStore.get_meta_progress_state()
	var updated_economy: Dictionary = updated_meta_progress.get("economy", {}) as Dictionary
	var updated_inventory: Dictionary = updated_meta_progress.get("inventory", {}) as Dictionary
	var updated_materials: Dictionary = updated_inventory.get("materials", {}) as Dictionary
	var updated_seeds: Array = (updated_inventory.get("unlocked_seeds", []) as Array).duplicate()
	var second_claim_result: Dictionary = daily_orders.call("claim_order", 101)
	if bool(second_claim_result.get("ok", false)):
		push_error("Claimed the same order twice")
		_cleanup(daily_orders)
		return
	var updated_gold := int(updated_economy.get("gold", 0))
	if updated_gold != gold_before + total_reward:
		push_error("Daily order rewards did not persist to the shared gold economy")
		_cleanup(daily_orders)
		return
	if int(updated_economy.get("restaurant_reputation", 0)) != reputation_before + 1:
		push_error("Daily order reputation rewards did not persist to the shared economy state")
		_cleanup(daily_orders)
		return
	if int(updated_materials.get("wheat", 0)) != wheat_before + 3:
		push_error("Daily order material rewards did not persist to the shared inventory state")
		_cleanup(daily_orders)
		return
	if int(updated_materials.get("reef_salt", 0)) != reef_salt_before + 1:
		push_error("Claim setup unexpectedly altered baseline night loot accounting")
		_cleanup(daily_orders)
		return
	if updated_seeds.find("kelpberry_seed") == -1 or unlocked_seeds_before.find("kelpberry_seed") != -1:
		push_error("Daily order seed unlock rewards did not persist to the shared inventory state")
		_cleanup(daily_orders)
		return
	daily_orders.call("_reset_runtime_state")
	ProfileStore.load_profile("diver", "map_trench_lab")
	await get_tree().process_frame
	cards = _get_cards(daily_orders)
	for order_id in [101, 102, 103]:
		var card := _get_card(cards, order_id)
		if not bool(card.get("completed", false)):
			push_error("Completed order %d did not persist across reload" % order_id)
			_cleanup(daily_orders)
			return
	var persisted_gold := int((ProfileStore.get_meta_progress_state().get("economy", {}) as Dictionary).get("gold", 0))
	if persisted_gold != gold_before + total_reward:
		push_error("Gold reward did not survive reload")
		_cleanup(daily_orders)
		return
	var persisted_economy: Dictionary = ProfileStore.get_meta_progress_state().get("economy", {}) as Dictionary
	var persisted_inventory: Dictionary = ProfileStore.get_meta_progress_state().get("inventory", {}) as Dictionary
	var persisted_materials: Dictionary = persisted_inventory.get("materials", {}) as Dictionary
	var persisted_seeds: Array = (persisted_inventory.get("unlocked_seeds", []) as Array).duplicate()
	if int(persisted_economy.get("restaurant_reputation", 0)) != reputation_before + 1:
		push_error("Reputation reward did not survive reload")
		_cleanup(daily_orders)
		return
	if int(persisted_materials.get("wheat", 0)) != wheat_before + 3:
		push_error("Material reward did not survive reload")
		_cleanup(daily_orders)
		return
	if persisted_seeds.find("kelpberry_seed") == -1:
		push_error("Seed unlock reward did not survive reload")
		_cleanup(daily_orders)
		return
	print("Daily orders persistence smoke PASS")
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
