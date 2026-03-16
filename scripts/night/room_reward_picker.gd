extends RefCounted
class_name RoomRewardPicker

const REWARD_TABLE_PATHS := [
	"res://data/night_reward_tables.json",
	"res://data/night_reward_tables_v2.json"
]
const SCHEMA_CONTRACT_VERSION := 1
const SUPPORTED_OFFER_TYPES := {
	"bundle": true,
	"modifier": true
}
const BUNDLE_SCHEMA_FIELDS: Array[String] = [
	"id",
	"schema_contract_version",
	"reward_kind",
	"label",
	"label_zh",
	"summary",
	"summary_zh",
	"description",
	"description_zh",
	"instant",
	"reward_multipliers",
	"route_resources"
]
const TABLE_SCHEMA_FIELDS: Array[String] = [
	"id",
	"schema_contract_version",
	"draws",
	"slots",
	"category_weights",
	"reward_groups"
]
const SHRINE_POOL_SCHEMA_FIELDS: Array[String] = [
	"id",
	"schema_contract_version",
	"fallback_direction_id",
	"directions"
]
const SHRINE_DIRECTION_SCHEMA_FIELDS: Array[String] = [
	"id",
	"label",
	"label_zh",
	"cost_type",
	"cost_value",
	"entries",
	"route_resources"
]
const TABLE_SLOT_SCHEMA_FIELDS: Array[String] = [
	"id",
	"offer_type",
	"entries"
]
const REWARD_GROUP_SCHEMA_FIELDS: Array[String] = [
	"offer_type",
	"entries"
]
const SHOP_INVENTORY_SCHEMA_FIELDS: Array[String] = [
	"id",
	"schema_contract_version",
	"refresh_cost_xp",
	"refresh_cost_step_xp",
	"refresh_cost_cap_xp",
	"slots"
]
const SHOP_SLOT_SCHEMA_FIELDS: Array[String] = [
	"id",
	"label",
	"label_zh",
	"offer_type",
	"price_offset",
	"lockable",
	"rare_slot",
	"rarity",
	"entries"
]
const SHOP_ENTRY_SCHEMA_FIELDS: Array[String] = [
	"id",
	"weight",
	"tags",
	"theme_weights",
	"build_tag_weights",
	"rarity"
]
const BUNDLE_DEFAULTS := {
	"reward_kind": "currency",
	"instant": {},
	"reward_multipliers": {},
	"route_resources": {}
}
const TABLE_DEFAULTS := {
	"draws": 3,
	"slots": [],
	"category_weights": {},
	"reward_groups": {}
}
const SHOP_INVENTORY_DEFAULTS := {
	"refresh_cost_xp": 18,
	"refresh_cost_step_xp": 6,
	"refresh_cost_cap_xp": 36,
	"slots": []
}
const SHOP_SLOT_DEFAULTS := {
	"offer_type": "modifier",
	"price_offset": 0,
	"lockable": true,
	"rare_slot": false,
	"rarity": "standard",
	"entries": []
}
const SHOP_ENTRY_DEFAULTS := {
	"weight": 1.0,
	"tags": [],
	"theme_weights": {},
	"build_tag_weights": {},
	"rarity": "standard"
}
const SHRINE_POOL_DEFAULTS := {
	"fallback_direction_id": "",
	"directions": []
}
const SHRINE_DIRECTION_DEFAULTS := {
	"cost_type": "hp_or_noise",
	"cost_value": 0,
	"entries": [],
	"route_resources": {}
}
const COMPATIBILITY_RULES := {
	"missing_schema_contract_version": "warn_and_normalize",
	"legacy_rolls_field_alias": "draws",
	"missing_reward_groups": "fallback_to_slots",
	"missing_shop_inventories": "treat_as_empty_array",
	"missing_shrine_pools": "treat_as_empty_array"
}
const SUPPORTED_INTERACTION_COST_TYPES := {
	"hp": true,
	"noise": true,
	"curse": true,
	"hp_or_noise": true
}

var _tables_by_id: Dictionary = {}
var _bundles_by_id: Dictionary = {}
var _shop_inventories_by_id: Dictionary = {}
var _shrine_pools_by_id: Dictionary = {}
var _schema_warnings: Array[String] = []


func build_room_rewards(
	run_seed: int,
	room_state,
	encounter_payload: Dictionary,
	rooms_cleared_total: int,
	run_modifier_state
) -> Array[Dictionary]:
	_ensure_loaded()
	var table_id := String(encounter_payload.get("reward_table_id", "")).strip_edges()
	if table_id.is_empty():
		var category := String(encounter_payload.get("encounter_category", "standard")).strip_edges().to_lower()
		table_id = "combat_%s" % category
	var table_variant: Variant = _tables_by_id.get(table_id, {})
	if not (table_variant is Dictionary):
		return []
	var table: Dictionary = table_variant
	var reward_groups_variant: Variant = table.get("reward_groups", {})
	if reward_groups_variant is Dictionary and not (reward_groups_variant as Dictionary).is_empty():
		return _build_grouped_room_rewards(
			table,
			table_id,
			run_seed,
			room_state,
			encounter_payload,
			rooms_cleared_total,
			run_modifier_state
		)
	var slots_variant: Variant = table.get("slots", [])
	if not (slots_variant is Array):
		return []

	var rewards: Array[Dictionary] = []
	var slots: Array = slots_variant
	for slot_index in range(slots.size()):
		var slot_variant: Variant = slots[slot_index]
		if not (slot_variant is Dictionary):
			continue
		var slot: Dictionary = slot_variant
		var slot_seed := _build_room_seed(run_seed, room_state, encounter_payload, rooms_cleared_total, slot_index)
		var offer := _pick_offer_for_slot(slot, slot_seed, run_modifier_state)
		if offer.is_empty():
			continue
		offer["offer_id"] = "%s_reward_%d" % [String(room_state.room_id), slot_index]
		offer["reward_table_id"] = table_id
		offer["slot_id"] = String(slot.get("id", "slot_%d" % slot_index)).strip_edges()
		rewards.append(offer)
	return rewards


