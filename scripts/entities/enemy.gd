extends CharacterBody2D
class_name Enemy

signal died(enemy_id: String, xp_reward: int)
signal summon_requested(enemy_type_id: String, count: int, world_position: Vector2)
signal explosion_requested(world_position: Vector2, radius: float, damage: float, source_enemy_id: String)
signal boss_telegraph_requested(telegraph_type: String, payload: Dictionary)
signal boss_echoes_spawned(count: int, world_position: Vector2)
signal boss_true_form_revealed(world_position: Vector2)

const BossEchoDecoyScene := preload("res://scenes/enemy/BossEchoDecoy.tscn")
const PixelStickerRegistry := preload("res://scripts/visual/pixel_sticker_registry.gd")
const CombatPaletteClass := preload("res://scripts/visual/combat_palette.gd")
const ENEMY_IDLE_FRAME_SEC := 0.12
const ENEMY_BOB_AMPLITUDE := 0.72
const VISUAL_OFFSET_SNAP := 0.25
const HIT_OUTLINE_PULSE_SEC := 0.16
const HIT_OUTLINE_SCALE_BONUS := 0.18
const HIT_OUTLINE_LIGHTEN := 0.58
const ENEMY_AURA_BASE_SCALE := 1.58
const ENEMY_AURA_PULSE_AMPLITUDE := 0.11
const ENEMY_AURA_BASE_ALPHA := 0.20
const ENEMY_AURA_ELITE_ALPHA_BONUS := 0.08
const ENEMY_AURA_PURSUER_ALPHA_BONUS := 0.10

var enemy_id := "drifter"
var enemy_name := "Drifter"
var behavior := "drifter"
var spawn_group := "normal"
var max_hp := 20.0
var hp := 20.0
var speed := 100.0
var contact_damage := 8.0
var contact_cooldown := 0.7
var threat := 1.0
var xp_reward := 5
var body_radius := 14.0
var knockback_velocity := Vector2.ZERO
var contact_timer := 0.0
var target: Node2D
var reveal_until: float = 0.0
var reveal_reaction: String = "none"
var reveal_reaction_duration: float = 0.0
var noise_aggression_scale: float = 0.0

var is_elite: bool = false
var elite_affix_id: String = ""
var damage_reduction: float = 0.0
var elite_noise_aura_add: float = 0.0
var elite_pursuer_bonus: float = 0.0
var elite_reveal_duration_mult: float = 1.0
var elite_jam_radius: float = 0.0
var elite_xp_siphon_rate: float = 0.0
var elite_siphon_radius: float = 0.0

var shield_hp: float = 0.0
var shield_max_hp: float = 0.0
var shield_reveal_break: bool = false

var dash_speed: float = 380.0
var dash_cooldown: float = 3.4
var dash_windup: float = 0.45
var dash_cooldown_remaining: float = 0.0
var dash_windup_remaining: float = 0.0
var dash_active_remaining: float = 0.0
var dash_direction := Vector2.RIGHT

var ranged_range: float = 320.0
var ranged_cooldown: float = 2.0
var ranged_damage: float = 7.0
var ranged_cooldown_remaining: float = 0.0

var split_on_death: bool = false
var split_into_id: String = ""
var split_count: int = 0

var explode_radius: float = 0.0
var explode_damage: float = 0.0
var explode_windup: float = 0.0
var explode_primed: bool = false
var explode_timer: float = 0.0

var summon_enemy_id: String = ""
var summon_interval: float = 6.0
var summon_count: int = 1
var summon_timer: float = 0.0

var lurker_evasion: float = 0.0
var lurker_speed_boost: float = 1.0

var leech_noise_delta: float = 0.0
var leech_xp_drain: int = 0

var magnet_radius: float = 0.0
var magnet_force: float = 0.0

var stagger_timer: float = 0.0
var rage_timer: float = 0.0
var runtime_speed_multiplier: float = 1.0
var burn_dps: float = 0.0
var burn_remaining: float = 0.0
var burn_tick_timer: float = 0.0
var chill_slow_ratio: float = 0.0
var chill_remaining: float = 0.0
var shock_remaining: float = 0.0
var shock_tick_timer: float = 0.0

var boss_phase_id: String = ""
var boss_phase_label: String = ""
var boss_requires_reveal_lock: bool = false
var boss_hidden_damage_multiplier: float = 0.35
var boss_fake_echoes: int = 0
var boss_phase_spawn_rate_mult: float = 1.0
var boss_phase_fog_radius_mult: float = 1.0
var boss_pending_attack: bool = false
var boss_attack_windup_remaining: float = 0.0
var boss_attack_windup_duration: float = 0.42
var boss_echo_count_runtime: int = 0
var boss_true_form_exposed_announced: bool = false
var boss_decoys: Array[Node] = []
var boss_exam_type: String = ""
var boss_exam_objective: String = ""
var boss_noise_fail_threshold: float = 50.0
var boss_noise_fail_damage_taken_mult: float = 0.65
var boss_noise_fail_attack_damage_mult: float = 1.22
var boss_noise_fail_attack_cooldown_mult: float = 0.82
var boss_mobility_dodge_distance: float = 84.0
var boss_mobility_fail_damage_mult: float = 1.55
var boss_mobility_success_damage_mult: float = 0.72
var boss_attack_target_anchor: Vector2 = Vector2.ZERO
var boss_attack_target_anchor_valid: bool = false
var boss_summon_break_active: bool = false
var boss_summon_break_remaining: int = 0
var boss_summon_break_total_required: int = 0
var boss_summon_break_shield_mult: float = 0.18
var recycle_handler: Callable = Callable()
var pooled_active: bool = false
var default_collision_layer: int = 2
var default_collision_mask: int = 0
var _sticker_frames: Array[Texture2D] = []
var _sticker_idle_timer: float = 0.0
var _sticker_frame_idx: int = 0
var _sticker_base_position: Vector2 = Vector2.ZERO
var _sticker_idle_offset_y: float = 0.0
var _body_base_scale: Vector2 = Vector2.ONE
var _outline_base_scale: Vector2 = Vector2.ONE
var _outline_base_color: Color = Color(0.72, 0.96, 1.0, 1.0)
var _hit_outline_timer: float = 0.0
var _palette_seed_color: Color = Color(0.22, 0.9, 1.0, 1.0)
var _enemy_aura_visual: Polygon2D
var _enemy_aura_phase: float = 0.0

@onready var outline_visual: Polygon2D = $Outline
@onready var body_visual: Polygon2D = $Body
@onready var sticker_visual: Sprite2D = $Sticker
@onready var collision_shape: CollisionShape2D = $CollisionShape2D


func _ready() -> void:
	default_collision_layer = collision_layer
	default_collision_mask = collision_mask
	if sticker_visual != null:
		_sticker_base_position = sticker_visual.position
	_ensure_enemy_aura_visual()
	on_pool_recycle()


func set_recycle_handler(handler: Callable) -> void:
	recycle_handler = handler


