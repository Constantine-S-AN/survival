extends RefCounted
class_name WeaponRuntime

const DEFAULT_WEAPON_MODIFIER: Dictionary = {
	"weapon_damage_mult": 0.0,
	"weapon_attack_rate_mult": 0.0,
	"weapon_range_mult": 0.0,
	"weapon_projectile_speed_mult": 0.0,
	"weapon_pierce_bonus": 0,
	"weapon_crit_chance_add": 0.0,
	"weapon_crit_multiplier_add": 0.0,
	"weapon_aoe_radius_mult": 0.0,
	"weapon_noise_mult": 0.0,
	"weapon_noise_add": 0.0,
	"weapon_projectile_count_bonus": 0,
	"weapon_reveal_bonus_add": 0.0,
	"weapon_summon_cap_bonus": 0
}

var weapon_id: String = ""
var display_name: String = ""
var description: String = ""
var attack_model: String = "projectile"
var tags: Array[String] = []
var level: int = 1
var max_level: int = 1

var damage: float = 0.0
var attack_rate: float = 1.0
var attack_interval: float = 1.0
var range: float = 0.0
var projectile_speed: float = 0.0
var pierce: int = 0
var crit_chance: float = 0.0
var crit_multiplier: float = 1.5
var aoe_radius: float = 0.0
var noise_per_attack: float = 0.0
var projectile_count: int = 1
var reveal_bonus_duration: float = 0.0
var summon_count: int = 1
var beam_tick_interval: float = 0.16
var orbit_radius: float = 120.0
var sonar_pulse_strength: float = 1.0
var projectile_radius: float = 6.0
var projectile_spread_deg: float = 8.0
var burst_count: int = 1
var burst_interval: float = 0.0
var impact_aoe_radius: float = 0.0
var impact_aoe_damage_mult: float = 0.5
var impact_pulse_strength: float = 0.0
var impact_pulse_radius_scale: float = 0.9
var impact_knockback: float = 180.0
var pulse_repeats: int = 1
var pulse_repeat_interval: float = 0.09
var pulse_falloff: float = 0.82
var beam_chain_targets: int = 0
var beam_chain_falloff: float = 0.6
var mine_shard_count: int = 0
var mine_shard_speed: float = 560.0
var mine_shard_range: float = 300.0
var drone_volley: int = 1
var drone_spread_deg: float = 8.0
var drone_projectile_radius: float = 4.5
var melee_cone_dot: float = 0.35
var fx_color: String = ""
var signature_mode: String = ""
var signature_power: float = 0.0
var signature_aux: float = 0.0
var signature_cycle: int = 0
var signature_duration: float = 0.0
var conditional_triggers: Array[Dictionary] = []


