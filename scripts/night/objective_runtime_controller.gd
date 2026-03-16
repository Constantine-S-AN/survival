extends RefCounted
class_name ObjectiveRuntimeController

const ObjectiveNodeScene := preload("res://scenes/night/rooms/setpieces/ObjectiveNode.tscn")
const ObjectiveZoneScene := preload("res://scenes/night/rooms/setpieces/ObjectiveZone.tscn")
const ObjectiveInteractionScene := preload("res://scenes/night/rooms/setpieces/RoomInteractable.tscn")

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
	var runtime_flags := _duplicate_dictionary(payload.get("runtime_flags", {}))
	var escort_integrity_max := maxf(1.0, float(runtime_flags.get("integrity_max", 100.0)))
	var blocks_clear := objective_id != "kill_all"
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
		"failed": false,
		"failure_reason": "",
		"active": blocks_clear,
		"blocks_clear": blocks_clear,
		"waves": waves,
		"objective_props": props.duplicate(true),
		"success_bonus": _duplicate_dictionary(payload.get("success_bonus", {})),
		"fail_penalty": _duplicate_dictionary(payload.get("fail_penalty", {})),
		"room_mutators": _duplicate_string_array(payload.get("room_mutators", [])),
		"tags": _duplicate_string_array(payload.get("tags", [])),
		"telegraph_ui": _duplicate_dictionary(payload.get("telegraph_ui", {})),
		"runtime_flags": runtime_flags,
		"focused_interaction_id": "",
		"interaction_started": false,
		"interaction_count": 0,
		"escort_integrity_max": escort_integrity_max,
		"escort_integrity": escort_integrity_max
	}
	for prop_index in range(props.size()):
		var prop_variant: Variant = props[prop_index]
		if not (prop_variant is Dictionary):
			continue
		_spawn_room_objective_prop(objective_root, prop_variant as Dictionary, objective_id, prop_index, context)
	_initialize_objective_state(objective_id)
	_sync_hold_open(context)
	return get_snapshot()


func update(delta: float, context: Dictionary = {}) -> Dictionary:
	if _objective_state.is_empty() or _is_resolved():
		return {}
	_objective_state["elapsed_sec"] = float(_objective_state.get("elapsed_sec", 0.0)) + maxf(delta, 0.0)
	_process_waves(context)
	var objective_id := String(_objective_state.get("objective_id", "")).strip_edges().to_lower()
	var result: Dictionary = {}
	match objective_id:
		"hold_zone":
			result = _update_hold_zone(delta, context)
		"destroy_nodes", "destroy_spawner":
			if _progress_reached_goal():
				result = complete_objective(false, context)
		"escort":
			result = _update_escort(delta, context)
		"payload_hack":
			result = _update_payload_hack(delta, context)
		"survive_timer":
			result = _update_survive_timer(context)
		"elite_hunt":
			result = _update_elite_hunt(context)
		"power_reroute":
			result = _update_power_reroute(context)
		"cursed_cache":
			result = _update_cursed_cache(context)
		_:
			result = {}
	if result.is_empty():
		result = _check_fail_conditions(objective_id, context)
	_sync_hold_open(context)
	return result


func complete_objective(force_clear: bool = false, context: Dictionary = {}) -> Dictionary:
	if _objective_state.is_empty() or _is_resolved():
		return {}
	_objective_state["completed"] = true
	_objective_state["active"] = false
	_objective_state["blocks_clear"] = false
	_objective_state["interaction_started"] = false
	_set_objective_interaction_focus("")
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
	if _objective_state.is_empty() or _is_resolved():
		return {}
	var objective_kind := String(_objective_state.get("objective_id", "")).strip_edges().to_lower()
	if objective_kind != "destroy_nodes" and objective_kind != "destroy_spawner" and objective_kind != "cursed_cache":
		return {}
	var required_count := maxi(1, int(_objective_state.get("required_count", 1)))
	var progress_count := maxi(0, int(_objective_state.get("progress_count", 0))) + 1
	_objective_state["progress_count"] = mini(required_count, progress_count)
	if objective_kind == "cursed_cache" and _progress_reached_goal():
		return {
			"objective": get_snapshot(),
			"note": _tr("night.objective.note.cache_ready")
		}
	return update(0.0, context)


