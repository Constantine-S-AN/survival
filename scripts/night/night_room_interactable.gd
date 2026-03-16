extends Node2D
class_name NightRoomInteractable

@export var interaction_id: String = ""
@export var interaction_kind: String = "generic"
@export var label: String = "Interact"
@export var prompt_text: String = ""
@export var radius: float = 76.0
@export var target_room_id: String = ""

@onready var halo_visual: Polygon2D = $Halo
@onready var core_visual: Polygon2D = $Core
@onready var ring_visual: Line2D = $Ring

var _focused: bool = false
var _pulse_clock: float = 0.0


func _ready() -> void:
	_apply_style()
	set_process(true)


func _process(delta: float) -> void:
	_pulse_clock += maxf(delta, 0.0)
	var pulse := 0.5 + 0.5 * sin(_pulse_clock * TAU * 0.72)
	if halo_visual != null:
		halo_visual.scale = Vector2.ONE * lerpf(0.94, 1.08, pulse)
		halo_visual.color.a = lerpf(0.10, 0.26, pulse) if _focused else lerpf(0.06, 0.14, pulse)
	if ring_visual != null:
		ring_visual.width = lerpf(2.6, 5.0, pulse if _focused else pulse * 0.55)
		ring_visual.modulate.a = lerpf(0.54, 0.98, pulse) if _focused else lerpf(0.34, 0.60, pulse)
	if core_visual != null:
		core_visual.scale = Vector2.ONE * lerpf(0.96, 1.04, pulse if _focused else pulse * 0.4)


func configure_from_payload(payload: Dictionary) -> void:
	interaction_id = String(payload.get("interaction_id", interaction_id)).strip_edges().to_lower()
	interaction_kind = String(payload.get("interaction_kind", interaction_kind)).strip_edges().to_lower()
	label = String(payload.get("label", label)).strip_edges()
	prompt_text = String(payload.get("prompt_text", prompt_text)).strip_edges()
	radius = maxf(24.0, float(payload.get("radius", radius)))
	target_room_id = String(payload.get("target_room_id", target_room_id)).strip_edges().to_lower()
	_apply_style()


func set_focused(focused: bool) -> void:
	_focused = focused


func contains_world_point(point: Vector2) -> bool:
	return global_position.distance_to(point) <= radius


func get_snapshot() -> Dictionary:
	return {
		"interaction_id": interaction_id,
		"interaction_kind": interaction_kind,
		"label": label,
		"prompt_text": prompt_text,
		"radius": radius,
		"target_room_id": target_room_id,
		"focused": _focused,
		"position": global_position
	}


func _apply_style() -> void:
	var accent := Color(0.72, 0.84, 0.96, 0.92)
	match interaction_kind:
		"hack":
			accent = Color(0.40, 0.96, 0.86, 0.96)
		"reroute":
			accent = Color(1.0, 0.82, 0.42, 0.96)
		"cache":
			accent = Color(0.94, 0.42, 0.58, 0.96)
		"shrine":
			accent = Color(1.0, 0.76, 0.44, 0.96)
		"shop":
			accent = Color(0.52, 0.90, 1.0, 0.96)
		"breach":
			accent = Color(1.0, 0.62, 0.34, 0.96)
	if halo_visual != null:
		halo_visual.color = Color(accent.r, accent.g, accent.b, 0.12)
		halo_visual.polygon = _build_circle(radius * 0.92, 18)
	if core_visual != null:
		core_visual.color = accent
	if ring_visual != null:
		ring_visual.default_color = Color(accent.r, accent.g, accent.b, 0.92)
		ring_visual.points = _build_circle(radius, 28)


func _build_circle(target_radius: float, steps: int) -> PackedVector2Array:
	var points := PackedVector2Array()
	for index in range(maxi(6, steps)):
		var angle := TAU * float(index) / float(maxi(6, steps))
		points.append(Vector2.RIGHT.rotated(angle) * target_radius)
	return points
