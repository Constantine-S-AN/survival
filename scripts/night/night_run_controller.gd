extends Node
class_name NightRunController

signal session_completed(summary: Dictionary)

const GAME_ROOT_SCENE := preload("res://scenes/game/GameRoot.tscn")
const RoomGraphGeneratorClass := preload("res://scripts/night/room_graph_generator.gd")
const EncounterDirectorClass := preload("res://scripts/night/encounter_director.gd")
const RoomExitClass := preload("res://scripts/night/room_exit.gd")

const STATE_BOOTING := "booting"
const STATE_ENTERING_ROOM := "entering_room"
const STATE_ROOM_LOCKED := "room_locked"
const STATE_ROOM_CLEARED := "room_cleared"
const STATE_FLOOR_CLEARED := "floor_cleared"
const STATE_COMPLETED := "completed"
const STATE_ABORTED := "aborted"
const BOOT_MAX_ATTEMPTS := 12
const EXIT_ANCHOR_LAYOUTS := {
	1: ["East"],
	2: ["East", "West"],
	3: ["East", "North", "West"],
	4: ["East", "North", "West", "South"]
}
const ROOM_THEME := {
	"combat": {"floor": Color(0.08, 0.13, 0.18, 0.88), "outline": Color(0.31, 0.78, 0.90, 0.96)},
	"treasure": {"floor": Color(0.20, 0.14, 0.05, 0.88), "outline": Color(1.0, 0.84, 0.32, 0.96)},
	"rest": {"floor": Color(0.06, 0.16, 0.11, 0.88), "outline": Color(0.53, 0.95, 0.67, 0.96)},
	"event": {"floor": Color(0.18, 0.10, 0.07, 0.88), "outline": Color(1.0, 0.62, 0.38, 0.96)},
	"boss": {"floor": Color(0.21, 0.06, 0.10, 0.90), "outline": Color(1.0, 0.44, 0.54, 0.98)}
}

@onready var game_mount: Node = $GameMount
@onready var floor_label: Label = $Overlay/MarginContainer/PanelContainer/VBoxContainer/FloorLabel
@onready var room_label: Label = $Overlay/MarginContainer/PanelContainer/VBoxContainer/RoomLabel
@onready var status_label: Label = $Overlay/MarginContainer/PanelContainer/VBoxContainer/StatusLabel
@onready var minimap: Node = $Overlay/NightMinimap

var _room_graph_generator = RoomGraphGeneratorClass.new()
var _encounter_director = EncounterDirectorClass.new()
var _active_request: Dictionary = {}
var _game_root: Node = null
var _world: Node2D = null
var _enemy_manager: Node = null
var _floors: Array = []
var _current_floor_index: int = -1
var _current_room = null
var _active_room_node: Node2D = null
var _active_exit_nodes: Array = []
var _run_state: String = STATE_BOOTING
var _boot_attempts: int = 0
var _completion_emitted: bool = false
var _rooms_cleared_total: int = 0
var _visited_room_ids: Array[String] = []
var _last_room_note: String = ""


func start_session(request: Dictionary) -> void:
	_reset_runtime_state()
	_active_request = request.duplicate(true)
	_floors = _room_graph_generator.build_floors(int(_active_request.get("seed", 0)))
	if _floors.is_empty():
		_run_state = STATE_ABORTED
		_last_room_note = "No dungeon template available"
		_update_ui()
		push_error("NightRunController could not build a dungeon floor from the night data files.")
		return

	_game_root = GAME_ROOT_SCENE.instantiate()
	if _game_root == null:
		_run_state = STATE_ABORTED
		_last_room_note = "Combat world unavailable"
		_update_ui()
		push_error("NightRunController could not instantiate GameRoot.")
		return
	var embedded_request := _active_request.duplicate(true)
	embedded_request["session_duration_sec"] = 0.0
	if _game_root.has_method("set_embedded_session_request"):
		_game_root.call("set_embedded_session_request", embedded_request)
	if _game_root.has_signal("embedded_session_finished"):
		_game_root.connect("embedded_session_finished", Callable(self, "_on_embedded_session_finished"))
	game_mount.add_child(_game_root)
	_run_state = STATE_BOOTING
	_last_room_note = "Mapping the floor"
	_update_ui()
	call_deferred("_finish_bootstrap")


