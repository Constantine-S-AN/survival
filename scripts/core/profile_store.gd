extends Node

const PROFILE_PATH := "user://profile.json"
const PROFILE_TMP_PATH := "user://profile.json.tmp"
const PROFILE_SCHEMA_VERSION := 2

const DEFAULT_PROGRESS: Dictionary = {
	"total_kills": 0,
	"pickups_collected": 0,
	"elite_or_pursuer_kills": 0,
	"best_survive_time_seconds": 0.0,
	"best_max_noise_reached": 0.0,
	"reached_noise_tiers": []
}

var profile: Dictionary = {}
var loaded: bool = false


func _ready() -> void:
	var default_character_id := DataRegistry.get_default_character_id()
	var default_map_id := DataRegistry.get_default_map_id()
	load_profile(
		default_character_id if not default_character_id.is_empty() else "diver",
		default_map_id
	)


func load_profile(default_character_id: String, default_map_id: String = "") -> Dictionary:
	var raw_profile: Dictionary = {}
	if FileAccess.file_exists(PROFILE_PATH):
		var text: String = FileAccess.get_file_as_string(PROFILE_PATH)
		var parsed: Variant = JSON.parse_string(text)
		if parsed is Dictionary:
			raw_profile = (parsed as Dictionary).duplicate(true)
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


func update_progress_from_run(run_stats: Dictionary) -> void:
	var progress: Dictionary = get_progress_snapshot()
	progress["total_kills"] = int(progress.get("total_kills", 0)) + int(run_stats.get("total_kills", 0))
	progress["pickups_collected"] = int(progress.get("pickups_collected", 0)) + int(run_stats.get("pickups_collected", 0))
	progress["elite_or_pursuer_kills"] = int(progress.get("elite_or_pursuer_kills", 0)) + int(run_stats.get("elite_or_pursuer_kills", 0))
	progress["best_survive_time_seconds"] = maxf(float(progress.get("best_survive_time_seconds", 0.0)), float(run_stats.get("survive_time_seconds", 0.0)))
	progress["best_max_noise_reached"] = maxf(float(progress.get("best_max_noise_reached", 0.0)), float(run_stats.get("max_noise_reached", 0.0)))

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
				"text": "Reached" if met else "Not reached",
				"met": met
			}
		_:
			return {
				"type": unlock_type,
				"current": 0.0,
				"target": 0.0,
				"ratio": 0.0,
				"text": "N/A",
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
	var output := profile.duplicate(true)
	var content := JSON.stringify(output, "\t")
	var file := FileAccess.open(PROFILE_TMP_PATH, FileAccess.WRITE)
	if file == null:
		push_error("[profile] failed to open tmp profile for write: %s" % PROFILE_TMP_PATH)
		return false
	file.store_string(content)
	file.flush()
	file = null

	if FileAccess.file_exists(PROFILE_PATH):
		DirAccess.remove_absolute(PROFILE_PATH)
	var err := DirAccess.rename_absolute(PROFILE_TMP_PATH, PROFILE_PATH)
	if err != OK:
		push_error("[profile] failed to move tmp profile to profile.json (err=%d)" % err)
		return false
	return true


func _is_unlock_requirement_met(requirement: Dictionary) -> bool:
	var result: Dictionary = get_requirement_progress(requirement)
	return bool(result.get("met", false))


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

	if schema_version < PROFILE_SCHEMA_VERSION:
		migrated["schema_version"] = PROFILE_SCHEMA_VERSION
	else:
		migrated["schema_version"] = schema_version

	return migrated


func _get_unlocked_characters() -> Array[String]:
	return _normalize_string_array(profile.get("unlocked_characters", []))


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
