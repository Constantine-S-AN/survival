extends RefCounted
class_name RoomGraphGenerator

const DungeonFloorStateClass := preload("res://scripts/night/dungeon_floor_state.gd")
const RoomStateClass := preload("res://scripts/night/room_state.gd")

const ROOM_TYPES_PATH := "res://data/night_room_types.json"
const ROOM_TEMPLATES_PATH := "res://data/night_room_templates.json"
const FLOOR_RULES_PATH := "res://data/night_floor_rules.json"
const SCHEMA_CONTRACT_VERSION := 1
const FLOOR_SCHEMA_FIELDS: Array[String] = [
	"id",
	"label",
	"label_zh",
	"template_id",
	"template_ids",
	"start_room_id",
	"goal_room_id",
	"map_layout",
	"encounters",
	"room_overrides",
	"extra_connections",
	"mutator_id",
	"mutator_pool"
]
const TEMPLATE_SCHEMA_FIELDS: Array[String] = [
	"id",
	"label",
	"label_zh",
	"start_room_id",
	"goal_room_id",
	"map_layout",
	"encounters",
	"rooms",
	"connections",
	"mutator_id",
	"mutator_pool"
]
const TEMPLATE_ROOM_REQUIRED_FIELDS: Array[String] = [
	"id",
	"room_type_id",
	"scene"
]
const CONNECTION_SCHEMA_FIELDS: Array[String] = [
	"from",
	"to",
	"hidden"
]

var _schema_warnings: Array[String] = []


func build_floors(seed: int = 0, options: Dictionary = {}) -> Array:
	var room_types := _load_room_types()
	if room_types.is_empty():
		return []
	var room_templates := _load_room_templates_dictionary()
	if room_templates.is_empty():
		return []
	var floor_rows := _load_floor_rows()
	if floor_rows.is_empty():
		return []
	if not options.is_empty():
		floor_rows = _apply_build_options(floor_rows, options)
	return build_floors_from_data(room_types, room_templates, floor_rows, seed)


func build_floors_from_data(room_types: Dictionary, room_templates: Dictionary, floor_rows: Array, seed: int = 0) -> Array:
	var floors: Array = []
	for floor_index in range(floor_rows.size()):
		var floor_variant: Variant = floor_rows[floor_index]
		if not (floor_variant is Dictionary):
			continue
		var floor_row: Dictionary = floor_variant
		var floor_id := _resolve_floor_id(floor_row, floor_index)
		var template_ids := _build_template_candidates(floor_row, seed, floor_index)
		if template_ids.is_empty():
			push_warning("Night floor %s has no template candidates." % floor_id)
			continue
		var built_floor := false
		for template_id in template_ids:
			var template_variant: Variant = room_templates.get(template_id, null)
			if not (template_variant is Dictionary):
				push_warning("Night floor %s skipped missing template '%s'." % [floor_id, template_id])
				continue
			var floor_state = _build_floor_state(floor_row, template_variant as Dictionary, room_types, floor_index, template_id, seed)
			if _validate_floor_state(floor_state):
				floors.append(floor_state)
				built_floor = true
				break
			push_warning("Night floor %s rejected invalid template '%s'." % [floor_id, template_id])
		if not built_floor:
			push_warning("Night floor %s could not build a valid room graph." % floor_id)
	return floors


func get_schema_contract() -> Dictionary:
	return {
		"contract_version": SCHEMA_CONTRACT_VERSION,
		"floor_fields": FLOOR_SCHEMA_FIELDS.duplicate(),
		"template_fields": TEMPLATE_SCHEMA_FIELDS.duplicate(),
		"room_required_fields": TEMPLATE_ROOM_REQUIRED_FIELDS.duplicate(),
		"connection_fields": CONNECTION_SCHEMA_FIELDS.duplicate()
	}


func get_schema_warnings() -> Array[String]:
	return _schema_warnings.duplicate()