static func from_definition(
	weapon_def: Dictionary,
	weapon_level: int,
	global_modifiers: Dictionary = {},
	modifier_sources: Array = []
) -> Variant:
	var runtime_script: Script = load("res://scripts/weapons/weapon_runtime.gd")
	var runtime = runtime_script.new()
	if weapon_def.is_empty():
		return runtime

	runtime.weapon_id = String(weapon_def.get("id", "")).strip_edges()
	runtime.display_name = String(weapon_def.get("name", runtime.weapon_id))
	runtime.description = String(weapon_def.get("description", ""))
	runtime.attack_model = String(weapon_def.get("attack_model", "projectile"))
	var tags_variant: Variant = weapon_def.get("tags", [])
	if tags_variant is Array:
		for tag_variant in tags_variant:
			var tag := String(tag_variant).strip_edges().to_lower()
			if tag.is_empty() or runtime.tags.has(tag):
				continue
			runtime.tags.append(tag)

	var growth_variant: Variant = weapon_def.get("level_growth", [])
	var growth_rows: Array = growth_variant if growth_variant is Array else []
	runtime.max_level = maxi(1, growth_rows.size())
	runtime.level = clampi(weapon_level, 1, runtime.max_level)
	var growth := _pick_growth_row(growth_rows, runtime.level)

	var base_damage := float(weapon_def.get("base_damage", weapon_def.get("damage", 10.0)))
	var base_attack_rate := float(weapon_def.get("attack_rate", 1.0 / maxf(0.0001, float(weapon_def.get("cooldown", 0.5)))))
	var base_range := float(weapon_def.get("range", 640.0))
	var base_projectile_speed := float(weapon_def.get("projectile_speed", 0.0))
	var base_projectile_count := int(weapon_def.get("projectile_count", 1))
	var base_pierce := int(weapon_def.get("projectile_pierce", weapon_def.get("pierce", 0)))
	var base_crit_chance := float(weapon_def.get("crit_chance", 0.0))
	var base_crit_multiplier := float(weapon_def.get("crit_multiplier", 1.5))
	var base_aoe_radius := float(weapon_def.get("aoe_radius", 0.0))
	var base_noise := float(weapon_def.get("noise_per_attack", weapon_def.get("noise", 2.0)))
	var base_reveal_bonus := float(weapon_def.get("reveal_bonus_duration", 0.0))
	var base_summon_count := int(weapon_def.get("drone_count", 1))
	var base_projectile_radius := float(weapon_def.get("projectile_radius", 6.0))
	var base_projectile_spread_deg := float(weapon_def.get("projectile_spread_deg", 8.0))
	var base_burst_count := int(weapon_def.get("burst_count", 1))
	var base_burst_interval := float(weapon_def.get("burst_interval", 0.0))
	var base_impact_aoe_radius := float(weapon_def.get("impact_aoe_radius", 0.0))
	var base_impact_aoe_damage_mult := float(weapon_def.get("impact_aoe_damage_mult", 0.5))
	var base_impact_pulse_strength := float(weapon_def.get("impact_pulse_strength", 0.0))
	var base_impact_pulse_radius_scale := float(weapon_def.get("impact_pulse_radius_scale", 0.9))
	var base_impact_knockback := float(weapon_def.get("impact_knockback", 180.0))
	var base_pulse_repeats := int(weapon_def.get("pulse_repeats", 1))
	var base_pulse_repeat_interval := float(weapon_def.get("pulse_repeat_interval", 0.09))
	var base_pulse_falloff := float(weapon_def.get("pulse_falloff", 0.82))
	var base_beam_chain_targets := int(weapon_def.get("beam_chain_targets", 0))
	var base_beam_chain_falloff := float(weapon_def.get("beam_chain_falloff", 0.6))
	var base_mine_shard_count := int(weapon_def.get("mine_shard_count", 0))
	var base_mine_shard_speed := float(weapon_def.get("mine_shard_speed", 560.0))
	var base_mine_shard_range := float(weapon_def.get("mine_shard_range", 300.0))
	var base_drone_volley := int(weapon_def.get("drone_volley", 1))
	var base_drone_spread_deg := float(weapon_def.get("drone_spread_deg", 8.0))
	var base_drone_projectile_radius := float(weapon_def.get("drone_projectile_radius", 4.5))
	var base_melee_cone_dot := float(weapon_def.get("melee_cone_dot", 0.35))
	var base_fx_color := String(weapon_def.get("fx_color", ""))
	var base_signature_mode := String(weapon_def.get("signature_mode", "")).strip_edges().to_lower()
	var base_signature_power := float(weapon_def.get("signature_power", 0.0))
	var base_signature_aux := float(weapon_def.get("signature_aux", 0.0))
	var base_signature_cycle := int(weapon_def.get("signature_cycle", 0))
	var base_signature_duration := float(weapon_def.get("signature_duration", 0.0))
	var base_conditional_triggers := normalize_conditional_triggers(weapon_def.get("conditional_triggers", []))

	var growth_damage_mult := float(growth.get("damage_mult", 1.0))
	var growth_attack_rate_mult := float(growth.get("attack_rate_mult", 1.0))
	var growth_range_mult := float(growth.get("range_mult", 1.0))
	var growth_projectile_speed_mult := float(growth.get("projectile_speed_mult", 1.0))
	var growth_pierce_bonus := int(growth.get("pierce_bonus", 0))
	var growth_crit_chance_add := float(growth.get("crit_chance_add", 0.0))
	var growth_crit_multiplier_add := float(growth.get("crit_multiplier_add", 0.0))
	var growth_aoe_mult := float(growth.get("aoe_mult", 1.0))
	var growth_noise_mult := float(growth.get("noise_mult", 1.0))
	var growth_noise_add := float(growth.get("noise_add", 0.0))
	var growth_projectile_count_bonus := int(growth.get("projectile_count_bonus", 0))
	var growth_reveal_bonus := float(growth.get("reveal_bonus", 0.0))
	var growth_drone_count_bonus := int(growth.get("drone_count_bonus", 0))

	runtime.damage = base_damage * growth_damage_mult
	runtime.attack_rate = base_attack_rate * growth_attack_rate_mult
	runtime.range = base_range * growth_range_mult
	runtime.projectile_speed = base_projectile_speed * growth_projectile_speed_mult
	runtime.pierce = base_pierce + growth_pierce_bonus
	runtime.crit_chance = base_crit_chance + growth_crit_chance_add
	runtime.crit_multiplier = base_crit_multiplier + growth_crit_multiplier_add
	runtime.aoe_radius = base_aoe_radius * growth_aoe_mult
	runtime.noise_per_attack = base_noise * growth_noise_mult + growth_noise_add
	runtime.projectile_count = maxi(1, base_projectile_count + growth_projectile_count_bonus)
	runtime.reveal_bonus_duration = base_reveal_bonus + growth_reveal_bonus
	runtime.summon_count = maxi(1, base_summon_count + growth_drone_count_bonus)
	runtime.beam_tick_interval = maxf(0.05, float(weapon_def.get("beam_tick_interval", 1.0 / maxf(0.1, runtime.attack_rate))))
	runtime.orbit_radius = maxf(24.0, float(weapon_def.get("orbit_radius", 120.0)))
	runtime.sonar_pulse_strength = maxf(0.1, float(weapon_def.get("sonar_pulse_strength", 1.0)))
	runtime.projectile_radius = base_projectile_radius
	runtime.projectile_spread_deg = base_projectile_spread_deg
	runtime.burst_count = base_burst_count
	runtime.burst_interval = base_burst_interval
	runtime.impact_aoe_radius = base_impact_aoe_radius
	runtime.impact_aoe_damage_mult = base_impact_aoe_damage_mult
	runtime.impact_pulse_strength = base_impact_pulse_strength
	runtime.impact_pulse_radius_scale = base_impact_pulse_radius_scale
	runtime.impact_knockback = base_impact_knockback
	runtime.pulse_repeats = base_pulse_repeats
	runtime.pulse_repeat_interval = base_pulse_repeat_interval
	runtime.pulse_falloff = base_pulse_falloff
	runtime.beam_chain_targets = base_beam_chain_targets
	runtime.beam_chain_falloff = base_beam_chain_falloff
	runtime.mine_shard_count = base_mine_shard_count
	runtime.mine_shard_speed = base_mine_shard_speed
	runtime.mine_shard_range = base_mine_shard_range
	runtime.drone_volley = base_drone_volley
	runtime.drone_spread_deg = base_drone_spread_deg
	runtime.drone_projectile_radius = base_drone_projectile_radius
	runtime.melee_cone_dot = base_melee_cone_dot
	runtime.fx_color = base_fx_color
	runtime.signature_mode = base_signature_mode
	runtime.signature_power = base_signature_power
	runtime.signature_aux = base_signature_aux
	runtime.signature_cycle = base_signature_cycle
	runtime.signature_duration = base_signature_duration
	runtime.conditional_triggers = base_conditional_triggers.duplicate(true)

	for modifier_variant in modifier_sources:
		if not (modifier_variant is Dictionary):
			continue
		var modifier: Dictionary = _normalized_modifier_bucket(modifier_variant)
		runtime.damage *= maxf(0.05, 1.0 + float(modifier.get("weapon_damage_mult", 0.0)))
		runtime.attack_rate *= maxf(0.05, 1.0 + float(modifier.get("weapon_attack_rate_mult", 0.0)))
		runtime.range *= maxf(0.05, 1.0 + float(modifier.get("weapon_range_mult", 0.0)))
		runtime.projectile_speed *= maxf(0.05, 1.0 + float(modifier.get("weapon_projectile_speed_mult", 0.0)))
		runtime.pierce += int(modifier.get("weapon_pierce_bonus", 0))
		runtime.crit_chance += float(modifier.get("weapon_crit_chance_add", 0.0))
		runtime.crit_multiplier += float(modifier.get("weapon_crit_multiplier_add", 0.0))
		runtime.aoe_radius *= maxf(0.05, 1.0 + float(modifier.get("weapon_aoe_radius_mult", 0.0)))
		runtime.noise_per_attack = (runtime.noise_per_attack * maxf(0.0, 1.0 + float(modifier.get("weapon_noise_mult", 0.0)))) + float(modifier.get("weapon_noise_add", 0.0))
		runtime.projectile_count = maxi(1, runtime.projectile_count + int(modifier.get("weapon_projectile_count_bonus", 0)))
		runtime.reveal_bonus_duration += float(modifier.get("weapon_reveal_bonus_add", 0.0))
		runtime.summon_count = maxi(1, runtime.summon_count + int(modifier.get("weapon_summon_cap_bonus", 0)))

	var global_damage_mult := maxf(0.05, float(global_modifiers.get("damage_mult", 1.0)))
	var global_attack_speed_mult := maxf(0.05, float(global_modifiers.get("attack_speed_mult", 1.0)))
	var global_projectile_speed_mult := maxf(0.05, float(global_modifiers.get("projectile_speed_mult", 1.0)))
	var global_range_mult := maxf(0.05, float(global_modifiers.get("range_mult", 1.0)))
	var global_pierce_bonus := int(global_modifiers.get("pierce_bonus", 0))
	var global_crit_bonus := float(global_modifiers.get("crit_chance_bonus", 0.0))
	var global_projectile_count_bonus := int(global_modifiers.get("projectile_count_bonus", 0))
	var global_summon_bonus := int(global_modifiers.get("summon_cap_bonus", 0))

	runtime.damage *= global_damage_mult
	runtime.attack_rate *= global_attack_speed_mult
	runtime.projectile_speed *= global_projectile_speed_mult
	runtime.range *= global_range_mult
	runtime.pierce += global_pierce_bonus
	runtime.crit_chance += global_crit_bonus
	runtime.projectile_count = maxi(1, runtime.projectile_count + global_projectile_count_bonus)
	runtime.summon_count = maxi(1, runtime.summon_count + global_summon_bonus)
	_apply_balance_tuning(runtime)

	runtime.attack_rate = maxf(0.05, runtime.attack_rate)
	runtime.attack_interval = 1.0 / runtime.attack_rate
	runtime.crit_chance = clampf(runtime.crit_chance, 0.0, 0.95)
	runtime.crit_multiplier = maxf(1.0, runtime.crit_multiplier)
	runtime.range = maxf(8.0, runtime.range)
	runtime.projectile_speed = maxf(0.0, runtime.projectile_speed)
	runtime.aoe_radius = maxf(0.0, runtime.aoe_radius)
	runtime.noise_per_attack = maxf(0.0, runtime.noise_per_attack)
	runtime.projectile_count = clampi(runtime.projectile_count, 1, 12)
	runtime.reveal_bonus_duration = maxf(0.0, runtime.reveal_bonus_duration)
	runtime.projectile_radius = clampf(runtime.projectile_radius, 2.0, 24.0)
	runtime.projectile_spread_deg = clampf(runtime.projectile_spread_deg, 0.0, 40.0)
	runtime.burst_count = clampi(runtime.burst_count, 1, 6)
	runtime.burst_interval = clampf(runtime.burst_interval, 0.0, 0.45)
	runtime.impact_aoe_radius = maxf(0.0, runtime.impact_aoe_radius)
	runtime.impact_aoe_damage_mult = clampf(runtime.impact_aoe_damage_mult, 0.0, 1.6)
	runtime.impact_pulse_strength = maxf(0.0, runtime.impact_pulse_strength)
	runtime.impact_pulse_radius_scale = clampf(runtime.impact_pulse_radius_scale, 0.3, 2.5)
	runtime.impact_knockback = maxf(0.0, runtime.impact_knockback)
	runtime.pulse_repeats = clampi(runtime.pulse_repeats, 1, 4)
	runtime.pulse_repeat_interval = clampf(runtime.pulse_repeat_interval, 0.02, 0.45)
	runtime.pulse_falloff = clampf(runtime.pulse_falloff, 0.2, 1.0)
	runtime.beam_chain_targets = clampi(runtime.beam_chain_targets, 0, 6)
	runtime.beam_chain_falloff = clampf(runtime.beam_chain_falloff, 0.1, 1.0)
	runtime.mine_shard_count = clampi(runtime.mine_shard_count, 0, 24)
	runtime.mine_shard_speed = clampf(runtime.mine_shard_speed, 80.0, 1600.0)
	runtime.mine_shard_range = clampf(runtime.mine_shard_range, 30.0, 1400.0)
	runtime.drone_volley = clampi(runtime.drone_volley, 1, 6)
	runtime.drone_spread_deg = clampf(runtime.drone_spread_deg, 0.0, 35.0)
	runtime.drone_projectile_radius = clampf(runtime.drone_projectile_radius, 2.0, 16.0)
	runtime.melee_cone_dot = clampf(runtime.melee_cone_dot, -1.0, 0.95)
	runtime.signature_power = clampf(runtime.signature_power, -2.0, 5.0)
	runtime.signature_aux = clampf(runtime.signature_aux, 0.0, 3000.0)
	runtime.signature_cycle = clampi(runtime.signature_cycle, 0, 64)
	runtime.signature_duration = clampf(runtime.signature_duration, 0.0, 30.0)
	runtime.conditional_triggers = normalize_conditional_triggers(runtime.conditional_triggers)

	return runtime