func _build_grouped_room_rewards(
	table: Dictionary,
	table_id: String,
	run_seed: int,
	room_state,
	encounter_payload: Dictionary,
	rooms_cleared_total: int,
	run_modifier_state
) -> Array[Dictionary]:
	var reward_groups_variant: Variant = table.get("reward_groups", {})
	if not (reward_groups_variant is Dictionary):
		return []
	var reward_groups: Dictionary = reward_groups_variant
	var category_weights_variant: Variant = table.get("category_weights", {})
	var category_weights: Dictionary = category_weights_variant if category_weights_variant is Dictionary else {}
	var draw_count := maxi(1, int(table.get("draws", table.get("rolls", 3))))
	var chosen_offer_ids: Array[String] = []
	var rewards: Array[Dictionary] = []
	for draw_index in range(draw_count):
		var draw_seed := _build_room_seed(run_seed, room_state, encounter_payload, rooms_cleared_total, draw_index)
		var offer := _pick_offer_from_grouped_table(
			reward_groups,
			category_weights,
			draw_seed,
			run_modifier_state,
			chosen_offer_ids
		)
		if offer.is_empty():
			continue
		var offer_id := String(offer.get("id", offer.get("modifier_id", ""))).strip_edges().to_lower()
		if not offer_id.is_empty() and not chosen_offer_ids.has(offer_id):
			chosen_offer_ids.append(offer_id)
		offer["offer_id"] = "%s_reward_%d" % [String(room_state.room_id), draw_index]
		offer["reward_table_id"] = table_id
		offer["slot_id"] = "draw_%d" % draw_index
		rewards.append(offer)
	return rewards


func build_bundle_offer(bundle_id: String) -> Dictionary:
	_ensure_loaded()
	return _build_bundle_offer(bundle_id)


func get_schema_contract() -> Dictionary:
	return {
		"contract_version": SCHEMA_CONTRACT_VERSION,
		"bundle_fields": BUNDLE_SCHEMA_FIELDS.duplicate(),
		"table_fields": TABLE_SCHEMA_FIELDS.duplicate(),
		"shrine_pool_fields": SHRINE_POOL_SCHEMA_FIELDS.duplicate(),
		"shrine_direction_fields": SHRINE_DIRECTION_SCHEMA_FIELDS.duplicate(),
		"table_slot_fields": TABLE_SLOT_SCHEMA_FIELDS.duplicate(),
		"reward_group_fields": REWARD_GROUP_SCHEMA_FIELDS.duplicate(),
		"shop_inventory_fields": SHOP_INVENTORY_SCHEMA_FIELDS.duplicate(),
		"shop_slot_fields": SHOP_SLOT_SCHEMA_FIELDS.duplicate(),
		"shop_entry_fields": SHOP_ENTRY_SCHEMA_FIELDS.duplicate(),
		"supported_offer_types": SUPPORTED_OFFER_TYPES.keys(),
		"supported_interaction_cost_types": SUPPORTED_INTERACTION_COST_TYPES.keys(),
		"supported_route_resource_types": ["key", "curse", "contract"],
		"defaults": {
			"bundle": BUNDLE_DEFAULTS.duplicate(true),
			"table": TABLE_DEFAULTS.duplicate(true),
			"shrine_pool": SHRINE_POOL_DEFAULTS.duplicate(true),
			"shrine_direction": SHRINE_DIRECTION_DEFAULTS.duplicate(true),
			"shop_inventory": SHOP_INVENTORY_DEFAULTS.duplicate(true),
			"shop_slot": SHOP_SLOT_DEFAULTS.duplicate(true),
			"shop_entry": SHOP_ENTRY_DEFAULTS.duplicate(true)
		},
		"compatibility": COMPATIBILITY_RULES.duplicate(true)
	}


func get_schema_warnings() -> Array[String]:
	_ensure_loaded()
	return _schema_warnings.duplicate()


func get_reward_table(table_id: String) -> Dictionary:
	_ensure_loaded()
	var normalized_id := table_id.strip_edges()
	if normalized_id.is_empty():
		return {}
	var table_variant: Variant = _tables_by_id.get(normalized_id, {})
	return table_variant.duplicate(true) if table_variant is Dictionary else {}


func get_bundle_definition(bundle_id: String) -> Dictionary:
	_ensure_loaded()
	var normalized_id := bundle_id.strip_edges().to_lower()
	if normalized_id.is_empty():
		return {}
	var bundle_variant: Variant = _bundles_by_id.get(normalized_id, {})
	return bundle_variant.duplicate(true) if bundle_variant is Dictionary else {}


func get_shop_inventory(inventory_id: String) -> Dictionary:
	_ensure_loaded()
	var normalized_id := inventory_id.strip_edges().to_lower()
	if normalized_id.is_empty():
		return {}
	var inventory_variant: Variant = _shop_inventories_by_id.get(normalized_id, {})
	return inventory_variant.duplicate(true) if inventory_variant is Dictionary else {}


func get_shrine_pool(pool_id: String) -> Dictionary:
	_ensure_loaded()
	var normalized_id := pool_id.strip_edges().to_lower()
	if normalized_id.is_empty():
		return {}
	var pool_variant: Variant = _shrine_pools_by_id.get(normalized_id, {})
	return pool_variant.duplicate(true) if pool_variant is Dictionary else {}


