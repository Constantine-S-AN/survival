extends CharacterBody2D
class_name Player

signal died
signal stats_changed(stats: Dictionary)
signal level_up_requested(options: Array)
signal attack_mode_changed(is_auto: bool)

const BASE_MOVE_SPEED := 240.0
const BASE_DASH_SPEED := 820.0
const DASH_DURATION := 0.14
const BASE_DASH_COOLDOWN := 2.2
const BASE_MAX_HP := 100.0
const BASE_XP_TO_NEXT := 20.0
const BASE_ACTIVE_WEAPON_ID := "needle_rifle"

var enemy_manager: Node
var projectile_manager: Node
var rng := RandomNumberGenerator.new()

var max_hp := 100.0
var hp := 100.0
var xp := 0.0
var xp_to_next := 20.0
var level := 1
var noise := 0.0
var noise_min := 0.0
var noise_max := 100.0
var noise_decay_per_second := 4.5
var noise_sources: Dictionary = {
	"attack": 1.2,
	"attack_weapon_scale": 0.7,
	"dash": 6.0,
	"skill": 13.0
}

var damage_mult := 1.0
var attack_speed_mult := 1.0
var projectile_speed_mult := 1.0
var projectile_count_bonus := 0
var pierce_bonus := 0
var move_speed_bonus := 0.0
var dash_cooldown_reduction := 0.0
var regen_per_second := 0.0
var xp_gain_mult := 1.0
var noise_generation_mult := 1.0
var sonar_silence_synergy_bonus := 0.0

var upgrade_stacks: Dictionary = {}
var acquired_tags: Dictionary = {}
var pending_level_ups := 0
var level_up_open := false

var dash_cd_remaining := 0.0
var dash_time_remaining := 0.0
var dash_direction := Vector2.RIGHT
var last_move_direction := Vector2.RIGHT
var attack_cd_remaining := 0.0
var invuln_remaining := 0.0
var auto_attack := true
var active_weapon_id := BASE_ACTIVE_WEAPON_ID
var skill_cd_remaining := 0.0
var skill_cooldown := 8.0
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
var character_chain_bonus: float = 0.0 # TODO: Hook once chain damage system exists.
var character_crit_chance_bonus: float = 0.0 # TODO: Hook once crit system exists.
var character_summon_cap_bonus: int = 0 # TODO: Hook once summon cap system exists.


func _ready() -> void:
	add_to_group("player")
	emit_stats_changed()


func setup(enemy_manager_ref: Node, projectile_manager_ref: Node, run_rng: RandomNumberGenerator, character_def: Dictionary = {}) -> void:
	enemy_manager = enemy_manager_ref
	projectile_manager = projectile_manager_ref
	if run_rng != null:
		rng = run_rng
	_reset_run_stats()
	apply_noise_config(DataRegistry.get_noise_config())
	apply_character(character_def)
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
	active_weapon_id = BASE_ACTIVE_WEAPON_ID
	skill_cd_remaining = 0.0
	skill_cooldown = 8.0
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
	var hp_mult := float(modifiers.get("max_hp_multiplier", 1.0))
	var hp_bonus := float(modifiers.get("max_hp_bonus", 0.0))
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

	var starting_weapon_id := String(effective_def.get("starting_weapon_id", BASE_ACTIVE_WEAPON_ID))
	if not DataRegistry.get_weapon(starting_weapon_id).is_empty():
		active_weapon_id = starting_weapon_id
	else:
		active_weapon_id = BASE_ACTIVE_WEAPON_ID


func get_pickup_radius_multiplier() -> float:
	return character_pickup_radius_multiplier


func get_sonar_reveal_duration_multiplier() -> float:
	return character_sonar_reveal_duration_multiplier


func get_character_tag_weights() -> Dictionary:
	return character_tag_weights.duplicate(true)


func _physics_process(delta: float) -> void:
	invuln_remaining = max(0.0, invuln_remaining - delta)
	dash_cd_remaining = max(0.0, dash_cd_remaining - delta)
	attack_cd_remaining = max(0.0, attack_cd_remaining - delta)
	dash_time_remaining = max(0.0, dash_time_remaining - delta)
	skill_cd_remaining = max(0.0, skill_cd_remaining - delta)

	if regen_per_second > 0.0 and hp > 0.0:
		hp = min(max_hp, hp + regen_per_second * delta)

	if Input.is_action_just_pressed("toggle_attack_mode"):
		auto_attack = not auto_attack
		attack_mode_changed.emit(auto_attack)

	var input_direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if input_direction.length() > 0.01:
		last_move_direction = input_direction.normalized()

	if Input.is_action_just_pressed("dash") and dash_cd_remaining <= 0.0:
		dash_direction = last_move_direction if last_move_direction.length() > 0.01 else Vector2.RIGHT
		dash_time_remaining = DASH_DURATION
		dash_cd_remaining = _current_dash_cooldown()
		_add_noise_source("dash")

	if Input.is_action_just_pressed("sonar_skill") and skill_cd_remaining <= 0.0:
		skill_cd_remaining = skill_cooldown
		_add_noise_source("skill")
		FeedbackBus.emit_sonar_pulse(global_position, {
			"source": "skill",
			"reveal_duration_multiplier": character_sonar_reveal_duration_multiplier
		})

	if dash_time_remaining > 0.0:
		velocity = dash_direction * BASE_DASH_SPEED
	else:
		velocity = input_direction * ((BASE_MOVE_SPEED * character_move_speed_multiplier) + move_speed_bonus)
	move_and_slide()

	if attack_cd_remaining <= 0.0:
		_attempt_fire()

	noise = clampf(noise - noise_decay_per_second * delta, noise_min, noise_max)


