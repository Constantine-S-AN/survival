extends RefCounted
class_name ExtractionController

const ROOM_CLEAR_BUNDLES := {
	"standard": {"scrap": 1},
	"elite": {"scrap": 2, "reef_salt": 1}
}

var _cleared_room_materials: Dictionary = {}
var _cleared_room_count: int = 0
var _boss_bonus_materials: Dictionary = {}
var _boss_bonus_label: String = "Boss Cache Secured"
var _boss_cleared: bool = false


func reset() -> void:
	_cleared_room_materials.clear()
	_cleared_room_count = 0
	_boss_bonus_materials.clear()
	_boss_bonus_label = "Boss Cache Secured"
	_boss_cleared = false


func record_combat_room_clear(encounter_payload: Dictionary) -> Dictionary:
	var category := String(encounter_payload.get("encounter_category", "standard")).strip_edges().to_lower()
	var bundle_variant: Variant = ROOM_CLEAR_BUNDLES.get(category, {})
	var bundle := _normalize_material_bundle(bundle_variant)
	if bundle.is_empty():
		return {}
	_cleared_room_count += 1
	_accumulate_bundle(_cleared_room_materials, bundle)
	return bundle.duplicate(true)


func record_boss_bonus(bonus_payload: Dictionary) -> void:
	if _boss_cleared:
		return
	var materials_variant: Variant = bonus_payload.get("materials", {})
	var materials := _normalize_material_bundle(materials_variant)
	_boss_cleared = true
	if not materials.is_empty():
		_accumulate_bundle(_boss_bonus_materials, materials)
	_boss_bonus_label = String(bonus_payload.get("label", _boss_bonus_label)).strip_edges()


func build_status(run_state: String, current_room, has_pending_rewards: bool) -> Dictionary:
	var status := {
		"available": false,
		"title": "Extraction",
		"subtitle": "Secure another room to call the skiff.",
		"button_text": "Extract"
	}
	if current_room == null:
		status["subtitle"] = "Route not anchored yet."
		return status
	if run_state == "completed":
		status["title"] = "Run Complete"
		status["subtitle"] = "Return route already secured."
		return status
	if run_state == "aborted":
		status["title"] = "Extraction Offline"
		status["subtitle"] = "The run could not stabilize."
		return status
	if has_pending_rewards:
		status["subtitle"] = "Claim the room reward before returning."
		return status
	if String(current_room.room_type_id).strip_edges().to_lower() == "boss":
		if String(current_room.status).strip_edges().to_lower() == "cleared":
			status["title"] = "Climax Complete"
			status["subtitle"] = "Boss floor secured. Finish the return."
		else:
			status["title"] = "Climax Locked"
			status["subtitle"] = "The boss chamber only ends in victory or failure."
		return status
	if String(current_room.status).strip_edges().to_lower() != "cleared":
		status["subtitle"] = "Secure the current room before calling the skiff."
		return status
	if _cleared_room_count <= 0:
		status["subtitle"] = "Clear at least one combat room to secure haul."
		return status
	status["available"] = true
	status["title"] = "Skiff Ready"
	status["subtitle"] = "Leave now with the haul already secured."
	status["button_text"] = "Extract Now"
	return status


