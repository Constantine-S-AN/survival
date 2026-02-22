extends Node

const DATA_FILES: Dictionary = {
	"weapons": "res://data/weapons.json",
	"enemies": "res://data/enemies.json",
	"upgrades": "res://data/upgrades.json",
	"spawn_curve": "res://data/spawn_curve.json",
	"fog": "res://data/fog.json",
	"sonar": "res://data/sonar.json",
	"noise": "res://data/noise.json"
}

const RARITY_WEIGHT: Dictionary = {
	"common": 70.0,
	"uncommon": 24.0,
	"rare": 8.0,
	"legendary": 2.0
}

var weapons: Dictionary = {}
var enemies: Dictionary = {}
var upgrades: Array = []
var spawn_curve: Array = []
var fog_config: Dictionary = {}
var sonar_config: Dictionary = {}
var noise_config: Dictionary = {}
var validation_errors: Array[String] = []
var loaded: bool = false


func _ready() -> void:
	if not loaded:
		load_all()


func load_all(log_errors: bool = true) -> bool:
	validation_errors.clear()
	weapons = _load_dictionary(DATA_FILES["weapons"], "weapons")
	enemies = _load_dictionary(DATA_FILES["enemies"], "enemies")
	upgrades = _load_array_of_dictionaries(DATA_FILES["upgrades"], "upgrades")
	spawn_curve = _load_array_of_dictionaries(DATA_FILES["spawn_curve"], "spawn_curve")
	fog_config = _load_dictionary(DATA_FILES["fog"], "fog")
	sonar_config = _load_dictionary(DATA_FILES["sonar"], "sonar")
	noise_config = _load_dictionary(DATA_FILES["noise"], "noise")

	_validate_weapons()
	_validate_enemies()
	_validate_upgrades()
	_validate_spawn_curve()
	_validate_fog()
	_validate_sonar()
	_validate_noise()

	loaded = validation_errors.is_empty()
	if not loaded and log_errors:
		for error_text in validation_errors:
			push_error(error_text)
	return loaded


func reload_in_debug() -> bool:
	if not OS.is_debug_build():
		return loaded
	return load_all()


func get_validation_errors() -> Array[String]:
	return validation_errors.duplicate()


func get_fog_config() -> Dictionary:
	if fog_config.is_empty():
		return {}
	return fog_config.duplicate(true)


func get_data_path(key: String) -> String:
	return String(DATA_FILES.get(key, ""))


func get_data_version(key: String) -> int:
	var payload: Variant = null
	match key:
		"fog":
			payload = fog_config
		"sonar":
			payload = sonar_config
		"noise":
			payload = noise_config
		_:
			return -1
	if payload is Dictionary:
		return int((payload as Dictionary).get("schema_version", -1))
	return -1


func get_sonar_config() -> Dictionary:
	if sonar_config.is_empty():
		return {}
	return sonar_config.duplicate(true)


func get_noise_config() -> Dictionary:
	if noise_config.is_empty():
		return {}
	return noise_config.duplicate(true)


func get_noise_tier(noise_value: float) -> Dictionary:
	var tiers_variant: Variant = noise_config.get("tiers", [])
	if not (tiers_variant is Array):
		return {}
	var tiers: Array = tiers_variant
	for tier_variant in tiers:
		if not (tier_variant is Dictionary):
			continue
		var tier: Dictionary = tier_variant
		var min_value := float(tier.get("min", 0.0))
		var max_value := float(tier.get("max", 100.0))
		if noise_value >= min_value and noise_value < max_value:
			return tier
	if not tiers.is_empty():
		var last: Variant = tiers.back()
		if last is Dictionary:
			return last
	return {}


func get_noise_spawn_modifiers(noise_value: float) -> Dictionary:
	var tier := get_noise_tier(noise_value)
	if tier.is_empty():
		return {
			"spawn_rate_multiplier": 1.0,
			"spawn_cap_multiplier": 1.0,
			"pursuer_chance": 0.0,
			"tier_name": "Unknown"
		}
	return {
		"spawn_rate_multiplier": float(tier.get("spawn_rate_multiplier", 1.0)),
		"spawn_cap_multiplier": float(tier.get("spawn_cap_multiplier", 1.0)),
		"pursuer_chance": float(tier.get("pursuer_chance", 0.0)),
		"tier_name": String(tier.get("name", "Unknown")),
		"tier_id": String(tier.get("id", "unknown")),
		"hud_color": String(tier.get("hud_color", "#ffffff"))
	}


