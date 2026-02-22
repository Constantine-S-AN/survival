extends Node

const DATA_FILES: Dictionary = {
	"weapons": "res://data/weapons.json",
	"enemies": "res://data/enemies.json",
	"upgrades": "res://data/upgrades.json",
	"spawn_curve": "res://data/spawn_curve.json",
	"fog": "res://data/fog.json",
	"sonar": "res://data/sonar.json",
	"noise": "res://data/noise.json",
	"characters": "res://data/characters.json"
}

const RARITY_WEIGHT: Dictionary = {
	"common": 70.0,
	"uncommon": 20.0,
	"rare": 8.0,
	"epic": 2.0,
	"legendary": 0.5
}

const CHARACTER_REQUIRED_MODIFIER_KEYS: Array[String] = [
	"max_hp_multiplier",
	"max_hp_bonus",
	"move_speed_multiplier",
	"move_speed_bonus",
	"dash_cooldown_multiplier",
	"noise_gain_multiplier",
	"sonar_reveal_duration_multiplier",
	"pickup_radius_multiplier",
	"damage_multiplier",
	"attack_speed_multiplier",
	"projectile_range_multiplier",
	"pierce_bonus",
	"xp_gain_multiplier",
	"crit_chance_bonus",
	"chain_bonus",
	"summon_cap_bonus"
]

const CHARACTER_UNLOCK_TYPES: Dictionary = {
	"survive_time_seconds": true,
	"max_noise_reached": true,
	"reached_noise_tier": true,
	"total_kills": true,
	"pickups_collected": true,
	"elite_or_pursuer_kills": true
}

const WEAPON_REQUIRED_KEYS: Array[String] = [
	"id",
	"name",
	"description",
	"attack_model",
	"tags",
	"base_damage",
	"attack_rate",
	"range",
	"projectile_speed",
	"projectile_pierce",
	"crit_chance",
	"crit_multiplier",
	"aoe_radius",
	"noise_per_attack",
	"level_growth"
]

const WEAPON_SUPPORTED_MODELS: Dictionary = {
	"projectile": true,
	"pulse": true,
	"mine": true,
	"beam": true,
	"drone": true,
	"melee": true
}

const WEAPON_ALLOWED_TAGS: Dictionary = {
	"sonar": true,
	"silence": true,
	"heat": true,
	"crit": true,
	"pierce": true,
	"chain": true,
	"aoe": true,
	"pickup": true,
	"shield": true,
	"speed": true,
	"trap": true,
	"control": true,
	"summon": true,
	"economy": true,
	"damage": true,
	"weapon": true,
	"tempo": true,
	"starter": true,
	"kinetic": true
}

const UPGRADE_ALLOWED_TAGS: Dictionary = {
	"sonar": true,
	"silence": true,
	"heat": true,
	"crit": true,
	"pierce": true,
	"chain": true,
	"aoe": true,
	"pickup": true,
	"shield": true,
	"speed": true,
	"trap": true,
	"control": true,
	"summon": true,
	"economy": true,
	"damage": true,
	"weapon": true,
	"tempo": true,
	"noise": true,
	"mobility": true,
	"defense": true,
	"hull": true,
	"starter": true,
	"kinetic": true
}

const UPGRADE_EFFECT_TARGET_TYPES: Dictionary = {
	"weapon_id": true,
	"tag": true
}

const UPGRADE_PREREQ_TYPES: Dictionary = {
	"upgrade_selected": true,
	"upgrade_rank_at_least": true,
	"has_tag": true,
	"weapon_owned": true,
	"weapon_is_active": true,
	"player_level_at_least": true,
	"noise_tier_at_least": true,
	"survive_time_seconds_at_least": true
}

var weapons: Dictionary = {}
var enemies: Dictionary = {}
var upgrades: Array = []
var spawn_curve: Array = []
var fog_config: Dictionary = {}
var sonar_config: Dictionary = {}
var noise_config: Dictionary = {}
var characters_config: Dictionary = {}
var characters: Dictionary = {}
var character_order: Array[String] = []
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
	characters_config = _load_dictionary(DATA_FILES["characters"], "characters")
	characters.clear()
	character_order.clear()

	_validate_weapons()
	_validate_characters()
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
		"characters":
			payload = characters_config
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


func get_default_character_id() -> String:
	return String(characters_config.get("default_character_id", ""))