func build_shop_inventory_offers(
	inventory_id: String,
	shop_seed: int,
	shop_context: Dictionary,
	run_modifier_state,
	locked_offers_by_slot: Dictionary = {},
	excluded_offer_ids: Array[String] = []
) -> Array[Dictionary]:
	_ensure_loaded()
	var inventory := get_shop_inventory(inventory_id)
	if inventory.is_empty():
		return []
	var offers: Array[Dictionary] = []
	var chosen_offer_ids: Array[String] = _normalize_identifier_array(excluded_offer_ids)
	var refresh_count := maxi(0, int(shop_context.get("refresh_count", 0)))
	var slots_variant: Variant = inventory.get("slots", [])
	if not (slots_variant is Array):
		return offers
	for slot_variant in slots_variant:
		if not (slot_variant is Dictionary):
			continue
		var slot: Dictionary = slot_variant
		var slot_id := String(slot.get("id", "")).strip_edges().to_lower()
		if slot_id.is_empty():
			continue
		var locked_variant: Variant = locked_offers_by_slot.get(slot_id, {})
		if locked_variant is Dictionary and not (locked_variant as Dictionary).is_empty():
			var locked_offer: Dictionary = (locked_variant as Dictionary).duplicate(true)
			_apply_shop_slot_metadata(locked_offer, slot)
			locked_offer["shop_locked"] = true
			offers.append(locked_offer)
			var locked_offer_id := _resolve_offer_id(locked_offer)
			if not locked_offer_id.is_empty() and not chosen_offer_ids.has(locked_offer_id):
				chosen_offer_ids.append(locked_offer_id)
			continue
		var slot_seed := _build_shop_seed(shop_seed, inventory_id, slot_id, refresh_count)
		var offer := _pick_shop_offer_for_slot(slot, slot_seed, shop_context, run_modifier_state, chosen_offer_ids)
		if offer.is_empty():
			continue
		_apply_shop_slot_metadata(offer, slot)
		offer["shop_locked"] = false
		offers.append(offer)
		var offer_id := _resolve_offer_id(offer)
		if not offer_id.is_empty() and not chosen_offer_ids.has(offer_id):
			chosen_offer_ids.append(offer_id)
	return offers


func build_shrine_offers(
	pool_id: String,
	shrine_seed: int,
	shrine_context: Dictionary,
	run_modifier_state,
	excluded_offer_ids: Array[String] = []
) -> Array[Dictionary]:
	_ensure_loaded()
	var pool := get_shrine_pool(pool_id)
	if pool.is_empty():
		return []
	var directions_variant: Variant = pool.get("directions", [])
	if not (directions_variant is Array):
		return []
	var offers: Array[Dictionary] = []
	var chosen_offer_ids: Array[String] = _normalize_identifier_array(excluded_offer_ids)
	var directions: Array = directions_variant
	for direction_index in range(directions.size()):
		var direction_variant: Variant = directions[direction_index]
		if not (direction_variant is Dictionary):
			continue
		var direction: Dictionary = direction_variant
		var direction_id := String(direction.get("id", "")).strip_edges().to_lower()
		if direction_id.is_empty():
			continue
		var entries_variant: Variant = direction.get("entries", [])
		if not (entries_variant is Array):
			continue
		var offer := _pick_offer_from_entries(
			"modifier",
			entries_variant as Array,
			_build_shrine_seed(shrine_seed, pool_id, direction_id, direction_index),
			run_modifier_state,
			chosen_offer_ids
		)
		if offer.is_empty():
			continue
		offer["offer_id"] = "%s_%s" % [pool_id, direction_id]
		offer["shrine_pool_id"] = pool_id.strip_edges().to_lower()
		offer["shrine_direction_id"] = direction_id
		offer["shrine_direction_label"] = _localized_shrine_direction_field(
			direction_id,
			"label",
			String(direction.get("label", direction_id.capitalize())).strip_edges(),
			direction
		)
		offer["shrine_direction_label_zh"] = String(direction.get("label_zh", "")).strip_edges()
		offer["cost_type"] = String(
			direction.get("cost_type", shrine_context.get("default_cost_type", "hp_or_noise"))
		).strip_edges().to_lower()
		offer["cost_value"] = maxi(0, int(direction.get("cost_value", shrine_context.get("default_cost_value", 0))))
		offer["route_resources"] = _normalize_route_resource_spec(direction.get("route_resources", {}))
		offers.append(offer)
		var offer_id := _resolve_offer_id(offer)
		if not offer_id.is_empty() and not chosen_offer_ids.has(offer_id):
			chosen_offer_ids.append(offer_id)
	return offers


func _pick_offer_for_slot(slot: Dictionary, slot_seed: int, run_modifier_state) -> Dictionary:
	var offer_type := String(slot.get("offer_type", "modifier")).strip_edges().to_lower()
	var entries_variant: Variant = slot.get("entries", [])
	if not (entries_variant is Array):
		return {}
	return _pick_offer_from_entries(offer_type, entries_variant as Array, slot_seed, run_modifier_state)


func _pick_offer_from_grouped_table(
	reward_groups: Dictionary,
	category_weights: Dictionary,
	slot_seed: int,
	run_modifier_state,
	excluded_offer_ids: Array[String]
) -> Dictionary:
	var available_categories: Array[String] = []
	for category_variant in reward_groups.keys():
		var category_id := String(category_variant).strip_edges().to_lower()
		var group_variant: Variant = reward_groups.get(category_variant, {})
		if category_id.is_empty() or not (group_variant is Dictionary):
			continue
		available_categories.append(category_id)
	if available_categories.is_empty():
		return {}
	var rng := RandomNumberGenerator.new()
	rng.seed = maxi(1, abs(slot_seed))
	while not available_categories.is_empty():
		var chosen_category := _pick_weighted_category(available_categories, category_weights, rng)
		if chosen_category.is_empty():
			chosen_category = available_categories[0]
		var group_variant: Variant = reward_groups.get(chosen_category, {})
		if group_variant is Dictionary:
			var group: Dictionary = group_variant
			var offer_type := String(group.get("offer_type", "modifier")).strip_edges().to_lower()
			var entries_variant: Variant = group.get("entries", [])
			if entries_variant is Array:
				var offer := _pick_offer_from_entries(
					offer_type,
					entries_variant as Array,
					int(rng.randi()),
					run_modifier_state,
					excluded_offer_ids
				)
				if not offer.is_empty():
					return offer
		available_categories.erase(chosen_category)
	return {}


func _pick_weighted_category(categories: Array[String], category_weights: Dictionary, rng: RandomNumberGenerator) -> String:
	var total_weight := 0.0
	for category_id in categories:
		total_weight += maxf(0.0, float(category_weights.get(category_id, 0.0)))
	if total_weight <= 0.0:
		return categories[0] if not categories.is_empty() else ""
	var roll := rng.randf_range(0.0, total_weight)
	var cursor := 0.0
	for category_id in categories:
		cursor += maxf(0.0, float(category_weights.get(category_id, 0.0)))
		if roll <= cursor + 0.0001:
			return category_id
	return categories[categories.size() - 1]