func handle_enemy_killed(_enemy_id: String, meta: Dictionary = {}, context: Dictionary = {}) -> Dictionary:
	if _objective_state.is_empty() or _is_resolved():
		return {}
	if String(_objective_state.get("objective_id", "")).strip_edges().to_lower() != "elite_hunt":
		return {}
	var is_target := bool(meta.get("is_elite", false)) or bool(meta.get("is_pursuer", false))
	if not is_target:
		var spawn_group := String(meta.get("spawn_group", "")).strip_edges().to_lower()
		is_target = spawn_group == "pursuer"
	if not is_target:
		return {}
	var required_count := maxi(1, int(_objective_state.get("required_count", 1)))
	var progress_count := maxi(0, int(_objective_state.get("progress_count", 0))) + 1
	_objective_state["progress_count"] = mini(required_count, progress_count)
	return update(0.0, context)


func clear_runtime(context: Dictionary = {}) -> void:
	_set_hold_open(false, context)
	_set_objective_interaction_focus("")
	var objective_root := _get_objective_root()
	if objective_root != null and is_instance_valid(objective_root):
		objective_root.queue_free()
	_objective_state.clear()


func has_active_objective() -> bool:
	return bool(_objective_state.get("active", false)) and bool(_objective_state.get("blocks_clear", false))


func is_completed() -> bool:
	return bool(_objective_state.get("completed", false))


func has_pending_waves() -> bool:
	if _objective_state.is_empty() or _is_resolved():
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
			if bool(wave.get("until_objective_complete", false)) and _is_resolved():
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
	if _objective_state.is_empty():
		return {}
	var snapshot := _objective_state.duplicate(true)
	var active_target := _get_active_target_snapshot()
	snapshot["current_target_index"] = int(active_target.get("index", -1))
	snapshot["active_target_label"] = String(active_target.get("label", ""))
	snapshot["active_target_position"] = active_target.get("position", Vector2.ZERO)
	snapshot["interactions"] = get_interaction_snapshots()
	return snapshot


func get_status_text() -> String:
	if _objective_state.is_empty() or _is_resolved():
		return ""
	if not bool(_objective_state.get("blocks_clear", false)):
		return ""
	var objective_label := String(_objective_state.get("objective_label", "")).strip_edges()
	var objective_id := String(_objective_state.get("objective_id", "")).strip_edges().to_lower()
	var progress_count := maxi(0, int(_objective_state.get("progress_count", 0)))
	var required_count := maxi(0, int(_objective_state.get("required_count", 0)))
	var progress_sec := float(_objective_state.get("progress_sec", 0.0))
	var time_limit_sec := maxf(0.0, float(_objective_state.get("time_limit_sec", 0.0)))
	match objective_id:
		"hold_zone":
			return "%s %.1fs / %.1fs" % [objective_label, progress_sec, time_limit_sec]
		"destroy_nodes", "destroy_spawner":
			return "%s %d / %d" % [objective_label, progress_count, required_count]
		"escort":
			var integrity_pct := int(round(clampf(_escort_integrity_ratio(), 0.0, 1.0) * 100.0))
			return "%s %d / %d · %.1fs · %d%%" % [
				objective_label,
				progress_count,
				required_count,
				progress_sec,
				integrity_pct
			]
		"payload_hack":
			var payload_goal := _payload_hack_hold_sec()
			if bool(_objective_state.get("interaction_started", false)):
				return "%s %d / %d · %.1fs / %.1fs" % [
					objective_label,
					progress_count,
					required_count,
					progress_sec,
					payload_goal
				]
			return "%s %d / %d" % [objective_label, progress_count, required_count]
		"survive_timer":
			return "%s %.1fs / %.1fs" % [objective_label, minf(progress_sec, time_limit_sec), time_limit_sec]
		"elite_hunt":
			if time_limit_sec > 0.0:
				var remaining := maxf(0.0, time_limit_sec - float(_objective_state.get("elapsed_sec", 0.0)))
				return "%s %d / %d · %.1fs" % [objective_label, progress_count, required_count, remaining]
			return "%s %d / %d" % [objective_label, progress_count, required_count]
		"power_reroute", "cursed_cache":
			return "%s %d / %d" % [objective_label, progress_count, required_count]
	return objective_label


func get_objective_node_count() -> int:
	return _count_objective_nodes() + _count_objective_zones()


