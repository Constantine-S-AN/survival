extends SceneTree

var failed: int = 0
var _original_language_code: String = "en"


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_bootstrap_script_mode_singletons()
	var localization := _localization()
	if localization != null and localization.has_method("get_language_code"):
		_original_language_code = String(localization.call("get_language_code"))
	if localization != null and localization.has_method("set_language_code"):
		localization.call("set_language_code", "zh_CN")
	_assert_equal(TranslationServer.get_locale(), "zh_CN", "translation server switches to Chinese when localization changes")

	var registry := _registry()
	_assert_equal(String(registry.call("get_seed", "wheat_seed").get("name", "")), "小麦种子", "seed names localize into Chinese")
	_assert_equal(String(registry.call("get_crop", "mooncap").get("name", "")), "月菇", "crop names localize into Chinese")
	_assert_equal(String(registry.call("get_recipe", "field_stew").get("name", "")), "田园炖菜", "recipe names localize into Chinese")
	_assert_true(_contains_cjk(String((registry.call("get_recipe", "field_stew") as Dictionary).get("description", ""))), "recipe descriptions localize into Chinese")
	_assert_true(_contains_cjk(String(((registry.call("get_recipe", "field_stew") as Dictionary).get("night_material_synergy", {}) as Dictionary).get("feedback", ""))), "recipe synergy feedback localizes into Chinese")
	_assert_equal(String(registry.call("get_special_ingredient", "abyssfin").get("name", "")), "深渊鳍鱼片", "night ingredient names localize into Chinese")
	_assert_equal(String(registry.call("get_restaurant_upgrade", "decor_window_box").get("name", "")), "窗台香草箱", "restaurant upgrade names localize into Chinese")
	_assert_equal(String(registry.call("get_meta_unlock", "mooncap_seed_study").get("name", "")), "月菇育种研究", "unlock names localize into Chinese")
	_assert_equal(String(registry.call("get_contract", "contract_loud_world").get("name", "")), "喧响世界", "contract names localize into Chinese")
	_assert_equal(String(registry.call("get_map", "map_black_tide").get("name", "")), "黑潮深渊", "map names localize into Chinese")
	_assert_equal(String(registry.call("get_hazard", "hazard_magnetic_interference").get("name", "")), "磁干扰风暴", "hazard names localize into Chinese")
	_assert_equal(String(registry.call("get_upgrade", "u_shadow_lattice").get("name", "")), "影幕晶格", "late upgrade names localize into Chinese")
	_assert_true(_contains_cjk(String(registry.call("get_upgrade", "u_shadow_lattice").get("description", ""))), "late upgrade descriptions localize into Chinese")
	_assert_true(_contains_cjk(String(registry.call("get_shop_seed_offer", "kelpberry_seed").get("description", ""))), "shop seed offer descriptions localize into Chinese")
	_assert_true(_contains_cjk(String(registry.call("get_shop_sell_entry", "scrap").get("description", ""))), "shop sell descriptions localize into Chinese")
	_assert_equal(String(registry.call("get_material_display_name", "scrap")), "废料", "built-in material names localize into Chinese")
	_assert_equal(String(registry.call("get_enemy", "drifter").get("name", "")), "漂游体", "enemy names localize into Chinese")
	var cold_storage_order := load("res://data/quests/daily_orders/abyssfin_order.tres") as DailyOrderQuest
	if cold_storage_order == null:
		_fail("could not load abyssfin daily order for localization smoke")
	else:
		_assert_equal(cold_storage_order.get_localized_quest_name(), "冷库备货", "daily order titles localize into Chinese")
		_assert_true(_contains_cjk(cold_storage_order.get_localized_quest_description()), "daily order descriptions localize into Chinese")
		_assert_true(_contains_cjk(cold_storage_order.get_localized_quest_objective()), "daily order objectives localize into Chinese")
	var dialogue_layer_script: Script = load("res://scripts/meta/day_hub_intro_dialogue_layer.gd")
	if dialogue_layer_script == null:
		_fail("could not load day hub dialogue layer for localization smoke")
	else:
		var dialogue_layer: CanvasLayer = dialogue_layer_script.new()
		_assert_equal(
			String(dialogue_layer.call("debug_resolve_dialogue_resource_path", "res://data/dialogue/day_hub_intro.dialogue")),
			"res://data/dialogue/day_hub_intro_zh.dialogue",
			"day hub dialogue resolves to the Chinese resource in Chinese mode"
		)
		dialogue_layer.free()
	var boss := registry.call("get_boss", "abyss_siren") as Dictionary
	_assert_equal(String(boss.get("name", "")), "深渊海妖", "boss names localize into Chinese")
	var phases: Array = boss.get("phases", [])
	if phases.is_empty():
		_fail("boss phases are missing from localized boss data")
	else:
		var phase := phases[0] as Dictionary
		_assert_true(_contains_cjk(String(phase.get("label", ""))), "boss phase labels localize into Chinese")
		_assert_true(_contains_cjk(String(phase.get("telegraph_text", ""))), "boss telegraph text localizes into Chinese")

	var menu_planner_script: Script = load("res://scripts/day/restaurant/menu_planner.gd")
	var cards: Array = menu_planner_script.call("build_recipe_cards", [registry.call("get_recipe", "field_stew")], {"wheat": 4, "herb": 2, "scrap": 1}, ["field_stew"], [])
	_assert_true(not cards.is_empty(), "menu planner returns localized recipe cards")
	if not cards.is_empty() and cards[0] is Dictionary:
		var card := cards[0] as Dictionary
		_assert_true(_contains_cjk(String(card.get("label", ""))), "menu planner labels stay in Chinese")
		_assert_true(_contains_cjk(String(card.get("tooltip", ""))), "menu planner tooltips stay in Chinese")
	var service_simulator_script: Script = load("res://scripts/day/restaurant/service_simulator.gd")
	var meta_loop_script: Script = load("res://scripts/meta/meta_loop_controller.gd")
	if service_simulator_script == null or meta_loop_script == null:
		_fail("could not load restaurant/meta scripts for Chinese summary localization smoke")
	else:
		var meta_loop: Node = meta_loop_script.new()
		var service_summary: Dictionary = service_simulator_script.call("simulate_service", {
			"day": 2,
			"reputation": 3,
			"menu_recipes": [registry.call("get_recipe", "field_stew")],
			"inventory_materials": {"wheat": 8, "herb": 4},
			"upgrades": []
		})
		var restaurant_title := String(meta_loop.call("_build_restaurant_result_title", service_summary))
		_assert_true(_contains_cjk(restaurant_title), "restaurant summary title keeps its headline localized in Chinese")
		_assert_true(
			restaurant_title.find("service") == -1
			and restaurant_title.find("packed") == -1
			and restaurant_title.find("steady") == -1
			and restaurant_title.find("quiet") == -1,
			"restaurant summary title does not leak English headline copy in Chinese mode"
		)
		meta_loop.set("_pending_night_session", meta_loop.call("_build_pending_night_session", {
			"day": 2,
			"character_id": registry.call("get_default_character_id"),
			"map_id": registry.call("get_default_map_id"),
			"contract_ids": [],
			"seed": 7,
			"session_duration_sec": 0.0
		}))
		var interrupted_payload: Dictionary = meta_loop.call("_build_interrupted_night_return_payload")
		var interrupted_summary: Dictionary = interrupted_payload.get("raw_summary", {})
		_assert_equal(String(interrupted_summary.get("dungeon_return_route_label", "")), "中断后返港", "interrupted return route label localizes into Chinese")
		meta_loop.free()

	var hub_scene: PackedScene = load("res://scenes/meta/DayHub.tscn")
	if hub_scene == null:
		_fail("could not load DayHub scene for localization smoke")
	else:
		var hub := hub_scene.instantiate()
		root.add_child(hub)
		await process_frame
		var orders_button: Button = hub.get_node_or_null("ContentPanel/Margin/VBox/Actions/OrdersButton")
		if orders_button == null:
			_fail("DayHub orders button missing")
		else:
			_assert_equal(String(orders_button.text), "每日订单", "DayHub orders button text localizes into Chinese")
			_assert_true(_contains_cjk(String(orders_button.tooltip_text)), "DayHub orders tooltip localizes into Chinese")
		if hub != null and is_instance_valid(hub):
			hub.queue_free()

	var main_menu_scene: PackedScene = load("res://scenes/ui/menu/MainMenu.tscn")
	if main_menu_scene == null:
		_fail("could not load MainMenu scene for localization smoke")
	else:
		var main_menu := main_menu_scene.instantiate()
		root.add_child(main_menu)
		await process_frame
		var title_label: Label = main_menu.get_node_or_null("ContentLayer/Stack/Title")
		var play_button: Button = main_menu.get_node_or_null("ContentLayer/Stack/Buttons/PlayButton")
		if title_label == null or play_button == null:
			_fail("MainMenu localized controls missing")
		else:
			_assert_equal(String(title_label.text), "活下去", "main menu title localizes into Chinese")
			_assert_equal(String(play_button.text), "开始游戏", "main menu play button localizes into Chinese")
		if main_menu != null and is_instance_valid(main_menu):
			main_menu.queue_free()

	var orders_scene: PackedScene = load("res://scenes/meta/DailyOrdersBoard.tscn")
	if orders_scene == null:
		_fail("could not load DailyOrdersBoard scene for localization smoke")
	else:
		var orders_board := orders_scene.instantiate()
		root.add_child(orders_board)
		await process_frame
		var close_button: Button = orders_board.get_node_or_null("Panel/Margin/VBox/Header/CloseButton")
		if close_button == null:
			_fail("DailyOrdersBoard close button missing")
		else:
			_assert_equal(String(close_button.text), "关闭", "daily orders board close button localizes into Chinese")
		if orders_board != null and is_instance_valid(orders_board):
			orders_board.queue_free()

	var shop_scene: PackedScene = load("res://scenes/day/shop/Shop.tscn")
	if shop_scene == null:
		_fail("could not load Shop scene for localization smoke")
	else:
		var shop := shop_scene.instantiate()
		root.add_child(shop)
		await process_frame
		var shop_title: Label = shop.get_node_or_null("HUDLayer/InfoPanel/Margin/VBox/Title")
		var shop_leave: Button = shop.get_node_or_null("HUDLayer/LeaveButton")
		if shop_title == null or shop_leave == null:
			_fail("Shop localized controls missing")
		else:
			_assert_equal(String(shop_title.text), "补给小铺", "shop title localizes into Chinese")
			_assert_equal(String(shop_leave.text), "走出商店", "shop leave button localizes into Chinese")
		if shop != null and is_instance_valid(shop):
			shop.queue_free()

	var restaurant_scene: PackedScene = load("res://scenes/day/restaurant/Restaurant.tscn")
	if restaurant_scene == null:
		_fail("could not load Restaurant scene for localization smoke")
	else:
		var restaurant := restaurant_scene.instantiate()
		root.add_child(restaurant)
		await process_frame
		var restaurant_title: Label = restaurant.get_node_or_null("HUDLayer/InfoPanel/Margin/VBox/Title")
		var restaurant_leave: Button = restaurant.get_node_or_null("HUDLayer/LeaveButton")
		if restaurant_title == null or restaurant_leave == null:
			_fail("Restaurant localized controls missing")
		else:
			_assert_equal(String(restaurant_title.text), "餐厅内场", "restaurant title localizes into Chinese")
			_assert_equal(String(restaurant_leave.text), "走出餐馆", "restaurant leave button localizes into Chinese")
		if restaurant != null and is_instance_valid(restaurant):
			restaurant.queue_free()

	var summary_scene: PackedScene = load("res://scenes/meta/ReturnSummary.tscn")
	if summary_scene == null:
		_fail("could not load ReturnSummary scene for localization smoke")
	else:
		var summary_view = summary_scene.instantiate()
		root.add_child(summary_view)
		await process_frame
		if summary_view != null and summary_view.has_method("set_summary"):
			summary_view.call("set_summary", {
				"exit_reason": "extracted",
				"current_day": 2,
				"next_day": 3,
				"loot_text": "废料 x2",
				"night_bonus_text": "无",
				"unlock_text": "无",
				"unlock_progress_text": "无",
				"penalty_text": "状态稳定",
				"inventory_summary": "废料 x2",
				"raw_summary": {
					"dungeon_return_route_label": "提前撤离",
					"dungeon_carryover_rows": [
						{"secured": true},
						{"secured": false}
					]
				}
			})
		await process_frame
		var carryover_card: Label = summary_view.get_node_or_null("ContentPanel/Margin/VBox/Scroll/SummaryVBox/InventoryLabel")
		if carryover_card == null:
			_fail("ReturnSummary inventory card missing")
		else:
			var summary_text := String(carryover_card.text)
			_assert_true(_contains_cjk(summary_text), "return summary extracted carryover text stays in Chinese")
			_assert_true(summary_text.find("secured carryover cache") == -1, "return summary no longer exposes English carryover wording")
		if summary_view != null and is_instance_valid(summary_view):
			summary_view.queue_free()

	_finish()


