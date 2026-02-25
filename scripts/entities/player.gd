extends CharacterBody2D
class_name Player

signal died
signal stats_changed(stats: Dictionary)
signal level_up_requested(options: Array)
signal attack_mode_changed(is_auto: bool)

const BASE_MOVE_SPEED = 240.0
const BASE_DASH_SPEED = 820.0
const DASH_DURATION = 0.14
const BASE_DASH_COOLDOWN = 2.2
const BASE_MAX_HP = 100.0
const BASE_XP_TO_NEXT = 20.0
const BASE_ACTIVE_WEAPON_ID = "needle_rifle"
const PLAYER_TEXTURE_PATH := "res://assets/textures/player/diver_ship.png"
const LOW_NOISE_THRESHOLD = 25.0
const DRONE_MAX_HP = 40.0
const DRONE_RESPAWN_SECONDS = 3.0
const DRONE_CONTACT_RADIUS = 28.0
const ENEMY_QUERY_MASK = 2
const MINE_QUERY_INTERVAL = 0.2
const DRONE_QUERY_INTERVAL = 0.2
const TARGET_QUERY_MAX_RESULTS = 32
const WeaponRuntimeClass = preload("res://scripts/weapons/weapon_runtime.gd")
const PixelStickerRegistry := preload("res://scripts/visual/pixel_sticker_registry.gd")
const PLAYER_WORLD_HEIGHT_PX := 30.0
const WEAPON_WORLD_SIZE_PX := 24.0
const CHARACTER_IDLE_FRAME_SEC := 0.34
const WEAPON_IDLE_FRAME_SEC := 0.18

@onready var body_polygon: Polygon2D = $Body
@onready var sprite_node: Sprite2D = $Sprite
@onready var weapon_sticker_node: Sprite2D = $WeaponSticker

var enemy_manager: Node
var projectile_manager: Node
var rng = RandomNumberGenerator.new()

var max_hp = 100.0
var hp = 100.0
var xp = 0.0
var xp_to_next = 20.0
var level = 1
var noise = 0.0
var noise_min = 0.0
var noise_max = 100.0
var noise_decay_per_second = 4.5
var noise_sources: Dictionary = {
	"attack": 1.2,
	"attack_weapon_scale": 0.7,
	"dash": 6.0,
	"skill": 13.0
}

var damage_mult = 1.0
var attack_speed_mult = 1.0
var projectile_speed_mult = 1.0
var projectile_count_bonus = 0
var pierce_bonus = 0
var move_speed_bonus = 0.0
var dash_cooldown_reduction = 0.0
var regen_per_second = 0.0
var xp_gain_mult = 1.0
var noise_generation_mult = 1.0
var sonar_silence_synergy_bonus = 0.0

var upgrade_stacks: Dictionary = {}
var acquired_tags: Dictionary = {}
var pending_level_ups = 0
var level_up_open = false

var dash_cd_remaining = 0.0
var dash_time_remaining = 0.0
var dash_direction = Vector2.RIGHT
var last_move_direction = Vector2.RIGHT
var attack_cd_remaining = 0.0
var invuln_remaining = 0.0
var auto_attack = true
var active_weapon_id = BASE_ACTIVE_WEAPON_ID
var skill_cd_remaining = 0.0
var skill_cooldown = 8.0
var sonar_feedback_timer = 0.0
var sonar_feedback_duration = 0.9
var sonar_ping_count = 0
var sonar_ping_sequence = 0
var character_id: String = "diver"
var character_name: String = "Silent Diver"
var character_short_desc: String = ""
var character_effect_id: String = ""
var character_tag_weights: Dictionary = {}
var character_move_speed_multiplier: float = 1.0
var character_dash_cooldown_multiplier: float = 1.0
var character_sonar_reveal_duration_multiplier: float = 1.0
var character_pickup_radius_multiplier: float = 1.0
var character_projectile_range_multiplier: float = 1.0
var character_chain_bonus: float = 0.0
var character_crit_chance_bonus: float = 0.0
var character_summon_cap_bonus: int = 0

var bonus_sonar_reveal_duration_multiplier: float = 0.0
var bonus_pickup_radius_multiplier: float = 0.0
var bonus_revealed_damage_multiplier: float = 0.0
var bonus_low_noise_damage_multiplier: float = 0.0
var bonus_noise_decay_per_second: float = 0.0
var dash_noise_multiplier: float = 1.0
var bonus_summon_resistance: float = 0.0
var bonus_chain_chance: float = 0.0
var environment_noise_gain_multiplier: float = 1.0
var environment_noise_decay_multiplier: float = 1.0
var environment_sonar_reveal_multiplier: float = 1.0
var environment_xp_gain_multiplier: float = 1.0
var run_reward_multipliers: Dictionary = {
	"xp": 1.0,
	"rarity": 1.0,
	"drop": 1.0,
	"meta_currency": 1.0
}
var contract_max_hp_multiplier: float = 1.0
var contract_dash_disabled: bool = false
var contract_low_noise_damage_multiplier: float = 1.0
var contract_high_noise_damage_multiplier: float = 1.0

var weapon_levels: Dictionary = {}
var weapon_modifiers_by_id: Dictionary = {}
var weapon_modifiers_by_tag: Dictionary = {}

var deployed_mines: Array = []
var drone_nodes: Array[Node2D] = []
var drone_angles: Array[float] = []
var drone_hitpoints: Array[float] = []
var drone_contact_cooldowns: Array[float] = []
var drone_respawn_timers: Array[float] = []
var drone_target_query_cooldowns: Array[float] = []
var beam_target: Node2D = null
var beam_visual_timer: float = 0.0
var beam_visual: Line2D
var cached_runtime = null
var enemy_query_shape: CircleShape2D = CircleShape2D.new()
var enemy_query_params: PhysicsShapeQueryParameters2D = PhysicsShapeQueryParameters2D.new()
var target_query_total: int = 0
var target_query_window_count: int = 0
var target_query_window_seconds: float = 0.0
var target_query_count_per_sec: float = 0.0
var displayed_weapon_sticker_id: String = ""
var _character_sticker_frames: Array[Texture2D] = []
var _weapon_sticker_frames: Array[Texture2D] = []
var _character_idle_timer: float = 0.0
var _weapon_idle_timer: float = 0.0
var _character_frame_idx: int = 0
var _weapon_frame_idx: int = 0
var _sprite_base_position: Vector2 = Vector2.ZERO
var _weapon_base_offset_y: float = -8.0
var _weapon_idle_offset_y: float = 0.0


func _ready() -> void:
	add_to_group("player")
	if sprite_node != null:
		_sprite_base_position = sprite_node.position
	_apply_optional_player_texture()
	_apply_weapon_sticker()
	enemy_query_params.shape = enemy_query_shape
	enemy_query_params.collide_with_bodies = true
	enemy_query_params.collide_with_areas = true
	enemy_query_params.collision_mask = ENEMY_QUERY_MASK
	beam_visual = Line2D.new()
	beam_visual.width = 3.0
	beam_visual.default_color = Color(0.62, 0.95, 1.0, 0.92)
	beam_visual.visible = false
	beam_visual.z_index = 12
	add_child(beam_visual)
	emit_stats_changed()


func _apply_optional_player_texture() -> void:
	if sprite_node == null or body_polygon == null:
		return
	sprite_node.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_character_sticker_frames = PixelStickerRegistry.get_character_idle_frames(character_id)
	var sticker := _character_sticker_frames[0] if not _character_sticker_frames.is_empty() else null
	if sticker != null:
		_character_idle_timer = 0.0
		_character_frame_idx = 0
		sprite_node.texture = sticker
		sprite_node.visible = true
		var max_dim := maxf(sticker.get_size().x, sticker.get_size().y)
		var sprite_scale := PLAYER_WORLD_HEIGHT_PX / maxf(1.0, max_dim)
		sprite_node.scale = Vector2.ONE * sprite_scale
		sprite_node.position = _sprite_base_position
		body_polygon.visible = false
		return
	if ResourceLoader.exists(PLAYER_TEXTURE_PATH, "Texture2D"):
		_character_sticker_frames.clear()
		var texture_variant := load(PLAYER_TEXTURE_PATH)
		if texture_variant is Texture2D:
			sprite_node.texture = texture_variant
			sprite_node.visible = true
			body_polygon.visible = false
			return
	sprite_node.visible = false
	_character_sticker_frames.clear()
	body_polygon.visible = true