func _apply_build_options(floor_rows: Array, options: Dictionary) -> Array:
	var normalized_rows: Array = []
	var shorthand_template_id := String(options.get("floor_template_id", "")).strip_edges()
	var overrides_variant: Variant = options.get("floor_template_overrides", {})
	var template_overrides: Dictionary = overrides_variant if overrides_variant is Dictionary else {}
	for floor_variant in floor_rows:
		if not (floor_variant is Dictionary):
			continue
		var floor_row: Dictionary = (floor_variant as Dictionary).duplicate(true)
		var floor_id := String(floor_row.get("id", "")).strip_edges()
		var override_value: Variant = template_overrides.get(floor_id, null)
		if override_value == null and normalized_rows.is_empty() and not shorthand_template_id.is_empty():
			override_value = shorthand_template_id
		if override_value != null:
			var override_template_ids := _normalize_override_template_ids(override_value)
			if not override_template_ids.is_empty():
				floor_row["template_ids"] = override_template_ids
				floor_row["template_id"] = override_template_ids[0]
		normalized_rows.append(floor_row)
	return normalized_rows


func _build_floor_rooms(floor_state, template: Dictionary, floor_row: Dictionary, room_types: Dictionary) -> void:
	var template_rooms_variant: Variant = template.get("rooms", [])
	if not (template_rooms_variant is Array):
		return
	var room_overrides_variant: Variant = floor_row.get("room_overrides", {})
	var room_overrides: Dictionary = room_overrides_variant if room_overrides_variant is Dictionary else {}
	var template_rooms: Array = template_rooms_variant
	for room_variant in template_rooms:
		if not (room_variant is Dictionary):
			continue
		var room_row: Dictionary = (room_variant as Dictionary).duplicate(true)
		var room_id := String(room_row.get("id", "")).strip_edges()
		if room_id.is_empty():
			continue
		var override_variant: Variant = room_overrides.get(room_id, {})
		if override_variant is Dictionary:
			room_row = _merge_room_dictionary(room_row, override_variant as Dictionary)
		var room_type_id := String(room_row.get("room_type_id", room_row.get("type", ""))).strip_edges().to_lower()
		if room_type_id.is_empty() or not room_types.has(room_type_id):
			continue
		var type_variant: Variant = room_types.get(room_type_id, null)
		if not (type_variant is Dictionary):
			continue
		var room_state := RoomStateClass.from_dictionary(
			room_row,
			type_variant as Dictionary,
			floor_state.floor_id,
			floor_state.floor_index
		)
		floor_state.add_room(room_state)


func _build_floor_connections(floor_state, template: Dictionary, floor_row: Dictionary) -> void:
	var template_connections_variant: Variant = template.get("connections", [])
	if template_connections_variant is Array:
		var template_connections: Array = template_connections_variant
		for connection_variant in template_connections:
			if not (connection_variant is Dictionary):
				continue
			var connection: Dictionary = connection_variant
			var from_room_id := String(connection.get("from", "")).strip_edges()
			var to_room_id := String(connection.get("to", "")).strip_edges()
			var metadata := connection.duplicate(true)
			metadata.erase("from")
			metadata.erase("to")
			floor_state.connect_rooms(from_room_id, to_room_id, metadata)
			if bool(metadata.get("hidden", false)):
				var target_room: RoomState = floor_state.get_room(to_room_id)
				if target_room != null:
					target_room.metadata["hidden_room"] = true
	var extra_connections_variant: Variant = floor_row.get("extra_connections", [])
	if extra_connections_variant is Array:
		var extra_connections: Array = extra_connections_variant
		for connection_variant in extra_connections:
			if not (connection_variant is Dictionary):
				continue
			var connection: Dictionary = connection_variant
			var from_room_id := String(connection.get("from", "")).strip_edges()
			var to_room_id := String(connection.get("to", "")).strip_edges()
			var metadata := connection.duplicate(true)
			metadata.erase("from")
			metadata.erase("to")
			floor_state.connect_rooms(from_room_id, to_room_id, metadata)
			if bool(metadata.get("hidden", false)):
				var target_room: RoomState = floor_state.get_room(to_room_id)
				if target_room != null:
					target_room.metadata["hidden_room"] = true


