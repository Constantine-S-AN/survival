extends Node
class_name NightRunController

signal session_completed(summary: Dictionary)

const GAME_ROOT_SCENE := preload("res://scenes/game/GameRoot.tscn")
const RoomGraphGeneratorClass := preload("res://scripts/night/room_graph_generator.gd")
const EncounterDirectorClass := preload("res://scripts/night/encounter_director.gd")
const RoomExitClass := preload("res://scripts/night/room_exit.gd")
const RunModifierStateClass := preload("res://scripts/night/run_modifier_state.gd")
const RoomRewardPickerClass := preload("res://scripts/night/room_reward_picker.gd")
const BossRoomControllerClass := preload("res://scripts/night/boss_room_controller.gd")
const ExtractionControllerClass := preload("res://scripts/night/extraction_controller.gd")

const STATE_BOOTING := "booting"
const STATE_ENTERING_ROOM := "entering_room"
const STATE_ROOM_LOCKED := "room_locked"
const STATE_REWARD_PENDING := "reward_pending"
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
@onready var reward_panel: PanelContainer = $Overlay/RewardPanel
@onready var reward_title_label: Label = $Overlay/RewardPanel/MarginContainer/VBoxContainer/RewardTitle
@onready var reward_subtitle_label: Label = $Overlay/RewardPanel/MarginContainer/VBoxContainer/RewardSubtitle
@onready var reward_hint_label: Label = $Overlay/RewardPanel/MarginContainer/VBoxContainer/RewardHint
@onready var reward_button_one: Button = $Overlay/RewardPanel/MarginContainer/VBoxContainer/RewardButtons/RewardButton1
@onready var reward_button_two: Button = $Overlay/RewardPanel/MarginContainer/VBoxContainer/RewardButtons/RewardButton2
@onready var reward_button_three: Button = $Overlay/RewardPanel/MarginContainer/VBoxContainer/RewardButtons/RewardButton3
@onready var boss_panel: PanelContainer = $Overlay/BossClimaxPanel
@onready var boss_title_label: Label = $Overlay/BossClimaxPanel/MarginContainer/VBoxContainer/BossTitle
@onready var boss_phase_label: Label = $Overlay/BossClimaxPanel/MarginContainer/VBoxContainer/BossPhase
@onready var boss_status_label: Label = $Overlay/BossClimaxPanel/MarginContainer/VBoxContainer/BossStatus
@onready var extraction_panel: PanelContainer = $Overlay/ExtractionPanel
@onready var extraction_title_label: Label = $Overlay/ExtractionPanel/MarginContainer/VBoxContainer/ExtractionTitle
@onready var extraction_status_label: Label = $Overlay/ExtractionPanel/MarginContainer/VBoxContainer/ExtractionStatus
@onready var extract_button: Button = $Overlay/ExtractionPanel/MarginContainer/VBoxContainer/ExtractButton

var _room_graph_generator = RoomGraphGeneratorClass.new()
var _encounter_director = EncounterDirectorClass.new()
var _run_modifier_state = RunModifierStateClass.new()
var _room_reward_picker = RoomRewardPickerClass.new()
var _boss_room_controller = BossRoomControllerClass.new()
var _extraction_controller = ExtractionControllerClass.new()
var _reward_buttons: Array[Button] = []
var _active_request: Dictionary = {}
var _game_root: Node = null
var _world: Node2D = null
var _enemy_manager: Node = null
var _floors: Array = []
var _current_floor_index: int = -1
var _current_room = null
var _current_room_payload: Dictionary = {}
var _active_room_node: Node2D = null
var _active_exit_nodes: Array = []
var _pending_room_rewards: Array[Dictionary] = []
var _run_state: String = STATE_BOOTING
var _boot_attempts: int = 0
var _completion_emitted: bool = false
var _rooms_cleared_total: int = 0
var _visited_room_ids: Array[String] = []
var _last_room_note: String = ""
var _boss_climax_snapshot: Dictionary = {}
var _extraction_snapshot: Dictionary = {}


