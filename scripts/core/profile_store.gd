extends Node

signal language_code_changed(language_code: String)

const PROFILE_PATH := "user://profile.json"
const PROFILE_TMP_PATH := "user://profile.json.tmp"
const PROFILE_SCHEMA_VERSION := 7
const TEST_SESSION_META_KEY := "profile_store_test_session_id"
const DEFAULT_LANGUAGE_CODE := "en"
const DayClockClass := preload("res://scripts/meta/day_clock.gd")

const DEFAULT_PROGRESS: Dictionary = {
	"total_kills": 0,
	"pickups_collected": 0,
	"elite_or_pursuer_kills": 0,
	"best_survive_time_seconds": 0.0,
	"best_max_noise_reached": 0.0,
	"reached_noise_tiers": [],
	"meta_currency_total": 0
}

const DEFAULT_DIALOGUE_STATE: Dictionary = {
	"seen_dialogue_ids": []
}

const DEFAULT_DAILY_ORDERS_STATE: Dictionary = {
	"current_day": 0,
	"pool_state": {
		"available": [],
		"active": [],
		"completed": []
	},
	"serialized_quests": {},
	"tracked_dish_sales": {},
	"tracked_materials": {}
}

const DEFAULT_META_PROGRESS: Dictionary = {
	"schema_version": 5,
	"day_state": {
		"current_day": 1,
		"current_phase": DayClockClass.PHASE_MORNING,
		"stamina": 6,
		"max_stamina": 6,
		"action_budget": DayClockClass.DEFAULT_MAX_ACTION_BUDGET,
		"max_action_budget": DayClockClass.DEFAULT_MAX_ACTION_BUDGET,
		"pending_night_gold_bonus": 0,
		"pending_night_material_bonus": 0,
		"pending_next_day_stamina_penalty": 0
	},
	"economy": {
		"gold": 12,
		"restaurant_reputation": 1,
		"sold_dishes_stats": {}
	},
	"inventory": {
		"materials": {
			"wheat": 2,
			"herb": 1,
			"scrap": 0
		},
		"unlocked_seeds": ["wheat_seed", "herb_seed"],
		"unlocked_recipes": [
			"field_stew",
			"herb_tea",
			"kelpfire_noodles",
			"kelpberry_tart",
			"emberleaf_flatbread"
		]
	},
	"farm_state": {
		"columns": 3,
		"rows": 2,
		"plots": [
			{"tilled": false, "crop": {}},
			{"tilled": false, "crop": {}},
			{"tilled": false, "crop": {}},
			{"tilled": false, "crop": {}},
			{"tilled": false, "crop": {}},
			{"tilled": false, "crop": {}}
		]
	},
	"restaurant_state": {
		"selected_menu_recipe_ids": [],
		"last_service_day": 0,
		"last_service_summary": {},
		"owned_upgrade_ids": []
	},
	"day_world_state": {
		"pickup_day": 1,
		"collected_pickup_ids": []
	},
	"pending_return_summary": {}
}

var profile: Dictionary = {}
var loaded: bool = false
var _profile_path_override: String = ""
var _profile_tmp_path_override: String = ""
var _active_test_session_id: String = ""


func _ready() -> void:
	_maybe_enable_auto_test_session()
	var default_character_id := DataRegistry.get_default_character_id()
	var default_map_id := DataRegistry.get_default_map_id()
	load_profile(
		default_character_id if not default_character_id.is_empty() else "diver",
		default_map_id
	)


func load_profile(default_character_id: String, default_map_id: String = "") -> Dictionary:
	var profile_path := _resolve_profile_path()
	var backup_path := _resolve_profile_backup_path(profile_path)
	var raw_profile: Dictionary = _load_profile_payload(profile_path, backup_path)
	profile = _migrate_profile(raw_profile, default_character_id, default_map_id)
	loaded = true
	save_profile()
	return get_profile()


func get_profile() -> Dictionary:
	return profile.duplicate(true)


func get_schema_version() -> int:
	return int(profile.get("schema_version", 0))


func get_selected_character_id(fallback_default: String) -> String:
	var selected := String(profile.get("last_selected_character_id", fallback_default))
	if selected.is_empty():
		return fallback_default
	return selected


func set_selected_character_id(character_id: String) -> void:
	if character_id.is_empty():
		return
	profile["last_selected_character_id"] = character_id
	save_profile()


func get_selected_map_id(fallback_default: String) -> String:
	var selected := String(profile.get("last_selected_map_id", fallback_default))
	if selected.is_empty():
		return fallback_default
	return selected


func set_selected_map_id(map_id: String) -> void:
	if map_id.is_empty():
		return
	profile["last_selected_map_id"] = map_id
	save_profile()


func get_selected_contract_ids() -> Array[String]:
	return _normalize_string_array(profile.get("last_selected_contract_ids", []))


