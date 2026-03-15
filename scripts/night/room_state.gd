extends RefCounted
class_name RoomState

const TYPE_COMBAT := "combat"
const TYPE_TREASURE := "treasure"
const TYPE_REST := "rest"
const TYPE_EVENT := "event"
const TYPE_BOSS := "boss"

const STATUS_UNEXPLORED := "unexplored"
const STATUS_ACTIVE := "active"
const STATUS_CLEARED := "cleared"
const DEFAULT_MAP_SIZES := {
	TYPE_COMBAT: Vector2(1040.0, 700.0),
	TYPE_TREASURE: Vector2(860.0, 560.0),
	TYPE_REST: Vector2(900.0, 580.0),
	TYPE_EVENT: Vector2(940.0, 620.0),
	TYPE_BOSS: Vector2(1320.0, 860.0)
}

var room_id: String = ""
var floor_id: String = ""
var floor_index: int = 0
var room_type_id: String = TYPE_COMBAT
var room_type_label: String = ""
var label: String = ""
var scene_path: String = ""
var encounter_id: String = ""
var connections: Array[String] = []
var status: String = STATUS_UNEXPLORED
var reward_claimed: bool = false
var visited: bool = false
var is_goal: bool = false
var locks_on_entry: bool = true
var reward_on_enter: bool = false
var map_position: Vector2 = Vector2.ZERO
var map_size: Vector2 = Vector2(1040.0, 700.0)
var minimap_color: Color = Color(0.44, 0.76, 0.92, 1.0)
var exit_color: Color = Color(0.44, 0.76, 0.92, 1.0)
var reward_data: Dictionary = {}
var metadata: Dictionary = {}


static func from_dictionary(room_data: Dictionary, type_data: Dictionary, target_floor_id: String, target_floor_index: int) -> RoomState:
	var state := RoomState.new()
	state.room_id = String(room_data.get("id", room_data.get("room_id", ""))).strip_edges()
	state.floor_id = target_floor_id
	state.floor_index = target_floor_index
	state.room_type_id = String(
		room_data.get("room_type_id", room_data.get("type", type_data.get("id", TYPE_COMBAT)))
	).strip_edges().to_lower()
	var room_type_label_fallback := String(type_data.get("label", state.room_type_id.capitalize())).strip_edges()
	state.room_type_label = _localized_field(state.room_type_id, "label", room_type_label_fallback, type_data)
	var default_room_label := String(type_data.get("room_label", state.room_type_label)).strip_edges()
	var room_label_fallback := String(
		room_data.get("label", room_data.get("title", default_room_label))
	).strip_edges()
	state.label = _localized_field(state.room_id, "label", room_label_fallback, room_data)
	if state.label.is_empty():
		state.label = _localized_field(state.room_type_id, "room_label", default_room_label, type_data)
	state.scene_path = String(room_data.get("scene", type_data.get("scene", ""))).strip_edges()
	state.encounter_id = String(room_data.get("encounter_id", "")).strip_edges().to_lower()
	state.is_goal = bool(room_data.get("is_goal", type_data.get("is_goal", false)))
	state.locks_on_entry = bool(room_data.get("locks_on_entry", type_data.get("locks_on_entry", state.is_combat_room())))
	state.reward_on_enter = bool(room_data.get("reward_on_enter", type_data.get("reward_on_enter", state.has_reward())))
	state.map_position = _coerce_vector2(room_data.get("map_position", type_data.get("map_position", Vector2.ZERO)))
	var default_map_size := _default_map_size_for_type(state.room_type_id)
	state.map_size = _coerce_vector2(room_data.get("map_size", type_data.get("map_size", default_map_size)))
	if state.map_size.x <= 0.0 or state.map_size.y <= 0.0:
		state.map_size = default_map_size
	state.minimap_color = _coerce_color(type_data.get("minimap_color", "#70d3ff"), Color(0.44, 0.76, 0.92, 1.0))
	state.exit_color = _coerce_color(type_data.get("exit_color", "#70d3ff"), state.minimap_color)
	var reward_variant: Variant = room_data.get("reward", type_data.get("reward", {}))
	state.reward_data = reward_variant.duplicate(true) if reward_variant is Dictionary else {}
	var metadata_variant: Variant = room_data.get("metadata", {})
	state.metadata = metadata_variant.duplicate(true) if metadata_variant is Dictionary else {}
	if state.metadata.is_empty():
		state.metadata = {}
	state.metadata["map_position"] = state.map_position
	state.metadata["map_size"] = state.map_size
	state.metadata["room_type_id"] = state.room_type_id
	return state