func _ready() -> void:
	_reward_buttons = [
		reward_button_one,
		reward_button_two,
		reward_button_three
	]
	for button_index in range(_reward_buttons.size()):
		var button := _reward_buttons[button_index]
		if button == null:
			continue
		var pressed_callable := Callable(self, "_on_reward_button_pressed").bind(button_index)
		if not button.pressed.is_connected(pressed_callable):
			button.pressed.connect(pressed_callable)
	if extract_button != null and not extract_button.pressed.is_connected(_on_extract_button_pressed):
		extract_button.pressed.connect(_on_extract_button_pressed)
	_hide_reward_panel()
	_boss_room_controller.reset()
	_extraction_controller.reset()
	_boss_climax_snapshot = _boss_room_controller.get_snapshot()
	_refresh_boss_panel()
	_refresh_extraction_panel()


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
	_clear_pending_room_rewards()
	_boss_room_controller.reset()
	_extraction_controller.reset()
	_boss_climax_snapshot = _boss_room_controller.get_snapshot()
	if _game_root != null and is_instance_valid(_game_root):
		_game_root.queue_free()
	_game_root = null
	_world = null
	_active_request.clear()
	_refresh_boss_panel()
	_refresh_extraction_panel()


func debug_get_snapshot() -> Dictionary:
	var exits: Array[Dictionary] = []
	for exit_node in _active_exit_nodes:
		if exit_node == null or not is_instance_valid(exit_node):
			continue
		if exit_node.has_method("get_snapshot"):
			exits.append(exit_node.call("get_snapshot"))
	var modifier_snapshot := _run_modifier_state.get_snapshot()
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
		"room_content": _get_active_room_content_snapshot(),
		"encounter_id": String(_current_room_payload.get("encounter_id", "")),
		"encounter_label": String(_current_room_payload.get("encounter_label", "")),
		"encounter_category": String(_current_room_payload.get("encounter_category", "")),
		"encounter_category_label": String(_current_room_payload.get("encounter_category_label", "")),
		"spawn_set_id": String(_current_room_payload.get("spawn_set_id", "")),
		"reward_panel_visible": reward_panel != null and reward_panel.visible,
		"reward_choices": _pending_room_rewards.duplicate(true),
		"run_modifier_state": modifier_snapshot,
		"visited_room_ids": _visited_room_ids.duplicate(),
		"rooms_cleared_total": _rooms_cleared_total,
		"available_exits": exits,
		"floor_rooms": _build_floor_rooms_snapshot(),
		"boss_climax": _boss_climax_snapshot.duplicate(true),
		"extraction": _extraction_snapshot.duplicate(true),
		"dungeon_carryover_preview": _extraction_controller.get_snapshot(),
		"player_hud": _get_player_hud_snapshot(),
		"minimap": _build_minimap_snapshot()
	}


func debug_force_clear_room() -> void:
	if _has_pending_room_rewards():
		return
	if _enemy_manager != null and is_instance_valid(_enemy_manager) and _enemy_manager.has_method("clear_scripted_encounter"):
		_enemy_manager.call("clear_scripted_encounter", true, true)
		return
	_mark_current_room_cleared()
	if _current_room != null and _current_room.is_goal and _current_room.connections.is_empty():
		_complete_or_advance_floor()


func debug_use_exit(target_room_id: String) -> void:
	_on_exit_selected("", target_room_id)


func debug_select_room_reward(option_index: int) -> bool:
	return _claim_pending_room_reward(option_index)


func debug_request_extract() -> bool:
	return _try_extract_early()