func _pick_offer_from_entries(
	offer_type: String,
	entries: Array,
	slot_seed: int,
	run_modifier_state,
	excluded_offer_ids: Array[String] = []
) -> Dictionary:
	if entries.is_empty():
		return {}
	var build_tags := _extract_run_build_tags(run_modifier_state)
	var primary_direction := _extract_primary_build_direction(run_modifier_state)
	var weighted_offers: Array[Dictionary] = []
	var total_weight := 0.0
	for entry_variant in entries:
		var entry_id := ""
		var entry_weight := 1.0
		if entry_variant is Dictionary:
			var entry_dict: Dictionary = entry_variant
			entry_id = String(entry_dict.get("id", "")).strip_edges().to_lower()
			entry_weight = maxf(0.0, float(entry_dict.get("weight", 1.0)))
		else:
			entry_id = String(entry_variant).strip_edges().to_lower()
		if entry_id.is_empty() or excluded_offer_ids.has(entry_id) or entry_weight <= 0.0:
			continue
		var offer: Dictionary = {}
		match offer_type:
			"bundle":
				offer = _build_bundle_offer(entry_id)
			"modifier":
				if run_modifier_state != null:
					if run_modifier_state.has_method("can_offer_modifier"):
						if not bool(run_modifier_state.call("can_offer_modifier", entry_id)):
							continue
					elif run_modifier_state.has_method("has_modifier"):
						if bool(run_modifier_state.call("has_modifier", entry_id)):
							continue
					if run_modifier_state.has_method("build_modifier_offer"):
						var modifier_variant: Variant = run_modifier_state.call("build_modifier_offer", entry_id)
						if modifier_variant is Dictionary:
							offer = (modifier_variant as Dictionary).duplicate(true)
			_:
				continue
		if offer.is_empty():
			continue
		entry_weight *= _get_offer_build_weight(offer, build_tags, primary_direction)
		if entry_weight <= 0.0:
			continue
		weighted_offers.append({
			"offer": offer.duplicate(true),
			"weight": entry_weight
		})
		total_weight += entry_weight
	if weighted_offers.is_empty() or total_weight <= 0.0:
		return {}
	var rng := RandomNumberGenerator.new()
	rng.seed = max(1, abs(slot_seed))
	var roll := rng.randf_range(0.0, total_weight)
	var cursor := 0.0
	var chosen_offer: Dictionary = {}
	for row_variant in weighted_offers:
		if not (row_variant is Dictionary):
			continue
		var row: Dictionary = row_variant
		var weight := maxf(0.0, float(row.get("weight", 0.0)))
		if weight <= 0.0:
			continue
		cursor += weight
		var offer_variant: Variant = row.get("offer", {})
		chosen_offer = offer_variant.duplicate(true) if offer_variant is Dictionary else {}
		if roll <= cursor + 0.0001:
			break
	return chosen_offer


func _extract_run_build_tags(run_modifier_state) -> Array[String]:
	if run_modifier_state == null or not run_modifier_state.has_method("get_build_tags"):
		return []
	var tags_variant: Variant = run_modifier_state.call("get_build_tags")
	return _normalize_tag_array(tags_variant)


func _extract_primary_build_direction(run_modifier_state) -> String:
	if run_modifier_state == null or not run_modifier_state.has_method("get_primary_build_direction"):
		return ""
	return String(run_modifier_state.call("get_primary_build_direction")).strip_edges().to_lower()


func _get_offer_build_weight(offer: Dictionary, build_tags: Array[String], primary_direction: String) -> float:
	var weight := 1.0
	var offer_tags := _normalize_tag_array(offer.get("tags", []))
	var offer_direction := String(offer.get("build_direction", "")).strip_edges().to_lower()
	if not primary_direction.is_empty() and offer_direction == primary_direction:
		weight *= 1.35
	for build_tag in build_tags:
		if offer_tags.has(build_tag):
			weight *= 1.45
	return weight


func _pick_shop_offer_for_slot(
	slot: Dictionary,
	slot_seed: int,
	shop_context: Dictionary,
	run_modifier_state,
	excluded_offer_ids: Array[String] = []
) -> Dictionary:
	var offer_type := String(slot.get("offer_type", "modifier")).strip_edges().to_lower()
	var entries_variant: Variant = slot.get("entries", [])
	if not (entries_variant is Array):
		return {}
	var weighted_entries: Array[Dictionary] = []
	var total_weight := 0.0
	for entry_variant in entries_variant:
		if not (entry_variant is Dictionary):
			continue
		var entry: Dictionary = entry_variant
		var entry_id := String(entry.get("id", "")).strip_edges().to_lower()
		if entry_id.is_empty() or excluded_offer_ids.has(entry_id):
			continue
		if offer_type == "modifier" and run_modifier_state != null:
			if run_modifier_state.has_method("can_offer_modifier"):
				if not bool(run_modifier_state.call("can_offer_modifier", entry_id)):
					continue
			elif run_modifier_state.has_method("has_modifier"):
				if bool(run_modifier_state.call("has_modifier", entry_id)):
					continue
		var entry_weight := _get_shop_entry_weight(entry, shop_context, run_modifier_state)
		if entry_weight <= 0.0:
			continue
		weighted_entries.append({
			"entry": entry,
			"weight": entry_weight
		})
		total_weight += entry_weight
	if weighted_entries.is_empty() or total_weight <= 0.0:
		return {}
	var rng := RandomNumberGenerator.new()
	rng.seed = maxi(1, abs(slot_seed))
	var roll := rng.randf_range(0.0, total_weight)
	var cursor := 0.0
	var chosen_entry: Dictionary = {}
	for row in weighted_entries:
		var entry: Dictionary = row.get("entry", {})
		var weight := float(row.get("weight", 0.0))
		cursor += weight
		chosen_entry = entry
		if roll <= cursor + 0.0001:
			break
	var offer := _build_shop_offer_from_entry(offer_type, chosen_entry, run_modifier_state)
	if offer.is_empty():
		return {}
	return offer


