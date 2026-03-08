extends Node


func _ready() -> void:
	var meta_scene: PackedScene = load("res://scenes/meta/MetaLoopRoot.tscn")
	if meta_scene == null:
		push_error("Failed to load MetaLoopRoot for DayWorld shell smoke")
		get_tree().quit(1)
		return
	var meta_root: Node = meta_scene.instantiate()
	get_tree().root.add_child.call_deferred(meta_root)
	await get_tree().process_frame
	await get_tree().process_frame
	meta_root.call("debug_press_play")
	await get_tree().process_frame
	var snapshot: Dictionary = meta_root.call("debug_get_snapshot")
	if String(snapshot.get("current_screen", "")) != "day_hub":
		push_error("Meta loop did not enter the day hub state")
		_cleanup(meta_root)
		return
	if String(snapshot.get("daytime_shell_mode", "")) != "world":
		push_error("Walkable day shell should be the default daytime presentation")
		_cleanup(meta_root)
		return
	if String(snapshot.get("day_world_phase_visual_id", "")) != "morning":
		push_error("Day world should start in the morning visual state")
		_cleanup(meta_root)
		return
	if bool(snapshot.get("day_world_dock_gate_open", false)):
		push_error("Night dock gate should start closed before evening")
		_cleanup(meta_root)
		return
	if String(snapshot.get("day_world_selected_hotbar_id", "")) != "hand":
		push_error("Day world should default to the hand interaction slot")
		_cleanup(meta_root)
		return
	var visible_pickups: Array = snapshot.get("day_world_visible_pickup_ids", [])
	if not visible_pickups.has("harbor_herb") or not visible_pickups.has("dock_scrap"):
		push_error("Day world should expose the starter world pickups")
		_cleanup(meta_root)
		return
	var town_npcs_before := int(snapshot.get("day_world_visible_town_npc_count", 0))
	if town_npcs_before < 1:
		push_error("Day world should show at least one ambient town NPC during daytime")
		_cleanup(meta_root)
		return
	var starting_inventory: Dictionary = snapshot.get("inventory_materials", {})
	var herb_before := int(starting_inventory.get("herb", 0))
	if not bool(meta_root.call("debug_day_world_interact", "pickup_harbor_herb")):
		push_error("Harbor herb pickup should be interactable from the day world")
		_cleanup(meta_root)
		return
	await get_tree().process_frame
	snapshot = meta_root.call("debug_get_snapshot")
	var inventory_after_pickup: Dictionary = snapshot.get("inventory_materials", {})
	if int(inventory_after_pickup.get("herb", 0)) != herb_before + 1:
		push_error("Picking up harbor herb should route into shared inventory")
		_cleanup(meta_root)
		return
	visible_pickups = snapshot.get("day_world_visible_pickup_ids", [])
	if visible_pickups.has("harbor_herb"):
		push_error("Collected world pickups should disappear until the next day")
		_cleanup(meta_root)
		return
	if bool(meta_root.call("debug_day_world_interact", "night")):
		push_error("Night dock should stay locked at the start of the daytime loop")
		_cleanup(meta_root)
		return
	if not bool(meta_root.call("debug_day_world_select_farm_tool", "till")):
		push_error("Day world should expose the till tool")
		_cleanup(meta_root)
		return
	if not bool(meta_root.call("debug_day_world_interact_farm_plot", 0)):
		push_error("Tilling plot 0 should work directly in the day world")
		_cleanup(meta_root)
		return
	await get_tree().process_frame
	snapshot = meta_root.call("debug_get_snapshot")
	if String(snapshot.get("current_screen", "")) != "day_hub":
		push_error("World farming should stay inside the day world shell")
		_cleanup(meta_root)
		return
	var plots: Array = snapshot.get("farm_plots", [])
	if plots.is_empty() or not bool((plots[0] as Dictionary).get("tilled", false)):
		push_error("Plot 0 should become tilled after direct world interaction")
		_cleanup(meta_root)
		return
	if not bool(meta_root.call("debug_day_world_select_farm_tool", "plant", "wheat_seed")):
		push_error("Day world should expose unlocked seed tools")
		_cleanup(meta_root)
		return
	if not bool(meta_root.call("debug_day_world_interact_farm_plot", 0)):
		push_error("Planting wheat on plot 0 should work in the day world")
		_cleanup(meta_root)
		return
	await get_tree().process_frame
	snapshot = meta_root.call("debug_get_snapshot")
	plots = snapshot.get("farm_plots", [])
	if plots.is_empty() or String((plots[0] as Dictionary).get("seed_id", "")) != "wheat_seed":
		push_error("Plot 0 should remember the planted wheat seed")
		_cleanup(meta_root)
		return
	if not bool(meta_root.call("debug_day_world_select_farm_tool", "water")):
		push_error("Day world should expose the watering can")
		_cleanup(meta_root)
		return
	if not bool(meta_root.call("debug_day_world_interact_farm_plot", 0)):
		push_error("Watering plot 0 should work in the day world")
		_cleanup(meta_root)
		return
	await get_tree().process_frame
	snapshot = meta_root.call("debug_get_snapshot")
	plots = snapshot.get("farm_plots", [])
	var current_day := int(snapshot.get("current_day", 1))
	if plots.is_empty() or int((plots[0] as Dictionary).get("watered_day", 0)) != current_day:
		push_error("Plot 0 should record watering on the current day")
		_cleanup(meta_root)
		return
	if String(snapshot.get("day_world_phase_visual_id", "")) != "evening":
		push_error("Day world should shift into the evening visual state after enough daytime actions")
		_cleanup(meta_root)
		return
	if not bool(snapshot.get("day_world_night_ready", false)):
		push_error("Night readiness should become visible once evening is reached")
		_cleanup(meta_root)
		return
	if not bool(snapshot.get("day_world_dock_gate_open", false)):
		push_error("Night dock gate should visibly open once evening is reached")
		_cleanup(meta_root)
		return
	if int(snapshot.get("day_world_visible_town_npc_count", 0)) >= town_npcs_before:
		push_error("Ambient town NPC presence should wind down as evening begins")
		_cleanup(meta_root)
		return
	if not bool(meta_root.call("debug_day_world_interact", "restaurant")):
		push_error("Day world restaurant entrance should route into the restaurant view")
		_cleanup(meta_root)
		return
	await get_tree().process_frame
	snapshot = meta_root.call("debug_get_snapshot")
	if String(snapshot.get("current_screen", "")) != "restaurant":
		push_error("Restaurant entrance did not open the restaurant screen")
		_cleanup(meta_root)
		return
	meta_root.call("debug_return_to_hub")
	await get_tree().process_frame
	snapshot = meta_root.call("debug_get_snapshot")
	plots = snapshot.get("farm_plots", [])
	if plots.is_empty():
		push_error("Farm plots disappeared after leaving and returning to the day world")
		_cleanup(meta_root)
		return
	visible_pickups = snapshot.get("day_world_visible_pickup_ids", [])
	if visible_pickups.has("harbor_herb"):
		push_error("Collected pickups should stay gone across daytime scene changes")
		_cleanup(meta_root)
		return
	var plot0 := plots[0] as Dictionary
	if String(plot0.get("seed_id", "")) != "wheat_seed" or int(plot0.get("watered_day", 0)) != current_day:
		push_error("Farm state should persist across daytime scene changes")
		_cleanup(meta_root)
		return
	if not bool(meta_root.call("debug_day_world_interact", "shop")):
		push_error("Day world shop entrance should route into the shop view")
		_cleanup(meta_root)
		return
	await get_tree().process_frame
	snapshot = meta_root.call("debug_get_snapshot")
	if String(snapshot.get("current_screen", "")) != "shop":
		push_error("Shop entrance did not open the shop screen")
		_cleanup(meta_root)
		return
	meta_root.call("debug_return_to_hub")
	await get_tree().process_frame
	meta_root.call("debug_use_legacy_day_hub")
	await get_tree().process_frame
	snapshot = meta_root.call("debug_get_snapshot")
	if String(snapshot.get("daytime_shell_mode", "")) != "legacy":
		push_error("Legacy day hub fallback did not activate")
		_cleanup(meta_root)
		return
	meta_root.call("debug_use_day_world")
	await get_tree().process_frame
	snapshot = meta_root.call("debug_get_snapshot")
	if String(snapshot.get("daytime_shell_mode", "")) != "world":
		push_error("Walkable day shell did not restore after fallback")
		_cleanup(meta_root)
		return
	if bool(snapshot.get("night_button_disabled", false)):
		if not bool(meta_root.call("debug_day_world_interact", "wait")):
			push_error("Watch bench should route through the wait-until-evening flow")
			_cleanup(meta_root)
			return
		await get_tree().process_frame
	if not bool(meta_root.call("debug_day_world_interact", "night")):
		push_error("Night dock should open a departure confirmation after evening is reached")
		_cleanup(meta_root)
		return
	await get_tree().process_frame
	snapshot = meta_root.call("debug_get_snapshot")
	if not bool(snapshot.get("day_world_night_popup_open", false)):
		push_error("Night dock interaction did not open the world departure confirmation")
		_cleanup(meta_root)
		return
	if not bool(meta_root.call("debug_day_world_confirm_night_departure")):
		push_error("World departure confirmation should launch the night run")
		_cleanup(meta_root)
		return
	await get_tree().create_timer(0.7).timeout
	snapshot = meta_root.call("debug_get_snapshot")
	if String(snapshot.get("current_screen", "")) != "night":
		push_error("Night dock did not launch the embedded night combat screen")
		_cleanup(meta_root)
		return
	meta_root.call("debug_complete_active_night", {
		"exit_reason": "completed",
		"time_survived_sec": 84.0,
		"kills": 14
	})
	await get_tree().process_frame
	snapshot = meta_root.call("debug_get_snapshot")
	if String(snapshot.get("current_screen", "")) != "return_summary":
		push_error("Night completion should enter the return summary state")
		_cleanup(meta_root)
		return
	if not bool(snapshot.get("day_world_overlay_blocked", false)):
		push_error("Day world should stay visible but blocked behind the return overlay")
		_cleanup(meta_root)
		return
	if String(snapshot.get("day_world_phase_visual_id", "")) != "night":
		push_error("Day world should shift to the night visual state on return")
		_cleanup(meta_root)
		return
	var dock_position: Vector2 = snapshot.get("day_world_player_position", Vector2.ZERO)
	if dock_position.distance_to(Vector2(1218.0, 818.0)) > 80.0:
		push_error("Player should return near the dock after night combat")
		_cleanup(meta_root)
		return
	meta_root.call("debug_continue_summary")
	await get_tree().process_frame
	snapshot = meta_root.call("debug_get_snapshot")
	if String(snapshot.get("current_screen", "")) != "day_hub":
		push_error("Continuing the return overlay should advance into the next day world")
		_cleanup(meta_root)
		return
	visible_pickups = snapshot.get("day_world_visible_pickup_ids", [])
	if not visible_pickups.has("harbor_herb"):
		push_error("Day world pickups should refresh when the next day begins")
		_cleanup(meta_root)
		return
	print("Day World shell smoke PASS")
	_cleanup(meta_root, false)


func _cleanup(meta_root: Node, failed: bool = true) -> void:
	if meta_root != null:
		meta_root.free()
	if failed:
		get_tree().quit(1)
		return
	get_tree().quit()