func _apply_weapon_sticker() -> void:
	if weapon_sticker_node == null:
		return
	if active_weapon_id.is_empty():
		weapon_sticker_node.visible = false
		displayed_weapon_sticker_id = ""
		_weapon_sticker_frames.clear()
		return
	if displayed_weapon_sticker_id == active_weapon_id and weapon_sticker_node.texture != null:
		return
	_weapon_sticker_frames = PixelStickerRegistry.get_weapon_idle_frames(active_weapon_id)
	var texture := _weapon_sticker_frames[0] if not _weapon_sticker_frames.is_empty() else null
	if texture == null:
		weapon_sticker_node.visible = false
		displayed_weapon_sticker_id = ""
		_weapon_sticker_frames.clear()
		return
	displayed_weapon_sticker_id = active_weapon_id
	_weapon_idle_timer = 0.0
	_weapon_frame_idx = 0
	_weapon_idle_offset_y = 0.0
	weapon_sticker_node.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	weapon_sticker_node.texture = texture
	weapon_sticker_node.visible = true
	var max_dim := maxf(texture.get_size().x, texture.get_size().y)
	var weapon_scale := WEAPON_WORLD_SIZE_PX / maxf(1.0, max_dim)
	weapon_sticker_node.scale = Vector2.ONE * weapon_scale
	_update_weapon_sticker_transform()


func _update_weapon_sticker_transform() -> void:
	if weapon_sticker_node == null or not weapon_sticker_node.visible:
		return
	var facing: Vector2 = last_move_direction
	if facing.length() < 0.01:
		facing = Vector2.RIGHT
	var sign_x := 1.0 if facing.x >= 0.0 else -1.0
	weapon_sticker_node.position = Vector2(10.0 * sign_x, _weapon_base_offset_y + _weapon_idle_offset_y)
	weapon_sticker_node.flip_h = sign_x < 0.0


func setup(enemy_manager_ref: Node, projectile_manager_ref: Node, run_rng: RandomNumberGenerator, character_def: Dictionary = {}) -> void:
	enemy_manager = enemy_manager_ref
	projectile_manager = projectile_manager_ref
	if run_rng != null:
		rng = run_rng
	_reset_run_stats()
	apply_noise_config(DataRegistry.get_noise_config())
	apply_character(character_def)
	_ensure_weapon_state()
	emit_stats_changed()


func _reset_run_stats() -> void:
	max_hp = BASE_MAX_HP
	hp = BASE_MAX_HP
	xp = 0.0
	xp_to_next = BASE_XP_TO_NEXT
	level = 1
	noise = 0.0
	damage_mult = 1.0
	attack_speed_mult = 1.0
	projectile_speed_mult = 1.0
	projectile_count_bonus = 0
	pierce_bonus = 0
	move_speed_bonus = 0.0
	dash_cooldown_reduction = 0.0
	regen_per_second = 0.0
	xp_gain_mult = 1.0
	noise_generation_mult = 1.0
	sonar_silence_synergy_bonus = 0.0
	upgrade_stacks.clear()
	acquired_tags.clear()
	pending_level_ups = 0
	level_up_open = false
	dash_cd_remaining = 0.0
	dash_time_remaining = 0.0
	dash_direction = Vector2.RIGHT
	last_move_direction = Vector2.RIGHT
	attack_cd_remaining = 0.0
	invuln_remaining = 0.0
	auto_attack = true
	active_weapon_id = BASE_ACTIVE_WEAPON_ID
	skill_cd_remaining = 0.0
	skill_cooldown = 8.0
	sonar_feedback_timer = 0.0
	sonar_ping_count = 0
	sonar_ping_sequence = 0
	character_move_speed_multiplier = 1.0
	character_dash_cooldown_multiplier = 1.0
	character_sonar_reveal_duration_multiplier = 1.0
	character_pickup_radius_multiplier = 1.0
	character_projectile_range_multiplier = 1.0
	character_chain_bonus = 0.0
	character_crit_chance_bonus = 0.0
	character_summon_cap_bonus = 0
	character_effect_id = ""
	character_tag_weights.clear()
	bonus_sonar_reveal_duration_multiplier = 0.0
	bonus_pickup_radius_multiplier = 0.0
	bonus_revealed_damage_multiplier = 0.0
	bonus_low_noise_damage_multiplier = 0.0
	bonus_noise_decay_per_second = 0.0
	dash_noise_multiplier = 1.0
	bonus_summon_resistance = 0.0
	bonus_chain_chance = 0.0
	environment_noise_gain_multiplier = 1.0
	environment_noise_decay_multiplier = 1.0
	environment_sonar_reveal_multiplier = 1.0
	environment_xp_gain_multiplier = 1.0
	run_reward_multipliers = {
		"xp": 1.0,
		"rarity": 1.0,
		"drop": 1.0,
		"meta_currency": 1.0
	}
	contract_max_hp_multiplier = 1.0
	contract_dash_disabled = false
	contract_low_noise_damage_multiplier = 1.0
	contract_high_noise_damage_multiplier = 1.0
	weapon_levels.clear()
	weapon_modifiers_by_id.clear()
	weapon_modifiers_by_tag.clear()
	deployed_mines.clear()
	_clear_drone_visuals()
	beam_target = null
	beam_visual_timer = 0.0
	target_query_total = 0
	target_query_window_count = 0
	target_query_window_seconds = 0.0
	target_query_count_per_sec = 0.0
	if beam_visual != null:
		beam_visual.visible = false
	cached_runtime = null


func apply_character(character_def: Dictionary) -> void:
	var effective_def: Dictionary = character_def.duplicate(true)
	if effective_def.is_empty():
		effective_def = DataRegistry.get_character(DataRegistry.get_default_character_id())
	if effective_def.is_empty():
		effective_def = {
			"id": "diver",
			"display_name": "Silent Diver",
			"short_desc": "",
			"starting_weapon_id": BASE_ACTIVE_WEAPON_ID,
			"stat_modifiers": {},
			"tag_weights": {},
			"effect_id": ""
		}
	character_id = String(effective_def.get("id", "diver"))
	character_name = String(effective_def.get("display_name", "Silent Diver"))
	character_short_desc = String(effective_def.get("short_desc", ""))
	character_effect_id = String(effective_def.get("effect_id", ""))

	var tag_weights_variant: Variant = effective_def.get("tag_weights", {})
	character_tag_weights = (tag_weights_variant as Dictionary).duplicate(true) if tag_weights_variant is Dictionary else {}

	var modifiers_variant: Variant = effective_def.get("stat_modifiers", {})
	var modifiers: Dictionary = modifiers_variant if modifiers_variant is Dictionary else {}
	var hp_mult = float(modifiers.get("max_hp_multiplier", 1.0))
	var hp_bonus = float(modifiers.get("max_hp_bonus", 0.0))
	max_hp = maxf(1.0, BASE_MAX_HP * hp_mult + hp_bonus)
	hp = max_hp

	character_move_speed_multiplier = maxf(0.2, float(modifiers.get("move_speed_multiplier", 1.0)))
	move_speed_bonus += float(modifiers.get("move_speed_bonus", 0.0))
	character_dash_cooldown_multiplier = maxf(0.2, float(modifiers.get("dash_cooldown_multiplier", 1.0)))
	noise_generation_mult = maxf(0.2, float(modifiers.get("noise_gain_multiplier", 1.0)))
	character_sonar_reveal_duration_multiplier = maxf(0.2, float(modifiers.get("sonar_reveal_duration_multiplier", 1.0)))
	character_pickup_radius_multiplier = maxf(0.2, float(modifiers.get("pickup_radius_multiplier", 1.0)))
	damage_mult = maxf(0.1, float(modifiers.get("damage_multiplier", 1.0)))
	attack_speed_mult = maxf(0.1, float(modifiers.get("attack_speed_multiplier", 1.0)))
	character_projectile_range_multiplier = maxf(0.2, float(modifiers.get("projectile_range_multiplier", 1.0)))
	pierce_bonus += int(modifiers.get("pierce_bonus", 0))
	xp_gain_mult = maxf(0.1, float(modifiers.get("xp_gain_multiplier", 1.0)))
	character_crit_chance_bonus = float(modifiers.get("crit_chance_bonus", 0.0))
	character_chain_bonus = float(modifiers.get("chain_bonus", 0.0))
	character_summon_cap_bonus = int(modifiers.get("summon_cap_bonus", 0))

	var starting_weapon_id = String(effective_def.get("starting_weapon_id", BASE_ACTIVE_WEAPON_ID))
	if not DataRegistry.get_weapon_runtime(starting_weapon_id).is_empty():
		active_weapon_id = starting_weapon_id
	else:
		active_weapon_id = BASE_ACTIVE_WEAPON_ID
	_apply_optional_player_texture()
	_apply_weapon_sticker()