func stop_session() -> void:
	if _enemy_manager != null and is_instance_valid(_enemy_manager) and _enemy_manager.has_method("clear_scripted_encounter"):
		_enemy_manager.call("clear_scripted_encounter", true, false)
	_disconnect_enemy_manager()
	_cleanup_active_room()
	if _game_root != null and is_instance_valid(_game_root):
		_game_root.queue_free()
	_game_root = null
	_world = null
	_active_request.clear()


func debug_get_snapshot() -> Dictionary:
	var exits: Array[Dictionary] = []
	for exit_node in _active_exit_nodes:
		if exit_node == null or not is_instance_valid(exit_node):
			continue
		if exit_node.has_method("get_snapshot"):
			exits.append(exit_node.call("get_snapshot"))
	return {
		"state": _run_state,
		"floor_index": _current_floor_index + 1,
		"floor_count": _floors.size(),
		"floor_label": _resolve_floor_label(),
		"room_id": _current_room.room_id if _current_room != null else "",
		"room_label": _current_room.label if _current_room != null else "",
		"room_type_id": _current_room.room_type_id if _current_room != null else "",
		"room_type_label": _current_room.room_type_label if _current_room != null else "",
		"room_status": _current_room.status if _current_room != null else "",
		"room_cleared": _current_room.status == RoomState.STATUS_CLEARED if _current_room != null else false,
		"room_reward_claimed": bool(_current_room.reward_claimed) if _current_room != null else false,
		"room_goal": bool(_current_room.is_goal) if _current_room != null else false,
		"room_note": _last_room_note,
		"visited_room_ids": _visited_room_ids.duplicate(),
		"rooms_cleared_total": _rooms_cleared_total,
		"available_exits": exits,
		"floor_rooms": _build_floor_rooms_snapshot(),
		"minimap": _build_minimap_snapshot()
	}


func debug_force_clear_room() -> void:
	if _enemy_manager != null and is_instance_valid(_enemy_manager) and _enemy_manager.has_method("clear_scripted_encounter"):
		_enemy_manager.call("clear_scripted_encounter", true, true)
		return
	_mark_current_room_cleared()
	if _current_room != null and _current_room.is_goal and _current_room.connections.is_empty():
		_complete_or_advance_floor()


func debug_use_exit(target_room_id: String) -> void:
	_on_exit_selected("", target_room_id)


func _finish_bootstrap() -> void:
	if _completion_emitted or _game_root == null or not is_instance_valid(_game_root):
		return
	_boot_attempts += 1
	if _world == null:
		_world = _game_root.get_node_or_null("World")
	if _enemy_manager == null and _world != null:
		_enemy_manager = _world.get_node_or_null("EnemyManager")
	var run_state_variant: Variant = _game_root.get("run_state")
	var run_state := String(run_state_variant).strip_edges().to_lower()
	if (_world == null or _enemy_manager == null or run_state != "playing") and _boot_attempts < BOOT_MAX_ATTEMPTS:
		call_deferred("_finish_bootstrap")
		return
	if _world == null or _enemy_manager == null:
		_run_state = STATE_ABORTED
		_last_room_note = "Failed to boot combat core"
		_update_ui()
		push_error("NightRunController could not reach the embedded combat world.")
		return
	if _enemy_manager.has_signal("scripted_encounter_cleared"):
		var cleared_callable := Callable(self, "_on_scripted_encounter_cleared")
		if not _enemy_manager.is_connected("scripted_encounter_cleared", cleared_callable):
			_enemy_manager.connect("scripted_encounter_cleared", cleared_callable)
	if _enemy_manager.has_method("set_ambient_spawning_enabled"):
		_enemy_manager.call("set_ambient_spawning_enabled", false)
	_current_floor_index = 0
	var floor_state = _get_current_floor()
	if floor_state == null:
		_complete_run()
		return
	_enter_room(floor_state.get_room(floor_state.start_room_id))


