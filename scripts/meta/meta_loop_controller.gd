extends Node
class_name MetaLoopController

const STATE_MENU := "menu"
const STATE_DAY_HUB := "day_hub"
const STATE_FARM := "farm"
const STATE_RESTAURANT := "restaurant"
const STATE_NIGHT := "night"
const STATE_RETURN_SUMMARY := "return_summary"

const FARM_ACTION_TILL := "till"
const FARM_ACTION_WATER := "water"
const FARM_ACTION_HARVEST := "harvest"
const FARM_TILL_STAMINA_COST := 1
const FARM_WATER_STAMINA_COST := 1
const FARM_ACTION_TIME_COST := 1
const RESTAURANT_SERVICE_ACTION_COST := 3
const RESTAURANT_MAX_MENU_SIZE := 3

const DayClockClass := preload("res://scripts/meta/day_clock.gd")
const DayStateClass := preload("res://scripts/meta/day_state.gd")
const InventoryStateClass := preload("res://scripts/meta/inventory.gd")
const EconomyStateClass := preload("res://scripts/meta/economy_state.gd")
const RewardPipelineClass := preload("res://scripts/meta/reward_pipeline.gd")
const MenuPlannerClass := preload("res://scripts/day/restaurant/menu_planner.gd")
const ServiceSimulatorClass := preload("res://scripts/day/restaurant/service_simulator.gd")

const MATERIAL_DISPLAY_NAMES: Dictionary = {
	"scrap": "Scrap"
}

@onready var main_menu: MainMenuView = $MainMenu
@onready var day_hub: DayHubView = $DayHub
@onready var farm_view: Control = $Farm
@onready var restaurant_view: Control = $Restaurant
@onready var return_summary_view: ReturnSummaryView = $ReturnSummary
@onready var night_combat_root: NightCombatRoot = $NightCombatRoot

var _day_state = DayStateClass.new()
var _inventory = InventoryStateClass.new()
var _economy = EconomyStateClass.new()
var _reward_pipeline = RewardPipelineClass.new()
var _farm_state: Dictionary = {}
var _restaurant_state: Dictionary = {}
var _pending_return_summary: Dictionary = {}
var _current_state: String = STATE_MENU
var _day_hub_status_text: String = ""
var _farm_status_text: String = ""
var _restaurant_status_text: String = ""


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_ensure_profile_loaded()
	_load_meta_progress()
	_connect_signals()
	_refresh_views()
	_show_state(STATE_MENU)


func _connect_signals() -> void:
	if main_menu != null and main_menu.has_signal("play_pressed"):
		main_menu.connect("play_pressed", Callable(self, "_on_play_requested"))
	if day_hub != null:
		day_hub.farm_requested.connect(_on_day_hub_farm_requested)
		day_hub.restaurant_requested.connect(_on_day_hub_restaurant_requested)
		day_hub.wait_requested.connect(_on_day_hub_wait_requested)
		day_hub.night_requested.connect(_on_day_hub_night_requested)
		day_hub.menu_requested.connect(_on_menu_requested)
	if farm_view != null:
		farm_view.plot_action_requested.connect(_on_farm_plot_action_requested)
		farm_view.back_requested.connect(_on_farm_back_requested)
	if restaurant_view != null:
		restaurant_view.recipe_toggled.connect(_on_restaurant_recipe_toggled)
		restaurant_view.clear_menu_requested.connect(_on_restaurant_menu_cleared)
		restaurant_view.service_requested.connect(_on_restaurant_service_requested)
		restaurant_view.back_requested.connect(_on_restaurant_back_requested)
	if return_summary_view != null:
		return_summary_view.continue_requested.connect(_on_return_summary_continue_requested)
		return_summary_view.menu_requested.connect(_on_menu_requested)
	if night_combat_root != null:
		night_combat_root.session_completed.connect(_on_night_session_completed)


func _ensure_profile_loaded() -> void:
	if not DataRegistry.ensure_loaded():
		push_error("DataRegistry failed to load before meta loop.")
	var default_character_id := DataRegistry.get_default_character_id()
	var default_map_id := DataRegistry.get_default_map_id()
	if ProfileStore == null:
		return
	if not bool(ProfileStore.loaded):
		ProfileStore.load_profile(
			default_character_id if not default_character_id.is_empty() else "diver",
			default_map_id
		)


func _load_meta_progress() -> void:
	if ProfileStore == null or not ProfileStore.has_method("get_meta_progress_state"):
		return
	var snapshot: Dictionary = ProfileStore.get_meta_progress_state()
	_day_state = DayStateClass.from_dict(snapshot.get("day_state", {}))
	_inventory = InventoryStateClass.from_dict(snapshot.get("inventory", {}))
	_economy = EconomyStateClass.from_dict(snapshot.get("economy", {}))
	_farm_state = _normalize_farm_state(snapshot.get("farm_state", {}))
	_restaurant_state = _normalize_restaurant_state(snapshot.get("restaurant_state", {}))
	var summary_variant: Variant = snapshot.get("pending_return_summary", {})
	_pending_return_summary = (summary_variant as Dictionary).duplicate(true) if summary_variant is Dictionary else {}
	if _day_state.current_phase == DayStateClass.PHASE_NIGHT and _pending_return_summary.is_empty():
		_day_state.reset_daytime()
		_save_meta_progress()


func _save_meta_progress() -> void:
	if ProfileStore == null or not ProfileStore.has_method("set_meta_progress_state"):
		return
	ProfileStore.set_meta_progress_state({
		"schema_version": 5,
		"day_state": _day_state.to_dict(),
		"economy": _economy.to_dict(),
		"inventory": _inventory.to_dict(),
		"farm_state": _farm_state.duplicate(true),
		"restaurant_state": _restaurant_state.duplicate(true),
		"pending_return_summary": _pending_return_summary.duplicate(true)
	})


func _normalize_farm_state(source_variant: Variant) -> Dictionary:
	var source: Dictionary = source_variant if source_variant is Dictionary else {}
	var columns := maxi(1, int(source.get("columns", 3)))
	var rows := maxi(1, int(source.get("rows", 2)))
	var plot_count := maxi(1, columns * rows)
	var plots_variant: Variant = source.get("plots", [])
	var plots: Array = plots_variant if plots_variant is Array else []
	var normalized_plots: Array[Dictionary] = []
	for plot_variant in plots:
		if normalized_plots.size() >= plot_count:
			break
		var plot: Dictionary = plot_variant if plot_variant is Dictionary else {}
		normalized_plots.append(_normalize_plot(plot))
	while normalized_plots.size() < plot_count:
		normalized_plots.append(_build_empty_plot())
	return {
		"columns": columns,
		"rows": rows,
		"plots": normalized_plots
	}


func _normalize_restaurant_state(source_variant: Variant) -> Dictionary:
	var source: Dictionary = source_variant if source_variant is Dictionary else {}
	return {
		"selected_menu_recipe_ids": _normalize_string_id_array(source.get("selected_menu_recipe_ids", [])),
		"last_service_day": maxi(0, int(source.get("last_service_day", 0))),
		"last_service_summary": (source.get("last_service_summary", {}) as Dictionary).duplicate(true) if source.get("last_service_summary", {}) is Dictionary else {},
		"owned_upgrade_ids": _normalize_string_id_array(source.get("owned_upgrade_ids", []))
	}


func _normalize_plot(plot_variant: Variant) -> Dictionary:
	var plot: Dictionary = plot_variant if plot_variant is Dictionary else {}
	var crop_variant: Variant = plot.get("crop", {})
	var crop_state = _crop_from_dict(crop_variant if crop_variant is Dictionary else {})
	return {
		"tilled": bool(plot.get("tilled", false)),
		"crop": crop_state.duplicate(true)
	}


func _build_empty_plot() -> Dictionary:
	return {
		"tilled": false,
		"crop": {}
	}


func _crop_from_dict(crop_variant: Variant):
	var source: Dictionary = crop_variant if crop_variant is Dictionary else {}
	var crop_id := String(source.get("crop_id", "")).strip_edges().to_lower()
	var seed_id := String(source.get("seed_id", "")).strip_edges().to_lower()
	if crop_id.is_empty() or seed_id.is_empty():
		return {}
	return {
		"crop_id": crop_id,
		"seed_id": seed_id,
		"planted_day": maxi(1, int(source.get("planted_day", 1))),
		"growth_days": maxi(1, int(source.get("growth_days", 1))),
		"growth_progress_days": maxi(0, int(source.get("growth_progress_days", 0))),
		"watered_day": maxi(0, int(source.get("watered_day", 0)))
	}


func _new_crop_instance(seed_id: String, crop_id: String, growth_days: int, current_day: int):
	return {
		"seed_id": seed_id.strip_edges().to_lower(),
		"crop_id": crop_id.strip_edges().to_lower(),
		"growth_days": maxi(1, growth_days),
		"planted_day": maxi(1, current_day),
		"growth_progress_days": 0,
		"watered_day": 0
	}


func _crop_is_empty(crop_state: Dictionary) -> bool:
	return String(crop_state.get("crop_id", "")).strip_edges().is_empty() or String(crop_state.get("seed_id", "")).strip_edges().is_empty()


func _crop_is_watered_on_day(crop_state: Dictionary, current_day: int) -> bool:
	return int(crop_state.get("watered_day", 0)) == maxi(0, current_day)


func _crop_can_water(crop_state: Dictionary, current_day: int) -> bool:
	return not _crop_is_empty(crop_state) and not _crop_is_harvestable(crop_state) and not _crop_is_watered_on_day(crop_state, current_day)


func _crop_mark_watered(crop_state: Dictionary, current_day: int) -> void:
	if _crop_is_empty(crop_state):
		return
	crop_state["watered_day"] = maxi(0, current_day)


func _crop_advance_day(crop_state: Dictionary, previous_day: int) -> void:
	if _crop_is_empty(crop_state) or _crop_is_harvestable(crop_state):
		return
	if int(crop_state.get("watered_day", 0)) == maxi(0, previous_day):
		crop_state["growth_progress_days"] = mini(int(crop_state.get("growth_days", 1)), int(crop_state.get("growth_progress_days", 0)) + 1)


func _crop_is_harvestable(crop_state: Dictionary) -> bool:
	if _crop_is_empty(crop_state):
		return false
	return int(crop_state.get("growth_progress_days", 0)) >= int(crop_state.get("growth_days", 1))