func _build_bundle_offer(bundle_id: String) -> Dictionary:
	var bundle_variant: Variant = _bundles_by_id.get(bundle_id, {})
	if not (bundle_variant is Dictionary):
		return {}
	var bundle: Dictionary = bundle_variant
	var reward_kind := String(bundle.get("reward_kind", "currency")).strip_edges().to_lower()
	return {
		"id": String(bundle.get("id", bundle_id)).strip_edges(),
		"offer_type": "bundle",
		"reward_kind": reward_kind,
		"reward_kind_label": _reward_kind_label(reward_kind),
		"label": _localized_bundle_field(bundle_id, "label", String(bundle.get("label", bundle_id.capitalize())).strip_edges(), bundle),
		"summary": _localized_bundle_field(bundle_id, "summary", String(bundle.get("summary", "")).strip_edges(), bundle),
		"description": _localized_bundle_field(bundle_id, "description", String(bundle.get("description", "")).strip_edges(), bundle),
		"route_resources": _normalize_route_resource_spec(bundle.get("route_resources", {})),
		"bundle_data": bundle.duplicate(true)
	}


func _build_shop_offer_from_entry(offer_type: String, entry: Dictionary, run_modifier_state) -> Dictionary:
	var entry_id := String(entry.get("id", "")).strip_edges().to_lower()
	if entry_id.is_empty():
		return {}
	var offer: Dictionary = {}
	match offer_type:
		"bundle":
			offer = _build_bundle_offer(entry_id)
		"modifier":
			if run_modifier_state != null and run_modifier_state.has_method("build_modifier_offer"):
				var modifier_variant: Variant = run_modifier_state.call("build_modifier_offer", entry_id)
				if modifier_variant is Dictionary:
					offer = (modifier_variant as Dictionary).duplicate(true)
		_:
			return {}
	if offer.is_empty():
		return {}
	offer["shop_entry_id"] = entry_id
	offer["tags"] = _normalize_tag_array(entry.get("tags", []))
	offer["shop_tags"] = (offer.get("tags", []) as Array).duplicate()
	var shop_rarity := String(entry.get("rarity", offer.get("offer_rarity", offer.get("relic_rarity", "standard")))).strip_edges().to_lower()
	if shop_rarity.is_empty():
		shop_rarity = "standard"
	offer["shop_rarity"] = shop_rarity
	return offer


func _apply_shop_slot_metadata(offer: Dictionary, slot: Dictionary) -> void:
	offer["shop_slot_id"] = String(slot.get("id", "")).strip_edges().to_lower()
	offer["shop_slot_label"] = String(slot.get("label", offer.get("shop_slot_id", ""))).strip_edges()
	offer["shop_slot_label_zh"] = String(slot.get("label_zh", "")).strip_edges()
	offer["shop_price_offset"] = int(slot.get("price_offset", 0))
	offer["shop_lockable"] = bool(slot.get("lockable", true))
	offer["shop_slot_rare"] = bool(slot.get("rare_slot", false))
	if String(offer.get("shop_rarity", "")).strip_edges().is_empty():
		offer["shop_rarity"] = String(slot.get("rarity", "standard")).strip_edges().to_lower()


func _get_shop_entry_weight(entry: Dictionary, shop_context: Dictionary, run_modifier_state) -> float:
	var total_weight := maxf(0.0, float(entry.get("weight", 1.0)))
	if total_weight <= 0.0:
		return 0.0
	var theme_weights_variant: Variant = entry.get("theme_weights", {})
	var theme_id := String(shop_context.get("theme_id", "")).strip_edges().to_lower()
	if theme_weights_variant is Dictionary and not theme_id.is_empty():
		total_weight *= maxf(0.0, float((theme_weights_variant as Dictionary).get(theme_id, 1.0)))
	var room_tags := _normalize_tag_array(shop_context.get("room_tags", []))
	var entry_tags := _normalize_tag_array(entry.get("tags", []))
	for tag in entry_tags:
		if room_tags.has(tag):
			total_weight *= 1.2
	var feedback_tags := _normalize_tag_array(shop_context.get("feedback_tags", []))
	for feedback_tag in feedback_tags:
		if entry_tags.has(feedback_tag):
			total_weight *= 1.35
	var build_tags := _extract_shop_build_tags(shop_context, run_modifier_state)
	var build_tag_weights_variant: Variant = entry.get("build_tag_weights", {})
	var build_tag_weights: Dictionary = build_tag_weights_variant if build_tag_weights_variant is Dictionary else {}
	for build_tag in build_tags:
		if build_tag_weights.has(build_tag):
			total_weight *= maxf(0.0, float(build_tag_weights.get(build_tag, 1.0)))
		elif entry_tags.has(build_tag):
			total_weight *= 1.35
	return total_weight


func _extract_shop_build_tags(shop_context: Dictionary, run_modifier_state) -> Array[String]:
	var build_tags := _normalize_tag_array(shop_context.get("build_tags", []))
	if not build_tags.is_empty():
		return build_tags
	if run_modifier_state != null and run_modifier_state.has_method("get_build_tags"):
		var tags_variant: Variant = run_modifier_state.call("get_build_tags")
		return _normalize_tag_array(tags_variant)
	return []


func _build_shop_seed(shop_seed: int, inventory_id: String, slot_id: String, refresh_count: int) -> int:
	var seed_value: int = max(1, abs(shop_seed))
	var token: String = "%s|%s|%d" % [inventory_id.strip_edges().to_lower(), slot_id.strip_edges().to_lower(), refresh_count]
	for character in token.to_utf8_buffer():
		seed_value = int((int(seed_value) * 33 + int(character) + 29) & 0x7fffffff)
	return maxi(1, seed_value)


func _build_shrine_seed(shrine_seed: int, pool_id: String, direction_id: String, direction_index: int) -> int:
	var seed_value: int = max(1, abs(shrine_seed) + maxi(0, direction_index) * 137)
	var token := "%s|%s" % [pool_id.strip_edges().to_lower(), direction_id.strip_edges().to_lower()]
	for character in token.to_utf8_buffer():
		seed_value = int((int(seed_value) * 33 + int(character) + 23) & 0x7fffffff)
	return maxi(1, seed_value)


func _resolve_offer_id(offer: Dictionary) -> String:
	return String(offer.get("shop_entry_id", offer.get("modifier_id", offer.get("id", "")))).strip_edges().to_lower()