func get_pickup_radius_multiplier() -> float:
	return maxf(0.2, character_pickup_radius_multiplier * (1.0 + bonus_pickup_radius_multiplier))


func get_sonar_reveal_duration_multiplier() -> float:
	return maxf(
		0.2,
		character_sonar_reveal_duration_multiplier
		* (1.0 + bonus_sonar_reveal_duration_multiplier)
		* environment_sonar_reveal_multiplier
	)


func get_character_tag_weights() -> Dictionary:
	return character_tag_weights.duplicate(true)


func _physics_process(delta: float) -> void:
	_tick_idle_stickers(delta)
	target_query_window_seconds += delta
	if target_query_window_seconds >= 1.0:
		target_query_count_per_sec = float(target_query_window_count) / maxf(0.001, target_query_window_seconds)
		target_query_window_count = 0
		target_query_window_seconds = 0.0

	invuln_remaining = max(0.0, invuln_remaining - delta)
	dash_cd_remaining = max(0.0, dash_cd_remaining - delta)
	attack_cd_remaining = max(0.0, attack_cd_remaining - delta)
	dash_time_remaining = max(0.0, dash_time_remaining - delta)
	skill_cd_remaining = max(0.0, skill_cd_remaining - delta)
	sonar_feedback_timer = max(0.0, sonar_feedback_timer - delta)
	beam_visual_timer = max(0.0, beam_visual_timer - delta)

	if regen_per_second > 0.0 and hp > 0.0:
		hp = min(max_hp, hp + regen_per_second * delta)

	if Input.is_action_just_pressed("toggle_attack_mode"):
		auto_attack = not auto_attack
		attack_mode_changed.emit(auto_attack)

	var input_direction = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if input_direction.length() > 0.01:
		last_move_direction = input_direction.normalized()
	_update_weapon_sticker_transform()

	if not contract_dash_disabled and Input.is_action_just_pressed("dash") and dash_cd_remaining <= 0.0:
		dash_direction = last_move_direction if last_move_direction.length() > 0.01 else Vector2.RIGHT
		dash_time_remaining = DASH_DURATION
		dash_cd_remaining = _current_dash_cooldown()
		_add_noise_source("dash")

	if Input.is_action_just_pressed("sonar_skill") and skill_cd_remaining <= 0.0:
		_trigger_flare_skill()

	if dash_time_remaining > 0.0:
		velocity = dash_direction * BASE_DASH_SPEED
	else:
		velocity = input_direction * ((BASE_MOVE_SPEED * character_move_speed_multiplier) + move_speed_bonus)
	move_and_slide()

	if attack_cd_remaining <= 0.0:
		_attempt_fire()

	var noise_decay = (noise_decay_per_second + bonus_noise_decay_per_second) * environment_noise_decay_multiplier
	noise = clampf(noise - maxf(0.0, noise_decay) * delta, noise_min, noise_max)
	_update_deployed_mines(delta)
	_update_drone_orbits(delta)
	_update_beam_visual()
	if not deployed_mines.is_empty():
		queue_redraw()


func _tick_idle_stickers(delta: float) -> void:
	if sprite_node != null and _character_sticker_frames.size() > 1:
		_character_idle_timer += delta
		if _character_idle_timer >= CHARACTER_IDLE_FRAME_SEC:
			_character_idle_timer = 0.0
			_character_frame_idx = (_character_frame_idx + 1) % _character_sticker_frames.size()
			sprite_node.texture = _character_sticker_frames[_character_frame_idx]
			sprite_node.position = _sprite_base_position + Vector2(0.0, -0.8 if _character_frame_idx == 1 else 0.0)
	elif sprite_node != null:
		sprite_node.position = _sprite_base_position

	if weapon_sticker_node != null and weapon_sticker_node.visible and _weapon_sticker_frames.size() > 1:
		_weapon_idle_timer += delta
		if _weapon_idle_timer >= WEAPON_IDLE_FRAME_SEC:
			_weapon_idle_timer = 0.0
			_weapon_frame_idx = (_weapon_frame_idx + 1) % _weapon_sticker_frames.size()
			weapon_sticker_node.texture = _weapon_sticker_frames[_weapon_frame_idx]
			_weapon_idle_offset_y = -0.5 if _weapon_frame_idx == 1 else 0.0


func _trigger_flare_skill() -> void:
	skill_cd_remaining = skill_cooldown
	_add_noise_source("skill")
	var sonar_cfg := DataRegistry.get_sonar_config()
	var base_radius := maxf(120.0, float(sonar_cfg.get("max_radius", 720.0)))
	var ping_radius := base_radius * 1.26
	sonar_ping_count = _estimate_enemy_count_in_radius(global_position, ping_radius)
	sonar_ping_sequence += 1
	sonar_feedback_timer = sonar_feedback_duration
	FeedbackBus.emit_sonar_pulse(global_position, {
		"source": "flare",
		"strength": 1.26,
		"radius_scale": 1.28,
		"speed": 980.0,
		"line_width": 8.4,
		"ping_count": sonar_ping_count,
		"reveal_duration_multiplier": get_sonar_reveal_duration_multiplier()
	})


func _estimate_enemy_count_in_radius(center: Vector2, radius: float) -> int:
	return _query_enemy_nodes(center, radius, 96, true).size()


func _attempt_fire() -> void:
	if projectile_manager == null:
		return
	_ensure_weapon_state()
	var runtime = _build_active_weapon_runtime()
	if runtime == null:
		return
	cached_runtime = runtime

	var fire_direction = Vector2.ZERO
	var target = _resolve_target()
	if target != null and is_instance_valid(target):
		fire_direction = (target.global_position - global_position).normalized()
	elif not auto_attack:
		fire_direction = (get_global_mouse_position() - global_position).normalized()
	if fire_direction.length() < 0.01:
		fire_direction = last_move_direction if last_move_direction.length() > 0.01 else Vector2.RIGHT

	match runtime.attack_model:
		"projectile":
			if fire_direction.length() < 0.01:
				return
			_fire_projectile(runtime, fire_direction)
		"pulse":
			_fire_pulse(runtime)
		"mine":
			_deploy_mine(runtime, fire_direction, target)
		"beam":
			_fire_beam(runtime, target)
		"drone":
			_fire_drone(runtime)
		"melee":
			_fire_melee(runtime, fire_direction)
		_:
			_fire_projectile(runtime, fire_direction)

	FeedbackBus.emit_shot(global_position, 0.12)
	attack_cd_remaining = max(0.05, runtime.attack_interval)
	_add_noise_source("attack", runtime.noise_per_attack)


func _fire_projectile(runtime, fire_direction: Vector2) -> void:
	var count: int = maxi(1, runtime.projectile_count)
	var spread_step = deg_to_rad(8.0)
	var center = (float(count) - 1.0) * 0.5
	for i in range(count):
		var offset = (float(i) - center) * spread_step
		var dir = fire_direction.rotated(offset)
		var projectile_data = {
			"weapon_id": runtime.weapon_id,
			"damage": runtime.damage,
			"speed": runtime.projectile_speed,
			"range": runtime.range,
			"pierce": runtime.pierce,
			"radius": 6.0,
			"tags": runtime.tags,
			"crit_chance": runtime.crit_chance,
			"crit_multiplier": runtime.crit_multiplier,
			"reveal_bonus_duration": runtime.reveal_bonus_duration * get_sonar_reveal_duration_multiplier()
		}
		projectile_manager.spawn_projectile(global_position, dir, projectile_data, self)


func _fire_pulse(runtime) -> void:
	var radius = runtime.aoe_radius if runtime.aoe_radius > 0.0 else runtime.range
	var hit_count = _damage_enemies_in_radius(global_position, radius, runtime, Vector2.ZERO)
	FeedbackBus.emit_sonar_pulse(global_position, {
		"source": "hit",
		"strength": clampf(runtime.sonar_pulse_strength + (0.05 * float(hit_count)), 0.2, 2.0),
		"radius_scale": 1.08,
		"reveal_duration_multiplier": get_sonar_reveal_duration_multiplier()
	})