func _crop_progress_text(crop_state: Dictionary) -> String:
	if _crop_is_empty(crop_state):
		return ""
	return "%d/%d days" % [
		mini(int(crop_state.get("growth_progress_days", 0)), int(crop_state.get("growth_days", 1))),
		int(crop_state.get("growth_days", 1))
	]


func _refresh_views() -> void:
	if day_hub != null and day_hub.has_method("set_view_model"):
		day_hub.call("set_view_model", _build_day_hub_model())
	if farm_view != null and farm_view.has_method("set_view_model"):
		farm_view.call("set_view_model", _build_farm_model())
	if restaurant_view != null and restaurant_view.has_method("set_view_model"):
		restaurant_view.call("set_view_model", _build_restaurant_model())
	if return_summary_view != null and return_summary_view.has_method("set_summary"):
		return_summary_view.call("set_summary", _pending_return_summary)


func _show_state(next_state: String) -> void:
	_current_state = next_state
	if main_menu != null:
		main_menu.visible = next_state == STATE_MENU
	if day_hub != null:
		day_hub.visible = next_state == STATE_DAY_HUB
	if farm_view != null:
		farm_view.visible = next_state == STATE_FARM
	if restaurant_view != null:
		restaurant_view.visible = next_state == STATE_RESTAURANT
	if return_summary_view != null:
		return_summary_view.visible = next_state == STATE_RETURN_SUMMARY


func _on_play_requested() -> void:
	_refresh_views()
	if not _pending_return_summary.is_empty():
		_show_state(STATE_RETURN_SUMMARY)
		return
	_show_state(STATE_DAY_HUB)


func _on_menu_requested() -> void:
	_show_state(STATE_MENU)


func _on_day_hub_farm_requested() -> void:
	_show_state(STATE_FARM)


func _on_day_hub_restaurant_requested() -> void:
	_show_state(STATE_RESTAURANT)


func _on_day_hub_wait_requested() -> void:
	_wait_until_evening()


func _on_day_hub_night_requested() -> void:
	_launch_night()


func _on_farm_back_requested() -> void:
	_show_state(STATE_DAY_HUB)


func _on_restaurant_back_requested() -> void:
	_show_state(STATE_DAY_HUB)


func _on_farm_plot_action_requested(plot_index: int, action_id: String, seed_id: String) -> void:
	_apply_farm_plot_action(plot_index, action_id, seed_id)


func _on_restaurant_recipe_toggled(recipe_id: String) -> void:
	_toggle_restaurant_recipe(recipe_id)


func _on_restaurant_menu_cleared() -> void:
	_clear_restaurant_menu()


func _on_restaurant_service_requested() -> void:
	_open_restaurant_service()


func _wait_until_evening() -> bool:
	if _day_state.current_phase == DayStateClass.PHASE_NIGHT:
		return false
	var spent_actions := _day_state.rest_until_evening()
	if spent_actions <= 0:
		_day_hub_status_text = _build_day_hub_status_text()
		_refresh_views()
		return false
	_day_hub_status_text = _t("meta.hub.status_waited", {"value": spent_actions})
	_farm_status_text = ""
	_restaurant_status_text = ""
	_save_meta_progress()
	_refresh_views()
	return true


func _launch_night() -> bool:
	if not _day_state.can_launch_night():
		_day_hub_status_text = _t("meta.hub.status_night_locked", {"value": _day_state.actions_until_evening()})
		_refresh_views()
		return false
	var character_id := ProfileStore.get_selected_character_id(DataRegistry.get_default_character_id())
	if not ProfileStore.is_character_unlocked(character_id):
		character_id = DataRegistry.get_default_character_id()
	var map_id := ProfileStore.get_selected_map_id(DataRegistry.get_default_map_id())
	if map_id.is_empty() or not DataRegistry.has_map(map_id):
		map_id = DataRegistry.get_default_map_id()
	var request := {
		"day": _day_state.current_day,
		"character_id": character_id,
		"map_id": map_id,
		"contract_ids": ProfileStore.get_selected_contract_ids(),
		"seed": int(Time.get_unix_time_from_system())
	}
	_day_state.begin_night()
	_pending_return_summary.clear()
	_day_hub_status_text = ""
	_farm_status_text = ""
	_restaurant_status_text = ""
	_save_meta_progress()
	_refresh_views()
	_show_state(STATE_NIGHT)
	night_combat_root.start_session(request)
	return true


func _on_night_session_completed(summary: Dictionary) -> void:
	var return_payload := _apply_night_rewards(summary)
	_pending_return_summary = return_payload
	_save_meta_progress()
	_refresh_views()
	_show_state(STATE_RETURN_SUMMARY)


func _on_return_summary_continue_requested() -> void:
	var previous_day: int = _day_state.current_day
	_day_state.begin_next_day()
	_advance_farm_for_new_day(previous_day)
	_pending_return_summary.clear()
	_day_hub_status_text = ""
	_farm_status_text = ""
	_restaurant_status_text = ""
	_save_meta_progress()
	_refresh_views()
	_show_state(STATE_DAY_HUB)


func _advance_farm_for_new_day(previous_day: int) -> void:
	var plots := _get_farm_plots()
	for plot_index in range(plots.size()):
		var plot_variant: Variant = plots[plot_index]
		if not (plot_variant is Dictionary):
			continue
		var plot: Dictionary = plot_variant
		var crop_state: Dictionary = _crop_from_dict(plot.get("crop", {}))
		if _crop_is_empty(crop_state):
			continue
		_crop_advance_day(crop_state, previous_day)
		plot["crop"] = crop_state.duplicate(true)
		plots[plot_index] = plot
	_farm_state["plots"] = plots


func _apply_farm_plot_action(plot_index: int, action_id: String, seed_id: String) -> bool:
	var plots := _get_farm_plots()
	if plot_index < 0 or plot_index >= plots.size():
		_farm_status_text = _t("meta.farm.status_invalid")
		_refresh_views()
		return false
	var plot_variant: Variant = plots[plot_index]
	var plot: Dictionary = plot_variant if plot_variant is Dictionary else _build_empty_plot()
	var action := action_id.strip_edges().to_lower()
	var ok := false
	match action:
		FARM_ACTION_TILL:
			ok = _apply_till_action(plot_index, plot, plots)
		FARM_ACTION_WATER:
			ok = _apply_water_action(plot_index, plot, plots)
		FARM_ACTION_HARVEST:
			ok = _apply_harvest_action(plot_index, plot, plots)
		"plant":
			ok = _apply_plant_action(plot_index, plot, plots, seed_id)
		_:
			_farm_status_text = _t("meta.farm.status_invalid")
	if ok:
		_save_meta_progress()
	_refresh_views()
	return ok


func _try_consume_farm_action(stamina_cost: int, action_cost: int = FARM_ACTION_TIME_COST) -> bool:
	if not _day_state.can_spend_action_budget(action_cost):
		_farm_status_text = _t("meta.common.no_actions")
		return false
	if not _day_state.can_spend_stamina(stamina_cost):
		_farm_status_text = _t("meta.common.no_stamina")
		return false
	if not _day_state.spend_daytime_action(stamina_cost, action_cost):
		_farm_status_text = _t("meta.common.no_actions")
		return false
	_day_hub_status_text = ""
	return true


func _apply_till_action(plot_index: int, plot: Dictionary, plots: Array) -> bool:
	var crop_state: Dictionary = _crop_from_dict(plot.get("crop", {}))
	if bool(plot.get("tilled", false)) or not _crop_is_empty(crop_state):
		_farm_status_text = _t("meta.farm.status_tilled")
		return false
	if not _try_consume_farm_action(FARM_TILL_STAMINA_COST):
		return false
	plot["tilled"] = true
	plot["crop"] = {}
	plots[plot_index] = plot
	_farm_state["plots"] = plots
	_farm_status_text = _t("meta.farm.status_till_done", {"value": plot_index + 1})
	return true


func _apply_plant_action(plot_index: int, plot: Dictionary, plots: Array, seed_id: String) -> bool:
	var normalized_seed_id := seed_id.strip_edges().to_lower()
	if normalized_seed_id.is_empty():
		_farm_status_text = _t("meta.farm.status_invalid")
		return false
	if not _inventory.has_seed(normalized_seed_id):
		_farm_status_text = _t("meta.farm.status_locked", {"value": _display_seed_name(normalized_seed_id)})
		return false
	if not bool(plot.get("tilled", false)):
		_farm_status_text = _t("meta.farm.status_need_till")
		return false
	var existing_crop: Dictionary = _crop_from_dict(plot.get("crop", {}))
	if not _crop_is_empty(existing_crop):
		_farm_status_text = _t("meta.farm.status_plot_busy")
		return false
	var seed_def := DataRegistry.get_seed(normalized_seed_id)
	var crop_def := DataRegistry.get_crop_by_seed(normalized_seed_id)
	if seed_def.is_empty() or crop_def.is_empty():
		_farm_status_text = _t("meta.farm.status_invalid")
		return false
	var plant_cost := maxi(0, int(seed_def.get("plant_stamina_cost", 1)))
	if not _try_consume_farm_action(plant_cost):
		return false
	var crop_state = _new_crop_instance(
		normalized_seed_id,
		String(crop_def.get("id", "")),
		int(crop_def.get("growth_days", 1)),
		_day_state.current_day
	)
	plot["crop"] = crop_state.duplicate(true)
	plots[plot_index] = plot
	_farm_state["plots"] = plots
	_farm_status_text = _t("meta.farm.status_plant_done", {"value": _display_seed_name(normalized_seed_id)})
	return true


func _apply_water_action(plot_index: int, plot: Dictionary, plots: Array) -> bool:
	var crop_state: Dictionary = _crop_from_dict(plot.get("crop", {}))
	if _crop_is_empty(crop_state):
		_farm_status_text = _t("meta.farm.status_need_seed")
		return false
	if _crop_is_harvestable(crop_state):
		_farm_status_text = _t("meta.farm.status_ready")
		return false
	if not _crop_can_water(crop_state, _day_state.current_day):
		_farm_status_text = _t("meta.farm.status_watered")
		return false
	if not _try_consume_farm_action(FARM_WATER_STAMINA_COST):
		return false
	_crop_mark_watered(crop_state, _day_state.current_day)
	plot["crop"] = crop_state.duplicate(true)
	plots[plot_index] = plot
	_farm_state["plots"] = plots
	_farm_status_text = _t("meta.farm.status_water_done", {"value": _display_material_name(String(crop_state.get("crop_id", "")))})
	return true


