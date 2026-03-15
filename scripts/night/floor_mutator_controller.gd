extends RefCounted
class_name FloorMutatorController

var _current_mutator: Dictionary = {}
var _applied_floor_ids: Array[String] = []
var _applied_floor_mutators: Dictionary = {}


func reset() -> void:
	_current_mutator.clear()
	_applied_floor_ids.clear()
	_applied_floor_mutators.clear()


func enter_floor(floor_state, run_modifier_state, context: Dictionary = {}) -> Dictionary:
	_current_mutator.clear()
	if floor_state == null:
		return get_current_mutator()
	var floor_id := String(floor_state.floor_id).strip_edges()
	var mutator_id := String(floor_state.floor_mutator_id).strip_edges().to_lower()
	if floor_id.is_empty() or mutator_id.is_empty():
		return get_current_mutator()
	if _applied_floor_ids.has(floor_id):
		var existing := _resolve_existing_floor_mutator(floor_state, floor_id, mutator_id)
		_current_mutator = existing.duplicate(true)
		return get_current_mutator()
	if run_modifier_state == null:
		return get_current_mutator()
	var applied: Dictionary = run_modifier_state.apply_system_modifier(mutator_id, context, "floor_mutator")
	if applied.is_empty():
		return get_current_mutator()
	var snapshot := _build_mutator_snapshot(applied, floor_state, floor_id, mutator_id)
	_current_mutator = snapshot.duplicate(true)
	_applied_floor_ids.append(floor_id)
	_applied_floor_mutators[floor_id] = snapshot.duplicate(true)
	floor_state.floor_mutator = snapshot.duplicate(true)
	return get_current_mutator()


func get_current_mutator() -> Dictionary:
	return _current_mutator.duplicate(true)


func get_applied_floor_ids() -> Array[String]:
	var rows: Array[String] = []
	for floor_id in _applied_floor_ids:
		rows.append(floor_id)
	return rows


func get_applied_mutators() -> Array:
	var rows: Array = []
	for floor_id in _applied_floor_ids:
		var row_variant: Variant = _applied_floor_mutators.get(floor_id, {})
		if row_variant is Dictionary:
			rows.append((row_variant as Dictionary).duplicate(true))
	return rows


func get_snapshot() -> Dictionary:
	return {
		"current_mutator": get_current_mutator(),
		"applied_floor_ids": get_applied_floor_ids(),
		"applied_mutators": get_applied_mutators()
	}


func build_summary_payload() -> Dictionary:
	return {
		"dungeon_floor_mutator": get_current_mutator(),
		"dungeon_floor_mutator_history": get_applied_mutators()
	}


func _resolve_existing_floor_mutator(floor_state, floor_id: String, mutator_id: String) -> Dictionary:
	var existing_variant: Variant = _applied_floor_mutators.get(floor_id, floor_state.floor_mutator if floor_state != null else {})
	var existing: Dictionary = existing_variant.duplicate(true) if existing_variant is Dictionary else {}
	if existing.is_empty():
		existing = {
			"id": mutator_id,
			"mutator_id": mutator_id,
			"floor_id": floor_id,
			"floor_label": String(floor_state.label if floor_state != null else "")
		}
	if floor_state != null:
		floor_state.floor_mutator = existing.duplicate(true)
	_applied_floor_mutators[floor_id] = existing.duplicate(true)
	return existing


func _build_mutator_snapshot(applied: Dictionary, floor_state, floor_id: String, mutator_id: String) -> Dictionary:
	var snapshot := applied.duplicate(true)
	snapshot["mutator_id"] = mutator_id
	snapshot["floor_id"] = floor_id
	snapshot["floor_label"] = String(floor_state.label if floor_state != null else "")
	return snapshot