func _enter_room(room_state: RoomState) -> void:
	if room_state == null or _completion_emitted:
		return
	_run_state = STATE_ENTERING_ROOM
	_cleanup_active_room()
	if _enemy_manager != null and is_instance_valid(_enemy_manager) and _enemy_manager.has_method("clear_scripted_encounter"):
		_enemy_manager.call("clear_scripted_encounter", true, false)
	_current_room = room_state
	_current_room.set_active()
	_record_room_visit(room_state.room_id)

	var room_scene: PackedScene = load(room_state.scene_path)
	if room_scene == null:
		_run_state = STATE_ABORTED
		_last_room_note = "Missing room scene"
		_update_ui()
		push_error("NightRunController could not load room scene: %s" % room_state.scene_path)
		return
	var room_variant: Variant = room_scene.instantiate()
	if not (room_variant is Node2D):
		_run_state = STATE_ABORTED
		_last_room_note = "Invalid room scene"
		_update_ui()
		push_error("NightRunController expected a Node2D room scene: %s" % room_state.scene_path)
		return
	_active_room_node = room_variant
	_active_room_node.name = "ActiveRoom_%s" % room_state.room_id
	_world.add_child(_active_room_node)
	_apply_room_visual_theme(room_state)
	_spawn_exit_nodes(room_state)
	_teleport_player_to_active_room()
	_last_room_note = "%s room" % room_state.room_type_label

	if room_state.is_combat_room() and room_state.status != RoomState.STATUS_CLEARED:
		_lock_active_exits(true)
		_run_state = STATE_ROOM_LOCKED
		var room_payload := _encounter_director.build_room_payload(_get_current_floor(), room_state, _active_room_node)
		var enemy_specs: Array = room_payload.get("enemies", [])
		var spawned_total := 0
		if _enemy_manager != null and is_instance_valid(_enemy_manager) and _enemy_manager.has_method("start_scripted_encounter"):
			spawned_total = int(_enemy_manager.call("start_scripted_encounter", room_state.room_id, enemy_specs))
		if spawned_total <= 0:
			_mark_current_room_cleared()
			if room_state.is_goal and room_state.connections.is_empty():
				_complete_or_advance_floor()
	else:
		if room_state.reward_on_enter and not room_state.reward_claimed:
			_claim_room_reward(room_state)
		_mark_current_room_cleared()
		if room_state.is_goal and room_state.connections.is_empty():
			_complete_or_advance_floor()
	_update_ui()


func _apply_room_visual_theme(room_state: RoomState) -> void:
	if _active_room_node == null:
		return
	var theme: Dictionary = ROOM_THEME.get(room_state.room_type_id, ROOM_THEME[RoomState.TYPE_COMBAT])
	var floor_node := _active_room_node.get_node_or_null("Floor")
	if floor_node is Polygon2D:
		(floor_node as Polygon2D).color = theme["floor"]
	var outline_node := _active_room_node.get_node_or_null("Outline")
	if outline_node is Line2D:
		(outline_node as Line2D).default_color = theme["outline"]


func _spawn_exit_nodes(room_state: RoomState) -> void:
	_active_exit_nodes.clear()
	if _active_room_node == null:
		return
	var floor_state = _get_current_floor()
	if floor_state == null:
		return
	var connections: Array[String] = room_state.connections.duplicate()
	if connections.is_empty():
		return
	var anchor_root := _active_room_node.get_node_or_null("ExitAnchors")
	var anchor_names: Array = EXIT_ANCHOR_LAYOUTS.get(mini(connections.size(), 4), EXIT_ANCHOR_LAYOUTS[4])
	for index in range(connections.size()):
		var target_room_id := connections[index]
		var anchor_name := String(anchor_names[min(index, anchor_names.size() - 1)])
		var anchor := _find_named_child(anchor_root, anchor_name)
		var exit_node := RoomExitClass.new()
		var target_room: RoomState = floor_state.get_room(target_room_id)
		exit_node.position = (anchor as Node2D).position if anchor is Node2D else Vector2.ZERO
		exit_node.configure(
			"%s_exit_%d" % [room_state.room_id, index],
			target_room_id,
			target_room.label if target_room != null else target_room_id,
			target_room.room_type_id if target_room != null else "",
			target_room.status if target_room != null else RoomState.STATUS_UNEXPLORED,
			room_state.locks_on_entry and room_state.status != RoomState.STATUS_CLEARED,
			target_room.exit_color if target_room != null else Color(0.44, 0.76, 0.92, 1.0)
		)
		exit_node.exit_selected.connect(_on_exit_selected)
		_active_room_node.add_child(exit_node)
		_active_exit_nodes.append(exit_node)


