extends RefCounted
class_name ObjectiveRuntimeController

const ObjectiveNodeScene := preload("res://scenes/night/rooms/setpieces/ObjectiveNode.tscn")
const ObjectiveZoneScene := preload("res://scenes/night/rooms/setpieces/ObjectiveZone.tscn")

var _objective_state: Dictionary = {}
var _active_room_node: Node2D = null
var _objective_root_name: String = "RuntimeObjectives"


func reset(context: Dictionary = {}) -> void:
	clear_runtime(context)
	_active_room_node = null
	_objective_root_name = _resolve_objective_root_name(context)


func begin_room(room_node: Node2D, payload: Dictionary, context: Dictionary = {}) -> Dictionary:
	clear_runtime(context)
	_active_room_node = room_node
	_objective_root_name = _resolve_objective_root_name(context)
	if _active_room_node == null or not is_instance_valid(_active_room_node):
		return get_snapshot()
	var objective_id := String(payload.get("objective_id", "kill_all")).strip_edges().to_lower()
	var clear_mode := String(payload.get("clear_mode", "kill_all")).strip_edges().to_lower()
	var waves := _duplicate_dictionary_array(payload.get("waves", []))
	var props := _duplicate_dictionary_array(payload.get("objective_props", []))
	var blocks_clear := objective_id == "hold_zone" or objective_id == "destroy_nodes" or objective_id == "destroy_spawner"
	if not blocks_clear and waves.is_empty() and props.is_empty():
		return get_snapshot()
	var objective_root := Node2D.new()
	objective_root.name = _objective_root_name
	objective_root.z_as_relative = false
	objective_root.z_index = int(context.get("objective_root_z_index", 0))
	_active_room_node.add_child(objective_root)
	objective_root.owner = null
	_objective_state = {
		"objective_id": objective_id,
		"clear_mode": clear_mode,
		"objective_label": String(payload.get("objective_label", "")).strip_edges(),
		"time_limit_sec": maxf(0.0, float(payload.get("time_limit_sec", 0.0))),
		"elapsed_sec": 0.0,
		"progress_sec": 0.0,
		"progress_count": 0,
		"required_count": 0,
		"completed": false,
		"active": blocks_clear,
		"blocks_clear": blocks_clear,
		"waves": waves,
		"success_bonus": _duplicate_dictionary(payload.get("success_bonus", {})),
		"fail_penalty": _duplicate_dictionary(payload.get("fail_penalty", {})),
		"room_mutators": _duplicate_string_array(payload.get("room_mutators", [])),
		"tags": _duplicate_string_array(payload.get("tags", []))
	}
	for prop_index in range(props.size()):
		var prop_variant: Variant = props[prop_index]
		if not (prop_variant is Dictionary):
			continue
		_spawn_room_objective_prop(objective_root, prop_variant as Dictionary, objective_id, prop_index, context)
	var objective_node_count := _count_objective_nodes()
	if objective_id == "destroy_nodes" or objective_id == "destroy_spawner":
		_objective_state["required_count"] = objective_node_count
		_objective_state["active"] = objective_node_count > 0
		_objective_state["blocks_clear"] = objective_node_count > 0
	elif objective_id == "hold_zone":
		_objective_state["required_count"] = 1 if _get_objective_zone() != null else 0
		_objective_state["active"] = _get_objective_zone() != null
		_objective_state["blocks_clear"] = _get_objective_zone() != null
	_sync_hold_open(context)
	return get_snapshot()


func update(delta: float, context: Dictionary = {}) -> Dictionary:
	if _objective_state.is_empty() or bool(_objective_state.get("completed", false)):
		return {}
	_objective_state["elapsed_sec"] = float(_objective_state.get("elapsed_sec", 0.0)) + maxf(delta, 0.0)
	_process_waves(context)
	var objective_id := String(_objective_state.get("objective_id", "")).strip_edges().to_lower()
	var result: Dictionary = {}
	match objective_id:
		"hold_zone":
			result = _update_hold_zone(delta, context)
		"destroy_nodes", "destroy_spawner":
			var required_count := maxi(0, int(_objective_state.get("required_count", 0)))
			var progress_count := maxi(0, int(_objective_state.get("progress_count", 0)))
			if required_count > 0 and progress_count >= required_count:
				result = complete_objective(false, context)
		_:
			result = {}
	_sync_hold_open(context)
	return result