func _apply_harvest_action(plot_index: int, plot: Dictionary, plots: Array) -> bool:
	var crop_state: Dictionary = _crop_from_dict(plot.get("crop", {}))
	if _crop_is_empty(crop_state) or not _crop_is_harvestable(crop_state):
		_farm_status_text = _t("meta.farm.status_not_ready")
		return false
	if not _try_consume_farm_action(0):
		return false
	var crop_id := String(crop_state.get("crop_id", ""))
	var crop_def := DataRegistry.get_crop(crop_id)
	var harvest_yield := maxi(1, int(crop_def.get("harvest_yield", 1)))
	_inventory.add_material(crop_id, harvest_yield)
	plots[plot_index] = _build_empty_plot()
	_farm_state["plots"] = plots
	_farm_status_text = _t("meta.farm.status_gain", {
		"value": _build_material_bundle_text({crop_id: harvest_yield})
	})
	return true


func _toggle_restaurant_recipe(recipe_id: String) -> bool:
	var normalized_id := recipe_id.strip_edges().to_lower()
	if normalized_id.is_empty() or not DataRegistry.has_recipe(normalized_id):
		_restaurant_status_text = _t("meta.restaurant.status_invalid")
		_refresh_views()
		return false
	if not _inventory.has_recipe(normalized_id):
		_restaurant_status_text = _t("meta.restaurant.status_locked", {"value": _display_recipe_name(normalized_id)})
		_refresh_views()
		return false
	var result: Dictionary = MenuPlannerClass.toggle_recipe(
		_restaurant_state.get("selected_menu_recipe_ids", []),
		normalized_id,
		RESTAURANT_MAX_MENU_SIZE
	)
	_restaurant_state["selected_menu_recipe_ids"] = result.get("selected_menu_ids", [])
	var status := String(result.get("status", ""))
	if status == "full":
		_restaurant_status_text = _t("meta.restaurant.status_menu_full", {"value": RESTAURANT_MAX_MENU_SIZE})
		_refresh_views()
		return false
	if status == "removed":
		_restaurant_status_text = _t("meta.restaurant.status_menu_removed", {"value": _display_recipe_name(normalized_id)})
	else:
		_restaurant_status_text = _t("meta.restaurant.status_menu_added", {"value": _display_recipe_name(normalized_id)})
	_save_meta_progress()
	_refresh_views()
	return true


func _clear_restaurant_menu() -> void:
	_restaurant_state["selected_menu_recipe_ids"] = []
	_restaurant_status_text = _t("meta.restaurant.status_menu_cleared")
	_save_meta_progress()
	_refresh_views()


func _open_restaurant_service() -> bool:
	if _restaurant_service_completed_today():
		_restaurant_status_text = _t("meta.restaurant.status_closed_today")
		_refresh_views()
		return false
	if not _day_state.can_spend_action_budget(RESTAURANT_SERVICE_ACTION_COST):
		_restaurant_status_text = _t("meta.restaurant.status_need_time")
		_refresh_views()
		return false
	var selected_menu_ids: Array[String] = _normalize_string_id_array(_restaurant_state.get("selected_menu_recipe_ids", []))
	if selected_menu_ids.is_empty():
		_restaurant_status_text = _t("meta.restaurant.status_need_menu")
		_refresh_views()
		return false
	var recipe_lookup := _get_recipe_lookup()
	var menu_recipes: Array = []
	for recipe_id in selected_menu_ids:
		var recipe_variant: Variant = recipe_lookup.get(recipe_id, {})
		if recipe_variant is Dictionary:
			menu_recipes.append((recipe_variant as Dictionary).duplicate(true))
	var simulation: Dictionary = ServiceSimulatorClass.simulate_service({
		"day": _day_state.current_day,
		"reputation": _economy.restaurant_reputation,
		"menu_recipes": menu_recipes,
		"inventory_materials": _inventory.materials.duplicate(true),
		"upgrades": _get_owned_restaurant_upgrades()
	})
	if not bool(simulation.get("ok", false)):
		var error_code := String(simulation.get("error", "invalid"))
		match error_code:
			"no_menu":
				_restaurant_status_text = _t("meta.restaurant.status_need_menu")
			"insufficient_ingredients":
				_restaurant_status_text = _t("meta.restaurant.status_need_stock")
			_:
				_restaurant_status_text = _t("meta.restaurant.status_invalid")
		_refresh_views()
		return false

	var ingredients_consumed_variant: Variant = simulation.get("ingredients_consumed", {})
	var ingredients_consumed: Dictionary = ingredients_consumed_variant if ingredients_consumed_variant is Dictionary else {}
	for material_id_variant in ingredients_consumed.keys():
		var material_id := String(material_id_variant)
		var amount := int(ingredients_consumed.get(material_id_variant, 0))
		if amount <= 0:
			continue
		_inventory.remove_material(material_id, amount)
	_economy.add_gold(int(simulation.get("revenue", 0)))
	_economy.add_reputation(int(simulation.get("reputation_delta", 0)))
	var sold_dishes_variant: Variant = simulation.get("sold_dishes", {})
	if sold_dishes_variant is Dictionary:
		for dish_id_variant in (sold_dishes_variant as Dictionary).keys():
			_economy.record_dish_sales(String(dish_id_variant), int((sold_dishes_variant as Dictionary).get(dish_id_variant, 0)))

	_day_state.spend_action_budget(RESTAURANT_SERVICE_ACTION_COST)
	_restaurant_state["last_service_day"] = _day_state.current_day
	_restaurant_state["last_service_summary"] = simulation.duplicate(true)
	var unlocked_recipe_names := _maybe_unlock_restaurant_recipes()
	_day_hub_status_text = ""
	_restaurant_status_text = _t("meta.restaurant.status_service_complete", {
		"gold": int(simulation.get("revenue", 0)),
		"rep": _format_signed_int(int(simulation.get("reputation_delta", 0)))
	})
	if not unlocked_recipe_names.is_empty():
		_restaurant_status_text += "\n%s" % _t("meta.restaurant.status_new_unlock", {
			"value": ", ".join(unlocked_recipe_names)
		})
	_save_meta_progress()
	_refresh_views()
	return true


func _apply_night_rewards(summary: Dictionary) -> Dictionary:
	var reward_result: Dictionary = _reward_pipeline.resolve_night_return(summary, _day_state, _economy, _inventory)
	var session_variant: Variant = reward_result.get("session", {})
	var session: Dictionary = session_variant if session_variant is Dictionary else {}
	var material_bundle: Dictionary = (reward_result.get("material_rewards", {}) as Dictionary).duplicate(true) if reward_result.get("material_rewards", {}) is Dictionary else {}
	var loot_categories: Array = (reward_result.get("loot_categories", []) as Array).duplicate(true) if reward_result.get("loot_categories", []) is Array else []
	var gold_reward := maxi(0, int(reward_result.get("gold_reward", 0)))

	if _day_state.pending_night_gold_bonus > 0:
		gold_reward += _day_state.pending_night_gold_bonus
		_economy.add_gold(_day_state.pending_night_gold_bonus)
	if _day_state.pending_night_material_bonus > 0:
		material_bundle["scrap"] = maxi(0, int(material_bundle.get("scrap", 0))) + _day_state.pending_night_material_bonus
		_inventory.add_material("scrap", _day_state.pending_night_material_bonus)
		_add_loot_category_amount(loot_categories, "common_materials", "scrap", _day_state.pending_night_material_bonus)

	var unlock_names := _extract_unlock_names(reward_result.get("new_unlocks", []))
	var restaurant_unlocks := _maybe_unlock_restaurant_recipes()
	for unlock_name in restaurant_unlocks:
		if unlock_names.has(unlock_name):
			continue
		unlock_names.append(unlock_name)

	var penalty_variant: Variant = reward_result.get("penalty", {})
	var penalty: Dictionary = penalty_variant if penalty_variant is Dictionary else {}
	var unlock_progress_variant: Variant = reward_result.get("unlock_progress", [])
	var unlock_progress: Array = unlock_progress_variant if unlock_progress_variant is Array else []

	return {
		"current_day": _day_state.current_day,
		"next_day": _day_state.current_day + 1,
		"exit_reason": String(session.get("exit_reason", "completed")),
		"time_text": _format_time(float(session.get("time_survived_sec", 0.0))),
		"kills": int(session.get("kills", 0)),
		"seed": int(summary.get("seed", 0)),
		"gold_reward": gold_reward,
		"materials_reward": material_bundle.duplicate(true),
		"materials_reward_text": _build_material_bundle_text(material_bundle),
		"loot_categories": loot_categories.duplicate(true),
		"loot_text": _build_loot_summary_text(gold_reward, loot_categories),
		"night_bonus_text": _build_night_bonus_summary(),
		"inventory_summary": _build_inventory_summary(),
		"unlock_names": unlock_names.duplicate(),
		"unlock_text": ", ".join(unlock_names) if not unlock_names.is_empty() else _t("meta.common.none"),
		"unlock_progress": unlock_progress.duplicate(true),
		"unlock_progress_text": _build_unlock_progress_text(unlock_progress),
		"penalty": penalty.duplicate(true),
		"penalty_text": _build_penalty_text(penalty),
		"raw_summary": summary.duplicate(true)
	}


func _build_day_hub_model() -> Dictionary:
	var bridge_info := _build_day_hub_bridge_info()
	var night_ready := _day_state.can_launch_night()
	return {
		"current_day": _day_state.current_day,
		"gold": _economy.gold,
		"reputation": _economy.restaurant_reputation,
		"stamina": _day_state.stamina,
		"max_stamina": _day_state.max_stamina,
		"action_budget": _day_state.action_budget,
		"max_action_budget": _day_state.max_action_budget,
		"phase": _day_state.current_phase,
		"inventory_summary": _build_inventory_summary(),
		"inventory_tooltip": _build_night_stock_tooltip(),
		"seed_summary": _build_unlocked_seed_summary(),
		"seed_tooltip": _build_seed_bridge_tooltip(),
		"recipe_summary": _build_unlocked_recipe_summary(),
		"recipe_tooltip": _build_recipe_bridge_tooltip(),
		"night_bonus_summary": _build_night_bonus_summary(),
		"bonus_tooltip": _build_night_bonus_summary(),
		"bridge_summary": String(bridge_info.get("summary", _t("meta.bridge.summary_none"))),
		"bridge_tooltip": String(bridge_info.get("tooltip", "")),
		"status_text": _build_day_hub_status_text(),
		"wait_button_text": _t("meta.hub.wait_evening"),
		"wait_button_tooltip": _build_wait_button_tooltip(),
		"wait_button_disabled": night_ready,
		"night_button_disabled": not night_ready,
		"night_button_tooltip": _build_night_button_tooltip()
	}


