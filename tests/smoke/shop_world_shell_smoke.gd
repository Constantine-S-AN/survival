extends Node


func _ready() -> void:
	var meta_scene: PackedScene = load("res://scenes/meta/MetaLoopRoot.tscn")
	if meta_scene == null:
		push_error("Failed to load MetaLoopRoot for shop world smoke")
		get_tree().quit(1)
		return
	var meta_root: Node = meta_scene.instantiate()
	get_tree().root.add_child.call_deferred(meta_root)
	await get_tree().process_frame
	await get_tree().process_frame
	meta_root.call("debug_press_play")
	await get_tree().process_frame
	if not bool(meta_root.call("debug_day_world_interact", "shop")):
		push_error("Day world shop entrance should open the shop interior")
		_cleanup(meta_root)
		return
	await get_tree().process_frame
	var snapshot: Dictionary = meta_root.call("debug_get_snapshot")
	if String(snapshot.get("current_screen", "")) != "shop":
		push_error("Shop interior did not become the active screen")
		_cleanup(meta_root)
		return
	if not bool(meta_root.call("debug_shop_interact", "shopkeeper")):
		push_error("Shopkeeper counter should open from a world interaction zone")
		_cleanup(meta_root)
		return
	await get_tree().process_frame
	snapshot = meta_root.call("debug_get_snapshot")
	if String(snapshot.get("shop_world_popup", "")) != "merchant":
		push_error("Shopkeeper interaction did not open the merchant popup")
		_cleanup(meta_root)
		return
	if String(snapshot.get("shopkeeper_line", "")).strip_edges().is_empty():
		push_error("Shopkeeper should surface a short world-facing line")
		_cleanup(meta_root)
		return
	var sell_offer_id := _first_enabled_offer(snapshot.get("shop_sell_offers", []))
	if sell_offer_id.is_empty():
		push_error("Shop world smoke could not find a sellable inventory item")
		_cleanup(meta_root)
		return
	var gold_before_sale := int(snapshot.get("gold", 0))
	if not bool(meta_root.call("debug_shop_popup_sell_material", sell_offer_id)):
		push_error("Merchant popup should allow selling inventory through the shared shop flow")
		_cleanup(meta_root)
		return
	await get_tree().process_frame
	snapshot = meta_root.call("debug_get_snapshot")
	if int(snapshot.get("gold", 0)) <= gold_before_sale:
		push_error("Selling through the merchant popup did not increase shared gold")
		_cleanup(meta_root)
		return
	var seed_offer_id := _first_enabled_offer(snapshot.get("shop_seed_offers", []))
	if seed_offer_id.is_empty():
		push_error("Shop world smoke could not find a purchasable seed offer")
		_cleanup(meta_root)
		return
	if not bool(meta_root.call("debug_shop_popup_buy_seed", seed_offer_id)):
		push_error("Merchant popup should allow buying seeds through the shared shop flow")
		_cleanup(meta_root)
		return
	await get_tree().process_frame
	snapshot = meta_root.call("debug_get_snapshot")
	if not (snapshot.get("unlocked_seed_ids", []) as Array).has(seed_offer_id):
		push_error("Buying from the merchant popup did not unlock the seed in shared inventory state")
		_cleanup(meta_root)
		return
	if not bool(meta_root.call("debug_shop_interact", "regular")):
		push_error("Town regular should open from a world interaction zone")
		_cleanup(meta_root)
		return
	await get_tree().process_frame
	snapshot = meta_root.call("debug_get_snapshot")
	if String(snapshot.get("shop_world_popup", "")) != "customer":
		push_error("Town regular interaction did not open the customer popup")
		_cleanup(meta_root)
		return
	if String(snapshot.get("shop_request_title", "")).strip_edges().is_empty():
		push_error("Town regular should surface at least one lightweight request from daily orders")
		_cleanup(meta_root)
		return
	if String(snapshot.get("shop_customer_line", "")).strip_edges().is_empty():
		push_error("Town regular should have a short world-facing line")
		_cleanup(meta_root)
		return
	if not bool(meta_root.call("debug_shop_interact", "door")):
		push_error("Shop exit door should return the player to the day hub")
		_cleanup(meta_root)
		return
	await get_tree().process_frame
	snapshot = meta_root.call("debug_get_snapshot")
	if String(snapshot.get("current_screen", "")) != "day_hub":
		push_error("Shop exit door did not return the player to the day hub")
		_cleanup(meta_root)
		return
	print("Shop World shell smoke PASS")
	_cleanup(meta_root, false)


func _first_enabled_offer(items_variant: Variant) -> String:
	if not (items_variant is Array):
		return ""
	for item_variant in items_variant:
		if not (item_variant is Dictionary):
			continue
		var item := item_variant as Dictionary
		if not bool(item.get("enabled", false)):
			continue
		return String(item.get("id", ""))
	return ""


func _cleanup(meta_root: Node, failed: bool = true) -> void:
	if meta_root != null:
		meta_root.free()
	if failed:
		get_tree().quit(1)
		return
	get_tree().quit()