func _build_floor_state(
	floor_row: Dictionary,
	template: Dictionary,
	room_types: Dictionary,
	floor_index: int,
	template_id: String,
	seed: int
) -> DungeonFloorState:
	var floor_state := DungeonFloorStateClass.new()
	floor_state.floor_id = _resolve_floor_id(floor_row, floor_index)
	floor_state.floor_index = floor_index
	var floor_label_fallback := String(floor_row.get("label", "Floor %d" % (floor_index + 1))).strip_edges()
	if Localization != null and Localization.has_method("data_field"):
		floor_state.label = String(Localization.call("data_field", floor_state.floor_id, "label", floor_label_fallback, floor_row))
	else:
		floor_state.label = floor_label_fallback
	floor_state.template_id = template_id
	var start_room_id := String(floor_row.get("start_room_id", "")).strip_edges()
	if start_room_id.is_empty():
		start_room_id = String(template.get("start_room_id", "")).strip_edges()
	floor_state.start_room_id = start_room_id
	var goal_room_id := String(floor_row.get("goal_room_id", "")).strip_edges()
	if goal_room_id.is_empty():
		goal_room_id = String(template.get("goal_room_id", "")).strip_edges()
	floor_state.goal_room_id = goal_room_id
	var map_layout_variant: Variant = floor_row.get("map_layout", {})
	if not (map_layout_variant is Dictionary) or (map_layout_variant as Dictionary).is_empty():
		map_layout_variant = template.get("map_layout", {})
	var map_layout: Dictionary = map_layout_variant if map_layout_variant is Dictionary else {}
	var default_grid_spacing := floor_state.map_grid_spacing
	floor_state.map_grid_spacing = _coerce_vector2(map_layout.get("grid_spacing", default_grid_spacing), default_grid_spacing)
	floor_state.map_corridor_width = maxf(48.0, float(map_layout.get("corridor_width", floor_state.map_corridor_width)))
	var encounters_variant: Variant = floor_row.get("encounters", {})
	if not (encounters_variant is Dictionary) or (encounters_variant as Dictionary).is_empty():
		encounters_variant = template.get("encounters", {})
	floor_state.encounters = encounters_variant.duplicate(true) if encounters_variant is Dictionary else {}
	floor_state.floor_mutator_id = _resolve_floor_mutator_id(floor_row, template, floor_index, template_id, seed)
	floor_state.floor_mutator = {
		"id": floor_state.floor_mutator_id
	} if not floor_state.floor_mutator_id.is_empty() else {}
	_build_floor_rooms(floor_state, template, floor_row, room_types)
	_build_floor_connections(floor_state, template, floor_row)
	return floor_state


func _build_template_candidates(floor_row: Dictionary, seed: int, floor_index: int) -> Array[String]:
	var candidates: Array[String] = []
	var template_id := String(floor_row.get("template_id", "")).strip_edges()
	if not template_id.is_empty():
		candidates.append(template_id)
	var template_ids_variant: Variant = floor_row.get("template_ids", [])
	if not (template_ids_variant is Array):
		return candidates
	var template_ids: Array = template_ids_variant
	if template_ids.is_empty():
		return candidates
	var normalized_candidates: Array[String] = []
	for template_variant in template_ids:
		var normalized := String(template_variant).strip_edges()
		if normalized.is_empty() or normalized_candidates.has(normalized):
			continue
		normalized_candidates.append(normalized)
	if normalized_candidates.is_empty():
		return candidates
	var seed_basis: int = abs(seed) + floor_index
	var index: int = seed_basis % normalized_candidates.size()
	for offset in range(normalized_candidates.size()):
		var chosen := normalized_candidates[(index + offset) % normalized_candidates.size()]
		if candidates.has(chosen):
			continue
		candidates.append(chosen)
	return candidates


func _validate_floor_state(floor_state: DungeonFloorState) -> bool:
	if floor_state == null:
		return false
	if floor_state.room_order.is_empty():
		push_warning("Night floor %s has no valid rooms." % floor_state.floor_id)
		return false
	_sanitize_floor_connections(floor_state)
	var resolved_start_room_id := _resolve_start_room_id(floor_state)
	if resolved_start_room_id.is_empty():
		push_warning("Night floor %s has no usable start room." % floor_state.floor_id)
		return false
	if resolved_start_room_id != floor_state.start_room_id:
		push_warning(
			"Night floor %s remapped invalid start room '%s' to '%s'."
			% [floor_state.floor_id, floor_state.start_room_id, resolved_start_room_id]
		)
	floor_state.start_room_id = resolved_start_room_id
	var reachable_room_ids := _collect_reachable_room_ids(floor_state, resolved_start_room_id)
	if reachable_room_ids.is_empty():
		push_warning("Night floor %s could not traverse from start room '%s'." % [floor_state.floor_id, resolved_start_room_id])
		return false
	var resolved_goal_room_id := _resolve_goal_room_id(floor_state, reachable_room_ids)
	if resolved_goal_room_id.is_empty():
		push_warning("Night floor %s has no usable goal room." % floor_state.floor_id)
		return false
	if resolved_goal_room_id != floor_state.goal_room_id:
		push_warning(
			"Night floor %s remapped invalid goal room '%s' to '%s'."
			% [floor_state.floor_id, floor_state.goal_room_id, resolved_goal_room_id]
		)
	floor_state.goal_room_id = resolved_goal_room_id
	_apply_goal_room_flag(floor_state)
	if reachable_room_ids.size() < floor_state.room_order.size():
		push_warning(
			"Night floor %s contains unreachable rooms from start '%s': %s"
			% [floor_state.floor_id, floor_state.start_room_id, str(_collect_unreachable_room_ids(floor_state, reachable_room_ids))]
		)
	return true