func _lock_active_exits(locked: bool) -> void:
	for exit_node in _active_exit_nodes:
		if exit_node == null or not is_instance_valid(exit_node):
			continue
		if exit_node.has_method("set_locked"):
			exit_node.call("set_locked", locked)


func _teleport_player_to_active_room() -> void:
	if _world == null or _active_room_node == null:
		return
	var player := _get_player()
	var spawn_node := _active_room_node.get_node_or_null("PlayerSpawn")
	if not (player is Node2D) or not (spawn_node is Node2D):
		return
	(player as Node2D).global_position = (spawn_node as Node2D).global_position
	if player is CharacterBody2D:
		(player as CharacterBody2D).velocity = Vector2.ZERO


func _record_room_visit(room_id: String) -> void:
	var normalized := room_id.strip_edges()
	if normalized.is_empty():
		return
	if _visited_room_ids.has(normalized):
		return
	_visited_room_ids.append(normalized)


func _mark_current_room_cleared() -> void:
	if _current_room == null:
		return
	var first_clear: bool = _current_room.status != RoomState.STATUS_CLEARED
	_current_room.set_cleared()
	if first_clear:
		_rooms_cleared_total += 1
	_lock_active_exits(false)
	_run_state = STATE_ROOM_CLEARED
	_update_ui()


func _claim_room_reward(room_state: RoomState) -> void:
	if room_state == null or room_state.reward_claimed:
		return
	var reward: Dictionary = room_state.reward_data.duplicate(true)
	var reward_kind := String(reward.get("kind", room_state.room_type_id)).strip_edges().to_lower()
	match reward_kind:
		RoomState.TYPE_TREASURE:
			_claim_treasure_reward(reward)
			_last_room_note = "Treasure claimed"
		RoomState.TYPE_REST:
			_claim_rest_reward(reward)
			_last_room_note = "Rested and resupplied"
		RoomState.TYPE_EVENT:
			_claim_event_reward(reward)
			_last_room_note = "Event resolved"
		_:
			_last_room_note = "Room reward claimed"
	room_state.mark_reward_claimed()


func _claim_treasure_reward(reward: Dictionary) -> void:
	if _world == null or not is_instance_valid(_world):
		return
	var pickup_count := clampi(int(reward.get("xp_pickups", 5)), 1, 12)
	var xp_amount := clampi(int(reward.get("xp_amount", 18)), 1, 80)
	var origin := _room_anchor_position()
	for index in range(pickup_count):
		var angle := TAU * float(index) / maxf(1.0, float(pickup_count))
		var radius := 28.0 + float(index % 3) * 18.0
		var spawn_pos := origin + Vector2.RIGHT.rotated(angle) * radius
		_world.call_deferred("spawn_xp_pickup", spawn_pos, xp_amount)


func _claim_rest_reward(reward: Dictionary) -> void:
	var player := _get_player()
	if player == null or not is_instance_valid(player):
		return
	var heal_pct := clampf(float(reward.get("heal_pct", 0.30)), 0.0, 1.0)
	var max_hp := float(player.get("max_hp"))
	var current_hp := float(player.get("hp"))
	player.set("hp", minf(max_hp, current_hp + max_hp * heal_pct))
	if player.has_method("emit_stats_changed"):
		player.call("emit_stats_changed")
	var noise_delta := float(reward.get("noise_delta", -12.0))
	if player.has_method("add_noise_delta"):
		player.call("add_noise_delta", noise_delta)


