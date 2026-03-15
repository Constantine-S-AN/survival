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
	"reward_multipliers"
]
const TABLE_SCHEMA_FIELDS: Array[String] = [
	"id",
	"schema_contract_version",
	"draws",
	"slots",
	"category_weights",
	"reward_groups"
]

var _tables_by_id: Dictionary = {}
var _bundles_by_id: Dictionary = {}
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
		"supported_offer_types": SUPPORTED_OFFER_TYPES.keys()
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
		"reward_multipliers": _normalize_dictionary(row.get("reward_multipliers", {}))
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


func _record_schema_warning(message: String) -> void:
	if message.is_empty() or _schema_warnings.has(message):
		return
	_schema_warnings.append(message)
