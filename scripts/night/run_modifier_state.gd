extends RefCounted
class_name RunModifierState

const MODIFIERS_PATH := "res://data/night_run_modifiers.json"
const BUILD_DIRECTION_TAGS := {
	"pressure": ["pressure", "damage", "volley", "crit", "burst", "aoe"],
	"silence": ["silence", "precision", "reveal", "quiet", "low_noise", "control"],
	"return": ["return", "economy", "meta", "drop", "sustain", "regen", "defense"],
	"mobility": ["mobility", "dash", "skirmish", "position", "speed", "afterimage"],
	"summon": ["summon", "device", "trap", "orbit", "drone", "guard"]
}
const CURSE_ENEMY_STEP := {
	"spawn_rate_mult": 1.04,
	"enemy_speed_mult": 1.03,
	"elite_chance_add": 0.02
}
const CURSE_REWARD_STEP := {
	"meta_currency": 0.97
}

var _modifier_defs: Dictionary = {}
var _base_reward_multipliers: Dictionary = _default_reward_multipliers()
var _current_reward_multipliers: Dictionary = _default_reward_multipliers()
var _current_enemy_modifiers: Dictionary = _default_enemy_modifiers()
var _claimed_rewards: Array[Dictionary] = []
var _applied_modifiers: Array[Dictionary] = []
var _system_modifiers: Array[Dictionary] = []
var _curse_level: int = 0
var _curse_events: Array[Dictionary] = []


func reset(base_reward_multipliers: Dictionary = {}) -> void:
	_ensure_loaded()
	_base_reward_multipliers = _normalize_reward_multipliers(base_reward_multipliers)
	_current_reward_multipliers = _base_reward_multipliers.duplicate(true)
	_current_enemy_modifiers = _default_enemy_modifiers()
	_claimed_rewards.clear()
	_applied_modifiers.clear()
	_system_modifiers.clear()
	_curse_level = 0
	_curse_events.clear()


func build_modifier_offer(modifier_id: String) -> Dictionary:
	var modifier := _get_modifier(modifier_id)
	if modifier.is_empty():
		return {}
	var category := String(modifier.get("category", "upgrade")).strip_edges().to_lower()
	var relic_rarity := ""
	if category == "relic":
		relic_rarity = String(modifier.get("relic_rarity", modifier.get("rarity", "rare"))).strip_edges().to_lower()
	var offer_rarity := String(modifier.get("offer_rarity", modifier.get("rarity", relic_rarity))).strip_edges().to_lower()
	var localized_label := _localized_modifier_field(
		modifier_id,
		"label",
		String(modifier.get("label", modifier_id.capitalize())).strip_edges(),
		modifier
	)
	var localized_summary := _localized_modifier_field(
		modifier_id,
		"summary",
		String(modifier.get("summary", "")).strip_edges(),
		modifier
	)
	var localized_description := _localized_modifier_field(
		modifier_id,
		"description",
		String(modifier.get("description", "")).strip_edges(),
		modifier
	)
	return {
		"id": String(modifier.get("id", modifier_id)).strip_edges(),
		"modifier_id": String(modifier.get("id", modifier_id)).strip_edges(),
		"offer_type": "modifier",
		"reward_kind": category,
		"reward_kind_label": _reward_kind_label(category),
		"label": localized_label,
		"summary": localized_summary,
		"description": localized_description,
		"build_direction": String(modifier.get("build_direction", "")).strip_edges().to_lower(),
		"tags": _normalize_tag_array(modifier.get("tags", [])),
		"offer_rarity": offer_rarity,
		"relic_rarity": relic_rarity,
		"unique": bool(modifier.get("unique", category == "relic")),
		"conflicts": _normalize_identifier_array(modifier.get("conflicts", [])),
		"conflict_groups": _normalize_identifier_array(modifier.get("conflict_groups", []))
	}