func set_selected_contract_ids(contract_ids: Array) -> void:
	var normalized := _normalize_string_array(contract_ids)
	profile["last_selected_contract_ids"] = normalized
	save_profile()


func get_language_code() -> String:
	return _normalize_language_code(String(profile.get("language_code", DEFAULT_LANGUAGE_CODE)))


func set_language_code(language_code: String) -> void:
	var normalized := _normalize_language_code(language_code)
	if String(profile.get("language_code", "")) == normalized:
		return
	profile["language_code"] = normalized
	save_profile()
	language_code_changed.emit(normalized)


func is_character_unlocked(character_id: String) -> bool:
	if character_id.is_empty():
		return false
	var unlocked: Array[String] = _get_unlocked_characters()
	return unlocked.has(character_id)


func unlock_character(character_id: String) -> bool:
	if character_id.is_empty():
		return false
	var unlocked: Array[String] = _get_unlocked_characters()
	if unlocked.has(character_id):
		return false
	unlocked.append(character_id)
	profile["unlocked_characters"] = unlocked
	save_profile()
	return true


func get_unlocked_characters() -> Array[String]:
	return _get_unlocked_characters().duplicate()


func unlock_all_characters(character_defs: Array) -> void:
	var unlocked: Array[String] = _get_unlocked_characters()
	for character_variant in character_defs:
		if not (character_variant is Dictionary):
			continue
		var character: Dictionary = character_variant
		var character_id := String(character.get("id", ""))
		if character_id.is_empty() or unlocked.has(character_id):
			continue
		unlocked.append(character_id)
	profile["unlocked_characters"] = unlocked
	save_profile()


func get_progress_snapshot() -> Dictionary:
	var progress_variant: Variant = profile.get("progress", {})
	if progress_variant is Dictionary:
		return (progress_variant as Dictionary).duplicate(true)
	return DEFAULT_PROGRESS.duplicate(true)


func get_meta_currency_total() -> int:
	var progress := get_progress_snapshot()
	return maxi(0, int(progress.get("meta_currency_total", 0)))


func get_meta_progress_state() -> Dictionary:
	var meta_variant: Variant = profile.get("meta_progress", DEFAULT_META_PROGRESS)
	if meta_variant is Dictionary:
		return _normalize_meta_progress(meta_variant as Dictionary)
	return DEFAULT_META_PROGRESS.duplicate(true)


func set_meta_progress_state(state: Dictionary) -> void:
	profile["meta_progress"] = _normalize_meta_progress(state)
	save_profile()


func get_dialogue_state() -> Dictionary:
	var dialogue_variant: Variant = profile.get("dialogue_state", DEFAULT_DIALOGUE_STATE)
	if dialogue_variant is Dictionary:
		return _normalize_dialogue_state(dialogue_variant)
	return DEFAULT_DIALOGUE_STATE.duplicate(true)


func set_dialogue_state(state: Dictionary) -> void:
	profile["dialogue_state"] = _normalize_dialogue_state(state)
	save_profile()


func get_daily_orders_state() -> Dictionary:
	var orders_variant: Variant = profile.get("daily_orders_state", DEFAULT_DAILY_ORDERS_STATE)
	if orders_variant is Dictionary:
		return _normalize_daily_orders_state(orders_variant)
	return DEFAULT_DAILY_ORDERS_STATE.duplicate(true)


func set_daily_orders_state(state: Dictionary) -> void:
	profile["daily_orders_state"] = _normalize_daily_orders_state(state)
	save_profile()


func update_progress_from_run(run_stats: Dictionary) -> void:
	var progress: Dictionary = get_progress_snapshot()
	progress["total_kills"] = int(progress.get("total_kills", 0)) + int(run_stats.get("total_kills", 0))
	progress["pickups_collected"] = int(progress.get("pickups_collected", 0)) + int(run_stats.get("pickups_collected", 0))
	progress["elite_or_pursuer_kills"] = int(progress.get("elite_or_pursuer_kills", 0)) + int(run_stats.get("elite_or_pursuer_kills", 0))
	progress["best_survive_time_seconds"] = maxf(float(progress.get("best_survive_time_seconds", 0.0)), float(run_stats.get("survive_time_seconds", 0.0)))
	progress["best_max_noise_reached"] = maxf(float(progress.get("best_max_noise_reached", 0.0)), float(run_stats.get("max_noise_reached", 0.0)))
	progress["meta_currency_total"] = maxi(
		0,
		int(progress.get("meta_currency_total", 0)) + _extract_meta_currency_earned_total(run_stats)
	)

	var tiers_variant: Variant = progress.get("reached_noise_tiers", [])
	var reached_tiers: Array[String] = _normalize_string_array(tiers_variant)
	var run_tier := String(run_stats.get("max_noise_tier_id", "")).strip_edges()
	if not run_tier.is_empty() and not reached_tiers.has(run_tier):
		reached_tiers.append(run_tier)
	progress["reached_noise_tiers"] = reached_tiers

	profile["progress"] = progress
	profile["run_count"] = int(profile.get("run_count", 0)) + 1


