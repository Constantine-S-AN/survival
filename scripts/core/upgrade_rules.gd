extends RefCounted
class_name UpgradeRules

const NOISE_TIER_ORDER: Dictionary = {
	"silent": 0,
	"alert": 1,
	"exposed": 2
}


static func filter_candidates(upgrades: Array, current_stacks: Dictionary, context: Dictionary = {}) -> Array:
	var output: Array = []
	var lookup: Dictionary = _build_lookup(upgrades)
	var selected_ids: Array[String] = _get_selected_ids(current_stacks)
	var selected_id_set: Dictionary = {}
	for selected_id in selected_ids:
		selected_id_set[selected_id] = true
	var selected_groups: Dictionary = _collect_selected_groups(selected_ids, lookup)
	var selected_blocks: Dictionary = _collect_selected_blocks(selected_ids, lookup)

	for upgrade_variant in upgrades:
		if not (upgrade_variant is Dictionary):
			continue
		var upgrade: Dictionary = upgrade_variant
		if _is_upgrade_available(
			upgrade,
			current_stacks,
			context,
			selected_id_set,
			selected_groups,
			selected_blocks
		):
			output.append(upgrade)
	return output


static func _is_upgrade_available(
	upgrade: Dictionary,
	current_stacks: Dictionary,
	context: Dictionary,
	selected_id_set: Dictionary,
	selected_groups: Dictionary,
	selected_blocks: Dictionary
) -> bool:
	var upgrade_id := String(upgrade.get("id", "")).strip_edges()
	if upgrade_id.is_empty():
		return false

	var current_rank := int(current_stacks.get(upgrade_id, 0))
	var max_rank := int(upgrade.get("max_rank", upgrade.get("max_stacks", 1)))
	if current_rank >= max_rank:
		return false

	if selected_blocks.has(upgrade_id):
		return false

	var exclusive_group := String(upgrade.get("exclusive_group", "")).strip_edges()
	if not exclusive_group.is_empty() and selected_groups.has(exclusive_group):
		var chosen_id := String(selected_groups.get(exclusive_group, ""))
		if chosen_id != upgrade_id:
			return false

	var candidate_blocks_variant: Variant = upgrade.get("blocks", [])
	if candidate_blocks_variant is Array:
		var candidate_blocks: Array = candidate_blocks_variant
		for blocked_variant in candidate_blocks:
			var blocked_id := String(blocked_variant).strip_edges()
			if blocked_id.is_empty():
				continue
			if selected_id_set.has(blocked_id):
				return false

	if not _validate_requires_tags(upgrade, context):
		return false
	if not _validate_requires_weapon_ids(upgrade, context):
		return false
	if not _validate_prereq(upgrade, current_stacks, context):
		return false

	return true


static func _validate_requires_tags(upgrade: Dictionary, context: Dictionary) -> bool:
	var requires_tags_variant: Variant = upgrade.get("requires_tags", [])
	if not (requires_tags_variant is Array):
		return true
	var requires_tags: Array = requires_tags_variant
	if requires_tags.is_empty():
		return true

	var acquired_tags_variant: Variant = context.get("acquired_tags", {})
	var acquired_tags: Dictionary = acquired_tags_variant if acquired_tags_variant is Dictionary else {}
	for tag_variant in requires_tags:
		var required_tag := String(tag_variant).strip_edges().to_lower()
		if required_tag.is_empty():
			continue
		if int(acquired_tags.get(required_tag, 0)) <= 0:
			return false
	return true


static func _validate_requires_weapon_ids(upgrade: Dictionary, context: Dictionary) -> bool:
	var requires_weapon_ids_variant: Variant = upgrade.get("requires_weapon_ids", [])
	if not (requires_weapon_ids_variant is Array):
		return true
	var requires_weapon_ids: Array = requires_weapon_ids_variant
	if requires_weapon_ids.is_empty():
		return true

	var current_weapon_ids := _normalize_string_array(context.get("current_weapon_ids", []))
	if current_weapon_ids.is_empty():
		return false
	for required_weapon_id_variant in requires_weapon_ids:
		var required_weapon_id := String(required_weapon_id_variant).strip_edges().to_lower()
		if required_weapon_id.is_empty():
			continue
		if current_weapon_ids.has(required_weapon_id):
			return true
	return false


static func _validate_prereq(upgrade: Dictionary, current_stacks: Dictionary, context: Dictionary) -> bool:
	var prereq_variant: Variant = upgrade.get("prereq", {})
	if not (prereq_variant is Dictionary):
		return true
	var prereq: Dictionary = prereq_variant

	var all_variant: Variant = prereq.get("all", [])
	if all_variant is Array:
		for condition_variant in all_variant:
			if not (condition_variant is Dictionary):
				return false
			if not _evaluate_condition(condition_variant as Dictionary, current_stacks, context):
				return false

	var any_variant: Variant = prereq.get("any", [])
	if any_variant is Array:
		var any_rules: Array = any_variant
		if not any_rules.is_empty():
			var any_met := false
			for condition_variant in any_rules:
				if not (condition_variant is Dictionary):
					continue
				if _evaluate_condition(condition_variant as Dictionary, current_stacks, context):
					any_met = true
					break
			if not any_met:
				return false

	return true


