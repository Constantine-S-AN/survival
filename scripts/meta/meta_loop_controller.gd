extends Node
class_name MetaLoopController

const STATE_MENU := "menu"
const STATE_DAY_HUB := "day_hub"
const STATE_FARM := "farm"
const STATE_RESTAURANT := "restaurant"
const STATE_NIGHT := "night"
const STATE_RETURN_SUMMARY := "return_summary"

const DayStateClass := preload("res://scripts/meta/day_state.gd")
const InventoryStateClass := preload("res://scripts/meta/inventory.gd")
const EconomyStateClass := preload("res://scripts/meta/economy_state.gd")

const FARM_ACTIONS: Dictionary = {
	"wheat_seed": {
		"stamina_cost": 1,
		"yield": {
			"wheat": 2
		}
	},
	"herb_seed": {
		"stamina_cost": 1,
		"yield": {
			"herb": 1
		}
	}
}

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
			"wheat": 3
		},
		"night_gold_bonus": 0,
		"night_material_bonus": 2
	}
}

const MATERIAL_DISPLAY_NAMES: Dictionary = {
	"wheat": "Wheat",
	"herb": "Herb",
	"scrap": "Scrap"
}

const SEED_DISPLAY_NAMES: Dictionary = {
	"wheat_seed": "Wheat Bed",
	"herb_seed": "Herb Patch"
}

const RECIPE_DISPLAY_NAMES: Dictionary = {
	"field_stew": "Field Stew",
	"sweet_bread": "Sweet Bread"
}

@onready var main_menu: MainMenuView = $MainMenu
@onready var day_hub: DayHubView = $DayHub
@onready var farm_view: FarmView = $Farm
@onready var restaurant_view: RestaurantView = $Restaurant
@onready var return_summary_view: ReturnSummaryView = $ReturnSummary
@onready var night_combat_root: NightCombatRoot = $NightCombatRoot

var _day_state = DayStateClass.new()
var _inventory = InventoryStateClass.new()
var _economy = EconomyStateClass.new()
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
		farm_view.action_requested.connect(_on_farm_action_requested)
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
	var summary_variant: Variant = snapshot.get("pending_return_summary", {})
	_pending_return_summary = (summary_variant as Dictionary).duplicate(true) if summary_variant is Dictionary else {}
	if _day_state.current_phase == DayStateClass.PHASE_NIGHT and _pending_return_summary.is_empty():
		_day_state.current_phase = DayStateClass.PHASE_DAY
		_save_meta_progress()


func _save_meta_progress() -> void:
	if ProfileStore == null or not ProfileStore.has_method("set_meta_progress_state"):
		return
	ProfileStore.set_meta_progress_state({
		"schema_version": 1,
		"day_state": _day_state.to_dict(),
		"economy": _economy.to_dict(),
		"inventory": _inventory.to_dict(),
		"pending_return_summary": _pending_return_summary.duplicate(true)
	})


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


func _on_farm_action_requested(action_id: String) -> void:
	_apply_farm_action(action_id)


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
	_day_state.begin_next_day()
	_pending_return_summary.clear()
	_farm_status_text = ""
	_restaurant_status_text = ""
	_save_meta_progress()
	_refresh_views()
	_show_state(STATE_DAY_HUB)


func _apply_farm_action(action_id: String) -> bool:
	var action_variant: Variant = FARM_ACTIONS.get(action_id, {})
	if not (action_variant is Dictionary):
		_farm_status_text = _t("meta.farm.status_invalid")
		_refresh_views()
		return false
	if not _inventory.has_seed(action_id):
		_farm_status_text = _t("meta.farm.status_locked", {"value": _display_seed_name(action_id)})
		_refresh_views()
		return false
	var action: Dictionary = action_variant
	var stamina_cost := maxi(0, int(action.get("stamina_cost", 1)))
	if not _day_state.spend_stamina(stamina_cost):
		_farm_status_text = _t("meta.common.no_stamina")
		_refresh_views()
		return false
	var yield_bundle: Dictionary = action.get("yield", {})
	for material_id_variant in yield_bundle.keys():
		var material_id := String(material_id_variant)
		_inventory.add_material(material_id, int(yield_bundle.get(material_id_variant, 0)))
	_farm_status_text = _t("meta.farm.status_gain", {"value": _build_material_bundle_text(yield_bundle)})
	_save_meta_progress()
	_refresh_views()
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
	if exit_reason != "abandoned" and _inventory.unlock_seed("herb_seed"):
		unlocks.append(_display_seed_name("herb_seed"))
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
	var actions: Array[Dictionary] = []
	for seed_id in ["wheat_seed", "herb_seed"]:
		var action_variant: Variant = FARM_ACTIONS.get(seed_id, {})
		var action: Dictionary = action_variant if action_variant is Dictionary else {}
		var unlocked := _inventory.has_seed(seed_id)
		var stamina_cost := int(action.get("stamina_cost", 1))
		var yield_bundle: Dictionary = action.get("yield", {})
		var label := _display_seed_name(seed_id)
		if unlocked:
			label += "\n%s" % _t("meta.farm.action_detail", {
				"yield": _build_material_bundle_text(yield_bundle),
				"cost": stamina_cost
			})
		else:
			label += "\n%s" % _t("meta.farm.action_locked")
		actions.append({
			"id": seed_id,
			"label": label,
			"enabled": unlocked and _day_state.can_spend_stamina(stamina_cost)
		})
	return {
		"current_day": _day_state.current_day,
		"stamina": _day_state.stamina,
		"max_stamina": _day_state.max_stamina,
		"inventory_summary": _build_inventory_summary(),
		"status_text": _farm_status_text,
		"actions": actions
	}


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
	var ordered_ids := ["wheat", "herb", "scrap"]
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
	var parts: Array[String] = []
	for material_id_variant in bundle.keys():
		var material_id := String(material_id_variant)
		var amount := int(bundle.get(material_id_variant, 0))
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
	return String(MATERIAL_DISPLAY_NAMES.get(material_id, material_id.capitalize()))


func _display_seed_name(seed_id: String) -> String:
	return String(SEED_DISPLAY_NAMES.get(seed_id, seed_id.capitalize()))


func _display_recipe_name(recipe_id: String) -> String:
	return String(RECIPE_DISPLAY_NAMES.get(recipe_id, recipe_id.capitalize()))


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


func debug_apply_farm_action(action_id: String) -> bool:
	return _apply_farm_action(action_id)


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
		"night_active": night_combat_root.is_session_active() if night_combat_root != null else false
	}