func get_character(character_id: String) -> Dictionary:
	var payload: Variant = characters.get(character_id, {})
	if payload is Dictionary:
		return (payload as Dictionary).duplicate(true)
	return {}


func has_character(character_id: String) -> bool:
	return characters.has(character_id)


func get_characters() -> Array:
	var output: Array = []
	for character_id in character_order:
		var character_variant: Variant = characters.get(character_id, {})
		if character_variant is Dictionary:
			output.append((character_variant as Dictionary).duplicate(true))
	return output


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


func get_upgrade_choices(rng: RandomNumberGenerator, current_stacks: Dictionary, count: int = 3, tag_weights: Dictionary = {}) -> Array:
	var candidates: Array = []
	for upgrade_variant in upgrades:
		if not (upgrade_variant is Dictionary):
			continue
		var upgrade: Dictionary = upgrade_variant
		var upgrade_id: String = String(upgrade.get("id", ""))
		if upgrade_id.is_empty():
			continue
		var max_stacks: int = int(upgrade.get("max_rank", upgrade.get("max_stacks", 1)))
		var current: int = int(current_stacks.get(upgrade_id, 0))
		if current >= max_stacks:
			continue
		candidates.append(upgrade)

	if candidates.is_empty():
		return []

	var picked: Array = []
	while picked.size() < count and not candidates.is_empty():
		var choice: Dictionary = _weighted_pick_upgrade(rng, candidates, tag_weights)
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
	if weapons.size() < 8:
		validation_errors.append("[weapons] expected at least 8 weapon definitions, found %d" % weapons.size())
	var normalized_weapons: Dictionary = {}
	var seen_ids: Dictionary = {}
	for weapon_key in weapons.keys():
		var weapon_variant: Variant = weapons[weapon_key]
		if not (weapon_variant is Dictionary):
			validation_errors.append("[weapons] %s must be a dictionary" % weapon_key)
			continue
		var weapon: Dictionary = weapon_variant
		var label := "weapons:%s" % String(weapon_key)
		_validate_required_keys(weapon, WEAPON_REQUIRED_KEYS, label)

		var weapon_id := String(weapon.get("id", String(weapon_key))).strip_edges()
		if weapon_id.is_empty():
			validation_errors.append("[%s] id must be non-empty string" % label)
			continue
		if seen_ids.has(weapon_id):
			validation_errors.append("[%s] duplicate weapon id '%s'" % [label, weapon_id])
			continue
		seen_ids[weapon_id] = true

		var normalized: Dictionary = weapon.duplicate(true)
		normalized["id"] = weapon_id

		var attack_model := String(normalized.get("attack_model", "")).strip_edges().to_lower()
		if not WEAPON_SUPPORTED_MODELS.has(attack_model):
			validation_errors.append("[%s] unsupported attack_model '%s'" % [label, attack_model])
		normalized["attack_model"] = attack_model

		var tags_variant: Variant = normalized.get("tags", [])
		if not (tags_variant is Array):
			validation_errors.append("[%s] tags must be an array" % label)
			normalized["tags"] = []
		else:
			var tags: Array = tags_variant
			if tags.is_empty():
				validation_errors.append("[%s] tags must contain at least one tag" % label)
			var normalized_tags: Array[String] = []
			for tag_variant in tags:
				var tag := String(tag_variant).strip_edges().to_lower()
				if tag.is_empty():
					validation_errors.append("[%s] tags cannot contain empty values" % label)
					continue
				if not WEAPON_ALLOWED_TAGS.has(tag):
					validation_errors.append("[%s] unknown tag '%s'" % [label, tag])
				if not normalized_tags.has(tag):
					normalized_tags.append(tag)
			normalized["tags"] = normalized_tags

		var base_damage := float(normalized.get("base_damage", 0.0))
		var attack_rate := float(normalized.get("attack_rate", 0.0))
		var weapon_range := float(normalized.get("range", 0.0))
		var projectile_speed := float(normalized.get("projectile_speed", 0.0))
		var crit_chance := float(normalized.get("crit_chance", 0.0))
		var crit_multiplier := float(normalized.get("crit_multiplier", 1.0))
		var aoe_radius := float(normalized.get("aoe_radius", 0.0))
		var noise_per_attack := float(normalized.get("noise_per_attack", 0.0))
		var projectile_pierce := int(normalized.get("projectile_pierce", 0))
		if base_damage < 0.0:
			validation_errors.append("[%s] base_damage must be >= 0" % label)
		if attack_rate <= 0.0:
			validation_errors.append("[%s] attack_rate must be > 0" % label)
			attack_rate = 0.0001
		if weapon_range < 0.0:
			validation_errors.append("[%s] range must be >= 0" % label)
		if projectile_speed < 0.0:
			validation_errors.append("[%s] projectile_speed must be >= 0" % label)
		if crit_chance < 0.0:
			validation_errors.append("[%s] crit_chance must be >= 0" % label)
		if crit_multiplier < 1.0:
			validation_errors.append("[%s] crit_multiplier must be >= 1.0" % label)
		if aoe_radius < 0.0:
			validation_errors.append("[%s] aoe_radius must be >= 0" % label)
		if noise_per_attack < 0.0:
			validation_errors.append("[%s] noise_per_attack must be >= 0" % label)
		if projectile_pierce < 0:
			validation_errors.append("[%s] projectile_pierce must be >= 0" % label)

		var growth_variant: Variant = normalized.get("level_growth", [])
		if not (growth_variant is Array):
			validation_errors.append("[%s] level_growth must be array" % label)
		else:
			var growth: Array = growth_variant
			if growth.size() < 5:
				validation_errors.append("[%s] level_growth must define at least 5 levels" % label)
			var seen_levels: Dictionary = {}
			for g_idx in range(growth.size()):
				var row_variant: Variant = growth[g_idx]
				if not (row_variant is Dictionary):
					validation_errors.append("[%s] level_growth[%d] must be dictionary" % [label, g_idx])
					continue
				var row: Dictionary = row_variant
				_validate_required_keys(row, ["level"], "%s:level_growth[%d]" % [label, g_idx])
				var level_value := int(row.get("level", 0))
				if level_value <= 0:
					validation_errors.append("[%s] level_growth[%d].level must be > 0" % [label, g_idx])
					continue
				if seen_levels.has(level_value):
					validation_errors.append("[%s] duplicate level_growth level %d" % [label, level_value])
					continue
				seen_levels[level_value] = true

		# Backward-compatible fields so existing runtime can keep reading cooldown/damage/pierce/noise.
		normalized["damage"] = base_damage
		normalized["cooldown"] = 1.0 / maxf(0.0001, attack_rate)
		normalized["pierce"] = projectile_pierce
		normalized["noise"] = noise_per_attack

		normalized_weapons[weapon_id] = normalized
	weapons = normalized_weapons


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
	if upgrades.size() < 20:
		validation_errors.append("[upgrades] expected at least 20 entries, found %d" % upgrades.size())
	var seen_ids: Dictionary = {}
	var normalized_upgrades: Array = []
	var blocks_by_upgrade: Dictionary = {}
	var exclusive_group_by_upgrade: Dictionary = {}
	for i in range(upgrades.size()):
		var upgrade_variant: Variant = upgrades[i]
		if not (upgrade_variant is Dictionary):
			validation_errors.append("[upgrades:%d] must be a dictionary" % i)
			continue
		var upgrade: Dictionary = upgrade_variant
		var label := "upgrades:%d" % i
		_validate_required_keys(
			upgrade,
			[
				"id",
				"name",
				"description",
				"rarity",
				"base_weight",
				"max_rank",
				"max_stacks",
				"tags",
				"effects",
				"prereq",
				"requires_tags",
				"requires_weapon_ids",
				"exclusive_group",
				"blocks"
			],
			label
		)

		var upgrade_id := String(upgrade.get("id", "")).strip_edges()
		if upgrade_id.is_empty():
			validation_errors.append("[%s] id must be non-empty string" % label)
			continue
		if seen_ids.has(upgrade_id):
			validation_errors.append("[%s] duplicate id '%s'" % [label, upgrade_id])
			continue
		seen_ids[upgrade_id] = i

		var normalized: Dictionary = upgrade.duplicate(true)
		normalized["id"] = upgrade_id

		var rarity: String = String(upgrade.get("rarity", "common")).strip_edges().to_lower()
		if not RARITY_WEIGHT.has(rarity):
			validation_errors.append("[%s] unknown rarity '%s'" % [label, rarity])
		normalized["rarity"] = rarity

		var base_weight := float(upgrade.get("base_weight", 1.0))
		if base_weight <= 0.0:
			validation_errors.append("[%s] base_weight must be > 0" % label)
			base_weight = 0.0001
		normalized["base_weight"] = base_weight

		var max_rank := int(upgrade.get("max_rank", upgrade.get("max_stacks", 1)))
		if max_rank <= 0:
			validation_errors.append("[%s] max_rank must be >= 1" % label)
			max_rank = 1
		normalized["max_rank"] = max_rank
		normalized["max_stacks"] = max_rank

		var tags_variant: Variant = upgrade.get("tags", [])
		if not (tags_variant is Array):
			validation_errors.append("[%s] tags must be an array" % label)
			normalized["tags"] = []
		else:
			var tags: Array = tags_variant
			if tags.is_empty():
				validation_errors.append("[%s] tags must not be empty" % label)
			var normalized_tags: Array[String] = []
			for tag_variant in tags:
				var tag := String(tag_variant).strip_edges().to_lower()
				if tag.is_empty():
					validation_errors.append("[%s] tags cannot contain empty values" % label)
					continue
				if not _is_known_upgrade_tag(tag):
					validation_errors.append("[%s] unknown tag '%s'" % [label, tag])
				if not normalized_tags.has(tag):
					normalized_tags.append(tag)
			normalized["tags"] = normalized_tags

		var requires_tags_variant: Variant = upgrade.get("requires_tags", [])
		if not (requires_tags_variant is Array):
			validation_errors.append("[%s] requires_tags must be an array" % label)
			normalized["requires_tags"] = []
		else:
			var requires_tags: Array = requires_tags_variant
			var normalized_requires_tags: Array[String] = []
			for requires_tag_variant in requires_tags:
				var requires_tag := String(requires_tag_variant).strip_edges().to_lower()
				if requires_tag.is_empty():
					validation_errors.append("[%s] requires_tags cannot contain empty values" % label)
					continue
				if not _is_known_upgrade_tag(requires_tag):
					validation_errors.append("[%s] requires_tags contains unknown tag '%s'" % [label, requires_tag])
				if not normalized_requires_tags.has(requires_tag):
					normalized_requires_tags.append(requires_tag)
			normalized["requires_tags"] = normalized_requires_tags

		var requires_weapon_ids_variant: Variant = upgrade.get("requires_weapon_ids", [])
		if not (requires_weapon_ids_variant is Array):
			validation_errors.append("[%s] requires_weapon_ids must be an array" % label)
			normalized["requires_weapon_ids"] = []
		else:
			var requires_weapon_ids: Array = requires_weapon_ids_variant
			var normalized_requires_weapon_ids: Array[String] = []
			for weapon_id_variant in requires_weapon_ids:
				var required_weapon_id := String(weapon_id_variant).strip_edges().to_lower()
				if required_weapon_id.is_empty():
					validation_errors.append("[%s] requires_weapon_ids cannot contain empty values" % label)
					continue
				if not weapons.has(required_weapon_id):
					validation_errors.append("[%s] requires_weapon_ids contains unknown weapon '%s'" % [label, required_weapon_id])
				if not normalized_requires_weapon_ids.has(required_weapon_id):
					normalized_requires_weapon_ids.append(required_weapon_id)
			normalized["requires_weapon_ids"] = normalized_requires_weapon_ids

		var prereq_variant: Variant = upgrade.get("prereq", {})
		_validate_upgrade_prereq(prereq_variant, label)
		if prereq_variant is Dictionary:
			var prereq := (prereq_variant as Dictionary).duplicate(true)
			if not prereq.has("all"):
				prereq["all"] = []
			if not prereq.has("any"):
				prereq["any"] = []
			normalized["prereq"] = prereq
		else:
			normalized["prereq"] = {
				"all": [],
				"any": []
			}

		var exclusive_group := String(upgrade.get("exclusive_group", "")).strip_edges()
		normalized["exclusive_group"] = exclusive_group
		if not exclusive_group.is_empty():
			exclusive_group_by_upgrade[upgrade_id] = exclusive_group

		var blocks_variant: Variant = upgrade.get("blocks", [])
		if not (blocks_variant is Array):
			validation_errors.append("[%s] blocks must be an array" % label)
			normalized["blocks"] = []
			blocks_by_upgrade[upgrade_id] = []
		else:
			var blocks: Array = blocks_variant
			var normalized_blocks: Array[String] = []
			for block_variant in blocks:
				var blocked_upgrade_id := String(block_variant).strip_edges()
				if blocked_upgrade_id.is_empty():
					validation_errors.append("[%s] blocks cannot contain empty id" % label)
					continue
				if blocked_upgrade_id == upgrade_id:
					validation_errors.append("[%s] blocks cannot include self id '%s'" % [label, upgrade_id])
					continue
				if not normalized_blocks.has(blocked_upgrade_id):
					normalized_blocks.append(blocked_upgrade_id)
			normalized["blocks"] = normalized_blocks
			blocks_by_upgrade[upgrade_id] = normalized_blocks

		var effects_variant: Variant = upgrade.get("effects", [])
		if not (effects_variant is Array):
			validation_errors.append("[%s] effects must be an array" % label)
			continue
		var effects: Array = effects_variant
		if effects.is_empty():
			validation_errors.append("[%s] effects must be a non-empty array" % label)
			continue
		for e_index in range(effects.size()):
			var effect_variant: Variant = effects[e_index]
			if not (effect_variant is Dictionary):
				validation_errors.append("[%s] effect %d must be a dictionary" % [label, e_index])
				continue
			var effect: Dictionary = effect_variant
			_validate_required_keys(effect, ["stat", "add"], "%s:effect:%d" % [label, e_index])
			var target_variant: Variant = effect.get("target", null)
			if target_variant == null:
				continue
			if not (target_variant is Dictionary):
				validation_errors.append("[%s] effect %d target must be dictionary" % [label, e_index])
				continue
			var target: Dictionary = target_variant
			_validate_required_keys(target, ["type", "value"], "%s:effect:%d:target" % [label, e_index])
			var target_type := String(target.get("type", "")).strip_edges().to_lower()
			var target_value := String(target.get("value", "")).strip_edges().to_lower()
			if not UPGRADE_EFFECT_TARGET_TYPES.has(target_type):
				validation_errors.append("[%s] effect %d target type '%s' is unsupported" % [label, e_index, target_type])
				continue
			if target_value.is_empty():
				validation_errors.append("[%s] effect %d target value must be non-empty" % [label, e_index])
				continue
			if target_type == "weapon_id" and not weapons.has(target_value):
				validation_errors.append("[%s] effect %d unknown target weapon_id '%s'" % [label, e_index, target_value])
			elif target_type == "tag" and not _is_known_upgrade_tag(target_value):
				validation_errors.append("[%s] effect %d unknown target tag '%s'" % [label, e_index, target_value])

		normalized_upgrades.append(normalized)

	for source_upgrade_id_variant in blocks_by_upgrade.keys():
		var source_upgrade_id := String(source_upgrade_id_variant)
		var blocked_ids_variant: Variant = blocks_by_upgrade[source_upgrade_id_variant]
		if not (blocked_ids_variant is Array):
			continue
		var blocked_ids: Array = blocked_ids_variant
		for blocked_id_variant in blocked_ids:
			var blocked_upgrade_id := String(blocked_id_variant).strip_edges()
			if not seen_ids.has(blocked_upgrade_id):
				validation_errors.append("[upgrades:%s] blocks references unknown upgrade id '%s'" % [source_upgrade_id, blocked_upgrade_id])
				continue
			var source_group := String(exclusive_group_by_upgrade.get(source_upgrade_id, ""))
			var target_group := String(exclusive_group_by_upgrade.get(blocked_upgrade_id, ""))
			if not source_group.is_empty() and source_group == target_group:
				validation_errors.append(
					"[upgrades:%s] blocks '%s' but both are in exclusive_group '%s' (redundant/conflicting rule)" %
					[source_upgrade_id, blocked_upgrade_id, source_group]
				)

	upgrades = normalized_upgrades


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


