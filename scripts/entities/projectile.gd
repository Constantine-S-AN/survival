extends Area2D
class_name Projectile

const PixelStickerRegistry := preload("res://scripts/visual/pixel_sticker_registry.gd")
const CombatPaletteClass := preload("res://scripts/visual/combat_palette.gd")
const PROJECTILE_IDLE_FRAME_SEC := 0.16
const PROJECTILE_GLOW_SCALE_MULT := 1.88
const PROJECTILE_GLOW_PULSE_AMPLITUDE := 0.14

var direction := Vector2.RIGHT
var speed := 520.0
var damage := 10.0
var remaining_range := 600.0
var start_range := 600.0
var shot_origin := Vector2.ZERO
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
var weapon_id: String = ""
var attack_model: String = "projectile"
var signature_mode: String = ""
var signature_power: float = 0.0
var signature_aux: float = 0.0
var signature_cycle: int = 0
var signature_duration: float = 0.0
var precision_bonus: float = 0.0
var weapon_tags: Array = []
var source_owner: Node = null
var recycle_handler: Callable = Callable()
var active: bool = false
var _weapon_sticker_frames: Array[Texture2D] = []
var _weapon_sticker_timer: float = 0.0
var _weapon_sticker_frame_idx: int = 0
var _projectile_core_color: Color = Color(0.76, 0.98, 1.0, 1.0)
var _projectile_glow_color: Color = Color(0.86, 0.98, 1.0, 0.34)
var _glow_visual: Polygon2D
var _glow_phase: float = 0.0
var _body_base_scale: Vector2 = Vector2.ONE

@onready var body_visual: Polygon2D = $Body
@onready var sticker_visual: Sprite2D = $Sticker
@onready var collision_shape: CollisionShape2D = $CollisionShape2D


func _ready() -> void:
	_ensure_glow_visual()
	on_pool_recycle()


func set_recycle_handler(handler: Callable) -> void:
	recycle_handler = handler


func configure(origin: Vector2, fire_direction: Vector2, projectile_data: Dictionary, owner_ref: Node) -> void:
	global_position = origin
	shot_origin = origin
	hit_count = 0
	direction = fire_direction.normalized() if fire_direction.length() > 0.01 else Vector2.RIGHT
	speed = float(projectile_data.get("speed", speed))
	damage = float(projectile_data.get("damage", damage))
	remaining_range = float(projectile_data.get("range", remaining_range))
	start_range = remaining_range
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
	weapon_id = String(projectile_data.get("weapon_id", "")).strip_edges().to_lower()
	attack_model = String(projectile_data.get("attack_model", "projectile")).strip_edges().to_lower()
	signature_mode = String(projectile_data.get("signature_mode", "")).strip_edges().to_lower()
	signature_power = float(projectile_data.get("signature_power", 0.0))
	signature_aux = float(projectile_data.get("signature_aux", 0.0))
	signature_cycle = int(projectile_data.get("signature_cycle", 0))
	signature_duration = float(projectile_data.get("signature_duration", 0.0))
	precision_bonus = clampf(float(projectile_data.get("precision_bonus", 0.0)), 0.0, 0.1)
	var fx_color_hex := String(projectile_data.get("fx_color", "")).strip_edges()
	fx_color = Color(1.0, 1.0, 1.0, 1.0)
	if not fx_color_hex.is_empty():
		fx_color = Color.from_string(fx_color_hex, Color(1.0, 1.0, 1.0, 1.0))
	var tags_variant: Variant = projectile_data.get("tags", [])
	weapon_tags = tags_variant if tags_variant is Array else []
	source_owner = owner_ref
	var shape := collision_shape.shape
	if shape is CircleShape2D:
		shape.radius = radius
	body_visual.scale = Vector2.ONE * (radius / 6.0)
	_body_base_scale = body_visual.scale
	_apply_projectile_sticker(weapon_id, radius)
	_apply_projectile_palette()
	_apply_layer_hierarchy()

	rotation = direction.angle()
	on_pool_spawned()


func _physics_process(delta: float) -> void:
	if not active:
		return
	_tick_weapon_sticker(delta)
	_tick_glow_visual(delta)
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
		var payload: Dictionary = {}
		if source_owner != null and source_owner.has_method("compute_hit_payload"):
			var payload_variant: Variant = source_owner.compute_hit_payload(body, damage, crit_chance, crit_multiplier, {
				"weapon_id": weapon_id,
				"attack_model": attack_model,
				"weapon_range": start_range,
				"hit_origin": shot_origin,
				"weapon_tags": weapon_tags,
				"signature_mode": signature_mode,
				"signature_power": signature_power,
				"signature_aux": signature_aux,
				"signature_cycle": signature_cycle,
				"signature_duration": signature_duration,
				"precision_bonus": precision_bonus
			})
			if payload_variant is Dictionary:
				payload = payload_variant
				final_damage = float(payload.get("damage", damage))
				is_crit = bool(payload.get("crit", false))
		var killed := bool(body.take_hit(final_damage, direction * impact_knockback))
		if source_owner != null and source_owner.has_method("on_projectile_hit"):
			source_owner.on_projectile_hit(body, final_damage, is_crit, killed, payload, global_position)
		if reveal_bonus_duration > 0.0 and body.has_method("set_revealed"):
			body.set_revealed(reveal_bonus_duration)
		var intensity := clampf((final_damage / 34.0) + (0.07 if killed else 0.0) + (0.05 if is_crit else 0.0), 0.08, 0.36)
		FeedbackBus.emit_hit(global_position, intensity, killed, {
			"is_crit": is_crit,
			"source": "projectile",
			"weapon_id": weapon_id,
			"attack_model": attack_model,
			"weapon_tags": weapon_tags.duplicate(),
			"fx_color": fx_color.to_html(false),
			"damage": final_damage
		})
		_apply_impact_aoe(body, final_damage)
		_emit_impact_pulse()
		hit_count += 1
		if hit_count > pierce:
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
	start_range = 600.0
	shot_origin = Vector2.ZERO
	weapon_id = ""
	attack_model = "projectile"
	signature_mode = ""
	signature_power = 0.0
	signature_aux = 0.0
	signature_cycle = 0
	signature_duration = 0.0
	precision_bonus = 0.0
	weapon_tags.clear()
	_glow_phase = 0.0
	if sticker_visual != null:
		sticker_visual.texture = null
		sticker_visual.visible = false
		sticker_visual.modulate = Color(1.0, 1.0, 1.0, 1.0)
	_weapon_sticker_frames.clear()
	_weapon_sticker_timer = 0.0
	_weapon_sticker_frame_idx = 0
	body_visual.visible = true
	body_visual.modulate = Color(1.0, 1.0, 1.0, 1.0)
	body_visual.color = Color(0.76, 0.98, 1.0, 1.0)
	_projectile_core_color = body_visual.color
	_projectile_glow_color = Color(0.86, 0.98, 1.0, 0.34)
	_body_base_scale = Vector2.ONE
	if _glow_visual != null:
		_glow_visual.visible = false
		_glow_visual.color = _projectile_glow_color
		_glow_visual.scale = Vector2.ONE
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