func clamp_noise_value(value: float) -> float:
	var min_value := float(noise_config.get("min", 0.0))
	var max_value := float(noise_config.get("max", 100.0))
	return clampf(value, min_value, max_value)


func get_timeline_progress(elapsed_time: float) -> float:
	if spawn_curve.is_empty():
		return 0.0
	var last_variant: Variant = spawn_curve.back()
	if not (last_variant is Dictionary):
		return 0.0
	var last_profile: Dictionary = last_variant
	var end_time := float(last_profile.get("time", 0.0))
	if end_time <= 0.0:
		return 0.0
	return clampf(elapsed_time / end_time, 0.0, 1.0)


func get_weapon(weapon_id: String) -> Dictionary:
	var weapon_variant: Variant = weapons.get(weapon_id, {})
	if weapon_variant is Dictionary:
		return weapon_variant
	return {}


func get_enemy(enemy_id: String) -> Dictionary:
	var enemy_variant: Variant = enemies.get(enemy_id, {})
	if enemy_variant is Dictionary:
		return enemy_variant
	return {}


func get_upgrade(upgrade_id: String) -> Dictionary:
	for upgrade_variant in upgrades:
		if not (upgrade_variant is Dictionary):
			continue
		var upgrade: Dictionary = upgrade_variant
		if String(upgrade.get("id", "")) == upgrade_id:
			return upgrade
	return {}


func get_upgrade_choices(rng: RandomNumberGenerator, current_stacks: Dictionary, count: int = 3) -> Array:
	var candidates: Array = []
	for upgrade_variant in upgrades:
		if not (upgrade_variant is Dictionary):
			continue
		var upgrade: Dictionary = upgrade_variant
		var upgrade_id: String = String(upgrade.get("id", ""))
		if upgrade_id.is_empty():
			continue
		var max_stacks: int = int(upgrade.get("max_stacks", 1))
		var current: int = int(current_stacks.get(upgrade_id, 0))
		if current >= max_stacks:
			continue
		candidates.append(upgrade)

	if candidates.is_empty():
		return []

	var picked: Array = []
	while picked.size() < count and not candidates.is_empty():
		var choice: Dictionary = _weighted_pick_upgrade(rng, candidates)
		picked.append(choice)
		var chosen_id: String = String(choice.get("id", ""))
		var remaining: Array = []
		for item_variant in candidates:
			if not (item_variant is Dictionary):
				continue
			var item: Dictionary = item_variant
			if String(item.get("id", "")) != chosen_id:
				remaining.append(item)
		candidates = remaining

	return picked


func get_spawn_rate(elapsed_time: float, noise: float = 0.0) -> float:
	var profile: Dictionary = _get_spawn_profile(elapsed_time)
	var base_rate: float = float(profile.get("spawn_per_second", 1.0))
	var modifiers := get_noise_spawn_modifiers(noise)
	var noise_multiplier: float = float(modifiers.get("spawn_rate_multiplier", 1.0))
	return base_rate * noise_multiplier


func get_enemy_cap(elapsed_time: float, noise: float = 0.0) -> int:
	var profile: Dictionary = _get_spawn_profile(elapsed_time)
	var base_cap: int = int(profile.get("enemy_cap", 60))
	var modifiers := get_noise_spawn_modifiers(noise)
	var mult: float = float(modifiers.get("spawn_cap_multiplier", 1.0))
	return int(round(base_cap * mult))


func pick_enemy_id(rng: RandomNumberGenerator, elapsed_time: float, noise: float = 0.0) -> String:
	var profile: Dictionary = _get_spawn_profile(elapsed_time)
	var weights_variant: Variant = profile.get("weights", {})
	if not (weights_variant is Dictionary):
		return ""
	var weights: Dictionary = (weights_variant as Dictionary).duplicate()
	if weights.is_empty():
		return ""

	for enemy_key in weights.keys():
		var enemy_id: String = String(enemy_key)
		var enemy_def: Dictionary = get_enemy(enemy_id)
		if enemy_def.is_empty():
			continue
		var threat: float = float(enemy_def.get("threat", 1.0))
		var current_weight: float = float(weights.get(enemy_key, 0.0))
		weights[enemy_key] = maxf(0.0, current_weight + (noise * 0.0025 * threat))

	var total: float = 0.0
	for value in weights.values():
		total += maxf(0.0, float(value))
	if total <= 0.0:
		return ""

	var roll: float = rng.randf_range(0.0, total)
	var running: float = 0.0
	for enemy_key in weights.keys():
		running += maxf(0.0, float(weights.get(enemy_key, 0.0)))
		if roll <= running:
			return String(enemy_key)
	return String(weights.keys().back())