func _validate_characters() -> void:
	_validate_required_keys(
		characters_config,
		["schema_version", "default_character_id", "characters"],
		"characters"
	)
	var rows_variant: Variant = characters_config.get("characters", [])
	if not (rows_variant is Array):
		validation_errors.append("[characters] characters must be array")
		return
	var rows: Array = rows_variant
	if rows.size() < 5:
		validation_errors.append("[characters] expected at least 5 character entries")

	var seen_ids: Dictionary = {}
	for i in range(rows.size()):
		var row_variant: Variant = rows[i]
		if not (row_variant is Dictionary):
			validation_errors.append("[characters:%d] entry must be dictionary" % i)
			continue
		var row: Dictionary = row_variant
		_validate_required_keys(
			row,
			[
				"id",
				"display_name",
				"short_desc",
				"passive_summary",
				"starting_weapon_id",
				"effect_id",
				"stat_modifiers",
				"tag_weights",
				"unlock"
			],
			"characters:%d" % i
		)
		var character_id := String(row.get("id", "")).strip_edges()
		if character_id.is_empty():
			validation_errors.append("[characters:%d] id must be non-empty string" % i)
			continue
		if seen_ids.has(character_id):
			validation_errors.append("[characters:%d] duplicate id '%s'" % [i, character_id])
			continue
		seen_ids[character_id] = true

		var starting_weapon_id := String(row.get("starting_weapon_id", "")).strip_edges()
		if starting_weapon_id.is_empty():
			validation_errors.append("[characters:%d] starting_weapon_id must be non-empty string" % i)
		elif not weapons.has(starting_weapon_id):
			validation_errors.append("[characters:%d] unknown starting_weapon_id '%s'" % [i, starting_weapon_id])

		var modifiers_variant: Variant = row.get("stat_modifiers", {})
		if not (modifiers_variant is Dictionary):
			validation_errors.append("[characters:%d] stat_modifiers must be dictionary" % i)
		else:
			_validate_required_keys(modifiers_variant, CHARACTER_REQUIRED_MODIFIER_KEYS, "characters:%d:stat_modifiers" % i)

		var tag_weights_variant: Variant = row.get("tag_weights", {})
		if not (tag_weights_variant is Dictionary):
			validation_errors.append("[characters:%d] tag_weights must be dictionary" % i)
		else:
			var tag_weights: Dictionary = tag_weights_variant
			for tag_variant in tag_weights.keys():
				var tag := String(tag_variant).strip_edges()
				var weight := float(tag_weights.get(tag_variant, 1.0))
				if tag.is_empty():
					validation_errors.append("[characters:%d] tag_weights contains empty tag key" % i)
					continue
				if weight <= 0.0:
					validation_errors.append("[characters:%d] tag_weight '%s' must be > 0" % [i, tag])

		var unlock_variant: Variant = row.get("unlock", {})
		if not (unlock_variant is Dictionary):
			validation_errors.append("[characters:%d] unlock must be dictionary" % i)
		else:
			var unlock: Dictionary = unlock_variant
			_validate_required_keys(unlock, ["type", "params", "display"], "characters:%d:unlock" % i)
			var unlock_type := String(unlock.get("type", "")).strip_edges()
			if not CHARACTER_UNLOCK_TYPES.has(unlock_type):
				validation_errors.append("[characters:%d] unsupported unlock type '%s'" % [i, unlock_type])
			if not (unlock.get("params", {}) is Dictionary):
				validation_errors.append("[characters:%d] unlock params must be dictionary" % i)
			if String(unlock.get("display", "")).strip_edges().is_empty():
				validation_errors.append("[characters:%d] unlock display must be non-empty string" % i)

		var normalized: Dictionary = row.duplicate(true)
		normalized["id"] = character_id
		normalized["starting_weapon_id"] = starting_weapon_id
		characters[character_id] = normalized
		character_order.append(character_id)

	var default_character_id := String(characters_config.get("default_character_id", "")).strip_edges()
	if default_character_id.is_empty():
		validation_errors.append("[characters] default_character_id must be non-empty string")
	elif not seen_ids.has(default_character_id):
		validation_errors.append("[characters] default_character_id '%s' not found in characters list" % default_character_id)


