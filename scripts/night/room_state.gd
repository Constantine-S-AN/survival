extends RefCounted
class_name RoomState

const ROOM_KIND_COMBAT := "combat"
const ROOM_KIND_TRANSITION := "transition"

var room_id: String = ""
var floor_id: String = ""
var floor_index: int = 0
var room_type_id: String = ""
var label: String = ""
var room_kind: String = ROOM_KIND_COMBAT
var scene_path: String = ""
var encounter_id: String = ""
var connections: Array[String] = []
var visited: bool = false
var cleared: bool = false
var is_goal: bool = false
var metadata: Dictionary = {}


static func from_dictionary(room_data: Dictionary, type_data: Dictionary, target_floor_id: String, target_floor_index: int) -> RoomState:
	var state := RoomState.new()
	state.room_id = String(room_data.get("id", room_data.get("room_id", ""))).strip_edges()
	state.floor_id = target_floor_id
	state.floor_index = target_floor_index
	state.room_type_id = String(type_data.get("id", room_data.get("room_type_id", room_data.get("type", "")))).strip_edges().to_lower()
	state.label = String(
		room_data.get("label", room_data.get("title", type_data.get("label", state.room_id.capitalize())))
	).strip_edges()
	state.room_kind = String(room_data.get("kind", type_data.get("kind", ROOM_KIND_COMBAT))).strip_edges().to_lower()
	if state.room_kind != ROOM_KIND_TRANSITION:
		state.room_kind = ROOM_KIND_COMBAT
	state.scene_path = String(room_data.get("scene", type_data.get("scene", ""))).strip_edges()
	state.encounter_id = String(room_data.get("encounter_id", "")).strip_edges().to_lower()
	state.is_goal = bool(room_data.get("is_goal", type_data.get("is_goal", false)))
	var metadata_variant: Variant = room_data.get("metadata", {})
	state.metadata = metadata_variant.duplicate(true) if metadata_variant is Dictionary else {}
	return state


func duplicate_state() -> RoomState:
	var copy := RoomState.new()
	copy.room_id = room_id
	copy.floor_id = floor_id
	copy.floor_index = floor_index
	copy.room_type_id = room_type_id
	copy.label = label
	copy.room_kind = room_kind
	copy.scene_path = scene_path
	copy.encounter_id = encounter_id
	copy.connections = connections.duplicate()
	copy.visited = visited
	copy.cleared = cleared
	copy.is_goal = is_goal
	copy.metadata = metadata.duplicate(true)
	return copy


func to_dictionary() -> Dictionary:
	return {
		"id": room_id,
		"floor_id": floor_id,
		"floor_index": floor_index,
		"room_type_id": room_type_id,
		"label": label,
		"kind": room_kind,
		"scene_path": scene_path,
		"encounter_id": encounter_id,
		"connections": connections.duplicate(),
		"visited": visited,
		"cleared": cleared,
		"is_goal": is_goal,
		"metadata": metadata.duplicate(true)
	}
