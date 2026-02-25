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
const HIGH_NOISE_THRESHOLD = 60.0
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
const CHARACTER_IDLE_FRAME_SEC := 0.12
const WEAPON_IDLE_FRAME_SEC := 0.10
const CHARACTER_BOB_AMPLITUDE := 0.85
const WEAPON_BOB_AMPLITUDE := 0.42
const VISUAL_OFFSET_SNAP := 0.25
const WEAPON_TRIGGER_CANDLE_RADIUS := 168.0
const WEAPON_TRIGGER_BACKSTAB_DOT_DEFAULT := -0.22
const WEAPON_TRIGGER_LIGHT_MIN_DEFAULT := 0.56
const WEAPON_TRIGGER_DARK_MAX_DEFAULT := 0.34
const FLARE_DECISION_MIN_STRENGTH := 0.95
const FLARE_DECISION_MAX_STRENGTH := 2.20
const FLARE_RISK_BUILDUP_SEC := 4.2
const FLARE_VISIBILITY_GRACE_BASE := 2.4
const FLARE_VISIBILITY_GRACE_PER_STRENGTH := 1.2
const FLARE_EXPOSURE_SPIKE_BASE := 3.6
const FLARE_EXPOSURE_SPIKE_PER_STRENGTH := 5.2
const FLARE_EXPOSURE_SPIKE_DARK_BONUS := 4.8
const FLARE_EXPOSURE_SURGE_BASE_SEC := 1.2
const FLARE_EXPOSURE_SURGE_PER_STRENGTH_SEC := 1.55
const FLARE_EXPOSURE_SURGE_BASE_RATE := 1.4
const FLARE_EXPOSURE_SURGE_PER_STRENGTH_RATE := 2.4
const DARKNESS_SPREAD_MAX_MULT := 1.95
const DARKNESS_PRECISION_MIN_MULT := 0.22
const DARKNESS_VISIBILITY_MIN_MULT := 0.52
const DARKNESS_NOISE_DECAY_BOOST_MIN_PRESSURE := 0.35
const DARKNESS_NOISE_DECAY_BOOST_MAX_MULT := 1.85

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
var bonus_low_noise_attack_speed_multiplier: float = 0.0
var bonus_high_noise_damage_multiplier: float = 0.0
var bonus_high_noise_attack_speed_multiplier: float = 0.0
var bonus_noise_decay_per_second: float = 0.0
var bonus_darkness_noise_decay_boost: float = 0.0
var dash_noise_multiplier: float = 1.0
var bonus_summon_resistance: float = 0.0
var bonus_summon_contact_radius_multiplier: float = 0.0
var bonus_summon_orbit_radius_multiplier: float = 0.0
var bonus_summon_hit_noise_refund: float = 0.0
var bonus_summon_guard_damage_reduction: float = 0.0
var bonus_kill_noise_refund: float = 0.0
var bonus_kill_attack_cooldown_refund: float = 0.0
var bonus_kill_skill_cooldown_refund: float = 0.0
var bonus_flare_noise_spike_multiplier: float = 0.0
var bonus_flare_visibility_grace_multiplier: float = 0.0
var bonus_flare_overdrive_duration: float = 0.0
var bonus_flare_overdrive_attack_speed_multiplier: float = 0.0
var bonus_flare_overdrive_damage_multiplier: float = 0.0
var bonus_chain_chance: float = 0.0
var environment_noise_gain_multiplier: float = 1.0
var environment_noise_decay_multiplier: float = 1.0
var environment_sonar_reveal_multiplier: float = 1.0
var environment_sonar_radius_multiplier: float = 1.0
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
var _character_idle_offset_y: float = 0.0
var _weapon_base_offset_y: float = -8.0
var _weapon_idle_offset_y: float = 0.0
var recoil_heat: float = 0.0
var last_shot_precision_bonus: float = 0.0
var weapon_hit_counters: Dictionary = {}
var weapon_signature_marks: Dictionary = {}
var flare_visibility_grace_remaining: float = 0.0
var flare_exposure_surge_remaining: float = 0.0
var flare_exposure_surge_duration: float = 0.0
var flare_exposure_surge_rate: float = 0.0
var flare_overdrive_remaining: float = 0.0
var darkness_pressure: float = 0.0
var last_flare_strength: float = FLARE_DECISION_MIN_STRENGTH


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
		_character_idle_offset_y = 0.0
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
	bonus_low_noise_attack_speed_multiplier = 0.0
	bonus_high_noise_damage_multiplier = 0.0
	bonus_high_noise_attack_speed_multiplier = 0.0
	bonus_noise_decay_per_second = 0.0
	bonus_darkness_noise_decay_boost = 0.0
	dash_noise_multiplier = 1.0
	bonus_summon_resistance = 0.0
	bonus_summon_contact_radius_multiplier = 0.0
	bonus_summon_orbit_radius_multiplier = 0.0
	bonus_summon_hit_noise_refund = 0.0
	bonus_summon_guard_damage_reduction = 0.0
	bonus_kill_noise_refund = 0.0
	bonus_kill_attack_cooldown_refund = 0.0
	bonus_kill_skill_cooldown_refund = 0.0
	bonus_flare_noise_spike_multiplier = 0.0
	bonus_flare_visibility_grace_multiplier = 0.0
	bonus_flare_overdrive_duration = 0.0
	bonus_flare_overdrive_attack_speed_multiplier = 0.0
	bonus_flare_overdrive_damage_multiplier = 0.0
	bonus_chain_chance = 0.0
	environment_noise_gain_multiplier = 1.0
	environment_noise_decay_multiplier = 1.0
	environment_sonar_reveal_multiplier = 1.0
	environment_sonar_radius_multiplier = 1.0
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
	recoil_heat = 0.0
	last_shot_precision_bonus = 0.0
	weapon_hit_counters.clear()
	weapon_signature_marks.clear()
	flare_visibility_grace_remaining = 0.0
	flare_exposure_surge_remaining = 0.0
	flare_exposure_surge_duration = 0.0
	flare_exposure_surge_rate = 0.0
	flare_overdrive_remaining = 0.0
	darkness_pressure = 0.0
	last_flare_strength = FLARE_DECISION_MIN_STRENGTH
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
	var recoil_decay := 1.8 + (0.8 if velocity.length() < 24.0 else 0.0)
	recoil_heat = maxf(0.0, recoil_heat - recoil_decay * delta)
	_tick_flare_risk_state(delta)

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
	noise_decay *= _get_darkness_noise_decay_multiplier()
	noise = clampf(noise - maxf(0.0, noise_decay) * delta, noise_min, noise_max)
	_update_deployed_mines(delta)
	_update_drone_orbits(delta)
	_update_beam_visual()
	if not deployed_mines.is_empty():
		queue_redraw()


func _tick_idle_stickers(delta: float) -> void:
	if sprite_node != null and _character_sticker_frames.size() > 1:
		_character_idle_timer += delta
		while _character_idle_timer >= CHARACTER_IDLE_FRAME_SEC:
			_character_idle_timer -= CHARACTER_IDLE_FRAME_SEC
			_character_frame_idx = (_character_frame_idx + 1) % _character_sticker_frames.size()
			sprite_node.texture = _character_sticker_frames[_character_frame_idx]
		_character_idle_offset_y = _idle_bob_offset(_character_frame_idx, _character_sticker_frames.size(), CHARACTER_BOB_AMPLITUDE)
		sprite_node.position = _sprite_base_position + Vector2(0.0, _character_idle_offset_y)
	elif sprite_node != null:
		_character_idle_offset_y = 0.0
		sprite_node.position = _sprite_base_position

	if weapon_sticker_node != null and weapon_sticker_node.visible and _weapon_sticker_frames.size() > 1:
		_weapon_idle_timer += delta
		while _weapon_idle_timer >= WEAPON_IDLE_FRAME_SEC:
			_weapon_idle_timer -= WEAPON_IDLE_FRAME_SEC
			_weapon_frame_idx = (_weapon_frame_idx + 1) % _weapon_sticker_frames.size()
			weapon_sticker_node.texture = _weapon_sticker_frames[_weapon_frame_idx]
		_weapon_idle_offset_y = _idle_bob_offset(_weapon_frame_idx, _weapon_sticker_frames.size(), WEAPON_BOB_AMPLITUDE)
	elif weapon_sticker_node != null:
		_weapon_idle_offset_y = 0.0


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