func _validate_required_keys(payload: Dictionary, required_keys: Array, label: String) -> void:
	for key in required_keys:
		if not payload.has(key):
			validation_errors.append("[%s] missing key '%s'" % [label, key])


func _is_known_upgrade_tag(tag: String) -> bool:
	return UPGRADE_ALLOWED_TAGS.has(tag) or WEAPON_ALLOWED_TAGS.has(tag)


func _validate_upgrade_prereq(prereq_variant: Variant, label: String) -> void:
	if not (prereq_variant is Dictionary):
		validation_errors.append("[%s] prereq must be dictionary" % label)
		return
	var prereq: Dictionary = prereq_variant
	_validate_required_keys(prereq, ["all", "any"], "%s:prereq" % label)
	for branch in ["all", "any"]:
		var branch_variant: Variant = prereq.get(branch, [])
		if not (branch_variant is Array):
			validation_errors.append("[%s:prereq] '%s' must be an array" % [label, branch])
			continue
		var rules: Array = branch_variant
		for idx in range(rules.size()):
			var condition_variant: Variant = rules[idx]
			if not (condition_variant is Dictionary):
				validation_errors.append("[%s:prereq] '%s' item %d must be dictionary" % [label, branch, idx])
				continue
			_validate_upgrade_prereq_condition(condition_variant as Dictionary, label, branch, idx)


