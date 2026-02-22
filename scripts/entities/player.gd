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
const NOISE_DECAY_PER_SECOND := 4.5

var enemy_manager: Node
var projectile_manager: Node
var rng := RandomNumberGenerator.new()

var max_hp := 100.0
var hp := 100.0
var xp := 0.0
var xp_to_next := 20.0
var level := 1
var noise := 0.0

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
var active_weapon_id := "pulse_emitter"


func _ready() -> void:
	add_to_group("player")
	emit_stats_changed()


func setup(enemy_manager_ref: Node, projectile_manager_ref: Node, run_rng: RandomNumberGenerator) -> void:
	enemy_manager = enemy_manager_ref
	projectile_manager = projectile_manager_ref
	if run_rng != null:
		rng = run_rng


func _physics_process(delta: float) -> void:
	invuln_remaining = max(0.0, invuln_remaining - delta)
	dash_cd_remaining = max(0.0, dash_cd_remaining - delta)
	attack_cd_remaining = max(0.0, attack_cd_remaining - delta)
	dash_time_remaining = max(0.0, dash_time_remaining - delta)

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
		_add_noise(6.0)

	if dash_time_remaining > 0.0:
		velocity = dash_direction * BASE_DASH_SPEED
	else:
		velocity = input_direction * (BASE_MOVE_SPEED + move_speed_bonus)
	move_and_slide()

	if attack_cd_remaining <= 0.0:
		_attempt_fire()

	noise = max(0.0, noise - NOISE_DECAY_PER_SECOND * delta)


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
	var base_cooldown := float(weapon.get("cooldown", 0.5))
	attack_cd_remaining = max(0.06, base_cooldown / max(0.1, attack_speed_mult))
	_add_noise(float(weapon.get("noise", 3.0)))


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
			"range": float(weapon.get("range", 650.0)),
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
	var options := DataRegistry.get_upgrade_choices(rng, upgrade_stacks, 3)
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
	return BASE_DASH_COOLDOWN * (1.0 - dash_cooldown_reduction)


func _add_noise(amount: float) -> void:
	noise = clamp(noise + (amount * noise_generation_mult), 0.0, 100.0)


func get_hud_data() -> Dictionary:
	return {
		"hp": hp,
		"max_hp": max_hp,
		"xp": xp,
		"xp_to_next": xp_to_next,
		"level": level,
		"noise": noise,
		"dash_cd": dash_cd_remaining,
		"attack_mode": "AUTO" if auto_attack else "AIM"
	}


func emit_stats_changed() -> void:
	stats_changed.emit(get_hud_data())