func _build_day_hub_status_text() -> String:
	if not _day_hub_status_text.is_empty():
		return _day_hub_status_text
	if _day_state.can_launch_night():
		return _t("meta.hub.status_night_ready")
	return _t("meta.hub.status_night_locked", {"value": _day_state.actions_until_evening()})


func _build_wait_button_tooltip() -> String:
	if _day_state.can_launch_night():
		return _t("meta.hub.wait_tooltip_ready")
	return _t("meta.hub.wait_tooltip", {"value": _day_state.actions_until_evening()})


func _build_night_button_tooltip() -> String:
	if _day_state.can_launch_night():
		return _t("meta.hub.night_tooltip_ready")
	return _t("meta.hub.night_tooltip_locked", {"value": _day_state.actions_until_evening()})


func _build_farm_model() -> Dictionary:
	var bridge_info := _build_farm_bridge_info()
	return {
		"current_day": _day_state.current_day,
		"phase": _day_state.current_phase,
		"stamina": _day_state.stamina,
		"max_stamina": _day_state.max_stamina,
		"action_budget": _day_state.action_budget,
		"max_action_budget": _day_state.max_action_budget,
		"inventory_summary": _build_inventory_summary(),
		"inventory_tooltip": _build_night_stock_tooltip(),
		"bridge_summary": String(bridge_info.get("summary", _t("meta.bridge.summary_none"))),
		"bridge_tooltip": String(bridge_info.get("tooltip", "")),
		"status_text": _farm_status_text,
		"columns": int(_farm_state.get("columns", 3)),
		"tools": _build_farm_tools(),
		"plots": _build_farm_plot_models()
	}


func _build_farm_tools() -> Array[Dictionary]:
	var tools: Array[Dictionary] = [
		{
			"id": FARM_ACTION_TILL,
			"seed_id": "",
			"label": _t("meta.farm.tool_till"),
			"enabled": _day_state.can_take_daytime_action(FARM_TILL_STAMINA_COST, FARM_ACTION_TIME_COST)
		},
		{
			"id": FARM_ACTION_WATER,
			"seed_id": "",
			"label": _t("meta.farm.tool_water"),
			"enabled": _day_state.can_take_daytime_action(FARM_WATER_STAMINA_COST, FARM_ACTION_TIME_COST)
		},
		{
			"id": FARM_ACTION_HARVEST,
			"seed_id": "",
			"label": _t("meta.farm.tool_harvest"),
			"enabled": _day_state.can_spend_action_budget(FARM_ACTION_TIME_COST)
		}
	]
	for seed_variant in DataRegistry.get_seeds():
		if not (seed_variant is Dictionary):
			continue
		var seed: Dictionary = seed_variant
		var seed_id := String(seed.get("id", "")).strip_edges().to_lower()
		if seed_id.is_empty():
			continue
		var crop_def := DataRegistry.get_crop(String(seed.get("crop_id", "")))
		var growth_days := maxi(1, int(crop_def.get("growth_days", 1)))
		var plant_cost := maxi(0, int(seed.get("plant_stamina_cost", 1)))
		var unlock_material_ids := _get_unlock_material_ids_for_target("seed", seed_id)
		var label := _display_seed_name(seed_id)
		if _inventory.has_seed(seed_id):
			label += "\n%s" % _t("meta.farm.tool_seed_detail", {
				"days": growth_days,
				"cost": plant_cost
			})
		else:
			label += "\n%s" % _t("meta.farm.action_locked")
		if not unlock_material_ids.is_empty():
			label += "\n%s" % _t("meta.farm.tool_night_unlock", {
				"value": _build_material_name_list(unlock_material_ids)
			})
		tools.append({
			"id": "plant",
			"seed_id": seed_id,
			"label": label,
			"enabled": _inventory.has_seed(seed_id) and _day_state.can_take_daytime_action(plant_cost, FARM_ACTION_TIME_COST),
			"tooltip": _build_seed_tooltip(seed, crop_def)
		})
	return tools


func _build_farm_plot_models() -> Array[Dictionary]:
	var plots: Array[Dictionary] = []
	var farm_plots := _get_farm_plots()
	for plot_index in range(farm_plots.size()):
		var plot_variant: Variant = farm_plots[plot_index]
		var plot: Dictionary = plot_variant if plot_variant is Dictionary else _build_empty_plot()
		var crop_state: Dictionary = _crop_from_dict(plot.get("crop", {}))
		var state_id := "empty"
		var title := _t("meta.farm.plot_empty")
		var subtitle := _t("meta.farm.plot_empty_hint")
		if bool(plot.get("tilled", false)) and _crop_is_empty(crop_state):
			state_id = "tilled"
			title = _t("meta.farm.plot_tilled")
			subtitle = _t("meta.farm.plot_tilled_hint")
		elif not _crop_is_empty(crop_state):
			var crop_name := _display_material_name(String(crop_state.get("crop_id", "")))
			var progress_text := _crop_progress_text(crop_state)
			if _crop_is_harvestable(crop_state):
				state_id = "harvestable"
				title = crop_name
				subtitle = _t("meta.farm.plot_harvest_hint")
			elif _crop_is_watered_on_day(crop_state, _day_state.current_day):
				state_id = "watered"
				title = crop_name
				subtitle = _t("meta.farm.plot_watered_hint", {"value": progress_text})
			else:
				state_id = "planted"
				title = crop_name
				subtitle = _t("meta.farm.plot_planted_hint", {"value": progress_text})
			plots.append({
				"index": plot_index,
				"title": title,
				"subtitle": subtitle,
				"state_id": state_id,
				"enabled": true,
				"tooltip": _build_plot_tooltip(plot_index, plot, crop_state)
			})
	return plots


func _build_restaurant_model() -> Dictionary:
	var selected_menu_ids: Array[String] = _normalize_string_id_array(_restaurant_state.get("selected_menu_recipe_ids", []))
	var recipe_lookup := _get_recipe_lookup()
	var recipe_cards := MenuPlannerClass.build_recipe_cards(
		DataRegistry.get_recipes(),
		_inventory.materials.duplicate(true),
		_inventory.unlocked_recipes,
		selected_menu_ids
	)
	var selected_menu_entries := MenuPlannerClass.build_selected_menu_entries(
		selected_menu_ids,
		recipe_lookup,
		_inventory.materials.duplicate(true)
	)
	var last_service_summary := _get_last_restaurant_service_summary()
	var bridge_info := _build_restaurant_bridge_info()
	return {
		"current_day": _day_state.current_day,
		"phase": _day_state.current_phase,
		"gold": _economy.gold,
		"reputation": _economy.restaurant_reputation,
		"action_budget": _day_state.action_budget,
		"max_action_budget": _day_state.max_action_budget,
		"ingredient_summary": _build_restaurant_ingredient_summary(),
		"ingredient_tooltip": _build_night_stock_tooltip(),
		"bridge_summary": String(bridge_info.get("summary", _t("meta.bridge.summary_none"))),
		"bridge_tooltip": String(bridge_info.get("tooltip", "")),
		"status_text": _restaurant_status_text,
		"recipe_cards": recipe_cards,
		"selected_menu_entries": selected_menu_entries,
		"menu_hint_text": _t("meta.restaurant.menu_hint", {
			"count": selected_menu_ids.size(),
			"max": RESTAURANT_MAX_MENU_SIZE
		}),
		"service_button_text": _build_restaurant_service_button_text(),
		"service_button_tooltip": _t("meta.restaurant.service_tooltip", {"value": RESTAURANT_SERVICE_ACTION_COST}),
		"service_button_enabled": _can_open_restaurant_service(),
		"clear_button_enabled": not selected_menu_ids.is_empty(),
		"result_title": _build_restaurant_result_title(last_service_summary),
		"result_summary": _build_restaurant_result_summary(last_service_summary),
		"result_feedback": _build_restaurant_feedback_text(last_service_summary),
		"sold_stats_text": _build_restaurant_sold_stats_text(last_service_summary)
	}


func _restaurant_service_completed_today() -> bool:
	return int(_restaurant_state.get("last_service_day", 0)) >= _day_state.current_day


func _get_recipe_lookup() -> Dictionary:
	var lookup: Dictionary = {}
	for recipe_variant in DataRegistry.get_recipes():
		if not (recipe_variant is Dictionary):
			continue
		var recipe: Dictionary = recipe_variant
		var recipe_id := String(recipe.get("id", "")).strip_edges().to_lower()
		if recipe_id.is_empty():
			continue
		lookup[recipe_id] = recipe.duplicate(true)
	return lookup


func _get_owned_restaurant_upgrades() -> Array:
	var owned_upgrades: Array = []
	var owned_upgrade_ids: Array[String] = _normalize_string_id_array(_restaurant_state.get("owned_upgrade_ids", []))
	for upgrade_id in owned_upgrade_ids:
		var upgrade := DataRegistry.get_restaurant_upgrade(upgrade_id)
		if upgrade.is_empty():
			continue
		owned_upgrades.append(upgrade)
	return owned_upgrades


func _maybe_unlock_restaurant_recipes() -> Array[String]:
	var unlocks: Array[String] = []
	if not DataRegistry.has_recipe("sweet_bread"):
		return unlocks
	if _economy.gold >= 24 and _inventory.unlock_recipe("sweet_bread"):
		unlocks.append(_display_recipe_name("sweet_bread"))
	elif _economy.restaurant_reputation >= 3 and _economy.get_dish_sales("field_stew") >= 1 and _inventory.unlock_recipe("sweet_bread"):
		unlocks.append(_display_recipe_name("sweet_bread"))
	return unlocks


func _build_restaurant_ingredient_summary() -> String:
	return _build_inventory_summary()


func _build_restaurant_service_button_text() -> String:
	if _restaurant_service_completed_today():
		return _t("meta.restaurant.service_closed_today")
	return _t("meta.restaurant.open_service_cost", {"value": RESTAURANT_SERVICE_ACTION_COST})


