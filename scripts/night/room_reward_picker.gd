extends RefCounted
class_name RoomRewardPicker

const REWARD_TABLES_PATH := "res://data/night_reward_tables.json"

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


func _pick_offer_for_slot(slot: Dictionary, slot_seed: int, run_modifier_state) -> Dictionary:
	var offer_type := String(slot.get("offer_type", "modifier")).strip_edges().to_lower()
	var entries_variant: Variant = slot.get("entries", [])
	if not (entries_variant is Array):
		return {}
	var entries: Array = entries_variant
	if entries.is_empty():
		return {}
	var rng := RandomNumberGenerator.new()
	rng.seed = max(1, abs(slot_seed))
	var start_index := rng.randi_range(0, entries.size() - 1)
	for offset in range(entries.size()):
		var entry_id := String(entries[(start_index + offset) % entries.size()]).strip_edges().to_lower()
		if entry_id.is_empty():
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
	return {
		"id": String(bundle.get("id", bundle_id)).strip_edges(),
		"offer_type": "bundle",
		"reward_kind": String(bundle.get("reward_kind", "currency")).strip_edges().to_lower(),
		"label": String(bundle.get("label", bundle_id.capitalize())).strip_edges(),
		"summary": String(bundle.get("summary", "")).strip_edges(),
		"description": String(bundle.get("description", "")).strip_edges(),
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
	var payload := _load_json_dictionary(REWARD_TABLES_PATH)
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