func get_interaction_snapshots() -> Array[Dictionary]:
	var snapshots: Array[Dictionary] = []
	for interaction_node in _get_objective_interactions():
		if interaction_node == null or not is_instance_valid(interaction_node):
			continue
		if not _is_interaction_enabled(interaction_node):
			continue
		if interaction_node.has_method("get_snapshot"):
			var snapshot_variant: Variant = interaction_node.call("get_snapshot")
			if snapshot_variant is Dictionary:
				snapshots.append((snapshot_variant as Dictionary).duplicate(true))
	return snapshots


func update_interaction_focus(context: Dictionary = {}) -> Dictionary:
	var player_variant: Variant = context.get("player", null)
	if not (player_variant is Node2D):
		_set_objective_interaction_focus("")
		return {}
	var player := player_variant as Node2D
	var best_id := ""
	var best_distance := INF
	for interaction_node in _get_objective_interactions():
		if interaction_node == null or not is_instance_valid(interaction_node):
			continue
		if not _is_interaction_enabled(interaction_node):
			if interaction_node.has_method("set_focused"):
				interaction_node.call("set_focused", false)
			continue
		var contains := false
		if interaction_node.has_method("contains_world_point"):
			contains = bool(interaction_node.call("contains_world_point", player.global_position))
		if not contains:
			if interaction_node.has_method("set_focused"):
				interaction_node.call("set_focused", false)
			continue
		var interaction_id := String(interaction_node.get("interaction_id")).strip_edges()
		if interaction_id.is_empty():
			continue
		var distance := (interaction_node as Node2D).global_position.distance_to(player.global_position)
		if distance < best_distance:
			best_distance = distance
			best_id = interaction_id
	_set_objective_interaction_focus(best_id)
	return get_focused_interaction_snapshot()


func get_focused_interaction_snapshot() -> Dictionary:
	if _objective_state.is_empty():
		return {}
	var focused_id := String(_objective_state.get("focused_interaction_id", "")).strip_edges()
	if focused_id.is_empty():
		return {}
	var interaction_node := _find_interaction_by_id(focused_id)
	if interaction_node == null or not is_instance_valid(interaction_node) or not _is_interaction_enabled(interaction_node):
		return {}
	if interaction_node.has_method("get_snapshot"):
		var snapshot_variant: Variant = interaction_node.call("get_snapshot")
		if snapshot_variant is Dictionary:
			return (snapshot_variant as Dictionary).duplicate(true)
	return {}


func activate_interaction(interaction_id: String = "", context: Dictionary = {}) -> Dictionary:
	if _objective_state.is_empty() or _is_resolved():
		return {}
	var objective_id := String(_objective_state.get("objective_id", "")).strip_edges().to_lower()
	if objective_id != "payload_hack" and objective_id != "power_reroute" and objective_id != "cursed_cache":
		return {}
	var normalized_id := interaction_id.strip_edges()
	if normalized_id.is_empty():
		normalized_id = String(_objective_state.get("focused_interaction_id", "")).strip_edges()
	var interaction_node := _find_interaction_by_id(normalized_id)
	if interaction_node == null or not is_instance_valid(interaction_node) or not _is_interaction_enabled(interaction_node):
		return {}
	var prop_index := int(interaction_node.get_meta("objective_prop_index", -1))
	var label := String(interaction_node.get("label")).strip_edges()
	match objective_id:
		"payload_hack":
			if prop_index != maxi(0, int(_objective_state.get("progress_count", 0))):
				return {}
			_objective_state["interaction_started"] = true
			_objective_state["progress_sec"] = 0.0
			return {
				"objective": get_snapshot(),
				"note": _tr("night.objective.note.payload_started", {"value": label})
			}
		"power_reroute":
			if prop_index != maxi(0, int(_objective_state.get("progress_count", 0))):
				return {}
			_objective_state["progress_count"] = mini(
				maxi(1, int(_objective_state.get("required_count", 1))),
				maxi(0, int(_objective_state.get("progress_count", 0))) + 1
			)
			if _progress_reached_goal():
				return complete_objective(false, context)
			return {
				"objective": get_snapshot(),
				"note": _tr("night.objective.note.relay_rerouted", {"value": label})
			}
		"cursed_cache":
			if prop_index < 0 or not _cache_interaction_ready():
				return {}
			return _complete_cursed_cache(label, context)
	return {}


