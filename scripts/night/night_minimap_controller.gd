extends PanelContainer
class_name NightMinimapController

const BACKDROP_COLOR := Color(0.03, 0.07, 0.10, 0.82)
const EDGE_COLOR := Color(0.33, 0.46, 0.54, 0.82)
const EDGE_ACTIVE_COLOR := Color(0.70, 0.90, 0.96, 0.92)
const UNEXPLORED_COLOR := Color(0.18, 0.21, 0.25, 0.90)
const CLEARED_RING_COLOR := Color(0.90, 0.98, 1.0, 0.96)
const REWARD_RING_COLOR := Color(1.0, 0.90, 0.54, 0.98)
const ACTIVE_RING_COLOR := Color(1.0, 1.0, 1.0, 0.98)
const MAP_PADDING := Vector2(18.0, 54.0)
const MAP_BOTTOM_PADDING := 18.0
const NODE_RADIUS := 9.0
const ACTIVE_NODE_RADIUS := 12.0

@onready var title_label: Label = $TitleLabel
@onready var summary_label: Label = $SummaryLabel

var _map_snapshot: Dictionary = {}


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	title_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	summary_label.mouse_filter = Control.MOUSE_FILTER_IGNORE


func set_map_snapshot(snapshot: Dictionary) -> void:
	_map_snapshot = snapshot.duplicate(true)
	var current_room_label := String(_map_snapshot.get("current_room_label", ""))
	var current_room_type := String(_map_snapshot.get("current_room_type_label", ""))
	title_label.text = String(_map_snapshot.get("floor_label", "Night Route"))
	if current_room_label.is_empty():
		summary_label.text = "Mapping route"
	elif current_room_type.is_empty():
		summary_label.text = current_room_label
	else:
		summary_label.text = "%s · %s" % [current_room_label, current_room_type]
	queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), BACKDROP_COLOR, true)
	if _map_snapshot.is_empty():
		return
	var rooms_variant: Variant = _map_snapshot.get("rooms", [])
	if not (rooms_variant is Array):
		return
	var rooms: Array = rooms_variant
	if rooms.is_empty():
		return
	var positions_by_room_id := _resolve_node_positions(rooms)
	var rooms_by_id: Dictionary = {}
	for room_variant in rooms:
		if not (room_variant is Dictionary):
			continue
		var room: Dictionary = room_variant
		var room_id := String(room.get("id", ""))
		if room_id.is_empty():
			continue
		rooms_by_id[room_id] = room

	for room_variant in rooms:
		if not (room_variant is Dictionary):
			continue
		var room: Dictionary = room_variant
		var from_room_id := String(room.get("id", ""))
		if from_room_id.is_empty():
			continue
		var from_position: Vector2 = positions_by_room_id.get(from_room_id, Vector2.ZERO)
		var connections_variant: Variant = room.get("connections", [])
		if not (connections_variant is Array):
			continue
		var connections: Array = connections_variant
		for connection_variant in connections:
			var target_room_id := String(connection_variant).strip_edges()
			if target_room_id.is_empty() or not positions_by_room_id.has(target_room_id):
				continue
			if from_room_id > target_room_id:
				continue
			var target_position: Vector2 = positions_by_room_id[target_room_id]
			var target_room_variant: Variant = rooms_by_id.get(target_room_id, {})
			var target_room: Dictionary = target_room_variant if target_room_variant is Dictionary else {}
			var edge_color := EDGE_ACTIVE_COLOR if _edge_is_explored(room, target_room) else EDGE_COLOR
			draw_line(from_position, target_position, edge_color, 3.0, true)

	for room_variant in rooms:
		if not (room_variant is Dictionary):
			continue
		var room: Dictionary = room_variant
		var room_id := String(room.get("id", ""))
		var node_position: Vector2 = positions_by_room_id.get(room_id, Vector2.ZERO)
		var room_color := _coerce_color(room.get("minimap_color", Color(0.44, 0.76, 0.92, 1.0)), UNEXPLORED_COLOR)
		var room_status := String(room.get("status", "unexplored")).strip_edges().to_lower()
		var reward_claimed := bool(room.get("reward_claimed", false))
		var is_current := room_id == String(_map_snapshot.get("current_room_id", ""))
		var fill_color := room_color if room_status != "unexplored" else UNEXPLORED_COLOR
		var node_radius := ACTIVE_NODE_RADIUS if is_current else NODE_RADIUS
		draw_circle(node_position, node_radius, fill_color)
		draw_arc(node_position, node_radius + 3.0, 0.0, TAU, 28, Color(0.02, 0.04, 0.05, 0.9), 2.0, true)
		if room_status == "cleared":
			draw_arc(node_position, node_radius + 6.0, 0.0, TAU, 28, CLEARED_RING_COLOR, 2.0, true)
		if reward_claimed:
			draw_arc(node_position, node_radius + 10.0, 0.0, TAU, 28, REWARD_RING_COLOR, 2.0, true)
		if is_current:
			draw_arc(node_position, node_radius + 14.0, 0.0, TAU, 36, ACTIVE_RING_COLOR, 2.0, true)


func _resolve_node_positions(rooms: Array) -> Dictionary:
	var raw_positions: Dictionary = {}
	var min_x := INF
	var max_x := -INF
	var min_y := INF
	var max_y := -INF
	for room_variant in rooms:
		if not (room_variant is Dictionary):
			continue
		var room: Dictionary = room_variant
		var room_id := String(room.get("id", ""))
		if room_id.is_empty():
			continue
		var map_position := _coerce_vector2(room.get("map_position", Vector2.ZERO))
		raw_positions[room_id] = map_position
		min_x = minf(min_x, map_position.x)
		max_x = maxf(max_x, map_position.x)
		min_y = minf(min_y, map_position.y)
		max_y = maxf(max_y, map_position.y)
	if raw_positions.is_empty():
		return {}

	var map_rect := Rect2(
		MAP_PADDING,
		Vector2(
			maxf(36.0, size.x - MAP_PADDING.x * 2.0),
			maxf(36.0, size.y - MAP_PADDING.y - MAP_BOTTOM_PADDING)
		)
	)
	var span_x := maxf(1.0, max_x - min_x)
	var span_y := maxf(1.0, max_y - min_y)
	var resolved: Dictionary = {}
	for room_id in raw_positions.keys():
		var raw_position: Vector2 = raw_positions[room_id]
		var normalized := Vector2(
			(raw_position.x - min_x) / span_x,
			(raw_position.y - min_y) / span_y
		)
		resolved[room_id] = Vector2(
			map_rect.position.x + normalized.x * map_rect.size.x,
			map_rect.position.y + normalized.y * map_rect.size.y
		)
	return resolved


func _edge_is_explored(from_room: Dictionary, to_room: Dictionary) -> bool:
	var from_status := String(from_room.get("status", "unexplored")).strip_edges().to_lower()
	var to_status := String(to_room.get("status", "unexplored")).strip_edges().to_lower()
	return from_status != "unexplored" and to_status != "unexplored"


func _coerce_vector2(value: Variant) -> Vector2:
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


func _coerce_color(value: Variant, fallback: Color) -> Color:
	if value is Color:
		return value
	if value is String:
		return Color.from_string(String(value), fallback)
	return fallback
