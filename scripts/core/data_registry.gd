extends Node

const UpgradeRules := preload("res://scripts/core/upgrade_rules.gd")

const DATA_FILES: Dictionary = {
	"weapons": "res://data/weapons.json",
	"enemies": "res://data/enemies.json",
	"elites": "res://data/elites.json",
	"bosses": "res://data/bosses.json",
	"contracts": "res://data/contracts.json",
	"upgrades": "res://data/upgrades.json",
	"spawn_curve": "res://data/spawn_curve.json",
	"fog": "res://data/fog.json",
	"sonar": "res://data/sonar.json",
	"noise": "res://data/noise.json",
	"characters": "res://data/characters.json",
	"maps": "res://data/maps.json",
	"hazards": "res://data/hazards.json",
	"events": "res://data/events.json"
}

const RARITY_WEIGHT: Dictionary = {
	"common": 70.0,
	"uncommon": 20.0,
	"rare": 8.0,
	"epic": 2.0,
	"legendary": 0.5
}

const RARITY_CONTEXT_POWER: Dictionary = {
	"common": 0.0,
	"uncommon": 0.45,
	"rare": 0.9,
	"epic": 1.35,
	"legendary": 1.8
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

const UPGRADE_ALLOWED_EFFECT_STATS: Dictionary = {
	"damage_mult": true,
	"attack_speed_mult": true,
	"projectile_speed_mult": true,
	"projectile_count_bonus": true,
	"pierce_bonus": true,
	"move_speed_bonus": true,
	"dash_cooldown_reduction": true,
	"max_hp": true,
	"heal": true,
	"regen_per_second": true,
	"xp_gain_mult": true,
	"noise_generation_mult": true,
	"noise_decay_bonus": true,
	"dash_noise_mult": true,
	"sonar_reveal_duration_mult": true,
	"revealed_damage_mult": true,
	"low_noise_damage_mult": true,
	"pickup_radius_mult": true,
	"summon_cap_bonus": true,
	"summon_resistance": true,
	"chain_bonus": true,
	"weapon_level_up": true,
	"weapon_level_up_active": true,
	"weapon_damage_mult": true,
	"weapon_attack_rate_mult": true,
	"weapon_range_mult": true,
	"weapon_projectile_speed_mult": true,
	"weapon_pierce_bonus": true,
	"weapon_crit_chance_add": true,
	"weapon_crit_multiplier_add": true,
	"weapon_aoe_radius_mult": true,
	"weapon_noise_mult": true,
	"weapon_noise_add": true,
	"weapon_projectile_count_bonus": true,
	"weapon_reveal_bonus_add": true,
	"weapon_summon_cap_bonus": true
}

const MAP_EVENT_TYPES: Dictionary = {
	"supply_pod": true,
	"abyss_rift": true,
	"quiet_pocket": true
}

const MAP_MODIFIER_KEYS: Dictionary = {
	"fog": {
		"vision_radius_mult": true,
		"noise_strength_add": true,
		"scanline_strength_add": true
	},
	"sonar": {
		"wave_speed_mult": true,
		"max_radius_mult": true,
		"reveal_duration_mult": true
	},
	"noise": {
		"gain_mult": true,
		"decay_mult": true
	},
	"spawner": {
		"spawn_rate_mult": true,
		"spawn_cap_mult": true,
		"pursuer_chance_add": true
	},
	"rewards": {
		"xp_mult": true
	}
}

const ENEMY_BEHAVIORS: Dictionary = {
	"drifter": true,
	"sprinter": true,
	"shooter": true,
	"shielded": true,
	"splitter": true,
	"bloater": true,
	"summoner": true,
	"lurker": true,
	"leech": true,
	"magnetoid": true,
	"pursuer": true,
	"boss": true
}

const ENEMY_REVEAL_REACTIONS: Dictionary = {
	"none": true,
	"stagger": true,
	"rage": true,
	"shield_break": true
}

const ENEMY_SPAWN_GROUPS: Dictionary = {
	"normal": true,
	"pursuer": true,
	"boss": true,
	"summon_only": true
}

const ELITE_ALLOWED_STAT_MULTIPLIERS: Dictionary = {
	"max_hp_mult": true,
	"speed_mult": true,
	"damage_mult": true,
	"threat_mult": true
}

const ELITE_ALLOWED_EFFECT_KEYS: Dictionary = {
	"damage_reduction": true,
	"death_explosion_radius": true,
	"death_explosion_damage": true,
	"sonar_reveal_mult": true,
	"jam_radius": true,
	"noise_aura_add": true,
	"pursuer_bonus": true,
	"xp_siphon_rate": true,
	"siphon_radius": true
}

const CONTRACT_MODIFIER_KEYS: Dictionary = {
	"fog": {
		"vision_radius_mult": true
	},
	"sonar": {
		"reveal_duration_mult": true,
		"max_radius_mult": true,
		"wave_speed_mult": true
	},
	"noise": {
		"gain_mult": true,
		"decay_mult": true
	},
	"spawner": {
		"spawn_rate_mult": true,
		"spawn_cap_mult": true,
		"pursuer_chance_add": true,
		"elite_chance_add": true
	},
	"events": {
		"rate_mult": true,
		"hazard_cycle_mult": true
	},
	"rewards": {
		"xp_mult": true,
		"rarity_mult": true,
		"drop_mult": true,
		"meta_currency_mult": true
	},
	"player": {
		"max_hp_mult": true,
		"dash_disabled": true,
		"low_noise_damage_mult": true,
		"high_noise_damage_mult": true
	},
	"enemy": {
		"speed_mult": true
	}
}

const CONTRACT_MODIFIER_DEFAULTS: Dictionary = {
	"fog": {
		"vision_radius_mult": 1.0
	},
	"sonar": {
		"reveal_duration_mult": 1.0,
		"max_radius_mult": 1.0,
		"wave_speed_mult": 1.0
	},
	"noise": {
		"gain_mult": 1.0,
		"decay_mult": 1.0
	},
	"spawner": {
		"spawn_rate_mult": 1.0,
		"spawn_cap_mult": 1.0,
		"pursuer_chance_add": 0.0,
		"elite_chance_add": 0.0
	},
	"events": {
		"rate_mult": 1.0,
		"hazard_cycle_mult": 1.0
	},
	"rewards": {
		"xp_mult": 1.0,
		"rarity_mult": 1.0,
		"drop_mult": 1.0,
		"meta_currency_mult": 1.0
	},
	"player": {
		"max_hp_mult": 1.0,
		"dash_disabled": 0.0,
		"low_noise_damage_mult": 1.0,
		"high_noise_damage_mult": 1.0
	},
	"enemy": {
		"speed_mult": 1.0
	}
}

var weapons: Dictionary = {}
var enemies: Dictionary = {}
var elites_config: Dictionary = {}
var bosses_config: Dictionary = {}
var contracts_config: Dictionary = {}
var upgrades: Array = []
var spawn_curve: Array = []
var fog_config: Dictionary = {}
var sonar_config: Dictionary = {}
var noise_config: Dictionary = {}
var characters_config: Dictionary = {}
var maps_config: Dictionary = {}
var hazards_config: Dictionary = {}
var events_config: Dictionary = {}
var characters: Dictionary = {}
var character_order: Array[String] = []
var maps: Dictionary = {}
var map_order: Array[String] = []
var hazards: Dictionary = {}
var event_tables: Dictionary = {}
var elite_affixes: Dictionary = {}
var elite_affix_order: Array[String] = []
var bosses: Dictionary = {}
var boss_order: Array[String] = []
var contracts: Dictionary = {}
var contract_order: Array[String] = []
var validation_errors: Array[String] = []
var loaded: bool = false


func _ready() -> void:
	if not loaded:
		load_all()


func load_all(log_errors: bool = true, path_overrides: Dictionary = {}) -> bool:
	validation_errors.clear()
	var resolved_files := _resolve_data_files(path_overrides)
	weapons = _load_dictionary(String(resolved_files["weapons"]), "weapons")
	enemies = _load_dictionary(String(resolved_files["enemies"]), "enemies")
	elites_config = _load_dictionary(String(resolved_files["elites"]), "elites")
	bosses_config = _load_dictionary(String(resolved_files["bosses"]), "bosses")
	contracts_config = _load_dictionary(String(resolved_files["contracts"]), "contracts")
	upgrades = _load_array_of_dictionaries(String(resolved_files["upgrades"]), "upgrades")
	spawn_curve = _load_array_of_dictionaries(String(resolved_files["spawn_curve"]), "spawn_curve")
	fog_config = _load_dictionary(String(resolved_files["fog"]), "fog")
	sonar_config = _load_dictionary(String(resolved_files["sonar"]), "sonar")
	noise_config = _load_dictionary(String(resolved_files["noise"]), "noise")
	characters_config = _load_dictionary(String(resolved_files["characters"]), "characters")
	maps_config = _load_dictionary(String(resolved_files["maps"]), "maps")
	hazards_config = _load_dictionary(String(resolved_files["hazards"]), "hazards")
	events_config = _load_dictionary(String(resolved_files["events"]), "events")
	characters.clear()
	character_order.clear()
	maps.clear()
	map_order.clear()
	hazards.clear()
	event_tables.clear()
	elite_affixes.clear()
	elite_affix_order.clear()
	bosses.clear()
	boss_order.clear()
	contracts.clear()
	contract_order.clear()

	_validate_weapons()
	_validate_characters()
	_validate_enemies()
	_validate_elites()
	_validate_bosses()
	_validate_contracts()
	_validate_upgrades()
	_validate_spawn_curve()
	_validate_fog()
	_validate_sonar()
	_validate_noise()
	_validate_hazards()
	_validate_events()
	_validate_maps()

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


func _resolve_data_files(path_overrides: Dictionary) -> Dictionary:
	var resolved := DATA_FILES.duplicate(true)
	for override_key_variant in path_overrides.keys():
		var override_key := String(override_key_variant).strip_edges().to_lower()
		if not resolved.has(override_key):
			validation_errors.append("[data] unknown override key '%s'" % override_key)
			continue
		var override_path := String(path_overrides.get(override_key_variant, "")).strip_edges()
		if override_path.is_empty():
			validation_errors.append("[data] override path for '%s' must be non-empty" % override_key)
			continue
		resolved[override_key] = override_path
	return resolved


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
		"elites":
			payload = elites_config
		"bosses":
			payload = bosses_config
		"contracts":
			payload = contracts_config
		"maps":
			payload = maps_config
		"hazards":
			payload = hazards_config
		"events":
			payload = events_config
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


func get_default_map_id() -> String:
	return String(maps_config.get("default_map_id", ""))


func _localize_dictionary_row(row: Dictionary) -> Dictionary:
	var output := row.duplicate(true)
	if Localization == null:
		return output
	if not Localization.has_method("localize_data_entry"):
		return output
	return Localization.call("localize_data_entry", output)


func _localize_dictionary_array(rows: Array) -> Array:
	var output: Array = []
	for row_variant in rows:
		if row_variant is Dictionary:
			output.append(_localize_dictionary_row(row_variant))
		else:
			output.append(row_variant)
	return output


func _noise_tier_name_from_id(tier_id: String, fallback_name: String) -> String:
	if Localization == null:
		return fallback_name
	if not Localization.has_method("data_field"):
		return fallback_name
	return String(Localization.call("data_field", tier_id, "name", fallback_name, {"id": tier_id, "name": fallback_name}))


func get_map(map_id: String) -> Dictionary:
	var payload: Variant = maps.get(map_id, {})
	if payload is Dictionary:
		return _localize_dictionary_row(payload as Dictionary)
	return {}


func has_map(map_id: String) -> bool:
	return maps.has(map_id)


func get_maps() -> Array:
	var output: Array = []
	for map_id in map_order:
		var map_variant: Variant = maps.get(map_id, {})
		if map_variant is Dictionary:
			output.append(_localize_dictionary_row(map_variant as Dictionary))
	return output


func get_hazard(hazard_id: String) -> Dictionary:
	var payload: Variant = hazards.get(hazard_id, {})
	if payload is Dictionary:
		return _localize_dictionary_row(payload as Dictionary)
	return {}


func get_event_table(event_table_id: String) -> Dictionary:
	var payload: Variant = event_tables.get(event_table_id, {})
	if payload is Dictionary:
		return _localize_event_table(payload as Dictionary)
	return {}


func _localize_event_table(event_table: Dictionary) -> Dictionary:
	var localized := _localize_dictionary_row(event_table)
	var events_variant: Variant = localized.get("events", [])
	if not (events_variant is Array):
		return localized
	var events: Array = events_variant
	var localized_events: Array = []
	for event_variant in events:
		if not (event_variant is Dictionary):
			localized_events.append(event_variant)
			continue
		var event: Dictionary = _localize_dictionary_row(event_variant as Dictionary)
		var event_id := String(event.get("id", "")).strip_edges()
		var immediate_variant: Variant = event.get("immediate", {})
		if immediate_variant is Dictionary:
			var immediate: Dictionary = (immediate_variant as Dictionary).duplicate(true)
			var message_fallback := String(immediate.get("message", ""))
			if not event_id.is_empty() and Localization != null and Localization.has_method("data_field"):
				immediate["message"] = String(Localization.call("data_field", event_id, "immediate_message", message_fallback, immediate))
			event["immediate"] = immediate
		localized_events.append(event)
	localized["events"] = localized_events
	return localized


func get_elite_affix(affix_id: String) -> Dictionary:
	var payload: Variant = elite_affixes.get(affix_id, {})
	if payload is Dictionary:
		return (payload as Dictionary).duplicate(true)
	return {}


func get_elite_affixes() -> Array:
	var output: Array = []
	for affix_id in elite_affix_order:
		var affix_variant: Variant = elite_affixes.get(affix_id, {})
		if affix_variant is Dictionary:
			output.append((affix_variant as Dictionary).duplicate(true))
	return output


func get_default_elite_chance() -> float:
	return float(elites_config.get("default_elite_chance", 0.0))


func get_max_active_elites() -> int:
	return maxi(0, int(elites_config.get("max_active_elites", 0)))


func get_boss(boss_id: String) -> Dictionary:
	var payload: Variant = bosses.get(boss_id, {})
	if payload is Dictionary:
		return (payload as Dictionary).duplicate(true)
	return {}


func get_bosses() -> Array:
	var output: Array = []
	for boss_id in boss_order:
		var boss_variant: Variant = bosses.get(boss_id, {})
		if boss_variant is Dictionary:
			output.append((boss_variant as Dictionary).duplicate(true))
	return output


func get_contract(contract_id: String) -> Dictionary:
	var payload: Variant = contracts.get(contract_id, {})
	if payload is Dictionary:
		return _localize_dictionary_row(payload as Dictionary)
	return {}


func get_contracts() -> Array:
	var output: Array = []
	for contract_id in contract_order:
		var contract_variant: Variant = contracts.get(contract_id, {})
		if contract_variant is Dictionary:
			output.append(_localize_dictionary_row(contract_variant as Dictionary))
	return output


func get_contract_max_select() -> int:
	return clampi(int(contracts_config.get("max_select", 0)), 0, 3)


func normalize_contract_selection(contract_ids: Array) -> Array[String]:
	var requested: Dictionary = {}
	for contract_id_variant in contract_ids:
		var contract_id := String(contract_id_variant).strip_edges()
		if contract_id.is_empty():
			continue
		if not contracts.has(contract_id):
			continue
		requested[contract_id] = true
	var selected: Array[String] = []
	var used_exclusive_groups: Dictionary = {}
	var max_select := get_contract_max_select()
	for contract_id in contract_order:
		if not requested.has(contract_id):
			continue
		var contract := get_contract(contract_id)
		if contract.is_empty():
			continue
		var exclusive_group := String(contract.get("exclusive_group", "")).strip_edges()
		if not exclusive_group.is_empty() and used_exclusive_groups.has(exclusive_group):
			continue
		selected.append(contract_id)
		if not exclusive_group.is_empty():
			used_exclusive_groups[exclusive_group] = true
		if max_select > 0 and selected.size() >= max_select:
			break
	return selected


func compose_contract_modifiers(contract_ids: Array) -> Dictionary:
	var selected := normalize_contract_selection(contract_ids)
	var composed := CONTRACT_MODIFIER_DEFAULTS.duplicate(true)
	var reward_pct_sum := 0.0
	for contract_id in selected:
		var contract := get_contract(contract_id)
		if contract.is_empty():
			continue
		reward_pct_sum += maxf(0.0, float(contract.get("reward_pct", 0.0)))
		var effects_variant: Variant = contract.get("effects", {})
		if not (effects_variant is Dictionary):
			continue
		var effects: Dictionary = effects_variant
		for group_key_variant in effects.keys():
			var group_key := String(group_key_variant).strip_edges().to_lower()
			if group_key.is_empty() or not composed.has(group_key):
				continue
			var source_group_variant: Variant = effects.get(group_key_variant, {})
			if not (source_group_variant is Dictionary):
				continue
			var source_group: Dictionary = source_group_variant
			var target_group_variant: Variant = composed.get(group_key, {})
			if not (target_group_variant is Dictionary):
				continue
			var target_group: Dictionary = target_group_variant
			for modifier_key_variant in source_group.keys():
				var modifier_key := String(modifier_key_variant).strip_edges()
				if modifier_key.is_empty() or not target_group.has(modifier_key):
					continue
				var source_value := float(source_group.get(modifier_key_variant, 0.0))
				if modifier_key.ends_with("_mult"):
					target_group[modifier_key] = maxf(0.05, float(target_group.get(modifier_key, 1.0)) * source_value)
				else:
					target_group[modifier_key] = float(target_group.get(modifier_key, 0.0)) + source_value
			composed[group_key] = target_group
	composed["selected_contracts"] = selected
	composed["reward_pct_sum"] = reward_pct_sum
	composed["reward_multiplier"] = 1.0 + reward_pct_sum / 100.0
	return composed


func get_contract_reward_preview(contract_ids: Array) -> Dictionary:
	var composed := compose_contract_modifiers(contract_ids)
	var rewards_variant: Variant = composed.get("rewards", {})
	var rewards: Dictionary = rewards_variant if rewards_variant is Dictionary else {}
	var reward_multiplier := float(composed.get("reward_multiplier", 1.0))
	var meta_from_rewards := float(rewards.get("meta_currency_mult", 1.0))
	var meta_multiplier := meta_from_rewards if not is_equal_approx(meta_from_rewards, 1.0) else reward_multiplier
	return {
		"selected_contracts": composed.get("selected_contracts", []),
		"reward_pct_sum": float(composed.get("reward_pct_sum", 0.0)),
		"reward_multiplier": reward_multiplier,
		"xp_mult": float(rewards.get("xp_mult", 1.0)),
		"rarity_mult": float(rewards.get("rarity_mult", 1.0)),
		"drop_mult": float(rewards.get("drop_mult", 1.0)),
		"meta_currency_mult": meta_multiplier
	}


func get_character(character_id: String) -> Dictionary:
	var payload: Variant = characters.get(character_id, {})
	if payload is Dictionary:
		return _localize_dictionary_row(payload as Dictionary)
	return {}


func has_character(character_id: String) -> bool:
	return characters.has(character_id)


func get_characters() -> Array:
	var output: Array = []
	for character_id in character_order:
		var character_variant: Variant = characters.get(character_id, {})
		if character_variant is Dictionary:
			output.append(_localize_dictionary_row(character_variant as Dictionary))
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
			var localized := tier.duplicate(true)
			localized["name"] = _noise_tier_name_from_id(String(localized.get("id", "")), String(localized.get("name", "Unknown")))
			return localized
	if not tiers.is_empty():
		var last: Variant = tiers.back()
		if last is Dictionary:
			var localized_last := (last as Dictionary).duplicate(true)
			localized_last["name"] = _noise_tier_name_from_id(String(localized_last.get("id", "")), String(localized_last.get("name", "Unknown")))
			return localized_last
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
		return _localize_dictionary_row(weapon_variant as Dictionary)
	return {}


func get_weapon_runtime(weapon_id: String) -> Dictionary:
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
			return _localize_dictionary_row(upgrade)
	return {}


func get_upgrade_choices(
	rng: RandomNumberGenerator,
	current_stacks: Dictionary,
	count: int = 3,
	tag_weights: Dictionary = {},
	context: Dictionary = {}
) -> Array:
	var runtime_context := context.duplicate(true)
	runtime_context["current_stacks"] = current_stacks.duplicate(true)
	var candidates := UpgradeRules.filter_candidates(upgrades, current_stacks, runtime_context)

	if candidates.is_empty():
		return []

	var picked: Array = []
	while picked.size() < count and not candidates.is_empty():
		var choice: Dictionary = _weighted_pick_upgrade(rng, candidates, tag_weights, runtime_context)
		picked.append(_localize_dictionary_row(choice))
		var chosen_id: String = String(choice.get("id", ""))
		var remaining: Array = []
		for item_variant in candidates:
			if not (item_variant is Dictionary):
				continue
			var item: Dictionary = item_variant
			if String(item.get("id", "")) != chosen_id:
				remaining.append(item)
		candidates = remaining

	# Keep UI consistent with a three-card level-up surface even when strict runtime
	# rules temporarily leave too few valid candidates.
	if picked.size() < count:
		var picked_ids := {}
		for picked_variant in picked:
			if picked_variant is Dictionary:
				var picked_row: Dictionary = picked_variant
				picked_ids[String(picked_row.get("id", ""))] = true
		var fallback_pool: Array = []
		for upgrade_variant in upgrades:
			if not (upgrade_variant is Dictionary):
				continue
			var upgrade: Dictionary = upgrade_variant
			var upgrade_id := String(upgrade.get("id", ""))
			if upgrade_id.is_empty() or picked_ids.has(upgrade_id):
				continue
			fallback_pool.append(upgrade)
		while picked.size() < count and not fallback_pool.is_empty():
			var fallback_choice: Dictionary = _weighted_pick_upgrade(rng, fallback_pool, tag_weights, runtime_context)
			picked.append(_localize_dictionary_row(fallback_choice))
			picked_ids[String(fallback_choice.get("id", ""))] = true
			var fallback_remaining: Array = []
			var chosen_fallback_id := String(fallback_choice.get("id", ""))
			for pool_variant in fallback_pool:
				if not (pool_variant is Dictionary):
					continue
				var pool_item: Dictionary = pool_variant
				if String(pool_item.get("id", "")) != chosen_fallback_id:
					fallback_remaining.append(pool_item)
			fallback_pool = fallback_remaining

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
	if enemies.size() < 10:
		validation_errors.append("[enemies] expected at least 10 enemy definitions, found %d" % enemies.size())
	var normalized_enemies: Dictionary = {}
	var normal_count := 0
	for enemy_key in enemies.keys():
		var enemy_variant: Variant = enemies[enemy_key]
		if not (enemy_variant is Dictionary):
			validation_errors.append("[enemies] %s must be a dictionary" % enemy_key)
			continue
		var enemy: Dictionary = enemy_variant
		var label := "enemies:%s" % String(enemy_key)
		_validate_required_keys(
			enemy,
			[
				"id",
				"name",
				"behavior",
				"spawn_group",
				"max_hp",
				"speed",
				"damage",
				"xp_reward",
				"contact_cooldown",
				"threat",
				"size",
				"color",
				"tags",
				"noise_aggression_scale",
				"reveal_reaction",
				"reveal_reaction_duration"
			],
			label
		)
		var enemy_id := String(enemy.get("id", String(enemy_key))).strip_edges()
		if enemy_id.is_empty():
			validation_errors.append("[%s] id must be non-empty string" % label)
			continue
		var behavior := String(enemy.get("behavior", "")).strip_edges().to_lower()
		if not ENEMY_BEHAVIORS.has(behavior):
			validation_errors.append("[%s] unsupported behavior '%s'" % [label, behavior])
		var spawn_group := String(enemy.get("spawn_group", "normal")).strip_edges().to_lower()
		if not ENEMY_SPAWN_GROUPS.has(spawn_group):
			validation_errors.append("[%s] unsupported spawn_group '%s'" % [label, spawn_group])
		if spawn_group == "normal":
			normal_count += 1
		var reveal_reaction := String(enemy.get("reveal_reaction", "none")).strip_edges().to_lower()
		if not ENEMY_REVEAL_REACTIONS.has(reveal_reaction):
			validation_errors.append("[%s] unsupported reveal_reaction '%s'" % [label, reveal_reaction])
		if float(enemy.get("max_hp", 0.0)) <= 0.0:
			validation_errors.append("[%s] max_hp must be > 0" % label)
		if float(enemy.get("speed", 0.0)) < 0.0:
			validation_errors.append("[%s] speed must be >= 0" % label)
		if float(enemy.get("damage", 0.0)) < 0.0:
			validation_errors.append("[%s] damage must be >= 0" % label)
		if int(enemy.get("xp_reward", 0)) < 0:
			validation_errors.append("[%s] xp_reward must be >= 0" % label)
		if float(enemy.get("contact_cooldown", 0.0)) <= 0.0:
			validation_errors.append("[%s] contact_cooldown must be > 0" % label)
		if float(enemy.get("threat", 0.0)) <= 0.0:
			validation_errors.append("[%s] threat must be > 0" % label)
		if float(enemy.get("size", 0.0)) <= 0.0:
			validation_errors.append("[%s] size must be > 0" % label)
		if float(enemy.get("noise_aggression_scale", 0.0)) < 0.0:
			validation_errors.append("[%s] noise_aggression_scale must be >= 0" % label)
		if float(enemy.get("reveal_reaction_duration", 0.0)) < 0.0:
			validation_errors.append("[%s] reveal_reaction_duration must be >= 0" % label)

		var tags_variant: Variant = enemy.get("tags", [])
		if not (tags_variant is Array):
			validation_errors.append("[%s] tags must be an array" % label)
		else:
			var tags: Array = tags_variant
			if tags.is_empty():
				validation_errors.append("[%s] tags must not be empty" % label)

		var normalized := enemy.duplicate(true)
		normalized["id"] = enemy_id
		normalized["behavior"] = behavior
		normalized["spawn_group"] = spawn_group
		normalized["reveal_reaction"] = reveal_reaction
		normalized_enemies[enemy_id] = normalized
	enemies = normalized_enemies
	if normal_count < 10:
		validation_errors.append("[enemies] expected at least 10 normal enemies, found %d" % normal_count)


func _validate_elites() -> void:
	_validate_required_keys(elites_config, ["schema_version", "default_elite_chance", "max_active_elites", "affixes"], "elites")
	var affixes_variant: Variant = elites_config.get("affixes", [])
	if not (affixes_variant is Array):
		validation_errors.append("[elites] affixes must be array")
		return
	var affixes: Array = affixes_variant
	if affixes.size() < 6:
		validation_errors.append("[elites] expected at least 6 elite affixes")
	var seen_ids: Dictionary = {}
	for i in range(affixes.size()):
		var affix_variant: Variant = affixes[i]
		if not (affix_variant is Dictionary):
			validation_errors.append("[elites:%d] affix must be dictionary" % i)
			continue
		var affix: Dictionary = affix_variant
		var label := "elites:%d" % i
		_validate_required_keys(
			affix,
			["id", "name", "description", "color", "stat_multipliers", "effects", "drop_bonus"],
			label
		)
		var affix_id := String(affix.get("id", "")).strip_edges()
		if affix_id.is_empty():
			validation_errors.append("[%s] id must be non-empty string" % label)
			continue
		if seen_ids.has(affix_id):
			validation_errors.append("[%s] duplicate affix id '%s'" % [label, affix_id])
			continue
		seen_ids[affix_id] = true

		var stat_mult_variant: Variant = affix.get("stat_multipliers", {})
		if not (stat_mult_variant is Dictionary):
			validation_errors.append("[%s] stat_multipliers must be dictionary" % label)
		else:
			var stat_mult: Dictionary = stat_mult_variant
			for stat_key_variant in stat_mult.keys():
				var stat_key := String(stat_key_variant).strip_edges()
				if not ELITE_ALLOWED_STAT_MULTIPLIERS.has(stat_key):
					validation_errors.append("[%s] unknown stat multiplier key '%s'" % [label, stat_key])
					continue
				if float(stat_mult.get(stat_key_variant, 0.0)) <= 0.0:
					validation_errors.append("[%s] stat multiplier '%s' must be > 0" % [label, stat_key])

		var effects_variant: Variant = affix.get("effects", {})
		if not (effects_variant is Dictionary):
			validation_errors.append("[%s] effects must be dictionary" % label)
		else:
			var effects: Dictionary = effects_variant
			for effect_key_variant in effects.keys():
				var effect_key := String(effect_key_variant).strip_edges()
				if not ELITE_ALLOWED_EFFECT_KEYS.has(effect_key):
					validation_errors.append("[%s] unknown effect key '%s'" % [label, effect_key])
					continue
				if float(effects.get(effect_key_variant, 0.0)) < 0.0:
					validation_errors.append("[%s] effect '%s' must be >= 0" % [label, effect_key])
		if float(affix.get("drop_bonus", 0.0)) < 0.0:
			validation_errors.append("[%s] drop_bonus must be >= 0" % label)

		var normalized := affix.duplicate(true)
		normalized["id"] = affix_id
		elite_affixes[affix_id] = normalized
		elite_affix_order.append(affix_id)

	if float(elites_config.get("default_elite_chance", 0.0)) < 0.0:
		validation_errors.append("[elites] default_elite_chance must be >= 0")
	if int(elites_config.get("max_active_elites", 0)) < 0:
		validation_errors.append("[elites] max_active_elites must be >= 0")


func _validate_bosses() -> void:
	_validate_required_keys(bosses_config, ["schema_version", "bosses"], "bosses")
	var rows_variant: Variant = bosses_config.get("bosses", [])
	if not (rows_variant is Array):
		validation_errors.append("[bosses] bosses must be array")
		return
	var rows: Array = rows_variant
	if rows.is_empty():
		validation_errors.append("[bosses] expected at least 1 boss")
	var seen_ids: Dictionary = {}
	for i in range(rows.size()):
		var row_variant: Variant = rows[i]
		if not (row_variant is Dictionary):
			validation_errors.append("[bosses:%d] boss must be dictionary" % i)
			continue
		var row: Dictionary = row_variant
		var label := "bosses:%d" % i
		_validate_required_keys(
			row,
			[
				"id",
				"name",
				"description",
				"spawn_time_seconds",
				"max_hp",
				"speed",
				"damage",
				"xp_reward",
				"size",
				"color",
				"phases"
			],
			label
		)
		var boss_id := String(row.get("id", "")).strip_edges()
		if boss_id.is_empty():
			validation_errors.append("[%s] id must be non-empty string" % label)
			continue
		if seen_ids.has(boss_id):
			validation_errors.append("[%s] duplicate boss id '%s'" % [label, boss_id])
			continue
		seen_ids[boss_id] = true
		if float(row.get("spawn_time_seconds", 0.0)) <= 0.0:
			validation_errors.append("[%s] spawn_time_seconds must be > 0" % label)
		if float(row.get("max_hp", 0.0)) <= 0.0:
			validation_errors.append("[%s] max_hp must be > 0" % label)
		if float(row.get("size", 0.0)) <= 0.0:
			validation_errors.append("[%s] size must be > 0" % label)
		if int(row.get("xp_reward", 0)) < 0:
			validation_errors.append("[%s] xp_reward must be >= 0" % label)
		var phases_variant: Variant = row.get("phases", [])
		if not (phases_variant is Array):
			validation_errors.append("[%s] phases must be array" % label)
			continue
		var phases: Array = phases_variant
		if phases.size() < 2:
			validation_errors.append("[%s] phases must include at least 2 entries" % label)
		var phase_ratios: Array[float] = []
		for p_idx in range(phases.size()):
			var phase_variant: Variant = phases[p_idx]
			if not (phase_variant is Dictionary):
				validation_errors.append("[%s:phase:%d] must be dictionary" % [label, p_idx])
				continue
			var phase: Dictionary = phase_variant
			_validate_required_keys(
				phase,
				["id", "start_hp_ratio", "label", "description", "telegraph_text", "attack_interval", "summon_interval", "summon_count"],
				"%s:phase:%d" % [label, p_idx]
			)
			var ratio := float(phase.get("start_hp_ratio", 0.0))
			if ratio <= 0.0 or ratio > 1.0:
				validation_errors.append("[%s:phase:%d] start_hp_ratio must be in (0, 1]" % [label, p_idx])
			phase_ratios.append(ratio)
		for ratio_idx in range(1, phase_ratios.size()):
			if phase_ratios[ratio_idx] > phase_ratios[ratio_idx - 1]:
				validation_errors.append("[%s] phase start_hp_ratio must be descending" % label)
				break
		var normalized := row.duplicate(true)
		normalized["id"] = boss_id
		bosses[boss_id] = normalized
		boss_order.append(boss_id)


func _validate_contracts() -> void:
	_validate_required_keys(contracts_config, ["schema_version", "max_select", "contracts"], "contracts")
	var max_select := int(contracts_config.get("max_select", 0))
	if max_select < 0 or max_select > 3:
		validation_errors.append("[contracts] max_select must be within [0, 3]")
	var rows_variant: Variant = contracts_config.get("contracts", [])
	if not (rows_variant is Array):
		validation_errors.append("[contracts] contracts must be array")
		return
	var rows: Array = rows_variant
	if rows.size() < 12:
		validation_errors.append("[contracts] expected at least 12 contracts")
	var seen_ids: Dictionary = {}
	for i in range(rows.size()):
		var row_variant: Variant = rows[i]
		if not (row_variant is Dictionary):
			validation_errors.append("[contracts:%d] contract must be dictionary" % i)
			continue
		var row: Dictionary = row_variant
		var label := "contracts:%d" % i
		_validate_required_keys(
			row,
			["id", "name", "description", "category", "reward_pct", "effects", "exclusive_group"],
			label
		)
		var contract_id := String(row.get("id", "")).strip_edges()
		if contract_id.is_empty():
			validation_errors.append("[%s] id must be non-empty string" % label)
			continue
		if seen_ids.has(contract_id):
			validation_errors.append("[%s] duplicate contract id '%s'" % [label, contract_id])
			continue
		seen_ids[contract_id] = true
		if float(row.get("reward_pct", 0.0)) < 0.0:
			validation_errors.append("[%s] reward_pct must be >= 0" % label)

		_validate_modifier_sections(
			row.get("effects", {}),
			CONTRACT_MODIFIER_KEYS,
			"%s:effects" % label
		)

		var normalized := row.duplicate(true)
		normalized["id"] = contract_id
		contracts[contract_id] = normalized
		contract_order.append(contract_id)


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
		var upgrade_has_invalid_effect := false
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
				upgrade_has_invalid_effect = true
				continue
			var effect: Dictionary = effect_variant
			_validate_required_keys(effect, ["stat", "add"], "%s:effect:%d" % [label, e_index])
			var stat := String(effect.get("stat", "")).strip_edges()
			if stat.is_empty():
				validation_errors.append("[%s] effect %d stat must be non-empty" % [label, e_index])
				upgrade_has_invalid_effect = true
				continue
			if not _is_known_upgrade_effect_stat(stat):
				validation_errors.append("[%s] effect %d unknown effect stat '%s'" % [label, e_index, stat])
				upgrade_has_invalid_effect = true
				continue
			var target_variant: Variant = effect.get("target", null)
			if target_variant == null:
				continue
			if not (target_variant is Dictionary):
				validation_errors.append("[%s] effect %d target must be dictionary" % [label, e_index])
				upgrade_has_invalid_effect = true
				continue
			var target: Dictionary = target_variant
			_validate_required_keys(target, ["type", "value"], "%s:effect:%d:target" % [label, e_index])
			var target_type := String(target.get("type", "")).strip_edges().to_lower()
			var target_value := String(target.get("value", "")).strip_edges().to_lower()
			if not UPGRADE_EFFECT_TARGET_TYPES.has(target_type):
				validation_errors.append("[%s] effect %d target type '%s' is unsupported" % [label, e_index, target_type])
				upgrade_has_invalid_effect = true
				continue
			if target_value.is_empty():
				validation_errors.append("[%s] effect %d target value must be non-empty" % [label, e_index])
				upgrade_has_invalid_effect = true
				continue
			if target_type == "weapon_id" and not weapons.has(target_value):
				validation_errors.append("[%s] effect %d unknown target weapon_id '%s'" % [label, e_index, target_value])
				upgrade_has_invalid_effect = true
			elif target_type == "tag" and not _is_known_upgrade_tag(target_value):
				validation_errors.append("[%s] effect %d unknown target tag '%s'" % [label, e_index, target_value])
				upgrade_has_invalid_effect = true

		if upgrade_has_invalid_effect:
			continue
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
		if float(profile.get("spawn_per_second", 0.0)) <= 0.0:
			validation_errors.append("[spawn_curve:%d] spawn_per_second must be > 0" % i)
		if int(profile.get("enemy_cap", 0)) <= 0:
			validation_errors.append("[spawn_curve:%d] enemy_cap must be > 0" % i)
		if not (profile.get("weights", {}) is Dictionary):
			validation_errors.append("[spawn_curve:%d] weights must be dictionary" % i)
		else:
			var weights: Dictionary = profile.get("weights", {})
			for enemy_id_variant in weights.keys():
				var enemy_id := String(enemy_id_variant).strip_edges()
				var weight := float(weights.get(enemy_id_variant, 0.0))
				if enemy_id.is_empty():
					validation_errors.append("[spawn_curve:%d] weights cannot contain empty enemy id" % i)
					continue
				if not enemies.has(enemy_id):
					validation_errors.append("[spawn_curve:%d] weights references unknown enemy '%s'" % [i, enemy_id])
					continue
				if weight < 0.0:
					validation_errors.append("[spawn_curve:%d] weight for '%s' must be >= 0" % [i, enemy_id])
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


func _validate_hazards() -> void:
	_validate_required_keys(hazards_config, ["schema_version", "hazards"], "hazards")
	var rows_variant: Variant = hazards_config.get("hazards", [])
	if not (rows_variant is Array):
		validation_errors.append("[hazards] hazards must be array")
		return
	var rows: Array = rows_variant
	var seen_ids: Dictionary = {}
	for i in range(rows.size()):
		var row_variant: Variant = rows[i]
		if not (row_variant is Dictionary):
			validation_errors.append("[hazards:%d] entry must be dictionary" % i)
			continue
		var row: Dictionary = row_variant
		_validate_required_keys(
			row,
			["id", "name", "description", "cycle_seconds", "active_seconds", "warning_text", "effects"],
			"hazards:%d" % i
		)
		var hazard_id := String(row.get("id", "")).strip_edges()
		if hazard_id.is_empty():
			validation_errors.append("[hazards:%d] id must be non-empty string" % i)
			continue
		if seen_ids.has(hazard_id):
			validation_errors.append("[hazards:%d] duplicate id '%s'" % [i, hazard_id])
			continue
		seen_ids[hazard_id] = true
		if float(row.get("cycle_seconds", 0.0)) <= 0.0:
			validation_errors.append("[hazards:%d] cycle_seconds must be > 0" % i)
		if float(row.get("active_seconds", 0.0)) <= 0.0:
			validation_errors.append("[hazards:%d] active_seconds must be > 0" % i)
		_validate_map_modifier_sections(row.get("effects", {}), "hazards:%d:effects" % i)
		hazards[hazard_id] = row.duplicate(true)


func _validate_events() -> void:
	_validate_required_keys(events_config, ["schema_version", "event_tables"], "events")
	var tables_variant: Variant = events_config.get("event_tables", [])
	if not (tables_variant is Array):
		validation_errors.append("[events] event_tables must be array")
		return
	var tables: Array = tables_variant
	var seen_table_ids: Dictionary = {}
	for i in range(tables.size()):
		var table_variant: Variant = tables[i]
		if not (table_variant is Dictionary):
			validation_errors.append("[events:%d] event table must be dictionary" % i)
			continue
		var table: Dictionary = table_variant
		_validate_required_keys(table, ["id", "name", "events"], "events:%d" % i)
		var table_id := String(table.get("id", "")).strip_edges()
		if table_id.is_empty():
			validation_errors.append("[events:%d] table id must be non-empty string" % i)
			continue
		if seen_table_ids.has(table_id):
			validation_errors.append("[events:%d] duplicate table id '%s'" % [i, table_id])
			continue
		seen_table_ids[table_id] = true
		var events_variant: Variant = table.get("events", [])
		if not (events_variant is Array):
			validation_errors.append("[events:%d] events must be array" % i)
			continue
		var events_rows: Array = events_variant
		var seen_event_ids: Dictionary = {}
		for e_idx in range(events_rows.size()):
			var event_variant: Variant = events_rows[e_idx]
			if not (event_variant is Dictionary):
				validation_errors.append("[events:%d:event:%d] entry must be dictionary" % [i, e_idx])
				continue
			var event: Dictionary = event_variant
			_validate_required_keys(
				event,
				[
					"id",
					"name",
					"description",
					"type",
					"weight",
					"cooldown_seconds",
					"min_time",
					"max_time",
					"duration_seconds",
					"effects",
					"immediate"
				],
				"events:%d:event:%d" % [i, e_idx]
			)
			var event_id := String(event.get("id", "")).strip_edges()
			if event_id.is_empty():
				validation_errors.append("[events:%d:event:%d] id must be non-empty string" % [i, e_idx])
				continue
			if seen_event_ids.has(event_id):
				validation_errors.append("[events:%d:event:%d] duplicate id '%s'" % [i, e_idx, event_id])
				continue
			seen_event_ids[event_id] = true

			var event_type := String(event.get("type", "")).strip_edges().to_lower()
			if not MAP_EVENT_TYPES.has(event_type):
				validation_errors.append("[events:%d:event:%d] unsupported type '%s'" % [i, e_idx, event_type])
			if float(event.get("weight", 0.0)) <= 0.0:
				validation_errors.append("[events:%d:event:%d] weight must be > 0" % [i, e_idx])
			if float(event.get("cooldown_seconds", 0.0)) < 0.0:
				validation_errors.append("[events:%d:event:%d] cooldown_seconds must be >= 0" % [i, e_idx])
			if float(event.get("max_time", 0.0)) <= float(event.get("min_time", 0.0)):
				validation_errors.append("[events:%d:event:%d] max_time must be > min_time" % [i, e_idx])
			_validate_map_modifier_sections(event.get("effects", {}), "events:%d:event:%d:effects" % [i, e_idx])
		event_tables[table_id] = table.duplicate(true)


func _validate_maps() -> void:
	_validate_required_keys(maps_config, ["schema_version", "default_map_id", "maps"], "maps")
	var rows_variant: Variant = maps_config.get("maps", [])
	if not (rows_variant is Array):
		validation_errors.append("[maps] maps must be array")
		return
	var rows: Array = rows_variant
	if rows.size() < 2:
		validation_errors.append("[maps] expected at least 2 map entries")
	var seen_ids: Dictionary = {}
	for i in range(rows.size()):
		var row_variant: Variant = rows[i]
		if not (row_variant is Dictionary):
			validation_errors.append("[maps:%d] entry must be dictionary" % i)
			continue
		var row: Dictionary = row_variant
		_validate_required_keys(
			row,
			[
				"id",
				"name",
				"description",
				"hazard_id",
				"event_table_id",
				"hazard_summary",
				"event_summary",
				"modifiers"
			],
			"maps:%d" % i
		)
		var map_id := String(row.get("id", "")).strip_edges()
		if map_id.is_empty():
			validation_errors.append("[maps:%d] id must be non-empty string" % i)
			continue
		if seen_ids.has(map_id):
			validation_errors.append("[maps:%d] duplicate id '%s'" % [i, map_id])
			continue
		seen_ids[map_id] = true

		var hazard_id := String(row.get("hazard_id", "")).strip_edges()
		var event_table_id := String(row.get("event_table_id", "")).strip_edges()
		if hazard_id.is_empty() or not hazards.has(hazard_id):
			validation_errors.append("[maps:%d] unknown hazard_id '%s'" % [i, hazard_id])
		if event_table_id.is_empty() or not event_tables.has(event_table_id):
			validation_errors.append("[maps:%d] unknown event_table_id '%s'" % [i, event_table_id])

		_validate_map_modifier_sections(row.get("modifiers", {}), "maps:%d:modifiers" % i)
		maps[map_id] = row.duplicate(true)
		map_order.append(map_id)

	var default_map_id := String(maps_config.get("default_map_id", "")).strip_edges()
	if default_map_id.is_empty():
		validation_errors.append("[maps] default_map_id must be non-empty string")
	elif not seen_ids.has(default_map_id):
		validation_errors.append("[maps] default_map_id '%s' not found in maps list" % default_map_id)


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


func _validate_map_modifier_sections(modifiers_variant: Variant, label: String) -> void:
	_validate_modifier_sections(modifiers_variant, MAP_MODIFIER_KEYS, label)


func _validate_modifier_sections(modifiers_variant: Variant, schema: Dictionary, label: String) -> void:
	if not (modifiers_variant is Dictionary):
		validation_errors.append("[%s] modifiers must be dictionary" % label)
		return
	var modifiers: Dictionary = modifiers_variant
	for group_key_variant in modifiers.keys():
		var group_key := String(group_key_variant).strip_edges().to_lower()
		if group_key.is_empty():
			validation_errors.append("[%s] modifier group key cannot be empty" % label)
			continue
		if not schema.has(group_key):
			validation_errors.append("[%s] unknown modifier group '%s'" % [label, group_key])
			continue
		var group_variant: Variant = modifiers.get(group_key_variant, {})
		if not (group_variant is Dictionary):
			validation_errors.append("[%s] modifier group '%s' must be dictionary" % [label, group_key])
			continue
		var group: Dictionary = group_variant
		var allowed_keys_variant: Variant = schema.get(group_key, {})
		var allowed_keys: Dictionary = allowed_keys_variant if allowed_keys_variant is Dictionary else {}
		for modifier_key_variant in group.keys():
			var modifier_key := String(modifier_key_variant).strip_edges()
			if modifier_key.is_empty():
				validation_errors.append("[%s] modifier key in '%s' cannot be empty" % [label, group_key])
				continue
			if not allowed_keys.has(modifier_key):
				validation_errors.append("[%s] unknown modifier key '%s.%s'" % [label, group_key, modifier_key])
				continue
			var value_variant: Variant = group.get(modifier_key_variant, null)
			if value_variant == null:
				validation_errors.append("[%s] modifier '%s.%s' cannot be null" % [label, group_key, modifier_key])
				continue
			if typeof(value_variant) != TYPE_FLOAT and typeof(value_variant) != TYPE_INT:
				validation_errors.append("[%s] modifier '%s.%s' must be numeric" % [label, group_key, modifier_key])
				continue


func _is_known_upgrade_tag(tag: String) -> bool:
	return UPGRADE_ALLOWED_TAGS.has(tag) or WEAPON_ALLOWED_TAGS.has(tag)


func _is_known_upgrade_effect_stat(stat: String) -> bool:
	return UPGRADE_ALLOWED_EFFECT_STATS.has(stat)


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


func _weighted_pick_upgrade(rng: RandomNumberGenerator, candidates: Array, tag_weights: Dictionary = {}, context: Dictionary = {}) -> Dictionary:
	var total: float = 0.0
	for candidate_variant in candidates:
		if not (candidate_variant is Dictionary):
			continue
		var candidate: Dictionary = candidate_variant
		total += _get_upgrade_weight(candidate, tag_weights, context)

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
		running += _get_upgrade_weight(candidate, tag_weights, context)
		if roll <= running:
			return candidate

	var last_candidate: Variant = candidates.back()
	if last_candidate is Dictionary:
		return last_candidate
	return {}


func _get_upgrade_weight(candidate: Dictionary, tag_weights: Dictionary, context: Dictionary = {}) -> float:
	var rarity: String = String(candidate.get("rarity", "common")).strip_edges().to_lower()
	var rarity_weight := float(RARITY_WEIGHT.get(rarity, 1.0))
	var base_weight := maxf(0.0001, float(candidate.get("base_weight", 1.0)))
	var total_base_weight := rarity_weight * base_weight
	var rarity_mult := clampf(float(context.get("rarity_mult", 1.0)), 0.25, 3.0)
	if not is_equal_approx(rarity_mult, 1.0):
		var rarity_power := float(RARITY_CONTEXT_POWER.get(rarity, 0.0))
		if rarity_power > 0.0:
			total_base_weight *= pow(rarity_mult, rarity_power)
	var active_weapon_id := String(context.get("active_weapon_id", "")).strip_edges().to_lower()
	if not active_weapon_id.is_empty():
		var requires_weapon_ids_variant: Variant = candidate.get("requires_weapon_ids", [])
		if requires_weapon_ids_variant is Array:
			var requires_weapon_ids: Array = requires_weapon_ids_variant
			if requires_weapon_ids.has(active_weapon_id):
				total_base_weight *= 1.15
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