func _deploy_mine(runtime, fire_direction: Vector2, target: Node2D) -> void:
	var place_distance = runtime.range
	if target != null and is_instance_valid(target):
		place_distance = minf(runtime.range, global_position.distance_to(target.global_position))
	var placement = global_position + fire_direction.normalized() * place_distance
	var activation_delay = float(DataRegistry.get_weapon_runtime(runtime.weapon_id).get("activation_delay", 0.65))
	deployed_mines.append({
		"position": placement,
		"timer": maxf(0.0, activation_delay),
		"ttl": 4.0,
		"scan_cd": 0.0,
		"radius": runtime.aoe_radius if runtime.aoe_radius > 0.0 else 128.0,
		"damage": runtime.damage,
		"crit_chance": runtime.crit_chance,
		"crit_multiplier": runtime.crit_multiplier,
		"reveal_bonus_duration": runtime.reveal_bonus_duration * get_sonar_reveal_duration_multiplier(),
		"tags": runtime.tags.duplicate(),
		"pulse_strength": runtime.sonar_pulse_strength
	})
	queue_redraw()


func _fire_beam(runtime, target: Node2D) -> void:
	var beam_target_local = target
	if beam_target_local == null or not is_instance_valid(beam_target_local):
		beam_target_local = _pick_target_in_range(runtime.range)
	if beam_target_local == null:
		return
	if beam_target_local.global_position.distance_to(global_position) > runtime.range:
		beam_target_local = _pick_target_in_range(runtime.range)
	if beam_target_local == null:
		return
	_apply_damage_to_enemy(beam_target_local, runtime.damage, runtime, Vector2.ZERO)
	beam_target = beam_target_local
	beam_visual_timer = maxf(beam_visual_timer, runtime.beam_tick_interval)


func _fire_drone(runtime) -> void:
	var drone_count = maxi(1, runtime.summon_count)
	_ensure_drone_nodes(drone_count)
	for i in range(drone_nodes.size()):
		var drone = drone_nodes[i]
		if i >= drone_count:
			drone.visible = false
			continue
		drone.visible = true
		var origin = drone.global_position
		var target = _pick_target_near(origin, runtime.range * 1.15)
		if target == null:
			continue
		var direction = (target.global_position - origin).normalized()
		if direction.length() < 0.01:
			continue
		var projectile_data = {
			"weapon_id": runtime.weapon_id,
			"damage": runtime.damage * 0.9,
			"speed": maxf(240.0, runtime.projectile_speed),
			"range": maxf(220.0, runtime.range),
			"pierce": runtime.pierce,
			"radius": 4.5,
			"tags": runtime.tags,
			"crit_chance": runtime.crit_chance,
			"crit_multiplier": runtime.crit_multiplier,
			"reveal_bonus_duration": runtime.reveal_bonus_duration * get_sonar_reveal_duration_multiplier()
		}
		projectile_manager.spawn_projectile(origin, direction, projectile_data, self)


func _fire_melee(runtime, fire_direction: Vector2) -> void:
	var forward = fire_direction.normalized()
	if forward.length() < 0.01:
		forward = last_move_direction if last_move_direction.length() > 0.01 else Vector2.RIGHT
	var radius = runtime.aoe_radius if runtime.aoe_radius > 0.0 else runtime.range
	var hit_count = 0
	for enemy in _query_enemy_nodes(global_position, radius, 28, false):
		if enemy == null or not is_instance_valid(enemy):
			continue
		if not enemy.has_method("take_hit"):
			continue
		var to_enemy = enemy.global_position - global_position
		if to_enemy.length() > radius:
			continue
		var enemy_dir = to_enemy.normalized()
		if forward.dot(enemy_dir) < 0.35:
			continue
		if _apply_damage_to_enemy(enemy, runtime.damage, runtime, enemy_dir * 160.0):
			hit_count += 1
	FeedbackBus.emit_sonar_pulse(global_position, {
		"source": "hit",
		"strength": clampf(runtime.sonar_pulse_strength + (0.08 * float(hit_count)), 0.3, 2.2),
		"radius_scale": 1.25,
		"reveal_duration_multiplier": get_sonar_reveal_duration_multiplier()
	})


func _resolve_target() -> Node2D:
	if auto_attack:
		if enemy_manager != null and enemy_manager.has_method("get_priority_target"):
			var target: Variant = enemy_manager.get_priority_target(global_position)
			if target is Node2D and is_instance_valid(target as Node2D):
				return target as Node2D
	else:
		var mouse_direction = get_global_mouse_position() - global_position
		if mouse_direction.length() > 0.01:
			return _pick_target_in_direction(mouse_direction.normalized())
	return null


func _query_enemy_nodes(
	center: Vector2,
	radius: float,
	max_results: int = TARGET_QUERY_MAX_RESULTS,
	allow_group_fallback: bool = false
) -> Array[Node2D]:
	var candidates: Array[Node2D] = []
	if radius <= 0.0:
		return candidates
	target_query_total += 1
	target_query_window_count += 1
	var world2d := get_world_2d()
	if world2d != null:
		enemy_query_shape.radius = radius
		enemy_query_params.transform = Transform2D(0.0, center)
		enemy_query_params.exclude = [get_rid()]
		var query_hits := world2d.direct_space_state.intersect_shape(enemy_query_params, maxi(1, max_results))
		var seen: Dictionary = {}
		for hit_variant in query_hits:
			if not (hit_variant is Dictionary):
				continue
			var hit: Dictionary = hit_variant
			var collider_variant: Variant = hit.get("collider", null)
			if not (collider_variant is Node2D):
				continue
			var node := collider_variant as Node2D
			if node == self or not node.is_in_group("enemy") or not is_instance_valid(node):
				continue
			var instance_id := int(node.get_instance_id())
			if seen.has(instance_id):
				continue
			seen[instance_id] = true
			candidates.append(node)
	if not candidates.is_empty() or not allow_group_fallback:
		return candidates
	for enemy in get_tree().get_nodes_in_group("enemy"):
		if enemy == null or not is_instance_valid(enemy):
			continue
		if not (enemy is Node2D):
			continue
		var enemy_node := enemy as Node2D
		if enemy_node.global_position.distance_to(center) > radius:
			continue
		candidates.append(enemy_node)
		if candidates.size() >= max_results:
			break
	return candidates


func _has_enemy_in_radius(center: Vector2, radius: float) -> bool:
	return _query_enemy_nodes(center, radius, 1, false).size() > 0


func _pick_target_in_direction(direction: Vector2) -> Node2D:
	var best_target: Node2D = null
	var best_score = -INF
	for enemy in get_tree().get_nodes_in_group("enemy"):
		if enemy == null or not is_instance_valid(enemy):
			continue
		if not (enemy is Node2D):
			continue
		var enemy_node = enemy as Node2D
		var to_enemy = enemy_node.global_position - global_position
		if to_enemy.length() < 0.01:
			continue
		var alignment = direction.dot(to_enemy.normalized())
		if alignment < 0.2:
			continue
		var score = alignment * 1.8 - (to_enemy.length() * 0.0015)
		if score > best_score:
			best_score = score
			best_target = enemy_node
	return best_target


func _pick_target_in_range(max_range: float) -> Node2D:
	var best_target: Node2D = null
	var best_distance = INF
	for enemy_node in _query_enemy_nodes(global_position, max_range, TARGET_QUERY_MAX_RESULTS, false):
		if enemy_node == null or not is_instance_valid(enemy_node):
			continue
		var distance = enemy_node.global_position.distance_to(global_position)
		if distance > max_range:
			continue
		if distance < best_distance:
			best_distance = distance
			best_target = enemy_node
	return best_target


func _pick_target_near(origin: Vector2, max_range: float) -> Node2D:
	var best_target: Node2D = null
	var best_distance = INF
	for enemy_node in _query_enemy_nodes(origin, max_range, TARGET_QUERY_MAX_RESULTS, false):
		if enemy_node == null or not is_instance_valid(enemy_node):
			continue
		var distance = enemy_node.global_position.distance_to(origin)
		if distance > max_range:
			continue
		if distance < best_distance:
			best_distance = distance
			best_target = enemy_node
	return best_target


func _damage_enemies_in_radius(center: Vector2, radius: float, runtime, impulse: Vector2 = Vector2.ZERO) -> int:
	var hit_count = 0
	for enemy_node in _query_enemy_nodes(center, radius, TARGET_QUERY_MAX_RESULTS, false):
		if enemy_node == null or not is_instance_valid(enemy_node):
			continue
		if enemy_node.global_position.distance_to(center) > radius:
			continue
		if _apply_damage_to_enemy(enemy_node, runtime.damage, runtime, impulse):
			hit_count += 1
	return hit_count