func complete_objective(force_clear: bool = false, context: Dictionary = {}) -> Dictionary:
	if _objective_state.is_empty() or bool(_objective_state.get("completed", false)):
		return {}
	_objective_state["completed"] = true
	_objective_state["active"] = false
	_objective_state["blocks_clear"] = false
	var materials := _extract_success_bonus_materials(_objective_state.get("success_bonus", {}))
	var clear_mode := String(_objective_state.get("clear_mode", "kill_all")).strip_edges().to_lower()
	var handled_by_enemy_manager := false
	var enemy_manager_variant: Variant = context.get("enemy_manager", null)
	if enemy_manager_variant is Node and is_instance_valid(enemy_manager_variant):
		var enemy_manager: Node = enemy_manager_variant
		if enemy_manager.has_method("set_scripted_encounter_hold_open"):
			enemy_manager.call("set_scripted_encounter_hold_open", false)
		if enemy_manager.has_method("clear_scripted_encounter"):
			if force_clear or clear_mode == "complete_objective":
				enemy_manager.call("clear_scripted_encounter", true, true)
				handled_by_enemy_manager = true
			elif clear_mode == "objective_then_cleanup" and _get_alive_enemy_count(context) <= 0:
				enemy_manager.call("clear_scripted_encounter", false, true)
				handled_by_enemy_manager = true
	return {
		"completed": true,
		"handled_by_enemy_manager": handled_by_enemy_manager,
		"should_mark_room_cleared": not handled_by_enemy_manager and (
			force_clear
			or clear_mode == "complete_objective"
			or (clear_mode == "objective_then_cleanup" and _get_alive_enemy_count(context) <= 0)
		),
		"success_bonus_materials": materials,
		"objective": get_snapshot()
	}


func handle_objective_node_destroyed(_objective_id: String, context: Dictionary = {}) -> Dictionary:
	if _objective_state.is_empty() or bool(_objective_state.get("completed", false)):
		return {}
	var required_count := maxi(1, int(_objective_state.get("required_count", 1)))
	var progress_count := maxi(0, int(_objective_state.get("progress_count", 0))) + 1
	_objective_state["progress_count"] = mini(required_count, progress_count)
	return update(0.0, context)


func clear_runtime(context: Dictionary = {}) -> void:
	_set_hold_open(false, context)
	var objective_root := _get_objective_root()
	if objective_root != null and is_instance_valid(objective_root):
		objective_root.queue_free()
	_objective_state.clear()


func has_active_objective() -> bool:
	return bool(_objective_state.get("active", false)) and bool(_objective_state.get("blocks_clear", false))


func is_completed() -> bool:
	return bool(_objective_state.get("completed", false))


func has_pending_waves() -> bool:
	if _objective_state.is_empty() or bool(_objective_state.get("completed", false)):
		return false
	var waves_variant: Variant = _objective_state.get("waves", [])
	if not (waves_variant is Array):
		return false
	for wave_variant in waves_variant:
		if not (wave_variant is Dictionary):
			continue
		var wave: Dictionary = wave_variant
		var trigger := String(wave.get("trigger", "on_timer")).strip_edges().to_lower()
		if trigger == "repeat":
			if bool(wave.get("until_objective_complete", false)) and bool(_objective_state.get("completed", false)):
				continue
			return true
		if not bool(wave.get("_fired", false)):
			return true
	return false


func should_defer_room_resolution() -> bool:
	return has_active_objective() or has_pending_waves()


func sync_hold_open(context: Dictionary = {}) -> void:
	_sync_hold_open(context)


func get_snapshot() -> Dictionary:
	return _objective_state.duplicate(true)


func get_status_text() -> String:
	if _objective_state.is_empty() or bool(_objective_state.get("completed", false)):
		return ""
	if not bool(_objective_state.get("blocks_clear", false)):
		return ""
	var objective_label := String(_objective_state.get("objective_label", "")).strip_edges()
	var objective_id := String(_objective_state.get("objective_id", "")).strip_edges().to_lower()
	match objective_id:
		"hold_zone":
			var progress_sec := float(_objective_state.get("progress_sec", 0.0))
			var required_sec := maxf(0.0, float(_objective_state.get("time_limit_sec", 0.0)))
			return "%s %.1fs / %.1fs" % [objective_label, progress_sec, required_sec]
		"destroy_nodes", "destroy_spawner":
			return "%s %d / %d" % [
				objective_label,
				maxi(0, int(_objective_state.get("progress_count", 0))),
				maxi(0, int(_objective_state.get("required_count", 0)))
			]
	return objective_label