func has_modifier(modifier_id: String) -> bool:
	var normalized := modifier_id.strip_edges().to_lower()
	if normalized.is_empty():
		return false
	for row in _applied_modifiers:
		if String(row.get("id", "")).strip_edges().to_lower() == normalized:
			return true
	return false


func can_offer_modifier(modifier_id: String) -> bool:
	return bool(get_modifier_offer_availability(modifier_id).get("ok", false))


func get_modifier_offer_availability(modifier_id: String) -> Dictionary:
	var normalized := modifier_id.strip_edges().to_lower()
	if normalized.is_empty():
		return {
			"ok": false,
			"reason": "missing",
			"modifier_id": normalized
		}
	var modifier := _get_modifier(normalized)
	if modifier.is_empty():
		return {
			"ok": false,
			"reason": "missing",
			"modifier_id": normalized
		}
	var modifier_label := _localized_modifier_field(
		normalized,
		"label",
		String(modifier.get("label", normalized.capitalize())).strip_edges(),
		modifier
	)
	if has_modifier(normalized):
		return {
			"ok": false,
			"reason": "duplicate",
			"modifier_id": normalized,
			"blocked_modifier_id": normalized,
			"blocked_label": modifier_label
		}
	var candidate_conflicts := _normalize_identifier_array(modifier.get("conflicts", []))
	var candidate_groups := _normalize_identifier_array(modifier.get("conflict_groups", []))
	for row_variant in _applied_modifiers:
		if not (row_variant is Dictionary):
			continue
		var row: Dictionary = row_variant
		var applied_id := String(row.get("id", "")).strip_edges().to_lower()
		if applied_id.is_empty():
			continue
		var applied_modifier := _get_modifier(applied_id)
		var applied_conflicts := _normalize_identifier_array(applied_modifier.get("conflicts", []))
		var applied_groups := _normalize_identifier_array(applied_modifier.get("conflict_groups", []))
		var applied_label := String(row.get("label", "")).strip_edges()
		if applied_label.is_empty():
			applied_label = _localized_modifier_field(
				applied_id,
				"label",
				String(applied_modifier.get("label", applied_id.capitalize())).strip_edges(),
				applied_modifier
			)
		if candidate_conflicts.has(applied_id) or applied_conflicts.has(normalized):
			return {
				"ok": false,
				"reason": "conflict",
				"modifier_id": normalized,
				"blocked_modifier_id": applied_id,
				"blocked_label": applied_label
			}
		var blocked_group := _find_first_overlap(candidate_groups, applied_groups)
		if not blocked_group.is_empty():
			return {
				"ok": false,
				"reason": "conflict_group",
				"modifier_id": normalized,
				"blocked_modifier_id": applied_id,
				"blocked_label": applied_label,
				"blocked_group": blocked_group
			}
	return {
		"ok": true,
		"modifier_id": normalized,
		"label": modifier_label
	}