func _can_open_restaurant_service() -> bool:
	if _restaurant_service_completed_today():
		return false
	if not _day_state.can_spend_action_budget(RESTAURANT_SERVICE_ACTION_COST):
		return false
	var selected_menu_ids: Array[String] = _normalize_string_id_array(_restaurant_state.get("selected_menu_recipe_ids", []))
	if selected_menu_ids.is_empty():
		return false
	var recipe_lookup := _get_recipe_lookup()
	var total_servings := 0
	for recipe_id in selected_menu_ids:
		var recipe_variant: Variant = recipe_lookup.get(recipe_id, {})
		if not (recipe_variant is Dictionary):
			continue
		total_servings += MenuPlannerClass.max_servings(recipe_variant as Dictionary, _inventory.materials)
	return total_servings > 0


func _get_last_restaurant_service_summary() -> Dictionary:
	var summary_variant: Variant = _restaurant_state.get("last_service_summary", {})
	return (summary_variant as Dictionary).duplicate(true) if summary_variant is Dictionary else {}


func _build_restaurant_result_title(summary: Dictionary) -> String:
	if summary.is_empty():
		return _t("meta.restaurant.summary_idle_title")
	return _t("meta.restaurant.summary_title", {
		"day": maxi(1, int(summary.get("served_day", _day_state.current_day))),
		"headline": String(summary.get("headline", _t("meta.restaurant.summary_idle_title")))
	})


func _build_restaurant_result_summary(summary: Dictionary) -> String:
	if summary.is_empty():
		return _t("meta.restaurant.summary_idle")
	return _t("meta.restaurant.summary_body", {
		"served": maxi(0, int(summary.get("served_customers", 0))),
		"expected": maxi(0, int(summary.get("expected_customers", 0))),
		"revenue": maxi(0, int(summary.get("revenue", 0))),
		"tips": maxi(0, int(summary.get("tips", 0))),
		"satisfaction": clampi(int(summary.get("satisfaction_pct", 0)), 0, 100),
		"rep": _format_signed_int(int(summary.get("reputation_delta", 0))),
		"ingredients": _build_material_bundle_text(summary.get("ingredients_consumed", {}))
	})


func _build_restaurant_feedback_text(summary: Dictionary) -> String:
	if summary.is_empty():
		return _t("meta.common.none")
	var feedback_parts: Array[String] = []
	var feedback_tags_variant: Variant = summary.get("feedback_tags", [])
	if feedback_tags_variant is Array:
		for tag_variant in feedback_tags_variant:
			var text := _build_feedback_reason_text(String(tag_variant))
			if text.is_empty() or feedback_parts.has(text):
				continue
			feedback_parts.append(text)
	var synergy_feedback_variant: Variant = summary.get("synergy_feedback", [])
	if synergy_feedback_variant is Array:
		for entry_variant in synergy_feedback_variant:
			var entry_text := String(entry_variant).strip_edges()
			if entry_text.is_empty() or feedback_parts.has(entry_text):
				continue
			feedback_parts.append(entry_text)
	if feedback_parts.is_empty():
		return _t("meta.common.none")
	return _t("meta.restaurant.summary_feedback", {"value": " | ".join(feedback_parts)})


func _build_restaurant_sold_stats_text(summary: Dictionary) -> String:
	var lines: Array[String] = []
	var today_text := _build_recipe_sales_text(summary.get("sold_dishes", {}))
	if not summary.is_empty():
		lines.append(_t("meta.restaurant.summary_sold_today", {"value": today_text}))
	var lifetime_text := _build_recipe_sales_text(_economy.sold_dishes_stats)
	lines.append(_t("meta.restaurant.summary_sold_lifetime", {"value": lifetime_text}))
	return "\n".join(lines)


func _build_inventory_summary() -> String:
	var ordered_ids: Array[String] = []
	for crop_variant in DataRegistry.get_crops():
		if not (crop_variant is Dictionary):
			continue
		var crop_id := String((crop_variant as Dictionary).get("id", "")).strip_edges().to_lower()
		if crop_id.is_empty() or ordered_ids.has(crop_id):
			continue
		ordered_ids.append(crop_id)
	if not ordered_ids.has("scrap"):
		ordered_ids.append("scrap")
	var extras: Array[String] = []
	for material_id_variant in _inventory.materials.keys():
		var material_id := String(material_id_variant).strip_edges().to_lower()
		if material_id.is_empty():
			continue
		if ordered_ids.has(material_id) or extras.has(material_id):
			continue
		extras.append(material_id)
	extras.sort()
	ordered_ids.append_array(extras)
	var parts: Array[String] = []
	for material_id in ordered_ids:
		var amount := _inventory.get_material_amount(material_id)
		if amount <= 0:
			continue
		parts.append("%s x%d" % [_display_material_name(material_id), amount])
	if parts.is_empty():
		return _t("meta.common.none")
	return ", ".join(parts)


func _build_unlocked_seed_summary() -> String:
	if _inventory.unlocked_seeds.is_empty():
		return _t("meta.common.none")
	var names: Array[String] = []
	for seed_id in _inventory.unlocked_seeds:
		names.append(_display_seed_name(seed_id))
	return ", ".join(names)


func _build_unlocked_recipe_summary() -> String:
	if _inventory.unlocked_recipes.is_empty():
		return _t("meta.common.none")
	var names: Array[String] = []
	for recipe_id in _inventory.unlocked_recipes:
		names.append(_display_recipe_name(recipe_id))
	return ", ".join(names)


func _build_day_hub_bridge_info() -> Dictionary:
	var summary_lines: Array[String] = []
	var ready_recipe_rows := _get_ready_night_recipe_rows()
	for row_variant in _take_items(ready_recipe_rows, 2):
		if not (row_variant is Dictionary):
			continue
		var row: Dictionary = row_variant
		summary_lines.append(_t("meta.bridge.recipe_ready", {
			"name": String(row.get("name", _t("meta.common.none"))),
			"price": int(row.get("base_price", 0)),
			"servings": int(row.get("craftable_servings", 0))
		}))
	var progress_rows := _get_unlock_rows_with_progress()
	for row in progress_rows:
		if summary_lines.size() >= 3:
			break
		summary_lines.append(_t("meta.bridge.unlock_progress", {
			"name": String(row.get("name", _t("meta.common.none"))),
			"current": int(row.get("current", 0)),
			"required": int(row.get("required", 0)),
			"target": String(row.get("target_name", _t("meta.common.none")))
		}))
	if summary_lines.size() < 3 and _inventory.has_seed("mooncap_seed"):
		var mooncap_recipe_names := _collect_recipe_names_for_material("mooncap")
		var mooncap_use_text := ", ".join(mooncap_recipe_names) if not mooncap_recipe_names.is_empty() else _t("meta.common.none")
		var mooncap_crop := DataRegistry.get_crop("mooncap")
		summary_lines.append(_t("meta.bridge.crop_ready", {
			"name": _display_seed_name("mooncap_seed"),
			"value": int(mooncap_crop.get("sell_value", 0)),
			"uses": mooncap_use_text
		}))
	if summary_lines.is_empty():
		summary_lines.append(_t("meta.bridge.summary_none"))
	return {
		"summary": "\n".join(summary_lines),
		"tooltip": "%s\n\n%s\n\n%s" % [
			_build_night_stock_tooltip(),
			_build_seed_bridge_tooltip(),
			_build_recipe_bridge_tooltip()
		]
	}


func _build_farm_bridge_info() -> Dictionary:
	var summary_lines: Array[String] = []
	var unlock_rows := _build_current_unlock_rows()
	var mooncap_unlock := _find_unlock_row(unlock_rows, "seed", "mooncap_seed")
	if not mooncap_unlock.is_empty() and not bool(mooncap_unlock.get("complete", false)):
		summary_lines.append(_t("meta.bridge.unlock_progress", {
			"name": String(mooncap_unlock.get("name", _t("meta.common.none"))),
			"current": int(mooncap_unlock.get("current", 0)),
			"required": int(mooncap_unlock.get("required", 0)),
			"target": String(mooncap_unlock.get("target_name", _t("meta.common.none")))
		}))
	if _inventory.has_seed("mooncap_seed"):
		var crop_recipe_names := _collect_recipe_names_for_material("mooncap")
		var crop_use_text := ", ".join(crop_recipe_names) if not crop_recipe_names.is_empty() else _t("meta.common.none")
		var mooncap_crop := DataRegistry.get_crop("mooncap")
		summary_lines.append(_t("meta.bridge.crop_ready", {
			"name": _display_seed_name("mooncap_seed"),
			"value": int(mooncap_crop.get("sell_value", 0)),
			"uses": crop_use_text
		}))
	if _inventory.get_material_amount("moon_spore") > 0:
		summary_lines.append(_build_stock_line_for_material("moon_spore", _inventory.get_material_amount("moon_spore")))
	if summary_lines.is_empty():
		summary_lines.append(_t("meta.bridge.summary_none"))
	return {
		"summary": "\n".join(_take_items(summary_lines, 3)),
		"tooltip": "%s\n\n%s" % [_build_seed_bridge_tooltip(), _build_night_stock_tooltip()]
	}


func _build_restaurant_bridge_info() -> Dictionary:
	var summary_lines: Array[String] = []
	var ready_recipe_rows := _get_ready_night_recipe_rows()
	for row_variant in _take_items(ready_recipe_rows, 2):
		if not (row_variant is Dictionary):
			continue
		var row: Dictionary = row_variant
		summary_lines.append(_t("meta.bridge.recipe_ready", {
			"name": String(row.get("name", _t("meta.common.none"))),
			"price": int(row.get("base_price", 0)),
			"servings": int(row.get("craftable_servings", 0))
		}))
	if summary_lines.is_empty():
		for row in _get_unlock_rows_with_progress("recipe"):
			if summary_lines.size() >= 2:
				break
			summary_lines.append(_t("meta.bridge.unlock_progress", {
				"name": String(row.get("name", _t("meta.common.none"))),
				"current": int(row.get("current", 0)),
				"required": int(row.get("required", 0)),
				"target": String(row.get("target_name", _t("meta.common.none")))
			}))
	if summary_lines.is_empty():
		summary_lines.append(_t("meta.bridge.summary_none"))
	return {
		"summary": "\n".join(summary_lines),
		"tooltip": "%s\n\n%s" % [_build_recipe_bridge_tooltip(), _build_night_stock_tooltip()]
	}