func evaluate_character_unlocks(character_defs: Array, run_stats: Dictionary) -> Array[String]:
	update_progress_from_run(run_stats)
	var newly_unlocked: Array[String] = []
	for character_variant in character_defs:
		if not (character_variant is Dictionary):
			continue
		var character: Dictionary = character_variant
		var character_id := String(character.get("id", "")).strip_edges()
		if character_id.is_empty():
			continue
		if is_character_unlocked(character_id):
			continue
		var unlock_variant: Variant = character.get("unlock", {})
		if not (unlock_variant is Dictionary):
			continue
		if _is_unlock_requirement_met(unlock_variant):
			var unlocked := unlock_character(character_id)
			if unlocked:
				newly_unlocked.append(character_id)
	save_profile()
	return newly_unlocked


func get_requirement_progress(requirement: Dictionary) -> Dictionary:
	var unlock_type := String(requirement.get("type", "")).strip_edges()
	var params_variant: Variant = requirement.get("params", {})
	var params: Dictionary = params_variant if params_variant is Dictionary else {}
	var target_value := float(params.get("value", 0.0))
	var progress: Dictionary = get_progress_snapshot()

	var current_value := 0.0
	match unlock_type:
		"survive_time_seconds":
			current_value = float(progress.get("best_survive_time_seconds", 0.0))
		"max_noise_reached":
			current_value = float(progress.get("best_max_noise_reached", 0.0))
		"total_kills":
			current_value = float(progress.get("total_kills", 0))
		"pickups_collected":
			current_value = float(progress.get("pickups_collected", 0))
		"elite_or_pursuer_kills":
			current_value = float(progress.get("elite_or_pursuer_kills", 0))
		"reached_noise_tier":
			var target_tier := String(params.get("tier_id", "")).strip_edges()
			var tiers := _normalize_string_array(progress.get("reached_noise_tiers", []))
			var met := tiers.has(target_tier)
			return {
				"type": unlock_type,
				"current": 1 if met else 0,
				"target": 1,
				"ratio": 1.0 if met else 0.0,
				"text": _t("profile.progress.reached") if met else _t("profile.progress.not_reached"),
				"met": met
			}
		_:
			return {
				"type": unlock_type,
				"current": 0.0,
				"target": 0.0,
				"ratio": 0.0,
				"text": _t("profile.progress.na"),
				"met": false
			}

	var ratio := 1.0 if target_value <= 0.0 else clampf(current_value / target_value, 0.0, 1.0)
	var met := current_value >= target_value and target_value > 0.0
	return {
		"type": unlock_type,
		"current": current_value,
		"target": target_value,
		"ratio": ratio,
		"text": "%d / %d" % [int(floor(current_value)), int(floor(target_value))],
		"met": met
	}


func save_profile() -> bool:
	var profile_path := _resolve_profile_path()
	var profile_tmp_path := _resolve_profile_tmp_path()
	var output := profile.duplicate(true)
	var content := JSON.stringify(output, "\t")
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(profile_path.get_base_dir()))
	var file := FileAccess.open(profile_tmp_path, FileAccess.WRITE)
	if file == null:
		push_error("[profile] failed to open tmp profile for write: %s" % profile_tmp_path)
		return false
	file.store_string(content)
	file.flush()
	file = null

	var profile_abs_path := ProjectSettings.globalize_path(profile_path)
	var profile_tmp_abs_path := ProjectSettings.globalize_path(profile_tmp_path)
	var backup_path := _resolve_profile_backup_path(profile_path)
	var backup_abs_path := ProjectSettings.globalize_path(backup_path)
	var has_existing_profile := FileAccess.file_exists(profile_path)
	if has_existing_profile:
		if FileAccess.file_exists(backup_path):
			DirAccess.remove_absolute(backup_abs_path)
		var backup_err := DirAccess.rename_absolute(profile_abs_path, backup_abs_path)
		if backup_err != OK:
			push_error("[profile] failed to create profile backup %s (err=%d)" % [backup_path, backup_err])
			DirAccess.remove_absolute(profile_tmp_abs_path)
			return false
	var err := DirAccess.rename_absolute(profile_tmp_abs_path, profile_abs_path)
	if err != OK:
		push_error("[profile] failed to move tmp profile to profile path %s (err=%d)" % [profile_path, err])
		if has_existing_profile and FileAccess.file_exists(backup_path):
			var restore_err := DirAccess.rename_absolute(backup_abs_path, profile_abs_path)
			if restore_err != OK:
				push_error("[profile] failed to restore profile backup %s (err=%d)" % [backup_path, restore_err])
		return false
	if has_existing_profile and FileAccess.file_exists(backup_path):
		DirAccess.remove_absolute(backup_abs_path)
	return true


