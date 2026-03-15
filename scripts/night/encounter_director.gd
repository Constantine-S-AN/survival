extends RefCounted
class_name EncounterDirector

const ENCOUNTERS_PATH := "res://data/night_encounters.json"
const SPAWN_SET_PATHS := [
	"res://data/night_spawn_sets.json",
	"res://data/night_spawn_sets_v2.json"
]
const SCHEMA_CONTRACT_VERSION := 1
const CATEGORY_LABELS := {
	"standard": "Standard Combat",
	"elite": "Elite Combat",
	"boss": "Boss Combat"
}
const SUPPORTED_CATEGORIES := {
	"standard": true,
	"elite": true,
	"boss": true
}
const SUPPORTED_CLEAR_MODES := {
	"kill_all": true,
	"complete_objective": true,
	"objective_then_cleanup": true
}
const SUPPORTED_WAVE_TRIGGERS := {
	"on_timer": true,
	"on_objective_progress": true,
	"repeat": true
}
const ENCOUNTER_SCHEMA_FIELDS: Array[String] = [
	"id",
	"schema_contract_version",
	"label",
	"label_zh",
	"category",
	"category_label",
	"category_label_zh",
	"reward_table_id",
	"difficulty",
	"spawn_set_id",
	"clear_mode",
	"objective_id",
	"objective_label",
	"objective_label_zh",
	"time_limit_sec",
	"waves",
	"objective_props",
	"room_mutators",
	"success_bonus",
	"fail_penalty",
	"telegraph_ui",
	"runtime_flags",
	"tags"
]
const WAVE_SCHEMA_FIELDS: Array[String] = [
	"trigger",
	"spawn_set_id",
	"at_sec",
	"every_sec",
	"at_count",
	"until_objective_complete",
	"enemies"
]
const OBJECTIVE_PROP_SCHEMA_FIELDS: Array[String] = [
	"prop_id",
	"marker",
	"radius",
	"hp",
	"label",
	"label_zh"
]

var _encounters_by_id: Dictionary = {}
var _spawn_sets_by_id: Dictionary = {}
var _schema_warnings: Array[String] = []


