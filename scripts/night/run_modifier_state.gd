extends RefCounted
class_name RunModifierState

const MODIFIERS_PATH := "res://data/night_run_modifiers.json"

var _modifier_defs: Dictionary = {}
var _base_reward_multipliers: Dictionary = _default_reward_multipliers()
var _current_reward_multipliers: Dictionary = _default_reward_multipliers()
var _current_enemy_modifiers: Dictionary = _default_enemy_modifiers()
var _claimed_rewards: Array[Dictionary] = []
var _applied_modifiers: Array[Dictionary] = []


func reset(base_reward_multipliers: Dictionary = {}) -> void:
	_ensure_loaded()
	_base_reward_multipliers = _normalize_reward_multipliers(base_reward_multipliers)
	_current_reward_multipliers = _base_reward_multipliers.duplicate(true)
	_current_enemy_modifiers = _default_enemy_modifiers()
	_claimed_rewards.clear()
	_applied_modifiers.clear()


func build_modifier_offer(modifier_id: String) -> Dictionary:
	var modifier := _get_modifier(modifier_id)
	if modifier.is_empty():
		return {}
	var category := String(modifier.get("category", "upgrade")).strip_edges().to_lower()
	return {
		"id": String(modifier.get("id", modifier_id)).strip_edges(),
		"modifier_id": String(modifier.get("id", modifier_id)).strip_edges(),
		"offer_type": "modifier",
		"reward_kind": category,
		"label": String(modifier.get("label", modifier_id.capitalize())).strip_edges(),
		"summary": String(modifier.get("summary", "")).strip_edges(),
		"description": String(modifier.get("description", "")).strip_edges()
	}


func has_modifier(modifier_id: String) -> bool:
	var normalized := modifier_id.strip_edges().to_lower()
	if normalized.is_empty():
		return false
	for row in _applied_modifiers:
		if String(row.get("id", "")).strip_edges().to_lower() == normalized:
			return true
	return false


func apply_offer(offer: Dictionary, context: Dictionary = {}) -> Dictionary:
	var offer_type := String(offer.get("offer_type", "")).strip_edges().to_lower()
	if offer_type.is_empty():
		return {}
	var claimed_snapshot := {
		"id": String(offer.get("id", "")).strip_edges(),
		"offer_type": offer_type,
		"reward_kind": String(offer.get("reward_kind", "")).strip_edges().to_lower(),
		"label": String(offer.get("label", "")).strip_edges(),
		"summary": String(offer.get("summary", "")).strip_edges(),
		"room_id": String(context.get("room_id", "")).strip_edges()
	}

	match offer_type:
		"modifier":
			var modifier_id := String(offer.get("modifier_id", offer.get("id", ""))).strip_edges().to_lower()
			var modifier := _get_modifier(modifier_id)
			if modifier.is_empty():
				return {}
			_apply_player_effects(_resolve_effects(modifier.get("effects", []), context), context)
			_apply_reward_multipliers(modifier.get("reward_multipliers", {}), context)
			_apply_enemy_modifiers(modifier.get("enemy_modifiers", {}), context)
			_applied_modifiers.append(claimed_snapshot.duplicate(true))
		"bundle":
			var bundle_variant: Variant = offer.get("bundle_data", {})
			var bundle: Dictionary = bundle_variant if bundle_variant is Dictionary else {}
			_apply_player_effects(_resolve_effects(bundle.get("player_effects", []), context), context)
			_apply_reward_multipliers(bundle.get("reward_multipliers", {}), context)
			_apply_enemy_modifiers(bundle.get("enemy_modifiers", {}), context)
			_apply_instant_bundle(bundle.get("instant", {}), context)
		_:
			return {}

	_claimed_rewards.append(claimed_snapshot.duplicate(true))
	return claimed_snapshot


func get_reward_multipliers() -> Dictionary:
	return _current_reward_multipliers.duplicate(true)


func get_snapshot() -> Dictionary:
	return {
		"claimed_rewards": _claimed_rewards.duplicate(true),
		"applied_modifiers": _applied_modifiers.duplicate(true),
		"reward_multipliers": _current_reward_multipliers.duplicate(true),
		"enemy_modifiers": _current_enemy_modifiers.duplicate(true)
	}