func _finish_bootstrap() -> void:
	if _completion_emitted or _game_root == null or not is_instance_valid(_game_root):
		return
	_boot_attempts += 1
	if _world == null:
		_world = _game_root.get_node_or_null("World")
	if _enemy_manager == null and _world != null:
		_enemy_manager = _world.get_node_or_null("EnemyManager")
	var runtime_state_variant: Variant = _game_root.get("run_state")
	var runtime_state := String(runtime_state_variant).strip_edges().to_lower()
	if (_world == null or _enemy_manager == null or runtime_state != "playing") and _boot_attempts < BOOT_MAX_ATTEMPTS:
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
	if _enemy_manager.has_signal("boss_spawned"):
		var boss_spawned_callable := Callable(self, "_on_boss_spawned")
		if not _enemy_manager.is_connected("boss_spawned", boss_spawned_callable):
			_enemy_manager.connect("boss_spawned", boss_spawned_callable)
	if _enemy_manager.has_signal("boss_phase_changed"):
		var boss_phase_callable := Callable(self, "_on_boss_phase_changed")
		if not _enemy_manager.is_connected("boss_phase_changed", boss_phase_callable):
			_enemy_manager.connect("boss_phase_changed", boss_phase_callable)
	if _enemy_manager.has_signal("boss_defeated"):
		var boss_defeated_callable := Callable(self, "_on_boss_defeated")
		if not _enemy_manager.is_connected("boss_defeated", boss_defeated_callable):
			_enemy_manager.connect("boss_defeated", boss_defeated_callable)
	if _enemy_manager.has_method("set_ambient_spawning_enabled"):
		_enemy_manager.call("set_ambient_spawning_enabled", false)
	_run_modifier_state.reset(_extract_base_reward_multipliers())
	_extraction_controller.reset()
	_boss_room_controller.reset()
	_boss_climax_snapshot = _boss_room_controller.get_snapshot()
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
	_clear_pending_room_rewards()
	_cleanup_active_room()
	if _enemy_manager != null and is_instance_valid(_enemy_manager) and _enemy_manager.has_method("clear_scripted_encounter"):
		_enemy_manager.call("clear_scripted_encounter", true, false)
	_current_room = room_state
	_current_room_payload = _encounter_director.describe_room(_get_current_floor(), room_state)
	_current_room.set_active()
	_record_room_visit(room_state.room_id)
	_boss_climax_snapshot = _boss_room_controller.begin_room(room_state, _current_room_payload)

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
	_last_room_note = "%s room" % _resolve_current_room_focus_label()

	if room_state.is_combat_room() and room_state.status != RoomState.STATUS_CLEARED:
		_lock_active_exits(true)
		_run_state = STATE_ROOM_LOCKED
		_current_room_payload = _encounter_director.build_room_payload(_get_current_floor(), room_state, _active_room_node)
		var enemy_specs: Array = _current_room_payload.get("enemies", [])
		var spawned_total := 0
		if _enemy_manager != null and is_instance_valid(_enemy_manager) and _enemy_manager.has_method("start_scripted_encounter"):
			spawned_total = int(_enemy_manager.call("start_scripted_encounter", room_state.room_id, enemy_specs))
		if spawned_total <= 0:
			_mark_current_room_cleared()
			if not _present_room_clear_rewards():
				if room_state.is_goal and room_state.connections.is_empty():
					_complete_or_advance_floor()
				else:
					_last_room_note = "Room clear: choose a door"
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
		if _current_room.is_combat_room() and String(_current_room_payload.get("encounter_category", "")).strip_edges().to_lower() != "boss":
			_extraction_controller.record_combat_room_clear(_current_room_payload)
		elif _current_room.is_combat_room():
			var boss_bonus_payload := _boss_room_controller.finalize_boss_room()
			if not boss_bonus_payload.is_empty():
				_extraction_controller.record_boss_bonus(boss_bonus_payload)
	_lock_active_exits(false)
	_run_state = STATE_ROOM_CLEARED
	_update_ui()