func _load_dictionary(path: String, label: String) -> Dictionary:
	var result: Variant = _load_json(path, label)
	if result is Dictionary:
		return result
	validation_errors.append("[%s] expected JSON object at %s" % [label, path])
	return {}


func _load_array_of_dictionaries(path: String, label: String) -> Array:
	var result: Variant = _load_json(path, label)
	if not (result is Array):
		validation_errors.append("[%s] expected JSON array at %s" % [label, path])
		return []

	var output: Array = []
	var rows: Array = result
	for i in range(rows.size()):
		var row_variant: Variant = rows[i]
		if row_variant is Dictionary:
			output.append(row_variant)
		else:
			validation_errors.append("[%s] item %d is not a dictionary in %s" % [label, i, path])
	return output


func _load_json(path: String, label: String) -> Variant:
	if not FileAccess.file_exists(path):
		validation_errors.append("[%s] missing file: %s" % [label, path])
		return {}

	var text: String = FileAccess.get_file_as_string(path)
	var parsed: Variant = JSON.parse_string(text)
	if parsed == null:
		validation_errors.append("[%s] invalid JSON in %s" % [label, path])
		return {}
	return parsed


func _validate_weapons() -> void:
	for weapon_key in weapons.keys():
		var weapon_variant: Variant = weapons[weapon_key]
		if not (weapon_variant is Dictionary):
			validation_errors.append("[weapons] %s must be a dictionary" % weapon_key)
			continue
		var weapon: Dictionary = weapon_variant
		_validate_required_keys(
			weapon,
			["name", "damage", "cooldown", "projectile_speed", "range", "pierce", "tags"],
			"weapons:%s" % String(weapon_key)
		)
		weapon["id"] = String(weapon.get("id", String(weapon_key)))


func _validate_enemies() -> void:
	for enemy_key in enemies.keys():
		var enemy_variant: Variant = enemies[enemy_key]
		if not (enemy_variant is Dictionary):
			validation_errors.append("[enemies] %s must be a dictionary" % enemy_key)
			continue
		var enemy: Dictionary = enemy_variant
		_validate_required_keys(
			enemy,
			["name", "max_hp", "speed", "damage", "xp_reward", "contact_cooldown", "threat", "size", "color", "tags"],
			"enemies:%s" % String(enemy_key)
		)
		enemy["id"] = String(enemy.get("id", String(enemy_key)))


func _validate_upgrades() -> void:
	for i in range(upgrades.size()):
		var upgrade_variant: Variant = upgrades[i]
		if not (upgrade_variant is Dictionary):
			validation_errors.append("[upgrades:%d] must be a dictionary" % i)
			continue
		var upgrade: Dictionary = upgrade_variant
		_validate_required_keys(
			upgrade,
			["id", "name", "description", "rarity", "max_stacks", "tags", "effects"],
			"upgrades:%d" % i
		)
		var rarity: String = String(upgrade.get("rarity", "common"))
		if not RARITY_WEIGHT.has(rarity):
			validation_errors.append("[upgrades:%d] unknown rarity '%s'" % [i, rarity])
		var effects_variant: Variant = upgrade.get("effects", [])
		if not (effects_variant is Array):
			validation_errors.append("[upgrades:%d] effects must be an array" % i)
			continue
		var effects: Array = effects_variant
		if effects.is_empty():
			validation_errors.append("[upgrades:%d] effects must be a non-empty array" % i)
			continue
		for e_index in range(effects.size()):
			var effect_variant: Variant = effects[e_index]
			if not (effect_variant is Dictionary):
				validation_errors.append("[upgrades:%d] effect %d must be a dictionary" % [i, e_index])
				continue
			var effect: Dictionary = effect_variant
			_validate_required_keys(effect, ["stat", "add"], "upgrades:%d:effect:%d" % [i, e_index])