func _get_modifier(modifier_id: String) -> Dictionary:
	_ensure_loaded()
	var normalized := modifier_id.strip_edges().to_lower()
	if normalized.is_empty():
		return {}
	var modifier_variant: Variant = _modifier_defs.get(normalized, {})
	return modifier_variant if modifier_variant is Dictionary else {}


func _apply_player_effects(effects_variant: Variant, context: Dictionary) -> void:
	if not (effects_variant is Array):
		return
	var player_variant: Variant = context.get("player", null)
	if not (player_variant is Node) or not is_instance_valid(player_variant):
		return
	var player: Node = player_variant
	if player.has_method("apply_runtime_effects"):
		player.call("apply_runtime_effects", effects_variant)


func _apply_reward_multipliers(source_variant: Variant, context: Dictionary) -> void:
	if not (source_variant is Dictionary):
		return
	var source: Dictionary = source_variant
	for key_variant in _current_reward_multipliers.keys():
		var key := String(key_variant)
		var incoming := float(source.get(key, source.get("%s_mult" % key, 1.0)))
		_current_reward_multipliers[key] = maxf(0.0, float(_current_reward_multipliers.get(key, 1.0)) * incoming)
	var game_root_variant: Variant = context.get("game_root", null)
	if game_root_variant is Node and is_instance_valid(game_root_variant):
		var game_root: Node = game_root_variant
		if game_root.has_method("set_runtime_reward_multipliers"):
			game_root.call("set_runtime_reward_multipliers", _current_reward_multipliers)


func _apply_enemy_modifiers(source_variant: Variant, context: Dictionary) -> void:
	if not (source_variant is Dictionary):
		return
	var source: Dictionary = source_variant
	_current_enemy_modifiers["spawn_rate_mult"] = maxf(
		0.05,
		float(_current_enemy_modifiers.get("spawn_rate_mult", 1.0)) * float(source.get("spawn_rate_mult", 1.0))
	)
	_current_enemy_modifiers["spawn_cap_mult"] = maxf(
		0.05,
		float(_current_enemy_modifiers.get("spawn_cap_mult", 1.0)) * float(source.get("spawn_cap_mult", 1.0))
	)
	_current_enemy_modifiers["enemy_speed_mult"] = maxf(
		0.05,
		float(_current_enemy_modifiers.get("enemy_speed_mult", 1.0)) * float(source.get("enemy_speed_mult", 1.0))
	)
	_current_enemy_modifiers["pursuer_chance_add"] = float(_current_enemy_modifiers.get("pursuer_chance_add", 0.0)) + float(source.get("pursuer_chance_add", 0.0))
	_current_enemy_modifiers["elite_chance_add"] = float(_current_enemy_modifiers.get("elite_chance_add", 0.0)) + float(source.get("elite_chance_add", 0.0))
	var enemy_manager_variant: Variant = context.get("enemy_manager", null)
	if enemy_manager_variant is Node and is_instance_valid(enemy_manager_variant):
		var enemy_manager: Node = enemy_manager_variant
		if enemy_manager.has_method("set_map_spawn_modifiers"):
			enemy_manager.call("set_map_spawn_modifiers", _current_enemy_modifiers)


func _apply_instant_bundle(bundle_variant: Variant, context: Dictionary) -> void:
	if not (bundle_variant is Dictionary):
		return
	var bundle: Dictionary = bundle_variant
	var world_variant: Variant = context.get("world", null)
	var player_variant: Variant = context.get("player", null)
	var player: Node = player_variant if player_variant is Node and is_instance_valid(player_variant) else null
	var origin := _coerce_vector2(context.get("origin", Vector2.ZERO))

	if world_variant is Node and is_instance_valid(world_variant):
		var world: Node = world_variant
		var pickup_count := clampi(int(bundle.get("xp_pickups", 0)), 0, 12)
		var xp_amount := clampi(int(bundle.get("xp_amount", 0)), 0, 100)
		for pickup_index in range(pickup_count):
			if not world.has_method("spawn_xp_pickup"):
				break
			var angle := TAU * float(pickup_index) / maxf(1.0, float(pickup_count))
			var radius := 24.0 + float(pickup_index % 3) * 14.0
			world.call_deferred("spawn_xp_pickup", origin + Vector2.RIGHT.rotated(angle) * radius, xp_amount)

	if player != null:
		var should_emit_stats := false
		var heal_pct := clampf(float(bundle.get("heal_pct", 0.0)), 0.0, 1.0)
		if heal_pct > 0.0:
			var max_hp := float(player.get("max_hp"))
			var hp := float(player.get("hp"))
			player.set("hp", minf(max_hp, hp + max_hp * heal_pct))
			should_emit_stats = true
		var heal_flat := maxf(0.0, float(bundle.get("heal_flat", 0.0)))
		if heal_flat > 0.0:
			var bundle_max_hp := float(player.get("max_hp"))
			var bundle_hp := float(player.get("hp"))
			player.set("hp", minf(bundle_max_hp, bundle_hp + heal_flat))
			should_emit_stats = true
		var noise_delta := float(bundle.get("noise_delta", 0.0))
		if not is_zero_approx(noise_delta) and player.has_method("add_noise_delta"):
			player.call("add_noise_delta", noise_delta)
			should_emit_stats = true
		var xp_bonus := maxi(0, int(bundle.get("xp_bonus", 0)))
		if xp_bonus > 0 and player.has_method("gain_xp"):
			player.call("gain_xp", xp_bonus)
			should_emit_stats = false
		if should_emit_stats and player.has_method("emit_stats_changed"):
			player.call("emit_stats_changed")