func _sanitize_floor_connections(floor_state: DungeonFloorState) -> void:
	for room_id in floor_state.room_order:
		var room := floor_state.get_room(room_id)
		if room == null:
			continue
		var sanitized_connections: Array[String] = []
		for target_room_id in room.connections:
			var normalized_target := target_room_id.strip_edges()
			if normalized_target.is_empty() or not floor_state.has_room(normalized_target):
				continue
			if sanitized_connections.has(normalized_target):
				continue
			sanitized_connections.append(normalized_target)
		if sanitized_connections.size() != room.connections.size():
			push_warning(
				"Night floor %s dropped invalid connections from room '%s'."
				% [floor_state.floor_id, room.room_id]
			)
		room.connections = sanitized_connections


func _resolve_start_room_id(floor_state: DungeonFloorState) -> String:
	var candidate := floor_state.start_room_id.strip_edges()
	if not candidate.is_empty() and floor_state.has_room(candidate):
		return candidate
	for room_id in floor_state.room_order:
		if floor_state.has_room(room_id):
			return room_id
	return ""


func _collect_reachable_room_ids(floor_state: DungeonFloorState, start_room_id: String) -> Array[String]:
	var start_id := start_room_id.strip_edges()
	if start_id.is_empty() or not floor_state.has_room(start_id):
		return []
	var pending: Array[String] = [start_id]
	var visited: Array[String] = []
	while not pending.is_empty():
		var room_id: String = pending.pop_front()
		if visited.has(room_id):
			continue
		visited.append(room_id)
		var room := floor_state.get_room(room_id)
		if room == null:
			continue
		for target_room_id in room.connections:
			if floor_state.has_room(target_room_id) and not visited.has(target_room_id) and not pending.has(target_room_id):
				pending.append(target_room_id)
	return visited


func _resolve_goal_room_id(floor_state: DungeonFloorState, reachable_room_ids: Array[String]) -> String:
	var candidate := floor_state.goal_room_id.strip_edges()
	if not candidate.is_empty() and floor_state.has_room(candidate) and reachable_room_ids.has(candidate):
		return candidate
	for index in range(floor_state.room_order.size() - 1, -1, -1):
		var room_id := floor_state.room_order[index]
		if not reachable_room_ids.has(room_id):
			continue
		var room := floor_state.get_room(room_id)
		if room != null and room.is_goal:
			return room_id
	for index in range(floor_state.room_order.size() - 1, -1, -1):
		var room_id := floor_state.room_order[index]
		if not reachable_room_ids.has(room_id):
			continue
		var room := floor_state.get_room(room_id)
		if room == null:
			continue
		var has_reachable_exit := false
		for target_room_id in room.connections:
			if reachable_room_ids.has(target_room_id):
				has_reachable_exit = true
				break
		if not has_reachable_exit:
			return room_id
	for index in range(floor_state.room_order.size() - 1, -1, -1):
		var room_id := floor_state.room_order[index]
		if reachable_room_ids.has(room_id):
			return room_id
	return ""


func _apply_goal_room_flag(floor_state: DungeonFloorState) -> void:
	for room_id in floor_state.room_order:
		var room := floor_state.get_room(room_id)
		if room == null:
			continue
		room.is_goal = room.room_id == floor_state.goal_room_id


func _collect_unreachable_room_ids(floor_state: DungeonFloorState, reachable_room_ids: Array[String]) -> Array[String]:
	var unreachable_room_ids: Array[String] = []
	for room_id in floor_state.room_order:
		if reachable_room_ids.has(room_id):
			continue
		unreachable_room_ids.append(room_id)
	return unreachable_room_ids