func _present_room_clear_rewards() -> bool:
	if _current_room == null or _current_room.reward_claimed or not _current_room.is_combat_room():
		return false
	_pending_room_rewards = _room_reward_picker.build_room_rewards(
		int(_active_request.get("seed", 0)),
		_current_room,
		_current_room_payload,
		_rooms_cleared_total,
		_run_modifier_state
	)
	if _pending_room_rewards.is_empty():
		return false
	_run_state = STATE_REWARD_PENDING
	_last_room_note = "Room clear: choose one reward"
	_refresh_reward_panel()
	return true


func _claim_pending_room_reward(option_index: int) -> bool:
	if _current_room == null or _pending_room_rewards.is_empty():
		return false
	if option_index < 0 or option_index >= _pending_room_rewards.size():
		return false
	var offer: Dictionary = _pending_room_rewards[option_index].duplicate(true)
	var applied := _run_modifier_state.apply_offer(offer, _build_reward_context())
	if applied.is_empty():
		return false
	_current_room.mark_reward_claimed()
	_clear_pending_room_rewards()
	_last_room_note = "Reward claimed: %s" % String(applied.get("label", "Choice"))
	_update_ui()
	if _current_room.is_goal and _current_room.connections.is_empty():
		_complete_or_advance_floor()
	return true


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


func _build_reward_context() -> Dictionary:
	return {
		"room_id": _current_room.room_id if _current_room != null else "",
		"player": _get_player(),
		"world": _world,
		"enemy_manager": _enemy_manager,
		"game_root": _game_root,
		"origin": _room_anchor_position()
	}


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
	_complete_run_with_reason("completed")


func _complete_run_with_reason(exit_reason: String) -> void:
	if _completion_emitted or _game_root == null or not is_instance_valid(_game_root):
		return
	_run_state = STATE_COMPLETED
	var normalized_exit_reason := exit_reason.strip_edges().to_lower()
	match normalized_exit_reason:
		"extracted":
			_last_room_note = "Early extraction secured"
		"completed":
			_last_room_note = "Boss floor secured"
		_:
			_last_room_note = "Night run complete"
	_update_ui()
	if _enemy_manager != null and is_instance_valid(_enemy_manager) and _enemy_manager.has_method("clear_scripted_encounter"):
		_enemy_manager.call("clear_scripted_encounter", true, false)
	if _game_root.has_method("_complete_embedded_session"):
		_game_root.call("_complete_embedded_session", normalized_exit_reason)


func _on_scripted_encounter_cleared(encounter_id: String) -> void:
	if _current_room == null:
		return
	if encounter_id.strip_edges() != _current_room.room_id:
		return
	_mark_current_room_cleared()
	if _current_room.reward_on_enter and not _current_room.reward_claimed:
		_claim_room_reward(_current_room)
	if _present_room_clear_rewards():
		_update_ui()
		return
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
	if _has_pending_room_rewards():
		_last_room_note = "Claim a room reward before moving on"
		_update_ui()
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


func _on_reward_button_pressed(button_index: int) -> void:
	_claim_pending_room_reward(button_index)


func _on_embedded_session_finished(summary: Dictionary) -> void:
	if _completion_emitted:
		return
	_completion_emitted = true
	var payload := summary.duplicate(true)
	var modifier_snapshot := _run_modifier_state.get_snapshot()
	payload["dungeon_floor_index"] = _current_floor_index + 1
	payload["dungeon_floor_count"] = _floors.size()
	payload["dungeon_rooms_cleared"] = _rooms_cleared_total
	payload["dungeon_room_path"] = _visited_room_ids.duplicate()
	payload["dungeon_last_room_id"] = _current_room.room_id if _current_room != null else ""
	payload["dungeon_last_room_label"] = _current_room.label if _current_room != null else ""
	payload["dungeon_last_room_type_id"] = _current_room.room_type_id if _current_room != null else ""
	payload["dungeon_last_encounter_id"] = String(_current_room_payload.get("encounter_id", ""))
	payload["dungeon_last_encounter_category"] = String(_current_room_payload.get("encounter_category", ""))
	payload["dungeon_run_rewards"] = modifier_snapshot.get("claimed_rewards", [])
	payload["dungeon_run_modifiers"] = modifier_snapshot.get("applied_modifiers", [])
	payload["dungeon_reward_multipliers"] = modifier_snapshot.get("reward_multipliers", {})
	var exit_reason := String(payload.get("exit_reason", "completed")).strip_edges().to_lower()
	var outcome_payload := _extraction_controller.build_outcome_payload(exit_reason, {
		"room_id": _current_room.room_id if _current_room != null else "",
		"room_label": _current_room.label if _current_room != null else ""
	})
	for key_variant in outcome_payload.keys():
		payload[String(key_variant)] = outcome_payload[key_variant]
	payload["dungeon_completed"] = exit_reason == "completed"
	session_completed.emit(payload)


