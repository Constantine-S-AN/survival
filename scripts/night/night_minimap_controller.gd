extends PanelContainer
class_name NightMinimapController

const BACKDROP_COLOR := Color(0.03, 0.07, 0.10, 0.82)
const EDGE_COLOR := Color(0.33, 0.46, 0.54, 0.82)
const EDGE_ACTIVE_COLOR := Color(0.70, 0.90, 0.96, 0.92)
const UNEXPLORED_COLOR := Color(0.18, 0.21, 0.25, 0.90)
const ROOM_OUTLINE_COLOR := Color(0.07, 0.11, 0.14, 0.98)
const CLEARED_OUTLINE_COLOR := Color(0.90, 0.98, 1.0, 0.96)
const REWARD_BADGE_COLOR := Color(1.0, 0.90, 0.54, 0.98)
const ACTIVE_OUTLINE_COLOR := Color(1.0, 1.0, 1.0, 0.98)
const GOAL_BADGE_COLOR := Color(1.0, 0.44, 0.54, 0.98)
const CURRENT_MARKER_COLOR := Color(0.98, 1.0, 1.0, 1.0)
const MAP_PADDING := Vector2(18.0, 54.0)
const MAP_BOTTOM_PADDING := 18.0
const MIN_ROOM_DRAW_SIZE := Vector2(28.0, 18.0)

@onready var title_label: Label = $TitleLabel
@onready var summary_label: Label = $SummaryLabel

var _map_snapshot: Dictionary = {}


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	title_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	summary_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_refresh_header()


func set_map_snapshot(snapshot: Dictionary) -> void:
	_map_snapshot = snapshot.duplicate(true)
	_refresh_header()
	queue_redraw()


func _refresh_header() -> void:
	var current_room_label := String(_map_snapshot.get("current_room_label", ""))
	var current_room_type := String(_map_snapshot.get("current_room_type_label", ""))
	title_label.text = String(_map_snapshot.get("floor_label", _tr("night.minimap.default_title")))
	if current_room_label.is_empty():
		summary_label.text = _tr("night.minimap.mapping_route")
	elif current_room_type.is_empty():
		summary_label.text = current_room_label
	else:
		summary_label.text = "%s · %s" % [current_room_label, current_room_type]


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), BACKDROP_COLOR, true)
	if _map_snapshot.is_empty():
		return
	var layout_mode := String(_map_snapshot.get("layout_mode", "")).strip_edges().to_lower()
	if layout_mode == "spatial":
		_draw_spatial_map()
		return
	_draw_node_map()


