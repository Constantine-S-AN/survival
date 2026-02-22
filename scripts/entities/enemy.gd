extends CharacterBody2D
class_name Enemy

signal died(enemy_id: String, xp_reward: int)
signal summon_requested(enemy_type_id: String, count: int, world_position: Vector2)
signal explosion_requested(world_position: Vector2, radius: float, damage: float, source_enemy_id: String)

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

var boss_phase_id: String = ""
var boss_phase_label: String = ""
var boss_requires_reveal_lock: bool = false
var boss_hidden_damage_multiplier: float = 0.35
var boss_fake_echoes: int = 0
var boss_phase_spawn_rate_mult: float = 1.0
var boss_phase_fog_radius_mult: float = 1.0

@onready var outline_visual: Polygon2D = $Outline
@onready var body_visual: Polygon2D = $Body
@onready var collision_shape: CollisionShape2D = $CollisionShape2D


func setup(new_enemy_id: String, definition: Dictionary, player_target: Node2D, runtime_modifiers: Dictionary = {}) -> void:
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

	# Boss runtime defaults.
	boss_phase_id = ""
	boss_phase_label = ""
	boss_requires_reveal_lock = false
	boss_hidden_damage_multiplier = 0.35
	boss_fake_echoes = 0
	boss_phase_spawn_rate_mult = 1.0
	boss_phase_fog_radius_mult = 1.0
	if behavior == "boss":
		var initial_phase := {}
		if definition.has("initial_phase") and definition.get("initial_phase", null) is Dictionary:
			initial_phase = (definition.get("initial_phase", {}) as Dictionary).duplicate(true)
		apply_boss_phase(initial_phase, definition)

	var color_text := String(definition.get("color", "#38e7ff"))
	body_visual.color = Color.from_string(color_text, Color(0.22, 0.9, 1.0, 1.0))
	outline_visual.color = Color.from_string(color_text, Color(0.22, 0.9, 1.0, 1.0)).lightened(0.45)

	var shape := collision_shape.shape
	if shape is CircleShape2D:
		shape.radius = body_radius
	body_visual.scale = Vector2.ONE * (body_radius / 15.0)
	outline_visual.scale = Vector2.ONE * ((body_radius / 15.0) * 1.24)
	_update_reveal_visual()

	add_to_group("enemy")
	if spawn_group == "pursuer":
		add_to_group("pursuer")
		is_elite = true
		outline_visual.color = Color(1.0, 0.52, 0.66, 0.95)
	if behavior == "boss":
		add_to_group("boss")


func _physics_process(delta: float) -> void:
	if target == null or not is_instance_valid(target):
		return

	contact_timer = maxf(0.0, contact_timer - delta)
	stagger_timer = maxf(0.0, stagger_timer - delta)
	rage_timer = maxf(0.0, rage_timer - delta)
	dash_cooldown_remaining = maxf(0.0, dash_cooldown_remaining - delta)
	dash_windup_remaining = maxf(0.0, dash_windup_remaining - delta)
	dash_active_remaining = maxf(0.0, dash_active_remaining - delta)
	ranged_cooldown_remaining = maxf(0.0, ranged_cooldown_remaining - delta)
	summon_timer = maxf(0.0, summon_timer - delta)

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
		var xp_variant: Variant = target.get("xp")
		if leech_xp_drain > 0 and xp_variant != null:
			var current_xp := float(xp_variant)
			target.set("xp", maxf(0.0, current_xp - float(leech_xp_drain)))
	if elite_xp_siphon_rate > 0.0 and target.has_method("gain_xp"):
		target.gain_xp(int(-elite_xp_siphon_rate))


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
	if split_on_death and not split_into_id.is_empty() and split_count > 0:
		summon_requested.emit(split_into_id, split_count, global_position)
	if behavior == "bloater" and not from_explosion and explode_radius > 0.0 and explode_damage > 0.0:
		explosion_requested.emit(global_position, explode_radius, explode_damage, enemy_id)
	died.emit(enemy_id, xp_reward)
	queue_free()
	return true


func _flash_hit(shield_only: bool) -> void:
	if shield_only:
		body_visual.modulate = Color(0.9, 1.35, 1.6, 1.0)
	else:
		body_visual.modulate = Color(1.6, 1.6, 1.6, 1.0)
	var tween := create_tween()
	tween.tween_property(body_visual, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.08)


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
	_update_reveal_visual()


func is_revealed() -> bool:
	var now_sec := float(Time.get_ticks_msec()) * 0.001
	return now_sec < reveal_until


func _update_reveal_visual() -> void:
	var revealed := is_revealed()
	outline_visual.visible = revealed or shield_hp > 0.0 or is_elite
	if revealed:
		body_visual.modulate = Color(1.12, 1.12, 1.16, 1.0)
	elif shield_hp > 0.0:
		body_visual.modulate = Color(0.85, 1.12, 1.3, 1.0)
	else:
		body_visual.modulate = Color(1.0, 1.0, 1.0, 1.0)


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
	outline_visual.color = Color.from_string(String(affix.get("color", "#ffd37f")), Color(1.0, 0.84, 0.6, 1.0)).lightened(0.25)
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
	if boss_config.has("hidden_damage_multiplier"):
		boss_hidden_damage_multiplier = clampf(float(boss_config.get("hidden_damage_multiplier", boss_hidden_damage_multiplier)), 0.05, 1.0)
	if boss_requires_reveal_lock:
		outline_visual.visible = true


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


func _apply_elite_auras(delta: float) -> void:
	if target == null or not is_instance_valid(target):
		return
	if elite_noise_aura_add > 0.0 and target.has_method("add_noise_delta"):
		target.add_noise_delta(elite_noise_aura_add * delta)
	if elite_xp_siphon_rate > 0.0 and elite_siphon_radius > 0.0:
		if global_position.distance_to(target.global_position) <= elite_siphon_radius:
			var xp_variant: Variant = target.get("xp")
			if xp_variant != null:
				var next_xp := maxf(0.0, float(xp_variant) - elite_xp_siphon_rate * delta)
				target.set("xp", next_xp)


func _apply_boss_aura(delta: float) -> void:
	if target == null or not is_instance_valid(target):
		return
	if boss_requires_reveal_lock:
		target.add_noise_delta(0.8 * delta)