func _initialize_objective_state(objective_id: String) -> void:
	var objective_node_count := _count_objective_nodes()
	var objective_zone_count := _count_objective_zones()
	var interaction_count := _get_objective_interactions().size()
	_objective_state["interaction_count"] = interaction_count
	match objective_id:
		"destroy_nodes", "destroy_spawner":
			_objective_state["required_count"] = objective_node_count
			_objective_state["active"] = objective_node_count > 0
			_objective_state["blocks_clear"] = objective_node_count > 0
		"hold_zone":
			_objective_state["required_count"] = 1 if objective_zone_count > 0 else 0
			_objective_state["active"] = objective_zone_count > 0
			_objective_state["blocks_clear"] = objective_zone_count > 0
		"escort":
			_objective_state["required_count"] = objective_zone_count
			_objective_state["active"] = objective_zone_count > 0
			_objective_state["blocks_clear"] = objective_zone_count > 0
		"payload_hack":
			_objective_state["required_count"] = maxi(objective_zone_count, interaction_count)
			_objective_state["active"] = int(_objective_state.get("required_count", 0)) > 0
			_objective_state["blocks_clear"] = bool(_objective_state.get("active", false))
		"survive_timer":
			_objective_state["required_count"] = 1
			_objective_state["active"] = maxf(0.0, float(_objective_state.get("time_limit_sec", 0.0))) > 0.0
			_objective_state["blocks_clear"] = bool(_objective_state.get("active", false))
		"elite_hunt":
			var runtime_flags: Dictionary = _objective_state.get("runtime_flags", {})
			_objective_state["required_count"] = maxi(1, int(runtime_flags.get("required_count", 1)))
			_objective_state["active"] = true
			_objective_state["blocks_clear"] = true
		"power_reroute":
			_objective_state["required_count"] = interaction_count
			_objective_state["active"] = interaction_count > 0
			_objective_state["blocks_clear"] = interaction_count > 0
		"cursed_cache":
			_objective_state["required_count"] = objective_node_count
			_objective_state["active"] = objective_node_count > 0 or interaction_count > 0
			_objective_state["blocks_clear"] = bool(_objective_state.get("active", false))
		_:
			_objective_state["required_count"] = 0
			_objective_state["active"] = false
			_objective_state["blocks_clear"] = false


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
	var display_name := String(prop.get("display_name", prop.get("label", prop_id.capitalize()))).strip_edges()
	if _should_spawn_zone(objective_id, prop_id):
		var zone_variant: Variant = ObjectiveZoneScene.instantiate()
		if zone_variant is Node2D:
			var zone := zone_variant as Node2D
			zone.name = "ObjectiveZone_%d" % prop_index
			zone.position = local_position
			objective_root.add_child(zone)
			zone.owner = null
			if zone.has_method("configure_from_payload"):
				zone.call("configure_from_payload", prop)
	if _should_spawn_node(objective_id, prop_id):
		var node_variant: Variant = ObjectiveNodeScene.instantiate()
		if node_variant is StaticBody2D:
			var objective_node := node_variant as StaticBody2D
			objective_node.name = "ObjectiveNode_%d" % prop_index
			objective_node.position = local_position
			objective_root.add_child(objective_node)
			objective_node.owner = null
			if objective_node.has_method("configure_from_payload"):
				objective_node.call("configure_from_payload", prop)
			var destroyed_callback_variant: Variant = context.get("objective_destroyed_callback", Callable())
			if objective_node.has_signal("objective_destroyed") and destroyed_callback_variant is Callable:
				var destroyed_callback: Callable = destroyed_callback_variant
				if destroyed_callback.is_valid() and not objective_node.is_connected("objective_destroyed", destroyed_callback):
					objective_node.connect("objective_destroyed", destroyed_callback)
	if _should_spawn_interaction(objective_id, prop_id):
		var interaction_variant: Variant = ObjectiveInteractionScene.instantiate()
		if interaction_variant is Node2D:
			var interaction_node := interaction_variant as Node2D
			interaction_node.name = "ObjectiveInteraction_%d" % prop_index
			interaction_node.position = local_position
			objective_root.add_child(interaction_node)
			interaction_node.owner = null
			interaction_node.set_meta("objective_prop_index", prop_index)
			interaction_node.set_meta("objective_prop_id", prop_id)
			if interaction_node.has_method("configure_from_payload"):
				interaction_node.call("configure_from_payload", {
					"interaction_id": "objective_%d" % prop_index,
					"interaction_kind": _interaction_kind_for_objective(objective_id, prop_id),
					"label": display_name,
					"prompt_text": _interaction_prompt_for_objective(objective_id, display_name),
					"radius": maxf(36.0, float(prop.get("radius", 72.0)))
				})


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