func describe_room(floor_state, room_state) -> Dictionary:
	var payload := {
		"schema_contract_version": SCHEMA_CONTRACT_VERSION,
		"room_id": room_state.room_id,
		"room_label": room_state.label,
		"room_type_id": room_state.room_type_id,
		"encounter_id": room_state.encounter_id,
		"encounter_label": room_state.label,
		"encounter_category": "",
		"encounter_category_label": "",
		"reward_table_id": "",
		"spawn_set_id": "",
		"difficulty": 0,
		"clear_mode": "kill_all",
		"objective_id": "kill_all",
		"objective_label": "",
		"time_limit_sec": 0.0,
		"waves": [],
		"objective_props": [],
		"room_mutators": [],
		"success_bonus": {},
		"fail_penalty": {},
		"telegraph_ui": {},
		"runtime_flags": {},
		"tags": [],
		"is_goal": room_state.is_goal,
		"reward": room_state.reward_data.duplicate(true),
		"enemies": []
	}
	if not room_state.is_combat_room():
		return payload

	var encounter := _resolve_encounter(floor_state, room_state)
	var fallback_category := "boss" if room_state.room_type_id == room_state.TYPE_BOSS else "standard"
	var category := String(encounter.get("category", fallback_category)).strip_edges().to_lower()
	if category.is_empty():
		category = fallback_category
	var encounter_id := String(encounter.get("id", room_state.encounter_id)).strip_edges().to_lower()
	var encounter_label_fallback := String(encounter.get("label", room_state.label)).strip_edges()
	payload["encounter_label"] = _localized_field(encounter_id, "label", encounter_label_fallback, encounter)
	payload["encounter_category"] = category
	var category_label_fallback := String(
		encounter.get("category_label", CATEGORY_LABELS.get(category, category.capitalize()))
	).strip_edges()
	var category_source := {
		"label": category_label_fallback,
		"label_zh": String(encounter.get("category_label_zh", "")).strip_edges()
	}
	payload["encounter_category_label"] = _localized_field(
		"night_encounter_category_%s" % category,
		"label",
		category_label_fallback,
		category_source
	)
	payload["reward_table_id"] = String(encounter.get("reward_table_id", "combat_%s" % category)).strip_edges()
	payload["spawn_set_id"] = String(encounter.get("spawn_set_id", "")).strip_edges().to_lower()
	payload["difficulty"] = maxi(1, int(encounter.get("difficulty", 1)))
	payload["clear_mode"] = String(encounter.get("clear_mode", "kill_all")).strip_edges().to_lower()
	payload["objective_id"] = String(encounter.get("objective_id", "kill_all")).strip_edges().to_lower()
	payload["schema_contract_version"] = maxi(1, int(encounter.get("schema_contract_version", SCHEMA_CONTRACT_VERSION)))
	payload["objective_label"] = _localized_field(
		encounter_id,
		"objective_label",
		String(encounter.get("objective_label", payload["encounter_label"])).strip_edges(),
		encounter
	)
	payload["time_limit_sec"] = maxf(0.0, float(encounter.get("time_limit_sec", 0.0)))
	payload["waves"] = _normalize_wave_rows(encounter.get("waves", []))
	payload["objective_props"] = _normalize_objective_props(encounter.get("objective_props", []))
	payload["room_mutators"] = _normalize_string_array(encounter.get("room_mutators", []))
	var success_bonus_variant: Variant = encounter.get("success_bonus", {})
	payload["success_bonus"] = success_bonus_variant.duplicate(true) if success_bonus_variant is Dictionary else {}
	var fail_penalty_variant: Variant = encounter.get("fail_penalty", {})
	payload["fail_penalty"] = fail_penalty_variant.duplicate(true) if fail_penalty_variant is Dictionary else {}
	payload["telegraph_ui"] = _normalize_dictionary(encounter.get("telegraph_ui", {}))
	payload["runtime_flags"] = _normalize_dictionary(encounter.get("runtime_flags", {}))
	payload["tags"] = _normalize_string_array(encounter.get("tags", []))
	return payload


func build_room_payload(floor_state, room_state, room_node: Node2D) -> Dictionary:
	var payload := describe_room(floor_state, room_state)
	if not room_state.is_combat_room():
		return payload

	var encounter := _resolve_encounter(floor_state, room_state)
	payload["enemies"] = _resolve_enemy_specs(room_node, encounter, room_state)
	payload["waves"] = _resolve_wave_enemy_specs(room_node, payload.get("waves", []), room_state)
	payload["objective_props"] = _resolve_objective_prop_positions(room_node, payload.get("objective_props", []))
	return payload


func get_schema_contract() -> Dictionary:
	return {
		"contract_version": SCHEMA_CONTRACT_VERSION,
		"encounter_fields": ENCOUNTER_SCHEMA_FIELDS.duplicate(),
		"wave_fields": WAVE_SCHEMA_FIELDS.duplicate(),
		"objective_prop_fields": OBJECTIVE_PROP_SCHEMA_FIELDS.duplicate(),
		"supported_categories": SUPPORTED_CATEGORIES.keys(),
		"supported_clear_modes": SUPPORTED_CLEAR_MODES.keys(),
		"supported_wave_triggers": SUPPORTED_WAVE_TRIGGERS.keys()
	}


func get_schema_warnings() -> Array[String]:
	_ensure_loaded()
	return _schema_warnings.duplicate()


func get_encounter_definition(encounter_id: String) -> Dictionary:
	_ensure_loaded()
	var normalized_id := encounter_id.strip_edges().to_lower()
	if normalized_id.is_empty():
		return {}
	var encounter_variant: Variant = _encounters_by_id.get(normalized_id, {})
	return encounter_variant.duplicate(true) if encounter_variant is Dictionary else {}