func _build_night_stock_tooltip() -> String:
	var lines: Array[String] = [_t("meta.bridge.stock_title")]
	var has_stock := false
	for ingredient_variant in DataRegistry.get_special_ingredients():
		if not (ingredient_variant is Dictionary):
			continue
		var ingredient: Dictionary = ingredient_variant
		var material_id := String(ingredient.get("id", "")).strip_edges().to_lower()
		if material_id.is_empty() or not bool(ingredient.get("night_only", false)):
			continue
		var amount := _inventory.get_material_amount(material_id)
		if amount <= 0:
			continue
		has_stock = true
		lines.append(_build_stock_line_for_material(material_id, amount))
		var description := String(ingredient.get("description", "")).strip_edges()
		if not description.is_empty():
			lines.append(description)
	if not has_stock:
		return _t("meta.bridge.summary_none")
	return "\n".join(lines)


func _build_seed_bridge_tooltip() -> String:
	var lines: Array[String] = []
	for seed_variant in DataRegistry.get_seeds():
		if not (seed_variant is Dictionary):
			continue
		var seed: Dictionary = seed_variant
		var seed_id := String(seed.get("id", "")).strip_edges().to_lower()
		if seed_id.is_empty():
			continue
		var unlock_material_ids := _get_unlock_material_ids_for_target("seed", seed_id)
		if unlock_material_ids.is_empty():
			continue
		lines.append(_build_seed_tooltip(seed, DataRegistry.get_crop(String(seed.get("crop_id", "")))))
	if lines.is_empty():
		return _t("meta.bridge.summary_none")
	return "\n\n".join(lines)


func _build_recipe_bridge_tooltip() -> String:
	var lines: Array[String] = []
	for row in _get_night_recipe_rows():
		var recipe_id := String(row.get("id", "")).strip_edges().to_lower()
		if recipe_id.is_empty():
			continue
		if bool(row.get("locked", false)):
			var unlock_rows := _build_current_unlock_rows()
			var unlock_row := _find_unlock_row(unlock_rows, "recipe", recipe_id)
			if unlock_row.is_empty():
				continue
			lines.append(_t("meta.bridge.unlock_progress", {
				"name": String(unlock_row.get("name", _t("meta.common.none"))),
				"current": int(unlock_row.get("current", 0)),
				"required": int(unlock_row.get("required", 0)),
				"target": String(unlock_row.get("target_name", _t("meta.common.none")))
			}))
			continue
		lines.append(_t("meta.bridge.recipe_ready", {
			"name": String(row.get("name", _t("meta.common.none"))),
			"price": int(row.get("base_price", 0)),
			"servings": int(row.get("craftable_servings", 0))
		}))
		var description := String(row.get("description", "")).strip_edges()
		if not description.is_empty():
			lines.append(description)
	if lines.is_empty():
		return _t("meta.bridge.summary_none")
	return "\n".join(lines)


func _build_seed_tooltip(seed: Dictionary, crop_def: Dictionary) -> String:
	var seed_id := String(seed.get("id", "")).strip_edges().to_lower()
	var lines: Array[String] = []
	var description := String(seed.get("description", "")).strip_edges()
	if not description.is_empty():
		lines.append(description)
	var unlock_material_ids := _get_unlock_material_ids_for_target("seed", seed_id)
	if not unlock_material_ids.is_empty():
		lines.append(_t("meta.bridge.night_source", {"value": _build_material_name_list(unlock_material_ids)}))
	var unlock_row := _find_unlock_row(_build_current_unlock_rows(), "seed", seed_id)
	if not unlock_row.is_empty() and not bool(unlock_row.get("complete", false)):
		lines.append(_t("meta.bridge.unlock_line", {
			"value": "%s · %d/%d" % [
				String(unlock_row.get("name", _t("meta.common.none"))),
				int(unlock_row.get("current", 0)),
				int(unlock_row.get("required", 0))
			]
		}))
	var crop_id := String(crop_def.get("id", "")).strip_edges().to_lower()
	var crop_name := String(crop_def.get("name", _display_material_name(crop_id)))
	lines.append(_t("meta.farm.tooltip.harvest", {
		"crop": crop_name,
		"yield": int(crop_def.get("harvest_yield", 1)),
		"days": int(crop_def.get("growth_days", 1)),
		"value": int(crop_def.get("sell_value", 0))
	}))
	var crop_use_names := _collect_recipe_names_for_material(crop_id)
	if not crop_use_names.is_empty():
		lines.append(_t("meta.farm.tooltip.use", {"value": ", ".join(crop_use_names)}))
	return "\n".join(lines)


func _build_plot_tooltip(plot_index: int, plot: Dictionary, crop_state: Dictionary) -> String:
	var lines: Array[String] = [_t("meta.farm.plot_number", {"value": plot_index + 1})]
	if bool(plot.get("tilled", false)) and _crop_is_empty(crop_state):
		lines.append(_t("meta.farm.plot_tilled_hint"))
	elif not _crop_is_empty(crop_state):
		var crop_def := DataRegistry.get_crop(String(crop_state.get("crop_id", "")))
		if not crop_def.is_empty():
			var crop_description := String(crop_def.get("description", "")).strip_edges()
			if not crop_description.is_empty():
				lines.append(crop_description)
			lines.append(_t("meta.farm.tooltip.harvest", {
				"crop": _display_material_name(String(crop_state.get("crop_id", ""))),
				"yield": int(crop_def.get("harvest_yield", 1)),
				"days": int(crop_def.get("growth_days", 1)),
				"value": int(crop_def.get("sell_value", 0))
			}))
			var crop_use_names := _collect_recipe_names_for_material(String(crop_state.get("crop_id", "")))
			if not crop_use_names.is_empty():
				lines.append(_t("meta.farm.tooltip.use", {"value": ", ".join(crop_use_names)}))
		var unlock_material_ids := _get_unlock_material_ids_for_target("seed", String(crop_state.get("seed_id", "")))
		if not unlock_material_ids.is_empty():
			lines.append(_t("meta.bridge.night_source", {"value": _build_material_name_list(unlock_material_ids)}))
	return "\n".join(lines)


func _build_current_unlock_rows() -> Array[Dictionary]:
	var rows: Array[Dictionary] = []
	for unlock_variant in DataRegistry.get_meta_unlocks():
		if not (unlock_variant is Dictionary):
			continue
		var unlock_def: Dictionary = unlock_variant
		var target_type := String(unlock_def.get("target_type", "")).strip_edges().to_lower()
		var target_id := String(unlock_def.get("target_id", "")).strip_edges().to_lower()
		var requirements := _normalize_material_bundle(unlock_def.get("requirements", {}))
		if target_type.is_empty() or target_id.is_empty() or requirements.is_empty():
			continue
		var required := _required_requirement_total(requirements)
		rows.append({
			"id": String(unlock_def.get("id", "")).strip_edges().to_lower(),
			"name": String(unlock_def.get("name", "")),
			"description": String(unlock_def.get("description", "")),
			"target_type": target_type,
			"target_id": target_id,
			"target_name": _resolve_meta_target_name(target_type, target_id),
			"current": mini(required, _current_requirement_progress(requirements)),
			"required": required,
			"requirements": requirements.duplicate(true),
			"complete": _is_meta_target_unlocked(target_type, target_id)
		})
	return rows


func _get_unlock_rows_with_progress(target_type: String = "") -> Array[Dictionary]:
	var rows: Array[Dictionary] = []
	var normalized_target_type := target_type.strip_edges().to_lower()
	for row in _build_current_unlock_rows():
		if normalized_target_type != "" and String(row.get("target_type", "")) != normalized_target_type:
			continue
		if bool(row.get("complete", false)):
			continue
		if int(row.get("current", 0)) <= 0:
			continue
		rows.append(row)
	return rows


func _find_unlock_row(rows: Array, target_type: String, target_id: String) -> Dictionary:
	var normalized_target_type := target_type.strip_edges().to_lower()
	var normalized_target_id := target_id.strip_edges().to_lower()
	for row_variant in rows:
		if not (row_variant is Dictionary):
			continue
		var row: Dictionary = row_variant
		if String(row.get("target_type", "")) != normalized_target_type:
			continue
		if String(row.get("target_id", "")) != normalized_target_id:
			continue
		return row.duplicate(true)
	return {}


func _get_unlock_material_ids_for_target(target_type: String, target_id: String) -> Array[String]:
	var unlock_row := _find_unlock_row(_build_current_unlock_rows(), target_type, target_id)
	var output: Array[String] = []
	if unlock_row.is_empty():
		return output
	for material_id_variant in (unlock_row.get("requirements", {}) as Dictionary).keys():
		var material_id := String(material_id_variant).strip_edges().to_lower()
		if material_id.is_empty() or output.has(material_id):
			continue
		output.append(material_id)
	return output


func _build_stock_line_for_material(material_id: String, amount: int) -> String:
	var uses := _collect_use_names_for_material(material_id)
	if uses.is_empty():
		return _t("meta.bridge.stock_line_simple", {
			"name": _display_material_name(material_id),
			"amount": amount
		})
	return _t("meta.bridge.stock_line", {
		"name": _display_material_name(material_id),
		"amount": amount,
		"uses": ", ".join(uses)
	})


func _collect_use_names_for_material(material_id: String) -> Array[String]:
	var normalized_id := material_id.strip_edges().to_lower()
	var uses := _collect_recipe_names_for_material(normalized_id)
	for row in _build_current_unlock_rows():
		var requirements: Dictionary = row.get("requirements", {})
		if not (requirements is Dictionary):
			continue
		if not requirements.has(normalized_id):
			continue
		var unlock_use := _t("meta.bridge.use_unlock", {
			"name": String(row.get("target_name", _t("meta.common.none")))
		})
		if not uses.has(unlock_use):
			uses.append(unlock_use)
	return uses


func _collect_recipe_names_for_material(material_id: String) -> Array[String]:
	var output: Array[String] = []
	var normalized_id := material_id.strip_edges().to_lower()
	if normalized_id.is_empty():
		return output
	for recipe_variant in DataRegistry.get_recipes():
		if not (recipe_variant is Dictionary):
			continue
		var recipe: Dictionary = recipe_variant
		if not _recipe_requires_material(recipe, normalized_id):
			continue
		var recipe_name := String(recipe.get("name", normalized_id.capitalize()))
		if output.has(recipe_name):
			continue
		output.append(recipe_name)
	return output