func _resolve_floor_id(floor_row: Dictionary, floor_index: int) -> String:
	return String(floor_row.get("id", "floor_%d" % (floor_index + 1))).strip_edges()


func _resolve_floor_mutator_id(
	floor_row: Dictionary,
	template: Dictionary,
	floor_index: int,
	template_id: String,
	seed: int
) -> String:
	var mutator_id := String(floor_row.get("mutator_id", "")).strip_edges().to_lower()
	if mutator_id.is_empty():
		mutator_id = String(template.get("mutator_id", "")).strip_edges().to_lower()
	if not mutator_id.is_empty():
		return mutator_id
	var mutator_pool_variant: Variant = floor_row.get("mutator_pool", [])
	if not (mutator_pool_variant is Array) or (mutator_pool_variant as Array).is_empty():
		mutator_pool_variant = template.get("mutator_pool", [])
	if not (mutator_pool_variant is Array):
		return ""
	var mutator_pool: Array = mutator_pool_variant
	var normalized_pool: Array[String] = []
	for mutator_variant in mutator_pool:
		var normalized := String(mutator_variant).strip_edges().to_lower()
		if normalized.is_empty() or normalized_pool.has(normalized):
			continue
		normalized_pool.append(normalized)
	if normalized_pool.is_empty():
		return ""
	var seed_basis: int = abs(seed) + floor_index * 131
	var token := "%s|%s" % [_resolve_floor_id(floor_row, floor_index), template_id]
	for character in token.to_utf8_buffer():
		seed_basis = int((seed_basis * 33 + int(character) + 17) & 0x7fffffff)
	return normalized_pool[seed_basis % normalized_pool.size()]


func _coerce_vector2(value: Variant, fallback: Vector2) -> Vector2:
	if value is Vector2:
		return value
	if value is Array:
		var parts: Array = value
		if parts.size() >= 2:
			return Vector2(float(parts[0]), float(parts[1]))
	if value is Dictionary:
		var payload: Dictionary = value
		return Vector2(float(payload.get("x", fallback.x)), float(payload.get("y", fallback.y)))
	return fallback


func _merge_room_dictionary(base_room: Dictionary, override_room: Dictionary) -> Dictionary:
	var merged := base_room.duplicate(true)
	for key in override_room.keys():
		merged[key] = override_room[key]
	return merged


func _load_room_types() -> Dictionary:
	var payload := _load_json_dictionary(ROOM_TYPES_PATH)
	if payload.is_empty():
		return {}
	var rows_variant: Variant = payload.get("room_types", [])
	if not (rows_variant is Array):
		return {}
	var room_types: Dictionary = {}
	var rows: Array = rows_variant
	for row_variant in rows:
		if not (row_variant is Dictionary):
			continue
		var row: Dictionary = row_variant
		var room_type_id := String(row.get("id", "")).strip_edges().to_lower()
		if room_type_id.is_empty():
			continue
		room_types[room_type_id] = row.duplicate(true)
	return room_types


func _load_room_templates_dictionary() -> Dictionary:
	_schema_warnings.clear()
	var payload := _load_json_dictionary(ROOM_TEMPLATES_PATH)
	if payload.is_empty():
		_record_schema_warning("[night_room_templates] missing or invalid template payload")
		return {}
	if not payload.has("schema_contract_version"):
		_record_schema_warning("[night_room_templates] missing schema_contract_version")
	var template_contract_version := int(payload.get("schema_contract_version", SCHEMA_CONTRACT_VERSION))
	if template_contract_version != SCHEMA_CONTRACT_VERSION:
		_record_schema_warning(
			"[night_room_templates] schema_contract_version %d does not match expected %d"
			% [template_contract_version, SCHEMA_CONTRACT_VERSION]
		)
	var rows_variant: Variant = payload.get("templates", [])
	if not (rows_variant is Array):
		_record_schema_warning("[night_room_templates] templates must be an array")
		return {}
	var templates: Dictionary = {}
	var rows: Array = rows_variant
	for row_index in range(rows.size()):
		var row_variant: Variant = rows[row_index]
		if not (row_variant is Dictionary):
			_record_schema_warning("[night_room_templates:%d] template must be a dictionary" % row_index)
			continue
		var row: Dictionary = _normalize_template_row(row_variant as Dictionary, row_index)
		var template_id := String(row.get("id", "")).strip_edges()
		if template_id.is_empty():
			continue
		templates[template_id] = row.duplicate(true)
	return templates


