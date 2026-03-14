extends RefCounted
class_name EncounterDirector

const ENCOUNTERS_PATH := "res://data/night_encounters.json"
const SPAWN_SETS_PATH := "res://data/night_spawn_sets.json"
const CATEGORY_LABELS := {
	"standard": "Standard Combat",
	"elite": "Elite Combat",
	"boss": "Boss Combat"
}

var _encounters_by_id: Dictionary = {}
var _spawn_sets_by_id: Dictionary = {}


func describe_room(floor_state, room_state) -> Dictionary:
	var payload := {
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
	payload["encounter_label"] = String(encounter.get("label", room_state.label)).strip_edges()
	payload["encounter_category"] = category
	payload["encounter_category_label"] = String(
		encounter.get("category_label", CATEGORY_LABELS.get(category, category.capitalize()))
	).strip_edges()
	payload["reward_table_id"] = String(encounter.get("reward_table_id", "combat_%s" % category)).strip_edges()
	payload["spawn_set_id"] = String(encounter.get("spawn_set_id", "")).strip_edges().to_lower()
	payload["difficulty"] = maxi(1, int(encounter.get("difficulty", 1)))
	return payload


func build_room_payload(floor_state, room_state, room_node: Node2D) -> Dictionary:
	var payload := describe_room(floor_state, room_state)
	if not room_state.is_combat_room():
		return payload

	var encounter := _resolve_encounter(floor_state, room_state)
	var spawn_set_id := String(encounter.get("spawn_set_id", "")).strip_edges().to_lower()
	var enemies_variant: Variant = encounter.get("enemies", [])
	if not spawn_set_id.is_empty():
		var spawn_set_variant: Variant = _spawn_sets_by_id.get(spawn_set_id, {})
		if spawn_set_variant is Dictionary:
			enemies_variant = (spawn_set_variant as Dictionary).get("enemies", enemies_variant)
	if not (enemies_variant is Array):
		return payload

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
	payload["enemies"] = enemy_payloads
	return payload


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
			"label": room_state.label,
			"category": "boss" if room_state.room_type_id == room_state.TYPE_BOSS else "standard",
			"reward_table_id": "combat_boss" if room_state.room_type_id == room_state.TYPE_BOSS else "combat_standard",
			"spawn_set_id": "",
			"difficulty": 1,
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
	var payload := _load_json_dictionary(ENCOUNTERS_PATH)
	var rows_variant: Variant = payload.get("encounters", [])
	if rows_variant is Array:
		for row_variant in rows_variant:
			if not (row_variant is Dictionary):
				continue
			var row: Dictionary = row_variant
			var encounter_id := String(row.get("id", "")).strip_edges().to_lower()
			if encounter_id.is_empty():
				continue
			_encounters_by_id[encounter_id] = row.duplicate(true)
	var spawn_payload := _load_json_dictionary(SPAWN_SETS_PATH)
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
