extends Node


func _ready() -> void:
	var meta_scene: PackedScene = load("res://scenes/meta/MetaLoopRoot.tscn")
	if meta_scene == null:
		push_error("Failed to load MetaLoopRoot for restaurant world smoke")
		get_tree().quit(1)
		return
	var meta_root: Node = meta_scene.instantiate()
	get_tree().root.add_child.call_deferred(meta_root)
	await get_tree().process_frame
	await get_tree().process_frame
	meta_root.call("debug_press_play")
	await get_tree().process_frame
	if not bool(meta_root.call("debug_day_world_interact", "restaurant")):
		push_error("Day world restaurant entrance should open the restaurant interior")
		_cleanup(meta_root)
		return
	await get_tree().process_frame
	var snapshot: Dictionary = meta_root.call("debug_get_snapshot")
	if String(snapshot.get("current_screen", "")) != "restaurant":
		push_error("Restaurant interior did not become the active screen")
		_cleanup(meta_root)
		return
	if not bool(meta_root.call("debug_restaurant_interact", "menu")):
		push_error("Menu board should open from a world interaction zone")
		_cleanup(meta_root)
		return
	await get_tree().process_frame
	snapshot = meta_root.call("debug_get_snapshot")
	if String(snapshot.get("restaurant_world_popup", "")) != "menu":
		push_error("Menu board interaction did not open the planning popup")
		_cleanup(meta_root)
		return
	var recipe_id := _first_craftable_recipe(snapshot.get("restaurant_recipe_cards", []))
	if recipe_id.is_empty():
		push_error("Restaurant world smoke could not find a craftable unlocked recipe")
		_cleanup(meta_root)
		return
	if not bool(meta_root.call("debug_restaurant_toggle_recipe", recipe_id)):
		push_error("Planning popup should allow selecting a recipe")
		_cleanup(meta_root)
		return
	await get_tree().process_frame
	snapshot = meta_root.call("debug_get_snapshot")
	if not (snapshot.get("restaurant_menu_ids", []) as Array).has(recipe_id):
		push_error("Selected recipe did not persist through the restaurant world planning flow")
		_cleanup(meta_root)
		return
	if not bool(meta_root.call("debug_restaurant_interact", "prep")):
		push_error("Prep station should open from a world interaction zone")
		_cleanup(meta_root)
		return
	await get_tree().process_frame
	snapshot = meta_root.call("debug_get_snapshot")
	if String(snapshot.get("restaurant_world_popup", "")) != "prep":
		push_error("Prep station interaction did not open the prep popup")
		_cleanup(meta_root)
		return
	if not bool(meta_root.call("debug_restaurant_interact", "service")):
		push_error("Service counter should open from a world interaction zone")
		_cleanup(meta_root)
		return
	await get_tree().process_frame
	snapshot = meta_root.call("debug_get_snapshot")
	if String(snapshot.get("restaurant_world_popup", "")) != "service":
		push_error("Service counter interaction did not open the service popup")
		_cleanup(meta_root)
		return
	if not bool(snapshot.get("restaurant_service_button_enabled", false)):
		push_error("Service counter should expose the existing service action when a craftable menu is selected")
		_cleanup(meta_root)
		return
	var gold_before := int(snapshot.get("gold", 0))
	var inventory_before: Dictionary = (snapshot.get("inventory_materials", {}) as Dictionary).duplicate(true)
	if not bool(meta_root.call("debug_restaurant_request_service")):
		push_error("Service popup should trigger the restaurant simulation")
		_cleanup(meta_root)
		return
	await get_tree().process_frame
	snapshot = meta_root.call("debug_get_snapshot")
	if String(snapshot.get("current_screen", "")) != "restaurant":
		push_error("Restaurant service should resolve inside the restaurant interior")
		_cleanup(meta_root)
		return
	if int(snapshot.get("gold", 0)) <= gold_before:
		push_error("Restaurant service did not award gold through the world flow")
		_cleanup(meta_root)
		return
	if snapshot.get("inventory_materials", {}) == inventory_before:
		push_error("Restaurant service did not consume inventory through the world flow")
		_cleanup(meta_root)
		return
	if String(snapshot.get("restaurant_world_popup", "")) != "summary":
		push_error("Service completion should surface the result summary popup")
		_cleanup(meta_root)
		return
	if int(snapshot.get("restaurant_world_customer_count", 0)) <= 0:
		push_error("Restaurant interior should show customer presence after service")
		_cleanup(meta_root)
		return
	if not bool(snapshot.get("restaurant_world_lights_on", false)):
		push_error("Restaurant interior should show open ambience after service")
		_cleanup(meta_root)
		return
	if not bool(meta_root.call("debug_restaurant_interact", "door")):
		push_error("Exit door should return the player to the day hub")
		_cleanup(meta_root)
		return
	await get_tree().process_frame
	snapshot = meta_root.call("debug_get_snapshot")
	if String(snapshot.get("current_screen", "")) != "day_hub":
		push_error("Restaurant exit door did not return the player to the day hub")
		_cleanup(meta_root)
		return
	print("Restaurant World shell smoke PASS")
	_cleanup(meta_root, false)


func _first_craftable_recipe(cards_variant: Variant) -> String:
	if not (cards_variant is Array):
		return ""
	for card_variant in cards_variant:
		if not (card_variant is Dictionary):
			continue
		var card := card_variant as Dictionary
		if not bool(card.get("enabled", false)):
			continue
		if int(card.get("craftable_servings", 0)) <= 0:
			continue
		return String(card.get("id", ""))
	return ""


func _cleanup(meta_root: Node, failed: bool = true) -> void:
	if meta_root != null:
		meta_root.free()
	if failed:
		get_tree().quit(1)
		return
	get_tree().quit()