func _build_room_seed(
	run_seed: int,
	room_state,
	encounter_payload: Dictionary,
	rooms_cleared_total: int,
	slot_index: int
) -> int:
	var seed_value: int = abs(run_seed) + maxi(0, rooms_cleared_total) * 131 + maxi(0, slot_index) * 977
	var token := "%s|%s|%s|%s" % [
		String(room_state.room_id),
		String(encounter_payload.get("encounter_id", "")),
		String(encounter_payload.get("encounter_category", "")),
		String(encounter_payload.get("reward_table_id", ""))
	]
	for character in token.to_utf8_buffer():
		seed_value = int((int(seed_value) * 33 + int(character) + 17) & 0x7fffffff)
	return maxi(1, seed_value)


func _ensure_loaded() -> void:
	if not _tables_by_id.is_empty() or not _bundles_by_id.is_empty() or not _shop_inventories_by_id.is_empty() or not _shrine_pools_by_id.is_empty():
		return
	_schema_warnings.clear()
	for path in REWARD_TABLE_PATHS:
		var payload := _load_json_dictionary(path)
		if payload.is_empty():
			_record_schema_warning("[night_rewards] missing or invalid reward payload: %s" % path)
			continue
		if not payload.has("schema_contract_version"):
			_record_schema_warning("[night_rewards] missing schema_contract_version: %s" % path)
		var contract_version := int(payload.get("schema_contract_version", SCHEMA_CONTRACT_VERSION))
		if contract_version != SCHEMA_CONTRACT_VERSION:
			_record_schema_warning(
				"[night_rewards] schema_contract_version %d does not match expected %d: %s"
				% [contract_version, SCHEMA_CONTRACT_VERSION, path]
			)
		var bundles_variant: Variant = payload.get("bundles", [])
		if bundles_variant is Array:
			var bundles: Array = bundles_variant
			for bundle_index in range(bundles.size()):
				var bundle_variant: Variant = bundles[bundle_index]
				if not (bundle_variant is Dictionary):
					_record_schema_warning("[night_rewards:%s:bundle:%d] bundle must be a dictionary" % [path, bundle_index])
					continue
				var bundle: Dictionary = _normalize_bundle_row(bundle_variant as Dictionary, path, bundle_index)
				var bundle_id := String(bundle.get("id", "")).strip_edges().to_lower()
				if bundle_id.is_empty():
					continue
				_bundles_by_id[bundle_id] = bundle.duplicate(true)
		else:
			_record_schema_warning("[night_rewards] bundles must be an array: %s" % path)
		var tables_variant: Variant = payload.get("tables", [])
		if tables_variant is Array:
			var tables: Array = tables_variant
			for table_index in range(tables.size()):
				var table_variant: Variant = tables[table_index]
				if not (table_variant is Dictionary):
					_record_schema_warning("[night_rewards:%s:table:%d] table must be a dictionary" % [path, table_index])
					continue
				var table: Dictionary = _normalize_table_row(table_variant as Dictionary, path, table_index)
				var table_id := String(table.get("id", "")).strip_edges()
				if table_id.is_empty():
					continue
				_tables_by_id[table_id] = table.duplicate(true)
		else:
			_record_schema_warning("[night_rewards] tables must be an array: %s" % path)
		var shop_inventories_variant: Variant = payload.get("shop_inventories", [])
		if shop_inventories_variant is Array:
			var inventories: Array = shop_inventories_variant
			for inventory_index in range(inventories.size()):
				var inventory_variant: Variant = inventories[inventory_index]
				if not (inventory_variant is Dictionary):
					_record_schema_warning("[night_rewards:%s:shop:%d] shop inventory must be a dictionary" % [path, inventory_index])
					continue
				var inventory := _normalize_shop_inventory_row(inventory_variant as Dictionary, path, inventory_index)
				var inventory_id := String(inventory.get("id", "")).strip_edges().to_lower()
				if inventory_id.is_empty():
					continue
				_shop_inventories_by_id[inventory_id] = inventory.duplicate(true)
		elif payload.has("shop_inventories"):
			_record_schema_warning("[night_rewards] shop_inventories must be an array: %s" % path)
		var shrine_pools_variant: Variant = payload.get("shrine_pools", [])
		if shrine_pools_variant is Array:
			var shrine_pools: Array = shrine_pools_variant
			for pool_index in range(shrine_pools.size()):
				var pool_variant: Variant = shrine_pools[pool_index]
				if not (pool_variant is Dictionary):
					_record_schema_warning("[night_rewards:%s:shrine:%d] shrine pool must be a dictionary" % [path, pool_index])
					continue
				var pool := _normalize_shrine_pool_row(pool_variant as Dictionary, path, pool_index)
				var pool_id := String(pool.get("id", "")).strip_edges().to_lower()
				if pool_id.is_empty():
					continue
				_shrine_pools_by_id[pool_id] = pool.duplicate(true)
		elif payload.has("shrine_pools"):
			_record_schema_warning("[night_rewards] shrine_pools must be an array: %s" % path)


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


func _localized_bundle_field(bundle_id: String, field: String, fallback: String, source: Dictionary = {}) -> String:
	if Localization != null and Localization.has_method("data_field"):
		return String(Localization.call("data_field", bundle_id, field, fallback, source))
	return fallback


func _localized_shrine_direction_field(direction_id: String, field: String, fallback: String, source: Dictionary = {}) -> String:
	if Localization != null and Localization.has_method("data_field"):
		return String(Localization.call("data_field", "night_shrine_direction_%s" % direction_id, field, fallback, source))
	return fallback


func _reward_kind_label(reward_kind: String) -> String:
	var normalized := reward_kind.strip_edges().to_lower()
	if Localization != null and Localization.has_method("t"):
		return String(Localization.call("t", "night.reward.kind.%s" % normalized))
	return normalized.capitalize()


func _normalize_bundle_row(row: Dictionary, path: String, row_index: int) -> Dictionary:
	var bundle_id := String(row.get("id", "")).strip_edges().to_lower()
	if bundle_id.is_empty():
		_record_schema_warning("[night_rewards:%s:bundle:%d] bundle id must be non-empty" % [path, row_index])
		return {}
	return {
		"id": bundle_id,
		"schema_contract_version": SCHEMA_CONTRACT_VERSION,
		"reward_kind": String(row.get("reward_kind", "currency")).strip_edges().to_lower(),
		"label": String(row.get("label", bundle_id.capitalize())).strip_edges(),
		"label_zh": String(row.get("label_zh", "")).strip_edges(),
		"summary": String(row.get("summary", "")).strip_edges(),
		"summary_zh": String(row.get("summary_zh", "")).strip_edges(),
		"description": String(row.get("description", "")).strip_edges(),
		"description_zh": String(row.get("description_zh", "")).strip_edges(),
		"instant": _normalize_dictionary(row.get("instant", {})),
		"reward_multipliers": _normalize_dictionary(row.get("reward_multipliers", {})),
		"route_resources": _normalize_route_resource_spec(row.get("route_resources", {}))
	}