func begin_test_session(session_id: String, clean_existing: bool = true) -> void:
	var normalized_session := session_id.strip_edges().replace("/", "_").replace("\\", "_")
	if normalized_session.is_empty():
		normalized_session = "test_%d" % int(Time.get_unix_time_from_system())
	var root_dir := "user://tmp/profile_sessions/%s" % normalized_session
	_active_test_session_id = normalized_session
	_profile_path_override = "%s/profile.json" % root_dir
	_profile_tmp_path_override = "%s/profile.json.tmp" % root_dir
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(root_dir))
	if clean_existing:
		_remove_path_if_exists(_profile_path_override)
		_remove_path_if_exists(_profile_tmp_path_override)
		_remove_path_if_exists(_resolve_profile_backup_path(_profile_path_override))
	Engine.set_meta(TEST_SESSION_META_KEY, normalized_session)


func end_test_session(cleanup_files: bool = true) -> void:
	if _profile_path_override.is_empty():
		return
	var profile_path := _profile_path_override
	var profile_tmp_path := _profile_tmp_path_override
	var profile_backup_path := _resolve_profile_backup_path(profile_path)
	var root_dir := profile_path.get_base_dir()
	if cleanup_files:
		_remove_path_if_exists(profile_path)
		_remove_path_if_exists(profile_tmp_path)
		_remove_path_if_exists(profile_backup_path)
		DirAccess.remove_absolute(ProjectSettings.globalize_path(root_dir))
	_profile_path_override = ""
	_profile_tmp_path_override = ""
	_active_test_session_id = ""
	if Engine.has_meta(TEST_SESSION_META_KEY):
		Engine.remove_meta(TEST_SESSION_META_KEY)


func get_profile_path() -> String:
	return _resolve_profile_path()


func get_profile_tmp_path() -> String:
	return _resolve_profile_tmp_path()


func get_active_test_session_id() -> String:
	return _active_test_session_id


func _is_unlock_requirement_met(requirement: Dictionary) -> bool:
	var result: Dictionary = get_requirement_progress(requirement)
	return bool(result.get("met", false))


func _extract_meta_currency_earned_total(run_stats: Dictionary) -> int:
	if run_stats.has("meta_currency_earned_total"):
		return maxi(0, int(run_stats.get("meta_currency_earned_total", 0)))
	var earned_variant: Variant = run_stats.get("meta_currency_earned", null)
	if earned_variant is Dictionary:
		var earned_dict: Dictionary = earned_variant
		return maxi(0, int(earned_dict.get("total", 0)))
	if earned_variant != null:
		return maxi(0, int(earned_variant))
	return 0


func _migrate_profile(raw_profile: Dictionary, default_character_id: String, default_map_id: String = "") -> Dictionary:
	var migrated: Dictionary = raw_profile.duplicate(true)
	var schema_version := int(migrated.get("schema_version", 1))

	if not migrated.has("unlocked_characters"):
		migrated["unlocked_characters"] = [default_character_id]
	migrated["unlocked_characters"] = _normalize_string_array(migrated.get("unlocked_characters", [default_character_id]))
	if (migrated["unlocked_characters"] as Array[String]).is_empty():
		(migrated["unlocked_characters"] as Array[String]).append(default_character_id)

	if not migrated.has("last_selected_character_id"):
		migrated["last_selected_character_id"] = default_character_id
	var selected := String(migrated.get("last_selected_character_id", default_character_id)).strip_edges()
	if selected.is_empty():
		selected = default_character_id
	migrated["last_selected_character_id"] = selected

	var resolved_default_map := default_map_id
	if resolved_default_map.is_empty():
		resolved_default_map = DataRegistry.get_default_map_id()
	if not migrated.has("last_selected_map_id"):
		migrated["last_selected_map_id"] = resolved_default_map
	var selected_map := String(migrated.get("last_selected_map_id", resolved_default_map)).strip_edges()
	if selected_map.is_empty():
		selected_map = resolved_default_map
	migrated["last_selected_map_id"] = selected_map
	if not migrated.has("last_selected_contract_ids"):
		migrated["last_selected_contract_ids"] = []
	migrated["last_selected_contract_ids"] = _normalize_string_array(migrated.get("last_selected_contract_ids", []))

	var progress_variant: Variant = migrated.get("progress", {})
	var progress: Dictionary = progress_variant.duplicate(true) if progress_variant is Dictionary else {}
	for progress_key in DEFAULT_PROGRESS.keys():
		if not progress.has(progress_key):
			progress[progress_key] = DEFAULT_PROGRESS[progress_key]
	progress["reached_noise_tiers"] = _normalize_string_array(progress.get("reached_noise_tiers", []))
	migrated["progress"] = progress
	if not migrated.has("run_count"):
		migrated["run_count"] = 0
	migrated["language_code"] = _normalize_language_code(String(migrated.get("language_code", DEFAULT_LANGUAGE_CODE)))
	migrated["dialogue_state"] = _normalize_dialogue_state(migrated.get("dialogue_state", DEFAULT_DIALOGUE_STATE))
	migrated["daily_orders_state"] = _normalize_daily_orders_state(migrated.get("daily_orders_state", DEFAULT_DAILY_ORDERS_STATE))
	migrated["meta_progress"] = _normalize_meta_progress(migrated.get("meta_progress", DEFAULT_META_PROGRESS))

	if schema_version < PROFILE_SCHEMA_VERSION:
		migrated["schema_version"] = PROFILE_SCHEMA_VERSION
	else:
		migrated["schema_version"] = schema_version

	return migrated