func apply_offer(offer: Dictionary, context: Dictionary = {}) -> Dictionary:
	var offer_type := String(offer.get("offer_type", "")).strip_edges().to_lower()
	if offer_type.is_empty():
		return {}
	if offer_type == "modifier":
		var availability := get_modifier_offer_availability(String(offer.get("modifier_id", offer.get("id", ""))).strip_edges().to_lower())
		if not bool(availability.get("ok", true)):
			return {}
	var offer_tags := _normalize_tag_array(offer.get("tags", offer.get("shop_tags", [])))
	var claimed_snapshot := {
		"id": String(offer.get("id", "")).strip_edges(),
		"offer_type": offer_type,
		"reward_kind": String(offer.get("reward_kind", "")).strip_edges().to_lower(),
		"reward_kind_label": String(offer.get("reward_kind_label", "")).strip_edges(),
		"label": String(offer.get("label", "")).strip_edges(),
		"summary": String(offer.get("summary", "")).strip_edges(),
		"room_id": String(context.get("room_id", "")).strip_edges(),
		"build_direction": String(offer.get("build_direction", offer.get("shrine_direction_id", ""))).strip_edges().to_lower(),
		"tags": offer_tags.duplicate(),
		"offer_rarity": String(offer.get("offer_rarity", "")).strip_edges().to_lower(),
		"relic_rarity": String(offer.get("relic_rarity", "")).strip_edges().to_lower()
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


func apply_system_modifier(modifier_id: String, context: Dictionary = {}, source_label: String = "system") -> Dictionary:
	var normalized_modifier_id := modifier_id.strip_edges().to_lower()
	var modifier := _get_modifier(normalized_modifier_id)
	if modifier.is_empty():
		return {}
	var category := String(modifier.get("category", "upgrade")).strip_edges().to_lower()
	var localized_label := _localized_modifier_field(
		normalized_modifier_id,
		"label",
		String(modifier.get("label", normalized_modifier_id.capitalize())).strip_edges(),
		modifier
	)
	var localized_summary := _localized_modifier_field(
		normalized_modifier_id,
		"summary",
		String(modifier.get("summary", "")).strip_edges(),
		modifier
	)
	var applied_snapshot := {
		"id": String(modifier.get("id", normalized_modifier_id)).strip_edges(),
		"source": source_label.strip_edges().to_lower(),
		"reward_kind": category,
		"reward_kind_label": _reward_kind_label(category),
		"label": localized_label,
		"summary": localized_summary
	}
	_apply_player_effects(_resolve_effects(modifier.get("effects", []), context), context)
	_apply_reward_multipliers(modifier.get("reward_multipliers", {}), context)
	_apply_enemy_modifiers(modifier.get("enemy_modifiers", {}), context)
	_system_modifiers.append(applied_snapshot.duplicate(true))
	return applied_snapshot


func get_reward_multipliers() -> Dictionary:
	return _current_reward_multipliers.duplicate(true)


func get_snapshot() -> Dictionary:
	return {
		"claimed_rewards": _claimed_rewards.duplicate(true),
		"claimed_relics": _filter_claimed_rewards_by_kind(_claimed_rewards, "relic"),
		"applied_modifiers": _applied_modifiers.duplicate(true),
		"system_modifiers": _system_modifiers.duplicate(true),
		"build_tags": get_build_tags(),
		"build_direction_scores": get_build_direction_scores(),
		"primary_build_direction": get_primary_build_direction(),
		"curse_level": _curse_level,
		"curse_events": _curse_events.duplicate(true),
		"reward_multipliers": _current_reward_multipliers.duplicate(true),
		"enemy_modifiers": _current_enemy_modifiers.duplicate(true)
	}


func get_build_tags() -> Array[String]:
	var build_tags: Array[String] = []
	for row_variant in _claimed_rewards:
		if not (row_variant is Dictionary):
			continue
		var row: Dictionary = row_variant
		var tags_variant: Variant = row.get("tags", [])
		if not (tags_variant is Array):
			continue
		for tag_variant in tags_variant:
			var tag := String(tag_variant).strip_edges().to_lower()
			if tag.is_empty() or build_tags.has(tag):
				continue
			build_tags.append(tag)
	return build_tags


func get_build_direction_scores() -> Dictionary:
	var build_tags := get_build_tags()
	var scores: Dictionary = {}
	for direction_id_variant in BUILD_DIRECTION_TAGS.keys():
		var direction_id := String(direction_id_variant)
		var direction_tags_variant: Variant = BUILD_DIRECTION_TAGS.get(direction_id_variant, [])
		var direction_tags: Array = direction_tags_variant if direction_tags_variant is Array else []
		var score := 0.0
		for tag_variant in direction_tags:
			var tag := String(tag_variant).strip_edges().to_lower()
			if build_tags.has(tag):
				score += 1.0
		scores[direction_id] = score
	return scores


func get_primary_build_direction() -> String:
	var scores := get_build_direction_scores()
	var best_direction := ""
	var best_score := 0.0
	for direction_id_variant in scores.keys():
		var direction_id := String(direction_id_variant)
		var score := float(scores.get(direction_id_variant, 0.0))
		if score <= best_score:
			continue
		best_score = score
		best_direction = direction_id
	return best_direction


func get_curse_level() -> int:
	return _curse_level


func add_curse(amount: int, context: Dictionary = {}, source_label: String = "curse", payload: Dictionary = {}) -> Dictionary:
	var curse_amount := maxi(0, amount)
	if curse_amount <= 0:
		return {}
	_curse_level += curse_amount
	var enemy_step := _build_curse_enemy_step(curse_amount)
	var reward_step := _build_curse_reward_step(curse_amount)
	_apply_enemy_modifiers(enemy_step, context)
	_apply_reward_multipliers(reward_step, context)
	var event := payload.duplicate(true)
	event["amount"] = curse_amount
	event["source"] = source_label.strip_edges().to_lower()
	event["room_id"] = String(context.get("room_id", event.get("room_id", ""))).strip_edges()
	event["curse_level"] = _curse_level
	event["enemy_modifiers"] = enemy_step.duplicate(true)
	event["reward_multipliers"] = reward_step.duplicate(true)
	_curse_events.append(event.duplicate(true))
	return event


func remove_curse(amount: int, context: Dictionary = {}, source_label: String = "cleanse", payload: Dictionary = {}) -> Dictionary:
	var curse_amount := mini(maxi(0, amount), _curse_level)
	if curse_amount <= 0:
		return {}
	_curse_level = maxi(0, _curse_level - curse_amount)
	var enemy_step := _build_curse_enemy_step(curse_amount)
	var reward_step := _build_curse_reward_step(curse_amount)
	_remove_enemy_modifiers(enemy_step, context)
	_remove_reward_multipliers(reward_step, context)
	var event := payload.duplicate(true)
	event["amount"] = -curse_amount
	event["source"] = source_label.strip_edges().to_lower()
	event["room_id"] = String(context.get("room_id", event.get("room_id", ""))).strip_edges()
	event["curse_level"] = _curse_level
	event["enemy_modifiers"] = enemy_step.duplicate(true)
	event["reward_multipliers"] = reward_step.duplicate(true)
	_curse_events.append(event.duplicate(true))
	return event


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


func _remove_reward_multipliers(source_variant: Variant, context: Dictionary) -> void:
	if not (source_variant is Dictionary):
		return
	var source: Dictionary = source_variant
	for key_variant in _current_reward_multipliers.keys():
		var key := String(key_variant)
		var divisor := float(source.get(key, source.get("%s_mult" % key, 1.0)))
		if is_zero_approx(divisor):
			continue
		_current_reward_multipliers[key] = maxf(0.0, float(_current_reward_multipliers.get(key, 1.0)) / divisor)
	var game_root_variant: Variant = context.get("game_root", null)
	if game_root_variant is Node and is_instance_valid(game_root_variant):
		var game_root: Node = game_root_variant
		if game_root.has_method("set_runtime_reward_multipliers"):
			game_root.call("set_runtime_reward_multipliers", _current_reward_multipliers)


func _remove_enemy_modifiers(source_variant: Variant, context: Dictionary) -> void:
	if not (source_variant is Dictionary):
		return
	var source: Dictionary = source_variant
	var spawn_rate_divisor := float(source.get("spawn_rate_mult", 1.0))
	if not is_zero_approx(spawn_rate_divisor):
		_current_enemy_modifiers["spawn_rate_mult"] = maxf(
			0.05,
			float(_current_enemy_modifiers.get("spawn_rate_mult", 1.0)) / spawn_rate_divisor
		)
	var spawn_cap_divisor := float(source.get("spawn_cap_mult", 1.0))
	if not is_zero_approx(spawn_cap_divisor):
		_current_enemy_modifiers["spawn_cap_mult"] = maxf(
			0.05,
			float(_current_enemy_modifiers.get("spawn_cap_mult", 1.0)) / spawn_cap_divisor
		)
	var speed_divisor := float(source.get("enemy_speed_mult", 1.0))
	if not is_zero_approx(speed_divisor):
		_current_enemy_modifiers["enemy_speed_mult"] = maxf(
			0.05,
			float(_current_enemy_modifiers.get("enemy_speed_mult", 1.0)) / speed_divisor
		)
	_current_enemy_modifiers["pursuer_chance_add"] = float(_current_enemy_modifiers.get("pursuer_chance_add", 0.0)) - float(source.get("pursuer_chance_add", 0.0))
	_current_enemy_modifiers["elite_chance_add"] = float(_current_enemy_modifiers.get("elite_chance_add", 0.0)) - float(source.get("elite_chance_add", 0.0))
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


func _localized_modifier_field(modifier_id: String, field: String, fallback: String, source: Dictionary = {}) -> String:
	if Localization != null and Localization.has_method("data_field"):
		return String(Localization.call("data_field", modifier_id, field, fallback, source))
	return fallback


func _normalize_tag_array(value: Variant) -> Array[String]:
	var rows: Array[String] = []
	if not (value is Array):
		return rows
	var source_rows: Array = value
	for row_variant in source_rows:
		var normalized := String(row_variant).strip_edges().to_lower()
		if normalized.is_empty() or rows.has(normalized):
			continue
		rows.append(normalized)
	return rows


func _normalize_identifier_array(value: Variant) -> Array[String]:
	var rows: Array[String] = []
	if not (value is Array):
		return rows
	var source_rows: Array = value
	for row_variant in source_rows:
		var normalized := String(row_variant).strip_edges().to_lower()
		if normalized.is_empty() or rows.has(normalized):
			continue
		rows.append(normalized)
	return rows


func _filter_claimed_rewards_by_kind(value: Variant, reward_kind: String) -> Array[Dictionary]:
	var rows: Array[Dictionary] = []
	if not (value is Array):
		return rows
	var normalized_kind := reward_kind.strip_edges().to_lower()
	for row_variant in (value as Array):
		if not (row_variant is Dictionary):
			continue
		var row: Dictionary = row_variant
		if String(row.get("reward_kind", "")).strip_edges().to_lower() != normalized_kind:
			continue
		rows.append(row.duplicate(true))
	return rows


func _find_first_overlap(left: Array[String], right: Array[String]) -> String:
	for left_value in left:
		if right.has(left_value):
			return left_value
	return ""


func _reward_kind_label(reward_kind: String) -> String:
	var normalized := reward_kind.strip_edges().to_lower()
	if Localization != null and Localization.has_method("t"):
		return String(Localization.call("t", "night.reward.kind.%s" % normalized))
	return normalized.capitalize()


func _default_enemy_modifiers() -> Dictionary:
	return {
		"spawn_rate_mult": 1.0,
		"spawn_cap_mult": 1.0,
		"enemy_speed_mult": 1.0,
		"pursuer_chance_add": 0.0,
		"elite_chance_add": 0.0
	}


func _build_curse_enemy_step(amount: int) -> Dictionary:
	var step_amount := maxi(0, amount)
	return {
		"spawn_rate_mult": pow(float(CURSE_ENEMY_STEP.get("spawn_rate_mult", 1.0)), step_amount),
		"enemy_speed_mult": pow(float(CURSE_ENEMY_STEP.get("enemy_speed_mult", 1.0)), step_amount),
		"elite_chance_add": float(CURSE_ENEMY_STEP.get("elite_chance_add", 0.0)) * step_amount
	}


func _build_curse_reward_step(amount: int) -> Dictionary:
	var step_amount := maxi(0, amount)
	return {
		"meta_currency": pow(float(CURSE_REWARD_STEP.get("meta_currency", 1.0)), step_amount)
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
