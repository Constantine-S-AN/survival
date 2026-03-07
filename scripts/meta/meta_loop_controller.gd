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

const DayStateClass := preload("res://scripts/meta/day_state.gd")
const InventoryStateClass := preload("res://scripts/meta/inventory.gd")
const EconomyStateClass := preload("res://scripts/meta/economy_state.gd")
const RECIPE_ACTIONS: Dictionary = {
	"field_stew": {
		"stamina_cost": 1,
		"ingredients": {
			"wheat": 2
		},
		"night_gold_bonus": 6,
		"night_material_bonus": 0
	},
	"sweet_bread": {
		"stamina_cost": 1,
		"ingredients": {
			"wheat": 2,
			"herb": 1
		},
		"night_gold_bonus": 3,
		"night_material_bonus": 2
	}
}

const MATERIAL_DISPLAY_NAMES: Dictionary = {
	"scrap": "Scrap"
}

const RECIPE_DISPLAY_NAMES: Dictionary = {
	"field_stew": "Field Stew",
	"sweet_bread": "Sweet Bread"
}

@onready var main_menu: MainMenuView = $MainMenu
@onready var day_hub: DayHubView = $DayHub
@onready var farm_view: Control = $Farm
@onready var restaurant_view: RestaurantView = $Restaurant
@onready var return_summary_view: ReturnSummaryView = $ReturnSummary
@onready var night_combat_root: NightCombatRoot = $NightCombatRoot

var _day_state = DayStateClass.new()
var _inventory = InventoryStateClass.new()
var _economy = EconomyStateClass.new()
var _farm_state: Dictionary = {}
var _pending_return_summary: Dictionary = {}
var _current_state: String = STATE_MENU
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
		day_hub.night_requested.connect(_on_day_hub_night_requested)
		day_hub.menu_requested.connect(_on_menu_requested)
	if farm_view != null:
		farm_view.plot_action_requested.connect(_on_farm_plot_action_requested)
		farm_view.back_requested.connect(_on_farm_back_requested)
	if restaurant_view != null:
		restaurant_view.recipe_requested.connect(_on_recipe_requested)
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
	var summary_variant: Variant = snapshot.get("pending_return_summary", {})
	_pending_return_summary = (summary_variant as Dictionary).duplicate(true) if summary_variant is Dictionary else {}
	if _day_state.current_phase == DayStateClass.PHASE_NIGHT and _pending_return_summary.is_empty():
		_day_state.current_phase = DayStateClass.PHASE_DAY
		_save_meta_progress()


