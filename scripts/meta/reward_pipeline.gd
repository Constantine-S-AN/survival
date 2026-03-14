extends RefCounted
class_name RewardPipeline

const CATEGORY_ORDER: Array[String] = [
	"common_materials",
	"rare_monster_ingredients",
	"special_seeds_spores",
	"unlock_tokens"
]
const FALLBACK_TABLE_ID := "completed_shallow"


func resolve_night_return(summary: Dictionary, day_state: Variant, economy: Variant, inventory: Variant) -> Dictionary:
	if DataRegistry == null or not DataRegistry.ensure_loaded():
		return {
			"session": _normalize_session(summary),
			"table_id": "",
			"table_name": "",
			"gold_reward": 0,
			"material_rewards": {},
			"loot_categories": [],
			"new_unlocks": [],
			"unlock_progress": [],
			"consumed_unlock_materials": {},
			"penalty": _build_penalty_payload({}, day_state)
		}

	var session := _normalize_session(summary)
	var loot_table := _select_loot_table(session)
	var gold_reward := _calculate_gold_reward(session, loot_table)
	if economy != null and economy.has_method("add_gold"):
		economy.call("add_gold", gold_reward)

	var reward_result := _collect_rewards(loot_table, session)
	var carryover_result := _collect_dungeon_carryover(summary, session)
	_merge_material_bundles(reward_result, carryover_result)
	var material_rewards: Dictionary = reward_result.get("material_rewards", {})
	for material_id_variant in material_rewards.keys():
		var material_id := String(material_id_variant).strip_edges().to_lower()
		var amount := int(material_rewards.get(material_id_variant, 0))
		if material_id.is_empty() or amount <= 0:
			continue
		if inventory != null and inventory.has_method("add_material"):
			inventory.call("add_material", material_id, amount)

	var unlock_result := _apply_unlocks(inventory, material_rewards)
	var penalty := _build_penalty_payload(loot_table.get("penalty", {}), day_state)
	if day_state != null and day_state.has_method("set_pending_next_day_stamina_penalty"):
		day_state.call("set_pending_next_day_stamina_penalty", int(penalty.get("stamina_loss", 0)))

	return {
		"session": session.duplicate(true),
		"table_id": String(loot_table.get("id", "")),
		"table_name": String(loot_table.get("name", "")),
		"gold_reward": gold_reward,
		"material_rewards": material_rewards.duplicate(true),
		"loot_categories": reward_result.get("loot_categories", []),
		"new_unlocks": unlock_result.get("new_unlocks", []),
		"unlock_progress": unlock_result.get("unlock_progress", []),
		"consumed_unlock_materials": unlock_result.get("consumed_unlock_materials", {}),
		"penalty": penalty,
		"carryover_rows": carryover_result.get("carryover_rows", [])
	}


func _normalize_session(summary: Dictionary) -> Dictionary:
	var exit_reason := String(summary.get("exit_reason", "")).strip_edges().to_lower()
	if exit_reason.is_empty():
		exit_reason = "abandoned" if bool(summary.get("abandoned", false)) else "completed"
	if exit_reason != "abandoned" and exit_reason != "extracted":
		exit_reason = "completed"
	var time_survived := maxf(0.0, float(summary.get("time_survived_sec", summary.get("survive_time_seconds", 0.0))))
	var kills := maxi(0, int(summary.get("kills", 0)))
	var drop_pickups := maxi(0, int(summary.get("drop_pickups_spawned", 0)))
	var score := kills + int(floor(time_survived / 30.0)) + int(floor(float(drop_pickups) / 3.0))
	return {
		"exit_reason": exit_reason,
		"time_survived_sec": time_survived,
		"kills": kills,
		"drop_pickups_spawned": drop_pickups,
		"score": maxi(0, score),
		"meta_currency_total": _extract_meta_currency_total(summary),
		"seed": int(summary.get("seed", 0))
	}


func _extract_meta_currency_total(summary: Dictionary) -> int:
	if summary.has("meta_currency_earned_total"):
		return maxi(0, int(summary.get("meta_currency_earned_total", 0)))
	var meta_variant: Variant = summary.get("meta_currency_earned", null)
	if meta_variant is Dictionary:
		return maxi(0, int((meta_variant as Dictionary).get("total", 0)))
	return maxi(0, int(summary.get("meta_currency_total", 0)))


func _select_loot_table(session: Dictionary) -> Dictionary:
	var best_match: Dictionary = {}
	var best_min_score := -1
	for table_variant in DataRegistry.get_night_loot_tables():
		if not (table_variant is Dictionary):
			continue
		var table: Dictionary = table_variant
		if not _table_matches_session(table, session):
			continue
		var min_score := int(table.get("min_score", 0))
		if min_score >= best_min_score:
			best_min_score = min_score
			best_match = table.duplicate(true)
	if not best_match.is_empty():
		return best_match
	return DataRegistry.get_night_loot_table(FALLBACK_TABLE_ID)