func _resolve_encounter(floor_state, room_state) -> Dictionary:
	_ensure_loaded()
	var encounter_id := String(room_state.encounter_id).strip_edges().to_lower()
	var resolved: Dictionary = {}
	if _encounters_by_id.has(encounter_id):
		var encounter_variant: Variant = _encounters_by_id.get(encounter_id, {})
		if encounter_variant is Dictionary:
			resolved = (encounter_variant as Dictionary).duplicate(true)
	var floor_encounters_variant: Variant = floor_state.encounters if floor_state != null else {}
	if floor_encounters_variant is Dictionary and (floor_encounters_variant as Dictionary).has(encounter_id):
		var override_variant: Variant = (floor_encounters_variant as Dictionary).get(encounter_id, {})
		if override_variant is Dictionary:
			resolved = _merge_dictionary(resolved, override_variant as Dictionary)
	if resolved.is_empty():
		resolved = {
			"id": encounter_id,
			"schema_contract_version": SCHEMA_CONTRACT_VERSION,
			"label": room_state.label,
			"category": "boss" if room_state.room_type_id == room_state.TYPE_BOSS else "standard",
			"reward_table_id": "combat_boss" if room_state.room_type_id == room_state.TYPE_BOSS else "combat_standard",
			"spawn_set_id": "",
			"difficulty": 1,
			"clear_mode": "kill_all",
			"objective_id": "kill_all",
			"objective_label": room_state.label,
			"time_limit_sec": 0.0,
			"waves": [],
			"objective_props": [],
			"room_mutators": [],
			"success_bonus": {},
			"fail_penalty": {},
			"telegraph_ui": {},
			"runtime_flags": {},
			"tags": [],
			"enemies": []
		}
	return resolved


func _resolve_spawn_position(room_node: Node2D, row: Dictionary, spawn_index: int, spawn_total: int) -> Vector2:
	var spawn_name := String(row.get("spawn_point", "")).strip_edges()
	var base_position := _find_marker_global_position(room_node, spawn_name, "SpawnPoints")
	if base_position == Vector2.ZERO:
		base_position = _find_marker_global_position(room_node, "EncounterAnchor", "")
	if base_position == Vector2.ZERO and room_node != null:
		base_position = room_node.global_position
	var offset_radius := maxf(0.0, float(row.get("offset_radius", 42.0)))
	if spawn_total <= 1 or is_zero_approx(offset_radius):
		return base_position
	var angle_step := TAU / maxf(1.0, float(spawn_total))
	var angle := float(spawn_index) * angle_step - PI * 0.5
	return base_position + Vector2.RIGHT.rotated(angle) * offset_radius


func _find_marker_global_position(root: Node, marker_name: String, preferred_parent_name: String) -> Vector2:
	if root == null or marker_name.is_empty():
		return Vector2.ZERO
	var preferred_parent := root.get_node_or_null(preferred_parent_name) if not preferred_parent_name.is_empty() else root
	var marker := _find_named_node(preferred_parent, marker_name)
	if marker == null and preferred_parent != root:
		marker = _find_named_node(root, marker_name)
	if marker is Node2D:
		return (marker as Node2D).global_position
	return Vector2.ZERO


func _find_named_node(parent: Node, target_name: String) -> Node:
	if parent == null:
		return null
	var normalized_target := target_name.strip_edges().to_lower()
	for child in parent.get_children():
		if child == null:
			continue
		if String(child.name).strip_edges().to_lower() == normalized_target:
			return child
	return null


func _merge_dictionary(base: Dictionary, override_source: Dictionary) -> Dictionary:
	var merged := base.duplicate(true)
	for key_variant in override_source.keys():
		var key := String(key_variant)
		merged[key] = override_source[key_variant]
	return merged