func _get_unlocked_characters() -> Array[String]:
	return _normalize_string_array(profile.get("unlocked_characters", []))


func _normalize_meta_progress(meta_variant: Variant) -> Dictionary:
	var output := DEFAULT_META_PROGRESS.duplicate(true)
	if not (meta_variant is Dictionary):
		return output
	var source: Dictionary = meta_variant
	output["schema_version"] = maxi(1, int(source.get("schema_version", 1)))

	var day_state_variant: Variant = source.get("day_state", {})
	if day_state_variant is Dictionary:
		var default_day_state_variant: Variant = output.get("day_state", {})
		var day_state: Dictionary = (default_day_state_variant as Dictionary).duplicate(true) if default_day_state_variant is Dictionary else {}
		var source_day_state: Dictionary = day_state_variant
		day_state["current_day"] = maxi(1, int(source_day_state.get("current_day", day_state.get("current_day", 1))))
		day_state["current_phase"] = _normalize_meta_phase(String(source_day_state.get("current_phase", day_state.get("current_phase", DayClockClass.PHASE_MORNING))))
		day_state["max_stamina"] = maxi(1, int(source_day_state.get("max_stamina", day_state.get("max_stamina", 6))))
		day_state["stamina"] = clampi(int(source_day_state.get("stamina", day_state.get("stamina", 6))), 0, int(day_state.get("max_stamina", 6)))
		day_state["max_action_budget"] = maxi(1, int(source_day_state.get("max_action_budget", day_state.get("max_action_budget", DayClockClass.DEFAULT_MAX_ACTION_BUDGET))))
		var default_action_budget := DayClockClass.default_action_budget_for_phase(String(day_state.get("current_phase", DayClockClass.PHASE_MORNING)), int(day_state.get("max_action_budget", DayClockClass.DEFAULT_MAX_ACTION_BUDGET)))
		day_state["action_budget"] = clampi(
			int(source_day_state.get("action_budget", default_action_budget)),
			0,
			int(day_state.get("max_action_budget", DayClockClass.DEFAULT_MAX_ACTION_BUDGET))
		)
		if String(day_state.get("current_phase", "")) != DayClockClass.PHASE_NIGHT:
			day_state["current_phase"] = DayClockClass.phase_from_action_budget(
				int(day_state.get("action_budget", default_action_budget)),
				int(day_state.get("max_action_budget", DayClockClass.DEFAULT_MAX_ACTION_BUDGET))
			)
		day_state["pending_night_gold_bonus"] = maxi(0, int(source_day_state.get("pending_night_gold_bonus", day_state.get("pending_night_gold_bonus", 0))))
		day_state["pending_night_material_bonus"] = maxi(0, int(source_day_state.get("pending_night_material_bonus", day_state.get("pending_night_material_bonus", 0))))
		day_state["pending_next_day_stamina_penalty"] = clampi(
			int(source_day_state.get("pending_next_day_stamina_penalty", day_state.get("pending_next_day_stamina_penalty", 0))),
			0,
			int(day_state.get("max_stamina", 6))
		)
		output["day_state"] = day_state

	var economy_variant: Variant = source.get("economy", {})
	if economy_variant is Dictionary:
		var default_economy_variant: Variant = output.get("economy", {})
		var economy: Dictionary = (default_economy_variant as Dictionary).duplicate(true) if default_economy_variant is Dictionary else {}
		economy["gold"] = maxi(0, int((economy_variant as Dictionary).get("gold", economy.get("gold", 0))))
		economy["restaurant_reputation"] = clampi(
			int((economy_variant as Dictionary).get("restaurant_reputation", economy.get("restaurant_reputation", 1))),
			0,
			20
		)
		var sold_dishes_stats: Dictionary = {}
		var sold_dishes_variant: Variant = (economy_variant as Dictionary).get("sold_dishes_stats", {})
		if sold_dishes_variant is Dictionary:
			for dish_id_variant in (sold_dishes_variant as Dictionary).keys():
				var dish_id := String(dish_id_variant).strip_edges().to_lower()
				if dish_id.is_empty():
					continue
				sold_dishes_stats[dish_id] = maxi(0, int((sold_dishes_variant as Dictionary).get(dish_id_variant, 0)))
		economy["sold_dishes_stats"] = sold_dishes_stats
		output["economy"] = economy

	var inventory_variant: Variant = source.get("inventory", {})
	if inventory_variant is Dictionary:
		var default_inventory_variant: Variant = output.get("inventory", {})
		var inventory: Dictionary = (default_inventory_variant as Dictionary).duplicate(true) if default_inventory_variant is Dictionary else {}
		var source_inventory: Dictionary = inventory_variant
		var materials: Dictionary = {}
		var materials_variant: Variant = source_inventory.get("materials", {})
		if materials_variant is Dictionary:
			for material_key_variant in (materials_variant as Dictionary).keys():
				var material_id := String(material_key_variant).strip_edges().to_lower()
				if material_id.is_empty():
					continue
				materials[material_id] = maxi(0, int((materials_variant as Dictionary).get(material_key_variant, 0)))
		inventory["materials"] = materials
		var unlocked_seeds := _normalize_string_array(source_inventory.get("unlocked_seeds", inventory.get("unlocked_seeds", [])))
		if DataRegistry != null and DataRegistry.has_method("get_seed_ids_started_unlocked"):
			for started_seed_id in DataRegistry.call("get_seed_ids_started_unlocked"):
				var seed_id := String(started_seed_id).strip_edges().to_lower()
				if seed_id.is_empty() or unlocked_seeds.has(seed_id):
					continue
				unlocked_seeds.append(seed_id)
		inventory["unlocked_seeds"] = unlocked_seeds
		var unlocked_recipes := _normalize_string_array(source_inventory.get("unlocked_recipes", inventory.get("unlocked_recipes", [])))
		if DataRegistry != null and DataRegistry.has_method("get_recipe_ids_started_unlocked"):
			for started_recipe_id in DataRegistry.call("get_recipe_ids_started_unlocked"):
				var recipe_id := String(started_recipe_id).strip_edges().to_lower()
				if recipe_id.is_empty() or unlocked_recipes.has(recipe_id):
					continue
				unlocked_recipes.append(recipe_id)
		inventory["unlocked_recipes"] = unlocked_recipes
		output["inventory"] = inventory

	var farm_state_variant: Variant = source.get("farm_state", {})
	output["farm_state"] = _normalize_farm_state(farm_state_variant)

	var restaurant_state_variant: Variant = source.get("restaurant_state", {})
	output["restaurant_state"] = _normalize_restaurant_state(restaurant_state_variant)

	var day_world_state_variant: Variant = source.get("day_world_state", {})
	output["day_world_state"] = _normalize_day_world_state(day_world_state_variant)

	var summary_variant: Variant = source.get("pending_return_summary", {})
	output["pending_return_summary"] = (summary_variant as Dictionary).duplicate(true) if summary_variant is Dictionary else {}
	return output