func _load_floor_rows() -> Array:
	var payload := _load_json_dictionary(FLOOR_RULES_PATH)
	if payload.is_empty():
		_record_schema_warning("[night_floor_rules] missing or invalid floor payload")
		return []
	if not payload.has("schema_contract_version"):
		_record_schema_warning("[night_floor_rules] missing schema_contract_version")
	var floor_contract_version := int(payload.get("schema_contract_version", SCHEMA_CONTRACT_VERSION))
	if floor_contract_version != SCHEMA_CONTRACT_VERSION:
		_record_schema_warning(
			"[night_floor_rules] schema_contract_version %d does not match expected %d"
			% [floor_contract_version, SCHEMA_CONTRACT_VERSION]
		)
	var rows_variant: Variant = payload.get("floors", [])
	if not (rows_variant is Array):
		_record_schema_warning("[night_floor_rules] floors must be an array")
		return []
	var normalized_rows: Array = []
	var rows: Array = rows_variant
	for row_index in range(rows.size()):
		var row_variant: Variant = rows[row_index]
		if not (row_variant is Dictionary):
			_record_schema_warning("[night_floor_rules:%d] floor must be a dictionary" % row_index)
			continue
		normalized_rows.append(_normalize_floor_row(row_variant as Dictionary, row_index))
	return normalized_rows