func _update_escort(delta: float, context: Dictionary = {}) -> Dictionary:
	var player_variant: Variant = context.get("player", null)
	if not (player_variant is Node2D):
		return {}
	var zone := _get_objective_zone_at(maxi(0, int(_objective_state.get("progress_count", 0))))
	if zone == null or not zone.has_method("contains_world_point"):
		return {}
	var runtime_flags: Dictionary = _objective_state.get("runtime_flags", {})
	var player := player_variant as Node2D
	var inside := bool(zone.call("contains_world_point", player.global_position))
	var integrity := float(_objective_state.get("escort_integrity", 0.0))
	if inside:
		_objective_state["progress_sec"] = float(_objective_state.get("progress_sec", 0.0)) + maxf(delta, 0.0)
		integrity += float(runtime_flags.get("integrity_recover_per_sec", 12.0)) * maxf(delta, 0.0)
	else:
		integrity -= float(runtime_flags.get("integrity_drain_per_sec", 20.0)) * maxf(delta, 0.0)
	var integrity_max := maxf(1.0, float(_objective_state.get("escort_integrity_max", 100.0)))
	_objective_state["escort_integrity"] = clampf(integrity, 0.0, integrity_max)
	var hold_sec := maxf(0.4, float(runtime_flags.get("checkpoint_hold_sec", 1.6)))
	if float(_objective_state.get("progress_sec", 0.0)) >= hold_sec:
		_objective_state["progress_count"] = mini(
			maxi(1, int(_objective_state.get("required_count", 1))),
			maxi(0, int(_objective_state.get("progress_count", 0))) + 1
		)
		_objective_state["progress_sec"] = 0.0
		if _progress_reached_goal():
			return complete_objective(false, context)
		return {
			"objective": get_snapshot(),
			"note": _tr("night.objective.note.checkpoint_secured")
		}
	return {}


func _update_payload_hack(delta: float, context: Dictionary = {}) -> Dictionary:
	if not bool(_objective_state.get("interaction_started", false)):
		return {}
	var player_variant: Variant = context.get("player", null)
	if not (player_variant is Node2D):
		return {}
	var zone := _get_objective_zone_at(maxi(0, int(_objective_state.get("progress_count", 0))))
	if zone == null or not zone.has_method("contains_world_point"):
		return {}
	var runtime_flags: Dictionary = _objective_state.get("runtime_flags", {})
	var player := player_variant as Node2D
	if bool(zone.call("contains_world_point", player.global_position)):
		_objective_state["progress_sec"] = float(_objective_state.get("progress_sec", 0.0)) + maxf(delta, 0.0)
	else:
		var decay_per_sec := maxf(0.0, float(runtime_flags.get("progress_decay_per_sec", 1.2)))
		_objective_state["progress_sec"] = maxf(0.0, float(_objective_state.get("progress_sec", 0.0)) - decay_per_sec * maxf(delta, 0.0))
	var hold_sec := _payload_hack_hold_sec()
	if float(_objective_state.get("progress_sec", 0.0)) >= hold_sec:
		_objective_state["progress_count"] = mini(
			maxi(1, int(_objective_state.get("required_count", 1))),
			maxi(0, int(_objective_state.get("progress_count", 0))) + 1
		)
		_objective_state["interaction_started"] = false
		_objective_state["progress_sec"] = 0.0
		if _progress_reached_goal():
			return complete_objective(false, context)
		return {
			"objective": get_snapshot(),
			"note": _tr("night.objective.note.payload_step_complete")
		}
	return {}


func _update_survive_timer(context: Dictionary = {}) -> Dictionary:
	var goal_sec := maxf(0.0, float(_objective_state.get("time_limit_sec", 0.0)))
	_objective_state["progress_sec"] = minf(float(_objective_state.get("elapsed_sec", 0.0)), goal_sec)
	if goal_sec > 0.0 and float(_objective_state.get("elapsed_sec", 0.0)) >= goal_sec:
		return complete_objective(false, context)
	return {}


func _update_elite_hunt(context: Dictionary = {}) -> Dictionary:
	if _progress_reached_goal():
		return complete_objective(false, context)
	return {}


func _update_power_reroute(context: Dictionary = {}) -> Dictionary:
	if _progress_reached_goal():
		return complete_objective(false, context)
	return {}