func _cleanup_active_room() -> void:
	_active_exit_nodes.clear()
	if _active_room_node != null and is_instance_valid(_active_room_node):
		_active_room_node.queue_free()
	_active_room_node = null
	_current_room_payload.clear()


func _disconnect_enemy_manager() -> void:
	if _enemy_manager == null or not is_instance_valid(_enemy_manager):
		_enemy_manager = null
		return
	if _enemy_manager.has_signal("scripted_encounter_cleared"):
		var cleared_callable := Callable(self, "_on_scripted_encounter_cleared")
		if _enemy_manager.is_connected("scripted_encounter_cleared", cleared_callable):
			_enemy_manager.disconnect("scripted_encounter_cleared", cleared_callable)
	if _enemy_manager.has_signal("boss_spawned"):
		var boss_spawned_callable := Callable(self, "_on_boss_spawned")
		if _enemy_manager.is_connected("boss_spawned", boss_spawned_callable):
			_enemy_manager.disconnect("boss_spawned", boss_spawned_callable)
	if _enemy_manager.has_signal("boss_phase_changed"):
		var boss_phase_callable := Callable(self, "_on_boss_phase_changed")
		if _enemy_manager.is_connected("boss_phase_changed", boss_phase_callable):
			_enemy_manager.disconnect("boss_phase_changed", boss_phase_callable)
	if _enemy_manager.has_signal("boss_defeated"):
		var boss_defeated_callable := Callable(self, "_on_boss_defeated")
		if _enemy_manager.is_connected("boss_defeated", boss_defeated_callable):
			_enemy_manager.disconnect("boss_defeated", boss_defeated_callable)
	_enemy_manager = null


func _reset_runtime_state() -> void:
	stop_session()
	_current_floor_index = -1
	_current_room = null
	_current_room_payload.clear()
	_floors.clear()
	_active_exit_nodes.clear()
	_pending_room_rewards.clear()
	_run_modifier_state.reset({})
	_run_state = STATE_BOOTING
	_boot_attempts = 0
	_completion_emitted = false
	_rooms_cleared_total = 0
	_visited_room_ids.clear()
	_last_room_note = ""
	_boss_climax_snapshot = _boss_room_controller.get_snapshot()
	_extraction_snapshot.clear()
	_update_ui()


func _get_current_floor():
	if _current_floor_index < 0 or _current_floor_index >= _floors.size():
		return null
	return _floors[_current_floor_index]


func _get_player() -> Node:
	if _world == null:
		return null
	return _world.get_node_or_null("Player")


func _get_player_hud_snapshot() -> Dictionary:
	var player := _get_player()
	if player == null or not is_instance_valid(player) or not player.has_method("get_hud_data"):
		return {}
	var snapshot_variant: Variant = player.call("get_hud_data")
	return snapshot_variant if snapshot_variant is Dictionary else {}


func _get_active_room_content_snapshot() -> Dictionary:
	if _active_room_node == null or not is_instance_valid(_active_room_node):
		return {}
	if _active_room_node.has_method("get_room_content_snapshot"):
		var snapshot_variant: Variant = _active_room_node.call("get_room_content_snapshot")
		return snapshot_variant if snapshot_variant is Dictionary else {}
	return {}