func _normalize_farm_state(farm_variant: Variant) -> Dictionary:
	var output: Dictionary = {
		"columns": 3,
		"rows": 2,
		"plots": []
	}
	var columns := 3
	var rows := 2
	var source: Dictionary = farm_variant if farm_variant is Dictionary else {}
	columns = maxi(1, int(source.get("columns", columns)))
	rows = maxi(1, int(source.get("rows", rows)))
	output["columns"] = columns
	output["rows"] = rows
	var plot_count := maxi(columns * rows, 1)
	var plots_variant: Variant = source.get("plots", [])
	var plots: Array = plots_variant if plots_variant is Array else []
	var normalized_plots: Array[Dictionary] = []
	for plot_variant in plots:
		if normalized_plots.size() >= plot_count:
			break
		var plot: Dictionary = plot_variant if plot_variant is Dictionary else {}
		var normalized_plot := {
			"tilled": bool(plot.get("tilled", false)),
			"crop": _normalize_farm_crop(plot.get("crop", {}))
		}
		if (normalized_plot["crop"] as Dictionary).is_empty():
			normalized_plot["crop"] = {}
		normalized_plots.append(normalized_plot)
	while normalized_plots.size() < plot_count:
		normalized_plots.append({
			"tilled": false,
			"crop": {}
		})
	output["plots"] = normalized_plots
	return output


func _normalize_farm_crop(crop_variant: Variant) -> Dictionary:
	if not (crop_variant is Dictionary):
		return {}
	var crop: Dictionary = crop_variant
	var crop_id := String(crop.get("crop_id", "")).strip_edges().to_lower()
	var seed_id := String(crop.get("seed_id", "")).strip_edges().to_lower()
	if crop_id.is_empty() or seed_id.is_empty():
		return {}
	if DataRegistry != null and DataRegistry.has_method("has_crop") and not bool(DataRegistry.call("has_crop", crop_id)):
		return {}
	if DataRegistry != null and DataRegistry.has_method("has_seed") and not bool(DataRegistry.call("has_seed", seed_id)):
		return {}
	if DataRegistry != null and DataRegistry.has_method("get_crop_by_seed"):
		var crop_by_seed_variant: Variant = DataRegistry.call("get_crop_by_seed", seed_id)
		if crop_by_seed_variant is Dictionary:
			var crop_by_seed: Dictionary = crop_by_seed_variant
			if String(crop_by_seed.get("id", "")).strip_edges().to_lower() != crop_id:
				return {}
	var growth_days := maxi(1, int(crop.get("growth_days", 1)))
	return {
		"crop_id": crop_id,
		"seed_id": seed_id,
		"planted_day": maxi(1, int(crop.get("planted_day", 1))),
		"growth_days": growth_days,
		"growth_progress_days": clampi(int(crop.get("growth_progress_days", 0)), 0, growth_days),
		"watered_day": maxi(0, int(crop.get("watered_day", 0)))
	}


