extends StaticBody2D
class_name NightObjectiveNode

signal objective_destroyed(objective_id: String)

@export var objective_id: String = "objective_node"
@export var label: String = "Objective Node"
@export var max_hp: float = 120.0
@export var collision_radius: float = 22.0

@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var body_visual: Polygon2D = $Body
@onready var core_visual: Polygon2D = $Core
@onready var ring_visual: Line2D = $Ring

var hp: float = 120.0
var _revealed: bool = false
var _reveal_remaining: float = 0.0
var _pulse_clock: float = 0.0


func _ready() -> void:
	add_to_group("enemy")
	add_to_group("night_objective")
	collision_layer = 2
	collision_mask = 0
	hp = max_hp
	_apply_radius()
	set_process(true)


func _process(delta: float) -> void:
	_pulse_clock += maxf(delta, 0.0)
	if _reveal_remaining > 0.0:
		_reveal_remaining = maxf(0.0, _reveal_remaining - delta)
		if is_zero_approx(_reveal_remaining):
			_revealed = false
	_update_visuals()


func configure_from_payload(payload: Dictionary) -> void:
	objective_id = String(payload.get("id", payload.get("objective_id", objective_id))).strip_edges()
	label = String(payload.get("label", payload.get("display_name", label))).strip_edges()
	max_hp = maxf(1.0, float(payload.get("hp", payload.get("max_hp", max_hp))))
	collision_radius = maxf(10.0, float(payload.get("radius", payload.get("collision_radius", collision_radius))))
	hp = max_hp
	_apply_radius()
	_update_visuals()


func get_snapshot() -> Dictionary:
	return {
		"id": objective_id,
		"label": label,
		"hp": hp,
		"max_hp": max_hp,
		"destroyed": hp <= 0.0,
		"position": global_position
	}


func take_hit(damage: float, _impulse: Vector2 = Vector2.ZERO) -> bool:
	if hp <= 0.0:
		return true
	hp = maxf(0.0, hp - maxf(0.0, damage))
	_revealed = true
	_reveal_remaining = maxf(_reveal_remaining, 0.8)
	_update_visuals()
	if hp <= 0.0:
		collision_layer = 0
		visible = false
		objective_destroyed.emit(objective_id)
		queue_free()
		return true
	return false


func apply_status_effect(_effect_id: String, _duration: float, _power: float = 0.0) -> void:
	return


func set_revealed(duration_sec: float) -> void:
	_revealed = true
	_reveal_remaining = maxf(_reveal_remaining, duration_sec)


func is_revealed() -> bool:
	return _revealed


func _apply_radius() -> void:
	if collision_shape != null and collision_shape.shape is CircleShape2D:
		(collision_shape.shape as CircleShape2D).radius = collision_radius
	if body_visual != null:
		body_visual.scale = Vector2.ONE * (collision_radius / 22.0)
	if core_visual != null:
		core_visual.scale = Vector2.ONE * (collision_radius / 22.0)
	if ring_visual != null:
		ring_visual.points = _build_circle(collision_radius + 8.0, 24)


func _update_visuals() -> void:
	var hp_ratio := clampf(hp / maxf(1.0, max_hp), 0.0, 1.0)
	var pulse := 0.5 + 0.5 * sin(_pulse_clock * TAU * 0.85)
	if body_visual != null:
		body_visual.color = Color(0.38 + (0.20 * pulse), 0.24, 0.20, 0.96)
	if core_visual != null:
		core_visual.color = Color(1.0, 0.58 + (0.18 * hp_ratio), 0.28 + (0.20 * hp_ratio), 0.90 if _revealed else 0.68)
	if ring_visual != null:
		ring_visual.width = lerpf(2.0, 4.4, pulse)
		ring_visual.default_color = Color(1.0, 0.82, 0.40, 0.92 if _revealed else 0.60)


func _build_circle(target_radius: float, steps: int) -> PackedVector2Array:
	var points := PackedVector2Array()
	for index in range(maxi(6, steps)):
		var angle := TAU * float(index) / float(maxi(6, steps))
		points.append(Vector2.RIGHT.rotated(angle) * target_radius)
	return points