func _extract_base_reward_multipliers() -> Dictionary:
	if _game_root != null and is_instance_valid(_game_root) and _game_root.has_method("get_runtime_reward_multipliers"):
		var payload_variant: Variant = _game_root.call("get_runtime_reward_multipliers")
		if payload_variant is Dictionary:
			return (payload_variant as Dictionary).duplicate(true)
	return {}


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
		var room_snapshot := room.to_dictionary()
		var encounter_snapshot := _encounter_director.describe_room(floor_state, room)
		room_snapshot["encounter_id"] = String(encounter_snapshot.get("encounter_id", ""))
		room_snapshot["encounter_label"] = String(encounter_snapshot.get("encounter_label", ""))
		room_snapshot["encounter_category"] = String(encounter_snapshot.get("encounter_category", ""))
		room_snapshot["encounter_category_label"] = String(encounter_snapshot.get("encounter_category_label", ""))
		room_snapshot["reward_table_id"] = String(encounter_snapshot.get("reward_table_id", ""))
		room_snapshot["spawn_set_id"] = String(encounter_snapshot.get("spawn_set_id", ""))
		room_snapshot["difficulty"] = int(encounter_snapshot.get("difficulty", 0))
		snapshots.append(room_snapshot)
	return snapshots


func _build_minimap_snapshot() -> Dictionary:
	var floor_state = _get_current_floor()
	return {
		"floor_label": _resolve_floor_label(),
		"current_room_id": _current_room.room_id if _current_room != null else "",
		"current_room_label": _current_room.label if _current_room != null else "",
		"current_room_type_label": _resolve_current_room_focus_label(),
		"rooms": _build_floor_rooms_snapshot(),
		"template_id": floor_state.template_id if floor_state != null else ""
	}


func _resolve_floor_label() -> String:
	var floor_state = _get_current_floor()
	if floor_state == null:
		return "Night Run"
	return floor_state.label


func _resolve_current_room_focus_label() -> String:
	if _current_room == null:
		return "Staging Chamber"
	var encounter_label := String(_current_room_payload.get("encounter_category_label", "")).strip_edges()
	if _current_room.is_combat_room() and not encounter_label.is_empty():
		return encounter_label
	return _current_room.room_type_label


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
		STATE_REWARD_PENDING:
			return "Choose one room reward"
		STATE_ROOM_CLEARED:
			return "Room clear: choose the next room"
		STATE_FLOOR_CLEARED:
			return "Extraction path secured"
		STATE_COMPLETED:
			if bool(_extraction_snapshot.get("available", false)):
				return "Skiff extraction ready"
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
			room_label.text = "%s · %s" % [_current_room.label, _resolve_current_room_focus_label()]
	if status_label != null:
		status_label.text = _resolve_status_text()
	_refresh_reward_panel()
	_refresh_boss_panel()
	_refresh_extraction_panel()
	if minimap != null and is_instance_valid(minimap) and minimap.has_method("set_map_snapshot"):
		minimap.call("set_map_snapshot", _build_minimap_snapshot())


func _refresh_reward_panel() -> void:
	if reward_panel == null:
		return
	if _pending_room_rewards.is_empty():
		_hide_reward_panel()
		return
	reward_panel.visible = true
	if reward_title_label != null:
		reward_title_label.text = "Room Reward"
	if reward_subtitle_label != null:
		reward_subtitle_label.text = "%s · %s" % [
			_current_room.label if _current_room != null else "Unknown Room",
			_resolve_current_room_focus_label()
		]
	if reward_hint_label != null:
		reward_hint_label.text = "Pick one reward before taking the next door."
	for button_index in range(_reward_buttons.size()):
		var button := _reward_buttons[button_index]
		if button == null:
			continue
		if button_index >= _pending_room_rewards.size():
			button.visible = false
			button.disabled = true
			button.text = ""
			continue
		var offer: Dictionary = _pending_room_rewards[button_index]
		button.visible = true
		button.disabled = false
		button.text = _format_reward_button_text(offer)