func _update_cursed_cache(context: Dictionary = {}) -> Dictionary:
	if bool(_objective_state.get("interaction_started", false)):
		return complete_objective(false, context)
	return {}


func _complete_cursed_cache(label: String, context: Dictionary = {}) -> Dictionary:
	var result := complete_objective(false, context)
	result["note"] = _tr("night.objective.note.cache_opened", {"value": label})
	result["objective"] = get_snapshot()
	return result


func _check_fail_conditions(objective_id: String, context: Dictionary = {}) -> Dictionary:
	var elapsed_sec := float(_objective_state.get("elapsed_sec", 0.0))
	var time_limit_sec := maxf(0.0, float(_objective_state.get("time_limit_sec", 0.0)))
	if _can_fail_on_deadline(objective_id) and time_limit_sec > 0.0 and elapsed_sec >= time_limit_sec:
		return _fail_objective("timer", context)
	if objective_id == "escort" and float(_objective_state.get("escort_integrity", 0.0)) <= 0.0:
		return _fail_objective("integrity", context)
	return {}


func _fail_objective(reason: String, context: Dictionary = {}) -> Dictionary:
	if _objective_state.is_empty() or _is_resolved():
		return {}
	_objective_state["failed"] = true
	_objective_state["failure_reason"] = reason
	_objective_state["active"] = false
	_objective_state["blocks_clear"] = false
	_objective_state["interaction_started"] = false
	_set_objective_interaction_focus("")
	_apply_fail_penalty(context)
	var handled_by_enemy_manager := false
	var should_mark_room_cleared := _get_alive_enemy_count(context) <= 0
	var enemy_manager_variant: Variant = context.get("enemy_manager", null)
	if should_mark_room_cleared and enemy_manager_variant is Node and is_instance_valid(enemy_manager_variant):
		var enemy_manager: Node = enemy_manager_variant
		if enemy_manager.has_method("clear_scripted_encounter"):
			enemy_manager.call("clear_scripted_encounter", false, true)
			handled_by_enemy_manager = true
	return {
		"failed": true,
		"handled_by_enemy_manager": handled_by_enemy_manager,
		"should_mark_room_cleared": should_mark_room_cleared and not handled_by_enemy_manager,
		"note": _failure_note_for_reason(reason),
		"objective": get_snapshot()
	}


func _apply_fail_penalty(context: Dictionary = {}) -> void:
	var fail_penalty_variant: Variant = _objective_state.get("fail_penalty", {})
	if not (fail_penalty_variant is Dictionary):
		return
	var enemies_variant: Variant = (fail_penalty_variant as Dictionary).get("enemies", [])
	if not (enemies_variant is Array) or (enemies_variant as Array).is_empty():
		return
	var enemy_manager_variant: Variant = context.get("enemy_manager", null)
	if not (enemy_manager_variant is Node) or not is_instance_valid(enemy_manager_variant):
		return
	var enemy_manager := enemy_manager_variant as Node
	if enemy_manager.has_method("spawn_scripted_wave"):
		enemy_manager.call("spawn_scripted_wave", String(context.get("room_id", "")).strip_edges(), enemies_variant)


func _process_waves(context: Dictionary = {}) -> void:
	var waves_variant: Variant = _objective_state.get("waves", [])
	if not (waves_variant is Array):
		return
	var waves: Array = waves_variant
	if waves.is_empty():
		return
	var elapsed_sec := float(_objective_state.get("elapsed_sec", 0.0))
	var progress_count := maxi(0, int(_objective_state.get("progress_count", 0)))
	var objective_resolved := _is_resolved()
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
					and not objective_resolved
					and progress_count >= maxi(1, int(wave.get("at_count", 1)))
				)
			"repeat":
				if objective_resolved and bool(wave.get("until_objective_complete", false)):
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
	return _get_objective_zone_at(0)


func _get_objective_zone_at(index: int) -> Node2D:
	var objective_root := _get_objective_root()
	if objective_root == null:
		return null
	var target_name := "ObjectiveZone_%d" % maxi(0, index)
	var zone_variant: Variant = objective_root.get_node_or_null(target_name)
	if zone_variant is Node2D:
		return zone_variant as Node2D
	return null


