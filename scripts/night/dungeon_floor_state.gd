extends RefCounted
class_name DungeonFloorState

var floor_id: String = ""
var floor_index: int = 0
var label: String = ""
var template_id: String = ""
var start_room_id: String = ""
var goal_room_id: String = ""
var map_grid_spacing: Vector2 = Vector2(1180.0, 860.0)
var map_corridor_width: float = 96.0
var route_resource_defaults: Dictionary = {}
var floor_mutator_id: String = ""
var floor_mutator: Dictionary = {}
var room_order: Array[String] = []
var rooms_by_id: Dictionary = {}
var encounters: Dictionary = {}
var connection_metadata_by_source: Dictionary = {}


func add_room(room: RoomState) -> void:
	if room == null or room.room_id.is_empty():
		return
	if not room_order.has(room.room_id):
		room_order.append(room.room_id)
	rooms_by_id[room.room_id] = room


func has_room(room_id: String) -> bool:
	return rooms_by_id.has(room_id.strip_edges())


func get_room(room_id: String) -> RoomState:
	var normalized := room_id.strip_edges()
	if normalized.is_empty():
		return null
	var room_variant: Variant = rooms_by_id.get(normalized, null)
	if room_variant is RoomState:
		return room_variant
	return null


func connect_rooms(from_room_id: String, to_room_id: String, connection_metadata: Dictionary = {}) -> void:
	var from_room := get_room(from_room_id)
	if from_room == null:
		return
	var normalized_target := to_room_id.strip_edges()
	if normalized_target.is_empty():
		return
	if from_room.connections.has(normalized_target):
		return
	from_room.connections.append(normalized_target)
	var normalized_source := from_room_id.strip_edges()
	if normalized_source.is_empty():
		return
	if not connection_metadata_by_source.has(normalized_source):
		connection_metadata_by_source[normalized_source] = {}
	var source_rows_variant: Variant = connection_metadata_by_source.get(normalized_source, {})
	if source_rows_variant is Dictionary:
		var source_rows: Dictionary = (source_rows_variant as Dictionary).duplicate(true)
		source_rows[normalized_target] = connection_metadata.duplicate(true)
		connection_metadata_by_source[normalized_source] = source_rows


func get_connection_metadata(from_room_id: String, to_room_id: String) -> Dictionary:
	var normalized_source := from_room_id.strip_edges()
	var normalized_target := to_room_id.strip_edges()
	if normalized_source.is_empty() or normalized_target.is_empty():
		return {}
	var source_rows_variant: Variant = connection_metadata_by_source.get(normalized_source, {})
	if not (source_rows_variant is Dictionary):
		return {}
	var row_variant: Variant = (source_rows_variant as Dictionary).get(normalized_target, {})
	return row_variant.duplicate(true) if row_variant is Dictionary else {}


func get_connected_room_ids(room_id: String) -> Array[String]:
	var room := get_room(room_id)
	if room == null:
		return []
	return room.connections.duplicate()


func get_rooms_cleared_count() -> int:
	var cleared_total := 0
	for room_id in room_order:
		var room := get_room(room_id)
		if room != null and room.cleared:
			cleared_total += 1
	return cleared_total


func to_dictionary() -> Dictionary:
	var serialized_rooms: Array[Dictionary] = []
	for room_id in room_order:
		var room := get_room(room_id)
		if room == null:
			continue
		serialized_rooms.append(room.to_dictionary())
	return {
		"id": floor_id,
		"floor_index": floor_index,
		"label": label,
		"template_id": template_id,
		"start_room_id": start_room_id,
		"goal_room_id": goal_room_id,
		"map_grid_spacing": map_grid_spacing,
		"map_corridor_width": map_corridor_width,
		"route_resource_defaults": route_resource_defaults.duplicate(true),
		"floor_mutator_id": floor_mutator_id,
		"floor_mutator": floor_mutator.duplicate(true),
		"rooms": serialized_rooms,
		"encounters": encounters.duplicate(true),
		"connection_metadata_by_source": connection_metadata_by_source.duplicate(true)
	}