func _recipe_requires_material(recipe: Dictionary, material_id: String) -> bool:
	var normalized_id := material_id.strip_edges().to_lower()
	if normalized_id.is_empty():
		return false
	var ingredients_variant: Variant = recipe.get("ingredients", {})
	if ingredients_variant is Dictionary:
		var ingredients: Dictionary = ingredients_variant
		if ingredients.has(normalized_id):
			return true
	var synergy_variant: Variant = recipe.get("night_material_synergy", {})
	if synergy_variant is Dictionary and String((synergy_variant as Dictionary).get("material_id", "")).strip_edges().to_lower() == normalized_id:
		return true
	return false


func _get_night_recipe_rows() -> Array[Dictionary]:
	var rows: Array[Dictionary] = []
	for recipe_variant in DataRegistry.get_recipes():
		if not (recipe_variant is Dictionary):
			continue
		var recipe: Dictionary = recipe_variant
		var recipe_id := String(recipe.get("id", "")).strip_edges().to_lower()
		if recipe_id.is_empty():
			continue
		var night_material_ids := _get_recipe_night_material_ids(recipe)
		if night_material_ids.is_empty():
			continue
		rows.append({
			"id": recipe_id,
			"name": String(recipe.get("name", recipe_id.capitalize())),
			"description": String(recipe.get("description", "")),
			"base_price": int(recipe.get("base_price", 0)),
			"craftable_servings": MenuPlannerClass.max_servings(recipe, _inventory.materials),
			"locked": not _inventory.has_recipe(recipe_id),
			"night_material_ids": night_material_ids.duplicate(),
			"night_material_text": _build_material_name_list(night_material_ids)
		})
	return rows


func _get_ready_night_recipe_rows() -> Array[Dictionary]:
	var rows: Array[Dictionary] = []
	for row in _get_night_recipe_rows():
		if bool(row.get("locked", false)):
			continue
		if int(row.get("craftable_servings", 0)) <= 0:
			continue
		rows.append(row)
	return rows


func _get_recipe_night_material_ids(recipe: Dictionary) -> Array[String]:
	var output: Array[String] = []
	var ingredients_variant: Variant = recipe.get("ingredients", {})
	if ingredients_variant is Dictionary:
		for material_id_variant in (ingredients_variant as Dictionary).keys():
			var material_id := String(material_id_variant).strip_edges().to_lower()
			if material_id.is_empty() or output.has(material_id) or not _material_is_night_only(material_id):
				continue
			output.append(material_id)
	var synergy_variant: Variant = recipe.get("night_material_synergy", {})
	if synergy_variant is Dictionary:
		var synergy_material_id := String((synergy_variant as Dictionary).get("material_id", "")).strip_edges().to_lower()
		if not synergy_material_id.is_empty() and not output.has(synergy_material_id) and _material_is_night_only(synergy_material_id):
			output.append(synergy_material_id)
	return output


func _material_is_night_only(material_id: String) -> bool:
	var ingredient := DataRegistry.get_special_ingredient(material_id.strip_edges().to_lower())
	return not ingredient.is_empty() and bool(ingredient.get("night_only", false))


func _build_material_name_list(material_ids: Array[String]) -> String:
	var names: Array[String] = []
	for material_id in material_ids:
		var normalized_id := material_id.strip_edges().to_lower()
		if normalized_id.is_empty():
			continue
		var display_name := _display_material_name(normalized_id)
		if display_name.is_empty() or names.has(display_name):
			continue
		names.append(display_name)
	return ", ".join(names)


func _normalize_material_bundle(value: Variant) -> Dictionary:
	var output: Dictionary = {}
	if not (value is Dictionary):
		return output
	for material_id_variant in (value as Dictionary).keys():
		var material_id := String(material_id_variant).strip_edges().to_lower()
		var amount := maxi(0, int((value as Dictionary).get(material_id_variant, 0)))
		if material_id.is_empty() or amount <= 0:
			continue
		output[material_id] = amount
	return output


func _current_requirement_progress(requirements: Dictionary) -> int:
	var total := 0
	for material_id_variant in requirements.keys():
		var material_id := String(material_id_variant).strip_edges().to_lower()
		var required_amount := maxi(0, int(requirements.get(material_id_variant, 0)))
		if material_id.is_empty() or required_amount <= 0:
			continue
		total += mini(required_amount, _inventory.get_material_amount(material_id))
	return total


func _required_requirement_total(requirements: Dictionary) -> int:
	var total := 0
	for amount_variant in requirements.values():
		total += maxi(0, int(amount_variant))
	return total


func _is_meta_target_unlocked(target_type: String, target_id: String) -> bool:
	match target_type.strip_edges().to_lower():
		"recipe":
			return _inventory.has_recipe(target_id)
		"seed":
			return _inventory.has_seed(target_id)
		_:
			return false


func _resolve_meta_target_name(target_type: String, target_id: String) -> String:
	match target_type.strip_edges().to_lower():
		"recipe":
			return _display_recipe_name(target_id)
		"seed":
			return _display_seed_name(target_id)
		_:
			return target_id.capitalize()


func _take_items(items: Array, max_items: int) -> Array:
	if max_items <= 0 or items.size() <= max_items:
		return items.duplicate()
	var output: Array = []
	for index in range(mini(items.size(), max_items)):
		output.append(items[index])
	return output


func _build_night_bonus_summary() -> String:
	var parts: Array[String] = []
	if _day_state.pending_night_gold_bonus > 0:
		parts.append(_t("meta.bonus.gold", {"value": _day_state.pending_night_gold_bonus}))
	if _day_state.pending_night_material_bonus > 0:
		parts.append(_t("meta.bonus.material", {"value": _day_state.pending_night_material_bonus}))
	if parts.is_empty():
		return _t("meta.common.none")
	return ", ".join(parts)


func _build_loot_summary_text(gold_reward: int, loot_categories: Array) -> String:
	var lines: Array[String] = []
	lines.append(_t("meta.summary.gold_line", {"value": gold_reward}))
	for row_variant in loot_categories:
		if not (row_variant is Dictionary):
			continue
		var row: Dictionary = row_variant
		var category_id := String(row.get("category", "")).strip_edges().to_lower()
		var items_variant: Variant = row.get("items", {})
		var items: Dictionary = items_variant if items_variant is Dictionary else {}
		var item_text := _build_material_bundle_text(items)
		if category_id.is_empty() or item_text == _t("meta.common.none"):
			continue
		lines.append(_t("meta.summary.loot_line", {
			"category": _t("meta.summary.category.%s" % category_id),
			"value": item_text
		}))
	return "\n".join(lines)


func _build_unlock_progress_text(rows: Array) -> String:
	if rows.is_empty():
		return _t("meta.common.none")
	var lines: Array[String] = []
	for row_variant in rows:
		if not (row_variant is Dictionary):
			continue
		var row: Dictionary = row_variant
		var progress_text := _t("meta.summary.progress_partial", {
			"name": String(row.get("name", _t("meta.common.none"))),
			"current": int(row.get("current", 0)),
			"required": int(row.get("required", 0)),
			"requirements": _build_unlock_requirement_text(row.get("requirements", {}))
		})
		if bool(row.get("complete", false)):
			progress_text = _t("meta.summary.progress_complete", {
				"name": String(row.get("name", _t("meta.common.none"))),
				"target": String(row.get("target_name", _t("meta.common.none")))
			})
		lines.append(progress_text)
	return "\n".join(lines)


func _build_unlock_requirement_text(requirements_variant: Variant) -> String:
	if not (requirements_variant is Dictionary):
		return _t("meta.common.none")
	return _build_material_bundle_text(requirements_variant as Dictionary)


func _build_penalty_text(penalty: Dictionary) -> String:
	if not bool(penalty.get("applied", false)):
		return _t("meta.summary.condition_none")
	var penalty_type := String(penalty.get("type", "")).strip_edges().to_lower()
	return _t("meta.summary.condition_%s" % penalty_type, {
		"value": int(penalty.get("stamina_loss", 0)),
		"next": int(penalty.get("next_day_stamina", _day_state.preview_next_day_stamina()))
	})


func _extract_unlock_names(unlocks_variant: Variant) -> Array[String]:
	var names: Array[String] = []
	if not (unlocks_variant is Array):
		return names
	for unlock_variant in unlocks_variant:
		if not (unlock_variant is Dictionary):
			continue
		var unlock_name := String((unlock_variant as Dictionary).get("name", "")).strip_edges()
		if unlock_name.is_empty() or names.has(unlock_name):
			continue
		names.append(unlock_name)
	return names


func _add_loot_category_amount(loot_categories: Array, category_id: String, material_id: String, amount: int) -> void:
	if amount <= 0:
		return
	var normalized_category := category_id.strip_edges().to_lower()
	var normalized_material := material_id.strip_edges().to_lower()
	for index in range(loot_categories.size()):
		var row_variant: Variant = loot_categories[index]
		if not (row_variant is Dictionary):
			continue
		var row: Dictionary = row_variant
		if String(row.get("category", "")).strip_edges().to_lower() != normalized_category:
			continue
		var items_variant: Variant = row.get("items", {})
		var items: Dictionary = items_variant if items_variant is Dictionary else {}
		items[normalized_material] = maxi(0, int(items.get(normalized_material, 0))) + amount
		row["items"] = items
		loot_categories[index] = row
		return
	loot_categories.append({
		"category": normalized_category,
		"items": {
			normalized_material: amount
		}
	})


func _build_material_bundle_text(bundle: Dictionary) -> String:
	var ordered_keys: Array[String] = []
	for material_id_variant in bundle.keys():
		var material_id := String(material_id_variant).strip_edges().to_lower()
		if material_id.is_empty():
			continue
		ordered_keys.append(material_id)
	ordered_keys.sort()
	var parts: Array[String] = []
	for material_id in ordered_keys:
		var amount := int(bundle.get(material_id, 0))
		if amount <= 0:
			continue
		parts.append("%s x%d" % [_display_material_name(material_id), amount])
	if parts.is_empty():
		return _t("meta.common.none")
	return ", ".join(parts)