func build_outcome_payload(exit_reason: String, context: Dictionary = {}) -> Dictionary:
	var normalized_exit_reason := exit_reason.strip_edges().to_lower()
	var secured_room_materials := _cleared_room_materials.duplicate(true)
	var secured_boss_materials := _boss_bonus_materials.duplicate(true)
	var carryover_materials: Dictionary = {}
	var carryover_rows: Array[Dictionary] = []

	var room_row_summary := "No combat-room salvage secured."
	var room_row_secured := false
	if normalized_exit_reason != "abandoned" and not secured_room_materials.is_empty():
		room_row_summary = "%d combat room%s secured · %s" % [
			_cleared_room_count,
			"" if _cleared_room_count == 1 else "s",
			_format_material_bundle(secured_room_materials)
		]
		room_row_secured = true
		_accumulate_bundle(carryover_materials, secured_room_materials)
	elif normalized_exit_reason == "abandoned" and _cleared_room_count > 0:
		room_row_summary = "Emergency return lost the unbanked room salvage."
	carryover_rows.append({
		"id": "cleared_rooms",
		"label": "Cleared rooms",
		"summary": room_row_summary,
		"secured": room_row_secured,
		"materials": secured_room_materials
	})

	var boss_row_summary := "Boss cache not secured."
	var boss_row_secured := false
	if normalized_exit_reason == "completed" and _boss_cleared and not secured_boss_materials.is_empty():
		boss_row_summary = _format_material_bundle(secured_boss_materials)
		boss_row_secured = true
		_accumulate_bundle(carryover_materials, secured_boss_materials)
	elif normalized_exit_reason == "extracted":
		boss_row_summary = "Skiff extraction left the floor boss cache behind."
	elif normalized_exit_reason == "abandoned" and _boss_cleared:
		boss_row_summary = "The boss fell, but the emergency return lost the final cache."
	carryover_rows.append({
		"id": "boss_bonus",
		"label": _boss_bonus_label,
		"summary": boss_row_summary,
		"secured": boss_row_secured,
		"materials": secured_boss_materials
	})

	var route_label := "Harbor return"
	match normalized_exit_reason:
		"completed":
			route_label = "Boss floor cleared"
		"extracted":
			route_label = "Early skiff extract"
		"abandoned":
			route_label = "Emergency return"
		_:
			pass

	var extraction_room_id := ""
	var extraction_room_label := ""
	if normalized_exit_reason == "extracted":
		extraction_room_id = String(context.get("room_id", "")).strip_edges()
		extraction_room_label = String(context.get("room_label", "")).strip_edges()

	return {
		"dungeon_combat_rooms_cleared": _cleared_room_count,
		"dungeon_secured_room_count": _cleared_room_count if normalized_exit_reason != "abandoned" else 0,
		"dungeon_room_clear_materials": secured_room_materials,
		"dungeon_boss_cleared": _boss_cleared,
		"dungeon_boss_bonus_label": _boss_bonus_label,
		"dungeon_boss_bonus_materials": secured_boss_materials if normalized_exit_reason == "completed" else {},
		"dungeon_extracted_early": normalized_exit_reason == "extracted",
		"dungeon_extraction_room_id": extraction_room_id,
		"dungeon_extraction_room_label": extraction_room_label,
		"dungeon_return_route_label": route_label,
		"dungeon_carryover_materials": carryover_materials,
		"dungeon_carryover_rows": carryover_rows
	}


func get_snapshot() -> Dictionary:
	return {
		"combat_rooms_cleared": _cleared_room_count,
		"room_clear_materials": _cleared_room_materials.duplicate(true),
		"boss_cleared": _boss_cleared,
		"boss_bonus_label": _boss_bonus_label,
		"boss_bonus_materials": _boss_bonus_materials.duplicate(true)
	}


func _format_material_bundle(bundle: Dictionary) -> String:
	var rows: Array[String] = []
	for material_id_variant in bundle.keys():
		var material_id := String(material_id_variant).strip_edges().to_lower()
		var amount := int(bundle.get(material_id_variant, 0))
		if material_id.is_empty() or amount <= 0:
			continue
		rows.append("%s x%d" % [_display_material_name(material_id), amount])
	rows.sort()
	return ", ".join(rows) if not rows.is_empty() else "None"


func _display_material_name(material_id: String) -> String:
	if DataRegistry != null and DataRegistry.has_method("get_material"):
		return String(DataRegistry.get_material(material_id).get("name", material_id.capitalize()))
	return material_id.capitalize()


func _accumulate_bundle(target: Dictionary, source: Dictionary) -> void:
	for material_id_variant in source.keys():
		var material_id := String(material_id_variant).strip_edges().to_lower()
		var amount := int(source.get(material_id_variant, 0))
		if material_id.is_empty() or amount <= 0:
			continue
		target[material_id] = maxi(0, int(target.get(material_id, 0))) + amount


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