func get_objective_node_count() -> int:
	var total := _count_objective_nodes()
	if _get_objective_zone() != null:
		total += 1
	return total


func _spawn_room_objective_prop(
	objective_root: Node2D,
	prop: Dictionary,
	objective_id: String,
	prop_index: int,
	context: Dictionary
) -> void:
	if objective_root == null:
		return
	var world_position: Vector2 = _coerce_vector2(prop.get("position", objective_root.global_position))
	var local_position: Vector2 = objective_root.to_local(world_position)
	var prop_id := String(prop.get("prop_id", prop.get("id", ""))).strip_edges().to_lower()
	var use_zone := objective_id == "hold_zone"
	if not use_zone:
		use_zone = prop_id.find("zone") >= 0 or prop_id.find("beacon") >= 0
	if use_zone:
		var zone_variant: Variant = ObjectiveZoneScene.instantiate()
		if not (zone_variant is Node2D):
			return
		var zone := zone_variant as Node2D
		zone.name = "ObjectiveZone_%d" % prop_index
		zone.position = local_position
		objective_root.add_child(zone)
		if zone.has_method("configure_from_payload"):
			zone.call("configure_from_payload", prop)
		return
	var node_variant: Variant = ObjectiveNodeScene.instantiate()
	if not (node_variant is StaticBody2D):
		return
	var objective_node := node_variant as StaticBody2D
	objective_node.name = "ObjectiveNode_%d" % prop_index
	objective_node.position = local_position
	objective_root.add_child(objective_node)
	if objective_node.has_method("configure_from_payload"):
		objective_node.call("configure_from_payload", prop)
	var destroyed_callback_variant: Variant = context.get("objective_destroyed_callback", Callable())
	if objective_node.has_signal("objective_destroyed") and destroyed_callback_variant is Callable:
		var destroyed_callback: Callable = destroyed_callback_variant
		if destroyed_callback.is_valid() and not objective_node.is_connected("objective_destroyed", destroyed_callback):
			objective_node.connect("objective_destroyed", destroyed_callback)


func _update_hold_zone(delta: float, context: Dictionary = {}) -> Dictionary:
	var zone := _get_objective_zone()
	if zone == null or not zone.has_method("contains_world_point"):
		return {}
	var player_variant: Variant = context.get("player", null)
	if not (player_variant is Node2D):
		return {}
	var player := player_variant as Node2D
	if bool(zone.call("contains_world_point", player.global_position)):
		var progress_sec := float(_objective_state.get("progress_sec", 0.0)) + maxf(delta, 0.0)
		var required_sec := maxf(0.0, float(_objective_state.get("time_limit_sec", 0.0)))
		if required_sec > 0.0:
			progress_sec = minf(progress_sec, required_sec)
		_objective_state["progress_sec"] = progress_sec
	var goal_sec := maxf(0.0, float(_objective_state.get("time_limit_sec", 0.0)))
	if goal_sec <= 0.0 or float(_objective_state.get("progress_sec", 0.0)) >= goal_sec:
		return complete_objective(false, context)
	return {}


func _process_waves(context: Dictionary = {}) -> void:
	var waves_variant: Variant = _objective_state.get("waves", [])
	if not (waves_variant is Array):
		return
	var waves: Array = waves_variant
	if waves.is_empty():
		return
	var elapsed_sec := float(_objective_state.get("elapsed_sec", 0.0))
	var progress_count := maxi(0, int(_objective_state.get("progress_count", 0)))
	var objective_completed := bool(_objective_state.get("completed", false))
	for wave_index in range(waves.size()):
		var wave_variant: Variant = waves[wave_index]
		if not (wave_variant is Dictionary):
			continue
		var wave: Dictionary = (wave_variant as Dictionary).duplicate(true)
		var trigger := String(wave.get("trigger", "on_timer")).strip_edges().to_lower()
		var should_fire := false
		match trigger:
			"on_start":
				should_fire = not bool(wave.get("_fired", false))
			"on_timer":
				should_fire = (
					not bool(wave.get("_fired", false))
					and elapsed_sec >= maxf(0.0, float(wave.get("at_sec", 0.0)))
				)
			"on_objective_progress":
				should_fire = (
					not bool(wave.get("_fired", false))
					and not objective_completed
					and progress_count >= maxi(1, int(wave.get("at_count", 1)))
				)
			"repeat":
				if objective_completed and bool(wave.get("until_objective_complete", false)):
					should_fire = false
				else:
					var every_sec := maxf(0.5, float(wave.get("every_sec", 6.0)))
					var next_fire_sec := float(wave.get("_next_fire_sec", every_sec))
					if elapsed_sec >= next_fire_sec:
						should_fire = true
						wave["_next_fire_sec"] = next_fire_sec + every_sec
			_:
				should_fire = false
		if should_fire:
			var enemies_variant: Variant = wave.get("enemies", [])
			var enemy_manager_variant: Variant = context.get("enemy_manager", null)
			if enemy_manager_variant is Node and is_instance_valid(enemy_manager_variant):
				var enemy_manager: Node = enemy_manager_variant
				if enemy_manager.has_method("spawn_scripted_wave"):
					enemy_manager.call("spawn_scripted_wave", String(context.get("room_id", "")).strip_edges(), enemies_variant)
			if trigger != "repeat":
				wave["_fired"] = true
		waves[wave_index] = wave
	_objective_state["waves"] = waves