func _apply_damage_to_enemy(enemy: Node, base_damage: float, runtime, impulse: Vector2 = Vector2.ZERO, chain_hop: int = 0) -> bool:
	if enemy == null or not is_instance_valid(enemy):
		return false
	if not enemy.has_method("take_hit"):
		return false
	var payload = compute_hit_payload(enemy, base_damage, runtime.crit_chance, runtime.crit_multiplier)
	var final_damage = float(payload.get("damage", base_damage))
	var is_crit = bool(payload.get("crit", false))
	var killed = bool(enemy.take_hit(final_damage, impulse))
	if runtime.reveal_bonus_duration > 0.0 and enemy.has_method("set_revealed"):
		enemy.set_revealed(runtime.reveal_bonus_duration)
	var intensity = clampf((final_damage / 34.0) + (0.08 if killed else 0.0) + (0.05 if is_crit else 0.0), 0.08, 0.38)
	if enemy is Node2D:
		FeedbackBus.emit_hit((enemy as Node2D).global_position, intensity, killed)
	else:
		FeedbackBus.emit_hit(global_position, intensity, killed)

	var chain_parameters = _get_chain_parameters(runtime)
	if bool(chain_parameters.get("enabled", false)):
		var max_hops := int(chain_parameters.get("max_hops", 0))
		var chance := float(chain_parameters.get("chance", 0.0))
		if chain_hop < max_hops and rng.randf() <= chance:
			_try_chain_bounce(enemy, final_damage, runtime, chain_hop + 1, max_hops)
	return true


func _get_chain_parameters(runtime) -> Dictionary:
	var tags_variant: Variant = runtime.tags if runtime != null else []
	if not (tags_variant is Array):
		return {
			"enabled": false,
			"chance": 0.0,
			"max_hops": 0
		}
	var tags: Array = tags_variant
	if not tags.has("chain"):
		return {
			"enabled": false,
			"chance": 0.0,
			"max_hops": 0
		}
	var chance := clampf(character_chain_bonus + bonus_chain_chance, 0.0, 0.9)
	var max_hops := 1 + int(floor(chance * 4.0))
	max_hops = clampi(max_hops, 1, 4)
	return {
		"enabled": chance > 0.0,
		"chance": chance,
		"max_hops": max_hops
	}


func _try_chain_bounce(source_enemy: Node, base_damage: float, runtime, next_hop: int, max_hops: int) -> void:
	if next_hop > max_hops:
		return
	if not (source_enemy is Node2D):
		return
	var source_position := (source_enemy as Node2D).global_position
	var search_radius := clampf(float(runtime.range) * 0.45, 120.0, 260.0)
	var chain_target: Node2D = null
	var best_distance := INF
	for enemy_node in _query_enemy_nodes(source_position, search_radius, 16, false):
		if enemy_node == null or not is_instance_valid(enemy_node):
			continue
		if enemy_node == source_enemy:
			continue
		var distance := enemy_node.global_position.distance_to(source_position)
		if distance > search_radius:
			continue
		if distance < best_distance:
			best_distance = distance
			chain_target = enemy_node
	if chain_target == null:
		return
	_apply_damage_to_enemy(chain_target, base_damage * 0.55, runtime, Vector2.ZERO, next_hop)
	FeedbackBus.emit_sonar_pulse(source_position, {
		"source": "hit",
		"strength": 0.55,
		"radius_scale": 0.82,
		"reveal_duration_multiplier": get_sonar_reveal_duration_multiplier()
	})


func _update_deployed_mines(delta: float) -> void:
	if deployed_mines.is_empty():
		return
	var active: Array = []
	for mine_variant in deployed_mines:
		if not (mine_variant is Dictionary):
			continue
		var mine: Dictionary = mine_variant
		mine["timer"] = float(mine.get("timer", 0.0)) - delta
		mine["ttl"] = float(mine.get("ttl", 0.0)) - delta
		mine["scan_cd"] = maxf(0.0, float(mine.get("scan_cd", 0.0)) - delta)
		var should_explode = false
		if float(mine.get("timer", 0.0)) <= 0.0 and float(mine.get("scan_cd", 0.0)) <= 0.0:
			mine["scan_cd"] = MINE_QUERY_INTERVAL
			var mine_pos = Vector2(mine.get("position", global_position))
			var mine_radius = float(mine.get("radius", 120.0))
			should_explode = _has_enemy_in_radius(mine_pos, mine_radius)
		if float(mine.get("ttl", 0.0)) <= 0.0:
			should_explode = true
		if should_explode:
			var synthetic_runtime = WeaponRuntimeClass.new()
			synthetic_runtime.damage = float(mine.get("damage", 20.0))
			synthetic_runtime.crit_chance = float(mine.get("crit_chance", 0.0))
			synthetic_runtime.crit_multiplier = float(mine.get("crit_multiplier", 1.5))
			synthetic_runtime.reveal_bonus_duration = float(mine.get("reveal_bonus_duration", 0.0))
			synthetic_runtime.attack_model = "mine"
			synthetic_runtime.tags = mine.get("tags", [])
			_damage_enemies_in_radius(Vector2(mine.get("position", global_position)), float(mine.get("radius", 120.0)), synthetic_runtime)
			FeedbackBus.emit_sonar_pulse(Vector2(mine.get("position", global_position)), {
				"source": "hit",
				"strength": clampf(float(mine.get("pulse_strength", 1.0)), 0.2, 2.0),
				"radius_scale": 1.22,
				"reveal_duration_multiplier": get_sonar_reveal_duration_multiplier()
			})
		else:
			active.append(mine)
	deployed_mines = active


func _ensure_drone_nodes(count: int) -> void:
	while drone_nodes.size() < count:
		var drone = Node2D.new()
		drone.name = "DroneVisual_%d" % drone_nodes.size()
		drone.z_index = 11
		var body = Polygon2D.new()
		body.color = Color(0.66, 0.95, 1.0, 0.92)
		body.polygon = PackedVector2Array([-8.0, -6.0, 7.0, -4.0, 9.0, 0.0, 7.0, 4.0, -8.0, 6.0, -10.0, 0.0])
		drone.add_child(body)
		add_child(drone)
		drone_nodes.append(drone)
		drone_angles.append(randf() * TAU)
		drone_hitpoints.append(DRONE_MAX_HP)
		drone_contact_cooldowns.append(0.0)
		drone_respawn_timers.append(0.0)
		drone_target_query_cooldowns.append(0.0)


func _clear_drone_visuals() -> void:
	for drone in drone_nodes:
		if drone != null and is_instance_valid(drone):
			drone.queue_free()
	drone_nodes.clear()
	drone_angles.clear()
	drone_hitpoints.clear()
	drone_contact_cooldowns.clear()
	drone_respawn_timers.clear()
	drone_target_query_cooldowns.clear()


func _update_drone_orbits(delta: float) -> void:
	if drone_nodes.is_empty():
		return
	var runtime = cached_runtime
	if runtime == null:
		runtime = _build_active_weapon_runtime()
	if runtime == null or runtime.attack_model != "drone":
		for i in range(drone_nodes.size()):
			var drone = drone_nodes[i]
			if drone != null and is_instance_valid(drone):
				drone.visible = false
			if i < drone_target_query_cooldowns.size():
				drone_target_query_cooldowns[i] = 0.0
		return
	var count = maxi(1, runtime.summon_count)
	_ensure_drone_nodes(count)
	for i in range(drone_nodes.size()):
		var drone = drone_nodes[i]
		if drone == null or not is_instance_valid(drone):
			continue
		drone_contact_cooldowns[i] = maxf(0.0, float(drone_contact_cooldowns[i]) - delta)
		drone_respawn_timers[i] = maxf(0.0, float(drone_respawn_timers[i]) - delta)
		drone_target_query_cooldowns[i] = maxf(0.0, float(drone_target_query_cooldowns[i]) - delta)
		if i >= count:
			drone.visible = false
			drone_target_query_cooldowns[i] = 0.0
			continue
		if float(drone_respawn_timers[i]) > 0.0:
			drone.visible = false
			drone_target_query_cooldowns[i] = 0.0
			continue
		if float(drone_hitpoints[i]) <= 0.0:
			drone_respawn_timers[i] = DRONE_RESPAWN_SECONDS
			drone_hitpoints[i] = DRONE_MAX_HP
			drone_contact_cooldowns[i] = 0.0
			drone_target_query_cooldowns[i] = 0.0
			drone.visible = false
			continue
		drone.visible = true
		drone_angles[i] = fposmod(drone_angles[i] + (1.4 + float(i) * 0.18) * delta, TAU)
		var offset = Vector2.RIGHT.rotated(drone_angles[i]) * runtime.orbit_radius
		drone.global_position = global_position + offset
		_update_drone_contact_damage(i, runtime)