func estimate_dps() -> float:
	var crit_factor := 1.0 + (crit_chance * maxf(0.0, crit_multiplier - 1.0))
	return maxf(0.0, damage * attack_rate * crit_factor * float(maxi(1, projectile_count)))


func to_debug_dict() -> Dictionary:
	return {
		"id": weapon_id,
		"name": display_name,
		"model": attack_model,
		"level": level,
		"max_level": max_level,
		"tags": tags.duplicate(),
		"damage": damage,
		"attack_rate": attack_rate,
		"attack_interval": attack_interval,
		"range": range,
		"projectile_speed": projectile_speed,
		"pierce": pierce,
		"crit_chance": crit_chance,
		"crit_multiplier": crit_multiplier,
		"aoe_radius": aoe_radius,
		"noise_per_attack": noise_per_attack,
		"projectile_count": projectile_count,
		"reveal_bonus_duration": reveal_bonus_duration,
		"summon_count": summon_count,
		"beam_tick_interval": beam_tick_interval,
		"orbit_radius": orbit_radius,
		"projectile_radius": projectile_radius,
		"projectile_spread_deg": projectile_spread_deg,
		"burst_count": burst_count,
		"burst_interval": burst_interval,
		"impact_aoe_radius": impact_aoe_radius,
		"impact_aoe_damage_mult": impact_aoe_damage_mult,
		"impact_pulse_strength": impact_pulse_strength,
		"impact_pulse_radius_scale": impact_pulse_radius_scale,
		"impact_knockback": impact_knockback,
		"pulse_repeats": pulse_repeats,
		"pulse_repeat_interval": pulse_repeat_interval,
		"pulse_falloff": pulse_falloff,
		"beam_chain_targets": beam_chain_targets,
		"beam_chain_falloff": beam_chain_falloff,
		"mine_shard_count": mine_shard_count,
		"mine_shard_speed": mine_shard_speed,
		"mine_shard_range": mine_shard_range,
		"drone_volley": drone_volley,
		"drone_spread_deg": drone_spread_deg,
		"drone_projectile_radius": drone_projectile_radius,
		"melee_cone_dot": melee_cone_dot,
		"fx_color": fx_color,
		"signature_mode": signature_mode,
		"signature_power": signature_power,
		"signature_aux": signature_aux,
		"signature_cycle": signature_cycle,
		"signature_duration": signature_duration,
		"conditional_triggers": conditional_triggers.duplicate(true),
		"dps_estimate": estimate_dps()
	}