func _table_matches_session(table: Dictionary, session: Dictionary) -> bool:
	var exit_reason := String(session.get("exit_reason", "completed"))
	if bool(table.get("abandoned_only", false)) and exit_reason != "abandoned":
		return false
	if bool(table.get("extracted_only", false)) and exit_reason != "extracted":
		return false
	if bool(table.get("completed_only", false)) and exit_reason != "completed":
		return false
	if exit_reason == "extracted" and not bool(table.get("extracted_only", false)):
		return false
	var score := int(session.get("score", 0))
	return score >= int(table.get("min_score", 0)) and score <= int(table.get("max_score", 999999))


func _calculate_gold_reward(session: Dictionary, loot_table: Dictionary) -> int:
	var base_gold := maxi(1, int(session.get("meta_currency_total", 0)))
	var gold_multiplier := maxf(0.0, float(loot_table.get("gold_multiplier", 1.0)))
	if gold_multiplier <= 0.0:
		return 0
	return maxi(0, int(round(float(base_gold) * gold_multiplier)))


func _collect_rewards(loot_table: Dictionary, session: Dictionary) -> Dictionary:
	var rewards_variant: Variant = loot_table.get("rewards", [])
	var rewards: Array = rewards_variant if rewards_variant is Array else []
	var material_rewards: Dictionary = {}
	var category_bundles: Dictionary = {}
	for reward_variant in rewards:
		if not (reward_variant is Dictionary):
			continue
		var reward: Dictionary = reward_variant
		if not _reward_matches_session(reward, session):
			continue
		var material_id := String(reward.get("material_id", "")).strip_edges().to_lower()
		var amount := maxi(0, int(reward.get("quantity", 0)))
		if material_id.is_empty() or amount <= 0:
			continue
		material_rewards[material_id] = maxi(0, int(material_rewards.get(material_id, 0))) + amount
		var category := String(reward.get("category", DataRegistry.get_material_category(material_id))).strip_edges().to_lower()
		var bundle: Dictionary = category_bundles.get(category, {}) if category_bundles.get(category, {}) is Dictionary else {}
		bundle[material_id] = maxi(0, int(bundle.get(material_id, 0))) + amount
		category_bundles[category] = bundle
	return {
		"material_rewards": material_rewards,
		"loot_categories": _build_category_rows(category_bundles)
	}


func _reward_matches_session(reward: Dictionary, session: Dictionary) -> bool:
	var exit_reason := String(session.get("exit_reason", "completed"))
	if bool(reward.get("abandoned_only", false)) and exit_reason != "abandoned":
		return false
	if bool(reward.get("extracted_only", false)) and exit_reason != "extracted":
		return false
	if bool(reward.get("completed_only", false)) and exit_reason != "completed":
		return false
	if exit_reason == "extracted" and not bool(reward.get("extracted_only", false)) and bool(reward.get("completed_only", false)):
		return false
	if int(session.get("kills", 0)) < int(reward.get("min_kills", 0)):
		return false
	if float(session.get("time_survived_sec", 0.0)) < float(reward.get("min_time_survived_sec", 0.0)):
		return false
	return true


func _build_category_rows(category_bundles: Dictionary) -> Array[Dictionary]:
	var rows: Array[Dictionary] = []
	for category_id in CATEGORY_ORDER:
		var bundle_variant: Variant = category_bundles.get(category_id, {})
		if not (bundle_variant is Dictionary) or (bundle_variant as Dictionary).is_empty():
			continue
		rows.append({
			"category": category_id,
			"items": (bundle_variant as Dictionary).duplicate(true)
		})
	return rows