func duplicate_state() -> RoomState:
	var copy := RoomState.new()
	copy.room_id = room_id
	copy.floor_id = floor_id
	copy.floor_index = floor_index
	copy.room_type_id = room_type_id
	copy.room_type_label = room_type_label
	copy.label = label
	copy.scene_path = scene_path
	copy.encounter_id = encounter_id
	copy.connections = connections.duplicate()
	copy.status = status
	copy.reward_claimed = reward_claimed
	copy.visited = visited
	copy.is_goal = is_goal
	copy.locks_on_entry = locks_on_entry
	copy.reward_on_enter = reward_on_enter
	copy.map_position = map_position
	copy.map_size = map_size
	copy.minimap_color = minimap_color
	copy.exit_color = exit_color
	copy.reward_data = reward_data.duplicate(true)
	copy.metadata = metadata.duplicate(true)
	return copy


func is_combat_room() -> bool:
	return room_type_id == TYPE_COMBAT or room_type_id == TYPE_BOSS


func has_reward() -> bool:
	return room_type_id == TYPE_TREASURE or room_type_id == TYPE_REST or room_type_id == TYPE_EVENT or not reward_data.is_empty()


func set_active() -> void:
	status = STATUS_ACTIVE
	visited = true


func set_cleared() -> void:
	status = STATUS_CLEARED


func mark_reward_claimed() -> void:
	reward_claimed = true


func to_dictionary() -> Dictionary:
	return {
		"id": room_id,
		"floor_id": floor_id,
		"floor_index": floor_index,
		"room_type_id": room_type_id,
		"room_type_label": room_type_label,
		"label": label,
		"scene_path": scene_path,
		"encounter_id": encounter_id,
		"connections": connections.duplicate(),
		"status": status,
		"reward_claimed": reward_claimed,
		"visited": visited,
		"is_goal": is_goal,
		"locks_on_entry": locks_on_entry,
		"reward_on_enter": reward_on_enter,
		"map_position": map_position,
		"map_size": map_size,
		"minimap_color": minimap_color,
		"exit_color": exit_color,
		"reward_data": reward_data.duplicate(true),
		"metadata": metadata.duplicate(true)
	}


static func _coerce_vector2(value: Variant) -> Vector2:
	if value is Vector2:
		return value
	if value is Array:
		var parts: Array = value
		if parts.size() >= 2:
			return Vector2(float(parts[0]), float(parts[1]))
	if value is Dictionary:
		var payload: Dictionary = value
		return Vector2(float(payload.get("x", 0.0)), float(payload.get("y", 0.0)))
	return Vector2.ZERO


static func _coerce_color(value: Variant, fallback: Color) -> Color:
	if value is Color:
		return value
	if value is String:
		return Color.from_string(String(value), fallback)
	return fallback


static func _default_map_size_for_type(room_type_id: String) -> Vector2:
	var normalized := room_type_id.strip_edges().to_lower()
	if DEFAULT_MAP_SIZES.has(normalized):
		return DEFAULT_MAP_SIZES[normalized]
	return DEFAULT_MAP_SIZES[TYPE_COMBAT]


static func _localized_field(entry_id: String, field: String, fallback: String, source: Dictionary = {}) -> String:
	if Localization != null and Localization.has_method("data_field"):
		return String(Localization.call("data_field", entry_id, field, fallback, source))
	return fallback