func _ensure_loaded() -> void:
	if not _encounters_by_id.is_empty():
		if not _spawn_sets_by_id.is_empty():
			return
	_schema_warnings.clear()
	_encounters_by_id.clear()
	_spawn_sets_by_id.clear()
	var payload := _load_json_dictionary(ENCOUNTERS_PATH)
	if payload.is_empty():
		_record_schema_warning("[night_encounters] missing or invalid encounter payload")
	if not payload.has("schema_contract_version"):
		_record_schema_warning("[night_encounters] missing schema_contract_version")
	var contract_version := int(payload.get("schema_contract_version", SCHEMA_CONTRACT_VERSION))
	if contract_version != SCHEMA_CONTRACT_VERSION:
		_record_schema_warning(
			"[night_encounters] schema_contract_version %d does not match expected %d"
			% [contract_version, SCHEMA_CONTRACT_VERSION]
		)
	var rows_variant: Variant = payload.get("encounters", [])
	if rows_variant is Array:
		var rows: Array = rows_variant
		for row_index in range(rows.size()):
			var row_variant: Variant = rows[row_index]
			if not (row_variant is Dictionary):
				_record_schema_warning("[night_encounters:%d] encounter must be a dictionary" % row_index)
				continue
			var row: Dictionary = _normalize_encounter_row(row_variant as Dictionary, row_index)
			var encounter_id := String(row.get("id", "")).strip_edges().to_lower()
			if encounter_id.is_empty():
				continue
			_encounters_by_id[encounter_id] = row
	else:
		_record_schema_warning("[night_encounters] encounters must be an array")
	for path in SPAWN_SET_PATHS:
		var spawn_payload := _load_json_dictionary(path)
		var spawn_rows_variant: Variant = spawn_payload.get("spawn_sets", [])
		if spawn_rows_variant is Array:
			for row_variant in spawn_rows_variant:
				if not (row_variant is Dictionary):
					continue
				var row: Dictionary = row_variant
				var spawn_set_id := String(row.get("id", "")).strip_edges().to_lower()
				if spawn_set_id.is_empty():
					continue
				_spawn_sets_by_id[spawn_set_id] = row.duplicate(true)