func _collect_dungeon_carryover(summary: Dictionary, session: Dictionary) -> Dictionary:
	var exit_reason := String(session.get("exit_reason", "completed")).strip_edges().to_lower()
	if exit_reason == "abandoned":
		return {
			"material_rewards": {},
			"loot_categories": [],
			"carryover_rows": _normalize_carryover_rows(summary.get("dungeon_carryover_rows", []))
		}
	var materials := _normalize_material_bundle(summary.get("dungeon_carryover_materials", {}))
	if materials.is_empty():
		return {
			"material_rewards": {},
			"loot_categories": [],
			"carryover_rows": _normalize_carryover_rows(summary.get("dungeon_carryover_rows", []))
		}
	var category_bundles: Dictionary = {}
	for material_id_variant in materials.keys():
		var material_id := String(material_id_variant).strip_edges().to_lower()
		var amount := int(materials.get(material_id_variant, 0))
		if material_id.is_empty() or amount <= 0:
			continue
		var category := String(DataRegistry.get_material_category(material_id)).strip_edges().to_lower()
		if category.is_empty():
			category = "common_materials"
		var bundle: Dictionary = category_bundles.get(category, {}) if category_bundles.get(category, {}) is Dictionary else {}
		bundle[material_id] = maxi(0, int(bundle.get(material_id, 0))) + amount
		category_bundles[category] = bundle
	return {
		"material_rewards": materials,
		"loot_categories": _build_category_rows(category_bundles),
		"carryover_rows": _normalize_carryover_rows(summary.get("dungeon_carryover_rows", []))
	}


func _merge_material_bundles(base_result: Dictionary, additive_result: Dictionary) -> void:
	var base_materials_variant: Variant = base_result.get("material_rewards", {})
	var base_materials: Dictionary = base_materials_variant if base_materials_variant is Dictionary else {}
	var additive_materials_variant: Variant = additive_result.get("material_rewards", {})
	var additive_materials: Dictionary = additive_materials_variant if additive_materials_variant is Dictionary else {}
	for material_id_variant in additive_materials.keys():
		var material_id := String(material_id_variant).strip_edges().to_lower()
		var amount := int(additive_materials.get(material_id_variant, 0))
		if material_id.is_empty() or amount <= 0:
			continue
		base_materials[material_id] = maxi(0, int(base_materials.get(material_id, 0))) + amount
	base_result["material_rewards"] = base_materials
	var base_loot_variant: Variant = base_result.get("loot_categories", [])
	var base_loot: Array = base_loot_variant if base_loot_variant is Array else []
	var additive_loot_variant: Variant = additive_result.get("loot_categories", [])
	var additive_loot: Array = additive_loot_variant if additive_loot_variant is Array else []
	for row_variant in additive_loot:
		if not (row_variant is Dictionary):
			continue
		base_loot.append((row_variant as Dictionary).duplicate(true))
	base_result["loot_categories"] = base_loot


func _normalize_material_bundle(value: Variant) -> Dictionary:
	var normalized: Dictionary = {}
	if not (value is Dictionary):
		return normalized
	for material_id_variant in (value as Dictionary).keys():
		var material_id := String(material_id_variant).strip_edges().to_lower()
		var amount := maxi(0, int((value as Dictionary).get(material_id_variant, 0)))
		if material_id.is_empty() or amount <= 0:
			continue
		normalized[material_id] = amount
	return normalized


func _normalize_carryover_rows(value: Variant) -> Array[Dictionary]:
	var rows: Array[Dictionary] = []
	if not (value is Array):
		return rows
	for row_variant in (value as Array):
		if not (row_variant is Dictionary):
			continue
		rows.append((row_variant as Dictionary).duplicate(true))
	return rows


func _apply_unlocks(inventory: Variant, reward_bundle: Dictionary) -> Dictionary:
	var new_unlocks: Array[Dictionary] = []
	var unlock_progress: Array[Dictionary] = []
	var consumed_unlock_materials: Dictionary = {}
	var reward_material_ids: Array[String] = []
	for material_id_variant in reward_bundle.keys():
		var material_id := String(material_id_variant).strip_edges().to_lower()
		if material_id.is_empty():
			continue
		reward_material_ids.append(material_id)

	for unlock_variant in DataRegistry.get_meta_unlocks():
		if not (unlock_variant is Dictionary):
			continue
		var unlock_def: Dictionary = unlock_variant
		var target_type := String(unlock_def.get("target_type", "")).strip_edges().to_lower()
		var target_id := String(unlock_def.get("target_id", "")).strip_edges().to_lower()
		if target_type.is_empty() or target_id.is_empty():
			continue
		var was_unlocked := _is_target_unlocked(inventory, target_type, target_id)
		var requirements := _normalize_requirement_bundle(unlock_def.get("requirements", {}))
		var relevant := not was_unlocked and _bundle_intersects_ids(requirements, reward_material_ids)
		if requirements.is_empty():
			continue
		var current_progress := _current_requirement_progress(inventory, requirements)
		var required_total := _required_requirement_total(requirements)
		var unlocked_now := false
		if not was_unlocked and _requirements_met(inventory, requirements):
			unlocked_now = _unlock_target(inventory, target_type, target_id)
			if unlocked_now and bool(unlock_def.get("consume_requirements", true)):
				for material_id in requirements.keys():
					var amount := int(requirements.get(material_id, 0))
					if amount <= 0:
						continue
					if inventory != null and inventory.has_method("remove_material"):
						inventory.call("remove_material", material_id, amount)
					consumed_unlock_materials[material_id] = maxi(0, int(consumed_unlock_materials.get(material_id, 0))) + amount
				current_progress = required_total
			if unlocked_now:
				new_unlocks.append({
					"type": target_type,
					"id": target_id,
					"name": _resolve_unlock_target_name(target_type, target_id),
					"unlock_name": String(unlock_def.get("name", target_id))
				})
		if relevant or unlocked_now:
			unlock_progress.append({
				"id": String(unlock_def.get("id", "")),
				"name": String(unlock_def.get("name", "")),
				"target_type": target_type,
				"target_id": target_id,
				"target_name": _resolve_unlock_target_name(target_type, target_id),
				"current": mini(required_total, current_progress),
				"required": required_total,
				"requirements": requirements.duplicate(true),
				"complete": was_unlocked or unlocked_now,
				"unlocked": unlocked_now
			})
	return {
		"new_unlocks": new_unlocks,
		"unlock_progress": unlock_progress,
		"consumed_unlock_materials": consumed_unlock_materials
	}