func _claim_event_reward(reward: Dictionary) -> void:
	var player := _get_player()
	if player == null or not is_instance_valid(player):
		return
	var xp_bonus := clampi(int(reward.get("xp_bonus", 36)), 0, 200)
	if xp_bonus > 0 and player.has_method("gain_xp"):
		player.call("gain_xp", xp_bonus)
	var noise_delta := float(reward.get("noise_delta", -6.0))
	if player.has_method("add_noise_delta"):
		player.call("add_noise_delta", noise_delta)
	var skill_cd := float(player.get("skill_cd_remaining"))
	player.set("skill_cd_remaining", maxf(0.0, skill_cd - float(reward.get("skill_cd_refund", 1.2))))


func _room_anchor_position() -> Vector2:
	if _active_room_node == null:
		return Vector2.ZERO
	var anchor := _active_room_node.get_node_or_null("EncounterAnchor")
	if anchor is Node2D:
		return (anchor as Node2D).global_position
	return _active_room_node.global_position


func _complete_or_advance_floor() -> void:
	var floor_state = _get_current_floor()
	if floor_state == null:
		_complete_run()
		return
	if _current_room == null or _current_room.room_id != floor_state.goal_room_id:
		return
	_run_state = STATE_FLOOR_CLEARED
	_last_room_note = "Floor secured"
	_update_ui()
	if _current_floor_index + 1 < _floors.size():
		_current_floor_index += 1
		var next_floor = _get_current_floor()
		if next_floor != null:
			_enter_room(next_floor.get_room(next_floor.start_room_id))
			return
	_complete_run()


func _complete_run() -> void:
	if _completion_emitted or _game_root == null or not is_instance_valid(_game_root):
		return
	_run_state = STATE_COMPLETED
	_last_room_note = "Extraction secured"
	_update_ui()
	if _enemy_manager != null and is_instance_valid(_enemy_manager) and _enemy_manager.has_method("clear_scripted_encounter"):
		_enemy_manager.call("clear_scripted_encounter", true, false)
	if _game_root.has_method("_complete_embedded_session"):
		_game_root.call("_complete_embedded_session")


func _on_scripted_encounter_cleared(encounter_id: String) -> void:
	if _current_room == null:
		return
	if encounter_id.strip_edges() != _current_room.room_id:
		return
	_mark_current_room_cleared()
	if _current_room.reward_on_enter and not _current_room.reward_claimed:
		_claim_room_reward(_current_room)
	if _current_room.is_goal and _current_room.connections.is_empty():
		_complete_or_advance_floor()
	else:
		_last_room_note = "Room clear: choose a door"
		_update_ui()


func _on_exit_selected(_exit_id: String, target_room_id: String) -> void:
	if _completion_emitted or _current_room == null:
		return
	if _current_room.locks_on_entry and _current_room.status != RoomState.STATUS_CLEARED:
		return
	var floor_state = _get_current_floor()
	if floor_state == null:
		return
	var normalized_target := target_room_id.strip_edges()
	if normalized_target.is_empty():
		if _current_room.is_goal:
			_complete_or_advance_floor()
		return
	if not floor_state.has_room(normalized_target):
		return
	_lock_active_exits(true)
	_enter_room(floor_state.get_room(normalized_target))


func _on_embedded_session_finished(summary: Dictionary) -> void:
	if _completion_emitted:
		return
	_completion_emitted = true
	var payload := summary.duplicate(true)
	payload["dungeon_floor_index"] = _current_floor_index + 1
	payload["dungeon_floor_count"] = _floors.size()
	payload["dungeon_rooms_cleared"] = _rooms_cleared_total
	payload["dungeon_room_path"] = _visited_room_ids.duplicate()
	payload["dungeon_last_room_id"] = _current_room.room_id if _current_room != null else ""
	payload["dungeon_last_room_label"] = _current_room.label if _current_room != null else ""
	payload["dungeon_last_room_type_id"] = _current_room.room_type_id if _current_room != null else ""
	payload["dungeon_completed"] = String(payload.get("exit_reason", "completed")).strip_edges().to_lower() == "completed"
	session_completed.emit(payload)


