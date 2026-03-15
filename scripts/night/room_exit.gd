extends Area2D
class_name RoomExit

signal exit_selected(exit_id: String, target_room_id: String)

const LOCKED_COLOR := Color(0.39, 0.45, 0.54, 0.92)
const READY_COLOR := Color(0.33, 0.90, 0.95, 0.98)
const READY_RING_COLOR := Color(0.86, 0.98, 1.0, 0.88)
const READY_PULSE_SPEED := 1.8

var exit_id: String = ""
var target_room_id: String = ""
var display_name: String = ""
var anchor_side: String = ""
var target_room_type_id: String = ""
var target_room_state: String = ""
var locked: bool = true
var _target_color: Color = READY_COLOR

var _portal_visual: Polygon2D = null
var _ring_visual: Line2D = null
var _collision_shape: CollisionShape2D = null
var _pulse_clock: float = 0.0


func _ready() -> void:
	collision_layer = 0
	collision_mask = 1
	z_index = 12
	_ensure_visuals()
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)
	set_process(true)
	_refresh_visuals()


func configure(
	next_exit_id: String,
	next_target_room_id: String,
	next_display_name: String,
	next_anchor_side: String,
	next_room_type_id: String,
	next_room_state: String,
	start_locked: bool,
	target_color: Color = READY_COLOR
) -> void:
	exit_id = next_exit_id.strip_edges()
	target_room_id = next_target_room_id.strip_edges()
	display_name = next_display_name.strip_edges()
	anchor_side = next_anchor_side.strip_edges()
	target_room_type_id = next_room_type_id.strip_edges().to_lower()
	target_room_state = next_room_state.strip_edges().to_lower()
	_target_color = target_color
	set_locked(start_locked)


func set_target_state(next_room_state: String) -> void:
	target_room_state = next_room_state.strip_edges().to_lower()
	_refresh_visuals()


func set_locked(value: bool) -> void:
	locked = value
	_refresh_visuals()


func get_snapshot() -> Dictionary:
	return {
		"exit_id": exit_id,
		"target_room_id": target_room_id,
		"display_name": display_name,
		"anchor_side": anchor_side,
		"target_room_type_id": target_room_type_id,
		"target_room_state": target_room_state,
		"locked": locked
	}


func _process(delta: float) -> void:
	if _portal_visual == null or _ring_visual == null:
		return
	if locked:
		_pulse_clock = 0.0
		_portal_visual.scale = Vector2.ONE
		_ring_visual.scale = Vector2.ONE
		return
	_pulse_clock += delta * READY_PULSE_SPEED
	var wave := 0.5 + 0.5 * sin(_pulse_clock * TAU)
	_portal_visual.scale = Vector2.ONE * lerpf(0.94, 1.08, wave)
	_ring_visual.modulate.a = lerpf(0.48, 0.96, wave)


func _on_body_entered(body: Node) -> void:
	if locked:
		return
	if body == null or not is_instance_valid(body) or not body.is_in_group("player"):
		return
	exit_selected.emit(exit_id, target_room_id)


func _ensure_visuals() -> void:
	if _portal_visual == null:
		_portal_visual = Polygon2D.new()
		_portal_visual.name = "PortalVisual"
		_portal_visual.polygon = PackedVector2Array([
			Vector2(0.0, -26.0),
			Vector2(24.0, 0.0),
			Vector2(0.0, 26.0),
			Vector2(-24.0, 0.0)
		])
		_portal_visual.z_index = 0
		add_child(_portal_visual)
	if _ring_visual == null:
		_ring_visual = Line2D.new()
		_ring_visual.name = "PortalRing"
		_ring_visual.width = 4.0
		_ring_visual.closed = true
		_ring_visual.default_color = READY_RING_COLOR
		_ring_visual.points = PackedVector2Array([
			Vector2(0.0, -36.0),
			Vector2(32.0, 0.0),
			Vector2(0.0, 36.0),
			Vector2(-32.0, 0.0)
		])
		_ring_visual.z_index = 1
		add_child(_ring_visual)
	if _collision_shape == null:
		_collision_shape = CollisionShape2D.new()
		_collision_shape.name = "CollisionShape2D"
		var shape := CircleShape2D.new()
		shape.radius = 28.0
		_collision_shape.shape = shape
		add_child(_collision_shape)


func _refresh_visuals() -> void:
	if _portal_visual == null or _ring_visual == null:
		return
	monitoring = not locked
	monitorable = not locked
	var portal_color := _target_color.darkened(0.28) if locked else _target_color
	if target_room_state == "cleared" and not locked:
		portal_color = portal_color.lightened(0.18)
	_portal_visual.color = LOCKED_COLOR if locked else portal_color
	_ring_visual.default_color = READY_RING_COLOR if not locked else LOCKED_COLOR.lightened(0.1)
	_ring_visual.modulate = Color(1.0, 1.0, 1.0, 0.46 if locked else 0.88)