func _normalize_requirement_bundle(value: Variant) -> Dictionary:
	var normalized: Dictionary = {}
	if not (value is Dictionary):
		return normalized
	for material_id_variant in (value as Dictionary).keys():
		var material_id := String(material_id_variant).strip_edges().to_lower()
		var amount := maxi(0, int((value as Dictionary).get(material_id_variant, 0)))
		if material_id.is_empty() or amount <= 0:
			continue
		normalized[material_id] = amount
	return normalized


func _bundle_intersects_ids(requirements: Dictionary, ids: Array[String]) -> bool:
	for material_id in requirements.keys():
		if ids.has(String(material_id)):
			return true
	return false


func _current_requirement_progress(inventory: Variant, requirements: Dictionary) -> int:
	var total := 0
	for material_id_variant in requirements.keys():
		var material_id := String(material_id_variant)
		var required_amount := maxi(0, int(requirements.get(material_id_variant, 0)))
		total += mini(required_amount, _get_material_amount(inventory, material_id))
	return total


func _required_requirement_total(requirements: Dictionary) -> int:
	var total := 0
	for amount_variant in requirements.values():
		total += maxi(0, int(amount_variant))
	return total


func _requirements_met(inventory: Variant, requirements: Dictionary) -> bool:
	for material_id_variant in requirements.keys():
		var material_id := String(material_id_variant)
		if _get_material_amount(inventory, material_id) < int(requirements.get(material_id_variant, 0)):
			return false
	return true


func _get_material_amount(inventory: Variant, material_id: String) -> int:
	if inventory == null or not inventory.has_method("get_material_amount"):
		return 0
	return maxi(0, int(inventory.call("get_material_amount", material_id)))


func _is_target_unlocked(inventory: Variant, target_type: String, target_id: String) -> bool:
	if inventory == null:
		return false
	match target_type:
		"recipe":
			return bool(inventory.call("has_recipe", target_id)) if inventory.has_method("has_recipe") else false
		"seed":
			return bool(inventory.call("has_seed", target_id)) if inventory.has_method("has_seed") else false
		_:
			return false


func _unlock_target(inventory: Variant, target_type: String, target_id: String) -> bool:
	if inventory == null:
		return false
	match target_type:
		"recipe":
			return bool(inventory.call("unlock_recipe", target_id)) if inventory.has_method("unlock_recipe") else false
		"seed":
			return bool(inventory.call("unlock_seed", target_id)) if inventory.has_method("unlock_seed") else false
		_:
			return false


func _resolve_unlock_target_name(target_type: String, target_id: String) -> String:
	match target_type:
		"recipe":
			return String(DataRegistry.get_recipe(target_id).get("name", target_id.capitalize()))
		"seed":
			return String(DataRegistry.get_seed(target_id).get("name", target_id.capitalize()))
		_:
			return target_id.capitalize()


func _build_penalty_payload(penalty_variant: Variant, day_state: Variant) -> Dictionary:
	var penalty: Dictionary = penalty_variant if penalty_variant is Dictionary else {}
	var stamina_loss := maxi(0, int(penalty.get("stamina_loss", 0)))
	var max_stamina := 0
	if day_state != null:
		max_stamina = maxi(0, int(day_state.get("max_stamina")))
	return {
		"applied": stamina_loss > 0,
		"type": String(penalty.get("type", "")).strip_edges().to_lower(),
		"stamina_loss": stamina_loss,
		"next_day_stamina": clampi(max_stamina - stamina_loss, 0, max_stamina) if max_stamina > 0 else 0
	}