func setup(new_enemy_id: String, definition: Dictionary, player_target: Node2D, runtime_modifiers: Dictionary = {}) -> void:
	on_pool_spawned()
	enemy_id = new_enemy_id
	enemy_name = String(definition.get("name", new_enemy_id))
	behavior = String(definition.get("behavior", "drifter")).strip_edges().to_lower()
	spawn_group = String(definition.get("spawn_group", "normal")).strip_edges().to_lower()
	target = player_target
	max_hp = maxf(1.0, float(definition.get("max_hp", max_hp)))
	hp = max_hp
	speed = maxf(0.0, float(definition.get("speed", speed)))
	contact_damage = maxf(0.0, float(definition.get("damage", contact_damage)))
	contact_cooldown = maxf(0.05, float(definition.get("contact_cooldown", contact_cooldown)))
	threat = maxf(0.1, float(definition.get("threat", threat)))
	xp_reward = maxi(0, int(definition.get("xp_reward", xp_reward)))
	body_radius = maxf(4.0, float(definition.get("size", body_radius)))
	noise_aggression_scale = maxf(0.0, float(definition.get("noise_aggression_scale", 0.0)))
	reveal_reaction = String(definition.get("reveal_reaction", "none")).strip_edges().to_lower()
	reveal_reaction_duration = maxf(0.0, float(definition.get("reveal_reaction_duration", 0.0)))

	# Shielded
	shield_max_hp = maxf(0.0, float(definition.get("shield_hp", 0.0)))
	shield_hp = shield_max_hp
	shield_reveal_break = bool(definition.get("shield_reveal_break", false))

	# Sprinter
	dash_speed = maxf(40.0, float(definition.get("dash_speed", 380.0)))
	dash_cooldown = maxf(0.2, float(definition.get("dash_cooldown", 3.4)))
	dash_windup = maxf(0.0, float(definition.get("dash_windup", 0.45)))
	dash_cooldown_remaining = randf_range(0.1, dash_cooldown * 0.5)
	dash_windup_remaining = 0.0
	dash_active_remaining = 0.0

	# Shooter
	ranged_range = maxf(80.0, float(definition.get("ranged_range", 320.0)))
	ranged_cooldown = maxf(0.2, float(definition.get("ranged_cooldown", 2.0)))
	ranged_damage = maxf(0.0, float(definition.get("ranged_damage", contact_damage * 0.8)))
	ranged_cooldown_remaining = randf_range(0.1, ranged_cooldown)

	# Splitter
	split_on_death = bool(definition.get("split_on_death", false))
	split_into_id = String(definition.get("split_into_id", "")).strip_edges()
	split_count = maxi(0, int(definition.get("split_count", 0)))

	# Bloater
	explode_radius = maxf(0.0, float(definition.get("explode_radius", 0.0)))
	explode_damage = maxf(0.0, float(definition.get("explode_damage", 0.0)))
	explode_windup = maxf(0.0, float(definition.get("explode_windup", 0.0)))
	explode_primed = false
	explode_timer = 0.0

	# Summoner
	summon_enemy_id = String(definition.get("summon_enemy_id", "")).strip_edges()
	summon_interval = maxf(0.1, float(definition.get("summon_interval", 6.0)))
	summon_count = maxi(0, int(definition.get("summon_count", 1)))
	summon_timer = randf_range(0.1, summon_interval)

	# Lurker
	lurker_evasion = clampf(float(definition.get("lurker_evasion", 0.0)), 0.0, 0.95)
	lurker_speed_boost = maxf(1.0, float(definition.get("lurker_speed_boost", 1.0)))

	# Leech
	leech_noise_delta = float(definition.get("leech_noise_delta", 0.0))
	leech_xp_drain = maxi(0, int(definition.get("leech_xp_drain", 0)))

	# Magnetoid
	magnet_radius = maxf(0.0, float(definition.get("magnet_radius", 0.0)))
	magnet_force = maxf(0.0, float(definition.get("magnet_force", 0.0)))
	runtime_speed_multiplier = maxf(0.05, float(runtime_modifiers.get("speed_mult", 1.0)))

	# Elite / affix runtime state reset.
	is_elite = false
	elite_affix_id = ""
	damage_reduction = 0.0
	elite_noise_aura_add = 0.0
	elite_pursuer_bonus = 0.0
	elite_reveal_duration_mult = 1.0
	elite_jam_radius = 0.0
	elite_xp_siphon_rate = 0.0
	elite_siphon_radius = 0.0
	burn_dps = 0.0
	burn_remaining = 0.0
	burn_tick_timer = 0.0
	chill_slow_ratio = 0.0
	chill_remaining = 0.0
	shock_remaining = 0.0
	shock_tick_timer = 0.0

	# Boss runtime defaults.
	boss_phase_id = ""
	boss_phase_label = ""
	boss_requires_reveal_lock = false
	boss_hidden_damage_multiplier = 0.35
	boss_fake_echoes = 0
	boss_phase_spawn_rate_mult = 1.0
	boss_phase_fog_radius_mult = 1.0
	boss_pending_attack = false
	boss_attack_windup_remaining = 0.0
	boss_attack_windup_duration = 0.42
	boss_echo_count_runtime = 0
	boss_true_form_exposed_announced = false
	boss_exam_type = ""
	boss_exam_objective = ""
	boss_noise_fail_threshold = 50.0
	boss_noise_fail_damage_taken_mult = 0.65
	boss_noise_fail_attack_damage_mult = 1.22
	boss_noise_fail_attack_cooldown_mult = 0.82
	boss_mobility_dodge_distance = 84.0
	boss_mobility_fail_damage_mult = 1.55
	boss_mobility_success_damage_mult = 0.72
	boss_attack_target_anchor = Vector2.ZERO
	boss_attack_target_anchor_valid = false
	boss_summon_break_active = false
	boss_summon_break_remaining = 0
	boss_summon_break_total_required = 0
	boss_summon_break_shield_mult = 0.18
	_clear_boss_decoys()
	if behavior == "boss":
		var initial_phase := {}
		if definition.has("initial_phase") and definition.get("initial_phase", null) is Dictionary:
			initial_phase = (definition.get("initial_phase", {}) as Dictionary).duplicate(true)
		apply_boss_phase(initial_phase, definition)

	var color_text := String(definition.get("color", "#38e7ff"))
	_palette_seed_color = Color.from_string(color_text, Color(0.22, 0.9, 1.0, 1.0))

	var shape := collision_shape.shape
	if shape is CircleShape2D:
		shape.radius = body_radius
	body_visual.scale = Vector2.ONE * (body_radius / 15.0)
	_body_base_scale = body_visual.scale
	outline_visual.scale = Vector2.ONE * ((body_radius / 15.0) * 1.24)
	_outline_base_scale = outline_visual.scale
	_apply_enemy_sticker()
	z_index = CombatPaletteClass.LAYER_ENEMY

	add_to_group("enemy")
	if spawn_group == "pursuer":
		add_to_group("pursuer")
		is_elite = true
		_palette_seed_color = Color(1.0, 0.52, 0.66, 1.0)
	if behavior == "boss":
		add_to_group("boss")
	_refresh_enemy_palette()
	_update_reveal_visual()