func _normalize_table_row(row: Dictionary, path: String, row_index: int) -> Dictionary:
	var table_id := String(row.get("id", "")).strip_edges()
	if table_id.is_empty():
		_record_schema_warning("[night_rewards:%s:table:%d] table id must be non-empty" % [path, row_index])
		return {}
	var normalized := {
		"id": table_id,
		"schema_contract_version": SCHEMA_CONTRACT_VERSION,
		"draws": maxi(1, int(row.get("draws", row.get("rolls", 3)))),
		"slots": [],
		"category_weights": {},
		"reward_groups": {}
	}
	var reward_groups_variant: Variant = row.get("reward_groups", {})
	if reward_groups_variant is Dictionary and not (reward_groups_variant as Dictionary).is_empty():
		normalized["category_weights"] = _normalize_float_dictionary(row.get("category_weights", {}))
		normalized["reward_groups"] = _normalize_reward_groups(reward_groups_variant, path, table_id)
	else:
		normalized["slots"] = _normalize_slots(row.get("slots", []), path, table_id)
	return normalized


func _normalize_shrine_pool_row(row: Dictionary, path: String, row_index: int) -> Dictionary:
	var pool_id := String(row.get("id", "")).strip_edges().to_lower()
	if pool_id.is_empty():
		_record_schema_warning("[night_rewards:%s:shrine:%d] pool id must be non-empty" % [path, row_index])
		return {}
	return {
		"id": pool_id,
		"schema_contract_version": SCHEMA_CONTRACT_VERSION,
		"fallback_direction_id": String(row.get("fallback_direction_id", "")).strip_edges().to_lower(),
		"directions": _normalize_shrine_directions(row.get("directions", []), path, pool_id)
	}


func _normalize_shrine_directions(value: Variant, path: String, pool_id: String) -> Array:
	var rows: Array = []
	if not (value is Array):
		_record_schema_warning("[night_rewards:%s:shrine:%s] directions must be an array" % [path, pool_id])
		return rows
	var source_rows: Array = value
	for row_index in range(source_rows.size()):
		var row_variant: Variant = source_rows[row_index]
		if not (row_variant is Dictionary):
			_record_schema_warning("[night_rewards:%s:shrine:%s:direction:%d] direction must be a dictionary" % [path, pool_id, row_index])
			continue
		var row: Dictionary = row_variant
		var direction_id := String(row.get("id", "")).strip_edges().to_lower()
		if direction_id.is_empty():
			_record_schema_warning("[night_rewards:%s:shrine:%s:direction:%d] direction id must be non-empty" % [path, pool_id, row_index])
			continue
		var cost_type := String(row.get("cost_type", "hp_or_noise")).strip_edges().to_lower()
		if cost_type.is_empty() or not SUPPORTED_INTERACTION_COST_TYPES.has(cost_type):
			_record_schema_warning(
				"[night_rewards:%s:shrine:%s:direction:%d] unsupported cost_type '%s'"
				% [path, pool_id, row_index, cost_type]
			)
			cost_type = "hp_or_noise"
		rows.append({
			"id": direction_id,
			"label": String(row.get("label", direction_id.capitalize())).strip_edges(),
			"label_zh": String(row.get("label_zh", "")).strip_edges(),
			"cost_type": cost_type,
			"cost_value": maxi(0, int(row.get("cost_value", 0))),
			"entries": _normalize_string_array(row.get("entries", [])),
			"route_resources": _normalize_route_resource_spec(row.get("route_resources", {}))
		})
	return rows


func _normalize_shop_inventory_row(row: Dictionary, path: String, row_index: int) -> Dictionary:
	var inventory_id := String(row.get("id", "")).strip_edges().to_lower()
	if inventory_id.is_empty():
		_record_schema_warning("[night_rewards:%s:shop:%d] inventory id must be non-empty" % [path, row_index])
		return {}
	var refresh_cost_xp := maxi(0, int(row.get("refresh_cost_xp", 18)))
	var refresh_cost_step_xp := maxi(0, int(row.get("refresh_cost_step_xp", 6)))
	var refresh_cost_cap_xp := maxi(refresh_cost_xp, int(row.get("refresh_cost_cap_xp", refresh_cost_xp + refresh_cost_step_xp * 3)))
	return {
		"id": inventory_id,
		"schema_contract_version": SCHEMA_CONTRACT_VERSION,
		"refresh_cost_xp": refresh_cost_xp,
		"refresh_cost_step_xp": refresh_cost_step_xp,
		"refresh_cost_cap_xp": refresh_cost_cap_xp,
		"slots": _normalize_shop_slots(row.get("slots", []), path, inventory_id)
	}


func _normalize_shop_slots(value: Variant, path: String, inventory_id: String) -> Array:
	var rows: Array = []
	if not (value is Array):
		_record_schema_warning("[night_rewards:%s:shop:%s] slots must be an array" % [path, inventory_id])
		return rows
	var source_rows: Array = value
	for row_index in range(source_rows.size()):
		var row_variant: Variant = source_rows[row_index]
		if not (row_variant is Dictionary):
			_record_schema_warning("[night_rewards:%s:shop:%s:slot:%d] slot must be a dictionary" % [path, inventory_id, row_index])
			continue
		var row: Dictionary = row_variant
		var offer_type := String(row.get("offer_type", "modifier")).strip_edges().to_lower()
		if offer_type.is_empty() or not SUPPORTED_OFFER_TYPES.has(offer_type):
			_record_schema_warning(
				"[night_rewards:%s:shop:%s:slot:%d] unsupported offer_type '%s'"
				% [path, inventory_id, row_index, offer_type]
			)
			offer_type = "modifier"
		rows.append({
			"id": String(row.get("id", "shop_slot_%d" % row_index)).strip_edges().to_lower(),
			"label": String(row.get("label", "")).strip_edges(),
			"label_zh": String(row.get("label_zh", "")).strip_edges(),
			"offer_type": offer_type,
			"price_offset": int(row.get("price_offset", 0)),
			"lockable": bool(row.get("lockable", true)),
			"rare_slot": bool(row.get("rare_slot", false)),
			"rarity": String(row.get("rarity", "standard")).strip_edges().to_lower(),
			"entries": _normalize_shop_entries(row.get("entries", []), path, inventory_id, row_index)
		})
	return rows