func _draw_spatial_map() -> void:
	var rooms_variant: Variant = _map_snapshot.get("rooms", [])
	if not (rooms_variant is Array):
		return
	var rooms: Array = rooms_variant
	if rooms.is_empty():
		return
	var layout := _resolve_spatial_layout(rooms)
	if layout.is_empty():
		return
	var room_rects_variant: Variant = layout.get("room_rects", {})
	var room_rects_by_room_id: Dictionary = room_rects_variant if room_rects_variant is Dictionary else {}
	var centers_variant: Variant = layout.get("centers", {})
	var centers_by_room_id: Dictionary = centers_variant if centers_variant is Dictionary else {}
	var corridor_width := float(layout.get("corridor_width", 6.0))
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
		if not room_rects_by_room_id.has(from_room_id):
			continue
		var from_rect_variant: Variant = room_rects_by_room_id.get(from_room_id, Rect2())
		var from_rect: Rect2 = from_rect_variant if from_rect_variant is Rect2 else Rect2()
		var from_center: Vector2 = centers_by_room_id.get(from_room_id, Vector2.ZERO)
		var connections_variant: Variant = room.get("connections", [])
		if not (connections_variant is Array):
			continue
		var connections: Array = connections_variant
		for connection_variant in connections:
			var target_room_id := String(connection_variant).strip_edges()
			if target_room_id.is_empty() or not room_rects_by_room_id.has(target_room_id):
				continue
			if from_room_id > target_room_id:
				continue
			var target_rect_variant: Variant = room_rects_by_room_id.get(target_room_id, Rect2())
			var target_rect: Rect2 = target_rect_variant if target_rect_variant is Rect2 else Rect2()
			var target_center: Vector2 = centers_by_room_id.get(target_room_id, Vector2.ZERO)
			var target_room_variant: Variant = rooms_by_id.get(target_room_id, {})
			var target_room: Dictionary = target_room_variant if target_room_variant is Dictionary else {}
			var edge_color := EDGE_ACTIVE_COLOR if _edge_is_explored(room, target_room) else EDGE_COLOR
			var from_port := _resolve_room_connection_port(from_rect, target_center)
			var target_port := _resolve_room_connection_port(target_rect, from_center)
			draw_line(from_port, target_port, edge_color, corridor_width, true)
			draw_circle(from_port, corridor_width * 0.52, edge_color)
			draw_circle(target_port, corridor_width * 0.52, edge_color)

	for room_variant in rooms:
		if not (room_variant is Dictionary):
			continue
		var room: Dictionary = room_variant
		var room_id := String(room.get("id", ""))
		if room_id.is_empty() or not room_rects_by_room_id.has(room_id):
			continue
		var room_rect_variant: Variant = room_rects_by_room_id.get(room_id, Rect2())
		var room_rect: Rect2 = room_rect_variant if room_rect_variant is Rect2 else Rect2()
		var room_center: Vector2 = centers_by_room_id.get(room_id, room_rect.get_center())
		var room_color := _coerce_color(room.get("minimap_color", Color(0.44, 0.76, 0.92, 1.0)), UNEXPLORED_COLOR)
		var room_status := String(room.get("status", "unexplored")).strip_edges().to_lower()
		var reward_claimed := bool(room.get("reward_claimed", false))
		var is_current := room_id == String(_map_snapshot.get("current_room_id", ""))
		var is_goal := bool(room.get("is_goal", false))
		var fill_color := _resolve_room_fill_color(room_color, room_status)
		var outline_color := _resolve_room_outline_color(room_color, room_status)
		draw_rect(room_rect, fill_color, true)
		draw_rect(room_rect, ROOM_OUTLINE_COLOR, false, 2.0, true)
		if room_status == "cleared":
			draw_rect(room_rect.grow(-3.0), CLEARED_OUTLINE_COLOR, false, 2.0, true)
		draw_rect(room_rect, outline_color, false, 3.0 if is_current else 2.0, true)
		if reward_claimed:
			_draw_reward_badge(room_rect)
		if is_goal:
			_draw_goal_badge(room_rect)
		if is_current:
			draw_rect(room_rect.grow(4.0), ACTIVE_OUTLINE_COLOR, false, 2.0, true)
			draw_circle(room_center, maxf(4.0, room_rect.size.y * 0.08), CURRENT_MARKER_COLOR)


func _draw_node_map() -> void:
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
		for connection_variant in (connections_variant as Array):
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
		var node_radius := 12.0 if is_current else 9.0
		draw_circle(node_position, node_radius, fill_color)
		draw_arc(node_position, node_radius + 3.0, 0.0, TAU, 28, ROOM_OUTLINE_COLOR, 2.0, true)
		if room_status == "cleared":
			draw_arc(node_position, node_radius + 6.0, 0.0, TAU, 28, CLEARED_OUTLINE_COLOR, 2.0, true)
		if reward_claimed:
			draw_arc(node_position, node_radius + 10.0, 0.0, TAU, 28, REWARD_BADGE_COLOR, 2.0, true)
		if is_current:
			draw_arc(node_position, node_radius + 14.0, 0.0, TAU, 36, ACTIVE_OUTLINE_COLOR, 2.0, true)


func _resolve_spatial_layout(rooms: Array) -> Dictionary:
	var grid_spacing := _coerce_vector2(_map_snapshot.get("grid_spacing", Vector2(1180.0, 860.0)))
	var raw_rects: Dictionary = {}
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
		var logical_position := _coerce_vector2(room.get("map_position", Vector2.ZERO))
		var room_size := _resolve_room_map_size(room)
		var world_center := Vector2(logical_position.x * grid_spacing.x, logical_position.y * grid_spacing.y)
		var world_rect := Rect2(world_center - room_size * 0.5, room_size)
		raw_rects[room_id] = world_rect
		min_x = minf(min_x, world_rect.position.x)
		max_x = maxf(max_x, world_rect.end.x)
		min_y = minf(min_y, world_rect.position.y)
		max_y = maxf(max_y, world_rect.end.y)
	if raw_rects.is_empty():
		return {}

	var bounds := Rect2(Vector2(min_x, min_y), Vector2(maxf(1.0, max_x - min_x), maxf(1.0, max_y - min_y)))
	var map_rect := Rect2(
		MAP_PADDING,
		Vector2(
			maxf(36.0, size.x - MAP_PADDING.x * 2.0),
			maxf(36.0, size.y - MAP_PADDING.y - MAP_BOTTOM_PADDING)
		)
	)
	var scale := minf(map_rect.size.x / bounds.size.x, map_rect.size.y / bounds.size.y)
	var scaled_bounds_size := bounds.size * scale
	var offset := map_rect.position + (map_rect.size - scaled_bounds_size) * 0.5 - bounds.position * scale
	var room_rects: Dictionary = {}
	var room_centers: Dictionary = {}
	for room_id in raw_rects.keys():
		var world_rect_variant: Variant = raw_rects.get(room_id, Rect2())
		var world_rect: Rect2 = world_rect_variant if world_rect_variant is Rect2 else Rect2()
		var draw_rect := Rect2(world_rect.position * scale + offset, world_rect.size * scale)
		var draw_center := draw_rect.get_center()
		var clamped_size := Vector2(maxf(MIN_ROOM_DRAW_SIZE.x, draw_rect.size.x), maxf(MIN_ROOM_DRAW_SIZE.y, draw_rect.size.y))
		draw_rect = Rect2(draw_center - clamped_size * 0.5, clamped_size)
		room_rects[room_id] = draw_rect
		room_centers[room_id] = draw_rect.get_center()
	return {
		"room_rects": room_rects,
		"centers": room_centers,
		"corridor_width": maxf(6.0, float(_map_snapshot.get("corridor_width", 96.0)) * scale)
	}


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