func _normalize_restaurant_state(restaurant_variant: Variant) -> Dictionary:
	var output: Dictionary = {
		"selected_menu_recipe_ids": [],
		"last_service_day": 0,
		"last_service_summary": {},
		"owned_upgrade_ids": []
	}
	if not (restaurant_variant is Dictionary):
		return output
	var source: Dictionary = restaurant_variant
	var selected_menu_ids := _normalize_string_array(source.get("selected_menu_recipe_ids", []))
	if DataRegistry != null and DataRegistry.has_method("has_recipe"):
		var filtered_menu_ids: Array[String] = []
		for recipe_id in selected_menu_ids:
			if not bool(DataRegistry.call("has_recipe", recipe_id)):
				continue
			filtered_menu_ids.append(recipe_id)
		selected_menu_ids = filtered_menu_ids
	output["selected_menu_recipe_ids"] = selected_menu_ids
	output["last_service_day"] = maxi(0, int(source.get("last_service_day", 0)))
	var summary_variant: Variant = source.get("last_service_summary", {})
	output["last_service_summary"] = (summary_variant as Dictionary).duplicate(true) if summary_variant is Dictionary else {}
	var owned_upgrade_ids := _normalize_string_array(source.get("owned_upgrade_ids", []))
	if DataRegistry != null and DataRegistry.has_method("get_restaurant_upgrade"):
		var filtered_upgrade_ids: Array[String] = []
		for upgrade_id in owned_upgrade_ids:
			var upgrade_variant: Variant = DataRegistry.call("get_restaurant_upgrade", upgrade_id)
			if not (upgrade_variant is Dictionary) or (upgrade_variant as Dictionary).is_empty():
				continue
			filtered_upgrade_ids.append(upgrade_id)
		owned_upgrade_ids = filtered_upgrade_ids
	output["owned_upgrade_ids"] = owned_upgrade_ids
	return output


func _normalize_day_world_state(day_world_variant: Variant) -> Dictionary:
	var source: Dictionary = day_world_variant if day_world_variant is Dictionary else {}
	return {
		"pickup_day": maxi(1, int(source.get("pickup_day", 1))),
		"collected_pickup_ids": _normalize_string_array(source.get("collected_pickup_ids", []))
	}


func _normalize_dialogue_state(dialogue_variant: Variant) -> Dictionary:
	var source: Dictionary = dialogue_variant if dialogue_variant is Dictionary else {}
	return {
		"seen_dialogue_ids": _normalize_string_array(source.get("seen_dialogue_ids", []))
	}


func _normalize_daily_orders_state(orders_variant: Variant) -> Dictionary:
	var source: Dictionary = orders_variant if orders_variant is Dictionary else {}
	var pool_state_variant: Variant = source.get("pool_state", {})
	var serialized_variant: Variant = source.get("serialized_quests", {})
	return {
		"current_day": maxi(0, int(source.get("current_day", 0))),
		"pool_state": _normalize_daily_orders_pool_state(pool_state_variant),
		"serialized_quests": _normalize_daily_orders_serialized(serialized_variant),
		"tracked_dish_sales": _normalize_string_int_dictionary(source.get("tracked_dish_sales", {})),
		"tracked_materials": _normalize_string_int_dictionary(source.get("tracked_materials", {}))
	}


func _normalize_daily_orders_pool_state(pool_state_variant: Variant) -> Dictionary:
	var source: Dictionary = pool_state_variant if pool_state_variant is Dictionary else {}
	return {
		"available": _normalize_int_array(source.get("available", [])),
		"active": _normalize_int_array(source.get("active", [])),
		"completed": _normalize_int_array(source.get("completed", []))
	}


func _normalize_daily_orders_serialized(serialized_variant: Variant) -> Dictionary:
	var source: Dictionary = serialized_variant if serialized_variant is Dictionary else {}
	var normalized: Dictionary = {}
	for quest_id_variant in source.keys():
		var quest_data_variant: Variant = source.get(quest_id_variant, {})
		if not (quest_data_variant is Dictionary):
			continue
		normalized[str(quest_id_variant)] = (quest_data_variant as Dictionary).duplicate(true)
	return normalized