func _normalize_shop_entries(value: Variant, path: String, inventory_id: String, row_index: int) -> Array:
	var rows: Array = []
	if not (value is Array):
		_record_schema_warning("[night_rewards:%s:shop:%s:slot:%d] entries must be an array" % [path, inventory_id, row_index])
		return rows
	var source_rows: Array = value
	for entry_index in range(source_rows.size()):
		var entry_variant: Variant = source_rows[entry_index]
		var entry_id := ""
		var entry: Dictionary = {}
		if entry_variant is Dictionary:
			entry = entry_variant as Dictionary
			entry_id = String(entry.get("id", "")).strip_edges().to_lower()
		else:
			entry_id = String(entry_variant).strip_edges().to_lower()
		if entry_id.is_empty():
			_record_schema_warning("[night_rewards:%s:shop:%s:slot:%d:entry:%d] entry id must be non-empty" % [path, inventory_id, row_index, entry_index])
			continue
		rows.append({
			"id": entry_id,
			"weight": maxf(0.0, float(entry.get("weight", 1.0))),
			"tags": _normalize_tag_array(entry.get("tags", [])),
			"theme_weights": _normalize_float_dictionary(entry.get("theme_weights", {})),
			"build_tag_weights": _normalize_float_dictionary(entry.get("build_tag_weights", {})),
			"rarity": String(entry.get("rarity", "standard")).strip_edges().to_lower()
		})
	return rows


func _normalize_reward_groups(value: Variant, path: String, table_id: String) -> Dictionary:
	if not (value is Dictionary):
		_record_schema_warning("[night_rewards:%s:%s] reward_groups must be a dictionary" % [path, table_id])
		return {}
	var normalized: Dictionary = {}
	var source: Dictionary = value
	for key_variant in source.keys():
		var category_id := String(key_variant).strip_edges().to_lower()
		var row_variant: Variant = source.get(key_variant, {})
		if category_id.is_empty():
			continue
		if not (row_variant is Dictionary):
			_record_schema_warning("[night_rewards:%s:%s:%s] reward group must be a dictionary" % [path, table_id, category_id])
			continue
		var row: Dictionary = row_variant
		var offer_type := String(row.get("offer_type", "modifier")).strip_edges().to_lower()
		if offer_type.is_empty() or not SUPPORTED_OFFER_TYPES.has(offer_type):
			_record_schema_warning(
				"[night_rewards:%s:%s:%s] unsupported offer_type '%s'"
				% [path, table_id, category_id, offer_type]
			)
			offer_type = "modifier"
		normalized[category_id] = {
			"offer_type": offer_type,
			"entries": _normalize_string_array(row.get("entries", []))
		}
	return normalized


func _normalize_slots(value: Variant, path: String, table_id: String) -> Array:
	var rows: Array = []
	if not (value is Array):
		_record_schema_warning("[night_rewards:%s:%s] slots must be an array" % [path, table_id])
		return rows
	var source_rows: Array = value
	for row_index in range(source_rows.size()):
		var row_variant: Variant = source_rows[row_index]
		if not (row_variant is Dictionary):
			_record_schema_warning("[night_rewards:%s:%s:slot:%d] slot must be a dictionary" % [path, table_id, row_index])
			continue
		var row: Dictionary = row_variant
		var offer_type := String(row.get("offer_type", "modifier")).strip_edges().to_lower()
		if offer_type.is_empty() or not SUPPORTED_OFFER_TYPES.has(offer_type):
			_record_schema_warning(
				"[night_rewards:%s:%s:slot:%d] unsupported offer_type '%s'"
				% [path, table_id, row_index, offer_type]
			)
			offer_type = "modifier"
		rows.append({
			"id": String(row.get("id", "slot_%d" % row_index)).strip_edges(),
			"offer_type": offer_type,
			"entries": _normalize_string_array(row.get("entries", []))
		})
	return rows


func _normalize_dictionary(value: Variant) -> Dictionary:
	return value.duplicate(true) if value is Dictionary else {}


func _normalize_float_dictionary(value: Variant) -> Dictionary:
	if not (value is Dictionary):
		return {}
	var normalized: Dictionary = {}
	var source: Dictionary = value
	for key_variant in source.keys():
		var key := String(key_variant).strip_edges().to_lower()
		if key.is_empty():
			continue
		normalized[key] = maxf(0.0, float(source.get(key_variant, 0.0)))
	return normalized


func _normalize_route_resource_spec(value: Variant) -> Dictionary:
	if not (value is Dictionary):
		return {}
	var normalized: Dictionary = {}
	var source: Dictionary = value
	for section_id in ["grant", "cost", "require"]:
		var section_variant: Variant = source.get(section_id, {})
		if not (section_variant is Dictionary):
			continue
		var section: Dictionary = {}
		for key_variant in (section_variant as Dictionary).keys():
			var key := String(key_variant).strip_edges().to_lower()
			var amount := maxi(0, int((section_variant as Dictionary).get(key_variant, 0)))
			if not ["key", "curse", "contract"].has(key) or amount <= 0:
				continue
			section[key] = amount
		if not section.is_empty():
			normalized[section_id] = section
	return normalized


func _normalize_string_array(value: Variant) -> Array[String]:
	var rows: Array[String] = []
	if not (value is Array):
		return rows
	var source_rows: Array = value
	for row_variant in source_rows:
		var normalized := String(row_variant).strip_edges()
		if normalized.is_empty() or rows.has(normalized):
			continue
		rows.append(normalized)
	return rows


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


func _record_schema_warning(message: String) -> void:
	if message.is_empty() or _schema_warnings.has(message):
		return
	_schema_warnings.append(message)