func _save_meta_progress() -> void:
	if ProfileStore == null or not ProfileStore.has_method("set_meta_progress_state"):
		return
	ProfileStore.set_meta_progress_state({
		"schema_version": 2,
		"day_state": _day_state.to_dict(),
		"economy": _economy.to_dict(),
		"inventory": _inventory.to_dict(),
		"farm_state": _farm_state.duplicate(true),
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


func _on_day_hub_night_requested() -> void:
	_launch_night()


func _on_farm_back_requested() -> void:
	_show_state(STATE_DAY_HUB)


func _on_restaurant_back_requested() -> void:
	_show_state(STATE_DAY_HUB)


func _on_farm_plot_action_requested(plot_index: int, action_id: String, seed_id: String) -> void:
	_apply_farm_plot_action(plot_index, action_id, seed_id)


func _on_recipe_requested(recipe_id: String) -> void:
	_apply_recipe_action(recipe_id)


func _launch_night() -> void:
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
	_farm_status_text = ""
	_restaurant_status_text = ""
	_save_meta_progress()
	_refresh_views()
	_show_state(STATE_NIGHT)
	night_combat_root.start_session(request)


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


func _apply_till_action(plot_index: int, plot: Dictionary, plots: Array) -> bool:
	var crop_state: Dictionary = _crop_from_dict(plot.get("crop", {}))
	if bool(plot.get("tilled", false)) or not _crop_is_empty(crop_state):
		_farm_status_text = _t("meta.farm.status_tilled")
		return false
	if not _day_state.spend_stamina(FARM_TILL_STAMINA_COST):
		_farm_status_text = _t("meta.common.no_stamina")
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
	if not _day_state.spend_stamina(plant_cost):
		_farm_status_text = _t("meta.common.no_stamina")
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
	if not _day_state.spend_stamina(FARM_WATER_STAMINA_COST):
		_farm_status_text = _t("meta.common.no_stamina")
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


func _apply_recipe_action(recipe_id: String) -> bool:
	var recipe_variant: Variant = RECIPE_ACTIONS.get(recipe_id, {})
	if not (recipe_variant is Dictionary):
		_restaurant_status_text = _t("meta.restaurant.status_invalid")
		_refresh_views()
		return false
	if not _inventory.has_recipe(recipe_id):
		_restaurant_status_text = _t("meta.restaurant.status_locked", {"value": _display_recipe_name(recipe_id)})
		_refresh_views()
		return false
	var recipe: Dictionary = recipe_variant
	var stamina_cost := maxi(0, int(recipe.get("stamina_cost", 1)))
	if not _day_state.can_spend_stamina(stamina_cost):
		_restaurant_status_text = _t("meta.common.no_stamina")
		_refresh_views()
		return false
	var ingredients_variant: Variant = recipe.get("ingredients", {})
	var ingredients: Dictionary = ingredients_variant if ingredients_variant is Dictionary else {}
	if not _has_material_bundle(ingredients):
		_restaurant_status_text = _t("meta.restaurant.status_ingredients", {"value": _build_material_bundle_text(ingredients)})
		_refresh_views()
		return false
	for material_id_variant in ingredients.keys():
		_inventory.remove_material(String(material_id_variant), int(ingredients.get(material_id_variant, 0)))
	_day_state.spend_stamina(stamina_cost)
	_day_state.add_night_gold_bonus(int(recipe.get("night_gold_bonus", 0)))
	_day_state.add_night_material_bonus(int(recipe.get("night_material_bonus", 0)))
	_restaurant_status_text = _t("meta.restaurant.status_bonus", {"value": _build_night_bonus_summary()})
	_save_meta_progress()
	_refresh_views()
	return true


func _apply_night_rewards(summary: Dictionary) -> Dictionary:
	var exit_reason := String(summary.get("exit_reason", "completed")).strip_edges().to_lower()
	if exit_reason != "abandoned":
		exit_reason = "completed"
	var kills := maxi(0, int(summary.get("kills", 0)))
	var time_survived := maxf(0.0, float(summary.get("time_survived_sec", 0.0)))
	var drop_pickups := maxi(0, int(summary.get("drop_pickups_spawned", 0)))
	var base_gold: int = maxi(2, int(floor(time_survived / 45.0)) + int(floor(float(kills) / 6.0)) + _day_state.current_day)
	if exit_reason == "abandoned":
		base_gold = maxi(1, int(floor(float(base_gold) * 0.5)))
	var material_bundle: Dictionary = {
		"scrap": maxi(0, int(floor(time_survived / 60.0)) + int(floor(float(drop_pickups) / 2.0)) + _day_state.pending_night_material_bonus)
	}
	if exit_reason != "abandoned" and kills >= 18:
		material_bundle["wheat"] = 1
	var gold_reward: int = base_gold + _day_state.pending_night_gold_bonus
	_economy.add_gold(gold_reward)
	_apply_material_bundle(material_bundle)

	var unlocks: Array[String] = []
	if _economy.gold >= 24 and _inventory.unlock_recipe("sweet_bread"):
		unlocks.append(_display_recipe_name("sweet_bread"))

	return {
		"current_day": _day_state.current_day,
		"next_day": _day_state.current_day + 1,
		"exit_reason": exit_reason,
		"time_text": _format_time(time_survived),
		"kills": kills,
		"seed": int(summary.get("seed", 0)),
		"gold_reward": gold_reward,
		"materials_reward": material_bundle.duplicate(true),
		"materials_reward_text": _build_material_bundle_text(material_bundle),
		"night_bonus_text": _build_night_bonus_summary(),
		"inventory_summary": _build_inventory_summary(),
		"unlock_text": ", ".join(unlocks) if not unlocks.is_empty() else _t("meta.common.none"),
		"raw_summary": summary.duplicate(true)
	}


func _apply_material_bundle(bundle: Dictionary) -> void:
	for material_id_variant in bundle.keys():
		var amount := int(bundle.get(material_id_variant, 0))
		if amount <= 0:
			continue
		_inventory.add_material(String(material_id_variant), amount)


func _has_material_bundle(bundle: Dictionary) -> bool:
	for material_id_variant in bundle.keys():
		if _inventory.get_material_amount(String(material_id_variant)) < int(bundle.get(material_id_variant, 0)):
			return false
	return true


func _build_day_hub_model() -> Dictionary:
	return {
		"current_day": _day_state.current_day,
		"gold": _economy.gold,
		"stamina": _day_state.stamina,
		"max_stamina": _day_state.max_stamina,
		"phase": _day_state.current_phase,
		"inventory_summary": _build_inventory_summary(),
		"seed_summary": _build_unlocked_seed_summary(),
		"recipe_summary": _build_unlocked_recipe_summary(),
		"night_bonus_summary": _build_night_bonus_summary(),
		"night_button_disabled": false
	}


func _build_farm_model() -> Dictionary:
	return {
		"current_day": _day_state.current_day,
		"stamina": _day_state.stamina,
		"max_stamina": _day_state.max_stamina,
		"inventory_summary": _build_inventory_summary(),
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
			"enabled": _day_state.can_spend_stamina(FARM_TILL_STAMINA_COST)
		},
		{
			"id": FARM_ACTION_WATER,
			"seed_id": "",
			"label": _t("meta.farm.tool_water"),
			"enabled": _day_state.can_spend_stamina(FARM_WATER_STAMINA_COST)
		},
		{
			"id": FARM_ACTION_HARVEST,
			"seed_id": "",
			"label": _t("meta.farm.tool_harvest"),
			"enabled": true
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
		var label := _display_seed_name(seed_id)
		if _inventory.has_seed(seed_id):
			label += "\n%s" % _t("meta.farm.tool_seed_detail", {
				"days": growth_days,
				"cost": plant_cost
			})
		else:
			label += "\n%s" % _t("meta.farm.action_locked")
		tools.append({
			"id": "plant",
			"seed_id": seed_id,
			"label": label,
			"enabled": _inventory.has_seed(seed_id) and _day_state.can_spend_stamina(plant_cost)
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
			"tooltip": _t("meta.farm.plot_number", {"value": plot_index + 1})
		})
	return plots


func _build_restaurant_model() -> Dictionary:
	var recipes: Array[Dictionary] = []
	for recipe_id in ["field_stew", "sweet_bread"]:
		var recipe_variant: Variant = RECIPE_ACTIONS.get(recipe_id, {})
		var recipe: Dictionary = recipe_variant if recipe_variant is Dictionary else {}
		var unlocked := _inventory.has_recipe(recipe_id)
		var stamina_cost := int(recipe.get("stamina_cost", 1))
		var ingredients: Dictionary = recipe.get("ingredients", {})
		var label := _display_recipe_name(recipe_id)
		if unlocked:
			label += "\n%s" % _t("meta.restaurant.recipe_detail", {
				"ingredients": _build_material_bundle_text(ingredients),
				"cost": stamina_cost,
				"bonus": _build_recipe_bonus_text(recipe)
			})
		else:
			label += "\n%s" % _t("meta.restaurant.recipe_locked")
		recipes.append({
			"id": recipe_id,
			"label": label,
			"enabled": unlocked and _day_state.can_spend_stamina(stamina_cost) and _has_material_bundle(ingredients)
		})
	return {
		"current_day": _day_state.current_day,
		"stamina": _day_state.stamina,
		"max_stamina": _day_state.max_stamina,
		"inventory_summary": _build_inventory_summary(),
		"status_text": _restaurant_status_text,
		"recipes": recipes
	}


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


func _build_night_bonus_summary() -> String:
	var parts: Array[String] = []
	if _day_state.pending_night_gold_bonus > 0:
		parts.append(_t("meta.bonus.gold", {"value": _day_state.pending_night_gold_bonus}))
	if _day_state.pending_night_material_bonus > 0:
		parts.append(_t("meta.bonus.material", {"value": _day_state.pending_night_material_bonus}))
	if parts.is_empty():
		return _t("meta.common.none")
	return ", ".join(parts)


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
	return String(RECIPE_DISPLAY_NAMES.get(recipe_id, recipe_id.capitalize()))


func _get_farm_plots() -> Array:
	var plots_variant: Variant = _farm_state.get("plots", [])
	return (plots_variant as Array).duplicate(true) if plots_variant is Array else []


func _format_time(total_seconds: float) -> String:
	var total := maxi(0, int(floor(total_seconds)))
	var minutes := total / 60
	var seconds := total % 60
	return "%02d:%02d" % [minutes, seconds]


func _t(key: String, args: Dictionary = {}) -> String:
	if Localization == null or not Localization.has_method("t"):
		return key
	return String(Localization.call("t", key, args))


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
	return _apply_recipe_action(recipe_id)


func debug_launch_night() -> void:
	_launch_night()


func debug_complete_active_night(summary_override: Dictionary = {}) -> void:
	if night_combat_root != null and night_combat_root.has_method("debug_complete_session"):
		night_combat_root.call("debug_complete_session", summary_override)


func debug_continue_summary() -> void:
	_on_return_summary_continue_requested()


func debug_get_snapshot() -> Dictionary:
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
		"stamina": _day_state.stamina,
		"max_stamina": _day_state.max_stamina,
		"inventory_summary": _build_inventory_summary(),
		"seed_summary": _build_unlocked_seed_summary(),
		"recipe_summary": _build_unlocked_recipe_summary(),
		"pending_summary": not _pending_return_summary.is_empty(),
		"night_active": night_combat_root.is_session_active() if night_combat_root != null else false,
		"farm_status_text": _farm_status_text,
		"farm_plots": farm_plots
	}