func _physics_process(delta: float) -> void:
	if not pooled_active:
		return
	_tick_idle_sticker(delta)
	_tick_hit_outline_pulse(delta)
	_tick_enemy_aura_visual(delta)
	if target == null or not is_instance_valid(target):
		return

	contact_timer = maxf(0.0, contact_timer - delta)
	stagger_timer = maxf(0.0, stagger_timer - delta)
	rage_timer = maxf(0.0, rage_timer - delta)
	dash_cooldown_remaining = maxf(0.0, dash_cooldown_remaining - delta)
	dash_windup_remaining = maxf(0.0, dash_windup_remaining - delta)
	dash_active_remaining = maxf(0.0, dash_active_remaining - delta)
	ranged_cooldown_remaining = maxf(0.0, ranged_cooldown_remaining - delta)
	boss_attack_windup_remaining = maxf(0.0, boss_attack_windup_remaining - delta)
	summon_timer = maxf(0.0, summon_timer - delta)
	_update_status_effects(delta)

	if behavior == "summoner" and summon_timer <= 0.0:
		_try_summon()
		summon_timer = summon_interval

	if behavior == "magnetoid":
		_apply_magnet_pull(delta)
	if behavior == "boss":
		_apply_boss_aura(delta)
	if is_elite:
		_apply_elite_auras(delta)

	var to_target := target.global_position - global_position
	var distance := to_target.length()
	var dir := to_target.normalized() if distance > 0.01 else Vector2.ZERO

	if behavior == "bloater":
		_update_bloater_state(distance)

	if explode_primed:
		explode_timer -= delta
		velocity = Vector2.ZERO
		if explode_timer <= 0.0:
			_trigger_bloater_explosion()
			return
	elif stagger_timer > 0.0:
		velocity = knockback_velocity
		knockback_velocity = knockback_velocity.move_toward(Vector2.ZERO, 720.0 * delta)
		move_and_slide()
		_update_reveal_visual()
		return
	else:
		_match_behavior_movement(delta, distance, dir)

	knockback_velocity = knockback_velocity.move_toward(Vector2.ZERO, 640.0 * delta)
	move_and_slide()
	_update_reveal_visual()

	if distance <= body_radius + 13.0 and contact_timer <= 0.0:
		if target.has_method("take_damage"):
			target.take_damage(contact_damage)
		_apply_contact_specials()
		contact_timer = contact_cooldown


func _match_behavior_movement(delta: float, distance: float, dir: Vector2) -> void:
	var aggression := _get_noise_aggression_multiplier()
	var move_speed := speed * aggression * runtime_speed_multiplier
	if rage_timer > 0.0:
		move_speed *= 1.18
	if chill_remaining > 0.0 and chill_slow_ratio > 0.0:
		move_speed *= maxf(0.2, 1.0 - chill_slow_ratio)

	match behavior:
		"sprinter":
			_update_sprinter_movement(distance, dir, move_speed)
		"shooter":
			_update_shooter_movement(distance, dir, move_speed)
		"lurker":
			if not is_revealed():
				move_speed *= lurker_speed_boost
			velocity = (dir * move_speed) + knockback_velocity
		"summoner":
			velocity = (dir * move_speed * 0.78) + knockback_velocity
		"magnetoid":
			velocity = (dir * move_speed * 0.82) + knockback_velocity
		"pursuer":
			velocity = (dir * move_speed * 1.08) + knockback_velocity
		"boss":
			_update_boss_movement(distance, dir, move_speed)
		_:
			velocity = (dir * move_speed) + knockback_velocity

	if behavior == "shooter" or behavior == "boss":
		_update_shooter_attack(distance)


func _update_boss_movement(distance: float, dir: Vector2, move_speed: float) -> void:
	var anchor_range := ranged_range * 0.72
	if distance < anchor_range:
		velocity = (-dir * move_speed * 0.35) + knockback_velocity
	elif distance > ranged_range * 1.3:
		velocity = (dir * move_speed * 0.52) + knockback_velocity
	else:
		velocity = (dir * move_speed * 0.12) + knockback_velocity


func _update_sprinter_movement(distance: float, dir: Vector2, move_speed: float) -> void:
	if dash_active_remaining > 0.0:
		velocity = dash_direction * dash_speed + knockback_velocity
		return
	if dash_windup_remaining > 0.0:
		velocity = knockback_velocity
		return
	if dash_cooldown_remaining <= 0.0 and distance <= 300.0 and dir.length() > 0.0:
		dash_direction = dir
		dash_windup_remaining = dash_windup
		dash_active_remaining = 0.32
		dash_cooldown_remaining = dash_cooldown
		velocity = knockback_velocity
		return
	velocity = (dir * move_speed) + knockback_velocity


func _update_shooter_movement(distance: float, dir: Vector2, move_speed: float) -> void:
	var keep_range := ranged_range * 0.8
	var approach_range := ranged_range * 1.15
	if distance < keep_range:
		velocity = (-dir * move_speed * 0.9) + knockback_velocity
	elif distance > approach_range:
		velocity = (dir * move_speed * 0.7) + knockback_velocity
	else:
		velocity = knockback_velocity


func _update_shooter_attack(distance: float) -> void:
	if behavior == "boss":
		if distance > ranged_range:
			boss_pending_attack = false
			boss_attack_windup_remaining = 0.0
			boss_attack_target_anchor_valid = false
			return
		if ranged_cooldown_remaining > 0.0:
			return
		if not boss_pending_attack:
			boss_pending_attack = true
			boss_attack_windup_remaining = boss_attack_windup_duration
			if target != null and is_instance_valid(target):
				boss_attack_target_anchor = target.global_position
				boss_attack_target_anchor_valid = true
			else:
				boss_attack_target_anchor_valid = false
			_emit_boss_attack_telegraph(distance)
			return
		if boss_attack_windup_remaining > 0.0:
			return
		boss_pending_attack = false
		var attack_damage := ranged_damage * _get_boss_exam_attack_damage_multiplier()
		if boss_exam_type == "mobility":
			attack_damage *= _resolve_boss_mobility_exam_damage_multiplier()
		if target != null and is_instance_valid(target) and target.has_method("take_damage"):
			target.take_damage(attack_damage)
		ranged_cooldown_remaining = ranged_cooldown * _get_boss_exam_attack_cooldown_multiplier()
		return

	if ranged_cooldown_remaining > 0.0:
		return
	if distance > ranged_range:
		return
	if target != null and is_instance_valid(target) and target.has_method("take_damage"):
		target.take_damage(ranged_damage)
	ranged_cooldown_remaining = ranged_cooldown