func _trigger_flare_skill() -> void:
	skill_cd_remaining = skill_cooldown
	_add_noise_source("skill")
	var sonar_cfg := DataRegistry.get_sonar_config()
	var base_radius := maxf(120.0, float(sonar_cfg.get("max_radius", 720.0)))
	var enemy_pressure_radius := base_radius * 0.82 * maxf(0.2, environment_sonar_radius_multiplier)
	var local_enemy_pressure := clampf(float(_estimate_enemy_count_in_radius(global_position, enemy_pressure_radius)) / 9.0, 0.0, 1.0)
	var flare_strength := clampf(
		FLARE_DECISION_MIN_STRENGTH
		+ (_get_darkness_pressure_ratio() * 1.05)
		+ (local_enemy_pressure * 0.28),
		FLARE_DECISION_MIN_STRENGTH,
		FLARE_DECISION_MAX_STRENGTH
	)
	last_flare_strength = flare_strength
	var flare_strength_norm := clampf(
		(flare_strength - FLARE_DECISION_MIN_STRENGTH) / maxf(0.001, FLARE_DECISION_MAX_STRENGTH - FLARE_DECISION_MIN_STRENGTH),
		0.0,
		1.0
	)
	var ping_radius := base_radius * (1.02 + flare_strength * 0.28) * environment_sonar_radius_multiplier
	sonar_ping_count = _estimate_enemy_count_in_radius(global_position, ping_radius)
	sonar_ping_sequence += 1
	sonar_feedback_timer = sonar_feedback_duration
	var flare_spike := (
		FLARE_EXPOSURE_SPIKE_BASE
		+ (flare_strength * FLARE_EXPOSURE_SPIKE_PER_STRENGTH)
		+ (_get_darkness_pressure_ratio() * FLARE_EXPOSURE_SPIKE_DARK_BONUS)
	)
	flare_spike *= maxf(0.10, 1.0 + bonus_flare_noise_spike_multiplier)
	add_noise_delta(flare_spike)
	flare_exposure_surge_duration = FLARE_EXPOSURE_SURGE_BASE_SEC + (flare_strength * FLARE_EXPOSURE_SURGE_PER_STRENGTH_SEC)
	flare_exposure_surge_remaining = maxf(flare_exposure_surge_remaining, flare_exposure_surge_duration)
	flare_exposure_surge_rate = maxf(flare_exposure_surge_rate, FLARE_EXPOSURE_SURGE_BASE_RATE + (flare_strength * FLARE_EXPOSURE_SURGE_PER_STRENGTH_RATE))
	var flare_grace_mult := maxf(0.25, 1.0 + bonus_flare_visibility_grace_multiplier)
	flare_visibility_grace_remaining = maxf(
		flare_visibility_grace_remaining,
		(FLARE_VISIBILITY_GRACE_BASE + flare_strength * FLARE_VISIBILITY_GRACE_PER_STRENGTH) * flare_grace_mult
	)
	if bonus_flare_overdrive_duration > 0.0 and (
		bonus_flare_overdrive_attack_speed_multiplier > 0.0
		or bonus_flare_overdrive_damage_multiplier > 0.0
	):
		flare_overdrive_remaining = maxf(flare_overdrive_remaining, bonus_flare_overdrive_duration)
	darkness_pressure = maxf(0.0, darkness_pressure - (0.76 + flare_strength * 0.18))
	FeedbackBus.emit_sonar_pulse(global_position, {
		"source": "flare",
		"player_skill": true,
		"screen_flash": 1.18 + flare_strength * 0.52,
		"strength": flare_strength,
		"radius_scale": 1.06 + flare_strength * 0.30,
		"speed": 980.0,
		"line_width": 7.6 + flare_strength_norm * 2.8,
		"flare_duration_mult": 0.90 + flare_strength_norm * 0.45,
		"ping_count": sonar_ping_count,
		"reveal_duration_multiplier": get_sonar_reveal_duration_multiplier()
	})


func _estimate_enemy_count_in_radius(center: Vector2, radius: float) -> int:
	return _query_enemy_nodes(center, radius, 96, true).size()


func _tick_flare_risk_state(delta: float) -> void:
	if flare_overdrive_remaining > 0.0:
		flare_overdrive_remaining = maxf(0.0, flare_overdrive_remaining - delta)
	if flare_visibility_grace_remaining > 0.0:
		flare_visibility_grace_remaining = maxf(0.0, flare_visibility_grace_remaining - delta)
		darkness_pressure = maxf(0.0, darkness_pressure - (delta * 1.35))
	else:
		darkness_pressure = minf(1.0, darkness_pressure + (delta / maxf(0.2, FLARE_RISK_BUILDUP_SEC)))
	if flare_exposure_surge_remaining > 0.0:
		flare_exposure_surge_remaining = maxf(0.0, flare_exposure_surge_remaining - delta)
		var surge_ratio := clampf(flare_exposure_surge_remaining / maxf(0.001, flare_exposure_surge_duration), 0.0, 1.0)
		var surge_step := flare_exposure_surge_rate * delta * (0.72 + surge_ratio * 0.28)
		if surge_step > 0.0:
			add_noise_delta(surge_step)
	if flare_exposure_surge_remaining <= 0.0:
		flare_exposure_surge_duration = 0.0
		flare_exposure_surge_rate = 0.0


func _get_darkness_pressure_ratio() -> float:
	return clampf(darkness_pressure, 0.0, 1.0)


func _get_darkness_noise_decay_multiplier() -> float:
	var pressure_ratio := _get_darkness_pressure_ratio()
	if pressure_ratio <= DARKNESS_NOISE_DECAY_BOOST_MIN_PRESSURE:
		return 1.0
	var normalized := clampf(
		(pressure_ratio - DARKNESS_NOISE_DECAY_BOOST_MIN_PRESSURE) / maxf(0.001, 1.0 - DARKNESS_NOISE_DECAY_BOOST_MIN_PRESSURE),
		0.0,
		1.0
	)
	var max_mult := DARKNESS_NOISE_DECAY_BOOST_MAX_MULT + maxf(0.0, bonus_darkness_noise_decay_boost)
	return lerpf(1.0, max_mult, normalized)


func _get_visibility_accuracy_multiplier() -> float:
	return lerpf(1.0, DARKNESS_PRECISION_MIN_MULT, _get_darkness_pressure_ratio())


func get_visibility_penalty_multiplier() -> float:
	return lerpf(1.0, DARKNESS_VISIBILITY_MIN_MULT, _get_darkness_pressure_ratio())


func _attempt_fire() -> void:
	if projectile_manager == null:
		return
	_ensure_weapon_state()
	var runtime = _build_active_weapon_runtime()
	if runtime == null:
		return
	cached_runtime = runtime
	var shot_handling := _build_shot_handling(runtime)
	var targeting_range := _get_effective_targeting_range(runtime)

	var fire_direction = Vector2.ZERO
	var target = _resolve_target(targeting_range)
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
			_fire_projectile(runtime, fire_direction, shot_handling)
		"pulse":
			_fire_pulse(runtime)
		"mine":
			_deploy_mine(runtime, fire_direction, target)
		"beam":
			_fire_beam(runtime, target)
		"drone":
			_fire_drone(runtime, shot_handling)
		"melee":
			_fire_melee(runtime, fire_direction)
		_:
			_fire_projectile(runtime, fire_direction, shot_handling)

	FeedbackBus.emit_shot(global_position, 0.12)
	attack_cd_remaining = max(0.05, runtime.attack_interval)
	_add_noise_source("attack", runtime.noise_per_attack)


func _build_shot_handling(runtime) -> Dictionary:
	if runtime == null:
		return {"spread_mult": 1.0, "precision_bonus": 0.0}
	var base_move_speed := maxf(40.0, (BASE_MOVE_SPEED * character_move_speed_multiplier) + move_speed_bonus)
	var move_norm := clampf(velocity.length() / base_move_speed, 0.0, 1.0)
	var packet_pressure := float(runtime.attack_rate) * float(maxi(1, runtime.projectile_count)) * float(maxi(1, runtime.burst_count))
	if String(runtime.attack_model) != "projectile" and String(runtime.attack_model) != "drone":
		packet_pressure *= 0.55
	var heat_gain := 0.05 + clampf(packet_pressure / 40.0, 0.0, 0.38)
	heat_gain += move_norm * 0.04
	recoil_heat = clampf(recoil_heat + heat_gain, 0.0, 1.8)
	var spread_mult := 1.0 + (recoil_heat * 0.62) + (move_norm * 0.20)
	if move_norm < 0.18:
		spread_mult *= 0.88
	var darkness_pressure_ratio := _get_darkness_pressure_ratio()
	spread_mult *= lerpf(1.0, DARKNESS_SPREAD_MAX_MULT, darkness_pressure_ratio)
	var precision_bonus := clampf((0.72 - recoil_heat) * 0.055, 0.0, 0.045)
	precision_bonus *= _get_visibility_accuracy_multiplier()
	last_shot_precision_bonus = precision_bonus
	return {
		"spread_mult": clampf(spread_mult, 0.55, 3.45),
		"precision_bonus": precision_bonus
	}


