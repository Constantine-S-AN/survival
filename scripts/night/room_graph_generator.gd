extends RefCounted
class_name RoomGraphGenerator

const DungeonFloorStateClass := preload("res://scripts/night/dungeon_floor_state.gd")
const RoomStateClass := preload("res://scripts/night/room_state.gd")

const ROOM_TYPES_PATH := "res://data/night_room_types.json"
const ROOM_TEMPLATES_PATH := "res://data/night_room_templates.json"
const FLOOR_RULES_PATH := "res://data/night_floor_rules.json"


func build_floors(seed: int = 0) -> Array:
	var room_types := _load_room_types()
	if room_types.is_empty():
		return []
	var room_templates := _load_room_templates_dictionary()
	if room_templates.is_empty():
		return []
	var floor_rules := _load_json_dictionary(FLOOR_RULES_PATH)
	if floor_rules.is_empty():
		return []
	var floor_rows_variant: Variant = floor_rules.get("floors", [])
	if not (floor_rows_variant is Array):
		return []

	var floors: Array = []
	var floor_rows: Array = floor_rows_variant
	for floor_index in range(floor_rows.size()):
		var floor_variant: Variant = floor_rows[floor_index]
		if not (floor_variant is Dictionary):
			continue
		var floor_row: Dictionary = floor_variant
		var floor_state := DungeonFloorStateClass.new()
		floor_state.floor_id = String(floor_row.get("id", "floor_%d" % (floor_index + 1))).strip_edges()
		floor_state.floor_index = floor_index
		floor_state.label = String(floor_row.get("label", "Floor %d" % (floor_index + 1))).strip_edges()
		floor_state.template_id = _select_template_id(floor_row, room_templates, seed, floor_index)
		if floor_state.template_id.is_empty():
			continue
		var template_variant: Variant = room_templates.get(floor_state.template_id, {})
		if not (template_variant is Dictionary):
			continue
		var template: Dictionary = template_variant
		floor_state.start_room_id = String(floor_row.get("start_room_id", template.get("start_room_id", ""))).strip_edges()
		floor_state.goal_room_id = String(floor_row.get("goal_room_id", template.get("goal_room_id", ""))).strip_edges()

		var encounters_variant: Variant = floor_row.get("encounters", template.get("encounters", {}))
		floor_state.encounters = encounters_variant.duplicate(true) if encounters_variant is Dictionary else {}
		_build_floor_rooms(floor_state, template, floor_row, room_types)
		_build_floor_connections(floor_state, template, floor_row)

		if floor_state.start_room_id.is_empty() and not floor_state.room_order.is_empty():
			floor_state.start_room_id = floor_state.room_order[0]
		if floor_state.goal_room_id.is_empty() and not floor_state.room_order.is_empty():
			floor_state.goal_room_id = floor_state.room_order.back()
		floors.append(floor_state)
	return floors


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
		var type_variant: Variant = room_types.get(room_type_id, {})
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
			floor_state.connect_rooms(
				String(connection.get("from", "")).strip_edges(),
				String(connection.get("to", "")).strip_edges()
			)
	var extra_connections_variant: Variant = floor_row.get("extra_connections", [])
	if extra_connections_variant is Array:
		var extra_connections: Array = extra_connections_variant
		for connection_variant in extra_connections:
			if not (connection_variant is Dictionary):
				continue
			var connection: Dictionary = connection_variant
			floor_state.connect_rooms(
				String(connection.get("from", "")).strip_edges(),
				String(connection.get("to", "")).strip_edges()
			)


func _select_template_id(floor_row: Dictionary, templates: Dictionary, seed: int, floor_index: int) -> String:
	var template_id := String(floor_row.get("template_id", "")).strip_edges()
	if not template_id.is_empty():
		return template_id
	var template_ids_variant: Variant = floor_row.get("template_ids", [])
	if not (template_ids_variant is Array):
		return ""
	var template_ids: Array = template_ids_variant
	if template_ids.is_empty():
		return ""
	var seed_basis: int = abs(seed) + floor_index
	var index: int = seed_basis % template_ids.size()
	var chosen := String(template_ids[index]).strip_edges()
	if not templates.has(chosen):
		return ""
	return chosen


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
	var payload := _load_json_dictionary(ROOM_TEMPLATES_PATH)
	if payload.is_empty():
		return {}
	var rows_variant: Variant = payload.get("templates", [])
	if not (rows_variant is Array):
		return {}
	var templates: Dictionary = {}
	var rows: Array = rows_variant
	for row_variant in rows:
		if not (row_variant is Dictionary):
			continue
		var row: Dictionary = row_variant
		var template_id := String(row.get("id", "")).strip_edges()
		if template_id.is_empty():
			continue
		templates[template_id] = row.duplicate(true)
	return templates


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