func _update_bloater_state(distance: float) -> void:
	if explode_primed:
		return
	if explode_radius <= 0.0 or explode_windup <= 0.0:
		return
	if distance <= explode_radius * 0.72:
		explode_primed = true
		explode_timer = explode_windup
		outline_visual.visible = true


func _trigger_bloater_explosion() -> void:
	explode_primed = false
	if target != null and is_instance_valid(target) and target.has_method("take_damage"):
		if target.global_position.distance_to(global_position) <= explode_radius:
			target.take_damage(explode_damage)
	explosion_requested.emit(global_position, explode_radius, explode_damage, enemy_id)
	_on_death(true)


func _try_summon() -> void:
	if summon_enemy_id.is_empty() or summon_count <= 0:
		return
	summon_requested.emit(summon_enemy_id, summon_count, global_position)


func _apply_magnet_pull(delta: float) -> void:
	if magnet_radius <= 0.0 or magnet_force <= 0.0:
		return
	if target == null or not is_instance_valid(target):
		return
	var to_enemy := global_position - target.global_position
	var distance := to_enemy.length()
	if distance <= 0.01 or distance > magnet_radius:
		return
	var pull_strength := (1.0 - (distance / magnet_radius)) * magnet_force
	target.global_position += to_enemy.normalized() * pull_strength * delta * 0.08


func _apply_contact_specials() -> void:
	if target == null or not is_instance_valid(target):
		return
	if behavior == "leech":
		if leech_noise_delta > 0.0 and target.has_method("add_noise_delta"):
			target.add_noise_delta(leech_noise_delta)
		if leech_xp_drain > 0:
			_drain_target_xp(float(leech_xp_drain))
	if elite_xp_siphon_rate > 0.0:
		_drain_target_xp(elite_xp_siphon_rate)


func _drain_target_xp(amount: float) -> void:
	if amount <= 0.0:
		return
	if target == null or not is_instance_valid(target):
		return
	var xp_variant: Variant = target.get("xp")
	if xp_variant == null:
		return
	target.set("xp", maxf(0.0, float(xp_variant) - amount))


func _get_noise_aggression_multiplier() -> float:
	if target == null or not is_instance_valid(target):
		return 1.0
	if not ("noise" in target):
		return 1.0
	var noise_value := clampf(float(target.get("noise")), 0.0, 100.0)
	return 1.0 + ((noise_value / 100.0) * noise_aggression_scale)


func get_threat_score(reference_position: Vector2) -> float:
	var distance: float = maxf(32.0, global_position.distance_to(reference_position))
	var score := threat + (160.0 / distance)
	if behavior == "pursuer":
		score *= 1.45
	if is_elite:
		score *= 1.22
	if not is_revealed() and behavior == "lurker":
		score *= 1.2
	return score


func take_hit(damage: float, impulse: Vector2 = Vector2.ZERO) -> bool:
	var resolved_damage := maxf(0.0, damage)
	if behavior == "lurker" and not is_revealed() and lurker_evasion > 0.0 and randf() <= lurker_evasion:
		return false
	if behavior == "boss" and boss_requires_reveal_lock and not is_revealed():
		resolved_damage *= clampf(boss_hidden_damage_multiplier, 0.05, 1.0)
	if behavior == "boss":
		resolved_damage *= _get_boss_exam_damage_taken_multiplier()
	if shield_hp > 0.0:
		shield_hp = maxf(0.0, shield_hp - resolved_damage)
		if shield_hp > 0.0:
			_flash_hit(true)
			return false
	if damage_reduction > 0.0:
		resolved_damage *= maxf(0.05, 1.0 - damage_reduction)
	hp -= resolved_damage
	knockback_velocity += impulse
	_flash_hit(false)
	if hp <= 0.0:
		return _on_death(false)
	return false


func _on_death(from_explosion: bool) -> bool:
	if not pooled_active:
		return false
	if split_on_death and not split_into_id.is_empty() and split_count > 0:
		summon_requested.emit(split_into_id, split_count, global_position)
	if behavior == "bloater" and not from_explosion and explode_radius > 0.0 and explode_damage > 0.0:
		explosion_requested.emit(global_position, explode_radius, explode_damage, enemy_id)
	if behavior == "boss":
		_clear_boss_decoys()
	died.emit(enemy_id, xp_reward)
	_request_recycle()
	return true


func _flash_hit(shield_only: bool) -> void:
	_hit_outline_timer = HIT_OUTLINE_PULSE_SEC
	if outline_visual != null:
		outline_visual.visible = true
		outline_visual.scale = _outline_base_scale * (1.0 + HIT_OUTLINE_SCALE_BONUS)
		var peak_outline := _outline_base_color.lightened(HIT_OUTLINE_LIGHTEN)
		if shield_only:
			peak_outline = peak_outline.lerp(Color(0.80, 1.0, 1.0, peak_outline.a), 0.34)
		outline_visual.color = peak_outline
	if shield_only:
		_set_enemy_visual_modulate(Color(0.9, 1.35, 1.6, 1.0))
	else:
		_set_enemy_visual_modulate(Color(1.6, 1.6, 1.6, 1.0))
	var tween := create_tween()
	if sticker_visual != null and sticker_visual.visible:
		tween.tween_property(sticker_visual, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.08)
	else:
		tween.tween_property(body_visual, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.08)


func _tick_hit_outline_pulse(delta: float) -> void:
	if outline_visual == null:
		return
	if _hit_outline_timer <= 0.0:
		outline_visual.scale = _outline_base_scale
		outline_visual.color = _outline_base_color
		return
	_hit_outline_timer = maxf(0.0, _hit_outline_timer - delta)
	var ratio := clampf(_hit_outline_timer / HIT_OUTLINE_PULSE_SEC, 0.0, 1.0)
	var pulse := pow(ratio, 0.42)
	outline_visual.scale = _outline_base_scale * (1.0 + HIT_OUTLINE_SCALE_BONUS * pulse)
	outline_visual.color = _outline_base_color.lerp(_outline_base_color.lightened(HIT_OUTLINE_LIGHTEN), pulse)
	if _hit_outline_timer <= 0.0:
		outline_visual.scale = _outline_base_scale
		outline_visual.color = _outline_base_color


func apply_status_effect(effect_id: String, duration: float, power: float = 0.0) -> void:
	if not pooled_active:
		return
	var effect := effect_id.strip_edges().to_lower()
	match effect:
		"burn":
			burn_remaining = maxf(burn_remaining, clampf(duration, 0.2, 8.0))
			burn_dps = maxf(burn_dps, maxf(0.5, power))
			if burn_tick_timer <= 0.0:
				burn_tick_timer = 0.18
		"chill":
			chill_remaining = maxf(chill_remaining, clampf(duration, 0.15, 6.0))
			chill_slow_ratio = maxf(chill_slow_ratio, clampf(power, 0.05, 0.75))
		"shock":
			shock_remaining = maxf(shock_remaining, clampf(duration, 0.1, 4.0))
			if shock_tick_timer <= 0.0:
				shock_tick_timer = 0.12
		_:
			return