func _load_json_dictionary(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		push_warning("Night room config missing: %s" % path)
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_warning("Night room config could not open: %s" % path)
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if parsed is Dictionary:
		return (parsed as Dictionary).duplicate(true)
	push_warning("Night room config must be a dictionary: %s" % path)
	return {}


func _normalize_floor_row(row: Dictionary, row_index: int) -> Dictionary:
	var floor_id := _resolve_floor_id(row, row_index)
	var template_ids := _normalize_string_array(row.get("template_ids", []))
	var template_id := String(row.get("template_id", "")).strip_edges()
	if template_ids.is_empty() and template_id.is_empty():
		_record_schema_warning("[night_floor_rules:%d] floor '%s' has no template_id or template_ids" % [row_index, floor_id])
	var normalized := {
		"id": floor_id,
		"label": String(row.get("label", "Floor %d" % (row_index + 1))).strip_edges(),
		"label_zh": String(row.get("label_zh", "")).strip_edges(),
		"template_id": template_id,
		"template_ids": template_ids,
		"start_room_id": String(row.get("start_room_id", "")).strip_edges(),
		"goal_room_id": String(row.get("goal_room_id", "")).strip_edges(),
		"map_layout": _normalize_map_layout(row.get("map_layout", {}), Vector2(1180.0, 860.0), 96.0),
		"encounters": _normalize_dictionary_map(row.get("encounters", {})),
		"room_overrides": _normalize_dictionary_map(row.get("room_overrides", {})),
		"extra_connections": _normalize_connection_rows(row.get("extra_connections", []), "night_floor_rules:%d" % row_index),
		"mutator_id": String(row.get("mutator_id", "")).strip_edges().to_lower(),
		"mutator_pool": _normalize_string_array(row.get("mutator_pool", []))
	}
	return normalized


func _normalize_template_row(row: Dictionary, row_index: int) -> Dictionary:
	var template_id := String(row.get("id", "")).strip_edges()
	if template_id.is_empty():
		_record_schema_warning("[night_room_templates:%d] template id must be non-empty" % row_index)
		return {}
	var normalized := {
		"id": template_id,
		"label": String(row.get("label", template_id.capitalize())).strip_edges(),
		"label_zh": String(row.get("label_zh", "")).strip_edges(),
		"start_room_id": String(row.get("start_room_id", "")).strip_edges(),
		"goal_room_id": String(row.get("goal_room_id", "")).strip_edges(),
		"map_layout": _normalize_map_layout(row.get("map_layout", {}), Vector2(1180.0, 860.0), 96.0),
		"encounters": _normalize_dictionary_map(row.get("encounters", {})),
		"rooms": _normalize_template_rooms(row.get("rooms", []), "night_room_templates:%d" % row_index),
		"connections": _normalize_connection_rows(row.get("connections", []), "night_room_templates:%d" % row_index),
		"mutator_id": String(row.get("mutator_id", "")).strip_edges().to_lower(),
		"mutator_pool": _normalize_string_array(row.get("mutator_pool", []))
	}
	if (normalized["rooms"] as Array).is_empty():
		_record_schema_warning("[night_room_templates:%d] template '%s' has no rooms" % [row_index, template_id])
	return normalized


func _normalize_template_rooms(value: Variant, owner_label: String) -> Array:
	var rows: Array = []
	if not (value is Array):
		_record_schema_warning("[%s] rooms must be an array" % owner_label)
		return rows
	var source_rows: Array = value
	for row_index in range(source_rows.size()):
		var row_variant: Variant = source_rows[row_index]
		if not (row_variant is Dictionary):
			_record_schema_warning("[%s:room:%d] room must be a dictionary" % [owner_label, row_index])
			continue
		var room: Dictionary = (row_variant as Dictionary).duplicate(true)
		var room_id := String(room.get("id", room.get("room_id", ""))).strip_edges()
		if room_id.is_empty():
			_record_schema_warning("[%s:room:%d] room id must be non-empty" % [owner_label, row_index])
			continue
		room["id"] = room_id
		room["room_type_id"] = String(room.get("room_type_id", room.get("type", ""))).strip_edges().to_lower()
		room["scene"] = String(room.get("scene", "")).strip_edges()
		room["encounter_id"] = String(room.get("encounter_id", "")).strip_edges().to_lower()
		if String(room.get("room_type_id", "")).strip_edges().is_empty():
			_record_schema_warning("[%s:room:%d] room '%s' missing room_type_id" % [owner_label, row_index, room_id])
		rows.append(room)
	return rows


func _normalize_connection_rows(value: Variant, owner_label: String) -> Array:
	var rows: Array = []
	if not (value is Array):
		if not owner_label.is_empty():
			_record_schema_warning("[%s] connections must be an array" % owner_label)
		return rows
	var source_rows: Array = value
	for row_index in range(source_rows.size()):
		var row_variant: Variant = source_rows[row_index]
		if not (row_variant is Dictionary):
			_record_schema_warning("[%s:connection:%d] connection must be a dictionary" % [owner_label, row_index])
			continue
		var row: Dictionary = row_variant
		var from_room_id := String(row.get("from", "")).strip_edges()
		var to_room_id := String(row.get("to", "")).strip_edges()
		if from_room_id.is_empty() or to_room_id.is_empty():
			_record_schema_warning("[%s:connection:%d] connection must define non-empty from/to" % [owner_label, row_index])
			continue
		var normalized := {
			"from": from_room_id,
			"to": to_room_id,
			"hidden": bool(row.get("hidden", false))
		}
		for key_variant in row.keys():
			var key := String(key_variant)
			if key == "from" or key == "to" or key == "hidden":
				continue
			normalized[key] = row[key_variant]
		rows.append(normalized)
	return rows


func _normalize_map_layout(value: Variant, default_grid_spacing: Vector2, default_corridor_width: float) -> Dictionary:
	var source: Dictionary = value if value is Dictionary else {}
	return {
		"grid_spacing": _coerce_vector2(source.get("grid_spacing", default_grid_spacing), default_grid_spacing),
		"corridor_width": maxf(48.0, float(source.get("corridor_width", default_corridor_width)))
	}


func _normalize_dictionary_map(value: Variant) -> Dictionary:
	if not (value is Dictionary):
		return {}
	var normalized: Dictionary = {}
	var source: Dictionary = value
	for key_variant in source.keys():
		var key := String(key_variant).strip_edges()
		if key.is_empty():
			continue
		var row_variant: Variant = source.get(key_variant, {})
		normalized[key] = row_variant.duplicate(true) if row_variant is Dictionary else {}
	return normalized


func _normalize_string_array(value: Variant) -> Array[String]:
	var rows: Array[String] = []
	if not (value is Array):
		return rows
	var source_rows: Array = value
	for row_variant in source_rows:
		var normalized := String(row_variant).strip_edges()
		if normalized.is_empty() or rows.has(normalized):
			continue
		rows.append(normalized)
	return rows


func _normalize_override_template_ids(value: Variant) -> Array[String]:
	if value is String:
		var template_id := String(value).strip_edges()
		var rows: Array[String] = []
		if not template_id.is_empty():
			rows.append(template_id)
		return rows
	return _normalize_string_array(value)


func _record_schema_warning(message: String) -> void:
	if message.is_empty() or _schema_warnings.has(message):
		return
	_schema_warnings.append(message)
