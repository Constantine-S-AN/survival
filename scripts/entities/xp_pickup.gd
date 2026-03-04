extends Area2D
class_name XPPickup

const CombatPaletteClass := preload("res://scripts/visual/combat_palette.gd")
const PICKUP_GLOW_SCALE_MULT := 1.86
const PICKUP_RING_SCALE_MULT := 1.34
const PICKUP_RING_PULSE_AMPLITUDE := 0.16

var xp_amount: int = 1
var seek_speed: float = 320.0
var magnet_radius: float = 170.0
var source: String = "pickup"
var player: Node2D = null
var recycle_handler: Callable = Callable()
var active: bool = false
var _pickup_core_color: Color = Color(0.62, 1.0, 0.94, 0.98)
var _pickup_glow_color: Color = Color(0.76, 1.0, 0.96, 0.32)
var _pickup_ring_color: Color = Color(0.52, 0.92, 0.88, 0.56)
var _pickup_pulse_speed: float = 3.0
var _visual_phase: float = 0.0
var _body_base_scale: Vector2 = Vector2.ONE
var _glow_visual: Polygon2D
var _ring_visual: Polygon2D

@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var body_visual: Polygon2D = $Body


func _ready() -> void:
	add_to_group("pickup")
	body_entered.connect(_on_body_entered)
	_ensure_pickup_visuals()
	on_pool_recycle()


func set_recycle_handler(handler: Callable) -> void:
	recycle_handler = handler


func setup(amount: int, player_ref: Node2D) -> void:
	xp_amount = max(1, amount)
	player = player_ref
	magnet_radius = 170.0
	if player != null and player.has_method("get_pickup_radius_multiplier"):
		magnet_radius *= float(player.get_pickup_radius_multiplier())
	var radius := 6.0 + minf(7.0, float(xp_amount) * 0.25)
	var shape := collision_shape.shape
	if shape is CircleShape2D:
		shape.radius = radius
	body_visual.scale = Vector2.ONE * (radius / 7.0)
	_body_base_scale = body_visual.scale
	_apply_pickup_palette()
	_apply_layer_hierarchy()
	on_pool_spawned()


func _physics_process(delta: float) -> void:
	if not active:
		return
	_tick_pickup_visual(delta)
	if player == null or not is_instance_valid(player):
		return
	var distance := global_position.distance_to(player.global_position)
	if distance <= magnet_radius:
		global_position = global_position.move_toward(player.global_position, seek_speed * delta)


func _on_body_entered(body: Node) -> void:
	if not active:
		return
	if player == null or not is_instance_valid(player):
		return
	if body != player:
		return
	if player.has_method("gain_xp"):
		player.gain_xp(xp_amount)
	var reveal_mult := 1.0
	if player.has_method("get_sonar_reveal_duration_multiplier"):
		reveal_mult = float(player.get_sonar_reveal_duration_multiplier())
	FeedbackBus.emit_sonar_pulse(global_position, {
		"source": source,
		"reveal_duration_multiplier": reveal_mult
	})
	if FeedbackBus.has_method("emit_pickup_collected"):
		FeedbackBus.emit_pickup_collected(global_position, xp_amount)
	_request_recycle()


func on_pool_spawned() -> void:
	active = true
	_apply_layer_hierarchy()
	set_deferred("monitoring", true)
	set_deferred("monitorable", true)
	set_physics_process(true)
	visible = true
	if _glow_visual != null:
		_glow_visual.visible = true
	if _ring_visual != null:
		_ring_visual.visible = true


func on_pool_recycle() -> void:
	active = false
	set_deferred("monitoring", false)
	set_deferred("monitorable", false)
	set_physics_process(false)
	player = null
	_visual_phase = 0.0
	_body_base_scale = Vector2.ONE
	body_visual.color = Color(0.556863, 0.988235, 1.0, 0.95)
	body_visual.modulate = Color(1.0, 1.0, 1.0, 1.0)
	if _glow_visual != null:
		_glow_visual.visible = false
		_glow_visual.color = _pickup_glow_color
		_glow_visual.scale = Vector2.ONE
	if _ring_visual != null:
		_ring_visual.visible = false
		_ring_visual.color = _pickup_ring_color
		_ring_visual.scale = Vector2.ONE
	visible = false