func _ensure_glow_visual() -> void:
	if _glow_visual != null:
		return
	_glow_visual = Polygon2D.new()
	_glow_visual.name = "Glow"
	_glow_visual.polygon = body_visual.polygon
	_glow_visual.color = _projectile_glow_color
	_glow_visual.visible = false
	var glow_material := CanvasItemMaterial.new()
	glow_material.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	_glow_visual.material = glow_material
	add_child(_glow_visual)
	move_child(_glow_visual, 0)


func _apply_projectile_palette() -> void:
	var palette_variant: Variant = CombatPaletteClass.projectile_palette(fx_color, attack_model, weapon_tags)
	var palette: Dictionary = palette_variant if palette_variant is Dictionary else {}
	var core_variant: Variant = palette.get("core", fx_color)
	var glow_variant: Variant = palette.get("glow", fx_color)
	var core_color: Color = core_variant if core_variant is Color else fx_color
	var glow_color: Color = glow_variant if glow_variant is Color else fx_color
	_projectile_core_color = core_color
	_projectile_glow_color = glow_color
	body_visual.color = _projectile_core_color
	body_visual.modulate = Color(1.0, 1.0, 1.0, 1.0)
	if sticker_visual != null and sticker_visual.visible:
		sticker_visual.modulate = _projectile_core_color
	_ensure_glow_visual()
	if _glow_visual != null:
		_glow_visual.color = _projectile_glow_color
		_glow_visual.scale = _body_base_scale * PROJECTILE_GLOW_SCALE_MULT


func _apply_layer_hierarchy() -> void:
	z_index = CombatPaletteClass.LAYER_PROJECTILE
	body_visual.z_index = 0
	if sticker_visual != null:
		sticker_visual.z_index = 1
	if _glow_visual != null:
		_glow_visual.z_index = CombatPaletteClass.LAYER_PROJECTILE_GLOW - CombatPaletteClass.LAYER_PROJECTILE


func _tick_glow_visual(delta: float) -> void:
	if _glow_visual == null:
		return
	if not active:
		_glow_visual.visible = false
		return
	_glow_phase += delta * (6.0 + clampf(speed / 620.0, 0.2, 2.4))
	var wave := 0.5 + 0.5 * sin(_glow_phase)
	var glow_color := _projectile_glow_color
	glow_color.a = clampf(_projectile_glow_color.a * lerpf(0.74, 1.18, wave), 0.06, 0.72)
	_glow_visual.color = glow_color
	_glow_visual.scale = _body_base_scale * (PROJECTILE_GLOW_SCALE_MULT + PROJECTILE_GLOW_PULSE_AMPLITUDE * wave)
	_glow_visual.visible = true


func _apply_projectile_sticker(weapon_id: String, projectile_radius: float) -> void:
	if sticker_visual == null:
		return
	_weapon_sticker_frames = PixelStickerRegistry.get_weapon_idle_frames(weapon_id)
	var texture := _weapon_sticker_frames[0] if not _weapon_sticker_frames.is_empty() else null
	if texture == null:
		sticker_visual.visible = false
		body_visual.visible = true
		body_visual.modulate = Color(1.0, 1.0, 1.0, 1.0)
		_weapon_sticker_frames.clear()
		return
	_weapon_sticker_timer = 0.0
	_weapon_sticker_frame_idx = 0
	sticker_visual.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sticker_visual.texture = texture
	sticker_visual.visible = true
	sticker_visual.modulate = _projectile_core_color
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
		FeedbackBus.emit_hit(enemy.global_position, intensity, killed, {
			"is_crit": false,
			"source": "projectile_aoe",
			"weapon_id": weapon_id,
			"attack_model": attack_model,
			"weapon_tags": weapon_tags.duplicate(),
			"fx_color": fx_color.to_html(false),
			"damage": resolved_damage
		})


func _tick_weapon_sticker(delta: float) -> void:
	if sticker_visual == null or not sticker_visual.visible or _weapon_sticker_frames.size() <= 1:
		return
	_weapon_sticker_timer += delta
	if _weapon_sticker_timer < PROJECTILE_IDLE_FRAME_SEC:
		return
	_weapon_sticker_timer = 0.0
	_weapon_sticker_frame_idx = (_weapon_sticker_frame_idx + 1) % _weapon_sticker_frames.size()
	sticker_visual.texture = _weapon_sticker_frames[_weapon_sticker_frame_idx]
