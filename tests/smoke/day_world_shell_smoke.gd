extends Node

const META_LOOP_SCENE := preload("res://scenes/meta/MetaLoopRoot.tscn")
const NIGHT_DOCK_POSITION := Vector2(1218.0, 818.0)

var _meta_root: Node = null


func _ready() -> void:
	if ProfileStore == null:
		push_error("ProfileStore autoload missing for DayWorld shell smoke")
		_cleanup(true)
		return
	var session_id := "day_world_shell_%d" % int(Time.get_ticks_usec() % 1000000)
	ProfileStore.begin_test_session(session_id, true)
	ProfileStore.load_profile("diver", "map_trench_lab")
	_reset_daily_orders_runtime()
	await get_tree().process_frame

	_meta_root = await _spawn_meta_root()
	if _meta_root == null:
		push_error("Failed to load MetaLoopRoot for DayWorld shell smoke")
		_cleanup(true)
		return

	var snapshot := _snapshot()
	if not _require(String(snapshot.get("current_screen", "")) == "day_hub", "Meta loop did not enter the day hub state"):
		return
	if not _require(String(snapshot.get("daytime_shell_mode", "")) == "world", "Walkable day shell should be the default daytime presentation"):
		return
	if not _require(String(snapshot.get("day_world_phase_visual_id", "")) == "morning", "Day world should start in the morning visual state"):
		return
	if not _require(not bool(snapshot.get("day_world_dock_gate_open", false)), "Night dock gate should start closed before evening"):
		return
	if not _require(String(snapshot.get("day_world_selected_hotbar_id", "")) == "hand", "Day world should default to the hand interaction slot"):
		return
	var visible_pickups: Array = snapshot.get("day_world_visible_pickup_ids", [])
	if not _require(visible_pickups.has("harbor_herb") and visible_pickups.has("dock_scrap"), "Day world should expose the starter world pickups"):
		return

	if not _require(bool(_meta_root.call("debug_day_world_interact", "orders")), "Orders board should open from the day world notice board"):
		return
	await _await_frames(1)
	snapshot = _snapshot()
	if not _require(bool(snapshot.get("day_world_orders_open", false)), "Day world should expose the daily orders board in-world"):
		return
	if not _require(bool(_meta_root.call("debug_day_world_interact", "orders")), "Orders board should close from the same day world interaction zone"):
		return
	await _await_frames(1)
	snapshot = _snapshot()
	if not _require(not bool(snapshot.get("day_world_orders_open", false)), "Orders board should close cleanly inside the day world shell"):
		return

	var starting_inventory: Dictionary = snapshot.get("inventory_materials", {})
	var herb_before := int(starting_inventory.get("herb", 0))
	if not _require(bool(_meta_root.call("debug_day_world_interact", "pickup_harbor_herb")), "Harbor herb pickup should be interactable from the day world"):
		return
	await _await_frames(1)
	snapshot = _snapshot()
	var inventory_after_pickup: Dictionary = snapshot.get("inventory_materials", {})
	if not _require(int(inventory_after_pickup.get("herb", 0)) == herb_before + 1, "Picking up harbor herb should route into shared inventory"):
		return
	visible_pickups = snapshot.get("day_world_visible_pickup_ids", [])
	if not _require(not visible_pickups.has("harbor_herb"), "Collected world pickups should disappear until the next day"):
		return

	if not _require(bool(_meta_root.call("debug_day_world_snap_player_to_zone", "farm_plot_0")), "Day world smoke should be able to place the player on plot 0 for overlap-sensitive farm checks"):
		return
	await _await_physics_frames(2)
	snapshot = _snapshot()
	if not _require(String(snapshot.get("day_world_focus_id", "")) == "farm_plot_0", "Player focus should lock onto plot 0 before overlap-sensitive farm interactions"):
		return

	if not _require(bool(_meta_root.call("debug_day_world_select_farm_tool", "till")), "Day world should expose the till tool"):
		return
	await _await_frames(1)
	snapshot = _snapshot()
	if not _require(String(snapshot.get("day_world_selected_hotbar_id", "")) == "till", "Selecting the till tool should update the world hotbar state"):
		return
	if not _require(bool(_meta_root.call("debug_day_world_interact_farm_plot", 0)), "Tilling plot 0 should work directly in the day world"):
		return
	await _await_frames(1)
	snapshot = _snapshot()
	var plots: Array = snapshot.get("farm_plots", [])
	if not _require(not plots.is_empty() and bool((plots[0] as Dictionary).get("tilled", false)), "Plot 0 should become tilled after direct world interaction"):
		return

	if not _require(bool(_meta_root.call("debug_day_world_select_farm_tool", "plant", "wheat_seed")), "Day world should expose unlocked seed tools"):
		return
	await _await_frames(1)
	snapshot = _snapshot()
	if not _require(String(snapshot.get("day_world_selected_hotbar_id", "")) == "plant", "Selecting a seed tool should keep the plant action in the hotbar state"):
		return
	if not _require(String(snapshot.get("day_world_selected_farm_tool_seed_id", "")) == "wheat_seed", "Selecting a seed tool should track the chosen seed id"):
		return
	if not _require(bool(_meta_root.call("debug_day_world_interact_farm_plot", 0)), "Planting wheat on plot 0 should work in the day world"):
		return
	await _await_frames(1)
	snapshot = _snapshot()
	plots = snapshot.get("farm_plots", [])
	if not _require(not plots.is_empty() and String((plots[0] as Dictionary).get("seed_id", "")) == "wheat_seed", "Plot 0 should remember the planted wheat seed"):
		return

	if not _require(bool(_meta_root.call("debug_day_world_select_farm_tool", "water")), "Day world should expose the watering can"):
		return
	await _await_frames(1)
	snapshot = _snapshot()
	if not _require(String(snapshot.get("day_world_selected_hotbar_id", "")) == "water", "Selecting the watering can should update the hotbar state"):
		return
	if not _require(bool(_meta_root.call("debug_day_world_interact_farm_plot", 0)), "Watering plot 0 should work in the day world"):
		return
	await _await_frames(1)
	snapshot = _snapshot()
	plots = snapshot.get("farm_plots", [])
	var current_day := int(snapshot.get("current_day", 1))
	if not _require(not plots.is_empty() and int((plots[0] as Dictionary).get("watered_day", 0)) == current_day, "Plot 0 should record watering on the current day"):
		return
	if not _require(String(snapshot.get("day_world_phase_visual_id", "")) == "evening", "Day world should shift into the evening visual state after enough daytime actions"):
		return
	if not _require(bool(snapshot.get("day_world_night_ready", false)), "Night readiness should become visible once evening is reached"):
		return
	if not _require(bool(snapshot.get("day_world_dock_gate_open", false)), "Night dock gate should visibly open once evening is reached"):
		return

	if not _require(bool(_meta_root.call("debug_day_world_interact", "restaurant")), "Day world restaurant entrance should route into the restaurant view"):
		return
	await _await_frames(1)
	snapshot = _snapshot()
	if not _require(String(snapshot.get("current_screen", "")) == "restaurant", "Restaurant entrance did not open the restaurant interior"):
		return
	if not _require(bool(_meta_root.call("debug_restaurant_interact", "menu")), "Restaurant menu board should open from a world interaction zone"):
		return
	await _await_frames(1)
	snapshot = _snapshot()
	if not _require(String(snapshot.get("restaurant_world_popup", "")) == "menu", "Restaurant menu board interaction did not open the planning popup"):
		return
	if not _require(bool(_meta_root.call("debug_restaurant_toggle_recipe", "field_stew")), "Restaurant planning should allow selecting the starter stew recipe"):
		return
	await _await_frames(1)
	snapshot = _snapshot()
	if not _require((snapshot.get("restaurant_menu_ids", []) as Array).has("field_stew"), "Restaurant menu selection should persist through the world planning flow"):
		return
	if not _require(bool(_meta_root.call("debug_restaurant_interact", "prep")), "Prep station should open from a world interaction zone"):
		return
	await _await_frames(1)
	snapshot = _snapshot()
	if not _require(String(snapshot.get("restaurant_world_popup", "")) == "prep", "Prep station interaction did not open the prep popup"):
		return
	if not _require(bool(_meta_root.call("debug_restaurant_interact", "door")), "Restaurant exit door should return the player to the day hub"):
		return
	await _await_frames(1)
	snapshot = _snapshot()
	if not _require(String(snapshot.get("current_screen", "")) == "day_hub", "Restaurant exit door did not return the player to the day hub"):
		return

	if not _require(bool(_meta_root.call("debug_day_world_interact", "shop")), "Day world shop entrance should route into the shop view"):
		return
	await _await_frames(1)
	snapshot = _snapshot()
	if not _require(String(snapshot.get("current_screen", "")) == "shop", "Shop entrance did not open the shop interior"):
		return
	if not _require(bool(_meta_root.call("debug_shop_interact", "shopkeeper")), "Shopkeeper counter should open from a world interaction zone"):
		return
	await _await_frames(1)
	snapshot = _snapshot()
	if not _require(String(snapshot.get("shop_world_popup", "")) == "merchant", "Shopkeeper interaction did not open the merchant popup"):
		return
	if not _require(not String(snapshot.get("shopkeeper_line", "")).strip_edges().is_empty(), "Shopkeeper should surface a short world-facing line"):
		return
	if not _require(bool(_meta_root.call("debug_shop_interact", "regular")), "Town regular should open from a world interaction zone"):
		return
	await _await_frames(1)
	snapshot = _snapshot()
	if not _require(String(snapshot.get("shop_world_popup", "")) == "customer", "Town regular interaction did not open the customer popup"):
		return
	if not _require(not String(snapshot.get("shop_request_title", "")).strip_edges().is_empty(), "Town regular should surface at least one lightweight request from daily orders"):
		return
	if not _require(bool(_meta_root.call("debug_shop_interact", "door")), "Shop exit door should return the player to the day hub"):
		return
	await _await_frames(1)
	snapshot = _snapshot()
	if not _require(String(snapshot.get("current_screen", "")) == "day_hub", "Shop exit door did not return the player to the day hub"):
		return

	_meta_root = await _reload_meta_root()
	if _meta_root == null:
		return
	snapshot = _snapshot()
	plots = snapshot.get("farm_plots", [])
	if not _require(int(snapshot.get("current_day", 0)) == 1, "Day 1 save/load should preserve the current day before night departure"):
		return
	if not _require(String(snapshot.get("phase", "")) == "evening", "Day 1 save/load should preserve the evening phase"):
		return
	if not _require(not (snapshot.get("day_world_visible_pickup_ids", []) as Array).has("harbor_herb"), "Collected pickups should stay gone across day-world reloads"):
		return
	if not _require(not plots.is_empty() and String((plots[0] as Dictionary).get("seed_id", "")) == "wheat_seed", "Day 1 save/load should preserve the planted wheat plot"):
		return
	if not _require((snapshot.get("restaurant_menu_ids", []) as Array).has("field_stew"), "Day 1 save/load should preserve restaurant planning done through the world interior"):
		return

	if not _require(bool(_meta_root.call("debug_day_world_interact", "night")), "Night dock should open a departure confirmation after evening is reached"):
		return
	await _await_frames(1)
	snapshot = _snapshot()
	if not _require(bool(snapshot.get("day_world_night_popup_open", false)), "Night dock interaction did not open the world departure confirmation"):
		return
	if not _require(bool(_meta_root.call("debug_day_world_confirm_night_departure")), "World departure confirmation should launch the night run"):
		return
	await get_tree().create_timer(0.8).timeout
	snapshot = _snapshot()
	if not _require(String(snapshot.get("current_screen", "")) == "night", "Night dock did not launch the embedded night combat screen"):
		return

	_meta_root.call("debug_complete_active_night", {
		"exit_reason": "abandoned",
		"time_survived_sec": 84.0,
		"kills": 14,
		"seed": 424242
	})
	await _await_frames(2)
	snapshot = _snapshot()
	if not _require(String(snapshot.get("current_screen", "")) == "return_summary", "Night completion should enter the return summary state"):
		return
	if not _require(bool(snapshot.get("day_world_overlay_blocked", false)), "Day world should stay visible but blocked behind the return overlay"):
		return
	if not _require(String(snapshot.get("day_world_phase_visual_id", "")) == "night", "Day world should shift to the night visual state on return"):
		return
	var dock_position: Vector2 = snapshot.get("day_world_player_position", Vector2.ZERO)
	if not _require(dock_position.distance_to(NIGHT_DOCK_POSITION) <= 80.0, "Player should return near the dock after night combat"):
		return

	_meta_root = await _reload_meta_root()
	if _meta_root == null:
		return
	snapshot = _snapshot()
	if not _require(String(snapshot.get("current_screen", "")) == "return_summary", "Save/load should restore the pending return summary after night combat"):
		return
	if not _require(bool(snapshot.get("pending_summary", false)), "Save/load should preserve the pending return summary flag"):
		return
	if not _require(bool(snapshot.get("day_world_overlay_blocked", false)), "Save/load should preserve the blocked day-world overlay behind the summary"):
		return
	if not _require(int((snapshot.get("inventory_materials", {}) as Dictionary).get("moon_spore", 0)) == 1, "Night rewards should already persist into shared inventory before the next day starts"):
		return

	_meta_root.call("debug_continue_summary")
	await _await_frames(1)
	snapshot = _snapshot()
	if not _require(String(snapshot.get("current_screen", "")) == "day_hub", "Continuing the return overlay should advance into the next day world"):
		return
	if not _require(int(snapshot.get("current_day", 0)) == 2, "Continuing the first return overlay should advance to day 2"):
		return
	if not _require(String(snapshot.get("day_world_phase_visual_id", "")) == "morning", "The next day should restore the morning day-world presentation"):
		return
	visible_pickups = snapshot.get("day_world_visible_pickup_ids", [])
	if not _require(visible_pickups.has("harbor_herb") and visible_pickups.has("dock_scrap"), "Day world pickups should refresh when the next day begins"):
		return

	var scrap_before := int((snapshot.get("inventory_materials", {}) as Dictionary).get("scrap", 0))
	if not _require(bool(_meta_root.call("debug_day_world_interact", "pickup_dock_scrap")), "Dock scrap pickup should refresh on the next day"):
		return
	await _await_frames(1)
	snapshot = _snapshot()
	if not _require(int((snapshot.get("inventory_materials", {}) as Dictionary).get("scrap", 0)) == scrap_before + 1, "Dock scrap pickup should route into shared inventory"):
		return
	if not _require(not (snapshot.get("day_world_visible_pickup_ids", []) as Array).has("dock_scrap"), "Collected dock scrap should disappear until the next day"):
		return

	if not _require(bool(_meta_root.call("debug_day_world_select_farm_tool", "water")), "Watering can should still be available on day 2"):
		return
	if not _require(bool(_meta_root.call("debug_day_world_interact_farm_plot", 0)), "Watering the carry-over crop should work on day 2 through the day world"):
		return
	await _await_frames(1)
	snapshot = _snapshot()
	plots = snapshot.get("farm_plots", [])
	if not _require(not plots.is_empty() and int((plots[0] as Dictionary).get("watered_day", 0)) == 2, "Day 2 farm watering should persist on the world plot"):
		return

	if not _require(bool(_meta_root.call("debug_day_world_interact", "restaurant")), "Day 2 restaurant flow should still route through the world entrance"):
		return
	await _await_frames(1)
	snapshot = _snapshot()
	if not _require(String(snapshot.get("current_screen", "")) == "restaurant", "Day 2 restaurant entrance did not open the restaurant interior"):
		return
	if not _require(bool(_meta_root.call("debug_restaurant_interact", "service")), "Restaurant service counter should open from a world interaction zone"):
		return
	await _await_frames(1)
	snapshot = _snapshot()
	if not _require(String(snapshot.get("restaurant_world_popup", "")) == "service", "Restaurant service counter interaction did not open the service popup"):
		return
	if not _require(bool(snapshot.get("restaurant_service_button_enabled", false)), "Restaurant service should be available after day 2 watering and menu planning"):
		return
	var gold_before_service := int(snapshot.get("gold", 0))
	var materials_before_service: Dictionary = (snapshot.get("inventory_materials", {}) as Dictionary).duplicate(true)
	if not _require(bool(_meta_root.call("debug_restaurant_request_service")), "Restaurant service popup should trigger the shared daytime service flow"):
		return
	await _await_frames(1)
	snapshot = _snapshot()
	if not _require(String(snapshot.get("restaurant_world_popup", "")) == "summary", "Restaurant service should surface the result summary popup inside the world interior"):
		return
	if not _require(int(snapshot.get("gold", 0)) > gold_before_service, "Restaurant service should award gold through the worldified interior flow"):
		return
	if not _require(snapshot.get("inventory_materials", {}) != materials_before_service, "Restaurant service should consume inventory through the worldified interior flow"):
		return
	if not _require(int(snapshot.get("restaurant_last_service_day", 0)) == 2, "Restaurant service should persist the served day through the world interior flow"):
		return
	_sync_daily_orders_progress()
	var lunch_rush_card := _find_order_card_by_title("Lunch Rush")
	if not _require(bool(lunch_rush_card.get("can_claim", false)), "Daily orders should observe the world restaurant service and surface Lunch Rush as ready to claim"):
		return
	if not _require(bool(_meta_root.call("debug_restaurant_interact", "door")), "Restaurant exit door should still work after service resolves"):
		return
	await _await_frames(1)
	snapshot = _snapshot()
	if not _require(String(snapshot.get("current_screen", "")) == "day_hub", "Restaurant exit door should return the player to the day hub after service"):
		return

	if bool(snapshot.get("night_button_disabled", false)):
		if not _require(bool(_meta_root.call("debug_day_world_interact", "wait")), "Watch bench should route through the wait-until-evening flow when the dock is still locked"):
			return
		await _await_frames(1)
		snapshot = _snapshot()
	if not _require(bool(snapshot.get("day_world_night_ready", false)), "Day 2 should still reach the world night-ready state before departure"):
		return
	_meta_root = await _reload_meta_root()
	if _meta_root == null:
		return
	snapshot = _snapshot()
	plots = snapshot.get("farm_plots", [])
	if not _require(int(snapshot.get("current_day", 0)) == 2, "Mid-loop save/load should preserve day 2 world state before the second departure"):
		return
	if not _require(int(snapshot.get("restaurant_last_service_day", 0)) == 2, "Mid-loop save/load should preserve the last world restaurant service day"):
		return
	if not _require(not String(snapshot.get("restaurant_result_title", "")).is_empty(), "Mid-loop save/load should preserve the restaurant world summary result"):
		return
	if not _require(not (snapshot.get("day_world_visible_pickup_ids", []) as Array).has("dock_scrap"), "Mid-loop save/load should preserve collected world pickup state on day 2"):
		return
	if not _require(not plots.is_empty() and int((plots[0] as Dictionary).get("watered_day", 0)) == 2, "Mid-loop save/load should preserve same-day watering on the world crop"):
		return
	_sync_daily_orders_progress()
	lunch_rush_card = _find_order_card_by_title("Lunch Rush")
	if not _require(bool(lunch_rush_card.get("can_claim", false)), "Mid-loop save/load should preserve ready daily orders earned through world interactions"):
		return
	if not _require(bool(_meta_root.call("debug_day_world_interact", "night")), "Second night dock interaction should still open from the day world after reload"):
		return
	await _await_frames(1)
	if not _require(bool(_meta_root.call("debug_day_world_confirm_night_departure")), "Second night departure confirmation should still launch from the world dock after reload"):
		return
	await get_tree().create_timer(0.8).timeout
	_meta_root.call("debug_complete_active_night", {
		"exit_reason": "completed",
		"time_survived_sec": 92.0,
		"kills": 18,
		"seed": 424243
	})
	await _await_frames(2)
	snapshot = _snapshot()
	var second_return_payload: Dictionary = snapshot.get("return_summary_payload", {})
	var second_unlock_names: Array = second_return_payload.get("unlock_names", [])
	var second_unlocked_recipe_ids: Array = snapshot.get("unlocked_recipe_ids", [])
	if not _require(second_unlock_names.has("Mooncap Mycelium"), "Second night should unlock the mooncap seed path"):
		return
	if not _require(second_unlock_names.has("Mooncap Hotpot"), "Second night should unlock the mooncap hotpot recipe"):
		return
	if not _require(
		second_unlock_names.has("Abyssfin Crudo") or second_unlocked_recipe_ids.has("abyssfin_crudo"),
		"Second night return should leave the premium abyssfin crudo recipe unlocked"
	):
		return

	_meta_root.call("debug_continue_summary")
	await _await_frames(1)
	snapshot = _snapshot()
	if not _require(int(snapshot.get("current_day", 0)) == 3, "Second return summary should advance into day 3"):
		return
	if not _require(String(snapshot.get("day_world_phase_visual_id", "")) == "morning", "Day 3 should restart the day-world phase presentation in the morning"):
		return
	if not _require((snapshot.get("unlocked_seed_ids", []) as Array).has("mooncap_seed"), "Mooncap seed unlock should persist into the daytime world state"):
		return
	if not _require((snapshot.get("unlocked_recipe_ids", []) as Array).has("mooncap_hotpot"), "Mooncap hotpot unlock should persist into the daytime restaurant state"):
		return
	if not _require((snapshot.get("unlocked_recipe_ids", []) as Array).has("abyssfin_crudo"), "Abyssfin crudo unlock should persist into the daytime restaurant state"):
		return

	if not _require(bool(_meta_root.call("debug_day_world_select_farm_tool", "hand")), "The hand slot should stay selectable for harvest interactions"):
		return
	await _await_frames(1)
	snapshot = _snapshot()
	if not _require(String(snapshot.get("day_world_selected_hotbar_id", "")) == "hand", "Harvest flow should be able to route back through the hand hotbar slot"):
		return
	var wheat_before_harvest := int((snapshot.get("inventory_materials", {}) as Dictionary).get("wheat", 0))
	if not _require(bool(_meta_root.call("debug_day_world_interact_farm_plot", 0)), "Harvesting the day 3 wheat crop should work from the hand slot"):
		return
	await _await_frames(1)
	snapshot = _snapshot()
	plots = snapshot.get("farm_plots", [])
	if not _require(int((snapshot.get("inventory_materials", {}) as Dictionary).get("wheat", 0)) > wheat_before_harvest, "Harvesting through the day world should add crop output to shared inventory"):
		return
	if not _require(not plots.is_empty() and String((plots[0] as Dictionary).get("seed_id", "")) == "", "Harvesting through the day world should clear the harvested plot"):
		return
	_sync_daily_orders_progress()
	var pantry_restock_card := _find_order_card_by_title("Pantry Restock")
	if not _require(bool(pantry_restock_card.get("can_claim", false)), "Daily orders should observe world harvest gains and surface Pantry Restock as ready to claim"):
		return

	if not _require(bool(_meta_root.call("debug_day_world_select_farm_tool", "till")), "Day 3 should still allow selecting the till tool after harvesting"):
		return
	if not _require(bool(_meta_root.call("debug_day_world_interact_farm_plot", 0)), "Harvested plots should be tillable again through the day world"):
		return
	if not _require(bool(_meta_root.call("debug_day_world_select_farm_tool", "plant", "mooncap_seed")), "Unlocked mooncap seed should appear in the world hotbar tools"):
		return
	await _await_frames(1)
	snapshot = _snapshot()
	if not _require(String(snapshot.get("day_world_selected_farm_tool_seed_id", "")) == "mooncap_seed", "World hotbar selection should track the unlocked mooncap seed"):
		return
	if not _require(bool(_meta_root.call("debug_day_world_interact_farm_plot", 0)), "Unlocked mooncap seed should plant through the day world farm interaction"):
		return
	if not _require(bool(_meta_root.call("debug_day_world_select_farm_tool", "water")), "Watering can should remain available for the unlocked special crop path"):
		return
	if not _require(bool(_meta_root.call("debug_day_world_interact_farm_plot", 0)), "Unlocked mooncap crop should follow the same world watering flow"):
		return
	await _await_frames(1)
	snapshot = _snapshot()
	plots = snapshot.get("farm_plots", [])
	if not _require(not plots.is_empty() and String((plots[0] as Dictionary).get("seed_id", "")) == "mooncap_seed", "World farm state should preserve the replanted mooncap crop"):
		return
	if not _require(not plots.is_empty() and int((plots[0] as Dictionary).get("watered_day", 0)) == 3, "World farm state should record same-day watering on the replanted mooncap crop"):
		return

	if not _require(bool(_meta_root.call("debug_day_world_interact", "shop")), "Day 3 shop entrance should still route into the worldified shop interior"):
		return
	await _await_frames(1)
	snapshot = _snapshot()
	if not _require(bool(_meta_root.call("debug_shop_interact", "shopkeeper")), "Merchant popup should still open from the worldified shop interior"):
		return
	await _await_frames(1)
	snapshot = _snapshot()
	var gold_before_sale := int(snapshot.get("gold", 0))
	if not _require(bool(_meta_root.call("debug_shop_popup_sell_material", "wheat")), "Shop merchant popup should allow selling harvested wheat through the worldified shop flow"):
		return
	await _await_frames(1)
	snapshot = _snapshot()
	if not _require(int(snapshot.get("gold", 0)) > gold_before_sale, "Selling harvested wheat through the worldified shop flow should increase shared gold"):
		return
	var kelpberry_offer := _find_entry_by_id(snapshot.get("shop_seed_offers", []), "kelpberry_seed")
	if not _require(bool(kelpberry_offer.get("enabled", false)), "Worldified merchant popup should expose the first purchasable seed offer once the player has enough gold"):
		return
	if not _require(bool(_meta_root.call("debug_shop_popup_buy_seed", "kelpberry_seed")), "Merchant popup should allow buying kelpberry seed through the worldified shop flow"):
		return
	await _await_frames(1)
	snapshot = _snapshot()
	if not _require((snapshot.get("unlocked_seed_ids", []) as Array).has("kelpberry_seed"), "Worldified shop purchases should unlock seeds in the shared inventory state"):
		return
	if not _require(bool(_meta_root.call("debug_shop_interact", "regular")), "Town regular request popup should still open after worldified merchant actions"):
		return
	await _await_frames(1)
	snapshot = _snapshot()
	if not _require(not String(snapshot.get("shop_request_title", "")).strip_edges().is_empty(), "Town regular request popup should still surface a daily-order request after worldified shop actions"):
		return
	if not _require(bool(_meta_root.call("debug_shop_interact", "door")), "Shop exit door should still return the player to the day hub after worldified merchant actions"):
		return
	await _await_frames(1)

	_meta_root = await _reload_meta_root()
	if _meta_root == null:
		return
	snapshot = _snapshot()
	plots = snapshot.get("farm_plots", [])
	if not _require(int(snapshot.get("current_day", 0)) == 3, "Final save/load checkpoint should preserve the current day"):
		return
	if not _require((snapshot.get("unlocked_seed_ids", []) as Array).has("kelpberry_seed"), "Final save/load checkpoint should preserve worldified shop seed purchases"):
		return
	if not _require((snapshot.get("unlocked_seed_ids", []) as Array).has("mooncap_seed"), "Final save/load checkpoint should preserve night-driven seed unlocks"):
		return
	if not _require(int(snapshot.get("restaurant_last_service_day", 0)) == 2, "Final save/load checkpoint should preserve the last restaurant service day"):
		return
	if not _require(not plots.is_empty() and String((plots[0] as Dictionary).get("seed_id", "")) == "mooncap_seed", "Final save/load checkpoint should preserve the replanted world crop"):
		return
	if not _require(not plots.is_empty() and int((plots[0] as Dictionary).get("watered_day", 0)) == 3, "Final save/load checkpoint should preserve same-day watering on the replanted world crop"):
		return
	_sync_daily_orders_progress()
	lunch_rush_card = _find_order_card_by_title("Lunch Rush")
	pantry_restock_card = _find_order_card_by_title("Pantry Restock")
	if not _require(not bool(lunch_rush_card.get("can_claim", false)), "Final save/load checkpoint should not carry day-2 restaurant order readiness into the refreshed day-3 board"):
		return
	if not _require(bool(pantry_restock_card.get("can_claim", false)), "Final save/load checkpoint should preserve farm daily-order readiness earned through the world loop"):
		return

	print("Day World shell smoke PASS")
	_cleanup(false)