func _cleanup_active_room() -> void:
	_active_exit_nodes.clear()
	if _active_room_node != null and is_instance_valid(_active_room_node):
		_active_room_node.queue_free()
	_active_room_node = null


func _disconnect_enemy_manager() -> void:
	if _enemy_manager == null or not is_instance_valid(_enemy_manager):
		_enemy_manager = null
		return
	if _enemy_manager.has_signal("scripted_encounter_cleared"):
		var cleared_callable := Callable(self, "_on_scripted_encounter_cleared")
		if _enemy_manager.is_connected("scripted_encounter_cleared", cleared_callable):
			_enemy_manager.disconnect("scripted_encounter_cleared", cleared_callable)
	_enemy_manager = null


func _reset_runtime_state() -> void:
	stop_session()
	_current_floor_index = -1
	_current_room = null
	_floors.clear()
	_active_exit_nodes.clear()
	_run_state = STATE_BOOTING
	_boot_attempts = 0
	_completion_emitted = false
	_rooms_cleared_total = 0
	_visited_room_ids.clear()
	_last_room_note = ""
	_update_ui()


func _get_current_floor():
	if _current_floor_index < 0 or _current_floor_index >= _floors.size():
		return null
	return _floors[_current_floor_index]


func _get_player() -> Node:
	if _world == null:
		return null
	return _world.get_node_or_null("Player")


func _find_named_child(parent: Node, target_name: String) -> Node:
	if parent == null:
		return null
	var normalized_target := target_name.strip_edges().to_lower()
	for child in parent.get_children():
		if child == null:
			continue
		if String(child.name).strip_edges().to_lower() == normalized_target:
			return child
	return null


func _build_floor_rooms_snapshot() -> Array[Dictionary]:
	var floor_state = _get_current_floor()
	if floor_state == null:
		return []
	var snapshots: Array[Dictionary] = []
	for room_id in floor_state.room_order:
		var room: RoomState = floor_state.get_room(room_id)
		if room == null:
			continue
		snapshots.append(room.to_dictionary())
	return snapshots


func _build_minimap_snapshot() -> Dictionary:
	var floor_state = _get_current_floor()
	return {
		"floor_label": _resolve_floor_label(),
		"current_room_id": _current_room.room_id if _current_room != null else "",
		"current_room_label": _current_room.label if _current_room != null else "",
		"current_room_type_label": _current_room.room_type_label if _current_room != null else "",
		"rooms": _build_floor_rooms_snapshot(),
		"template_id": floor_state.template_id if floor_state != null else ""
	}


func _resolve_floor_label() -> String:
	var floor_state = _get_current_floor()
	if floor_state == null:
		return "Night Run"
	return floor_state.label


func _resolve_status_text() -> String:
	if not _last_room_note.is_empty():
		return _last_room_note
	match _run_state:
		STATE_BOOTING:
			return "Initializing night run"
		STATE_ENTERING_ROOM:
			return "Crossing into the next chamber"
		STATE_ROOM_LOCKED:
			return "Doors sealed until the room is cleared"
		STATE_ROOM_CLEARED:
			return "Room clear: choose the next room"
		STATE_FLOOR_CLEARED:
			return "Extraction path secured"
		STATE_COMPLETED:
			return "Night run complete"
		STATE_ABORTED:
			return "Night run unavailable"
	return ""


func _update_ui() -> void:
	if floor_label != null:
		floor_label.text = _resolve_floor_label()
	if room_label != null:
		if _current_room == null:
			room_label.text = "Staging Chamber"
		else:
			room_label.text = "%s · %s" % [_current_room.label, _current_room.room_type_label]
	if status_label != null:
		status_label.text = _resolve_status_text()
	if minimap != null and is_instance_valid(minimap) and minimap.has_method("set_map_snapshot"):
		minimap.call("set_map_snapshot", _build_minimap_snapshot())
