extends RefCounted
class_name RoomRewardPicker

const REWARD_TABLE_PATHS := [
	"res://data/night_reward_tables.json",
	"res://data/night_reward_tables_v2.json"
]

var _tables_by_id: Dictionary = {}
var _bundles_by_id: Dictionary = {}


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
	if table.has("reward_groups"):
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
	var rng := RandomNumberGenerator.new()
	rng.seed = max(1, abs(slot_seed))
	var start_index := rng.randi_range(0, entries.size() - 1)
	for offset in range(entries.size()):
		var entry_id := String(entries[(start_index + offset) % entries.size()]).strip_edges().to_lower()
		if entry_id.is_empty() or excluded_offer_ids.has(entry_id):
			continue
		match offer_type:
			"bundle":
				var bundle := _build_bundle_offer(entry_id)
				if not bundle.is_empty():
					return bundle
			"modifier":
				if run_modifier_state != null and run_modifier_state.has_method("has_modifier"):
					if bool(run_modifier_state.call("has_modifier", entry_id)) and offset < entries.size() - 1:
						continue
				if run_modifier_state != null and run_modifier_state.has_method("build_modifier_offer"):
					var modifier_variant: Variant = run_modifier_state.call("build_modifier_offer", entry_id)
					if modifier_variant is Dictionary and not (modifier_variant as Dictionary).is_empty():
						return (modifier_variant as Dictionary).duplicate(true)
	return {}


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
		"bundle_data": bundle.duplicate(true)
	}


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
	if not _tables_by_id.is_empty() or not _bundles_by_id.is_empty():
		return
	for path in REWARD_TABLE_PATHS:
		var payload := _load_json_dictionary(path)
		var bundles_variant: Variant = payload.get("bundles", [])
		if bundles_variant is Array:
			for bundle_variant in bundles_variant:
				if not (bundle_variant is Dictionary):
					continue
				var bundle: Dictionary = bundle_variant
				var bundle_id := String(bundle.get("id", "")).strip_edges().to_lower()
				if bundle_id.is_empty():
					continue
				_bundles_by_id[bundle_id] = bundle.duplicate(true)
		var tables_variant: Variant = payload.get("tables", [])
		if tables_variant is Array:
			for table_variant in tables_variant:
				if not (table_variant is Dictionary):
					continue
				var table: Dictionary = table_variant
				var table_id := String(table.get("id", "")).strip_edges()
				if table_id.is_empty():
					continue
				_tables_by_id[table_id] = table.duplicate(true)


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


func _reward_kind_label(reward_kind: String) -> String:
	var normalized := reward_kind.strip_edges().to_lower()
	if Localization != null and Localization.has_method("t"):
		return String(Localization.call("t", "night.reward.kind.%s" % normalized))
	return normalized.capitalize()
