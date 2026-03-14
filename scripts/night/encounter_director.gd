extends RefCounted
class_name EncounterDirector


func build_room_payload(floor_state, room_state, room_node: Node2D) -> Dictionary:
	var payload := {
		"room_id": room_state.room_id,
		"room_label": room_state.label,
		"room_kind": room_state.room_kind,
		"encounter_id": room_state.encounter_id,
		"is_goal": room_state.is_goal,
		"enemies": []
	}
	if room_state.room_kind != room_state.ROOM_KIND_COMBAT:
		return payload

	var encounter_variant: Variant = floor_state.encounters.get(room_state.encounter_id, {})
	var encounter: Dictionary = encounter_variant if encounter_variant is Dictionary else {}
	var enemies_variant: Variant = encounter.get("enemies", [])
	if not (enemies_variant is Array):
		return payload

	var enemy_payloads: Array[Dictionary] = []
	var rows: Array = enemies_variant
	for row_variant in rows:
		if not (row_variant is Dictionary):
			continue
		var row: Dictionary = row_variant
		var enemy_id := String(row.get("enemy_id", "")).strip_edges().to_lower()
		if enemy_id.is_empty():
			continue
		var count := clampi(int(row.get("count", 1)), 1, 8)
		var allow_elite := bool(row.get("allow_elite", false))
		for spawn_index in range(count):
			enemy_payloads.append({
				"enemy_id": enemy_id,
				"allow_elite": allow_elite,
				"position": _resolve_spawn_position(room_node, row, spawn_index, count)
			})
	payload["enemies"] = enemy_payloads
	return payload


func _resolve_spawn_position(room_node: Node2D, row: Dictionary, spawn_index: int, spawn_total: int) -> Vector2:
	var spawn_name := String(row.get("spawn_point", "")).strip_edges()
	var base_position := _find_marker_global_position(room_node, spawn_name, "SpawnPoints")
	if base_position == Vector2.ZERO:
		base_position = _find_marker_global_position(room_node, "EncounterAnchor", "")
	if base_position == Vector2.ZERO and room_node != null:
		base_position = room_node.global_position
	var offset_radius := maxf(0.0, float(row.get("offset_radius", 42.0)))
	if spawn_total <= 1 or is_zero_approx(offset_radius):
		return base_position
	var angle_step := TAU / maxf(1.0, float(spawn_total))
	var angle := float(spawn_index) * angle_step - PI * 0.5
	return base_position + Vector2.RIGHT.rotated(angle) * offset_radius


func _find_marker_global_position(root: Node, marker_name: String, preferred_parent_name: String) -> Vector2:
	if root == null or marker_name.is_empty():
		return Vector2.ZERO
	var preferred_parent := root.get_node_or_null(preferred_parent_name) if not preferred_parent_name.is_empty() else root
	var marker := _find_named_node(preferred_parent, marker_name)
	if marker == null and preferred_parent != root:
		marker = _find_named_node(root, marker_name)
	if marker is Node2D:
		return (marker as Node2D).global_position
	return Vector2.ZERO


func _find_named_node(parent: Node, target_name: String) -> Node:
	if parent == null:
		return null
	var normalized_target := target_name.strip_edges().to_lower()
	for child in parent.get_children():
		if child == null:
			continue
		if String(child.name).strip_edges().to_lower() == normalized_target:
			return child
	return null