func _update_status_effects(delta: float) -> void:
	if burn_remaining > 0.0:
		burn_remaining = maxf(0.0, burn_remaining - delta)
		burn_tick_timer = maxf(0.0, burn_tick_timer - delta)
		if burn_tick_timer <= 0.0 and burn_dps > 0.0:
			burn_tick_timer = 0.24
			_apply_status_tick_damage(burn_dps * 0.24)
			_set_enemy_visual_modulate(Color(1.45, 0.95, 0.72, 1.0))
	elif burn_dps > 0.0:
		burn_dps = 0.0
		burn_tick_timer = 0.0

	if chill_remaining > 0.0:
		chill_remaining = maxf(0.0, chill_remaining - delta)
	elif chill_slow_ratio > 0.0:
		chill_slow_ratio = 0.0

	if shock_remaining > 0.0:
		shock_remaining = maxf(0.0, shock_remaining - delta)
		shock_tick_timer = maxf(0.0, shock_tick_timer - delta)
		if shock_tick_timer <= 0.0:
			shock_tick_timer = 0.20
			stagger_timer = maxf(stagger_timer, 0.05)
			_set_enemy_visual_modulate(Color(0.86, 1.22, 1.58, 1.0))
	elif shock_tick_timer > 0.0:
		shock_tick_timer = 0.0


func _apply_status_tick_damage(amount: float) -> void:
	if amount <= 0.0 or hp <= 0.0:
		return
	var resolved_damage := amount
	if shield_hp > 0.0:
		shield_hp = maxf(0.0, shield_hp - resolved_damage * 0.6)
		if shield_hp > 0.0:
			_flash_hit(true)
			return
	if damage_reduction > 0.0:
		resolved_damage *= maxf(0.05, 1.0 - (damage_reduction * 0.7))
	hp -= resolved_damage
	_flash_hit(false)
	if hp <= 0.0:
		_on_death(false)


func set_revealed(duration_sec: float) -> void:
	var now_sec := float(Time.get_ticks_msec()) * 0.001
	var final_duration := maxf(0.05, duration_sec * elite_reveal_duration_mult)
	reveal_until = maxf(reveal_until, now_sec + final_duration)
	match reveal_reaction:
		"stagger":
			stagger_timer = maxf(stagger_timer, reveal_reaction_duration)
		"rage":
			rage_timer = maxf(rage_timer, reveal_reaction_duration)
		"shield_break":
			if shield_reveal_break:
				shield_hp = 0.0
		_:
			pass
	if behavior == "boss" and boss_requires_reveal_lock and is_revealed():
		if not boss_true_form_exposed_announced:
			boss_true_form_exposed_announced = true
			boss_true_form_revealed.emit(global_position)
		_dissipate_boss_decoys()
	_update_reveal_visual()


func is_revealed() -> bool:
	var now_sec := float(Time.get_ticks_msec()) * 0.001
	return now_sec < reveal_until


func _update_reveal_visual() -> void:
	var revealed := is_revealed()
	outline_visual.visible = revealed or shield_hp > 0.0 or is_elite or _hit_outline_timer > 0.0
	if _enemy_aura_visual != null:
		_enemy_aura_visual.visible = pooled_active and (revealed or shield_hp > 0.0 or is_elite or _hit_outline_timer > 0.0 or behavior == "boss")
	if revealed:
		_set_enemy_visual_modulate(Color(1.12, 1.12, 1.16, 1.0))
	elif shield_hp > 0.0:
		_set_enemy_visual_modulate(Color(0.85, 1.12, 1.3, 1.0))
	else:
		_set_enemy_visual_modulate(Color(1.0, 1.0, 1.0, 1.0))


func apply_elite_affix(affix: Dictionary) -> void:
	if affix.is_empty():
		return
	is_elite = true
	elite_affix_id = String(affix.get("id", "")).strip_edges()
	var multipliers_variant: Variant = affix.get("stat_multipliers", {})
	if multipliers_variant is Dictionary:
		var multipliers: Dictionary = multipliers_variant
		max_hp *= maxf(0.1, float(multipliers.get("max_hp_mult", 1.0)))
		hp = max_hp
		speed *= maxf(0.1, float(multipliers.get("speed_mult", 1.0)))
		contact_damage *= maxf(0.1, float(multipliers.get("damage_mult", 1.0)))
		threat *= maxf(0.1, float(multipliers.get("threat_mult", 1.0)))
	var effects_variant: Variant = affix.get("effects", {})
	if effects_variant is Dictionary:
		var effects: Dictionary = effects_variant
		damage_reduction = clampf(float(effects.get("damage_reduction", damage_reduction)), 0.0, 0.85)
		if effects.has("death_explosion_radius"):
			explode_radius = maxf(explode_radius, float(effects.get("death_explosion_radius", explode_radius)))
		if effects.has("death_explosion_damage"):
			explode_damage = maxf(explode_damage, float(effects.get("death_explosion_damage", explode_damage)))
		if effects.has("noise_aura_add"):
			elite_noise_aura_add = maxf(0.0, float(effects.get("noise_aura_add", 0.0)))
		if effects.has("pursuer_bonus"):
			elite_pursuer_bonus = maxf(0.0, float(effects.get("pursuer_bonus", 0.0)))
		if effects.has("sonar_reveal_mult"):
			elite_reveal_duration_mult = clampf(float(effects.get("sonar_reveal_mult", 1.0)), 0.2, 2.0)
		if effects.has("jam_radius"):
			elite_jam_radius = maxf(0.0, float(effects.get("jam_radius", 0.0)))
		if effects.has("xp_siphon_rate"):
			elite_xp_siphon_rate = maxf(0.0, float(effects.get("xp_siphon_rate", 0.0)))
		if effects.has("siphon_radius"):
			elite_siphon_radius = maxf(0.0, float(effects.get("siphon_radius", 0.0)))
	_palette_seed_color = Color.from_string(String(affix.get("color", "#ffd37f")), Color(1.0, 0.84, 0.6, 1.0))
	_refresh_enemy_palette()
	xp_reward = int(round(float(xp_reward) * (1.0 + maxf(0.0, float(affix.get("drop_bonus", 0.0))))))
	add_to_group("elite")
	_update_reveal_visual()