func _load_json_dictionary(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if parsed is Dictionary:
		return (parsed as Dictionary).duplicate(true)
	return {}


func _localized_field(entry_id: String, field: String, fallback: String, source: Dictionary = {}) -> String:
	if Localization != null and Localization.has_method("data_field"):
		return String(Localization.call("data_field", entry_id, field, fallback, source))
	return fallback


func _resolve_enemy_specs(room_node: Node2D, encounter: Dictionary, room_state) -> Array[Dictionary]:
	var spawn_set_id := String(encounter.get("spawn_set_id", "")).strip_edges().to_lower()
	var enemies_variant: Variant = encounter.get("enemies", [])
	if not spawn_set_id.is_empty():
		var spawn_set_variant: Variant = _spawn_sets_by_id.get(spawn_set_id, {})
		if spawn_set_variant is Dictionary:
			enemies_variant = (spawn_set_variant as Dictionary).get("enemies", enemies_variant)
	return _build_enemy_payloads(room_node, enemies_variant, room_state)


func _build_enemy_payloads(room_node: Node2D, enemies_variant: Variant, room_state) -> Array[Dictionary]:
	if not (enemies_variant is Array):
		return []
	var enemy_payloads: Array[Dictionary] = []
	var rows: Array = enemies_variant
	for row_variant in rows:
		if not (row_variant is Dictionary):
			continue
		var row: Dictionary = row_variant
		var enemy_id := String(row.get("enemy_id", "")).strip_edges().to_lower()
		if enemy_id.is_empty():
			continue
		var count := clampi(int(row.get("count", 1)), 1, 8)
		var allow_elite: bool = bool(row.get("allow_elite", false))
		var spawn_boss: bool = bool(row.get("spawn_boss", false)) or room_state.room_type_id == room_state.TYPE_BOSS
		for spawn_index in range(count):
			enemy_payloads.append({
				"enemy_id": enemy_id,
				"allow_elite": allow_elite,
				"spawn_boss": spawn_boss,
				"position": _resolve_spawn_position(room_node, row, spawn_index, count)
			})
	return enemy_payloads


func _resolve_wave_enemy_specs(room_node: Node2D, waves_variant: Variant, room_state) -> Array[Dictionary]:
	if not (waves_variant is Array):
		return []
	var resolved: Array[Dictionary] = []
	for wave_variant in waves_variant:
		if not (wave_variant is Dictionary):
			continue
		var wave: Dictionary = (wave_variant as Dictionary).duplicate(true)
		var spawn_set_id := String(wave.get("spawn_set_id", "")).strip_edges().to_lower()
		var enemies_variant: Variant = wave.get("enemies", [])
		if not spawn_set_id.is_empty():
			var spawn_set_variant: Variant = _spawn_sets_by_id.get(spawn_set_id, {})
			if spawn_set_variant is Dictionary:
				enemies_variant = (spawn_set_variant as Dictionary).get("enemies", enemies_variant)
		wave["enemies"] = _build_enemy_payloads(room_node, enemies_variant, room_state)
		resolved.append(wave)
	return resolved


func _resolve_objective_prop_positions(room_node: Node2D, props_variant: Variant) -> Array[Dictionary]:
	if not (props_variant is Array):
		return []
	var resolved: Array[Dictionary] = []
	for prop_variant in props_variant:
		if not (prop_variant is Dictionary):
			continue
		var prop: Dictionary = (prop_variant as Dictionary).duplicate(true)
		var marker_name := String(prop.get("marker", prop.get("spawn_point", ""))).strip_edges()
		var position := _find_marker_global_position(room_node, marker_name, "SpawnPoints")
		if position == Vector2.ZERO and room_node != null:
			position = room_node.global_position
		prop["position"] = position
		resolved.append(prop)
	return resolved


func _normalize_wave_rows(value: Variant) -> Array[Dictionary]:
	var rows: Array[Dictionary] = []
	if not (value is Array):
		return rows
	var source_rows: Array = value
	for row_index in range(source_rows.size()):
		var row_variant: Variant = source_rows[row_index]
		if not (row_variant is Dictionary):
			continue
		var row: Dictionary = row_variant
		var trigger := String(row.get("trigger", "on_timer")).strip_edges().to_lower()
		if trigger.is_empty() or not SUPPORTED_WAVE_TRIGGERS.has(trigger):
			trigger = "on_timer"
		var normalized := {
			"trigger": trigger,
			"spawn_set_id": String(row.get("spawn_set_id", "")).strip_edges().to_lower(),
			"at_sec": maxf(0.0, float(row.get("at_sec", 0.0))),
			"every_sec": maxf(0.0, float(row.get("every_sec", 0.0))),
			"at_count": maxi(0, int(row.get("at_count", 0))),
			"until_objective_complete": bool(row.get("until_objective_complete", false)),
			"enemies": row.get("enemies", []).duplicate(true) if row.get("enemies", []) is Array else []
		}
		if trigger == "repeat" and is_zero_approx(float(normalized["every_sec"])):
			normalized["every_sec"] = 1.0
		elif trigger == "on_objective_progress" and int(normalized["at_count"]) <= 0:
			normalized["at_count"] = 1
		rows.append(normalized)
	return rows


func _normalize_objective_props(value: Variant) -> Array[Dictionary]:
	var rows: Array[Dictionary] = []
	if not (value is Array):
		return rows
	var source_rows: Array = value
	for row_index in range(source_rows.size()):
		var row_variant: Variant = source_rows[row_index]
		if not (row_variant is Dictionary):
			continue
		var row: Dictionary = row_variant
		rows.append({
			"prop_id": String(row.get("prop_id", "objective_prop_%d" % row_index)).strip_edges().to_lower(),
			"marker": String(row.get("marker", row.get("spawn_point", ""))).strip_edges(),
			"radius": maxf(0.0, float(row.get("radius", 24.0))),
			"hp": maxf(0.0, float(row.get("hp", 0.0))),
			"label": String(row.get("label", "")).strip_edges(),
			"label_zh": String(row.get("label_zh", "")).strip_edges()
		})
	return rows


func _normalize_string_array(value: Variant) -> Array[String]:
	var rows: Array[String] = []
	if not (value is Array):
		return rows
	for row_variant in value:
		var normalized := String(row_variant).strip_edges()
		if normalized.is_empty():
			continue
		rows.append(normalized)
	return rows


func _normalize_dictionary(value: Variant) -> Dictionary:
	return value.duplicate(true) if value is Dictionary else {}


func _normalize_encounter_row(row: Dictionary, row_index: int) -> Dictionary:
	var encounter_id := String(row.get("id", "")).strip_edges().to_lower()
	if encounter_id.is_empty():
		_record_schema_warning("[night_encounters:%d] encounter id must be non-empty" % row_index)
		return {}
	var category := String(row.get("category", "standard")).strip_edges().to_lower()
	if category.is_empty() or not SUPPORTED_CATEGORIES.has(category):
		_record_schema_warning(
			"[night_encounters:%d] encounter '%s' uses unsupported category '%s'"
			% [row_index, encounter_id, category]
		)
		category = "standard"
	var clear_mode := String(row.get("clear_mode", "kill_all")).strip_edges().to_lower()
	if clear_mode.is_empty() or not SUPPORTED_CLEAR_MODES.has(clear_mode):
		_record_schema_warning(
			"[night_encounters:%d] encounter '%s' uses unsupported clear_mode '%s'"
			% [row_index, encounter_id, clear_mode]
		)
		clear_mode = "kill_all"
	var encounter_label := String(row.get("label", encounter_id.capitalize())).strip_edges()
	var objective_id := String(row.get("objective_id", "kill_all")).strip_edges().to_lower()
	if objective_id.is_empty():
		objective_id = "kill_all"
	return {
		"id": encounter_id,
		"schema_contract_version": SCHEMA_CONTRACT_VERSION,
		"label": encounter_label,
		"label_zh": String(row.get("label_zh", "")).strip_edges(),
		"category": category,
		"category_label": String(row.get("category_label", CATEGORY_LABELS.get(category, category.capitalize()))).strip_edges(),
		"category_label_zh": String(row.get("category_label_zh", "")).strip_edges(),
		"reward_table_id": String(row.get("reward_table_id", "combat_%s" % category)).strip_edges(),
		"difficulty": maxi(1, int(row.get("difficulty", 1))),
		"spawn_set_id": String(row.get("spawn_set_id", "")).strip_edges().to_lower(),
		"clear_mode": clear_mode,
		"objective_id": objective_id,
		"objective_label": String(row.get("objective_label", encounter_label)).strip_edges(),
		"objective_label_zh": String(row.get("objective_label_zh", "")).strip_edges(),
		"time_limit_sec": maxf(0.0, float(row.get("time_limit_sec", 0.0))),
		"waves": _normalize_wave_rows(row.get("waves", [])),
		"objective_props": _normalize_objective_props(row.get("objective_props", [])),
		"room_mutators": _normalize_string_array(row.get("room_mutators", [])),
		"success_bonus": _normalize_dictionary(row.get("success_bonus", {})),
		"fail_penalty": _normalize_dictionary(row.get("fail_penalty", {})),
		"telegraph_ui": _normalize_dictionary(row.get("telegraph_ui", {})),
		"runtime_flags": _normalize_dictionary(row.get("runtime_flags", {})),
		"tags": _normalize_string_array(row.get("tags", []))
	}


func _record_schema_warning(message: String) -> void:
	if message.is_empty() or _schema_warnings.has(message):
		return
	_schema_warnings.append(message)
