extends RefCounted
class_name BossRoomController

const BOSS_RULES_PATH := "res://data/night_boss_rules.json"

var _rules_by_encounter_id: Dictionary = {}
var _rules_by_boss_id: Dictionary = {}
var _active_rule: Dictionary = {}
var _snapshot: Dictionary = {}
var _bonus_secured: bool = false


func reset() -> void:
	_active_rule.clear()
	_snapshot = _build_default_snapshot()
	_bonus_secured = false


func begin_room(room_state, room_payload: Dictionary) -> Dictionary:
	_ensure_loaded()
	if room_state == null or String(room_state.room_type_id).strip_edges().to_lower() != "boss":
		reset()
		return get_snapshot()
	var encounter_id := String(room_payload.get("encounter_id", room_state.encounter_id)).strip_edges().to_lower()
	var boss_id := _resolve_rule_boss_id(encounter_id)
	_active_rule = _resolve_rule(encounter_id, boss_id)
	_bonus_secured = false
	_snapshot = _build_default_snapshot()
	_snapshot["active"] = true
	_snapshot["encounter_id"] = encounter_id
	_snapshot["boss_id"] = boss_id
	_snapshot["title"] = String(_active_rule.get("climax_title", "Floor Climax")).strip_edges()
	_snapshot["phase_label"] = String(_active_rule.get("intro_label", room_state.label)).strip_edges()
	_snapshot["subtitle"] = String(
		_active_rule.get("intro_text", "A floor-end threat is rising ahead.")
	).strip_edges()
	_snapshot["status"] = "intro"
	return get_snapshot()


func on_boss_spawned(boss_id: String, phase_id: String, telegraph_text: String) -> Dictionary:
	_activate_rule_for_boss(boss_id)
	if _snapshot.is_empty():
		_snapshot = _build_default_snapshot()
	_snapshot["active"] = true
	_snapshot["boss_id"] = boss_id.strip_edges().to_lower()
	_snapshot["phase_id"] = phase_id.strip_edges().to_lower()
	_snapshot["phase_label"] = _resolve_phase_label(phase_id)
	_snapshot["subtitle"] = _resolve_message(telegraph_text, String(_snapshot.get("subtitle", "")))
	_snapshot["status"] = "active"
	return get_snapshot()


func on_boss_phase_changed(boss_id: String, phase_id: String, telegraph_text: String) -> Dictionary:
	_activate_rule_for_boss(boss_id)
	if _snapshot.is_empty():
		_snapshot = _build_default_snapshot()
	_snapshot["active"] = true
	_snapshot["boss_id"] = boss_id.strip_edges().to_lower()
	_snapshot["phase_id"] = phase_id.strip_edges().to_lower()
	_snapshot["phase_label"] = _resolve_phase_label(phase_id)
	_snapshot["subtitle"] = _resolve_message(telegraph_text, String(_snapshot.get("subtitle", "")))
	_snapshot["status"] = "phase"
	return get_snapshot()


func on_boss_defeated(boss_id: String) -> Dictionary:
	_activate_rule_for_boss(boss_id)
	if _snapshot.is_empty():
		_snapshot = _build_default_snapshot()
	_snapshot["active"] = true
	_snapshot["boss_id"] = boss_id.strip_edges().to_lower()
	_snapshot["defeated"] = true
	_snapshot["phase_label"] = String(_active_rule.get("defeat_label", "Boss Down")).strip_edges()
	_snapshot["subtitle"] = String(
		_active_rule.get("defeat_text", "The floor cache is exposed. Finish the run cleanly.")
	).strip_edges()
	_snapshot["status"] = "defeated"
	_bonus_secured = true
	return get_snapshot()


func get_completion_bonus() -> Dictionary:
	if not _bonus_secured:
		return {}
	var materials_variant: Variant = _active_rule.get("boss_bonus_materials", {})
	var materials: Dictionary = _normalize_material_bundle(materials_variant)
	if materials.is_empty():
		return {}
	return {
		"label": String(_active_rule.get("boss_bonus_label", "Boss Cache Secured")).strip_edges(),
		"materials": materials
	}


func finalize_boss_room() -> Dictionary:
	if _active_rule.is_empty():
		return {}
	if not _bonus_secured:
		var boss_id := String(_active_rule.get("boss_id", _snapshot.get("boss_id", ""))).strip_edges().to_lower()
		on_boss_defeated(boss_id)
	return get_completion_bonus()


func get_snapshot() -> Dictionary:
	if _snapshot.is_empty():
		return _build_default_snapshot()
	return _snapshot.duplicate(true)


