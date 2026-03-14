extends Area2D
class_name NightHazardZone

const HAZARDS_PATH := "res://data/night_hazards.json"

@export var hazard_id: String = "undertow_pool"
@export var radius: float = 72.0

@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var fill_visual: Polygon2D = $Fill
@onready var ring_visual: Line2D = $Ring

static var _zone_defs: Dictionary = {}

var _zone_def: Dictionary = {}
var _tick_remaining: float = 0.0
var _state_remaining: float = 0.0
var _active: bool = true
var _phase: float = 0.0
var _query_shape: CircleShape2D = CircleShape2D.new()
var _query_params: PhysicsShapeQueryParameters2D = PhysicsShapeQueryParameters2D.new()


func _ready() -> void:
	collision_layer = 0
	collision_mask = 3
	monitoring = true
	monitorable = false
	_query_params.shape = _query_shape
	_query_params.collide_with_bodies = true
	_query_params.collide_with_areas = false
	_query_params.collision_mask = 3
	_load_zone_definition()
	_apply_zone_shape()
	_refresh_visuals()
	set_physics_process(true)


func _physics_process(delta: float) -> void:
	if _zone_def.is_empty():
		return
	_phase += delta
	var active_sec := maxf(0.0, float(_zone_def.get("active_sec", 0.0)))
	var cooldown_sec := maxf(0.0, float(_zone_def.get("cooldown_sec", 0.0)))
	if active_sec > 0.0 or cooldown_sec > 0.0:
		_state_remaining -= delta
		if _state_remaining <= 0.0:
			_active = not _active if cooldown_sec > 0.0 else true
			_state_remaining = active_sec if _active else cooldown_sec
			_refresh_visuals()
	if not _active:
		_tick_visual_only()
		return
	_tick_remaining -= delta
	_tick_visual_only()
	if _tick_remaining > 0.0:
		return
	_tick_remaining = maxf(0.12, float(_zone_def.get("tick_sec", 0.75)))
	_apply_tick_damage()


func _load_zone_definition() -> void:
	_ensure_loaded()
	var normalized_hazard_id := hazard_id.strip_edges().to_lower()
	var zone_variant: Variant = _zone_defs.get(normalized_hazard_id, {})
	_zone_def = zone_variant if zone_variant is Dictionary else {}
	if _zone_def.is_empty():
		_zone_def = {
			"id": normalized_hazard_id,
			"damage": 6.0,
			"tick_sec": 0.75,
			"active_sec": 0.0,
			"cooldown_sec": 0.0,
			"affects_player": true,
			"affects_enemies": true,
			"fill_color": "#4ba3b7",
			"ring_color": "#98ecff"
		}
	_active = true
	_tick_remaining = maxf(0.12, float(_zone_def.get("tick_sec", 0.75)))
	_state_remaining = maxf(0.0, float(_zone_def.get("active_sec", 0.0)))
	if _state_remaining <= 0.0:
		_state_remaining = maxf(0.0, float(_zone_def.get("cooldown_sec", 0.0)))


func _apply_zone_shape() -> void:
	var resolved_radius := maxf(24.0, radius if radius > 0.0 else float(_zone_def.get("radius", 72.0)))
	radius = resolved_radius
	if collision_shape != null and collision_shape.shape is CircleShape2D:
		(collision_shape.shape as CircleShape2D).radius = resolved_radius
	_query_shape.radius = resolved_radius
	if fill_visual != null:
		fill_visual.polygon = _build_circle_polygon(resolved_radius * 0.88, 12)
	if ring_visual != null:
		ring_visual.points = _build_circle_polygon(resolved_radius, 24)


func _refresh_visuals() -> void:
	if fill_visual != null:
		var fill_color := _coerce_color(_zone_def.get("fill_color", "#4ba3b7"), Color(0.29, 0.64, 0.72, 0.56))
		fill_color.a = 0.16 if not _active else maxf(0.18, fill_color.a)
		fill_visual.color = fill_color
	if ring_visual != null:
		var ring_color := _coerce_color(_zone_def.get("ring_color", "#98ecff"), Color(0.60, 0.92, 1.0, 0.84))
		ring_color.a = 0.26 if not _active else maxf(0.34, ring_color.a)
		ring_visual.default_color = ring_color


func _tick_visual_only() -> void:
	if fill_visual != null:
		var wave := 0.5 + 0.5 * sin(_phase * TAU * 0.42)
		var base_alpha := 0.14 if not _active else 0.28
		fill_visual.scale = Vector2.ONE * lerpf(0.96, 1.03, wave)
		fill_visual.color.a = lerpf(base_alpha * 0.8, base_alpha, wave)
	if ring_visual != null:
		var ring_wave := 0.5 + 0.5 * sin(_phase * TAU * 0.68 + 0.4)
		ring_visual.width = lerpf(2.4, 4.0, ring_wave)


func _apply_tick_damage() -> void:
	if not is_inside_tree():
		return
	var space_state := get_world_2d().direct_space_state
	_query_params.transform = Transform2D(0.0, global_position)
	_query_params.exclude = []
	var hits := space_state.intersect_shape(_query_params, 32)
	var damage := maxf(0.0, float(_zone_def.get("damage", 6.0)))
	if damage <= 0.0:
		return
	for hit_variant in hits:
		if not (hit_variant is Dictionary):
			continue
		var collider_variant: Variant = (hit_variant as Dictionary).get("collider", null)
		if not (collider_variant is Node) or not is_instance_valid(collider_variant):
			continue
		var collider := collider_variant as Node
		if collider.is_in_group("player") and bool(_zone_def.get("affects_player", true)) and collider.has_method("take_damage"):
			collider.call("take_damage", damage)
		elif collider.is_in_group("enemy") and bool(_zone_def.get("affects_enemies", true)) and collider.has_method("take_hit"):
			var impulse := Vector2.ZERO
			if collider is Node2D:
				var away := (collider as Node2D).global_position - global_position
				if away.length() > 0.01:
					impulse = away.normalized() * 42.0
			collider.call("take_hit", damage, impulse)


func _build_circle_polygon(target_radius: float, steps: int) -> PackedVector2Array:
	var points := PackedVector2Array()
	for index in range(maxi(6, steps)):
		var angle := TAU * float(index) / float(maxi(6, steps))
		points.append(Vector2.RIGHT.rotated(angle) * target_radius)
	return points


func _coerce_color(value: Variant, fallback: Color) -> Color:
	if value is Color:
		return value
	if value is String:
		return Color.from_string(String(value), fallback)
	return fallback


static func _ensure_loaded() -> void:
	if not _zone_defs.is_empty():
		return
	var payload := _load_json_dictionary(HAZARDS_PATH)
	var rows_variant: Variant = payload.get("zones", [])
	if not (rows_variant is Array):
		return
	for row_variant in rows_variant:
		if not (row_variant is Dictionary):
			continue
		var row: Dictionary = row_variant
		var zone_id := String(row.get("id", "")).strip_edges().to_lower()
		if zone_id.is_empty():
			continue
		_zone_defs[zone_id] = row.duplicate(true)


static func _load_json_dictionary(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if parsed is Dictionary:
		return (parsed as Dictionary).duplicate(true)
	return {}