func _resolve_room_map_size(room: Dictionary) -> Vector2:
	var resolved := _coerce_vector2(room.get("map_size", Vector2(900.0, 580.0)))
	if resolved.x <= 0.0 or resolved.y <= 0.0:
		return Vector2(900.0, 580.0)
	return resolved


func _resolve_room_connection_port(room_rect: Rect2, target_center: Vector2) -> Vector2:
	var room_center := room_rect.get_center()
	var delta := target_center - room_center
	if delta.length_squared() <= 0.001:
		return room_center
	var half_size := room_rect.size * 0.5
	var abs_delta := Vector2(absf(delta.x), absf(delta.y))
	if abs_delta.x * half_size.y > abs_delta.y * half_size.x:
		var sign_x := 1.0 if delta.x >= 0.0 else -1.0
		var y_offset := 0.0 if abs_delta.x <= 0.001 else clampf(delta.y * half_size.x / abs_delta.x, -half_size.y, half_size.y)
		return room_center + Vector2(sign_x * half_size.x, y_offset)
	var sign_y := 1.0 if delta.y >= 0.0 else -1.0
	var x_offset := 0.0 if abs_delta.y <= 0.001 else clampf(delta.x * half_size.y / abs_delta.y, -half_size.x, half_size.x)
	return room_center + Vector2(x_offset, sign_y * half_size.y)


func _resolve_room_fill_color(room_color: Color, room_status: String) -> Color:
	match room_status:
		"active":
			return room_color.lightened(0.08)
		"cleared":
			return room_color.darkened(0.04)
		_:
			return room_color.lerp(UNEXPLORED_COLOR, 0.72)


func _resolve_room_outline_color(room_color: Color, room_status: String) -> Color:
	if room_status == "unexplored":
		return room_color.lerp(UNEXPLORED_COLOR, 0.38)
	return room_color.lightened(0.16)


func _draw_reward_badge(room_rect: Rect2) -> void:
	var radius := maxf(4.5, minf(room_rect.size.x, room_rect.size.y) * 0.12)
	var badge_center := room_rect.position + Vector2(room_rect.size.x - radius - 6.0, radius + 6.0)
	draw_circle(badge_center, radius, REWARD_BADGE_COLOR)
	draw_arc(badge_center, radius + 2.0, 0.0, TAU, 18, ROOM_OUTLINE_COLOR, 1.5, true)


func _draw_goal_badge(room_rect: Rect2) -> void:
	var radius := maxf(5.0, minf(room_rect.size.x, room_rect.size.y) * 0.14)
	var badge_center := room_rect.position + Vector2(radius + 7.0, radius + 7.0)
	var diamond := PackedVector2Array([
		badge_center + Vector2(0.0, -radius),
		badge_center + Vector2(radius, 0.0),
		badge_center + Vector2(0.0, radius),
		badge_center + Vector2(-radius, 0.0)
	])
	var closed_diamond := PackedVector2Array([
		diamond[0],
		diamond[1],
		diamond[2],
		diamond[3],
		diamond[0]
	])
	draw_colored_polygon(diamond, GOAL_BADGE_COLOR)
	draw_polyline(closed_diamond, ROOM_OUTLINE_COLOR, 1.5, true)


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


func _tr(key: String, args: Dictionary = {}) -> String:
	if Localization != null and Localization.has_method("t"):
		return String(Localization.call("t", key, args))
	return key