func _update_drone_contact_damage(drone_index: int, runtime) -> void:
	if drone_index < 0 or drone_index >= drone_nodes.size():
		return
	if float(drone_contact_cooldowns[drone_index]) > 0.0:
		return
	if float(drone_target_query_cooldowns[drone_index]) > 0.0:
		return
	drone_target_query_cooldowns[drone_index] = DRONE_QUERY_INTERVAL
	var drone := drone_nodes[drone_index]
	if drone == null or not is_instance_valid(drone):
		return
	for enemy_node in _query_enemy_nodes(drone.global_position, DRONE_CONTACT_RADIUS + 6.0, 10, false):
		if enemy_node == null or not is_instance_valid(enemy_node):
			continue
		if enemy_node.global_position.distance_to(drone.global_position) > DRONE_CONTACT_RADIUS:
			continue
		var incoming_damage := 8.0
		var enemy_contact_damage_variant: Variant = enemy_node.get("contact_damage")
		if enemy_contact_damage_variant != null:
			incoming_damage = maxf(1.0, float(enemy_contact_damage_variant) * 0.45)
		var taken_damage := get_summon_damage_taken(incoming_damage)
		drone_hitpoints[drone_index] = maxf(0.0, float(drone_hitpoints[drone_index]) - taken_damage)
		drone_contact_cooldowns[drone_index] = 0.55
		_apply_damage_to_enemy(enemy_node, runtime.damage * 0.35, runtime, Vector2.ZERO, 1)
		FeedbackBus.emit_hit(drone.global_position, 0.14, false)
		break


func get_summon_damage_taken(raw_damage: float) -> float:
	var resistance := clampf(bonus_summon_resistance, 0.0, 0.85)
	return maxf(0.0, raw_damage * (1.0 - resistance))


func _update_beam_visual() -> void:
	if beam_visual == null:
		return
	if beam_visual_timer <= 0.0:
		beam_visual.visible = false
		beam_target = null
		return
	if beam_target == null or not is_instance_valid(beam_target):
		beam_visual.visible = false
		return
	beam_visual.visible = true
	beam_visual.clear_points()
	beam_visual.add_point(Vector2.ZERO)
	beam_visual.add_point(to_local(beam_target.global_position))


func _draw() -> void:
	for mine_variant in deployed_mines:
		if not (mine_variant is Dictionary):
			continue
		var mine: Dictionary = mine_variant
		var world_pos = Vector2(mine.get("position", global_position))
		var local_pos = to_local(world_pos)
		var radius = float(mine.get("radius", 120.0))
		var timer = maxf(0.0, float(mine.get("timer", 0.0)))
		var color = Color(0.92, 0.44, 0.58, 0.6) if timer <= 0.0 else Color(0.58, 0.90, 1.0, 0.46)
		draw_circle(local_pos, 7.0, color)
		draw_arc(local_pos, radius * 0.18, 0.0, TAU, 26, color, 1.5, true)


func take_damage(amount: float) -> void:
	if hp <= 0.0:
		return
	if invuln_remaining > 0.0:
		return
	hp -= amount
	invuln_remaining = 0.35
	emit_stats_changed()
	if hp <= 0.0:
		hp = 0.0
		emit_stats_changed()
		died.emit()


func gain_xp(amount: int) -> void:
	xp += float(amount) * xp_gain_mult * environment_xp_gain_multiplier
	var leveled = false
	while xp >= xp_to_next:
		xp -= xp_to_next
		level += 1
		pending_level_ups += 1
		xp_to_next = floor(xp_to_next * 1.18 + 6.0)
		leveled = true

	if leveled:
		_request_upgrade_if_needed()
	emit_stats_changed()


func apply_upgrade(upgrade_id: String) -> void:
	var upgrade = DataRegistry.get_upgrade(upgrade_id)
	if upgrade.is_empty():
		level_up_open = false
		pending_level_ups = max(0, pending_level_ups - 1)
		_request_upgrade_if_needed()
		return

	upgrade_stacks[upgrade_id] = int(upgrade_stacks.get(upgrade_id, 0)) + 1
	for tag in upgrade.get("tags", []):
		acquired_tags[String(tag)] = int(acquired_tags.get(String(tag), 0)) + 1

	for effect in upgrade.get("effects", []):
		if effect is Dictionary:
			_apply_effect(effect)

	_recompute_synergies()
	cached_runtime = null
	level_up_open = false
	pending_level_ups = max(0, pending_level_ups - 1)
	emit_stats_changed()
	_request_upgrade_if_needed()


func _request_upgrade_if_needed() -> void:
	if pending_level_ups <= 0 or level_up_open:
		return
	var options = DataRegistry.get_upgrade_choices(
		rng,
		upgrade_stacks,
		3,
		character_tag_weights,
		_build_upgrade_context()
	)
	if options.is_empty():
		pending_level_ups = 0
		level_up_open = false
		return
	level_up_open = true
	level_up_requested.emit(options)


func _build_upgrade_context() -> Dictionary:
	var noise_tier = DataRegistry.get_noise_tier(noise)
	var rarity_mult := float(run_reward_multipliers.get("rarity", run_reward_multipliers.get("rarity_mult", 1.0)))
	return {
		"acquired_tags": acquired_tags.duplicate(true),
		"current_weapon_ids": [active_weapon_id],
		"active_weapon_id": active_weapon_id,
		"player_level": level,
		"survive_time_seconds": 0.0,
		"noise_tier_id": String(noise_tier.get("id", "silent")),
		"rarity_mult": rarity_mult,
		"run_reward_multipliers": run_reward_multipliers.duplicate(true)
	}


func _apply_effect(effect: Dictionary) -> void:
	var stat = String(effect.get("stat", ""))
	var value: Variant = effect.get("add", 0)
	var target_variant: Variant = effect.get("target", null)
	if target_variant is Dictionary:
		_apply_targeted_effect(stat, value, target_variant)
		return

	match stat:
		"damage_mult":
			damage_mult += float(value)
		"attack_speed_mult":
			attack_speed_mult += float(value)
		"projectile_speed_mult":
			projectile_speed_mult += float(value)
		"projectile_count_bonus":
			projectile_count_bonus += int(value)
		"pierce_bonus":
			pierce_bonus += int(value)
		"move_speed_bonus":
			move_speed_bonus += float(value)
		"dash_cooldown_reduction":
			dash_cooldown_reduction = clamp(dash_cooldown_reduction + float(value), 0.0, 0.75)
		"max_hp":
			max_hp += float(value)
			hp += float(value)
		"heal":
			hp = min(max_hp, hp + float(value))
		"regen_per_second":
			regen_per_second += float(value)
		"xp_gain_mult":
			xp_gain_mult += float(value)
		"noise_generation_mult":
			noise_generation_mult = max(0.2, noise_generation_mult + float(value))
		"noise_decay_bonus":
			bonus_noise_decay_per_second += float(value)
		"dash_noise_mult":
			dash_noise_multiplier = clampf(dash_noise_multiplier + float(value), 0.2, 2.0)
		"sonar_reveal_duration_mult":
			bonus_sonar_reveal_duration_multiplier += float(value)
		"revealed_damage_mult":
			bonus_revealed_damage_multiplier += float(value)
		"low_noise_damage_mult":
			bonus_low_noise_damage_multiplier += float(value)
		"pickup_radius_mult":
			bonus_pickup_radius_multiplier += float(value)
		"summon_cap_bonus":
			character_summon_cap_bonus += int(value)
		"summon_resistance":
			bonus_summon_resistance += float(value)
		"chain_bonus":
			bonus_chain_chance += float(value)
		"weapon_level_up_active":
			_level_weapon(active_weapon_id, int(value))
		_:
			push_warning("Unknown upgrade effect stat: %s" % stat)