static func _evaluate_condition(condition: Dictionary, current_stacks: Dictionary, context: Dictionary) -> bool:
	var condition_type := String(condition.get("type", "")).strip_edges().to_lower()
	match condition_type:
		"upgrade_selected":
			var upgrade_id := String(condition.get("upgrade_id", "")).strip_edges()
			return int(current_stacks.get(upgrade_id, 0)) > 0
		"upgrade_rank_at_least":
			var rank_upgrade_id := String(condition.get("upgrade_id", "")).strip_edges()
			var value := int(condition.get("value", 1))
			return int(current_stacks.get(rank_upgrade_id, 0)) >= value
		"has_tag":
			var tag := String(condition.get("tag", "")).strip_edges().to_lower()
			var acquired_tags_variant: Variant = context.get("acquired_tags", {})
			var acquired_tags: Dictionary = acquired_tags_variant if acquired_tags_variant is Dictionary else {}
			return int(acquired_tags.get(tag, 0)) > 0
		"weapon_owned":
			var owned_weapon := String(condition.get("weapon_id", "")).strip_edges().to_lower()
			var current_weapon_ids := _normalize_string_array(context.get("current_weapon_ids", []))
			return current_weapon_ids.has(owned_weapon)
		"weapon_is_active":
			var active_weapon := String(context.get("active_weapon_id", "")).strip_edges().to_lower()
			var required_active := String(condition.get("weapon_id", "")).strip_edges().to_lower()
			return not active_weapon.is_empty() and active_weapon == required_active
		"player_level_at_least":
			return int(context.get("player_level", 1)) >= int(condition.get("value", 1))
		"survive_time_seconds_at_least":
			return float(context.get("survive_time_seconds", 0.0)) >= float(condition.get("value", 0.0))
		"noise_tier_at_least":
			var current_tier := String(context.get("noise_tier_id", "silent")).strip_edges().to_lower()
			var required_tier := String(condition.get("tier_id", "silent")).strip_edges().to_lower()
			return int(NOISE_TIER_ORDER.get(current_tier, 0)) >= int(NOISE_TIER_ORDER.get(required_tier, 0))
		_:
			return true


static func _build_lookup(upgrades: Array) -> Dictionary:
	var lookup: Dictionary = {}
	for upgrade_variant in upgrades:
		if not (upgrade_variant is Dictionary):
			continue
		var upgrade: Dictionary = upgrade_variant
		var upgrade_id := String(upgrade.get("id", "")).strip_edges()
		if upgrade_id.is_empty():
			continue
		lookup[upgrade_id] = upgrade
	return lookup


static func _get_selected_ids(current_stacks: Dictionary) -> Array[String]:
	var selected_ids: Array[String] = []
	for key_variant in current_stacks.keys():
		var upgrade_id := String(key_variant).strip_edges()
		if upgrade_id.is_empty():
			continue
		if int(current_stacks.get(key_variant, 0)) <= 0:
			continue
		selected_ids.append(upgrade_id)
	return selected_ids


static func _collect_selected_groups(selected_ids: Array[String], lookup: Dictionary) -> Dictionary:
	var result: Dictionary = {}
	for upgrade_id in selected_ids:
		var upgrade_variant: Variant = lookup.get(upgrade_id, {})
		if not (upgrade_variant is Dictionary):
			continue
		var upgrade: Dictionary = upgrade_variant
		var group := String(upgrade.get("exclusive_group", "")).strip_edges()
		if group.is_empty():
			continue
		result[group] = upgrade_id
	return result


static func _collect_selected_blocks(selected_ids: Array[String], lookup: Dictionary) -> Dictionary:
	var result: Dictionary = {}
	for upgrade_id in selected_ids:
		var upgrade_variant: Variant = lookup.get(upgrade_id, {})
		if not (upgrade_variant is Dictionary):
			continue
		var upgrade: Dictionary = upgrade_variant
		var blocks_variant: Variant = upgrade.get("blocks", [])
		if not (blocks_variant is Array):
			continue
		var blocks: Array = blocks_variant
		for block_variant in blocks:
			var blocked_upgrade_id := String(block_variant).strip_edges()
			if blocked_upgrade_id.is_empty():
				continue
			result[blocked_upgrade_id] = upgrade_id
	return result


static func _normalize_string_array(source: Variant) -> Array[String]:
	var output: Array[String] = []
	if not (source is Array):
		return output
	var rows: Array = source
	for row_variant in rows:
		var text := String(row_variant).strip_edges().to_lower()
		if text.is_empty() or output.has(text):
			continue
		output.append(text)
	return output