static func _pick_growth_row(growth_rows: Array, desired_level: int) -> Dictionary:
	if growth_rows.is_empty():
		return {"level": 1, "damage_mult": 1.0, "attack_rate_mult": 1.0}
	var picked: Dictionary = {}
	for row_variant in growth_rows:
		if not (row_variant is Dictionary):
			continue
		var row: Dictionary = row_variant
		if int(row.get("level", 0)) <= desired_level:
			picked = row
	if picked.is_empty():
		var first_variant: Variant = growth_rows[0]
		if first_variant is Dictionary:
			picked = first_variant
	if picked.is_empty():
		picked = {"level": 1, "damage_mult": 1.0, "attack_rate_mult": 1.0}
	return picked


static func _normalized_modifier_bucket(source: Dictionary) -> Dictionary:
	var normalized := DEFAULT_WEAPON_MODIFIER.duplicate(true)
	for key_variant in source.keys():
		var key := String(key_variant)
		if not normalized.has(key):
			continue
		normalized[key] = source.get(key_variant, normalized[key])
	return normalized


static func _apply_balance_tuning(runtime) -> void:
	if runtime == null:
		return
	var packet_pressure := maxf(
		0.1,
		float(runtime.attack_rate) * float(maxi(1, runtime.projectile_count)) * float(maxi(1, runtime.burst_count))
	)
	match String(runtime.attack_model).strip_edges().to_lower():
		"projectile":
			# SK-inspired: very high packet weapons trade consistency for spray pressure.
			var pressure_factor := clampf(pow(11.0 / packet_pressure, 0.24), 0.72, 1.18)
			runtime.damage *= pressure_factor
			var extra_spread := clampf((packet_pressure - 11.0) / 48.0, 0.0, 0.52)
			runtime.projectile_spread_deg *= 1.0 + extra_spread
			if packet_pressure > 13.0:
				runtime.crit_chance -= minf(0.06, (packet_pressure - 13.0) * 0.0025)
			elif packet_pressure < 5.0:
				runtime.crit_chance += minf(0.04, (5.0 - packet_pressure) * 0.008)
		"mine":
			runtime.damage *= 1.16
			runtime.attack_rate *= 1.06
			if runtime.aoe_radius > 0.0:
				runtime.aoe_radius *= 1.10
		"drone":
			runtime.damage *= 1.18
			runtime.attack_rate *= 1.08
		"beam":
			runtime.damage *= 1.22
			runtime.attack_rate *= 1.06
		_:
			pass
	if runtime.tags is Array:
		var tags: Array = runtime.tags
		if tags.has("silence"):
			runtime.noise_per_attack *= 0.88
		if tags.has("crit") and runtime.attack_model == "projectile":
			runtime.crit_chance += 0.015