func _count_objective_zones() -> int:
	var objective_root := _get_objective_root()
	if objective_root == null:
		return 0
	var total := 0
	for child in objective_root.get_children():
		if child == null or not is_instance_valid(child):
			continue
		if String(child.name).begins_with("ObjectiveZone_"):
			total += 1
	return total


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


func _get_objective_interactions() -> Array[Node2D]:
	var nodes: Array[Node2D] = []
	var objective_root := _get_objective_root()
	if objective_root == null:
		return nodes
	for child in objective_root.get_children():
		if child == null or not is_instance_valid(child):
			continue
		if child is Node2D and String(child.name).begins_with("ObjectiveInteraction_"):
			nodes.append(child as Node2D)
	return nodes


func _find_interaction_by_id(interaction_id: String) -> Node2D:
	var normalized_id := interaction_id.strip_edges()
	if normalized_id.is_empty():
		return null
	for interaction_node in _get_objective_interactions():
		if interaction_node == null or not is_instance_valid(interaction_node):
			continue
		if String(interaction_node.get("interaction_id")).strip_edges() == normalized_id:
			return interaction_node
	return null


func _set_objective_interaction_focus(focused_id: String) -> void:
	if _objective_state.is_empty():
		return
	_objective_state["focused_interaction_id"] = focused_id
	for interaction_node in _get_objective_interactions():
		if interaction_node == null or not is_instance_valid(interaction_node):
			continue
		if interaction_node.has_method("set_focused"):
			interaction_node.call("set_focused", String(interaction_node.get("interaction_id")).strip_edges() == focused_id and not focused_id.is_empty())


func _is_interaction_enabled(interaction_node: Node2D) -> bool:
	if interaction_node == null or not is_instance_valid(interaction_node) or _objective_state.is_empty() or _is_resolved():
		return false
	var objective_id := String(_objective_state.get("objective_id", "")).strip_edges().to_lower()
	var prop_index := int(interaction_node.get_meta("objective_prop_index", -1))
	match objective_id:
		"payload_hack":
			return prop_index == maxi(0, int(_objective_state.get("progress_count", 0))) and not bool(_objective_state.get("interaction_started", false))
		"power_reroute":
			return prop_index == maxi(0, int(_objective_state.get("progress_count", 0)))
		"cursed_cache":
			return _cache_interaction_ready()
	return false


func _cache_interaction_ready() -> bool:
	if _objective_state.is_empty():
		return false
	return String(_objective_state.get("objective_id", "")).strip_edges().to_lower() == "cursed_cache" and _progress_reached_goal()


func _get_active_target_snapshot() -> Dictionary:
	if _objective_state.is_empty():
		return {}
	var objective_id := String(_objective_state.get("objective_id", "")).strip_edges().to_lower()
	var current_index := maxi(0, int(_objective_state.get("progress_count", 0)))
	match objective_id:
		"hold_zone", "escort", "payload_hack":
			var zone := _get_objective_zone_at(current_index)
			var prop := _get_objective_prop(current_index)
			if zone != null and is_instance_valid(zone):
				return {
					"index": current_index,
					"label": String(prop.get("display_name", prop.get("label", ""))).strip_edges(),
					"position": (zone as Node2D).global_position
				}
		"power_reroute":
			var reroute_interaction := _find_interaction_by_id("objective_%d" % current_index)
			var reroute_prop := _get_objective_prop(current_index)
			if reroute_interaction != null and is_instance_valid(reroute_interaction):
				return {
					"index": current_index,
					"label": String(reroute_prop.get("display_name", reroute_prop.get("label", ""))).strip_edges(),
					"position": reroute_interaction.global_position
				}
		"cursed_cache":
			var cache_prop := _get_cache_prop()
			var cache_interaction := _get_cache_interaction()
			if not cache_prop.is_empty() and cache_interaction != null and is_instance_valid(cache_interaction):
				return {
					"index": int(cache_interaction.get_meta("objective_prop_index", -1)),
					"label": String((cache_prop as Dictionary).get("display_name", (cache_prop as Dictionary).get("label", ""))).strip_edges(),
					"position": cache_interaction.global_position
				}
	return {}


func _get_objective_prop(index: int) -> Dictionary:
	var props_variant: Variant = _objective_state.get("objective_props", [])
	if not (props_variant is Array):
		return {}
	var props: Array = props_variant
	if index < 0 or index >= props.size():
		return {}
	var prop_variant: Variant = props[index]
	return (prop_variant as Dictionary).duplicate(true) if prop_variant is Dictionary else {}


