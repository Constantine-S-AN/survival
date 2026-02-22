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
	var base_pierce := int(weapon_def.get("projectile_pierce", weapon_def.get("pierce", 0)))
	var base_crit_chance := float(weapon_def.get("crit_chance", 0.0))
	var base_crit_multiplier := float(weapon_def.get("crit_multiplier", 1.5))
	var base_aoe_radius := float(weapon_def.get("aoe_radius", 0.0))
	var base_noise := float(weapon_def.get("noise_per_attack", weapon_def.get("noise", 2.0)))
	var base_reveal_bonus := float(weapon_def.get("reveal_bonus_duration", 0.0))
	var base_summon_count := int(weapon_def.get("drone_count", 1))

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
	runtime.projectile_count = maxi(1, 1 + growth_projectile_count_bonus)
	runtime.reveal_bonus_duration = base_reveal_bonus + growth_reveal_bonus
	runtime.summon_count = maxi(1, base_summon_count + growth_drone_count_bonus)
	runtime.beam_tick_interval = maxf(0.05, float(weapon_def.get("beam_tick_interval", 1.0 / maxf(0.1, runtime.attack_rate))))
	runtime.orbit_radius = maxf(24.0, float(weapon_def.get("orbit_radius", 120.0)))
	runtime.sonar_pulse_strength = maxf(0.1, float(weapon_def.get("sonar_pulse_strength", 1.0)))

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

	runtime.attack_rate = maxf(0.05, runtime.attack_rate)
	runtime.attack_interval = 1.0 / runtime.attack_rate
	runtime.crit_chance = clampf(runtime.crit_chance, 0.0, 0.95)
	runtime.crit_multiplier = maxf(1.0, runtime.crit_multiplier)
	runtime.range = maxf(8.0, runtime.range)
	runtime.projectile_speed = maxf(0.0, runtime.projectile_speed)
	runtime.aoe_radius = maxf(0.0, runtime.aoe_radius)
	runtime.noise_per_attack = maxf(0.0, runtime.noise_per_attack)
	runtime.reveal_bonus_duration = maxf(0.0, runtime.reveal_bonus_duration)

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
