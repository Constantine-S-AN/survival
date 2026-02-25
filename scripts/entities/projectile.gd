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
var impact_aoe_radius := 0.0
var impact_aoe_damage_mult := 0.0
var impact_pulse_strength := 0.0
var impact_pulse_radius_scale := 0.9
var impact_knockback := 180.0
var fx_color := Color(1.0, 1.0, 1.0, 1.0)
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
	impact_aoe_radius = maxf(0.0, float(projectile_data.get("impact_aoe_radius", 0.0)))
	impact_aoe_damage_mult = clampf(float(projectile_data.get("impact_aoe_damage_mult", 0.0)), 0.0, 1.6)
	impact_pulse_strength = maxf(0.0, float(projectile_data.get("impact_pulse_strength", 0.0)))
	impact_pulse_radius_scale = clampf(float(projectile_data.get("impact_pulse_radius_scale", 0.9)), 0.3, 2.5)
	impact_knockback = maxf(0.0, float(projectile_data.get("impact_knockback", 180.0)))
	var fx_color_hex := String(projectile_data.get("fx_color", "")).strip_edges()
	fx_color = Color(1.0, 1.0, 1.0, 1.0)
	if not fx_color_hex.is_empty():
		fx_color = Color.from_string(fx_color_hex, Color(1.0, 1.0, 1.0, 1.0))
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
		var killed := bool(body.take_hit(final_damage, direction * impact_knockback))
		if reveal_bonus_duration > 0.0 and body.has_method("set_revealed"):
			body.set_revealed(reveal_bonus_duration)
		var intensity := clampf((final_damage / 34.0) + (0.07 if killed else 0.0) + (0.05 if is_crit else 0.0), 0.08, 0.36)
		FeedbackBus.emit_hit(global_position, intensity, killed)
		_apply_impact_aoe(body, final_damage)
		_emit_impact_pulse()
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
	impact_aoe_radius = 0.0
	impact_aoe_damage_mult = 0.0
	impact_pulse_strength = 0.0
	impact_pulse_radius_scale = 0.9
	impact_knockback = 180.0
	fx_color = Color(1.0, 1.0, 1.0, 1.0)
	if sticker_visual != null:
		sticker_visual.texture = null
		sticker_visual.visible = false
		sticker_visual.modulate = Color(1.0, 1.0, 1.0, 1.0)
	_weapon_sticker_frames.clear()
	_weapon_sticker_timer = 0.0
	_weapon_sticker_frame_idx = 0
	body_visual.visible = true
	body_visual.modulate = Color(1.0, 1.0, 1.0, 1.0)
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
		body_visual.modulate = fx_color
		_weapon_sticker_frames.clear()
		return
	_weapon_sticker_timer = 0.0
	_weapon_sticker_frame_idx = 0
	sticker_visual.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sticker_visual.texture = texture
	sticker_visual.visible = true
	sticker_visual.modulate = fx_color
	var max_dim := maxf(texture.get_size().x, texture.get_size().y)
	var desired_world_size := maxf(8.0, projectile_radius * 2.8)
	sticker_visual.scale = Vector2.ONE * (desired_world_size / maxf(1.0, max_dim))
	body_visual.visible = false


func _emit_impact_pulse() -> void:
	if impact_pulse_strength <= 0.0:
		return
	FeedbackBus.emit_sonar_pulse(global_position, {
		"source": "hit",
		"strength": clampf(impact_pulse_strength, 0.1, 2.2),
		"radius_scale": impact_pulse_radius_scale,
		"reveal_duration_multiplier": 1.0
	})


func _apply_impact_aoe(primary_target: Node, base_impact_damage: float) -> void:
	if impact_aoe_radius <= 0.0 or base_impact_damage <= 0.0:
		return
	var splash_damage := base_impact_damage * impact_aoe_damage_mult
	if splash_damage <= 0.0:
		return
	for enemy_variant in get_tree().get_nodes_in_group("enemy"):
		if enemy_variant == null or not is_instance_valid(enemy_variant):
			continue
		if not (enemy_variant is Node2D):
			continue
		var enemy := enemy_variant as Node2D
		if enemy == primary_target:
			continue
		if enemy.global_position.distance_to(global_position) > impact_aoe_radius:
			continue
		if not enemy.has_method("take_hit"):
			continue
		var resolved_damage := splash_damage
		if source_owner != null and source_owner.has_method("compute_damage_against"):
			resolved_damage = float(source_owner.compute_damage_against(enemy, splash_damage))
		var impulse := (enemy.global_position - global_position).normalized() * (impact_knockback * 0.55)
		var killed := bool(enemy.take_hit(resolved_damage, impulse))
		if reveal_bonus_duration > 0.0 and enemy.has_method("set_revealed"):
			enemy.set_revealed(reveal_bonus_duration * 0.55)
		var intensity := clampf((resolved_damage / 42.0) + (0.05 if killed else 0.0), 0.05, 0.28)
		FeedbackBus.emit_hit(enemy.global_position, intensity, killed)


func _tick_weapon_sticker(delta: float) -> void:
	if sticker_visual == null or not sticker_visual.visible or _weapon_sticker_frames.size() <= 1:
		return
	_weapon_sticker_timer += delta
	if _weapon_sticker_timer < PROJECTILE_IDLE_FRAME_SEC:
		return
	_weapon_sticker_timer = 0.0
	_weapon_sticker_frame_idx = (_weapon_sticker_frame_idx + 1) % _weapon_sticker_frames.size()
	sticker_visual.texture = _weapon_sticker_frames[_weapon_sticker_frame_idx]
