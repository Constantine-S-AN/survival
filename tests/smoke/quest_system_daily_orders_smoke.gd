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
	for card_variant in cards:
		if not (card_variant is Dictionary):
			continue
		var card: Dictionary = card_variant
		pillars[String(card.get("pillar", ""))] = true
	if not pillars.has("farm") or not pillars.has("restaurant") or not pillars.has("night"):
		push_error("DailyOrders is missing one or more gameplay pillars in the board data")
		get_tree().quit(1)
		return
	print("QuestSystem daily orders smoke PASS")
	get_tree().quit()