func _bootstrap_script_mode_singletons() -> void:
	if root.get_node_or_null("Localization") == null:
		var localization_script: Script = load("res://scripts/core/localization.gd")
		var localization_instance: Node = localization_script.new()
		localization_instance.name = "Localization"
		root.add_child(localization_instance)
	if root.get_node_or_null("DataRegistry") == null:
		var registry_script: Script = load("res://scripts/core/data_registry.gd")
		var registry_instance: Node = registry_script.new()
		registry_instance.name = "DataRegistry"
		root.add_child(registry_instance)
	if root.get_node_or_null("ProfileStore") == null:
		var profile_script: Script = load("res://scripts/core/profile_store.gd")
		var profile_instance: Node = profile_script.new()
		profile_instance.name = "ProfileStore"
		root.add_child(profile_instance)
	if not bool(_registry().call("ensure_loaded")):
		_fail("chinese localization smoke could not load DataRegistry")
		return
	_profile_store().call(
		"load_profile",
		_registry().call("get_default_character_id"),
		_registry().call("get_default_map_id")
	)


func _registry() -> Node:
	return root.get_node_or_null("DataRegistry")


func _profile_store() -> Node:
	return root.get_node_or_null("ProfileStore")


func _localization() -> Node:
	return root.get_node_or_null("Localization")


func _contains_cjk(text: String) -> bool:
	for index in range(text.length()):
		var codepoint := text.unicode_at(index)
		if int(codepoint) >= 0x4e00 and int(codepoint) <= 0x9fff:
			return true
	return false


func _assert_true(condition: bool, label: String) -> void:
	if condition:
		print("PASS: %s" % label)
		return
	_fail(label)


func _assert_equal(actual, expected, label: String) -> void:
	if actual == expected:
		print("PASS: %s" % label)
		return
	_fail("%s (expected=%s actual=%s)" % [label, str(expected), str(actual)])


func _fail(message: String) -> void:
	failed += 1
	push_error(message)
	print("FAIL: %s" % message)


func _finish() -> void:
	var localization := _localization()
	if localization != null and localization.has_method("set_language_code"):
		localization.call("set_language_code", _original_language_code)
	print("Chinese localization smoke finished. failed=%d" % failed)
	quit(failed)