func _normalize_meta_phase(phase: String) -> String:
	return DayClockClass.normalize_phase(phase)


func _normalize_string_array(source: Variant) -> Array[String]:
	var output: Array[String] = []
	if not (source is Array):
		return output
	var rows: Array = source
	for row in rows:
		var text := String(row).strip_edges()
		if text.is_empty():
			continue
		if output.has(text):
			continue
		output.append(text)
	return output


func _normalize_int_array(source: Variant) -> Array[int]:
	var output: Array[int] = []
	if not (source is Array):
		return output
	for item in (source as Array):
		var value := int(item)
		if output.has(value):
			continue
		output.append(value)
	return output


func _normalize_string_int_dictionary(source_variant: Variant) -> Dictionary:
	var source: Dictionary = source_variant if source_variant is Dictionary else {}
	var output: Dictionary = {}
	for key_variant in source.keys():
		var key := String(key_variant).strip_edges().to_lower()
		if key.is_empty():
			continue
		output[key] = maxi(0, int(source.get(key_variant, 0)))
	return output


func _resolve_profile_path() -> String:
	return _profile_path_override if not _profile_path_override.is_empty() else PROFILE_PATH


func _resolve_profile_tmp_path() -> String:
	return _profile_tmp_path_override if not _profile_tmp_path_override.is_empty() else PROFILE_TMP_PATH


func _resolve_profile_backup_path(profile_path: String = "") -> String:
	var target_path := profile_path if not profile_path.is_empty() else _resolve_profile_path()
	return "%s.bak" % target_path


func _load_profile_payload(profile_path: String, backup_path: String) -> Dictionary:
	var primary_read := _read_profile_payload_result(profile_path)
	if bool(primary_read.get("ok", false)):
		var raw_variant: Variant = primary_read.get("data", {})
		var raw_profile: Dictionary = raw_variant if raw_variant is Dictionary else {}
		if FileAccess.file_exists(backup_path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(backup_path))
		return raw_profile
	if bool(primary_read.get("exists", false)):
		push_warning("[profile] profile parse failed, attempting backup restore: %s" % profile_path)
	var backup_read := _read_profile_payload_result(backup_path)
	if not bool(backup_read.get("ok", false)):
		return {}
	var backup_variant: Variant = backup_read.get("data", {})
	var backup_profile: Dictionary = backup_variant if backup_variant is Dictionary else {}
	var profile_abs_path := ProjectSettings.globalize_path(profile_path)
	var backup_abs_path := ProjectSettings.globalize_path(backup_path)
	if FileAccess.file_exists(profile_path):
		DirAccess.remove_absolute(profile_abs_path)
	var restore_err := DirAccess.rename_absolute(backup_abs_path, profile_abs_path)
	if restore_err != OK:
		push_warning("[profile] failed to restore backup %s (err=%d)" % [backup_path, restore_err])
	return backup_profile


func _read_profile_payload_result(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {
			"exists": false,
			"ok": false,
			"data": {}
		}
	var text: String = FileAccess.get_file_as_string(path)
	if text.strip_edges().is_empty():
		return {
			"exists": true,
			"ok": false,
			"data": {}
		}
	var parser := JSON.new()
	var parse_err := parser.parse(text)
	if parse_err == OK and parser.data is Dictionary:
		return {
			"exists": true,
			"ok": true,
			"data": (parser.data as Dictionary).duplicate(true)
		}
	return {
		"exists": true,
		"ok": false,
		"data": {}
	}


func _remove_path_if_exists(path: String) -> void:
	if not FileAccess.file_exists(path):
		return
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))


func _maybe_enable_auto_test_session() -> void:
	if not _profile_path_override.is_empty():
		return
	var test_scene := ""
	for arg in OS.get_cmdline_args():
		var value := String(arg).strip_edges()
		if value.begins_with("res://tests/") and value.ends_with(".tscn"):
			test_scene = value
			break
	if test_scene.is_empty():
		return
	if Engine.has_meta(TEST_SESSION_META_KEY):
		var existing_id := String(Engine.get_meta(TEST_SESSION_META_KEY)).strip_edges()
		if not existing_id.is_empty():
			begin_test_session(existing_id, false)
			return
	var scene_name := test_scene.get_file().get_basename().to_lower()
	var stamp := int(Time.get_unix_time_from_system())
	var nonce := int(Time.get_ticks_usec() % 1000000)
	begin_test_session("%s_%d_%d" % [scene_name, stamp, nonce], true)


func _normalize_language_code(language_code: String) -> String:
	var code := language_code.strip_edges()
	if code.is_empty():
		return DEFAULT_LANGUAGE_CODE
	if code == "zh" or code == "zh_CN" or code == "zh-Hans":
		return "zh_CN"
	return DEFAULT_LANGUAGE_CODE


func _t(key: String, args: Dictionary = {}) -> String:
	if Localization == null or not Localization.has_method("t"):
		return key
	return String(Localization.call("t", key, args))