func _ensure_pickup_visuals() -> void:
	if _glow_visual == null:
		_glow_visual = Polygon2D.new()
		_glow_visual.name = "Glow"
		_glow_visual.polygon = body_visual.polygon
		_glow_visual.visible = false
		_glow_visual.color = _pickup_glow_color
		var glow_material := CanvasItemMaterial.new()
		glow_material.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
		_glow_visual.material = glow_material
		add_child(_glow_visual)
		move_child(_glow_visual, 0)
	if _ring_visual == null:
		_ring_visual = Polygon2D.new()
		_ring_visual.name = "Ring"
		_ring_visual.polygon = body_visual.polygon
		_ring_visual.visible = false
		_ring_visual.color = _pickup_ring_color
		_ring_visual.z_index = 1
		add_child(_ring_visual)
		move_child(_ring_visual, 1)


func _apply_layer_hierarchy() -> void:
	z_index = CombatPaletteClass.LAYER_PICKUP
	body_visual.z_index = 0
	if _glow_visual != null:
		_glow_visual.z_index = CombatPaletteClass.LAYER_PICKUP_GLOW - CombatPaletteClass.LAYER_PICKUP
	if _ring_visual != null:
		_ring_visual.z_index = 1


func _apply_pickup_palette() -> void:
	var palette_variant: Variant = CombatPaletteClass.pickup_palette(xp_amount)
	var palette: Dictionary = palette_variant if palette_variant is Dictionary else {}
	var core_variant: Variant = palette.get("core", _pickup_core_color)
	var glow_variant: Variant = palette.get("glow", _pickup_glow_color)
	var ring_variant: Variant = palette.get("ring", _pickup_ring_color)
	var pulse_speed_variant: Variant = palette.get("pulse_speed", _pickup_pulse_speed)
	_pickup_core_color = core_variant if core_variant is Color else _pickup_core_color
	_pickup_glow_color = glow_variant if glow_variant is Color else _pickup_glow_color
	_pickup_ring_color = ring_variant if ring_variant is Color else _pickup_ring_color
	_pickup_pulse_speed = clampf(float(pulse_speed_variant), 1.2, 6.0)
	body_visual.color = _pickup_core_color
	body_visual.modulate = Color(1.0, 1.0, 1.0, 1.0)
	_ensure_pickup_visuals()
	if _glow_visual != null:
		_glow_visual.color = _pickup_glow_color
		_glow_visual.scale = _body_base_scale * PICKUP_GLOW_SCALE_MULT
	if _ring_visual != null:
		_ring_visual.color = _pickup_ring_color
		_ring_visual.scale = _body_base_scale * PICKUP_RING_SCALE_MULT


func _tick_pickup_visual(delta: float) -> void:
	if _glow_visual == null or _ring_visual == null:
		return
	if not active:
		_glow_visual.visible = false
		_ring_visual.visible = false
		return
	_visual_phase += delta * _pickup_pulse_speed
	var wave := 0.5 + 0.5 * sin(_visual_phase * TAU)
	var glow_color := _pickup_glow_color
	glow_color.a = clampf(_pickup_glow_color.a * lerpf(0.74, 1.18, wave), 0.06, 0.72)
	_glow_visual.color = glow_color
	_glow_visual.scale = _body_base_scale * (PICKUP_GLOW_SCALE_MULT + 0.10 * wave)
	var ring_color := _pickup_ring_color
	ring_color.a = clampf(_pickup_ring_color.a * lerpf(0.66, 1.16, 1.0 - wave), 0.06, 0.78)
	_ring_visual.color = ring_color
	_ring_visual.scale = _body_base_scale * (PICKUP_RING_SCALE_MULT + PICKUP_RING_PULSE_AMPLITUDE * wave)
	_glow_visual.visible = true
	_ring_visual.visible = true


func _request_recycle() -> void:
	if not active:
		return
	active = false
	set_physics_process(false)
	set_deferred("monitoring", false)
	set_deferred("monitorable", false)
	call_deferred("_dispatch_recycle_request")


func _dispatch_recycle_request() -> void:
	if recycle_handler.is_valid():
		recycle_handler.call(self)
		return
	queue_free()