func _fire_projectile(runtime, fire_direction: Vector2, shot_handling: Dictionary = {}) -> void:
	var shoot_origin := global_position
	var spread_mult := clampf(float(shot_handling.get("spread_mult", 1.0)), 0.55, 3.45)
	var precision_bonus := clampf(float(shot_handling.get("precision_bonus", 0.0)), 0.0, 0.08)
	_spawn_projectile_volley(runtime, fire_direction, shoot_origin, 1.0, spread_mult, precision_bonus)
	var bursts := clampi(int(runtime.burst_count), 1, 6)
	if bursts <= 1:
		return
	var interval := clampf(float(runtime.burst_interval), 0.0, 0.45)
	var tree := get_tree()
	if tree == null:
		return
	for burst_idx in range(1, bursts):
		var damage_scale := pow(0.9, float(burst_idx))
		var burst_spread := spread_mult * (1.0 + float(burst_idx) * 0.07)
		var burst_precision := maxf(0.0, precision_bonus - (0.008 * float(burst_idx)))
		if interval <= 0.01:
			_spawn_projectile_volley(runtime, fire_direction, shoot_origin, damage_scale, burst_spread, burst_precision)
			continue
		var fire_dir := fire_direction
		var origin := shoot_origin
		tree.create_timer(interval * float(burst_idx)).timeout.connect(func() -> void:
			if not is_inside_tree():
				return
			_spawn_projectile_volley(runtime, fire_dir, origin, damage_scale, burst_spread, burst_precision)
		)


func _fire_pulse(runtime) -> void:
	_emit_pulse_tick(runtime, 1.0)
	var repeats := clampi(int(runtime.pulse_repeats), 1, 4)
	if repeats <= 1:
		return
	var interval := clampf(float(runtime.pulse_repeat_interval), 0.02, 0.45)
	var tree := get_tree()
	if tree == null:
		return
	for pulse_idx in range(1, repeats):
		var damage_scale := pow(clampf(float(runtime.pulse_falloff), 0.2, 1.0), float(pulse_idx))
		tree.create_timer(interval * float(pulse_idx)).timeout.connect(func() -> void:
			if not is_inside_tree():
				return
			_emit_pulse_tick(runtime, damage_scale)
		)


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
		"pulse_strength": runtime.sonar_pulse_strength,
		"shard_count": int(runtime.mine_shard_count),
		"shard_speed": float(runtime.mine_shard_speed),
		"shard_range": float(runtime.mine_shard_range),
		"projectile_radius": float(runtime.projectile_radius),
		"impact_aoe_radius": float(runtime.impact_aoe_radius),
		"impact_aoe_damage_mult": float(runtime.impact_aoe_damage_mult),
		"impact_pulse_strength": float(runtime.impact_pulse_strength),
		"impact_pulse_radius_scale": float(runtime.impact_pulse_radius_scale),
		"impact_knockback": float(runtime.impact_knockback),
		"weapon_id": runtime.weapon_id,
		"fx_color": String(runtime.fx_color),
		"signature_mode": String(runtime.signature_mode),
		"signature_power": float(runtime.signature_power),
		"signature_aux": float(runtime.signature_aux),
		"signature_cycle": int(runtime.signature_cycle),
		"signature_duration": float(runtime.signature_duration),
		"attack_model": String(runtime.attack_model)
	})
	queue_redraw()


func _fire_beam(runtime, target: Node2D) -> void:
	var visible_range := _get_effective_targeting_range(runtime)
	var beam_target_local = target
	if beam_target_local == null or not is_instance_valid(beam_target_local):
		beam_target_local = _pick_target_in_range(visible_range)
	if beam_target_local == null:
		return
	if beam_target_local.global_position.distance_to(global_position) > visible_range:
		beam_target_local = _pick_target_in_range(visible_range)
	if beam_target_local == null:
		return
	var chain_targets := maxi(0, int(runtime.beam_chain_targets))
	var chain_falloff := clampf(float(runtime.beam_chain_falloff), 0.1, 1.0)
	var current_damage: float = float(runtime.damage)
	var visited: Dictionary = {}
	var current_target: Node2D = beam_target_local
	for hop in range(chain_targets + 1):
		if current_target == null or not is_instance_valid(current_target):
			break
		var impulse := (current_target.global_position - global_position).normalized() * float(runtime.impact_knockback)
		_apply_damage_to_enemy(current_target, current_damage, runtime, impulse)
		visited[int(current_target.get_instance_id())] = true
		if hop >= chain_targets:
			break
		var chain_radius := clampf(runtime.range * 0.5, 120.0, 420.0)
		var next_target := _pick_beam_chain_target(current_target.global_position, chain_radius, visited)
		if next_target == null:
			break
		FeedbackBus.emit_sonar_pulse(current_target.global_position, {
			"source": "hit",
			"strength": clampf(0.34 + float(hop) * 0.08, 0.2, 1.0),
			"radius_scale": 0.9,
			"reveal_duration_multiplier": get_sonar_reveal_duration_multiplier()
		})
		current_target = next_target
		current_damage *= chain_falloff
	beam_target = beam_target_local
	beam_visual_timer = maxf(beam_visual_timer, runtime.beam_tick_interval)


func _fire_drone(runtime, shot_handling: Dictionary = {}) -> void:
	var drone_count = maxi(1, runtime.summon_count)
	_ensure_drone_nodes(drone_count)
	var visible_range := _get_effective_targeting_range(runtime)
	var spread_mult := clampf(float(shot_handling.get("spread_mult", 1.0)), 0.7, 2.6)
	var precision_bonus := clampf(float(shot_handling.get("precision_bonus", 0.0)) * 0.5, 0.0, 0.04)
	for i in range(drone_nodes.size()):
		var drone = drone_nodes[i]
		if i >= drone_count:
			drone.visible = false
			continue
		drone.visible = true
		var origin = drone.global_position
		var target = _pick_target_near(origin, minf(runtime.range * 1.15, visible_range * 1.15))
		if target == null:
			continue
		var direction = (target.global_position - origin).normalized()
		if direction.length() < 0.01:
			continue
		var volley := maxi(1, int(runtime.drone_volley))
		var spread_step := deg_to_rad(float(runtime.drone_spread_deg) * lerpf(1.0, spread_mult, 0.35))
		var center := (float(volley) - 1.0) * 0.5
		for shot_idx in range(volley):
			var offset := (float(shot_idx) - center) * spread_step
			var dir: Vector2 = direction.rotated(offset)
			var projectile_data = {
				"weapon_id": runtime.weapon_id,
				"damage": runtime.damage * 0.9,
				"speed": maxf(240.0, runtime.projectile_speed),
				"range": maxf(220.0, runtime.range),
				"pierce": runtime.pierce,
				"radius": runtime.drone_projectile_radius,
				"tags": runtime.tags,
				"crit_chance": runtime.crit_chance,
				"crit_multiplier": runtime.crit_multiplier,
				"precision_bonus": precision_bonus,
				"reveal_bonus_duration": runtime.reveal_bonus_duration * get_sonar_reveal_duration_multiplier(),
				"impact_aoe_radius": runtime.impact_aoe_radius,
				"impact_aoe_damage_mult": runtime.impact_aoe_damage_mult,
				"impact_pulse_strength": runtime.impact_pulse_strength,
				"impact_pulse_radius_scale": runtime.impact_pulse_radius_scale,
				"impact_knockback": runtime.impact_knockback,
				"fx_color": runtime.fx_color,
				"signature_mode": runtime.signature_mode,
				"signature_power": runtime.signature_power,
				"signature_aux": runtime.signature_aux,
				"signature_cycle": runtime.signature_cycle,
				"signature_duration": runtime.signature_duration,
				"attack_model": runtime.attack_model
			}
			projectile_manager.spawn_projectile(origin, dir, projectile_data, self)


func _fire_melee(runtime, fire_direction: Vector2) -> void:
	var forward = fire_direction.normalized()
	if forward.length() < 0.01:
		forward = last_move_direction if last_move_direction.length() > 0.01 else Vector2.RIGHT
	var radius = runtime.aoe_radius if runtime.aoe_radius > 0.0 else runtime.range
	var cone_dot := clampf(float(runtime.melee_cone_dot), -1.0, 0.95)
	var knockback := maxf(0.0, float(runtime.impact_knockback))
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
		if forward.dot(enemy_dir) < cone_dot:
			continue
		if _apply_damage_to_enemy(enemy, runtime.damage, runtime, enemy_dir * knockback):
			hit_count += 1
	FeedbackBus.emit_sonar_pulse(global_position, {
		"source": "hit",
		"strength": clampf(runtime.sonar_pulse_strength + (0.08 * float(hit_count)), 0.3, 2.2),
		"radius_scale": 1.25,
		"reveal_duration_multiplier": get_sonar_reveal_duration_multiplier()
	})