func _apply_targeted_effect(stat: String, value: Variant, target: Dictionary) -> void:
	var target_type = String(target.get("type", "")).strip_edges()
	var target_value = String(target.get("value", "")).strip_edges().to_lower()
	if target_type.is_empty() or target_value.is_empty():
		return

	if stat == "weapon_level_up":
		if target_type == "weapon_id":
			_level_weapon(target_value, int(value))
		elif target_type == "tag":
			for weapon_variant in DataRegistry.weapons.values():
				if not (weapon_variant is Dictionary):
					continue
				var weapon: Dictionary = weapon_variant
				var tags_variant: Variant = weapon.get("tags", [])
				if not (tags_variant is Array):
					continue
				if (tags_variant as Array).has(target_value):
					_level_weapon(String(weapon.get("id", "")), int(value))
		return

	var bucket: Dictionary = {}
	if target_type == "weapon_id":
		bucket = _get_weapon_modifier_bucket(weapon_modifiers_by_id, target_value)
	elif target_type == "tag":
		bucket = _get_weapon_modifier_bucket(weapon_modifiers_by_tag, target_value)
	else:
		push_warning("Unknown effect target type: %s" % target_type)
		return

	match stat:
		"weapon_damage_mult", "damage_mult":
			bucket["weapon_damage_mult"] = float(bucket.get("weapon_damage_mult", 0.0)) + float(value)
		"weapon_attack_rate_mult", "attack_speed_mult":
			bucket["weapon_attack_rate_mult"] = float(bucket.get("weapon_attack_rate_mult", 0.0)) + float(value)
		"weapon_range_mult":
			bucket["weapon_range_mult"] = float(bucket.get("weapon_range_mult", 0.0)) + float(value)
		"weapon_projectile_speed_mult":
			bucket["weapon_projectile_speed_mult"] = float(bucket.get("weapon_projectile_speed_mult", 0.0)) + float(value)
		"weapon_pierce_bonus", "pierce_bonus":
			bucket["weapon_pierce_bonus"] = int(bucket.get("weapon_pierce_bonus", 0)) + int(value)
		"weapon_crit_chance_add":
			bucket["weapon_crit_chance_add"] = float(bucket.get("weapon_crit_chance_add", 0.0)) + float(value)
		"weapon_crit_multiplier_add":
			bucket["weapon_crit_multiplier_add"] = float(bucket.get("weapon_crit_multiplier_add", 0.0)) + float(value)
		"weapon_aoe_radius_mult":
			bucket["weapon_aoe_radius_mult"] = float(bucket.get("weapon_aoe_radius_mult", 0.0)) + float(value)
		"weapon_noise_mult":
			bucket["weapon_noise_mult"] = float(bucket.get("weapon_noise_mult", 0.0)) + float(value)
		"weapon_noise_add":
			bucket["weapon_noise_add"] = float(bucket.get("weapon_noise_add", 0.0)) + float(value)
		"weapon_projectile_count_bonus":
			bucket["weapon_projectile_count_bonus"] = int(bucket.get("weapon_projectile_count_bonus", 0)) + int(value)
		"weapon_reveal_bonus_add":
			bucket["weapon_reveal_bonus_add"] = float(bucket.get("weapon_reveal_bonus_add", 0.0)) + float(value)
		"weapon_summon_cap_bonus", "summon_cap_bonus":
			bucket["weapon_summon_cap_bonus"] = int(bucket.get("weapon_summon_cap_bonus", 0)) + int(value)
		_:
			push_warning("Unknown targeted upgrade effect stat: %s" % stat)

	if target_type == "weapon_id":
		weapon_modifiers_by_id[target_value] = bucket
	elif target_type == "tag":
		weapon_modifiers_by_tag[target_value] = bucket


func _get_weapon_modifier_bucket(store: Dictionary, key: String) -> Dictionary:
	if not store.has(key):
		store[key] = WeaponRuntimeClass.DEFAULT_WEAPON_MODIFIER.duplicate(true)
	var current_variant: Variant = store.get(key, {})
	if current_variant is Dictionary:
		return current_variant
	var fallback = WeaponRuntimeClass.DEFAULT_WEAPON_MODIFIER.duplicate(true)
	store[key] = fallback
	return fallback


func _recompute_synergies() -> void:
	var sonar_count = int(acquired_tags.get("sonar", 0))
	var silence_count = int(acquired_tags.get("silence", 0))
	if sonar_count >= 2 and silence_count >= 2:
		sonar_silence_synergy_bonus = 0.22
	else:
		sonar_silence_synergy_bonus = 0.0


func _current_dash_cooldown() -> float:
	return maxf(0.12, (BASE_DASH_COOLDOWN * character_dash_cooldown_multiplier) * (1.0 - dash_cooldown_reduction))


func _add_noise(amount: float) -> void:
	noise = clampf(noise + (amount * noise_generation_mult * environment_noise_gain_multiplier), noise_min, noise_max)


func _add_noise_source(source_key: String, extra: float = 0.0) -> void:
	var base = float(noise_sources.get(source_key, 0.0))
	if source_key == "attack":
		base += extra * float(noise_sources.get("attack_weapon_scale", 0.0))
	elif source_key == "dash":
		base *= dash_noise_multiplier
	_add_noise(base)


func apply_noise_config(config: Dictionary) -> void:
	if config.is_empty():
		return
	noise_min = float(config.get("min", 0.0))
	noise_max = float(config.get("max", 100.0))
	noise_decay_per_second = float(config.get("decay_per_second", 4.5))
	var sources_variant: Variant = config.get("sources", {})
	if sources_variant is Dictionary:
		noise_sources = (sources_variant as Dictionary).duplicate(true)
	var skill_variant: Variant = config.get("skill", {})
	if skill_variant is Dictionary:
		skill_cooldown = float((skill_variant as Dictionary).get("cooldown", 8.0))
	noise = clampf(noise, noise_min, noise_max)


func set_noise_value(value: float) -> void:
	noise = clampf(value, noise_min, noise_max)


func add_noise_delta(delta_value: float) -> void:
	noise = clampf(noise + delta_value, noise_min, noise_max)


func apply_environment_modifiers(
	noise_modifiers: Dictionary = {},
	sonar_modifiers: Dictionary = {},
	reward_modifiers: Dictionary = {}
) -> void:
	environment_noise_gain_multiplier = maxf(0.05, float(noise_modifiers.get("gain_mult", 1.0)))
	environment_noise_decay_multiplier = maxf(0.05, float(noise_modifiers.get("decay_mult", 1.0)))
	environment_sonar_reveal_multiplier = maxf(0.05, float(sonar_modifiers.get("reveal_duration_mult", 1.0)))
	environment_xp_gain_multiplier = maxf(0.05, float(reward_modifiers.get("xp_mult", 1.0)))


func set_run_reward_multipliers(multipliers: Dictionary = {}) -> void:
	run_reward_multipliers = {
		"xp": maxf(0.0, float(multipliers.get("xp", multipliers.get("xp_mult", 1.0)))),
		"rarity": maxf(0.0, float(multipliers.get("rarity", multipliers.get("rarity_mult", 1.0)))),
		"drop": maxf(0.0, float(multipliers.get("drop", multipliers.get("drop_mult", 1.0)))),
		"meta_currency": maxf(0.0, float(multipliers.get("meta_currency", multipliers.get("meta_currency_mult", 1.0))))
	}


func apply_contract_modifiers(player_modifiers: Dictionary = {}) -> void:
	contract_max_hp_multiplier = maxf(0.05, float(player_modifiers.get("max_hp_mult", 1.0)))
	contract_dash_disabled = float(player_modifiers.get("dash_disabled", 0.0)) >= 0.5
	contract_low_noise_damage_multiplier = maxf(0.05, float(player_modifiers.get("low_noise_damage_mult", 1.0)))
	contract_high_noise_damage_multiplier = maxf(0.05, float(player_modifiers.get("high_noise_damage_mult", 1.0)))
	var previous_max_hp := maxf(1.0, max_hp)
	var hp_ratio := clampf(hp / previous_max_hp, 0.0, 1.0)
	max_hp = maxf(1.0, max_hp * contract_max_hp_multiplier)
	hp = maxf(1.0, max_hp * hp_ratio)


func _ensure_weapon_state() -> void:
	var previous_weapon_id: String = active_weapon_id
	if DataRegistry.get_weapon_runtime(active_weapon_id).is_empty():
		if not DataRegistry.get_default_character_id().is_empty():
			var default_character = DataRegistry.get_character(DataRegistry.get_default_character_id())
			var fallback_weapon = String(default_character.get("starting_weapon_id", BASE_ACTIVE_WEAPON_ID))
			if not DataRegistry.get_weapon_runtime(fallback_weapon).is_empty():
				active_weapon_id = fallback_weapon
	if DataRegistry.get_weapon_runtime(active_weapon_id).is_empty():
		active_weapon_id = BASE_ACTIVE_WEAPON_ID
	if DataRegistry.get_weapon_runtime(active_weapon_id).is_empty():
		for weapon_key in DataRegistry.weapons.keys():
			active_weapon_id = String(weapon_key)
			break
	if active_weapon_id.is_empty():
		return
	if not weapon_levels.has(active_weapon_id):
		weapon_levels[active_weapon_id] = 1
	if previous_weapon_id != active_weapon_id or displayed_weapon_sticker_id != active_weapon_id:
		_apply_weapon_sticker()


