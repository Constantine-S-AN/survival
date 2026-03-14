extends RefCounted
class_name RoomGraphGenerator

const DungeonFloorStateClass := preload("res://scripts/night/dungeon_floor_state.gd")
const RoomStateClass := preload("res://scripts/night/room_state.gd")

const ROOM_TYPES_PATH := "res://data/night_room_types.json"
const FLOOR_RULES_PATH := "res://data/night_floor_rules.json"


func build_floors(_seed: int = 0) -> Array:
	var room_types := _load_room_types()
	if room_types.is_empty():
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
		floor_state.start_room_id = String(floor_row.get("start_room_id", "")).strip_edges()
		floor_state.goal_room_id = String(floor_row.get("goal_room_id", "")).strip_edges()
		var encounters_variant: Variant = floor_row.get("encounters", {})
		floor_state.encounters = encounters_variant.duplicate(true) if encounters_variant is Dictionary else {}

		var rooms_variant: Variant = floor_row.get("rooms", [])
		if rooms_variant is Array:
			var room_rows: Array = rooms_variant
			for room_variant in room_rows:
				if not (room_variant is Dictionary):
					continue
				var room_row: Dictionary = room_variant
				var room_type_id := String(room_row.get("room_type_id", room_row.get("type", ""))).strip_edges().to_lower()
				var type_variant: Variant = room_types.get(room_type_id, {})
				if not (type_variant is Dictionary):
					continue
				var room_state := RoomStateClass.from_dictionary(
					room_row,
					type_variant as Dictionary,
					floor_state.floor_id,
					floor_index
				)
				floor_state.add_room(room_state)

		var connections_variant: Variant = floor_row.get("connections", [])
		if connections_variant is Array:
			var connections: Array = connections_variant
			for connection_variant in connections:
				if not (connection_variant is Dictionary):
					continue
				var connection: Dictionary = connection_variant
				floor_state.connect_rooms(
					String(connection.get("from", "")).strip_edges(),
					String(connection.get("to", "")).strip_edges()
				)

		if floor_state.start_room_id.is_empty() and not floor_state.room_order.is_empty():
			floor_state.start_room_id = floor_state.room_order[0]
		if floor_state.goal_room_id.is_empty() and not floor_state.room_order.is_empty():
			floor_state.goal_room_id = floor_state.room_order.back()
		floors.append(floor_state)
	return floors


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