func _validate_upgrade_prereq_condition(condition: Dictionary, label: String, branch: String, index: int) -> void:
	var condition_label := "%s:prereq:%s[%d]" % [label, branch, index]
	_validate_required_keys(condition, ["type"], condition_label)
	var condition_type := String(condition.get("type", "")).strip_edges().to_lower()
	if condition_type.is_empty():
		validation_errors.append("[%s] type must be non-empty string" % condition_label)
		return
	if not UPGRADE_PREREQ_TYPES.has(condition_type):
		validation_errors.append("[%s] unsupported prereq type '%s'" % [condition_label, condition_type])
		return

	match condition_type:
		"upgrade_selected":
			var upgrade_id := String(condition.get("upgrade_id", "")).strip_edges()
			if upgrade_id.is_empty():
				validation_errors.append("[%s] upgrade_selected requires 'upgrade_id'" % condition_label)
		"upgrade_rank_at_least":
			var rank_upgrade_id := String(condition.get("upgrade_id", "")).strip_edges()
			var min_rank := int(condition.get("value", 0))
			if rank_upgrade_id.is_empty():
				validation_errors.append("[%s] upgrade_rank_at_least requires 'upgrade_id'" % condition_label)
			if min_rank <= 0:
				validation_errors.append("[%s] upgrade_rank_at_least requires value >= 1" % condition_label)
		"has_tag":
			var required_tag := String(condition.get("tag", "")).strip_edges().to_lower()
			if required_tag.is_empty():
				validation_errors.append("[%s] has_tag requires 'tag'" % condition_label)
			elif not _is_known_upgrade_tag(required_tag):
				validation_errors.append("[%s] has_tag references unknown tag '%s'" % [condition_label, required_tag])
		"weapon_owned", "weapon_is_active":
			var weapon_id := String(condition.get("weapon_id", "")).strip_edges().to_lower()
			if weapon_id.is_empty():
				validation_errors.append("[%s] %s requires 'weapon_id'" % [condition_label, condition_type])
			elif not weapons.has(weapon_id):
				validation_errors.append("[%s] %s references unknown weapon '%s'" % [condition_label, condition_type, weapon_id])
		"player_level_at_least", "survive_time_seconds_at_least":
			var min_value := float(condition.get("value", 0.0))
			if min_value <= 0.0:
				validation_errors.append("[%s] %s requires value > 0" % [condition_label, condition_type])
		"noise_tier_at_least":
			var tier_id := String(condition.get("tier_id", "")).strip_edges().to_lower()
			if tier_id.is_empty():
				validation_errors.append("[%s] noise_tier_at_least requires 'tier_id'" % condition_label)
		_:
			pass


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