func _attempt_fire() -> void:
	if projectile_manager == null:
		return
	var weapon := DataRegistry.get_weapon(active_weapon_id)
	if weapon.is_empty():
		return

	var fire_direction := Vector2.ZERO
	if auto_attack:
		if enemy_manager != null and enemy_manager.has_method("get_priority_target"):
			var target = enemy_manager.get_priority_target(global_position)
			if target != null and is_instance_valid(target):
				fire_direction = (target.global_position - global_position).normalized()
	else:
		fire_direction = (get_global_mouse_position() - global_position).normalized()
		if fire_direction.length() < 0.1:
			fire_direction = Vector2.ZERO

	if fire_direction == Vector2.ZERO:
		return

	_fire_weapon(weapon, fire_direction)
	FeedbackBus.emit_shot(global_position, 0.12)
	var base_cooldown := float(weapon.get("cooldown", 0.5))
	attack_cd_remaining = max(0.06, base_cooldown / max(0.1, attack_speed_mult))
	_add_noise_source("attack", float(weapon.get("noise", 3.0)))


func _fire_weapon(weapon: Dictionary, fire_direction: Vector2) -> void:
	var count: int = 1 + maxi(0, projectile_count_bonus)
	var spread_step := deg_to_rad(8.0)
	var center := (float(count) - 1.0) * 0.5
	for i in range(count):
		var offset := (float(i) - center) * spread_step
		var dir := fire_direction.rotated(offset)
		var projectile_data := {
			"damage": float(weapon.get("damage", 10.0)) * damage_mult * (1.0 + sonar_silence_synergy_bonus),
			"speed": float(weapon.get("projectile_speed", 520.0)) * projectile_speed_mult,
			"range": float(weapon.get("range", 650.0)) * character_projectile_range_multiplier,
			"pierce": int(weapon.get("pierce", 0)) + pierce_bonus,
			"radius": 6.0,
			"tags": weapon.get("tags", [])
		}
		projectile_manager.spawn_projectile(global_position, dir, projectile_data, self)


func take_damage(amount: float) -> void:
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
	xp += float(amount) * xp_gain_mult
	var leveled := false
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
	var upgrade := DataRegistry.get_upgrade(upgrade_id)
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
	level_up_open = false
	pending_level_ups = max(0, pending_level_ups - 1)
	emit_stats_changed()
	_request_upgrade_if_needed()


func _request_upgrade_if_needed() -> void:
	if pending_level_ups <= 0 or level_up_open:
		return
	var options := DataRegistry.get_upgrade_choices(rng, upgrade_stacks, 3, character_tag_weights)
	if options.is_empty():
		pending_level_ups = 0
		level_up_open = false
		return
	level_up_open = true
	level_up_requested.emit(options)


func _apply_effect(effect: Dictionary) -> void:
	var stat := String(effect.get("stat", ""))
	var value: Variant = effect.get("add", 0)
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
		_:
			push_warning("Unknown upgrade effect stat: %s" % stat)


func _recompute_synergies() -> void:
	var sonar_count := int(acquired_tags.get("sonar", 0))
	var silence_count := int(acquired_tags.get("silence", 0))
	if sonar_count >= 2 and silence_count >= 2:
		sonar_silence_synergy_bonus = 0.22
	else:
		sonar_silence_synergy_bonus = 0.0


func _current_dash_cooldown() -> float:
	return maxf(0.12, (BASE_DASH_COOLDOWN * character_dash_cooldown_multiplier) * (1.0 - dash_cooldown_reduction))


func _add_noise(amount: float) -> void:
	noise = clampf(noise + (amount * noise_generation_mult), noise_min, noise_max)


func _add_noise_source(source_key: String, extra: float = 0.0) -> void:
	var base := float(noise_sources.get(source_key, 0.0))
	if source_key == "attack":
		base += extra * float(noise_sources.get("attack_weapon_scale", 0.0))
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


func get_hud_data() -> Dictionary:
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
			"skill_cd": skill_cd_remaining,
			"attack_mode": "AUTO" if auto_attack else "AIM",
			"character_id": character_id,
			"character_name": character_name
		}


func emit_stats_changed() -> void:
	stats_changed.emit(get_hud_data())