func apply_boss_phase(phase: Dictionary, boss_config: Dictionary = {}) -> void:
	if phase.is_empty():
		return
	boss_phase_id = String(phase.get("id", boss_phase_id)).strip_edges()
	boss_phase_label = String(phase.get("label", boss_phase_label))
	var attack_interval := maxf(0.2, float(phase.get("attack_interval", ranged_cooldown)))
	ranged_cooldown = attack_interval
	ranged_cooldown_remaining = minf(ranged_cooldown_remaining, ranged_cooldown)
	var summon_interval_phase := maxf(0.1, float(phase.get("summon_interval", summon_interval)))
	summon_interval = summon_interval_phase
	summon_count = maxi(0, int(phase.get("summon_count", summon_count)))
	boss_phase_spawn_rate_mult = maxf(0.05, float(phase.get("spawn_rate_mult", 1.0)))
	boss_phase_fog_radius_mult = maxf(0.05, float(phase.get("fog_radius_mult", 1.0)))
	boss_requires_reveal_lock = bool(phase.get("sonar_lock_required", false))
	boss_fake_echoes = maxi(0, int(boss_config.get("fake_echoes", boss_fake_echoes)))
	boss_echo_count_runtime = clampi(int(phase.get("echo_count", boss_fake_echoes)), 0, 6)
	boss_attack_windup_duration = clampf(float(phase.get("attack_windup", boss_attack_windup_duration)), 0.12, 1.4)
	boss_pending_attack = false
	boss_attack_windup_remaining = 0.0
	boss_attack_target_anchor_valid = false
	boss_true_form_exposed_announced = false
	boss_exam_type = String(phase.get("exam_type", "")).strip_edges().to_lower()
	boss_exam_objective = String(phase.get("exam_objective", "")).strip_edges()
	boss_noise_fail_threshold = clampf(float(phase.get("noise_fail_threshold", boss_noise_fail_threshold)), 5.0, 100.0)
	boss_noise_fail_damage_taken_mult = clampf(float(phase.get("noise_fail_damage_taken_mult", boss_noise_fail_damage_taken_mult)), 0.05, 1.0)
	boss_noise_fail_attack_damage_mult = maxf(0.1, float(phase.get("noise_fail_attack_damage_mult", boss_noise_fail_attack_damage_mult)))
	boss_noise_fail_attack_cooldown_mult = clampf(float(phase.get("noise_fail_attack_cooldown_mult", boss_noise_fail_attack_cooldown_mult)), 0.3, 2.0)
	boss_mobility_dodge_distance = clampf(float(phase.get("movement_dodge_distance", boss_mobility_dodge_distance)), 18.0, 360.0)
	boss_mobility_fail_damage_mult = maxf(0.2, float(phase.get("movement_fail_damage_mult", boss_mobility_fail_damage_mult)))
	boss_mobility_success_damage_mult = clampf(float(phase.get("movement_success_damage_mult", boss_mobility_success_damage_mult)), 0.15, 1.2)
	boss_summon_break_shield_mult = clampf(float(phase.get("summon_break_shield_mult", boss_summon_break_shield_mult)), 0.02, 1.0)
	boss_summon_break_total_required = maxi(0, int(phase.get("summon_break_kills_required", boss_summon_break_total_required)))
	if boss_exam_type == "summon_break":
		boss_summon_break_remaining = boss_summon_break_total_required
		boss_summon_break_active = boss_summon_break_remaining > 0
	else:
		boss_summon_break_remaining = 0
		boss_summon_break_total_required = 0
		boss_summon_break_active = false
	if phase.has("hidden_damage_multiplier"):
		boss_hidden_damage_multiplier = clampf(float(phase.get("hidden_damage_multiplier", boss_hidden_damage_multiplier)), 0.05, 1.0)
	elif boss_config.has("hidden_damage_multiplier"):
		boss_hidden_damage_multiplier = clampf(float(boss_config.get("hidden_damage_multiplier", boss_hidden_damage_multiplier)), 0.05, 1.0)
	boss_telegraph_requested.emit("ring", {
		"origin": global_position,
		"radius": maxf(90.0, ranged_range * 0.62),
		"duration": 0.85,
		"line_width": 5.5,
		"color": String(boss_config.get("telegraph_color", "#8be8ff"))
	})
	if boss_requires_reveal_lock:
		_spawn_boss_echo_decoys(boss_echo_count_runtime)
		boss_echoes_spawned.emit(get_boss_decoy_count(), global_position)
		outline_visual.visible = true
	else:
		_clear_boss_decoys()


func get_hp_ratio() -> float:
	if max_hp <= 0.0:
		return 0.0
	return clampf(hp / max_hp, 0.0, 1.0)


func get_pursuer_bonus() -> float:
	return elite_pursuer_bonus


func get_noise_aura_add() -> float:
	return elite_noise_aura_add


func get_elite_jam_multiplier(reference_position: Vector2) -> float:
	if elite_jam_radius <= 0.0:
		return 1.0
	var distance := global_position.distance_to(reference_position)
	if distance > elite_jam_radius:
		return 1.0
	var ratio := 1.0 - clampf(distance / elite_jam_radius, 0.0, 1.0)
	return 1.0 - (0.22 * ratio)


func get_summon_interval() -> float:
	return summon_interval


func get_summon_count() -> int:
	return summon_count


func get_boss_phase_id() -> String:
	return boss_phase_id


func get_boss_phase_spawn_rate_multiplier() -> float:
	return boss_phase_spawn_rate_mult


func get_boss_phase_fog_multiplier() -> float:
	return boss_phase_fog_radius_mult


func get_boss_exam_type() -> String:
	return boss_exam_type


func get_boss_exam_objective() -> String:
	return boss_exam_objective


func set_boss_summon_break_state(active: bool, remaining: int, total_required: int = 0) -> void:
	boss_summon_break_active = active
	boss_summon_break_remaining = maxi(0, remaining)
	if total_required > 0:
		boss_summon_break_total_required = total_required
	elif not boss_summon_break_active:
		boss_summon_break_total_required = 0


func get_boss_summon_break_remaining() -> int:
	return boss_summon_break_remaining


func get_boss_summon_break_total_required() -> int:
	return boss_summon_break_total_required


func _apply_elite_auras(delta: float) -> void:
	if target == null or not is_instance_valid(target):
		return
	if elite_noise_aura_add > 0.0 and target.has_method("add_noise_delta"):
		target.add_noise_delta(elite_noise_aura_add * delta)
	if elite_xp_siphon_rate > 0.0 and elite_siphon_radius > 0.0:
		if global_position.distance_to(target.global_position) <= elite_siphon_radius:
			_drain_target_xp(elite_xp_siphon_rate * delta)


func _apply_boss_aura(delta: float) -> void:
	if target == null or not is_instance_valid(target):
		return
	if boss_requires_reveal_lock:
		target.add_noise_delta(0.8 * delta)
	if boss_exam_type == "noise_control" and _is_boss_noise_exam_failed():
		target.add_noise_delta(0.32 * delta)


func _emit_boss_attack_telegraph(distance_to_target: float) -> void:
	if target == null or not is_instance_valid(target):
		return
	var distance := minf(maxf(36.0, distance_to_target), ranged_range)
	var line_color := "#6ee7ff"
	if boss_exam_type == "noise_control" and _is_boss_noise_exam_failed():
		line_color = "#ff9c6e"
	elif boss_exam_type == "mobility":
		line_color = "#ffd27a"
	boss_telegraph_requested.emit("line", {
		"origin": global_position,
		"target": target.global_position,
		"length": distance,
		"duration": boss_attack_windup_duration + 0.08,
		"line_width": 14.0,
		"color": line_color
	})


