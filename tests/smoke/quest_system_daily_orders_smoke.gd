extends Node


func _ready() -> void:
	var quest_system: Node = get_node_or_null("/root/QuestSystem")
	if quest_system == null:
		push_error("QuestSystem autoload missing")
		get_tree().quit(1)
		return
	var daily_orders: Node = get_node_or_null("/root/DailyOrders")
	if daily_orders == null:
		push_error("DailyOrders autoload missing")
		get_tree().quit(1)
		return
	await get_tree().process_frame
	await get_tree().process_frame
	if not daily_orders.has_method("get_order_cards"):
		push_error("DailyOrders runtime API missing get_order_cards")
		get_tree().quit(1)
		return
	var cards_variant: Variant = daily_orders.call("get_order_cards")
	if not (cards_variant is Array):
		push_error("DailyOrders did not expose an order list")
		get_tree().quit(1)
		return
	var cards: Array = cards_variant as Array
	if cards.size() < 9:
		push_error("DailyOrders did not expose the expanded order catalog")
		get_tree().quit(1)
		return
	var pillars := {}
	var has_reputation_reward := false
	var has_material_reward := false
	var has_seed_reward := false
	for card_variant in cards:
		if not (card_variant is Dictionary):
			continue
		var card: Dictionary = card_variant
		pillars[String(card.get("pillar", ""))] = true
		var reward_text := String(card.get("reward_text", "")).to_lower()
		has_reputation_reward = has_reputation_reward or reward_text.contains("reputation")
		has_material_reward = has_material_reward or reward_text.contains("wheat") or reward_text.contains("herb")
		has_seed_reward = has_seed_reward or reward_text.contains("unlock")
	if not pillars.has("farm") or not pillars.has("restaurant") or not pillars.has("night"):
		push_error("DailyOrders is missing one or more gameplay pillars in the board data")
		get_tree().quit(1)
		return
	if not has_reputation_reward or not has_material_reward or not has_seed_reward:
		push_error("DailyOrders board data did not expose the expanded reward types")
		get_tree().quit(1)
		return
	print("QuestSystem daily orders smoke PASS")
	get_tree().quit()