func _validate_spawn_curve() -> void:
	if spawn_curve.is_empty():
		validation_errors.append("[spawn_curve] must contain at least one profile")
		return

	for i in range(spawn_curve.size()):
		var profile_variant: Variant = spawn_curve[i]
		if not (profile_variant is Dictionary):
			validation_errors.append("[spawn_curve:%d] profile must be dictionary" % i)
			continue
		var profile: Dictionary = profile_variant
		_validate_required_keys(profile, ["time", "spawn_per_second", "enemy_cap", "weights"], "spawn_curve:%d" % i)
		if not (profile.get("weights", {}) is Dictionary):
			validation_errors.append("[spawn_curve:%d] weights must be dictionary" % i)
	spawn_curve.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return int(a.get("time", 0)) < int(b.get("time", 0))
	)


func _validate_fog() -> void:
	_validate_required_keys(
		fog_config,
		[
			"schema_version",
			"enabled",
			"darkness_color",
			"vision_radius",
			"vision_energy",
			"scanline_enabled",
			"scanline_density",
			"scanline_strength",
			"noise_strength",
			"tint_color",
			"tint_alpha",
			"pulse_speed"
		],
		"fog"
	)


func _validate_sonar() -> void:
	_validate_required_keys(
		sonar_config,
		[
			"schema_version",
			"enabled",
			"wave_speed",
			"max_radius",
			"line_width",
			"glow_intensity",
			"reveal_duration",
			"color",
			"hit_strength",
			"pickup_strength",
			"skill_strength",
			"hit_radius_scale",
			"pickup_radius_scale",
			"skill_radius_scale"
		],
		"sonar"
	)


func _validate_noise() -> void:
	_validate_required_keys(
		noise_config,
		[
			"schema_version",
			"min",
			"max",
			"decay_per_second",
			"sources",
			"skill",
			"tiers",
			"pursuer"
		],
		"noise"
	)
	var tiers_variant: Variant = noise_config.get("tiers", [])
	if not (tiers_variant is Array):
		validation_errors.append("[noise] tiers must be array")
		return
	var tiers: Array = tiers_variant
	for i in range(tiers.size()):
		var tier_variant: Variant = tiers[i]
		if not (tier_variant is Dictionary):
			validation_errors.append("[noise] tier %d must be dictionary" % i)
			continue
		_validate_required_keys(
			tier_variant,
			["id", "name", "min", "max", "spawn_rate_multiplier", "spawn_cap_multiplier", "pursuer_chance", "hud_color"],
			"noise:tier:%d" % i
		)


func _validate_required_keys(payload: Dictionary, required_keys: Array, label: String) -> void:
	for key in required_keys:
		if not payload.has(key):
			validation_errors.append("[%s] missing key '%s'" % [label, key])


func _get_spawn_profile(elapsed_time: float) -> Dictionary:
	if spawn_curve.is_empty():
		return {}
	var first_variant: Variant = spawn_curve[0]
	if not (first_variant is Dictionary):
		return {}
	var chosen: Dictionary = first_variant
	for profile_variant in spawn_curve:
		if not (profile_variant is Dictionary):
			continue
		var profile: Dictionary = profile_variant
		if elapsed_time >= float(profile.get("time", 0.0)):
			chosen = profile
		else:
			break
	return chosen


func _weighted_pick_upgrade(rng: RandomNumberGenerator, candidates: Array) -> Dictionary:
	var total: float = 0.0
	for candidate_variant in candidates:
		if not (candidate_variant is Dictionary):
			continue
		var candidate: Dictionary = candidate_variant
		var rarity: String = String(candidate.get("rarity", "common"))
		total += float(RARITY_WEIGHT.get(rarity, 1.0))

	if total <= 0.0:
		var first_candidate: Variant = candidates[0]
		if first_candidate is Dictionary:
			return first_candidate
		return {}

	var roll: float = rng.randf_range(0.0, total)
	var running: float = 0.0
	for candidate_variant in candidates:
		if not (candidate_variant is Dictionary):
			continue
		var candidate: Dictionary = candidate_variant
		var rarity: String = String(candidate.get("rarity", "common"))
		running += float(RARITY_WEIGHT.get(rarity, 1.0))
		if roll <= running:
			return candidate

	var last_candidate: Variant = candidates.back()
	if last_candidate is Dictionary:
		return last_candidate
	return {}