func _get_boss_exam_damage_taken_multiplier() -> float:
	if behavior != "boss":
		return 1.0
	if boss_exam_type == "noise_control" and _is_boss_noise_exam_failed():
		return boss_noise_fail_damage_taken_mult
	if boss_exam_type == "summon_break" and boss_summon_break_active and boss_summon_break_remaining > 0:
		return boss_summon_break_shield_mult
	return 1.0


func _get_boss_exam_attack_damage_multiplier() -> float:
	if behavior != "boss":
		return 1.0
	if boss_exam_type == "noise_control" and _is_boss_noise_exam_failed():
		return boss_noise_fail_attack_damage_mult
	return 1.0


func _get_boss_exam_attack_cooldown_multiplier() -> float:
	if behavior != "boss":
		return 1.0
	if boss_exam_type == "noise_control" and _is_boss_noise_exam_failed():
		return boss_noise_fail_attack_cooldown_mult
	return 1.0


func _is_boss_noise_exam_failed() -> bool:
	if target == null or not is_instance_valid(target):
		return false
	if not ("noise" in target):
		return false
	return float(target.get("noise")) > boss_noise_fail_threshold


func _resolve_boss_mobility_exam_damage_multiplier() -> float:
	if boss_exam_type != "mobility":
		boss_attack_target_anchor_valid = false
		return 1.0
	if target == null or not is_instance_valid(target) or not boss_attack_target_anchor_valid:
		boss_attack_target_anchor_valid = false
		return 1.0
	var moved_distance := target.global_position.distance_to(boss_attack_target_anchor)
	boss_attack_target_anchor_valid = false
	if moved_distance + 0.01 >= boss_mobility_dodge_distance:
		return boss_mobility_success_damage_mult
	boss_telegraph_requested.emit("ring", {
		"origin": target.global_position,
		"radius": maxf(54.0, body_radius * 1.7),
		"duration": 0.28,
		"line_width": 5.2,
		"color": "#ff9a7f"
	})
	return boss_mobility_fail_damage_mult


func _spawn_boss_echo_decoys(count: int) -> void:
	_clear_boss_decoys()
	if count <= 0:
		return
	var parent_node := get_parent()
	if parent_node == null:
		return
	var palette := outline_visual.color if outline_visual != null else Color(0.84, 0.96, 1.0, 0.8)
	var clamped_count := clampi(count, 1, 6)
	for i in range(clamped_count):
		var decoy_variant := BossEchoDecoyScene.instantiate()
		if not (decoy_variant is Node):
			continue
		var decoy := decoy_variant as Node
		parent_node.add_child(decoy)
		var angle := (TAU / float(clamped_count)) * float(i) + (0.22 if i % 2 == 0 else -0.11)
		var ring_radius := maxf(42.0, body_radius * (2.8 + 0.24 * float(i % 3)))
		var pos := global_position + Vector2.RIGHT.rotated(angle) * ring_radius
		if decoy.has_method("configure"):
			decoy.configure(pos, palette, body_radius * 0.92, 9.0)
		boss_decoys.append(decoy)


func _dissipate_boss_decoys() -> void:
	for decoy in boss_decoys:
		if decoy == null or not is_instance_valid(decoy):
			continue
		if decoy.has_method("force_dissipate"):
			decoy.force_dissipate()
	boss_decoys.clear()


func _clear_boss_decoys() -> void:
	for decoy in boss_decoys:
		if decoy == null or not is_instance_valid(decoy):
			continue
		decoy.queue_free()
	boss_decoys.clear()


func get_boss_decoy_count() -> int:
	var count := 0
	var compact: Array[Node] = []
	for decoy in boss_decoys:
		if decoy == null or not is_instance_valid(decoy):
			continue
		compact.append(decoy)
		count += 1
	boss_decoys = compact
	return count


func is_boss_true_form_revealed() -> bool:
	return boss_true_form_exposed_announced


func on_pool_spawned() -> void:
	pooled_active = true
	collision_layer = default_collision_layer
	collision_mask = default_collision_mask
	visible = true
	set_physics_process(true)


func on_pool_recycle() -> void:
	pooled_active = false
	target = null
	velocity = Vector2.ZERO
	knockback_velocity = Vector2.ZERO
	contact_timer = 0.0
	reveal_until = 0.0
	stagger_timer = 0.0
	rage_timer = 0.0
	dash_cooldown_remaining = 0.0
	dash_windup_remaining = 0.0
	dash_active_remaining = 0.0
	ranged_cooldown_remaining = 0.0
	summon_timer = 0.0
	explode_timer = 0.0
	explode_primed = false
	is_elite = false
	elite_affix_id = ""
	damage_reduction = 0.0
	elite_noise_aura_add = 0.0
	elite_pursuer_bonus = 0.0
	elite_reveal_duration_mult = 1.0
	elite_jam_radius = 0.0
	elite_xp_siphon_rate = 0.0
	elite_siphon_radius = 0.0
	burn_dps = 0.0
	burn_remaining = 0.0
	burn_tick_timer = 0.0
	chill_slow_ratio = 0.0
	chill_remaining = 0.0
	shock_remaining = 0.0
	shock_tick_timer = 0.0
	shield_hp = 0.0
	shield_max_hp = 0.0
	boss_phase_id = ""
	boss_phase_label = ""
	boss_requires_reveal_lock = false
	boss_fake_echoes = 0
	boss_pending_attack = false
	boss_attack_windup_remaining = 0.0
	boss_attack_windup_duration = 0.42
	boss_echo_count_runtime = 0
	boss_true_form_exposed_announced = false
	boss_exam_type = ""
	boss_exam_objective = ""
	boss_noise_fail_threshold = 50.0
	boss_noise_fail_damage_taken_mult = 0.65
	boss_noise_fail_attack_damage_mult = 1.22
	boss_noise_fail_attack_cooldown_mult = 0.82
	boss_mobility_dodge_distance = 84.0
	boss_mobility_fail_damage_mult = 1.55
	boss_mobility_success_damage_mult = 0.72
	boss_attack_target_anchor = Vector2.ZERO
	boss_attack_target_anchor_valid = false
	boss_summon_break_active = false
	boss_summon_break_remaining = 0
	boss_summon_break_total_required = 0
	boss_summon_break_shield_mult = 0.18
	_hit_outline_timer = 0.0
	_body_base_scale = Vector2.ONE
	_outline_base_scale = Vector2.ONE
	_outline_base_color = Color(0.72, 0.96, 1.0, 1.0)
	_palette_seed_color = Color(0.22, 0.9, 1.0, 1.0)
	_enemy_aura_phase = 0.0
	_clear_boss_decoys()
	remove_from_group("enemy")
	remove_from_group("pursuer")
	remove_from_group("elite")
	remove_from_group("boss")
	collision_layer = 0
	collision_mask = 0
	z_index = CombatPaletteClass.LAYER_ENEMY
	visible = false
	set_physics_process(false)
	if _enemy_aura_visual != null:
		_enemy_aura_visual.visible = false
		_enemy_aura_visual.modulate = Color(1.0, 1.0, 1.0, 1.0)
	if sticker_visual != null:
		sticker_visual.texture = null
		sticker_visual.visible = false
		sticker_visual.modulate = Color(1.0, 1.0, 1.0, 1.0)
		sticker_visual.position = _sticker_base_position
	body_visual.visible = true
	_sticker_frames.clear()
	_sticker_idle_timer = 0.0
	_sticker_frame_idx = 0
	_sticker_idle_offset_y = 0.0
	_update_reveal_visual()