static func normalize_conditional_triggers(raw_variant: Variant) -> Array[Dictionary]:
	var normalized: Array[Dictionary] = []
	if not (raw_variant is Array):
		return normalized
	var triggers: Array = raw_variant
	for trigger_variant in triggers:
		if not (trigger_variant is Dictionary):
			continue
		var trigger: Dictionary = trigger_variant
		var trigger_id := String(trigger.get("id", "")).strip_edges().to_lower()
		if trigger_id.is_empty():
			continue
		var row := {"id": trigger_id}
		match trigger_id:
			"kill_refresh":
				row["cooldown_refund"] = clampf(float(trigger.get("cooldown_refund", 0.0)), 0.0, 1.6)
				row["skill_refund"] = clampf(float(trigger.get("skill_refund", 0.0)), 0.0, 2.8)
				row["noise_refund"] = clampf(float(trigger.get("noise_refund", 0.0)), 0.0, 20.0)
			"backstab_bonus":
				row["damage_mult"] = clampf(float(trigger.get("damage_mult", 0.0)), 0.0, 2.0)
				row["crit_chance_add"] = clampf(float(trigger.get("crit_chance_add", 0.0)), 0.0, 0.6)
				row["dot_threshold"] = clampf(float(trigger.get("dot_threshold", -0.22)), -0.95, 0.35)
			"light_zone_bonus":
				row["damage_mult"] = clampf(float(trigger.get("damage_mult", 0.0)), 0.0, 2.0)
				row["attack_rate_mult"] = clampf(float(trigger.get("attack_rate_mult", 0.0)), 0.0, 1.2)
				row["crit_chance_add"] = clampf(float(trigger.get("crit_chance_add", 0.0)), 0.0, 0.6)
				row["min_light_ratio"] = clampf(float(trigger.get("min_light_ratio", 0.55)), 0.0, 1.0)
			"dark_zone_bonus":
				row["damage_mult"] = clampf(float(trigger.get("damage_mult", 0.0)), 0.0, 2.0)
				row["crit_multiplier_add"] = clampf(float(trigger.get("crit_multiplier_add", 0.0)), 0.0, 3.0)
				row["max_light_ratio"] = clampf(float(trigger.get("max_light_ratio", 0.35)), 0.0, 1.0)
			_:
				continue
		normalized.append(row)
		if normalized.size() >= 4:
			break
	return normalized