func _spawn_meta_root() -> Node:
	if META_LOOP_SCENE == null:
		return null
	var meta_root: Node = META_LOOP_SCENE.instantiate()
	get_tree().root.add_child.call_deferred(meta_root)
	await _await_frames(2)
	meta_root.call("debug_press_play")
	await _await_frames(1)
	return meta_root


func _reload_meta_root() -> Node:
	if _meta_root != null:
		_meta_root.queue_free()
		_meta_root = null
		await _await_frames(2)
	return await _spawn_meta_root()


func _snapshot() -> Dictionary:
	if _meta_root == null:
		return {}
	var snapshot_variant: Variant = _meta_root.call("debug_get_snapshot")
	return snapshot_variant if snapshot_variant is Dictionary else {}


func _await_frames(frame_count: int) -> void:
	for _i in range(frame_count):
		await get_tree().process_frame


func _await_physics_frames(frame_count: int) -> void:
	for _i in range(frame_count):
		await get_tree().physics_frame
	await get_tree().process_frame


func _reset_daily_orders_runtime() -> void:
	if DailyOrders != null and DailyOrders.has_method("_reset_runtime_state"):
		DailyOrders.call("_reset_runtime_state")


func _sync_daily_orders_progress() -> void:
	if DailyOrders != null and DailyOrders.has_method("_sync_progress"):
		DailyOrders.call("_sync_progress")