func _apply_enemy_sticker() -> void:
	if sticker_visual == null:
		return
	_sticker_frames = PixelStickerRegistry.get_enemy_idle_frames(enemy_id)
	var texture := _sticker_frames[0] if not _sticker_frames.is_empty() else null
	if texture == null:
		sticker_visual.visible = false
		body_visual.visible = true
		_sticker_frames.clear()
		return
	_sticker_idle_timer = 0.0
	_sticker_frame_idx = 0
	_sticker_idle_offset_y = 0.0
	sticker_visual.position = _sticker_base_position
	sticker_visual.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sticker_visual.texture = texture
	sticker_visual.visible = true
	var max_dim := maxf(texture.get_size().x, texture.get_size().y)
	var desired_world_size := maxf(14.0, body_radius * 2.1)
	sticker_visual.scale = Vector2.ONE * (desired_world_size / maxf(1.0, max_dim))
	body_visual.visible = false


func _tick_idle_sticker(delta: float) -> void:
	if sticker_visual == null or not sticker_visual.visible or _sticker_frames.size() <= 1:
		return
	_sticker_idle_timer += delta
	while _sticker_idle_timer >= ENEMY_IDLE_FRAME_SEC:
		_sticker_idle_timer -= ENEMY_IDLE_FRAME_SEC
		_sticker_frame_idx = (_sticker_frame_idx + 1) % _sticker_frames.size()
		sticker_visual.texture = _sticker_frames[_sticker_frame_idx]
	_sticker_idle_offset_y = _idle_bob_offset(_sticker_frame_idx, _sticker_frames.size(), ENEMY_BOB_AMPLITUDE)
	sticker_visual.position = _sticker_base_position + Vector2(0.0, _sticker_idle_offset_y)


func _idle_bob_offset(frame_idx: int, frame_count: int, amplitude: float) -> float:
	if frame_count <= 1 or amplitude <= 0.0:
		return 0.0
	var progress := float(frame_idx) / float(maxi(1, frame_count))
	var triangle := maxf(0.0, 1.0 - absf(progress * 2.0 - 1.0))
	return _snap_visual_offset(-amplitude * triangle)


func _snap_visual_offset(value: float) -> float:
	if VISUAL_OFFSET_SNAP <= 0.0:
		return value
	return round(value / VISUAL_OFFSET_SNAP) * VISUAL_OFFSET_SNAP


func _ensure_enemy_aura_visual() -> void:
	if _enemy_aura_visual != null:
		return
	_enemy_aura_visual = Polygon2D.new()
	_enemy_aura_visual.name = "Aura"
	_enemy_aura_visual.polygon = body_visual.polygon
	_enemy_aura_visual.visible = false
	_enemy_aura_visual.color = Color(0.78, 0.98, 1.0, 0.32)
	_enemy_aura_visual.z_index = CombatPaletteClass.LAYER_ENEMY_AURA - CombatPaletteClass.LAYER_ENEMY
	var aura_material := CanvasItemMaterial.new()
	aura_material.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	_enemy_aura_visual.material = aura_material
	add_child(_enemy_aura_visual)
	move_child(_enemy_aura_visual, 0)


func _refresh_enemy_palette() -> void:
	var palette_variant: Variant = CombatPaletteClass.enemy_palette(_palette_seed_color, spawn_group, is_elite)
	var palette: Dictionary = palette_variant if palette_variant is Dictionary else {}
	var body_variant: Variant = palette.get("body", _palette_seed_color)
	var outline_variant: Variant = palette.get("outline", _palette_seed_color.lightened(0.32))
	var aura_variant: Variant = palette.get("aura", _palette_seed_color.lightened(0.18))
	var body_color: Color = body_variant if body_variant is Color else _palette_seed_color
	var outline_color: Color = outline_variant if outline_variant is Color else _palette_seed_color.lightened(0.32)
	var aura_color: Color = aura_variant if aura_variant is Color else _palette_seed_color.lightened(0.18)
	body_visual.color = body_color
	_set_outline_base_color(outline_color)
	_ensure_enemy_aura_visual()
	if _enemy_aura_visual != null:
		_enemy_aura_visual.color = aura_color
		_enemy_aura_visual.scale = _body_base_scale * ENEMY_AURA_BASE_SCALE


func _tick_enemy_aura_visual(delta: float) -> void:
	if _enemy_aura_visual == null:
		return
	if not pooled_active:
		_enemy_aura_visual.visible = false
		return
	_enemy_aura_phase += delta * (2.3 + (0.5 if is_elite else 0.0))
	var wave := 0.5 + 0.5 * sin(_enemy_aura_phase * TAU)
	var hit_boost := clampf(_hit_outline_timer / maxf(0.001, HIT_OUTLINE_PULSE_SEC), 0.0, 1.0)
	var base_alpha := ENEMY_AURA_BASE_ALPHA + (ENEMY_AURA_ELITE_ALPHA_BONUS if is_elite else 0.0)
	if spawn_group == "pursuer":
		base_alpha += ENEMY_AURA_PURSUER_ALPHA_BONUS
	var alpha := clampf(base_alpha * lerpf(0.82, 1.16, wave) + hit_boost * 0.18, 0.06, 0.72)
	var aura_color := _enemy_aura_visual.color
	aura_color.a = alpha
	_enemy_aura_visual.color = aura_color
	_enemy_aura_visual.scale = _body_base_scale * (ENEMY_AURA_BASE_SCALE + ENEMY_AURA_PULSE_AMPLITUDE * wave + hit_boost * 0.12)


func _set_outline_base_color(color_value: Color) -> void:
	_outline_base_color = color_value
	if outline_visual == null:
		return
	if _hit_outline_timer <= 0.0:
		outline_visual.color = _outline_base_color


func _set_enemy_visual_modulate(modulate_color: Color) -> void:
	if sticker_visual != null and sticker_visual.visible:
		sticker_visual.modulate = modulate_color
	else:
		body_visual.modulate = modulate_color


func _request_recycle() -> void:
	if not pooled_active:
		return
	pooled_active = false
	set_physics_process(false)
	call_deferred("_dispatch_recycle_request")


func _dispatch_recycle_request() -> void:
	if recycle_handler.is_valid():
		recycle_handler.call(self)
		return
	queue_free()