func _level_weapon(weapon_id: String, amount: int) -> void:
	if weapon_id.is_empty():
		return
	var weapon = DataRegistry.get_weapon_runtime(weapon_id)
	if weapon.is_empty():
		return
	var growth_variant: Variant = weapon.get("level_growth", [])
	var max_level = (growth_variant as Array).size() if growth_variant is Array else 1
	max_level = maxi(1, max_level)
	var current_level = int(weapon_levels.get(weapon_id, 1))
	weapon_levels[weapon_id] = clampi(current_level + amount, 1, max_level)


func _build_active_weapon_runtime() -> Variant:
	_ensure_weapon_state()
	if active_weapon_id.is_empty():
		return null
	var weapon = DataRegistry.get_weapon_runtime(active_weapon_id)
	if weapon.is_empty():
		return null

	var modifier_sources: Array = []
	if weapon_modifiers_by_id.has(active_weapon_id):
		modifier_sources.append(weapon_modifiers_by_id[active_weapon_id])
	var tags_variant: Variant = weapon.get("tags", [])
	if tags_variant is Array:
		var tags: Array = tags_variant
		for tag_variant in tags:
			var tag = String(tag_variant).to_lower()
			if weapon_modifiers_by_tag.has(tag):
				modifier_sources.append(weapon_modifiers_by_tag[tag])

	var effective_damage_mult = damage_mult * (1.0 + sonar_silence_synergy_bonus)
	if noise <= LOW_NOISE_THRESHOLD and bonus_low_noise_damage_multiplier > 0.0:
		effective_damage_mult *= (1.0 + bonus_low_noise_damage_multiplier)
	if noise <= LOW_NOISE_THRESHOLD:
		effective_damage_mult *= contract_low_noise_damage_multiplier
	elif noise >= 60.0:
		effective_damage_mult *= contract_high_noise_damage_multiplier

	var global_modifiers = {
		"damage_mult": maxf(0.1, effective_damage_mult),
		"attack_speed_mult": maxf(0.1, attack_speed_mult),
		"projectile_speed_mult": maxf(0.1, projectile_speed_mult),
		"range_mult": maxf(0.1, character_projectile_range_multiplier),
		"pierce_bonus": pierce_bonus,
		"crit_chance_bonus": character_crit_chance_bonus,
		"projectile_count_bonus": projectile_count_bonus,
		"summon_cap_bonus": character_summon_cap_bonus
	}
	var level_value = int(weapon_levels.get(active_weapon_id, 1))
	return WeaponRuntimeClass.from_definition(weapon, level_value, global_modifiers, modifier_sources)


func get_chain_parameters_for_current_weapon() -> Dictionary:
	var runtime = _build_active_weapon_runtime()
	if runtime == null:
		return {
			"enabled": false,
			"chance": 0.0,
			"max_hops": 0
	}
	return _get_chain_parameters(runtime)


func get_target_query_total() -> int:
	return target_query_total


func get_target_query_count_per_sec() -> float:
	return target_query_count_per_sec


func compute_damage_against(target: Node, base_damage: float) -> float:
	var damage_value = maxf(0.0, base_damage)
	if bonus_revealed_damage_multiplier > 0.0 and target != null and target.has_method("is_revealed"):
		if bool(target.is_revealed()):
			damage_value *= 1.0 + bonus_revealed_damage_multiplier
	return damage_value


func compute_hit_payload(target: Node, base_damage: float, crit_chance: float, crit_multiplier: float) -> Dictionary:
	var damage_value = compute_damage_against(target, base_damage)
	var final_crit_chance = clampf(crit_chance, 0.0, 0.95)
	var crit = rng.randf() <= final_crit_chance
	if crit:
		damage_value *= maxf(1.0, crit_multiplier)
	return {
		"damage": damage_value,
		"crit": crit
	}


func get_hud_data() -> Dictionary:
	var runtime = cached_runtime
	if runtime == null:
		runtime = _build_active_weapon_runtime()
	if runtime != null:
		cached_runtime = runtime
	var weapon_name = runtime.display_name if runtime != null else active_weapon_id
	var weapon_model = runtime.attack_model if runtime != null else "unknown"
	var weapon_tags = runtime.tags if runtime != null else []
	var weapon_noise = runtime.noise_per_attack if runtime != null else 0.0
	var weapon_noise_rate = runtime.noise_per_attack * runtime.attack_rate if runtime != null else 0.0
	var weapon_dps = runtime.estimate_dps() if runtime != null else 0.0
	var weapon_level = runtime.level if runtime != null else int(weapon_levels.get(active_weapon_id, 1))
	var build_tags := _get_top_build_tags(5)
	var chain_params := _get_chain_parameters(runtime) if runtime != null else {"enabled": false, "chance": 0.0, "max_hops": 0}
	return {
		"hp": hp,
		"max_hp": max_hp,
		"xp": xp,
		"xp_to_next": xp_to_next,
		"level": level,
		"noise": noise,
		"noise_min": noise_min,
		"noise_max": noise_max,
		"dash_cd": dash_cd_remaining,
		"dash_cd_total": _current_dash_cooldown(),
		"skill_cd": skill_cd_remaining,
		"skill_cd_total": skill_cooldown,
		"sonar_feedback_timer": sonar_feedback_timer,
		"sonar_ping_count": sonar_ping_count,
		"sonar_ping_sequence": sonar_ping_sequence,
		"attack_mode": "AUTO" if auto_attack else "AIM",
		"character_id": character_id,
		"character_name": character_name,
		"current_weapons": [active_weapon_id],
		"active_weapon_id": active_weapon_id,
		"active_weapon_name": weapon_name,
		"active_weapon_model": weapon_model,
		"active_weapon_level": weapon_level,
		"weapon_tags": weapon_tags,
		"build_tags": build_tags,
		"upgrade_stacks": upgrade_stacks.duplicate(true),
		"acquired_tags": acquired_tags.duplicate(true),
		"weapon_noise_per_attack": weapon_noise,
		"weapon_noise_rate": weapon_noise_rate,
		"weapon_dps_estimate": weapon_dps,
		"target_query_count_per_sec": target_query_count_per_sec,
		"target_query_total": target_query_total,
		"chain_enabled": bool(chain_params.get("enabled", false)),
		"chain_chance": float(chain_params.get("chance", 0.0)),
		"chain_max_hops": int(chain_params.get("max_hops", 0)),
		"summon_resistance": bonus_summon_resistance,
		"env_noise_gain_multiplier": environment_noise_gain_multiplier,
		"env_noise_decay_multiplier": environment_noise_decay_multiplier,
		"env_sonar_reveal_multiplier": environment_sonar_reveal_multiplier,
		"env_xp_gain_multiplier": environment_xp_gain_multiplier,
		"run_reward_multipliers": run_reward_multipliers.duplicate(true),
		"contract_dash_disabled": contract_dash_disabled,
		"contract_low_noise_damage_multiplier": contract_low_noise_damage_multiplier,
		"contract_high_noise_damage_multiplier": contract_high_noise_damage_multiplier
	}


func emit_stats_changed() -> void:
	stats_changed.emit(get_hud_data())


func _get_top_build_tags(max_count: int = 5) -> Array[String]:
	var pairs: Array = []
	for key_variant in acquired_tags.keys():
		var tag := String(key_variant).strip_edges().to_lower()
		var value := int(acquired_tags.get(key_variant, 0))
		if tag.is_empty() or value <= 0:
			continue
		pairs.append({"tag": tag, "value": value})
	pairs.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var av := int(a.get("value", 0))
		var bv := int(b.get("value", 0))
		if av == bv:
			return String(a.get("tag", "")) < String(b.get("tag", ""))
		return av > bv
	)
	var output: Array[String] = []
	var target_count := mini(max_count, pairs.size())
	for i in range(target_count):
		var pair: Dictionary = pairs[i]
		output.append(String(pair.get("tag", "")))
	return output