func _activate_rule_for_boss(boss_id: String) -> void:
	_ensure_loaded()
	var normalized_boss_id := boss_id.strip_edges().to_lower()
	if normalized_boss_id.is_empty():
		return
	if String(_active_rule.get("boss_id", "")).strip_edges().to_lower() == normalized_boss_id:
		return
	_active_rule = _resolve_rule("", normalized_boss_id)


func _resolve_rule_boss_id(encounter_id: String) -> String:
	var rule_variant: Variant = _rules_by_encounter_id.get(encounter_id, {})
	if rule_variant is Dictionary:
		return String((rule_variant as Dictionary).get("boss_id", "")).strip_edges().to_lower()
	return ""


func _resolve_rule(encounter_id: String, boss_id: String) -> Dictionary:
	var normalized_encounter_id := encounter_id.strip_edges().to_lower()
	if not normalized_encounter_id.is_empty():
		var encounter_variant: Variant = _rules_by_encounter_id.get(normalized_encounter_id, {})
		if encounter_variant is Dictionary:
			return (encounter_variant as Dictionary).duplicate(true)
	var normalized_boss_id := boss_id.strip_edges().to_lower()
	if not normalized_boss_id.is_empty():
		var boss_variant: Variant = _rules_by_boss_id.get(normalized_boss_id, {})
		if boss_variant is Dictionary:
			return (boss_variant as Dictionary).duplicate(true)
	return {}


func _resolve_phase_label(phase_id: String) -> String:
	var normalized_phase_id := phase_id.strip_edges().to_lower()
	var phase_labels_variant: Variant = _active_rule.get("phase_labels", {})
	if phase_labels_variant is Dictionary and (phase_labels_variant as Dictionary).has(normalized_phase_id):
		return String((phase_labels_variant as Dictionary).get(normalized_phase_id, normalized_phase_id)).strip_edges()
	var boss_id := String(_active_rule.get("boss_id", "")).strip_edges().to_lower()
	if not boss_id.is_empty() and DataRegistry != null and DataRegistry.has_method("get_boss"):
		var boss_def := DataRegistry.get_boss(boss_id)
		var phases_variant: Variant = boss_def.get("phases", [])
		if phases_variant is Array:
			for phase_variant in phases_variant:
				if not (phase_variant is Dictionary):
					continue
				var phase: Dictionary = phase_variant
				if String(phase.get("id", "")).strip_edges().to_lower() == normalized_phase_id:
					return String(phase.get("label", normalized_phase_id.capitalize())).strip_edges()
	return normalized_phase_id.capitalize() if not normalized_phase_id.is_empty() else "Boss Active"


func _resolve_message(primary_text: String, fallback_text: String) -> String:
	var normalized := primary_text.strip_edges()
	if not normalized.is_empty():
		return normalized
	return fallback_text


func _build_default_snapshot() -> Dictionary:
	return {
		"active": false,
		"encounter_id": "",
		"boss_id": "",
		"title": "Floor Climax",
		"phase_id": "",
		"phase_label": "",
		"subtitle": "",
		"status": "idle",
		"defeated": false
	}


func _normalize_material_bundle(value: Variant) -> Dictionary:
	var normalized: Dictionary = {}
	if not (value is Dictionary):
		return normalized
	for material_id_variant in (value as Dictionary).keys():
		var material_id := String(material_id_variant).strip_edges().to_lower()
		var amount := maxi(0, int((value as Dictionary).get(material_id_variant, 0)))
		if material_id.is_empty() or amount <= 0:
			continue
		normalized[material_id] = amount
	return normalized


func _ensure_loaded() -> void:
	if not _rules_by_encounter_id.is_empty() or not _rules_by_boss_id.is_empty():
		return
	var payload := _load_json_dictionary(BOSS_RULES_PATH)
	var rows_variant: Variant = payload.get("boss_rules", [])
	if not (rows_variant is Array):
		return
	for row_variant in rows_variant:
		if not (row_variant is Dictionary):
			continue
		var row: Dictionary = row_variant
		var encounter_id := String(row.get("encounter_id", "")).strip_edges().to_lower()
		var boss_id := String(row.get("boss_id", "")).strip_edges().to_lower()
		if encounter_id.is_empty() and boss_id.is_empty():
			continue
		var normalized := row.duplicate(true)
		if normalized.has("boss_bonus_materials"):
			normalized["boss_bonus_materials"] = _normalize_material_bundle(normalized.get("boss_bonus_materials", {}))
		if not encounter_id.is_empty():
			_rules_by_encounter_id[encounter_id] = normalized
		if not boss_id.is_empty():
			_rules_by_boss_id[boss_id] = normalized


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