func _build_projectile_payload(
	runtime,
	damage_scale: float = 1.0,
	radius_override: float = -1.0,
	precision_bonus: float = 0.0
) -> Dictionary:
	var reveal_bonus: float = float(runtime.reveal_bonus_duration) * get_sonar_reveal_duration_multiplier()
	var projectile_radius := radius_override if radius_override > 0.0 else float(runtime.projectile_radius)
	return {
		"weapon_id": runtime.weapon_id,
		"damage": runtime.damage * damage_scale,
		"speed": runtime.projectile_speed,
		"range": runtime.range,
		"pierce": runtime.pierce,
		"radius": projectile_radius,
		"tags": runtime.tags,
		"crit_chance": runtime.crit_chance,
		"crit_multiplier": runtime.crit_multiplier,
		"precision_bonus": clampf(precision_bonus, 0.0, 0.1),
		"reveal_bonus_duration": reveal_bonus,
		"impact_aoe_radius": runtime.impact_aoe_radius,
		"impact_aoe_damage_mult": runtime.impact_aoe_damage_mult,
		"impact_pulse_strength": runtime.impact_pulse_strength,
		"impact_pulse_radius_scale": runtime.impact_pulse_radius_scale,
		"impact_knockback": runtime.impact_knockback,
		"fx_color": runtime.fx_color,
		"signature_mode": runtime.signature_mode,
		"signature_power": runtime.signature_power,
		"signature_aux": runtime.signature_aux,
		"signature_cycle": runtime.signature_cycle,
		"signature_duration": runtime.signature_duration,
		"attack_model": runtime.attack_model
	}


func _spawn_projectile_volley(
	runtime,
	fire_direction: Vector2,
	origin: Vector2,
	damage_scale: float = 1.0,
	spread_multiplier: float = 1.0,
	precision_bonus: float = 0.0
) -> void:
	if projectile_manager == null:
		return
	var count: int = maxi(1, runtime.projectile_count)
	var spread_step := deg_to_rad(float(runtime.projectile_spread_deg) * clampf(spread_multiplier, 0.4, 4.2))
	var center := (float(count) - 1.0) * 0.5
	for i in range(count):
		var offset := (float(i) - center) * spread_step
		var dir := fire_direction.rotated(offset)
		var projectile_data := _build_projectile_payload(runtime, damage_scale, -1.0, precision_bonus)
		projectile_manager.spawn_projectile(origin, dir, projectile_data, self)


func _emit_pulse_tick(runtime, damage_scale: float = 1.0) -> void:
	var synthetic_runtime = WeaponRuntimeClass.new()
	synthetic_runtime.weapon_id = runtime.weapon_id
	synthetic_runtime.damage = runtime.damage * damage_scale
	synthetic_runtime.crit_chance = runtime.crit_chance
	synthetic_runtime.crit_multiplier = runtime.crit_multiplier
	synthetic_runtime.reveal_bonus_duration = runtime.reveal_bonus_duration
	synthetic_runtime.sonar_pulse_strength = runtime.sonar_pulse_strength
	synthetic_runtime.attack_model = "pulse"
	synthetic_runtime.tags = runtime.tags.duplicate()
	synthetic_runtime.range = runtime.range
	synthetic_runtime.signature_mode = runtime.signature_mode
	synthetic_runtime.signature_power = runtime.signature_power
	synthetic_runtime.signature_aux = runtime.signature_aux
	synthetic_runtime.signature_cycle = runtime.signature_cycle
	synthetic_runtime.signature_duration = runtime.signature_duration
	var radius: float = float(runtime.aoe_radius) if float(runtime.aoe_radius) > 0.0 else float(runtime.range)
	var hit_count := _damage_enemies_in_radius(global_position, radius, synthetic_runtime, Vector2.ZERO)
	FeedbackBus.emit_sonar_pulse(global_position, {
		"source": "hit",
		"strength": clampf(runtime.sonar_pulse_strength + (0.05 * float(hit_count) * damage_scale), 0.2, 2.0),
		"radius_scale": 1.08,
		"reveal_duration_multiplier": get_sonar_reveal_duration_multiplier()
	})


func _pick_beam_chain_target(origin: Vector2, radius: float, visited_ids: Dictionary) -> Node2D:
	var best_target: Node2D = null
	var best_distance := INF
	for enemy_node in _query_enemy_nodes(origin, radius, 20, false):
		if enemy_node == null or not is_instance_valid(enemy_node):
			continue
		var instance_id := int(enemy_node.get_instance_id())
		if visited_ids.has(instance_id):
			continue
		var distance := enemy_node.global_position.distance_to(origin)
		if distance < best_distance:
			best_distance = distance
			best_target = enemy_node
	return best_target


func _resolve_target(max_range: float = INF) -> Node2D:
	if auto_attack:
		if enemy_manager != null and enemy_manager.has_method("get_priority_target"):
			var target: Variant = enemy_manager.get_priority_target(global_position)
			if target is Node2D and is_instance_valid(target as Node2D):
				var target_node := target as Node2D
				if target_node.global_position.distance_to(global_position) <= max_range:
					return target_node
	else:
		var mouse_direction = get_global_mouse_position() - global_position
		if mouse_direction.length() > 0.01:
			return _pick_target_in_direction(mouse_direction.normalized(), max_range)
	return null


func _get_effective_targeting_range(runtime = null) -> float:
	var weapon_range := float(runtime.range) if runtime != null else 720.0
	var visibility_limit := _get_runtime_vision_radius() * get_visibility_penalty_multiplier()
	return clampf(minf(weapon_range, visibility_limit), 96.0, maxf(96.0, weapon_range))


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


func _pick_target_in_direction(direction: Vector2, max_range: float = INF) -> Node2D:
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
		if to_enemy.length() > max_range:
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
	var payload_context := _build_signature_context_from_runtime(runtime, global_position)
	var payload = compute_hit_payload(enemy, base_damage, runtime.crit_chance, runtime.crit_multiplier, payload_context)
	var final_damage = float(payload.get("damage", base_damage))
	var is_crit = bool(payload.get("crit", false))
	var killed = bool(enemy.take_hit(final_damage, impulse))
	if runtime.reveal_bonus_duration > 0.0 and enemy.has_method("set_revealed"):
		enemy.set_revealed(runtime.reveal_bonus_duration)
	_handle_signature_post_hit(enemy, final_damage, is_crit, killed, payload, global_position)
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
			synthetic_runtime.weapon_id = String(mine.get("weapon_id", active_weapon_id))
			synthetic_runtime.damage = float(mine.get("damage", 20.0))
			synthetic_runtime.crit_chance = float(mine.get("crit_chance", 0.0))
			synthetic_runtime.crit_multiplier = float(mine.get("crit_multiplier", 1.5))
			synthetic_runtime.reveal_bonus_duration = float(mine.get("reveal_bonus_duration", 0.0))
			synthetic_runtime.attack_model = "mine"
			synthetic_runtime.tags = mine.get("tags", [])
			synthetic_runtime.range = float(mine.get("radius", 120.0))
			synthetic_runtime.signature_mode = String(mine.get("signature_mode", ""))
			synthetic_runtime.signature_power = float(mine.get("signature_power", 0.0))
			synthetic_runtime.signature_aux = float(mine.get("signature_aux", 0.0))
			synthetic_runtime.signature_cycle = int(mine.get("signature_cycle", 0))
			synthetic_runtime.signature_duration = float(mine.get("signature_duration", 0.0))
			_damage_enemies_in_radius(Vector2(mine.get("position", global_position)), float(mine.get("radius", 120.0)), synthetic_runtime)
			FeedbackBus.emit_sonar_pulse(Vector2(mine.get("position", global_position)), {
				"source": "hit",
				"strength": clampf(float(mine.get("pulse_strength", 1.0)), 0.2, 2.0),
				"radius_scale": 1.22,
				"reveal_duration_multiplier": get_sonar_reveal_duration_multiplier()
			})
			_spawn_mine_shards(mine)
		else:
			active.append(mine)
	deployed_mines = active