func _weighted_pick_upgrade(rng: RandomNumberGenerator, candidates: Array, tag_weights: Dictionary = {}) -> Dictionary:
	var total: float = 0.0
	for candidate_variant in candidates:
		if not (candidate_variant is Dictionary):
			continue
		var candidate: Dictionary = candidate_variant
		total += _get_upgrade_weight(candidate, tag_weights)

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
		running += _get_upgrade_weight(candidate, tag_weights)
		if roll <= running:
			return candidate

	var last_candidate: Variant = candidates.back()
	if last_candidate is Dictionary:
		return last_candidate
	return {}


func _get_upgrade_weight(candidate: Dictionary, tag_weights: Dictionary) -> float:
	var rarity: String = String(candidate.get("rarity", "common"))
	var rarity_weight := float(RARITY_WEIGHT.get(rarity, 1.0))
	var base_weight := maxf(0.0001, float(candidate.get("base_weight", 1.0)))
	var total_base_weight := rarity_weight * base_weight
	if tag_weights.is_empty():
		return total_base_weight
	var tags_variant: Variant = candidate.get("tags", [])
	if not (tags_variant is Array):
		return total_base_weight
	var tags: Array = tags_variant
	var tag_mult := 1.0
	for tag_variant in tags:
		var tag := String(tag_variant)
		var weight_variant: Variant = tag_weights.get(tag, null)
		if weight_variant == null:
			continue
		tag_mult *= clampf(float(weight_variant), 0.2, 3.0)
	return maxf(0.0001, total_base_weight * tag_mult)
