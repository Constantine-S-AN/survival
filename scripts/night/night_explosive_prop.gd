extends Node2D
class_name NightExplosiveProp

const HAZARDS_PATH := "res://data/night_hazards.json"

@export var prop_id: String = "volatile_barrel"

@onready var body_blocker: StaticBody2D = $BodyBlocker
@onready var body_shape: CollisionShape2D = $BodyBlocker/CollisionShape2D
@onready var trigger_area: Area2D = $TriggerArea
@onready var trigger_shape: CollisionShape2D = $TriggerArea/CollisionShape2D
@onready var shadow_visual: Polygon2D = $Shadow
@onready var body_visual: Polygon2D = $Body
@onready var warning_ring: Line2D = $WarningRing

static var _prop_defs: Dictionary = {}

var _prop_def: Dictionary = {}
var _armed: bool = true
var _fuse_remaining: float = -1.0
var _phase: float = 0.0
var _query_shape: CircleShape2D = CircleShape2D.new()
var _query_params: PhysicsShapeQueryParameters2D = PhysicsShapeQueryParameters2D.new()


func _ready() -> void:
	_query_params.shape = _query_shape
	_query_params.collide_with_bodies = true
	_query_params.collide_with_areas = false
	_query_params.collision_mask = 3
	_load_prop_definition()
	_apply_shapes()
	_refresh_visuals()
	if trigger_area != null:
		trigger_area.collision_layer = 0
		trigger_area.collision_mask = 3
		if not trigger_area.body_entered.is_connected(_on_trigger_body_entered):
			trigger_area.body_entered.connect(_on_trigger_body_entered)
	set_physics_process(true)


func _physics_process(delta: float) -> void:
	if not _armed:
		return
	_phase += delta
	if _fuse_remaining >= 0.0:
		_fuse_remaining = maxf(0.0, _fuse_remaining - delta)
		_refresh_visuals()
		if _fuse_remaining <= 0.0:
			_explode()
			return
	elif warning_ring != null:
		var wave := 0.5 + 0.5 * sin(_phase * TAU * 0.8)
		warning_ring.width = lerpf(2.0, 3.6, wave)
		warning_ring.modulate.a = lerpf(0.45, 0.88, wave)


func _load_prop_definition() -> void:
	_ensure_loaded()
	var normalized_prop_id := prop_id.strip_edges().to_lower()
	var prop_variant: Variant = _prop_defs.get(normalized_prop_id, {})
	_prop_def = prop_variant if prop_variant is Dictionary else {}
	if _prop_def.is_empty():
		_prop_def = {
			"id": normalized_prop_id,
			"blocker_radius": 18.0,
			"trigger_radius": 54.0,
			"fuse_sec": 0.35,
			"explosion_radius": 92.0,
			"damage": 28.0,
			"body_color": "#c95b58",
			"warning_color": "#ffd08a"
		}


func _apply_shapes() -> void:
	var blocker_radius := maxf(10.0, float(_prop_def.get("blocker_radius", 18.0)))
	var trigger_radius := maxf(blocker_radius + 8.0, float(_prop_def.get("trigger_radius", 54.0)))
	var blast_radius := maxf(trigger_radius, float(_prop_def.get("explosion_radius", 92.0)))
	if body_shape != null and body_shape.shape is CircleShape2D:
		(body_shape.shape as CircleShape2D).radius = blocker_radius
	if trigger_shape != null and trigger_shape.shape is CircleShape2D:
		(trigger_shape.shape as CircleShape2D).radius = trigger_radius
	_query_shape.radius = blast_radius
	if body_visual != null:
		body_visual.scale = Vector2.ONE * (blocker_radius / 18.0)
	if shadow_visual != null:
		shadow_visual.scale = Vector2.ONE * (blocker_radius / 18.0)
	if warning_ring != null:
		warning_ring.points = _build_circle_polygon(trigger_radius, 24)


func _refresh_visuals() -> void:
	var body_color := _coerce_color(_prop_def.get("body_color", "#c95b58"), Color(0.78, 0.34, 0.32, 1.0))
	var warning_color := _coerce_color(_prop_def.get("warning_color", "#ffd08a"), Color(1.0, 0.82, 0.54, 0.88))
	if _fuse_remaining >= 0.0:
		body_color = body_color.lightened(0.24)
		warning_color = warning_color.lightened(0.18)
	if body_visual != null:
		body_visual.color = body_color
	if warning_ring != null:
		warning_ring.default_color = warning_color
		warning_ring.modulate.a = 0.92 if _fuse_remaining >= 0.0 else 0.62


func _on_trigger_body_entered(body: Node) -> void:
	if not _armed or _fuse_remaining >= 0.0:
		return
	if body == null or not is_instance_valid(body):
		return
	if not body.is_in_group("player") and not body.is_in_group("enemy"):
		return
	_fuse_remaining = maxf(0.05, float(_prop_def.get("fuse_sec", 0.35)))
	_refresh_visuals()


func _explode() -> void:
	if not _armed:
		return
	_armed = false
	if body_blocker != null:
		body_blocker.collision_layer = 0
	if trigger_area != null:
		trigger_area.monitoring = false
	var damage := maxf(0.0, float(_prop_def.get("damage", 28.0)))
	var knockback := maxf(0.0, float(_prop_def.get("knockback", 96.0)))
	if damage > 0.0 and is_inside_tree():
		var space_state := get_world_2d().direct_space_state
		_query_params.transform = Transform2D(0.0, global_position)
		_query_params.exclude = []
		var hits := space_state.intersect_shape(_query_params, 32)
		for hit_variant in hits:
			if not (hit_variant is Dictionary):
				continue
			var collider_variant: Variant = (hit_variant as Dictionary).get("collider", null)
			if not (collider_variant is Node) or not is_instance_valid(collider_variant):
				continue
			var collider := collider_variant as Node
			if collider == body_blocker:
				continue
			if collider.is_in_group("player") and collider.has_method("take_damage"):
				collider.call("take_damage", damage)
			elif collider.is_in_group("enemy") and collider.has_method("take_hit"):
				var impulse := Vector2.ZERO
				if collider is Node2D:
					var away := (collider as Node2D).global_position - global_position
					if away.length() > 0.01:
						impulse = away.normalized() * knockback
				collider.call("take_hit", damage, impulse)
	if body_visual != null:
		body_visual.visible = false
	if shadow_visual != null:
		shadow_visual.visible = false
	if warning_ring != null:
		warning_ring.visible = false
	queue_free()


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
	if not _prop_defs.is_empty():
		return
	var payload := _load_json_dictionary(HAZARDS_PATH)
	var rows_variant: Variant = payload.get("props", [])
	if not (rows_variant is Array):
		return
	for row_variant in rows_variant:
		if not (row_variant is Dictionary):
			continue
		var row: Dictionary = row_variant
		var row_id := String(row.get("id", "")).strip_edges().to_lower()
		if row_id.is_empty():
			continue
		_prop_defs[row_id] = row.duplicate(true)


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
