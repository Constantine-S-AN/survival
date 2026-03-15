extends Node2D
class_name NightObjectiveZone

@export var radius: float = 88.0
@export var label: String = "Objective Zone"

@onready var fill_visual: Polygon2D = $Fill
@onready var ring_visual: Line2D = $Ring

var _pulse_clock: float = 0.0


func _ready() -> void:
	_apply_radius()
	set_process(true)


func _process(delta: float) -> void:
	_pulse_clock += maxf(delta, 0.0)
	var pulse := 0.5 + 0.5 * sin(_pulse_clock * TAU * 0.52)
	if fill_visual != null:
		fill_visual.scale = Vector2.ONE * lerpf(0.96, 1.02, pulse)
		fill_visual.color.a = lerpf(0.10, 0.18, pulse)
	if ring_visual != null:
		ring_visual.width = lerpf(2.4, 4.8, pulse)
		ring_visual.default_color = Color(0.98, 0.84, 0.42, lerpf(0.55, 0.92, pulse))


func configure_from_payload(payload: Dictionary) -> void:
	radius = maxf(18.0, float(payload.get("radius", radius)))
	label = String(payload.get("label", payload.get("display_name", label))).strip_edges()
	_apply_radius()


func contains_world_point(point: Vector2) -> bool:
	return global_position.distance_to(point) <= radius


func get_snapshot() -> Dictionary:
	return {
		"label": label,
		"radius": radius,
		"position": global_position
	}


func _apply_radius() -> void:
	if fill_visual != null:
		fill_visual.polygon = _build_circle(radius * 0.92, 18)
	if ring_visual != null:
		ring_visual.points = _build_circle(radius, 28)


func _build_circle(target_radius: float, steps: int) -> PackedVector2Array:
	var points := PackedVector2Array()
	for index in range(maxi(6, steps)):
		var angle := TAU * float(index) / float(maxi(6, steps))
		points.append(Vector2.RIGHT.rotated(angle) * target_radius)
	return points