func _extract_success_bonus_materials(success_bonus_variant: Variant) -> Dictionary:
	if not (success_bonus_variant is Dictionary):
		return {}
	var materials_variant: Variant = (success_bonus_variant as Dictionary).get("carryover_materials", {})
	return _duplicate_dictionary(materials_variant)


func _get_alive_enemy_count(context: Dictionary = {}) -> int:
	var enemy_manager_variant: Variant = context.get("enemy_manager", null)
	if not (enemy_manager_variant is Node) or not is_instance_valid(enemy_manager_variant):
		return 0
	return maxi(0, int((enemy_manager_variant as Node).get("alive_enemy_count")))


func _get_objective_root() -> Node2D:
	if _active_room_node == null or not is_instance_valid(_active_room_node):
		return null
	var objective_root_variant: Variant = _active_room_node.get_node_or_null(_objective_root_name)
	if objective_root_variant is Node2D:
		return objective_root_variant as Node2D
	return null


func _get_objective_zone() -> Node2D:
	var objective_root := _get_objective_root()
	if objective_root == null:
		return null
	for child in objective_root.get_children():
		if child == null or not is_instance_valid(child):
			continue
		if child is Node2D and child.has_method("contains_world_point"):
			return child as Node2D
	return null


func _count_objective_nodes() -> int:
	var objective_root := _get_objective_root()
	if objective_root == null:
		return 0
	var total := 0
	for child in objective_root.get_children():
		if child == null or not is_instance_valid(child):
			continue
		if String(child.name).begins_with("ObjectiveNode_"):
			total += 1
	return total


func _set_hold_open(hold_open: bool, context: Dictionary = {}) -> void:
	var enemy_manager_variant: Variant = context.get("enemy_manager", null)
	if not (enemy_manager_variant is Node) or not is_instance_valid(enemy_manager_variant):
		return
	var enemy_manager := enemy_manager_variant as Node
	if enemy_manager.has_method("set_scripted_encounter_hold_open"):
		enemy_manager.call("set_scripted_encounter_hold_open", hold_open)


func _sync_hold_open(context: Dictionary = {}) -> void:
	_set_hold_open(has_active_objective() or has_pending_waves(), context)


func _duplicate_dictionary(value: Variant) -> Dictionary:
	return value.duplicate(true) if value is Dictionary else {}


func _duplicate_dictionary_array(value: Variant) -> Array:
	if not (value is Array):
		return []
	var rows: Array = []
	for row_variant in value:
		rows.append(row_variant.duplicate(true) if row_variant is Dictionary else row_variant)
	return rows


func _duplicate_string_array(value: Variant) -> Array[String]:
	var rows: Array[String] = []
	if not (value is Array):
		return rows
	for row_variant in value:
		rows.append(String(row_variant).strip_edges())
	return rows


func _coerce_vector2(value: Variant, fallback: Vector2 = Vector2.ZERO) -> Vector2:
	if value is Vector2:
		return value
	if value is Array and (value as Array).size() >= 2:
		var row := value as Array
		return Vector2(float(row[0]), float(row[1]))
	return fallback


func _resolve_objective_root_name(context: Dictionary = {}) -> String:
	var objective_root_name := String(context.get("objective_root_name", _objective_root_name)).strip_edges()
	if objective_root_name.is_empty():
		return "RuntimeObjectives"
	return objective_root_name