func _spawn_mine_shards(mine: Dictionary) -> void:
	var shard_count := maxi(0, int(mine.get("shard_count", 0)))
	if shard_count <= 0 or projectile_manager == null:
		return
	var origin := Vector2(mine.get("position", global_position))
	var weapon_id := String(mine.get("weapon_id", active_weapon_id))
	var shard_speed := clampf(float(mine.get("shard_speed", 560.0)), 80.0, 1600.0)
	var shard_range := clampf(float(mine.get("shard_range", 300.0)), 30.0, 1400.0)
	var projectile_radius := clampf(float(mine.get("projectile_radius", 4.0)), 2.0, 18.0)
	var aoe_radius := maxf(0.0, float(mine.get("impact_aoe_radius", 0.0)))
	var aoe_damage_mult := clampf(float(mine.get("impact_aoe_damage_mult", 0.45)), 0.0, 1.5)
	var pulse_strength := maxf(0.0, float(mine.get("impact_pulse_strength", 0.0)))
	var pulse_radius_scale := clampf(float(mine.get("impact_pulse_radius_scale", 0.9)), 0.3, 2.5)
	var knockback := maxf(0.0, float(mine.get("impact_knockback", 180.0)))
	var base_damage := maxf(0.1, float(mine.get("damage", 20.0)) * 0.48)
	var reveal_bonus := float(mine.get("reveal_bonus_duration", 0.0))
	var tags_variant: Variant = mine.get("tags", [])
	var shard_tags: Array = tags_variant if tags_variant is Array else []
	for i in range(shard_count):
		var angle := (TAU / float(shard_count)) * float(i)
		var dir := Vector2.RIGHT.rotated(angle)
		var projectile_data := {
			"weapon_id": weapon_id,
			"damage": base_damage,
			"speed": shard_speed,
			"range": shard_range,
			"pierce": 0,
			"radius": projectile_radius * 0.8,
			"tags": shard_tags,
			"crit_chance": float(mine.get("crit_chance", 0.0)),
			"crit_multiplier": float(mine.get("crit_multiplier", 1.5)),
			"reveal_bonus_duration": reveal_bonus,
			"impact_aoe_radius": aoe_radius,
			"impact_aoe_damage_mult": aoe_damage_mult,
			"impact_pulse_strength": pulse_strength,
			"impact_pulse_radius_scale": pulse_radius_scale,
			"impact_knockback": knockback,
			"fx_color": String(mine.get("fx_color", "")),
			"signature_mode": String(mine.get("signature_mode", "")),
			"signature_power": float(mine.get("signature_power", 0.0)),
			"signature_aux": float(mine.get("signature_aux", 0.0)),
			"signature_cycle": int(mine.get("signature_cycle", 0)),
			"signature_duration": float(mine.get("signature_duration", 0.0)),
			"attack_model": String(mine.get("attack_model", "mine"))
		}
		projectile_manager.spawn_projectile(origin, dir, projectile_data, self)


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
		var orbit_radius: float = float(runtime.orbit_radius) * maxf(0.45, 1.0 + bonus_summon_orbit_radius_multiplier)
		var offset = Vector2.RIGHT.rotated(drone_angles[i]) * orbit_radius
		drone.global_position = global_position + offset
		_update_drone_contact_damage(i, runtime, maxf(8.0, DRONE_CONTACT_RADIUS * maxf(0.45, 1.0 + bonus_summon_contact_radius_multiplier)))


func _update_drone_contact_damage(drone_index: int, runtime, contact_radius: float) -> void:
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
	for enemy_node in _query_enemy_nodes(drone.global_position, contact_radius + 6.0, 10, false):
		if enemy_node == null or not is_instance_valid(enemy_node):
			continue
		if enemy_node.global_position.distance_to(drone.global_position) > contact_radius:
			continue
		var incoming_damage := 8.0
		var enemy_contact_damage_variant: Variant = enemy_node.get("contact_damage")
		if enemy_contact_damage_variant != null:
			incoming_damage = maxf(1.0, float(enemy_contact_damage_variant) * 0.45)
		var taken_damage := get_summon_damage_taken(incoming_damage)
		drone_hitpoints[drone_index] = maxf(0.0, float(drone_hitpoints[drone_index]) - taken_damage)
		drone_contact_cooldowns[drone_index] = 0.55
		_apply_damage_to_enemy(enemy_node, runtime.damage * 0.35, runtime, Vector2.ZERO, 1)
		if bonus_summon_hit_noise_refund > 0.0:
			noise = maxf(noise_min, noise - bonus_summon_hit_noise_refund)
		FeedbackBus.emit_hit(drone.global_position, 0.14, false)
		break


func get_summon_damage_taken(raw_damage: float) -> float:
	var resistance := clampf(bonus_summon_resistance, 0.0, 0.85)
	return maxf(0.0, raw_damage * (1.0 - resistance))


func _has_active_summon_guard() -> bool:
	if bonus_summon_guard_damage_reduction <= 0.0:
		return false
	for i in range(drone_nodes.size()):
		var drone := drone_nodes[i]
		if drone == null or not is_instance_valid(drone) or not drone.visible:
			continue
		if i < drone_respawn_timers.size() and float(drone_respawn_timers[i]) > 0.0:
			continue
		if i < drone_hitpoints.size() and float(drone_hitpoints[i]) <= 0.0:
			continue
		return true
	return false


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
	var final_damage := maxf(0.0, amount)
	if _has_active_summon_guard():
		final_damage *= 1.0 - clampf(bonus_summon_guard_damage_reduction, 0.0, 0.70)
	hp -= final_damage
	invuln_remaining = 0.35
	emit_stats_changed()
	if hp <= 0.0:
		hp = 0.0
		emit_stats_changed()
		died.emit()