func _build_recipe_bonus_text(recipe: Dictionary) -> String:
	var parts: Array[String] = []
	var gold_bonus := int(recipe.get("night_gold_bonus", 0))
	var material_bonus := int(recipe.get("night_material_bonus", 0))
	if gold_bonus > 0:
		parts.append(_t("meta.bonus.gold", {"value": gold_bonus}))
	if material_bonus > 0:
		parts.append(_t("meta.bonus.material", {"value": material_bonus}))
	if parts.is_empty():
		return _t("meta.common.none")
	return ", ".join(parts)


func _display_material_name(material_id: String) -> String:
	var normalized_id := material_id.strip_edges().to_lower()
	if normalized_id.is_empty():
		return ""
	if DataRegistry != null and DataRegistry.has_method("get_material_display_name"):
		var material_name := String(DataRegistry.call("get_material_display_name", normalized_id))
		if not material_name.is_empty():
			return material_name
	var crop_def := DataRegistry.get_crop(normalized_id)
	if not crop_def.is_empty():
		return String(crop_def.get("name", normalized_id.capitalize()))
	return String(MATERIAL_DISPLAY_NAMES.get(normalized_id, normalized_id.capitalize()))


func _display_seed_name(seed_id: String) -> String:
	var seed_def := DataRegistry.get_seed(seed_id.strip_edges().to_lower())
	if not seed_def.is_empty():
		return String(seed_def.get("name", seed_id.capitalize()))
	return seed_id.capitalize()


func _display_recipe_name(recipe_id: String) -> String:
	var recipe_def := DataRegistry.get_recipe(recipe_id.strip_edges().to_lower())
	if not recipe_def.is_empty():
		return String(recipe_def.get("name", recipe_id.capitalize()))
	return recipe_id.capitalize()


func _build_recipe_sales_text(sold_dishes_variant: Variant) -> String:
	if not (sold_dishes_variant is Dictionary):
		return _t("meta.common.none")
	var sold_dishes: Dictionary = sold_dishes_variant
	if sold_dishes.is_empty():
		return _t("meta.common.none")
	var ordered_recipe_ids: Array[String] = []
	for recipe_id_variant in sold_dishes.keys():
		var recipe_id := String(recipe_id_variant).strip_edges().to_lower()
		if recipe_id.is_empty():
			continue
		ordered_recipe_ids.append(recipe_id)
	ordered_recipe_ids.sort()
	var parts: Array[String] = []
	for recipe_id in ordered_recipe_ids:
		var count := maxi(0, int(sold_dishes.get(recipe_id, 0)))
		if count <= 0:
			continue
		parts.append("%s x%d" % [_display_recipe_name(recipe_id), count])
	if parts.is_empty():
		return _t("meta.common.none")
	return ", ".join(parts)


func _build_feedback_reason_text(tag: String) -> String:
	var normalized_tag := tag.strip_edges().to_lower()
	if normalized_tag.is_empty():
		return ""
	var key := "meta.restaurant.feedback.%s" % normalized_tag
	var text := _t(key)
	if text == key:
		return normalized_tag.replace("_", " ").capitalize()
	return text


func _get_farm_plots() -> Array:
	var plots_variant: Variant = _farm_state.get("plots", [])
	return (plots_variant as Array).duplicate(true) if plots_variant is Array else []


func _format_time(total_seconds: float) -> String:
	var total := maxi(0, int(floor(total_seconds)))
	var minutes := total / 60
	var seconds := total % 60
	return "%02d:%02d" % [minutes, seconds]


func _format_signed_int(value: int) -> String:
	if value > 0:
		return "+%d" % value
	return str(value)


func _t(key: String, args: Dictionary = {}) -> String:
	if Localization == null or not Localization.has_method("t"):
		return key
	return String(Localization.call("t", key, args))


func _normalize_string_id_array(source: Variant) -> Array[String]:
	var output: Array[String] = []
	if not (source is Array):
		return output
	for item in (source as Array):
		var text := String(item).strip_edges().to_lower()
		if text.is_empty() or output.has(text):
			continue
		output.append(text)
	return output


func debug_press_play() -> void:
	_on_play_requested()


func debug_open_farm() -> void:
	_on_day_hub_farm_requested()


func debug_open_restaurant() -> void:
	_on_day_hub_restaurant_requested()


func debug_return_to_hub() -> void:
	_show_state(STATE_DAY_HUB)


func debug_select_farm_tool(action_id: String, seed_id: String = "") -> Dictionary:
	return {
		"action_id": action_id.strip_edges().to_lower(),
		"seed_id": seed_id.strip_edges().to_lower()
	}


func debug_apply_farm_action(action_id: String) -> bool:
	var normalized := action_id.strip_edges().to_lower()
	if normalized == FARM_ACTION_TILL:
		return _apply_farm_plot_action(0, FARM_ACTION_TILL, "")
	if normalized == FARM_ACTION_WATER:
		return _apply_farm_plot_action(0, FARM_ACTION_WATER, "")
	if normalized == FARM_ACTION_HARVEST:
		return _apply_farm_plot_action(0, FARM_ACTION_HARVEST, "")
	if DataRegistry.has_seed(normalized):
		for plot_index in range(_get_farm_plots().size()):
			var plot_variant: Variant = _get_farm_plots()[plot_index]
			var plot: Dictionary = plot_variant if plot_variant is Dictionary else _build_empty_plot()
			if not bool(plot.get("tilled", false)):
				if not _apply_farm_plot_action(plot_index, FARM_ACTION_TILL, ""):
					return false
				return _apply_farm_plot_action(plot_index, "plant", normalized)
		return false
	return false


func debug_interact_farm_plot(plot_index: int, action_id: String, seed_id: String = "") -> bool:
	return _apply_farm_plot_action(plot_index, action_id, seed_id)


func debug_apply_recipe(recipe_id: String) -> bool:
	return _toggle_restaurant_recipe(recipe_id)


func debug_toggle_restaurant_recipe(recipe_id: String) -> bool:
	return _toggle_restaurant_recipe(recipe_id)


func debug_open_restaurant_service() -> bool:
	return _open_restaurant_service()


func debug_wait_until_evening() -> bool:
	return _wait_until_evening()


func debug_launch_night() -> bool:
	return _launch_night()


func debug_complete_active_night(summary_override: Dictionary = {}) -> void:
	if night_combat_root != null and night_combat_root.has_method("debug_complete_session"):
		night_combat_root.call("debug_complete_session", summary_override)


func debug_continue_summary() -> void:
	_on_return_summary_continue_requested()


func debug_get_snapshot() -> Dictionary:
	var day_hub_model := _build_day_hub_model()
	var farm_model := _build_farm_model()
	var restaurant_model := _build_restaurant_model()
	var farm_plots: Array[Dictionary] = []
	for plot_variant in _get_farm_plots():
		var plot: Dictionary = plot_variant if plot_variant is Dictionary else _build_empty_plot()
		var crop_state: Dictionary = _crop_from_dict(plot.get("crop", {}))
		farm_plots.append({
			"tilled": bool(plot.get("tilled", false)),
			"crop_id": String(crop_state.get("crop_id", "")),
			"seed_id": String(crop_state.get("seed_id", "")),
			"growth_progress_days": int(crop_state.get("growth_progress_days", 0)),
			"growth_days": int(crop_state.get("growth_days", 0)),
			"watered_day": int(crop_state.get("watered_day", 0)),
			"harvestable": _crop_is_harvestable(crop_state)
		})
	return {
		"current_screen": _current_state,
		"current_day": _day_state.current_day,
		"phase": _day_state.current_phase,
		"gold": _economy.gold,
		"reputation": _economy.restaurant_reputation,
		"stamina": _day_state.stamina,
		"max_stamina": _day_state.max_stamina,
		"action_budget": _day_state.action_budget,
		"max_action_budget": _day_state.max_action_budget,
		"pending_next_day_stamina_penalty": _day_state.pending_next_day_stamina_penalty,
		"next_day_stamina_preview": _day_state.preview_next_day_stamina(),
		"inventory_summary": _build_inventory_summary(),
		"inventory_materials": _inventory.materials.duplicate(true),
		"unlocked_seed_ids": _inventory.unlocked_seeds.duplicate(),
		"unlocked_recipe_ids": _inventory.unlocked_recipes.duplicate(),
		"seed_summary": _build_unlocked_seed_summary(),
		"recipe_summary": _build_unlocked_recipe_summary(),
		"day_hub_status_text": String(day_hub_model.get("status_text", "")),
		"night_button_disabled": bool(day_hub_model.get("night_button_disabled", false)),
		"wait_button_disabled": bool(day_hub_model.get("wait_button_disabled", false)),
		"day_hub_bridge_summary": String(day_hub_model.get("bridge_summary", "")),
		"day_hub_bridge_tooltip": String(day_hub_model.get("bridge_tooltip", "")),
		"pending_summary": not _pending_return_summary.is_empty(),
		"return_summary_payload": _pending_return_summary.duplicate(true),
		"night_active": night_combat_root.is_session_active() if night_combat_root != null else false,
		"farm_status_text": _farm_status_text,
		"farm_bridge_summary": String(farm_model.get("bridge_summary", "")),
		"farm_bridge_tooltip": String(farm_model.get("bridge_tooltip", "")),
		"farm_tools": (farm_model.get("tools", []) as Array).duplicate(true) if farm_model.get("tools", []) is Array else [],
		"farm_plots": farm_plots,
		"sold_dishes_stats": _economy.sold_dishes_stats.duplicate(true),
		"restaurant_status_text": _restaurant_status_text,
		"restaurant_bridge_summary": String(restaurant_model.get("bridge_summary", "")),
		"restaurant_bridge_tooltip": String(restaurant_model.get("bridge_tooltip", "")),
		"restaurant_recipe_cards": (restaurant_model.get("recipe_cards", []) as Array).duplicate(true) if restaurant_model.get("recipe_cards", []) is Array else [],
		"restaurant_menu_ids": _normalize_string_id_array(_restaurant_state.get("selected_menu_recipe_ids", [])),
		"restaurant_last_service_day": int(_restaurant_state.get("last_service_day", 0)),
		"restaurant_last_service_summary": _get_last_restaurant_service_summary(),
		"restaurant_service_button_enabled": bool(restaurant_model.get("service_button_enabled", false)),
		"restaurant_result_title": String(restaurant_model.get("result_title", "")),
		"restaurant_result_summary": String(restaurant_model.get("result_summary", "")),
		"restaurant_feedback_text": String(restaurant_model.get("result_feedback", "")),
		"restaurant_sold_stats_text": String(restaurant_model.get("sold_stats_text", ""))
	}