func _format_reward_button_text(offer: Dictionary) -> String:
	var reward_kind := String(offer.get("reward_kind", "reward")).strip_edges().capitalize()
	var label := String(offer.get("label", "Choice")).strip_edges()
	var summary := String(offer.get("summary", offer.get("description", ""))).strip_edges()
	if summary.is_empty():
		return "%s\n%s" % [reward_kind, label]
	return "%s\n%s\n%s" % [reward_kind, label, summary]


func _hide_reward_panel() -> void:
	if reward_panel != null:
		reward_panel.visible = false


func _clear_pending_room_rewards() -> void:
	_pending_room_rewards.clear()
	_hide_reward_panel()


func _has_pending_room_rewards() -> bool:
	return not _pending_room_rewards.is_empty()


func _refresh_boss_panel() -> void:
	if boss_panel == null:
		return
	var snapshot := _boss_room_controller.get_snapshot()
	_boss_climax_snapshot = snapshot.duplicate(true)
	var visible := bool(snapshot.get("active", false))
	boss_panel.visible = visible
	if not visible:
		return
	if boss_title_label != null:
		boss_title_label.text = String(snapshot.get("title", "Floor Climax"))
	if boss_phase_label != null:
		boss_phase_label.text = String(snapshot.get("phase_label", "Boss Active"))
	if boss_status_label != null:
		boss_status_label.text = String(snapshot.get("subtitle", ""))


func _refresh_extraction_panel() -> void:
	if extraction_panel == null:
		return
	var current_run_state := _run_state
	if current_run_state == STATE_COMPLETED:
		current_run_state = "completed"
	elif current_run_state == STATE_ABORTED:
		current_run_state = "aborted"
	_extraction_snapshot = _extraction_controller.build_status(
		current_run_state,
		_current_room,
		_has_pending_room_rewards()
	)
	extraction_panel.visible = true
	if extraction_title_label != null:
		extraction_title_label.text = String(_extraction_snapshot.get("title", "Extraction"))
	if extraction_status_label != null:
		extraction_status_label.text = String(_extraction_snapshot.get("subtitle", ""))
	if extract_button != null:
		extract_button.text = String(_extraction_snapshot.get("button_text", "Extract"))
		extract_button.disabled = not bool(_extraction_snapshot.get("available", false))


func _try_extract_early() -> bool:
	var status := _extraction_controller.build_status(_run_state, _current_room, _has_pending_room_rewards())
	_extraction_snapshot = status.duplicate(true)
	if not bool(status.get("available", false)):
		_update_ui()
		return false
	_complete_run_with_reason("extracted")
	return true


func _on_extract_button_pressed() -> void:
	_try_extract_early()


func _on_boss_spawned(boss_id: String, phase_id: String, telegraph_text: String) -> void:
	_boss_climax_snapshot = _boss_room_controller.on_boss_spawned(boss_id, phase_id, telegraph_text)
	_last_room_note = "Floor climax engaged"
	_update_ui()


func _on_boss_phase_changed(boss_id: String, phase_id: String, telegraph_text: String) -> void:
	_boss_climax_snapshot = _boss_room_controller.on_boss_phase_changed(boss_id, phase_id, telegraph_text)
	_last_room_note = "Boss phase shift"
	_update_ui()


func _on_boss_defeated(boss_id: String) -> void:
	_boss_climax_snapshot = _boss_room_controller.on_boss_defeated(boss_id)
	var bonus_payload := _boss_room_controller.get_completion_bonus()
	if not bonus_payload.is_empty():
		_extraction_controller.record_boss_bonus(bonus_payload)
	_last_room_note = "Boss down: claim the final room reward"
	_update_ui()
