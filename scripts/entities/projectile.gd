extends Area2D
class_name Projectile

const PixelStickerRegistry := preload("res://scripts/visual/pixel_sticker_registry.gd")
const PROJECTILE_IDLE_FRAME_SEC := 0.16

var direction := Vector2.RIGHT
var speed := 520.0
var damage := 10.0
var remaining_range := 600.0
var radius := 6.0
var pierce := 0
var hit_count := 0
var crit_chance := 0.0
var crit_multiplier := 1.5
var reveal_bonus_duration := 0.0
var weapon_tags: Array = []
var source_owner: Node = null
var recycle_handler: Callable = Callable()
var active: bool = false
var _weapon_sticker_frames: Array[Texture2D] = []
var _weapon_sticker_timer: float = 0.0
var _weapon_sticker_frame_idx: int = 0

@onready var body_visual: Polygon2D = $Body
@onready var sticker_visual: Sprite2D = $Sticker
@onready var collision_shape: CollisionShape2D = $CollisionShape2D


func _ready() -> void:
	on_pool_recycle()


func set_recycle_handler(handler: Callable) -> void:
	recycle_handler = handler


func configure(origin: Vector2, fire_direction: Vector2, projectile_data: Dictionary, owner_ref: Node) -> void:
	global_position = origin
	hit_count = 0
	direction = fire_direction.normalized() if fire_direction.length() > 0.01 else Vector2.RIGHT
	speed = float(projectile_data.get("speed", speed))
	damage = float(projectile_data.get("damage", damage))
	remaining_range = float(projectile_data.get("range", remaining_range))
	pierce = int(projectile_data.get("pierce", pierce))
	radius = float(projectile_data.get("radius", radius))
	crit_chance = float(projectile_data.get("crit_chance", 0.0))
	crit_multiplier = float(projectile_data.get("crit_multiplier", 1.5))
	reveal_bonus_duration = float(projectile_data.get("reveal_bonus_duration", 0.0))
	var tags_variant: Variant = projectile_data.get("tags", [])
	weapon_tags = tags_variant if tags_variant is Array else []
	source_owner = owner_ref
	var weapon_id := String(projectile_data.get("weapon_id", "")).strip_edges()

	var shape := collision_shape.shape
	if shape is CircleShape2D:
		shape.radius = radius
	body_visual.scale = Vector2.ONE * (radius / 6.0)
	_apply_projectile_sticker(weapon_id, radius)

	rotation = direction.angle()
	on_pool_spawned()


func _physics_process(delta: float) -> void:
	if not active:
		return
	_tick_weapon_sticker(delta)
	var motion := direction * speed * delta
	global_position += motion
	remaining_range -= motion.length()
	if remaining_range <= 0.0:
		_request_recycle()


func _on_body_entered(body: Node) -> void:
	if not active:
		return
	if body == source_owner:
		return
	if body.is_in_group("enemy") and body.has_method("take_hit"):
		var final_damage := damage
		var is_crit := false
		if source_owner != null and source_owner.has_method("compute_hit_payload"):
			var payload_variant: Variant = source_owner.compute_hit_payload(body, damage, crit_chance, crit_multiplier)
			if payload_variant is Dictionary:
				var payload: Dictionary = payload_variant
				final_damage = float(payload.get("damage", damage))
				is_crit = bool(payload.get("crit", false))
		var killed := bool(body.take_hit(final_damage, direction * 180.0))
		if reveal_bonus_duration > 0.0 and body.has_method("set_revealed"):
			body.set_revealed(reveal_bonus_duration)
		var intensity := clampf((final_damage / 34.0) + (0.07 if killed else 0.0) + (0.05 if is_crit else 0.0), 0.08, 0.36)
		FeedbackBus.emit_hit(global_position, intensity, killed)
		hit_count += 1
		if hit_count > pierce:
			_request_recycle()


func on_pool_spawned() -> void:
	active = true
	set_deferred("monitoring", true)
	set_deferred("monitorable", true)
	set_physics_process(true)
	visible = true


func on_pool_recycle() -> void:
	active = false
	set_deferred("monitoring", false)
	set_deferred("monitorable", false)
	set_physics_process(false)
	source_owner = null
	if sticker_visual != null:
		sticker_visual.texture = null
		sticker_visual.visible = false
	_weapon_sticker_frames.clear()
	_weapon_sticker_timer = 0.0
	_weapon_sticker_frame_idx = 0
	body_visual.visible = true
	visible = false


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


func _apply_projectile_sticker(weapon_id: String, projectile_radius: float) -> void:
	if sticker_visual == null:
		return
	_weapon_sticker_frames = PixelStickerRegistry.get_weapon_idle_frames(weapon_id)
	var texture := _weapon_sticker_frames[0] if not _weapon_sticker_frames.is_empty() else null
	if texture == null:
		sticker_visual.visible = false
		body_visual.visible = true
		_weapon_sticker_frames.clear()
		return
	_weapon_sticker_timer = 0.0
	_weapon_sticker_frame_idx = 0
	sticker_visual.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sticker_visual.texture = texture
	sticker_visual.visible = true
	var max_dim := maxf(texture.get_size().x, texture.get_size().y)
	var desired_world_size := maxf(8.0, projectile_radius * 2.8)
	sticker_visual.scale = Vector2.ONE * (desired_world_size / maxf(1.0, max_dim))
	body_visual.visible = false


func _tick_weapon_sticker(delta: float) -> void:
	if sticker_visual == null or not sticker_visual.visible or _weapon_sticker_frames.size() <= 1:
		return
	_weapon_sticker_timer += delta
	if _weapon_sticker_timer < PROJECTILE_IDLE_FRAME_SEC:
		return
	_weapon_sticker_timer = 0.0
	_weapon_sticker_frame_idx = (_weapon_sticker_frame_idx + 1) % _weapon_sticker_frames.size()
	sticker_visual.texture = _weapon_sticker_frames[_weapon_sticker_frame_idx]