func gain_xp(amount: int) -> void:
	xp += float(amount) * xp_gain_mult * environment_xp_gain_multiplier
	xp = maxf(0.0, xp)
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
		"force_route_core_offer": true,
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
		"low_noise_attack_speed_mult":
			bonus_low_noise_attack_speed_multiplier += float(value)
		"high_noise_damage_mult":
			bonus_high_noise_damage_multiplier += float(value)
		"high_noise_attack_speed_mult":
			bonus_high_noise_attack_speed_multiplier += float(value)
		"pickup_radius_mult":
			bonus_pickup_radius_multiplier += float(value)
		"summon_cap_bonus":
			character_summon_cap_bonus += int(value)
		"summon_resistance":
			bonus_summon_resistance += float(value)
		"summon_contact_radius_mult":
			bonus_summon_contact_radius_multiplier += float(value)
		"summon_orbit_radius_mult":
			bonus_summon_orbit_radius_multiplier += float(value)
		"summon_hit_noise_refund":
			bonus_summon_hit_noise_refund += float(value)
		"summon_guard_damage_reduction":
			bonus_summon_guard_damage_reduction += float(value)
		"kill_noise_refund":
			bonus_kill_noise_refund += float(value)
		"kill_attack_cd_refund":
			bonus_kill_attack_cooldown_refund += float(value)
		"kill_skill_cd_refund":
			bonus_kill_skill_cooldown_refund += float(value)
		"flare_noise_spike_mult":
			bonus_flare_noise_spike_multiplier += float(value)
		"flare_visibility_grace_mult":
			bonus_flare_visibility_grace_multiplier += float(value)
		"flare_overdrive_duration":
			bonus_flare_overdrive_duration += float(value)
		"flare_overdrive_attack_speed_mult":
			bonus_flare_overdrive_attack_speed_multiplier += float(value)
		"flare_overdrive_damage_mult":
			bonus_flare_overdrive_damage_multiplier += float(value)
		"darkness_noise_decay_boost":
			bonus_darkness_noise_decay_boost += float(value)
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
	environment_sonar_radius_multiplier = maxf(0.05, float(sonar_modifiers.get("max_radius_mult", 1.0)))
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
	if noise >= HIGH_NOISE_THRESHOLD and bonus_high_noise_damage_multiplier > 0.0:
		effective_damage_mult *= (1.0 + bonus_high_noise_damage_multiplier)
	if flare_overdrive_remaining > 0.0 and bonus_flare_overdrive_damage_multiplier > 0.0:
		effective_damage_mult *= (1.0 + bonus_flare_overdrive_damage_multiplier)
	if noise <= LOW_NOISE_THRESHOLD:
		effective_damage_mult *= contract_low_noise_damage_multiplier
	elif noise >= HIGH_NOISE_THRESHOLD:
		effective_damage_mult *= contract_high_noise_damage_multiplier

	var effective_attack_speed_mult: float = attack_speed_mult
	if noise <= LOW_NOISE_THRESHOLD and bonus_low_noise_attack_speed_multiplier > 0.0:
		effective_attack_speed_mult *= (1.0 + bonus_low_noise_attack_speed_multiplier)
	if noise >= HIGH_NOISE_THRESHOLD and bonus_high_noise_attack_speed_multiplier > 0.0:
		effective_attack_speed_mult *= (1.0 + bonus_high_noise_attack_speed_multiplier)
	if flare_overdrive_remaining > 0.0 and bonus_flare_overdrive_attack_speed_multiplier > 0.0:
		effective_attack_speed_mult *= (1.0 + bonus_flare_overdrive_attack_speed_multiplier)

	var global_modifiers = {
		"damage_mult": maxf(0.1, effective_damage_mult),
		"attack_speed_mult": maxf(0.1, effective_attack_speed_mult),
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


func _build_signature_context_from_runtime(runtime, hit_origin: Vector2 = Vector2.ZERO) -> Dictionary:
	if runtime == null:
		return {}
	var visibility_accuracy_mult := _get_visibility_accuracy_multiplier()
	return {
		"weapon_id": String(runtime.weapon_id),
		"attack_model": String(runtime.attack_model),
		"weapon_range": float(runtime.range),
		"weapon_attack_interval": float(runtime.attack_interval),
		"hit_origin": hit_origin,
		"weapon_tags": runtime.tags.duplicate(),
		"signature_mode": String(runtime.signature_mode),
		"signature_power": float(runtime.signature_power),
		"signature_aux": float(runtime.signature_aux),
		"signature_cycle": int(runtime.signature_cycle),
		"signature_duration": float(runtime.signature_duration),
		"conditional_triggers": runtime.conditional_triggers.duplicate(true),
		"precision_bonus": clampf((0.72 - recoil_heat) * 0.045, 0.0, 0.04) * visibility_accuracy_mult
	}


func _get_target_health_ratio(target: Node) -> float:
	if target == null:
		return 1.0
	var hp_variant: Variant = target.get("hp")
	var max_hp_variant: Variant = target.get("max_hp")
	if hp_variant == null or max_hp_variant == null:
		return 1.0
	var max_hp_value := maxf(0.001, float(max_hp_variant))
	return clampf(float(hp_variant) / max_hp_value, 0.0, 1.0)


func _get_enemy_density(center: Vector2, radius: float) -> int:
	if radius <= 0.0:
		return 0
	return _query_enemy_nodes(center, radius, 16, false).size()


func _increment_weapon_hit_counter(weapon_id: String) -> int:
	var key := weapon_id.strip_edges().to_lower()
	if key.is_empty():
		return 0
	var next_value := int(weapon_hit_counters.get(key, 0)) + 1
	weapon_hit_counters[key] = next_value
	return next_value


func _get_mark_stack(weapon_id: String, target: Node) -> int:
	if target == null or not is_instance_valid(target):
		return 0
	var key := weapon_id.strip_edges().to_lower()
	if key.is_empty():
		return 0
	var instance_id := int(target.get_instance_id())
	var bucket_variant: Variant = weapon_signature_marks.get(key, {})
	if not (bucket_variant is Dictionary):
		return 0
	var bucket: Dictionary = bucket_variant
	if not bucket.has(instance_id):
		return 0
	var row_variant: Variant = bucket.get(instance_id, {})
	if not (row_variant is Dictionary):
		return 0
	var row: Dictionary = row_variant
	var now_sec := float(Time.get_ticks_msec()) * 0.001
	if now_sec > float(row.get("expire_at", 0.0)):
		bucket.erase(instance_id)
		weapon_signature_marks[key] = bucket
		return 0
	return maxi(0, int(row.get("stacks", 0)))


func _push_mark_stack(weapon_id: String, target: Node, max_stacks: int, duration: float) -> void:
	if target == null or not is_instance_valid(target):
		return
	var key := weapon_id.strip_edges().to_lower()
	if key.is_empty():
		return
	var instance_id := int(target.get_instance_id())
	var bucket_variant: Variant = weapon_signature_marks.get(key, {})
	var bucket: Dictionary = bucket_variant.duplicate(true) if bucket_variant is Dictionary else {}
	var now_sec := float(Time.get_ticks_msec()) * 0.001
	var current_stack := 0
	if bucket.has(instance_id):
		var row_variant: Variant = bucket.get(instance_id, {})
		if row_variant is Dictionary:
			var row: Dictionary = row_variant
			if now_sec <= float(row.get("expire_at", 0.0)):
				current_stack = maxi(0, int(row.get("stacks", 0)))
	var next_stack := clampi(current_stack + 1, 1, maxi(1, max_stacks))
	bucket[instance_id] = {
		"stacks": next_stack,
		"expire_at": now_sec + maxf(0.2, duration)
	}
	weapon_signature_marks[key] = bucket


func _normalize_tag_array(tags_variant: Variant) -> Array[String]:
	var tags: Array[String] = []
	if not (tags_variant is Array):
		return tags
	for item in (tags_variant as Array):
		var tag := String(item).strip_edges().to_lower()
		if tag.is_empty() or tags.has(tag):
			continue
		tags.append(tag)
	return tags


func compute_hit_payload(
	target: Node,
	base_damage: float,
	crit_chance: float,
	crit_multiplier: float,
	context: Dictionary = {}
) -> Dictionary:
	var damage_value = compute_damage_against(target, base_damage)
	var weapon_id := String(context.get("weapon_id", "")).strip_edges().to_lower()
	var attack_model := String(context.get("attack_model", "")).strip_edges().to_lower()
	var signature_mode := String(context.get("signature_mode", "")).strip_edges().to_lower()
	var signature_power := float(context.get("signature_power", 0.0))
	var signature_aux := float(context.get("signature_aux", 0.0))
	var signature_cycle := maxi(0, int(context.get("signature_cycle", 0)))
	var signature_duration := maxf(0.0, float(context.get("signature_duration", 0.0)))
	var weapon_tags := _normalize_tag_array(context.get("weapon_tags", []))
	var precision_bonus := clampf(float(context.get("precision_bonus", 0.0)), 0.0, 0.1)
	var weapon_attack_interval := maxf(0.02, float(context.get("weapon_attack_interval", 0.12)))
	var weapon_range := maxf(1.0, float(context.get("weapon_range", 1.0)))
	var hit_origin := Vector2(context.get("hit_origin", global_position))
	var conditional_triggers := _resolve_weapon_conditional_triggers(context, weapon_id)
	var distance_ratio := 0.0
	if target != null and is_instance_valid(target) and target is Node2D:
		distance_ratio = clampf((target as Node2D).global_position.distance_to(hit_origin) / weapon_range, 0.0, 1.0)
	var target_hp_ratio := _get_target_health_ratio(target)
	var sample_position := hit_origin
	if target != null and is_instance_valid(target) and target is Node2D:
		sample_position = (target as Node2D).global_position
	var light_ratio := _estimate_light_ratio_for_position(sample_position)
	var trigger_crit_bonus := 0.0
	var trigger_attack_rate_mult_total := 0.0

	match signature_mode:
		"execution":
			var threshold := clampf(signature_aux, 0.05, 0.95)
			if target_hp_ratio <= threshold:
				damage_value *= 1.0 + maxf(0.0, signature_power)
		"vanguard":
			var near_factor := 1.0 - distance_ratio
			damage_value *= 1.0 + maxf(0.0, signature_power) * near_factor
		"sniper":
			damage_value *= 1.0 + maxf(0.0, signature_power) * distance_ratio
		"noise_drive":
			var noise_norm := clampf(noise / maxf(1.0, noise_max), 0.0, 1.0)
			damage_value *= 1.0 + maxf(0.0, signature_power) * noise_norm
		"silence_focus":
			var quiet_norm := 1.0 - clampf(noise / maxf(1.0, noise_max), 0.0, 1.0)
			damage_value *= 1.0 + maxf(0.0, signature_power) * quiet_norm
		"reveal_hunter":
			if target != null and target.has_method("is_revealed") and bool(target.is_revealed()):
				damage_value *= 1.0 + maxf(0.0, signature_power)
		"shield_breaker":
			if target != null:
				var shield_variant: Variant = target.get("shield_hp")
				if shield_variant != null and float(shield_variant) > 0.0:
					damage_value *= 1.0 + maxf(0.0, signature_power)
		"swarm_breaker":
			if target != null and target is Node2D:
				var radius := maxf(60.0, signature_aux)
				var density := maxi(0, _get_enemy_density((target as Node2D).global_position, radius) - 1)
				damage_value *= 1.0 + minf(maxf(0.0, signature_power), float(density) * maxf(0.0, signature_power) * 0.35)
		"mark_burst":
			var stacks := _get_mark_stack(weapon_id, target)
			if stacks > 0:
				damage_value *= 1.0 + float(stacks) * maxf(0.0, signature_power)
		"elite_bane":
			if target != null and (target.is_in_group("elite") or attack_model == "beam"):
				damage_value *= 1.0 + maxf(0.0, signature_power)
		_:
			pass

	for trigger in conditional_triggers:
		var trigger_id := String(trigger.get("id", "")).strip_edges().to_lower()
		match trigger_id:
			"backstab_bonus":
				var dot_threshold := float(trigger.get("dot_threshold", WEAPON_TRIGGER_BACKSTAB_DOT_DEFAULT))
				if _is_backstab_hit(target, hit_origin, dot_threshold):
					damage_value *= 1.0 + maxf(0.0, float(trigger.get("damage_mult", 0.0)))
					trigger_crit_bonus += maxf(0.0, float(trigger.get("crit_chance_add", 0.0)))
			"light_zone_bonus":
				var min_light := float(trigger.get("min_light_ratio", WEAPON_TRIGGER_LIGHT_MIN_DEFAULT))
				if light_ratio >= min_light:
					damage_value *= 1.0 + maxf(0.0, float(trigger.get("damage_mult", 0.0)))
					trigger_crit_bonus += maxf(0.0, float(trigger.get("crit_chance_add", 0.0)))
					trigger_attack_rate_mult_total += maxf(0.0, float(trigger.get("attack_rate_mult", 0.0)))
			"dark_zone_bonus":
				var max_light := float(trigger.get("max_light_ratio", WEAPON_TRIGGER_DARK_MAX_DEFAULT))
				if light_ratio <= max_light:
					damage_value *= 1.0 + maxf(0.0, float(trigger.get("damage_mult", 0.0)))
					var dark_crit_mult_add := maxf(0.0, float(trigger.get("crit_multiplier_add", 0.0)))
					if dark_crit_mult_add > 0.0:
						crit_multiplier += dark_crit_mult_add
			_:
				pass

	var final_crit_chance = clampf(crit_chance + precision_bonus + trigger_crit_bonus, 0.0, 0.95)
	var crit = rng.randf() <= final_crit_chance
	if crit:
		damage_value *= maxf(1.0, crit_multiplier)
	return {
		"damage": damage_value,
		"crit": crit,
		"weapon_id": weapon_id,
		"attack_model": attack_model,
		"signature_mode": signature_mode,
		"signature_power": signature_power,
		"signature_aux": signature_aux,
		"signature_cycle": signature_cycle,
		"signature_duration": signature_duration,
		"weapon_tags": weapon_tags,
		"weapon_attack_interval": weapon_attack_interval,
		"conditional_triggers": conditional_triggers.duplicate(true),
		"conditional_light_ratio": light_ratio,
		"conditional_attack_rate_mult_total": trigger_attack_rate_mult_total
	}


func _handle_signature_post_hit(
	target: Node,
	final_damage: float,
	is_crit: bool,
	killed: bool,
	payload: Dictionary,
	impact_position: Vector2
) -> void:
	if target == null or not is_instance_valid(target):
		return
	var weapon_id := String(payload.get("weapon_id", "")).strip_edges().to_lower()
	var mode := String(payload.get("signature_mode", "")).strip_edges().to_lower()
	var power := float(payload.get("signature_power", 0.0))
	var aux := float(payload.get("signature_aux", 0.0))
	var cycle := maxi(0, int(payload.get("signature_cycle", 0)))
	var duration := maxf(0.0, float(payload.get("signature_duration", 0.0)))
	_apply_tag_combat_proc(target, final_damage, is_crit, payload, impact_position)
	_apply_conditional_trigger_post_hit(payload, killed)
	if killed:
		if bonus_kill_attack_cooldown_refund > 0.0:
			attack_cd_remaining = maxf(0.0, attack_cd_remaining - clampf(bonus_kill_attack_cooldown_refund, 0.0, 1.8))
		if bonus_kill_skill_cooldown_refund > 0.0:
			skill_cd_remaining = maxf(0.0, skill_cd_remaining - clampf(bonus_kill_skill_cooldown_refund, 0.0, 2.8))
		if bonus_kill_noise_refund > 0.0:
			noise = maxf(noise_min, noise - clampf(bonus_kill_noise_refund, 0.0, 24.0))
	if mode.is_empty():
		return

	match mode:
		"mark_burst":
			_push_mark_stack(weapon_id, target, maxi(1, cycle), maxf(0.6, duration))
		"reveal_hunter":
			if target.has_method("set_revealed") and duration > 0.0:
				target.set_revealed(duration * maxf(0.2, power))
		"crit_echo":
			var proc_chance := clampf(aux, 0.0, 1.0)
			if is_crit and proc_chance > 0.0 and rng.randf() <= proc_chance and target.has_method("take_hit"):
				var echo_damage := maxf(0.5, final_damage * maxf(0.1, power))
				var echo_kill := bool(target.take_hit(echo_damage, Vector2.ZERO))
				if target is Node2D:
					FeedbackBus.emit_hit((target as Node2D).global_position, clampf(echo_damage / 45.0, 0.06, 0.22), echo_kill)
		"finisher_cycle":
			if cycle <= 0:
				return
			var hit_idx := _increment_weapon_hit_counter(weapon_id)
			if hit_idx <= 0 or hit_idx % cycle != 0:
				return
			var blast_radius := maxf(64.0, aux)
			var splash_damage := maxf(0.5, final_damage * maxf(0.15, power))
			FeedbackBus.emit_sonar_pulse(impact_position, {
				"source": "hit",
				"strength": clampf(0.45 + power * 0.4, 0.2, 2.0),
				"radius_scale": clampf(blast_radius / 220.0, 0.5, 2.4),
				"reveal_duration_multiplier": get_sonar_reveal_duration_multiplier()
			})
			for enemy_node in _query_enemy_nodes(impact_position, blast_radius, 12, false):
				if enemy_node == null or not is_instance_valid(enemy_node) or enemy_node == target:
					continue
				if enemy_node.global_position.distance_to(impact_position) > blast_radius:
					continue
				if not enemy_node.has_method("take_hit"):
					continue
				var splash_kill := bool(enemy_node.take_hit(splash_damage, Vector2.ZERO))
				FeedbackBus.emit_hit(enemy_node.global_position, clampf(splash_damage / 52.0, 0.05, 0.24), splash_kill)
		"kill_reset":
			if killed:
				attack_cd_remaining = maxf(0.0, attack_cd_remaining - clampf(power, 0.02, 0.8))
		"xp_echo":
			if killed:
				gain_xp(int(round(clampf(power, 0.0, 12.0))))
		"skill_cool":
			if is_crit:
				skill_cd_remaining = maxf(0.0, skill_cd_remaining - clampf(power, 0.02, 1.2))
		_:
			pass


func _apply_conditional_trigger_post_hit(payload: Dictionary, killed: bool) -> void:
	var trigger_rate_mult_total := maxf(0.0, float(payload.get("conditional_attack_rate_mult_total", 0.0)))
	var weapon_attack_interval := maxf(0.02, float(payload.get("weapon_attack_interval", 0.12)))
	if trigger_rate_mult_total > 0.0:
		attack_cd_remaining = maxf(0.0, attack_cd_remaining - (weapon_attack_interval * clampf(trigger_rate_mult_total, 0.0, 1.2)))
	if not killed:
		return
	var conditional_triggers_variant: Variant = payload.get("conditional_triggers", [])
	var conditional_triggers: Array[Dictionary] = WeaponRuntimeClass.normalize_conditional_triggers(conditional_triggers_variant)
	for trigger in conditional_triggers:
		var trigger_id := String(trigger.get("id", "")).strip_edges().to_lower()
		if trigger_id != "kill_refresh":
			continue
		attack_cd_remaining = maxf(
			0.0,
			attack_cd_remaining - clampf(float(trigger.get("cooldown_refund", 0.0)), 0.0, 1.6)
		)
		skill_cd_remaining = maxf(
			0.0,
			skill_cd_remaining - clampf(float(trigger.get("skill_refund", 0.0)), 0.0, 2.8)
		)
		var noise_refund := clampf(float(trigger.get("noise_refund", 0.0)), 0.0, 20.0)
		if noise_refund > 0.0:
			noise = maxf(noise_min, noise - noise_refund)


func _resolve_weapon_conditional_triggers(context: Dictionary, weapon_id: String) -> Array[Dictionary]:
	var raw_from_context := WeaponRuntimeClass.normalize_conditional_triggers(context.get("conditional_triggers", []))
	if not raw_from_context.is_empty():
		return raw_from_context
	if weapon_id == active_weapon_id:
		var runtime = cached_runtime
		if runtime == null:
			runtime = _build_active_weapon_runtime()
			if runtime != null:
				cached_runtime = runtime
		if runtime != null:
			return WeaponRuntimeClass.normalize_conditional_triggers(runtime.conditional_triggers)
	if weapon_id.is_empty():
		return []
	var weapon_def: Dictionary = DataRegistry.get_weapon_runtime(weapon_id)
	return WeaponRuntimeClass.normalize_conditional_triggers(weapon_def.get("conditional_triggers", []))


func _estimate_light_ratio_for_position(world_position: Vector2) -> float:
	var light_ratio := 0.0
	var vision_radius := _get_runtime_vision_radius()
	if vision_radius > 0.0:
		var player_light := 1.0 - clampf(global_position.distance_to(world_position) / vision_radius, 0.0, 1.0)
		light_ratio = maxf(light_ratio, player_light)
	var world_node := get_parent()
	if world_node != null:
		var candles := world_node.get_node_or_null("Terrain/Candles")
		if candles != null:
			for candle_variant in candles.get_children():
				if not (candle_variant is Node2D):
					continue
				var candle_node := candle_variant as Node2D
				var dist := candle_node.global_position.distance_to(world_position)
				if dist > WEAPON_TRIGGER_CANDLE_RADIUS:
					continue
				var candle_light := 1.0 - (dist / WEAPON_TRIGGER_CANDLE_RADIUS)
				light_ratio = maxf(light_ratio, candle_light * 0.96)
	return clampf(light_ratio, 0.0, 1.0)


func _get_runtime_vision_radius() -> float:
	var base_radius := 420.0
	var world_node := get_parent()
	if world_node != null and world_node.has_method("get_effective_fog_config"):
		var fog_variant: Variant = world_node.call("get_effective_fog_config")
		if fog_variant is Dictionary:
			base_radius = maxf(120.0, float((fog_variant as Dictionary).get("vision_radius", 420.0)))
		var flare_variant: Variant = world_node.get("_flare_boost_remaining")
		var flare_remain := float(flare_variant) if flare_variant != null else 0.0
		if flare_remain > 0.0:
			var flare_intensity_variant: Variant = world_node.get("_flare_boost_intensity")
			var flare_intensity := float(flare_intensity_variant) if flare_intensity_variant != null else 1.0
			var intensity_norm := clampf((flare_intensity - FLARE_DECISION_MIN_STRENGTH) / (FLARE_DECISION_MAX_STRENGTH - FLARE_DECISION_MIN_STRENGTH), 0.0, 1.0)
			base_radius *= lerpf(1.30, 1.92, intensity_norm)
	return maxf(120.0, base_radius)


func _is_backstab_hit(target: Node, hit_origin: Vector2, dot_threshold: float) -> bool:
	if target == null or not is_instance_valid(target) or not (target is Node2D):
		return false
	var target_node := target as Node2D
	var to_attacker := hit_origin - target_node.global_position
	if to_attacker.length() <= 0.01:
		to_attacker = global_position - target_node.global_position
	if to_attacker.length() <= 0.01:
		return false
	var attacker_dir := to_attacker.normalized()
	var forward := Vector2.ZERO
	var velocity_variant: Variant = target.get("velocity")
	if velocity_variant is Vector2:
		var velocity := velocity_variant as Vector2
		if velocity.length() > 8.0:
			forward = velocity.normalized()
	if forward.length() <= 0.01:
		var dash_variant: Variant = target.get("dash_direction")
		if dash_variant is Vector2:
			var dash_dir := dash_variant as Vector2
			if dash_dir.length() > 0.01:
				forward = dash_dir.normalized()
	if forward.length() <= 0.01:
		var to_player := global_position - target_node.global_position
		if to_player.length() > 0.01:
			forward = to_player.normalized()
	var facing_dot := forward.dot(attacker_dir)
	return facing_dot <= clampf(dot_threshold, -0.95, 0.35)


func _apply_tag_combat_proc(
	target: Node,
	final_damage: float,
	is_crit: bool,
	payload: Dictionary,
	impact_position: Vector2
) -> void:
	if not is_crit:
		return
	if target == null or not is_instance_valid(target):
		return
	var weapon_tags := _normalize_tag_array(payload.get("weapon_tags", []))
	if weapon_tags.is_empty():
		return
	var power := maxf(0.0, float(payload.get("signature_power", 0.0)))
	var aux := maxf(0.0, float(payload.get("signature_aux", 0.0)))
	var proc_scale := clampf(0.9 + power * 0.35, 0.75, 1.8)
	if weapon_tags.has("heat") and target.has_method("apply_status_effect"):
		var burn_dps := maxf(1.0, final_damage * (0.08 + 0.05 * proc_scale))
		target.apply_status_effect("burn", 1.9 + (0.4 * proc_scale), burn_dps)
	if weapon_tags.has("silence"):
		if target.has_method("apply_status_effect"):
			target.apply_status_effect("chill", 1.2 + (0.4 * proc_scale), 0.20 + (0.10 * proc_scale))
		if target.has_method("set_revealed"):
			target.set_revealed(0.8 + (0.55 * proc_scale))
	if weapon_tags.has("chain") and rng.randf() <= clampf(0.26 + 0.08 * proc_scale, 0.0, 0.6):
		_emit_tag_chain_arc(target, final_damage * (0.28 + 0.08 * proc_scale))
	if weapon_tags.has("aoe") and rng.randf() <= clampf(0.18 + 0.05 * proc_scale, 0.0, 0.55):
		var blast_radius := clampf(88.0 + aux * 0.1, 80.0, 220.0)
		var splash_damage := maxf(0.5, final_damage * (0.16 + 0.08 * proc_scale))
		_emit_tag_aoe_splash(target, splash_damage, blast_radius, impact_position)


func _emit_tag_chain_arc(source_target: Node, arc_damage: float) -> void:
	if source_target == null or not is_instance_valid(source_target):
		return
	if not (source_target is Node2D):
		return
	var source_node := source_target as Node2D
	var visited := {int(source_node.get_instance_id()): true}
	var chain_target := _pick_beam_chain_target(source_node.global_position, 190.0, visited)
	if chain_target == null or not is_instance_valid(chain_target):
		return
	if not chain_target.has_method("take_hit"):
		return
	var killed := bool(chain_target.take_hit(maxf(0.4, arc_damage), Vector2.ZERO))
	if chain_target.has_method("apply_status_effect"):
		chain_target.apply_status_effect("shock", 0.65, 0.3)
	FeedbackBus.emit_sonar_pulse(source_node.global_position, {
		"source": "hit",
		"strength": 0.42,
		"radius_scale": 0.82,
		"reveal_duration_multiplier": get_sonar_reveal_duration_multiplier()
	})
	FeedbackBus.emit_hit(chain_target.global_position, clampf(arc_damage / 56.0, 0.04, 0.22), killed)


func _emit_tag_aoe_splash(primary_target: Node, splash_damage: float, radius: float, impact_position: Vector2) -> void:
	FeedbackBus.emit_sonar_pulse(impact_position, {
		"source": "hit",
		"strength": 0.36,
		"radius_scale": clampf(radius / 180.0, 0.4, 1.6),
		"reveal_duration_multiplier": get_sonar_reveal_duration_multiplier()
	})
	var hit_budget := 5
	for enemy_node in _query_enemy_nodes(impact_position, radius, 12, false):
		if hit_budget <= 0:
			break
		if enemy_node == null or not is_instance_valid(enemy_node):
			continue
		if enemy_node == primary_target:
			continue
		if enemy_node.global_position.distance_to(impact_position) > radius:
			continue
		if not enemy_node.has_method("take_hit"):
			continue
		var push := (enemy_node.global_position - impact_position).normalized() * 80.0
		var killed := bool(enemy_node.take_hit(maxf(0.4, splash_damage), push))
		if enemy_node.has_method("apply_status_effect"):
			enemy_node.apply_status_effect("shock", 0.45, 0.22)
		FeedbackBus.emit_hit(enemy_node.global_position, clampf(splash_damage / 60.0, 0.04, 0.20), killed)
		hit_budget -= 1


func on_projectile_hit(
	target: Node,
	final_damage: float,
	is_crit: bool,
	killed: bool,
	payload: Dictionary,
	impact_position: Vector2
) -> void:
	_handle_signature_post_hit(target, final_damage, is_crit, killed, payload, impact_position)


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
			"weapon_recoil_heat": recoil_heat,
			"weapon_precision_bonus": last_shot_precision_bonus,
			"darkness_pressure": _get_darkness_pressure_ratio(),
			"visibility_penalty_multiplier": get_visibility_penalty_multiplier(),
			"last_flare_strength": last_flare_strength,
			"flare_visibility_grace_remaining": flare_visibility_grace_remaining,
			"flare_exposure_surge_remaining": flare_exposure_surge_remaining,
			"flare_overdrive_remaining": flare_overdrive_remaining,
			"target_query_count_per_sec": target_query_count_per_sec,
		"target_query_total": target_query_total,
		"chain_enabled": bool(chain_params.get("enabled", false)),
		"chain_chance": float(chain_params.get("chance", 0.0)),
		"chain_max_hops": int(chain_params.get("max_hops", 0)),
		"summon_resistance": bonus_summon_resistance,
		"env_noise_gain_multiplier": environment_noise_gain_multiplier,
		"env_noise_decay_multiplier": environment_noise_decay_multiplier,
		"env_sonar_reveal_multiplier": environment_sonar_reveal_multiplier,
		"env_sonar_radius_multiplier": environment_sonar_radius_multiplier,
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