func _get_order_cards() -> Array:
	if DailyOrders == null or not DailyOrders.has_method("get_order_cards"):
		return []
	var cards_variant: Variant = DailyOrders.call("get_order_cards")
	return cards_variant as Array if cards_variant is Array else []


func _find_order_card_by_title(title: String) -> Dictionary:
	var normalized_title := title.strip_edges().to_lower()
	for card_variant in _get_order_cards():
		if not (card_variant is Dictionary):
			continue
		var card := card_variant as Dictionary
		if String(card.get("name", "")).strip_edges().to_lower() == normalized_title:
			return card.duplicate(true)
	return {}


func _find_entry_by_id(items_variant: Variant, item_id: String) -> Dictionary:
	if not (items_variant is Array):
		return {}
	var normalized_id := item_id.strip_edges().to_lower()
	for item_variant in (items_variant as Array):
		if not (item_variant is Dictionary):
			continue
		var item := item_variant as Dictionary
		if String(item.get("seed_id", "")).strip_edges().to_lower() == normalized_id:
			return item.duplicate(true)
		if String(item.get("id", "")).strip_edges().to_lower() == normalized_id:
			return item.duplicate(true)
	return {}


func _require(condition: bool, message: String) -> bool:
	if condition:
		return true
	push_error(message)
	_cleanup(true)
	return false


func _cleanup(failed: bool = true) -> void:
	if _meta_root != null:
		_meta_root.queue_free()
		_meta_root = null
	_reset_daily_orders_runtime()
	if ProfileStore != null and ProfileStore.has_method("end_test_session"):
		ProfileStore.end_test_session(true)
	var exit_code := 1 if failed else 0
	get_tree().create_timer(0.0).timeout.connect(func() -> void:
		get_tree().quit(exit_code)
	)