func _get_cache_prop() -> Dictionary:
	var props_variant: Variant = _objective_state.get("objective_props", [])
	if not (props_variant is Array):
		return {}
	for prop_variant in props_variant:
		if not (prop_variant is Dictionary):
			continue
		var prop: Dictionary = prop_variant
		var prop_id := String(prop.get("prop_id", "")).strip_edges().to_lower()
		if prop_id.find("cache") >= 0:
			return prop.duplicate(true)
	return {}


func _get_cache_interaction() -> Node2D:
	for interaction_node in _get_objective_interactions():
		if interaction_node == null or not is_instance_valid(interaction_node):
			continue
		var prop_id := String(interaction_node.get_meta("objective_prop_id", "")).strip_edges().to_lower()
		if prop_id.find("cache") >= 0:
			return interaction_node
	return null


func _should_spawn_zone(objective_id: String, prop_id: String) -> bool:
	if objective_id == "hold_zone" or objective_id == "escort" or objective_id == "payload_hack":
		return true
	return prop_id.find("zone") >= 0 or prop_id.find("beacon") >= 0


func _should_spawn_node(objective_id: String, prop_id: String) -> bool:
	if objective_id == "destroy_nodes" or objective_id == "destroy_spawner":
		return true
	if objective_id == "cursed_cache":
		return prop_id.find("seal") >= 0
	return false


func _should_spawn_interaction(objective_id: String, prop_id: String) -> bool:
	if objective_id == "payload_hack" or objective_id == "power_reroute":
		return true
	if objective_id == "cursed_cache":
		return prop_id.find("cache") >= 0
	return false


func _interaction_kind_for_objective(objective_id: String, prop_id: String) -> String:
	match objective_id:
		"payload_hack":
			return "hack"
		"power_reroute":
			return "reroute"
		"cursed_cache":
			if prop_id.find("cache") >= 0:
				return "cache"
	return "generic"


func _interaction_prompt_for_objective(objective_id: String, label: String) -> String:
	match objective_id:
		"payload_hack":
			return _tr("night.objective.prompt.hack", {"value": label})
		"power_reroute":
			return _tr("night.objective.prompt.reroute", {"value": label})
		"cursed_cache":
			return _tr("night.objective.prompt.cache", {"value": label})
	return _tr("night.interaction.prompt.generic", {"value": label})


func _payload_hack_hold_sec() -> float:
	var runtime_flags: Dictionary = _objective_state.get("runtime_flags", {})
	return maxf(0.4, float(runtime_flags.get("hack_hold_sec", 1.6)))


func _escort_integrity_ratio() -> float:
	var integrity_max := maxf(1.0, float(_objective_state.get("escort_integrity_max", 100.0)))
	return float(_objective_state.get("escort_integrity", 0.0)) / integrity_max


func _progress_reached_goal() -> bool:
	return maxi(0, int(_objective_state.get("required_count", 0))) > 0 and maxi(0, int(_objective_state.get("progress_count", 0))) >= maxi(0, int(_objective_state.get("required_count", 0)))


func _can_fail_on_deadline(objective_id: String) -> bool:
	return objective_id == "escort" or objective_id == "payload_hack" or objective_id == "elite_hunt" or objective_id == "power_reroute" or objective_id == "cursed_cache"


func _is_resolved() -> bool:
	return bool(_objective_state.get("completed", false)) or bool(_objective_state.get("failed", false))


func _failure_note_for_reason(reason: String) -> String:
	match reason:
		"integrity":
			return _tr("night.objective.note.failed_integrity")
		_:
			return _tr("night.objective.note.failed_timer")


func _set_hold_open(hold_open: bool, context: Dictionary = {}) -> void:
	var enemy_manager_variant: Variant = context.get("enemy_manager", null)
	if not (enemy_manager_variant is Node) or not is_instance_valid(enemy_manager_variant):
		return
	var enemy_manager := enemy_manager_variant as Node
	if enemy_manager.has_method("set_scripted_encounter_hold_open"):
		enemy_manager.call("set_scripted_encounter_hold_open", hold_open)


func _sync_hold_open(context: Dictionary = {}) -> void:
	_set_hold_open(has_active_objective() or has_pending_waves(), context)


func _tr(key: String, args: Dictionary = {}) -> String:
	if Localization != null and Localization.has_method("t"):
		return String(Localization.call("t", key, args))
	return key


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
