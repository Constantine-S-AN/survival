extends Node2D
class_name BossTelegraphEffect

var telegraph_type: String = "ring"
var duration: float = 0.8
var elapsed: float = 0.0
var color: Color = Color(0.54, 0.92, 1.0, 0.85)
var line_width: float = 5.0
var radius: float = 140.0
var length: float = 220.0
var direction: Vector2 = Vector2.RIGHT
var cone_angle_deg: float = 50.0


func _ready() -> void:
	add_to_group("boss_telegraph")
	set_process(true)
	queue_redraw()


func configure(type_id: String, payload: Dictionary = {}) -> void:
	telegraph_type = type_id.strip_edges().to_lower()
	duration = maxf(0.06, float(payload.get("duration", duration)))
	color = Color.from_string(String(payload.get("color", "#8be8ff")), color)
	line_width = maxf(1.0, float(payload.get("line_width", line_width)))
	radius = maxf(8.0, float(payload.get("radius", radius)))
	length = maxf(10.0, float(payload.get("length", length)))
	cone_angle_deg = clampf(float(payload.get("cone_angle_deg", cone_angle_deg)), 5.0, 170.0)
	global_position = Vector2(payload.get("origin", global_position))
	if payload.has("target"):
		var target := Vector2(payload.get("target", global_position))
		var dir := target - global_position
		if dir.length() > 0.001:
			direction = dir.normalized()
	if payload.has("direction"):
		var dir_payload := Vector2(payload.get("direction", direction))
		if dir_payload.length() > 0.001:
			direction = dir_payload.normalized()
	elapsed = 0.0
	queue_redraw()


func _process(delta: float) -> void:
	elapsed += delta
	if elapsed >= duration:
		queue_free()
		return
	queue_redraw()


func _draw() -> void:
	var progress := clampf(elapsed / maxf(duration, 0.001), 0.0, 1.0)
	var pulse := 0.65 + 0.35 * sin(progress * PI)
	var alpha := clampf((1.0 - progress) * 0.9 + 0.1, 0.0, 1.0)
	var draw_color := color
	draw_color.a *= alpha

	match telegraph_type:
		"line":
			var end := direction.normalized() * length
			draw_line(Vector2.ZERO, end, draw_color, line_width * pulse)
			draw_circle(end, line_width * (1.1 + 0.9 * pulse), draw_color * Color(1.0, 1.0, 1.0, 0.5))
		"cone":
			_draw_cone(draw_color, pulse)
		_:
			var ring_radius := radius * (0.84 + 0.24 * pulse)
			draw_arc(Vector2.ZERO, ring_radius, 0.0, TAU, 72, draw_color, line_width * pulse, true)
			draw_arc(Vector2.ZERO, ring_radius * 0.72, 0.0, TAU, 64, draw_color * Color(1.0, 1.0, 1.0, 0.55), maxf(1.0, line_width * 0.35), true)


func _draw_cone(draw_color: Color, pulse: float) -> void:
	var dir := direction.normalized()
	var center_angle := dir.angle()
	var half_angle := deg_to_rad(cone_angle_deg * 0.5)
	var start_angle := center_angle - half_angle
	var end_angle := center_angle + half_angle
	var segments := 24
	var points := PackedVector2Array()
	points.append(Vector2.ZERO)
	for i in range(segments + 1):
		var t := float(i) / float(segments)
		var a := lerpf(start_angle, end_angle, t)
		points.append(Vector2.RIGHT.rotated(a) * (radius * (0.9 + 0.15 * pulse)))
	var fill := draw_color * Color(1.0, 1.0, 1.0, 0.16)
	draw_colored_polygon(points, fill)
	draw_polyline(points, draw_color, line_width * pulse, true)