func _resolve_effects(effects_variant: Variant, context: Dictionary) -> Array[Dictionary]:
	if not (effects_variant is Array):
		return []
	var resolved: Array[Dictionary] = []
	for effect_variant in effects_variant:
		if not (effect_variant is Dictionary):
			continue
		var effect: Dictionary = (effect_variant as Dictionary).duplicate(true)
		var target_variant: Variant = effect.get("target", null)
		if target_variant is Dictionary:
			var target: Dictionary = (target_variant as Dictionary).duplicate(true)
			var target_value := String(target.get("value", "")).strip_edges()
			if target_value == "$active_weapon":
				var active_weapon_id := _resolve_active_weapon_id(context)
				if active_weapon_id.is_empty():
					continue
				target["value"] = active_weapon_id
			effect["target"] = target
		resolved.append(effect)
	return resolved


func _resolve_active_weapon_id(context: Dictionary) -> String:
	var player_variant: Variant = context.get("player", null)
	if player_variant is Node and is_instance_valid(player_variant):
		return String((player_variant as Node).get("active_weapon_id")).strip_edges().to_lower()
	return ""


func _ensure_loaded() -> void:
	if not _modifier_defs.is_empty():
		return
	var payload := _load_json_dictionary(MODIFIERS_PATH)
	var rows_variant: Variant = payload.get("modifiers", [])
	if not (rows_variant is Array):
		return
	for row_variant in rows_variant:
		if not (row_variant is Dictionary):
			continue
		var row: Dictionary = row_variant
		var modifier_id := String(row.get("id", "")).strip_edges().to_lower()
		if modifier_id.is_empty():
			continue
		_modifier_defs[modifier_id] = row.duplicate(true)


func _normalize_reward_multipliers(source: Dictionary = {}) -> Dictionary:
	return {
		"xp": maxf(0.0, float(source.get("xp", source.get("xp_mult", 1.0)))),
		"rarity": maxf(0.0, float(source.get("rarity", source.get("rarity_mult", 1.0)))),
		"drop": maxf(0.0, float(source.get("drop", source.get("drop_mult", 1.0)))),
		"meta_currency": maxf(0.0, float(source.get("meta_currency", source.get("meta_currency_mult", 1.0))))
	}


func _default_reward_multipliers() -> Dictionary:
	return {
		"xp": 1.0,
		"rarity": 1.0,
		"drop": 1.0,
		"meta_currency": 1.0
	}


func _default_enemy_modifiers() -> Dictionary:
	return {
		"spawn_rate_mult": 1.0,
		"spawn_cap_mult": 1.0,
		"enemy_speed_mult": 1.0,
		"pursuer_chance_add": 0.0,
		"elite_chance_add": 0.0
	}


func _coerce_vector2(value: Variant) -> Vector2:
	if value is Vector2:
		return value
	if value is Array:
		var parts: Array = value
		if parts.size() >= 2:
			return Vector2(float(parts[0]), float(parts[1]))
	if value is Dictionary:
		var payload: Dictionary = value
		return Vector2(float(payload.get("x", 0.0)), float(payload.get("y", 0.0)))
	return Vector2.ZERO


func _load_json_dictionary(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if parsed is Dictionary:
		return (parsed as Dictionary).duplicate(true)
	return {}
