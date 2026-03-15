extends Node
class_name NightRunController

signal session_completed(summary: Dictionary)
signal session_bootstrapped(success: bool)

const GAME_ROOT_SCENE := preload("res://scenes/game/GameRoot.tscn")
const RoomGraphGeneratorClass := preload("res://scripts/night/room_graph_generator.gd")
const EncounterDirectorClass := preload("res://scripts/night/encounter_director.gd")
const RoomExitClass := preload("res://scripts/night/room_exit.gd")
const RunModifierStateClass := preload("res://scripts/night/run_modifier_state.gd")
const RoomRewardPickerClass := preload("res://scripts/night/room_reward_picker.gd")
const FloorMutatorControllerClass := preload("res://scripts/night/floor_mutator_controller.gd")
const ObjectiveRuntimeControllerClass := preload("res://scripts/night/objective_runtime_controller.gd")
const BossRoomControllerClass := preload("res://scripts/night/boss_room_controller.gd")
const ExtractionControllerClass := preload("res://scripts/night/extraction_controller.gd")
const RoomInteractableScene := preload("res://scenes/night/rooms/setpieces/RoomInteractable.tscn")

const STATE_BOOTING := "booting"
const STATE_ENTERING_ROOM := "entering_room"
const STATE_TRANSITING := "transiting"
const STATE_ROOM_LOCKED := "room_locked"
const STATE_REWARD_PENDING := "reward_pending"
const STATE_ROOM_CLEARED := "room_cleared"
const STATE_FLOOR_CLEARED := "floor_cleared"
const STATE_COMPLETED := "completed"
const STATE_ABORTED := "aborted"
const BOOT_MAX_ATTEMPTS := 12
const EMBEDDED_PRESENTATION_PROFILE := "clear_dungeon"
const ROOM_SCENE_BASE_SIZE := Vector2(928.0, 608.0)
const ROOM_SHELL_NODE_NAME := "RuntimeRoomShell"
const ROOM_COVER_PROXY_NODE_NAME := "RuntimeCoverProxies"
const ROOM_OBJECTIVE_ROOT_NODE_NAME := "RuntimeObjectives"
const ROOM_INTERACTION_ROOT_NODE_NAME := "RuntimeInteractions"
const ROOM_TRANSITION_PREVIEW_NODE_NAME := "RuntimeTransitionPreview"
const ROOM_TRANSITION_CORRIDOR_NODE_NAME := "RuntimeTransitionCorridor"
const ROOM_PLAYER_TARGET_OFFSET := Vector2(0.0, 96.0)
const ROOM_SHELL_HALF_SIZE := Vector2(512.0, 340.0)
const ROOM_SHELL_INNER_HALF_SIZE := Vector2(436.0, 264.0)
const ROOM_SHELL_BACKDROP_HALF_SIZE := Vector2(660.0, 452.0)
const ROOM_SHELL_WALL_THICKNESS := 74.0
const ROOM_SHELL_DOOR_HALF_WIDTH := 118.0
const ROOM_SHELL_DOOR_HALF_HEIGHT := 96.0
const ROOM_SHELL_CORNER_SIZE := Vector2(92.0, 92.0)
const ROOM_OUTSIDE_MASK_EXTENT := Vector2(2400.0, 1800.0)
const ROOM_TILE_SIZE := Vector2(76.0, 58.0)
const ROOM_TILE_GAP := 4.0
const ROOM_CORNER_SHADOW_SIZE := Vector2(192.0, 192.0)
const ROOM_DOORWAY_PLANK_DEPTH := 76.0
const ROOM_CORRIDOR_STUB_LENGTH := 320.0
const ROOM_CORRIDOR_STUB_WIDTH_MULT := 0.94
const ROOM_CORRIDOR_RAIL_THICKNESS := 24.0
const ROOM_DOORWAY_PLANK_WIDTH_MULT := 1.42
const ROOM_DOORWAY_RAIL_THICKNESS := 12.0
const ROOM_DOORWAY_BOARD_THICKNESS := 14.0
const ROOM_DOORWAY_BOARD_GAP := 10.0
const ROOM_DOOR_PANEL_THICKNESS := 26.0
const ROOM_DOOR_PANEL_DEPTH := 108.0
const ROOM_DOOR_CENTER_SEAL := 18.0
const ROOM_DOOR_POST_THICKNESS := 18.0
const ROOM_DOOR_GLOW_THICKNESS := 10.0
const ROOM_COVER_PROXY_LAYER_Z := 30
const ROOM_TRANSITION_CAMERA_ZOOM := Vector2(0.84, 0.84)
const ROOM_TRANSITION_DURATION_SEC := 0.34
const ROOM_TRANSITION_HORIZONTAL_SPACING := 1580.0
const ROOM_TRANSITION_VERTICAL_SPACING := 1220.0
const ROOM_TRANSITION_CORRIDOR_WIDTH := 188.0
const ROOM_TRANSITION_CORRIDOR_WALL_THICKNESS := 28.0
const EXIT_ANCHOR_LAYOUTS := {
	1: ["East"],
	2: ["East", "West"],
	3: ["East", "North", "West"],
	4: ["East", "North", "West", "South"]
}
const ROOM_THEME := {
	"combat": {"floor": Color(0.23, 0.31, 0.38, 0.96), "outline": Color(0.64, 0.90, 1.0, 1.0)},
	"treasure": {"floor": Color(0.38, 0.31, 0.18, 0.96), "outline": Color(1.0, 0.86, 0.42, 1.0)},
	"rest": {"floor": Color(0.23, 0.35, 0.29, 0.96), "outline": Color(0.64, 0.96, 0.77, 1.0)},
	"event": {"floor": Color(0.40, 0.27, 0.21, 0.96), "outline": Color(1.0, 0.69, 0.47, 1.0)},
	"boss": {"floor": Color(0.36, 0.20, 0.24, 0.98), "outline": Color(1.0, 0.56, 0.62, 1.0)}
}
const SHRINE_BLESSING_POOLS := {
	"tide_statue_pool": [
		"blessing_tide_burst",
		"blessing_anchor_spark",
		"blessing_shell_guard",
		"blessing_hunter_gull",
		"blessing_broker_surge",
		"blessing_omen_lowtide",
		"blessing_choir_silence",
		"blessing_harbor_light"
	],
	"undertow_altar_pool": [
		"blessing_shell_guard",
		"blessing_hunter_gull",
		"blessing_broker_surge",
		"blessing_omen_lowtide",
		"blessing_choir_silence",
		"blessing_harbor_light"
	]
}
const SHOP_INVENTORY_POOLS := {
	"night_market_tier_1": {
		"bundle_entries": ["salvage_drift_pack", "relay_field_rations", "coil_haul"],
		"trait_entries": [
			"trait_ricochet_rifling",
			"trait_chilled_chamber",
			"trait_overcrank_burst",
			"trait_harpoon_spool",
			"trait_mining_tip"
		],
		"price_offsets": [-12, 0, 12]
	},
	"night_market_tier_2": {
		"bundle_entries": ["challenge_bounty", "sanctum_manifest", "coil_haul"],
		"trait_entries": [
			"trait_harpoon_spool",
			"trait_split_core",
			"trait_mining_tip",
			"trait_salt_edge",
			"trait_sonar_fins",
			"trait_conductive_chain"
		],
		"price_offsets": [-6, 12, 24]
	}
}
const ROOM_INTERACTION_OFFSETS := {
	"shrine": Vector2(0.0, -52.0),
	"shop": Vector2(0.0, -8.0),
	"generic": Vector2.ZERO
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
@onready var interaction_panel: PanelContainer = $Overlay/InteractionPanel
@onready var interaction_label: Label = $Overlay/InteractionPanel/MarginContainer/InteractionLabel
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
var _floor_mutator_controller = FloorMutatorControllerClass.new()
var _objective_runtime_controller = ObjectiveRuntimeControllerClass.new()
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
var _transition_preview_room_node: Node2D = null
var _transition_corridor_node: Node2D = null
var _active_exit_nodes: Array = []
var _pending_room_rewards: Array[Dictionary] = []
var _pending_reward_context: Dictionary = {}
var _run_state: String = STATE_BOOTING
var _boot_attempts: int = 0
var _bootstrap_reported: bool = false
var _completion_emitted: bool = false
var _rooms_cleared_total: int = 0
var _visited_room_ids: Array[String] = []
var _last_room_note: String = ""
var _boss_climax_snapshot: Dictionary = {}
var _extraction_snapshot: Dictionary = {}
var _transition_target_room_id: String = ""
var _transition_anchor_side: String = ""
var _transition_target_room = null
var _transition_elapsed_sec: float = 0.0
var _transition_start_position: Vector2 = Vector2.ZERO
var _transition_end_position: Vector2 = Vector2.ZERO
var _pending_entry_anchor_side: String = ""
var _current_room_entry_anchor_side: String = ""
var _active_room_interactions: Array = []
var _focused_room_interaction_id: String = ""


func _ready() -> void:
	set_process(true)
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
	_hide_interaction_panel()
	_boss_room_controller.reset()
	_extraction_controller.reset()
	_boss_climax_snapshot = _boss_room_controller.get_snapshot()
	_refresh_boss_panel()
	_refresh_extraction_panel()
	_update_ui()


func _process(delta: float) -> void:
	if _run_state == STATE_TRANSITING:
		if _transition_target_room == null:
			return
		var player := _get_player()
		if not (player is Node2D):
			_complete_room_transition(_transition_target_room)
			return
		_transition_elapsed_sec += maxf(delta, 0.0)
		var progress := 1.0
		if ROOM_TRANSITION_DURATION_SEC > 0.0:
			progress = clampf(_transition_elapsed_sec / ROOM_TRANSITION_DURATION_SEC, 0.0, 1.0)
		var eased := 0.5 - 0.5 * cos(progress * PI)
		(player as Node2D).global_position = _transition_start_position.lerp(_transition_end_position, eased)
		if progress >= 1.0:
			_complete_room_transition(_transition_target_room)
		return
	_update_room_objective(maxf(delta, 0.0))
	_update_room_interaction_focus()


func _unhandled_input(event: InputEvent) -> void:
	if event == null or _completion_emitted:
		return
	if _has_pending_room_rewards():
		return
	if event.is_echo():
		return
	if event.is_action_pressed("night_interact"):
		_try_activate_room_interaction()


func start_session(request: Dictionary) -> void:
	_reset_runtime_state()
	_active_request = request.duplicate(true)
	_floors = _room_graph_generator.build_floors(int(_active_request.get("seed", 0)), _active_request)
	if _floors.is_empty():
		_run_state = STATE_ABORTED
		_last_room_note = _tr("night.run.note.no_dungeon_template")
		_update_ui()
		_emit_bootstrap_result(false)
		push_error("NightRunController could not build a dungeon floor from the night data files.")
		return

	_game_root = GAME_ROOT_SCENE.instantiate()
	if _game_root == null:
		_run_state = STATE_ABORTED
		_last_room_note = _tr("night.run.note.combat_world_unavailable")
		_update_ui()
		_emit_bootstrap_result(false)
		push_error("NightRunController could not instantiate GameRoot.")
		return
	var embedded_request := _active_request.duplicate(true)
	embedded_request["session_duration_sec"] = 0.0
	embedded_request["presentation_profile"] = EMBEDDED_PRESENTATION_PROFILE
	if _game_root.has_method("set_embedded_session_request"):
		_game_root.call("set_embedded_session_request", embedded_request)
	if _game_root.has_signal("embedded_session_finished"):
		_game_root.connect("embedded_session_finished", Callable(self, "_on_embedded_session_finished"))
	game_mount.add_child(_game_root)
	_run_state = STATE_BOOTING
	_last_room_note = _tr("night.run.note.mapping_floor")
	_update_ui()
	call_deferred("_finish_bootstrap")


func stop_session() -> void:
	if _enemy_manager != null and is_instance_valid(_enemy_manager) and _enemy_manager.has_method("clear_scripted_encounter"):
		_enemy_manager.call("clear_scripted_encounter", true, false)
	_clear_room_objective_runtime()
	_disconnect_enemy_manager()
	_cleanup_transition_nodes()
	_set_player_input_locked(false)
	_clear_transition_camera_zoom()
	_transition_target_room_id = ""
	_transition_anchor_side = ""
	_transition_target_room = null
	_transition_elapsed_sec = 0.0
	_transition_start_position = Vector2.ZERO
	_transition_end_position = Vector2.ZERO
	_pending_entry_anchor_side = ""
	_current_room_entry_anchor_side = ""
	_cleanup_active_room()
	_clear_pending_room_rewards()
	_clear_room_interactions()
	_boss_room_controller.reset()
	_objective_runtime_controller.reset(_build_objective_runtime_context())
	_extraction_controller.reset()
	_boss_climax_snapshot = _boss_room_controller.get_snapshot()
	if _game_root != null and is_instance_valid(_game_root):
		_game_root.queue_free()
	_game_root = null
	_world = null
	_active_request.clear()
	_floor_mutator_controller.reset()
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
	var floor_mutator_snapshot := _floor_mutator_controller.get_current_mutator()
	var floor_mutator_state := _floor_mutator_controller.get_snapshot()
	var room_render_parent := ""
	var room_scene_scale := Vector2.ONE
	var room_position := Vector2.ZERO
	var room_shell_visual_count := 0
	var room_tile_visual_count := 0
	var room_corner_shadow_count := 0
	var room_plank_visual_count := 0
	var room_corridor_visual_count := 0
	var room_door_visual_count := 0
	var room_open_door_visual_count := 0
	var room_closed_door_visual_count := 0
	if _active_room_node != null and is_instance_valid(_active_room_node):
		room_scene_scale = _active_room_node.scale
		room_position = _active_room_node.position
		var room_shell := _active_room_node.get_node_or_null(ROOM_SHELL_NODE_NAME)
		if room_shell != null:
			room_shell_visual_count = room_shell.get_child_count()
			var tile_root := room_shell.get_node_or_null("FloorTiles")
			if tile_root != null:
				room_tile_visual_count = tile_root.get_child_count()
			var corner_shadow_root := room_shell.get_node_or_null("CornerShadows")
			if corner_shadow_root != null:
				room_corner_shadow_count = corner_shadow_root.get_child_count()
			var plank_root := room_shell.get_node_or_null("DoorwayPlanks")
			if plank_root != null:
				room_plank_visual_count = plank_root.get_child_count()
			var corridor_root := room_shell.get_node_or_null("CorridorStubs")
			if corridor_root != null:
				room_corridor_visual_count = corridor_root.get_child_count()
			var door_root := room_shell.get_node_or_null("DoorState")
			if door_root != null:
				room_door_visual_count = door_root.get_child_count()
				for child in door_root.get_children():
					if child == null:
						continue
					var child_name := String(child.name)
					if child_name.begins_with("DoorOpen_"):
						room_open_door_visual_count += 1
					elif child_name.begins_with("DoorClosed_"):
						room_closed_door_visual_count += 1
		var room_parent := _active_room_node.get_parent()
		if room_parent != null:
			room_render_parent = String(room_parent.name)
	var camera_zoom := Vector2.ONE
	if _world != null and is_instance_valid(_world):
		var camera_node := _world.get_node_or_null("Player/Camera2D")
		if camera_node is Camera2D:
			camera_zoom = (camera_node as Camera2D).zoom
	return {
		"state": _run_state,
		"presentation_profile": _game_root.call("get_presentation_profile") if _game_root != null and is_instance_valid(_game_root) and _game_root.has_method("get_presentation_profile") else "",
		"runtime_fog_enabled": _world.call("is_fog_enabled") if _world != null and is_instance_valid(_world) and _world.has_method("is_fog_enabled") else false,
		"runtime_clear_dungeon_presentation": _world.call("is_clear_dungeon_presentation_enabled") if _world != null and is_instance_valid(_world) and _world.has_method("is_clear_dungeon_presentation_enabled") else false,
		"floor_index": _current_floor_index + 1,
		"floor_count": _floors.size(),
		"floor_label": _resolve_floor_label(),
		"floor_template_id": _get_current_floor().template_id if _get_current_floor() != null else "",
		"room_id": _current_room.room_id if _current_room != null else "",
		"room_label": _current_room.label if _current_room != null else "",
		"room_type_id": _current_room.room_type_id if _current_room != null else "",
		"room_type_label": _current_room.room_type_label if _current_room != null else "",
		"room_status": _current_room.status if _current_room != null else "",
		"room_cleared": _current_room.status == RoomState.STATUS_CLEARED if _current_room != null else false,
		"room_reward_claimed": bool(_current_room.reward_claimed) if _current_room != null else false,
		"room_goal": bool(_current_room.is_goal) if _current_room != null else false,
		"room_note": _last_room_note,
		"room_render_parent": room_render_parent,
		"room_position": room_position,
		"room_scene_scale": room_scene_scale,
		"room_shell_present": room_shell_visual_count > 0,
		"room_shell_visual_count": room_shell_visual_count,
		"room_tile_visual_count": room_tile_visual_count,
		"room_corner_shadow_count": room_corner_shadow_count,
		"room_plank_visual_count": room_plank_visual_count,
		"room_corridor_visual_count": room_corridor_visual_count,
		"room_door_visual_count": room_door_visual_count,
		"room_open_door_visual_count": room_open_door_visual_count,
		"room_closed_door_visual_count": room_closed_door_visual_count,
		"room_content": _get_active_room_content_snapshot(),
		"transition_active": _transition_preview_room_node != null and is_instance_valid(_transition_preview_room_node),
		"transition_target_room_id": _transition_target_room_id,
		"transition_anchor_side": _transition_anchor_side,
		"transition_corridor_present": _transition_corridor_node != null and is_instance_valid(_transition_corridor_node),
		"room_payload": _current_room_payload.duplicate(true),
		"encounter_id": String(_current_room_payload.get("encounter_id", "")),
		"encounter_label": String(_current_room_payload.get("encounter_label", "")),
		"encounter_category": String(_current_room_payload.get("encounter_category", "")),
		"encounter_category_label": String(_current_room_payload.get("encounter_category_label", "")),
		"spawn_set_id": String(_current_room_payload.get("spawn_set_id", "")),
		"reward_panel_visible": reward_panel != null and reward_panel.visible,
		"interaction_panel_visible": interaction_panel != null and interaction_panel.visible,
		"reward_choices": _pending_room_rewards.duplicate(true),
		"interactions": _build_room_interaction_snapshot(),
		"objective": _objective_runtime_controller.get_snapshot(),
		"floor_mutator": floor_mutator_snapshot,
		"floor_mutator_state": floor_mutator_state,
		"schema_contracts": {
			"encounter": _encounter_director.get_schema_contract() if _encounter_director != null and _encounter_director.has_method("get_schema_contract") else {},
			"floor": _room_graph_generator.get_schema_contract() if _room_graph_generator != null and _room_graph_generator.has_method("get_schema_contract") else {},
			"reward": _room_reward_picker.get_schema_contract() if _room_reward_picker != null and _room_reward_picker.has_method("get_schema_contract") else {}
		},
		"schema_warnings": {
			"encounter": _encounter_director.get_schema_warnings() if _encounter_director != null and _encounter_director.has_method("get_schema_warnings") else [],
			"floor": _room_graph_generator.get_schema_warnings() if _room_graph_generator != null and _room_graph_generator.has_method("get_schema_warnings") else [],
			"reward": _room_reward_picker.get_schema_warnings() if _room_reward_picker != null and _room_reward_picker.has_method("get_schema_warnings") else []
		},
		"run_modifier_state": modifier_snapshot,
		"visited_room_ids": _visited_room_ids.duplicate(),
		"rooms_cleared_total": _rooms_cleared_total,
		"available_exits": exits,
		"floor_rooms": _build_floor_rooms_snapshot(),
		"boss_climax": _boss_climax_snapshot.duplicate(true),
		"boss_hud": _enemy_manager.get_boss_hud_snapshot() if _enemy_manager != null and is_instance_valid(_enemy_manager) and _enemy_manager.has_method("get_boss_hud_snapshot") else {},
		"extraction": _extraction_snapshot.duplicate(true),
		"dungeon_carryover_preview": _extraction_controller.get_snapshot(),
		"camera_zoom": camera_zoom,
		"runtime_map_geometry_hidden": _world.call("is_clear_dungeon_map_geometry_hidden") if _world != null and is_instance_valid(_world) and _world.has_method("is_clear_dungeon_map_geometry_hidden") else false,
		"player_hud": _get_player_hud_snapshot(),
		"minimap": _build_minimap_snapshot()
	}


func debug_force_clear_room() -> void:
	if _has_pending_room_rewards():
		return
	if _has_active_objective():
		_complete_room_objective(true)
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


func debug_interact_room_feature(interaction_id: String = "") -> bool:
	var normalized_interaction_id := interaction_id.strip_edges()
	if normalized_interaction_id.is_empty():
		for interaction_node in _active_room_interactions:
			if interaction_node == null or not is_instance_valid(interaction_node):
				continue
			normalized_interaction_id = String(interaction_node.get("interaction_id")).strip_edges()
			if not normalized_interaction_id.is_empty():
				break
	return _try_activate_room_interaction(normalized_interaction_id)


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
		_last_room_note = _tr("night.run.note.boot_failed")
		_update_ui()
		_emit_bootstrap_result(false)
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
	if not _enter_floor_start_room(floor_state):
		return


func _enter_room(room_state: RoomState) -> void:
	if room_state == null or _completion_emitted:
		return
	_run_state = STATE_ENTERING_ROOM
	_transition_target_room_id = ""
	_transition_anchor_side = ""
	_transition_target_room = null
	_transition_elapsed_sec = 0.0
	_transition_start_position = Vector2.ZERO
	_transition_end_position = Vector2.ZERO
	_current_room_entry_anchor_side = _pending_entry_anchor_side
	_pending_entry_anchor_side = ""
	_clear_pending_room_rewards()
	_cleanup_transition_nodes()
	_cleanup_active_room()
	_clear_room_interactions()
	if _enemy_manager != null and is_instance_valid(_enemy_manager) and _enemy_manager.has_method("clear_scripted_encounter"):
		_enemy_manager.call("clear_scripted_encounter", true, false)
	_set_player_input_locked(false)
	_clear_transition_camera_zoom()
	_current_room = room_state
	_current_room_payload = _encounter_director.describe_room(_get_current_floor(), room_state)
	_current_room.set_active()
	_record_room_visit(room_state.room_id)
	_boss_climax_snapshot = _boss_room_controller.begin_room(room_state, _current_room_payload)

	var room_scene: PackedScene = load(room_state.scene_path)
	if room_scene == null:
		_run_state = STATE_ABORTED
		_last_room_note = _tr("night.run.note.missing_room_scene")
		_update_ui()
		_emit_bootstrap_result(false)
		push_error("NightRunController could not load room scene: %s" % room_state.scene_path)
		return
	var room_variant: Variant = room_scene.instantiate()
	if not (room_variant is Node2D):
		_run_state = STATE_ABORTED
		_last_room_note = _tr("night.run.note.invalid_room_scene")
		_update_ui()
		_emit_bootstrap_result(false)
		push_error("NightRunController expected a Node2D room scene: %s" % room_state.scene_path)
		return
	_active_room_node = room_variant
	_active_room_node.name = "ActiveRoom_%s" % room_state.room_id
	_active_room_node.z_index = 0
	_suppress_base_room_shell_visuals()
	_apply_room_layout_scale(room_state)
	_apply_room_focus_offset()
	_resolve_room_mount().add_child(_active_room_node)
	_rebuild_runtime_room_shell(room_state)
	_rebuild_runtime_cover_proxies()
	_apply_room_visual_theme(room_state)
	_spawn_exit_nodes(room_state)
	_teleport_player_to_active_room()
	_last_room_note = _tr("night.run.note.enter_room", {"value": _resolve_current_room_focus_label()})

	if room_state.is_combat_room() and room_state.status != RoomState.STATUS_CLEARED:
		_lock_active_exits(true)
		_run_state = STATE_ROOM_LOCKED
		_current_room_payload = _encounter_director.build_room_payload(_get_current_floor(), room_state, _active_room_node)
		_start_room_objective(_current_room_payload)
		var enemy_specs: Array = _current_room_payload.get("enemies", [])
		var spawned_total := 0
		if _enemy_manager != null and is_instance_valid(_enemy_manager) and _enemy_manager.has_method("start_scripted_encounter"):
			spawned_total = int(_enemy_manager.call("start_scripted_encounter", room_state.room_id, enemy_specs))
		_sync_objective_hold_open()
		if spawned_total <= 0 and not _should_defer_room_resolution():
			_mark_current_room_cleared()
			if not _present_room_clear_rewards():
				if room_state.is_goal and room_state.connections.is_empty():
					_complete_or_advance_floor()
				else:
					_last_room_note = _tr("night.run.note.choose_door")
	else:
		_clear_room_objective_runtime()
		var spawned_interactions := _spawn_room_interactions(room_state)
		if room_state.reward_on_enter and not room_state.reward_claimed and not spawned_interactions:
			_claim_room_reward(room_state)
		_mark_current_room_cleared()
		if spawned_interactions:
			var special_kind := String(room_state.metadata.get("special_room_kind", "")).strip_edges().to_lower()
			_last_room_note = _interaction_panel_hint_for_kind(special_kind)
		if room_state.is_goal and room_state.connections.is_empty():
			_complete_or_advance_floor()
	_emit_bootstrap_result(true)
	_update_ui()


func _apply_room_visual_theme(room_state: RoomState) -> void:
	_apply_room_visual_theme_to_node(_active_room_node, room_state)


func _apply_room_visual_theme_to_node(room_node: Node2D, room_state: RoomState) -> void:
	if room_node == null:
		return
	var theme: Dictionary = ROOM_THEME.get(room_state.room_type_id, ROOM_THEME[RoomState.TYPE_COMBAT])
	var floor_node := room_node.get_node_or_null("Floor")
	if floor_node is Polygon2D:
		(floor_node as Polygon2D).color = theme["floor"]
	var outline_node := room_node.get_node_or_null("Outline")
	if outline_node is Line2D:
		(outline_node as Line2D).default_color = theme["outline"]


func _apply_room_layout_scale(room_state: RoomState) -> void:
	_apply_room_layout_scale_to_node(_active_room_node, room_state)


func _apply_room_layout_scale_to_node(room_node: Node2D, room_state: RoomState) -> void:
	if room_node == null:
		return
	var target_size := room_state.map_size
	if target_size.x <= 0.0 or target_size.y <= 0.0:
		room_node.scale = Vector2.ONE
		return
	room_node.scale = Vector2(
		clampf(target_size.x / ROOM_SCENE_BASE_SIZE.x, 0.85, 1.75),
		clampf(target_size.y / ROOM_SCENE_BASE_SIZE.y, 0.85, 1.75)
	)


func _apply_room_focus_offset() -> void:
	if _active_room_node == null:
		return
	var spawn_node := _active_room_node.get_node_or_null("PlayerSpawn")
	if not (spawn_node is Node2D):
		_active_room_node.position = Vector2.ZERO
		return
	var scaled_spawn := (spawn_node as Node2D).position * _active_room_node.scale
	_active_room_node.position = ROOM_PLAYER_TARGET_OFFSET - scaled_spawn


func _suppress_base_room_shell_visuals() -> void:
	return


func _rebuild_runtime_room_shell(room_state: RoomState) -> void:
	_rebuild_runtime_room_shell_for_node(_active_room_node, room_state, _current_room_entry_anchor_side)


func _rebuild_runtime_room_shell_for_node(room_node: Node2D, room_state: RoomState, entry_anchor_side: String = "") -> void:
	if room_node == null:
		return
	var existing_shell := room_node.get_node_or_null(ROOM_SHELL_NODE_NAME)
	if existing_shell != null:
		room_node.remove_child(existing_shell)
		existing_shell.queue_free()
	var shell_root := Node2D.new()
	shell_root.name = ROOM_SHELL_NODE_NAME
	shell_root.z_index = 12
	room_node.add_child(shell_root)
	shell_root.owner = null
	var theme: Dictionary = ROOM_THEME.get(room_state.room_type_id, ROOM_THEME[RoomState.TYPE_COMBAT])
	var theme_floor: Color = theme["floor"] as Color
	var theme_outline: Color = theme["outline"] as Color
	var floor_color := Color(0.26, 0.31, 0.37, 0.98).lerp(theme_floor.lightened(0.18), 0.24)
	var inner_floor_color := floor_color.lightened(0.12)
	var wall_color := Color(0.72, 0.78, 0.84, 1.0).lerp(theme_outline.lightened(0.08), 0.14)
	var wall_shadow_color := Color(0.02, 0.03, 0.05, 0.52)
	var trim_color := Color(0.88, 0.93, 0.98, 0.98).lerp(theme_outline, 0.18)
	var tile_color_a := inner_floor_color.lightened(0.04)
	var tile_color_b := inner_floor_color.darkened(0.05)
	var grout_color := Color(0.12, 0.15, 0.19, 0.28)
	var plank_base_color := Color(0.47, 0.35, 0.23, 0.96)
	var plank_board_color := Color(0.66, 0.52, 0.34, 0.98)
	var plank_rail_color := Color(0.27, 0.19, 0.12, 0.92)
	_add_outside_masks(shell_root)
	_add_shell_rect(shell_root, "BackdropPlate", Vector2.ZERO, ROOM_SHELL_BACKDROP_HALF_SIZE * 2.0, Color(0.03, 0.04, 0.06, 0.92), -2)
	_add_shell_rect(shell_root, "OuterFloor", Vector2.ZERO, ROOM_SHELL_HALF_SIZE * 2.0, floor_color, -1)
	_add_shell_rect(shell_root, "InnerFloor", Vector2.ZERO, ROOM_SHELL_INNER_HALF_SIZE * 2.0, inner_floor_color, 0)
	_add_floor_tiles(shell_root, ROOM_SHELL_INNER_HALF_SIZE, tile_color_a, tile_color_b, grout_color)
	_add_shell_grid(shell_root, ROOM_SHELL_INNER_HALF_SIZE, trim_color)
	_add_shell_rect(shell_root, "NorthShadow", Vector2(0.0, -ROOM_SHELL_INNER_HALF_SIZE.y + 26.0), Vector2(ROOM_SHELL_INNER_HALF_SIZE.x * 1.88, 56.0), wall_shadow_color, 1)
	_add_shell_rect(shell_root, "SouthShadow", Vector2(0.0, ROOM_SHELL_INNER_HALF_SIZE.y - 18.0), Vector2(ROOM_SHELL_INNER_HALF_SIZE.x * 1.86, 28.0), Color(0.02, 0.03, 0.05, 0.18), 1)
	_add_shell_rect(shell_root, "WestShadow", Vector2(-ROOM_SHELL_INNER_HALF_SIZE.x + 18.0, 0.0), Vector2(28.0, ROOM_SHELL_INNER_HALF_SIZE.y * 1.72), Color(0.02, 0.03, 0.05, 0.14), 1)
	_add_shell_rect(shell_root, "EastShadow", Vector2(ROOM_SHELL_INNER_HALF_SIZE.x - 18.0, 0.0), Vector2(28.0, ROOM_SHELL_INNER_HALF_SIZE.y * 1.72), Color(0.02, 0.03, 0.05, 0.14), 1)
	var open_sides: Array[String] = _resolve_room_open_sides(room_state, entry_anchor_side)
	_add_wall_band(shell_root, "North", "horizontal", -ROOM_SHELL_HALF_SIZE.y, ROOM_SHELL_HALF_SIZE.x, ROOM_SHELL_WALL_THICKNESS, ROOM_SHELL_DOOR_HALF_WIDTH, wall_color, open_sides.has("North"))
	_add_wall_band(shell_root, "South", "horizontal", ROOM_SHELL_HALF_SIZE.y, ROOM_SHELL_HALF_SIZE.x, ROOM_SHELL_WALL_THICKNESS, ROOM_SHELL_DOOR_HALF_WIDTH, wall_color.darkened(0.12), open_sides.has("South"))
	_add_wall_band(shell_root, "West", "vertical", -ROOM_SHELL_HALF_SIZE.x, ROOM_SHELL_HALF_SIZE.y, ROOM_SHELL_WALL_THICKNESS, ROOM_SHELL_DOOR_HALF_HEIGHT, wall_color.darkened(0.05), open_sides.has("West"))
	_add_wall_band(shell_root, "East", "vertical", ROOM_SHELL_HALF_SIZE.x, ROOM_SHELL_HALF_SIZE.y, ROOM_SHELL_WALL_THICKNESS, ROOM_SHELL_DOOR_HALF_HEIGHT, wall_color.darkened(0.05), open_sides.has("East"))
	_add_shell_rect(shell_root, "FloorLipNorth", Vector2(0.0, -ROOM_SHELL_INNER_HALF_SIZE.y), Vector2(ROOM_SHELL_INNER_HALF_SIZE.x * 1.92, 10.0), Color(trim_color.r, trim_color.g, trim_color.b, 0.34), 2)
	_add_shell_rect(shell_root, "FloorLipSouth", Vector2(0.0, ROOM_SHELL_INNER_HALF_SIZE.y), Vector2(ROOM_SHELL_INNER_HALF_SIZE.x * 1.92, 10.0), Color(trim_color.r, trim_color.g, trim_color.b, 0.24), 2)
	_add_shell_rect(shell_root, "FloorLipWest", Vector2(-ROOM_SHELL_INNER_HALF_SIZE.x, 0.0), Vector2(10.0, ROOM_SHELL_INNER_HALF_SIZE.y * 1.92), Color(trim_color.r, trim_color.g, trim_color.b, 0.24), 2)
	_add_shell_rect(shell_root, "FloorLipEast", Vector2(ROOM_SHELL_INNER_HALF_SIZE.x, 0.0), Vector2(10.0, ROOM_SHELL_INNER_HALF_SIZE.y * 1.92), Color(trim_color.r, trim_color.g, trim_color.b, 0.24), 2)
	_add_corner_blocks(shell_root, wall_color)
	_add_corner_shadows(shell_root, wall_shadow_color)
	_add_door_caps(shell_root, trim_color, open_sides)
	_add_corridor_stubs(shell_root, open_sides, floor_color.darkened(0.05), wall_color.darkened(0.16), trim_color)
	_add_doorway_planks(shell_root, open_sides, plank_base_color, plank_board_color, plank_rail_color)
	_add_shell_outline(shell_root, trim_color)


func _rebuild_runtime_cover_proxies() -> void:
	_rebuild_runtime_cover_proxies_for_node(_active_room_node)


func _rebuild_runtime_cover_proxies_for_node(room_node: Node2D) -> void:
	if room_node == null:
		return
	var existing_root := room_node.get_node_or_null(ROOM_COVER_PROXY_NODE_NAME)
	if existing_root != null:
		room_node.remove_child(existing_root)
		existing_root.queue_free()
	var cover_bodies := _collect_ballistic_cover_bodies(room_node)
	if cover_bodies.is_empty():
		return
	var proxy_root := Node2D.new()
	proxy_root.name = ROOM_COVER_PROXY_NODE_NAME
	proxy_root.z_as_relative = false
	proxy_root.z_index = ROOM_COVER_PROXY_LAYER_Z
	room_node.add_child(proxy_root)
	proxy_root.owner = null
	for body in cover_bodies:
		_add_cover_proxy(room_node, proxy_root, body)


func _collect_ballistic_cover_bodies(root_node: Node) -> Array[StaticBody2D]:
	var cover_bodies: Array[StaticBody2D] = []
	if root_node == null:
		return cover_bodies
	var stack: Array[Node] = [root_node]
	while not stack.is_empty():
		var node: Node = stack.pop_back()
		if node == null:
			continue
		if String(node.name) == ROOM_COVER_PROXY_NODE_NAME:
			continue
		if node is StaticBody2D and node.is_in_group("ballistic_cover"):
			cover_bodies.append(node as StaticBody2D)
			continue
		for child in node.get_children():
			if child is Node:
				stack.append(child)
	return cover_bodies


func _add_cover_proxy(room_node: Node2D, parent: Node2D, body: StaticBody2D) -> void:
	if body == null or not is_instance_valid(body):
		return
	var collision_shape: CollisionShape2D = _find_cover_collision_shape(body)
	if collision_shape == null or collision_shape.shape == null:
		return
	var body_transform: Transform2D = body.global_transform
	var local_position: Vector2 = room_node.to_local(body_transform.origin)
	var proxy := Node2D.new()
	proxy.name = "CoverProxy_%s" % String(body.get_parent().name)
	proxy.position = local_position
	proxy.rotation = body.global_rotation - room_node.global_rotation
	proxy.scale = Vector2(
		body.global_scale.x / maxf(0.001, room_node.global_scale.x),
		body.global_scale.y / maxf(0.001, room_node.global_scale.y)
	)
	parent.add_child(proxy)
	if collision_shape.shape is RectangleShape2D:
		var rect_shape := collision_shape.shape as RectangleShape2D
		_add_rect_cover_proxy(proxy, rect_shape.size)
	elif collision_shape.shape is CircleShape2D:
		var circle_shape := collision_shape.shape as CircleShape2D
		_add_pillar_cover_proxy(proxy, circle_shape.radius)


func _find_cover_collision_shape(body: Node) -> CollisionShape2D:
	if body == null:
		return null
	for child in body.get_children():
		if child is CollisionShape2D:
			return child as CollisionShape2D
	return null


func _add_rect_cover_proxy(parent: Node2D, size: Vector2) -> void:
	var shadow := Polygon2D.new()
	shadow.color = Color(0.02, 0.04, 0.06, 0.34)
	shadow.z_index = 0
	var shadow_half := Vector2(size.x * 0.64, size.y * 0.46)
	shadow.position = Vector2(0.0, size.y * 0.36)
	shadow.polygon = PackedVector2Array([
		Vector2(-shadow_half.x, -shadow_half.y),
		Vector2(shadow_half.x, -shadow_half.y),
		Vector2(shadow_half.x * 1.08, shadow_half.y),
		Vector2(-shadow_half.x * 1.08, shadow_half.y)
	])
	parent.add_child(shadow)

	var body_poly := Polygon2D.new()
	body_poly.color = Color(0.40, 0.47, 0.54, 1.0)
	body_poly.z_index = 1
	var body_half := size * 0.5
	body_poly.polygon = PackedVector2Array([
		Vector2(-body_half.x, -body_half.y),
		Vector2(body_half.x, -body_half.y),
		Vector2(body_half.x, body_half.y),
		Vector2(-body_half.x, body_half.y)
	])
	parent.add_child(body_poly)

	var inset := Polygon2D.new()
	inset.color = Color(0.54, 0.60, 0.66, 0.96)
	inset.z_index = 2
	var inset_half := size * Vector2(0.38, 0.32)
	inset.position = Vector2(0.0, -size.y * 0.06)
	inset.polygon = PackedVector2Array([
		Vector2(-inset_half.x, -inset_half.y),
		Vector2(inset_half.x, -inset_half.y),
		Vector2(inset_half.x, inset_half.y),
		Vector2(-inset_half.x, inset_half.y)
	])
	parent.add_child(inset)

	var top_cap := Polygon2D.new()
	top_cap.color = Color(0.84, 0.90, 0.95, 0.94)
	top_cap.z_index = 3
	var top_half := Vector2(size.x * 0.44, 4.0)
	top_cap.position = Vector2(0.0, -body_half.y + 3.0)
	top_cap.polygon = PackedVector2Array([
		Vector2(-top_half.x, -top_half.y),
		Vector2(top_half.x, -top_half.y),
		Vector2(top_half.x * 1.06, top_half.y),
		Vector2(-top_half.x * 1.06, top_half.y)
	])
	parent.add_child(top_cap)

	var trim := Line2D.new()
	trim.z_index = 4
	trim.width = 3.0
	trim.closed = true
	trim.default_color = Color(0.90, 0.96, 1.0, 0.88)
	trim.points = PackedVector2Array([
		Vector2(-body_half.x, -body_half.y),
		Vector2(body_half.x, -body_half.y),
		Vector2(body_half.x, body_half.y),
		Vector2(-body_half.x, body_half.y)
	])
	parent.add_child(trim)


func _add_pillar_cover_proxy(parent: Node2D, radius: float) -> void:
	var points := PackedVector2Array()
	var shadow_points := PackedVector2Array()
	var outer_radius := radius * 1.02
	var inset_radius := radius * 0.68
	for index in range(8):
		var angle := TAU * float(index) / 8.0
		points.append(Vector2.RIGHT.rotated(angle) * outer_radius)
		shadow_points.append(Vector2.RIGHT.rotated(angle) * radius * 1.16 + Vector2(0.0, radius * 0.34))

	var shadow := Polygon2D.new()
	shadow.color = Color(0.02, 0.04, 0.06, 0.34)
	shadow.z_index = 0
	shadow.polygon = shadow_points
	parent.add_child(shadow)

	var body_poly := Polygon2D.new()
	body_poly.color = Color(0.40, 0.47, 0.54, 1.0)
	body_poly.z_index = 1
	body_poly.polygon = points
	parent.add_child(body_poly)

	var inset_points := PackedVector2Array()
	for index in range(8):
		var angle := TAU * float(index) / 8.0
		inset_points.append(Vector2.RIGHT.rotated(angle) * inset_radius + Vector2(0.0, -radius * 0.08))
	var inset := Polygon2D.new()
	inset.color = Color(0.54, 0.61, 0.68, 0.96)
	inset.z_index = 2
	inset.polygon = inset_points
	parent.add_child(inset)

	var top_cap := Polygon2D.new()
	top_cap.color = Color(0.84, 0.90, 0.95, 0.94)
	top_cap.z_index = 3
	top_cap.position = Vector2(0.0, -radius * 0.46)
	top_cap.polygon = PackedVector2Array([
		Vector2(radius * 0.54, 0.0),
		Vector2(radius * 0.32, radius * 0.26),
		Vector2(0.0, radius * 0.40),
		Vector2(-radius * 0.32, radius * 0.26),
		Vector2(-radius * 0.54, 0.0),
		Vector2(-radius * 0.32, -radius * 0.26),
		Vector2(0.0, -radius * 0.40),
		Vector2(radius * 0.32, -radius * 0.26)
	])
	parent.add_child(top_cap)

	var trim := Line2D.new()
	trim.z_index = 4
	trim.width = 2.5
	trim.closed = true
	trim.default_color = Color(0.90, 0.96, 1.0, 0.88)
	trim.points = points
	parent.add_child(trim)


func _resolve_room_open_sides(room_state: RoomState, extra_side: String = "") -> Array[String]:
	if room_state == null:
		return []
	var open_sides: Array[String] = []
	var floor_state = _get_current_floor()
	var visible_connections: Array[String] = []
	if floor_state != null:
		visible_connections = _get_visible_room_connections(room_state, floor_state)
		for anchor_name in _resolve_connection_anchor_names(room_state, floor_state, visible_connections):
			if not anchor_name.is_empty() and not open_sides.has(anchor_name):
				open_sides.append(anchor_name)
	if open_sides.is_empty():
		var connection_count := mini(
			visible_connections.size() if floor_state != null else room_state.connections.size(),
			4
		)
		if connection_count > 0:
			var anchor_names_variant: Variant = EXIT_ANCHOR_LAYOUTS.get(connection_count, EXIT_ANCHOR_LAYOUTS[4])
			if anchor_names_variant is Array:
				for anchor_variant in anchor_names_variant:
					var anchor_name := String(anchor_variant).strip_edges()
					if not anchor_name.is_empty() and not open_sides.has(anchor_name):
						open_sides.append(anchor_name)
	var normalized_extra := extra_side.strip_edges()
	if not normalized_extra.is_empty() and not open_sides.has(normalized_extra):
		open_sides.append(normalized_extra)
	return open_sides


func _resolve_connection_anchor_names(room_state: RoomState, floor_state, room_connections: Array[String] = []) -> Array[String]:
	var anchor_names: Array[String] = []
	if room_state == null or floor_state == null:
		return anchor_names
	var connections: Array[String] = room_connections.duplicate()
	if connections.is_empty():
		connections = _get_visible_room_connections(room_state, floor_state)
	if connections.is_empty():
		connections = room_state.connections.duplicate()
	var used: Array[String] = []
	for connection_index in range(connections.size()):
		var target_room_id := String(connections[connection_index]).strip_edges()
		var target_room: RoomState = floor_state.get_room(target_room_id)
		var chosen_anchor := ""
		if target_room != null:
			var delta := target_room.map_position - room_state.map_position
			for candidate in _anchor_candidates_for_delta(delta):
				if not used.has(candidate):
					chosen_anchor = candidate
					break
		if chosen_anchor.is_empty():
			var fallback_variant: Variant = EXIT_ANCHOR_LAYOUTS.get(mini(connections.size(), 4), EXIT_ANCHOR_LAYOUTS[4])
			if fallback_variant is Array:
				var fallback_names: Array = fallback_variant
				chosen_anchor = String(fallback_names[min(connection_index, fallback_names.size() - 1)]).strip_edges()
		if chosen_anchor.is_empty():
			chosen_anchor = "East"
		used.append(chosen_anchor)
		anchor_names.append(chosen_anchor)
	return anchor_names


func _anchor_candidates_for_delta(delta: Vector2) -> Array[String]:
	var candidates: Array[String] = []
	var dx := delta.x
	var dy := delta.y
	if absf(dx) > absf(dy):
		candidates.append("East" if dx >= 0.0 else "West")
		candidates.append("South" if dy >= 0.0 else "North")
	elif absf(dy) > absf(dx):
		candidates.append("South" if dy >= 0.0 else "North")
		candidates.append("East" if dx >= 0.0 else "West")
	else:
		if dy > 0.0:
			candidates.append("South")
		elif dy < 0.0:
			candidates.append("North")
		if dx > 0.0:
			candidates.append("East")
		elif dx < 0.0:
			candidates.append("West")
	if dx >= 0.0 and not candidates.has("East"):
		candidates.append("East")
	if dx < 0.0 and not candidates.has("West"):
		candidates.append("West")
	if dy >= 0.0 and not candidates.has("South"):
		candidates.append("South")
	if dy < 0.0 and not candidates.has("North"):
		candidates.append("North")
	for fallback_side in ["East", "North", "West", "South"]:
		if not candidates.has(fallback_side):
			candidates.append(fallback_side)
	return candidates


func _is_connection_hidden(room_state: RoomState, target_room_id: String, floor_state) -> bool:
	if room_state == null or floor_state == null:
		return false
	if not floor_state.has_method("get_connection_metadata"):
		return false
	var metadata_variant: Variant = floor_state.call("get_connection_metadata", room_state.room_id, target_room_id)
	var metadata: Dictionary = metadata_variant if metadata_variant is Dictionary else {}
	return bool(metadata.get("hidden", false))


func _is_hidden_room_revealed(room_id: String, floor_state) -> bool:
	var normalized_room_id := room_id.strip_edges()
	if normalized_room_id.is_empty() or floor_state == null:
		return false
	var room: RoomState = floor_state.get_room(normalized_room_id)
	if room == null:
		return false
	var metadata: Dictionary = room.metadata if room.metadata is Dictionary else {}
	if not bool(metadata.get("hidden_room", false)):
		return true
	if room.visited or _visited_room_ids.has(normalized_room_id):
		return true
	for source_room_id in floor_state.room_order:
		var source_room: RoomState = floor_state.get_room(String(source_room_id))
		if source_room == null:
			continue
		if not _is_connection_hidden(source_room, normalized_room_id, floor_state):
			continue
		if source_room.status == RoomState.STATUS_CLEARED:
			return true
	return false


func _get_visible_room_connections(room_state: RoomState, floor_state) -> Array[String]:
	var visible_connections: Array[String] = []
	if room_state == null:
		return visible_connections
	for target_room_id in room_state.connections:
		var normalized_target := String(target_room_id).strip_edges()
		if normalized_target.is_empty():
			continue
		if not _is_connection_hidden(room_state, normalized_target, floor_state):
			visible_connections.append(normalized_target)
			continue
		if _is_hidden_room_revealed(normalized_target, floor_state):
			visible_connections.append(normalized_target)
	return visible_connections


func _should_show_room_on_map(room: RoomState, floor_state) -> bool:
	if room == null:
		return false
	if _current_room != null and room.room_id == _current_room.room_id:
		return true
	if room.visited or _visited_room_ids.has(room.room_id):
		return true
	var metadata: Dictionary = room.metadata if room.metadata is Dictionary else {}
	if not bool(metadata.get("hidden_room", false)):
		return true
	return _is_hidden_room_revealed(room.room_id, floor_state)


func _add_shell_rect(parent: Node2D, node_name: String, position: Vector2, size: Vector2, color: Color, z_order: int) -> void:
	var polygon := Polygon2D.new()
	polygon.name = node_name
	polygon.position = position
	polygon.color = color
	polygon.z_index = z_order
	var half := size * 0.5
	polygon.polygon = PackedVector2Array([
		Vector2(-half.x, -half.y),
		Vector2(half.x, -half.y),
		Vector2(half.x, half.y),
		Vector2(-half.x, half.y)
	])
	parent.add_child(polygon)


func _add_outside_masks(parent: Node2D) -> void:
	var mask_color := Color(0.01, 0.02, 0.03, 0.72)
	var horizontal_extent := ROOM_OUTSIDE_MASK_EXTENT.x
	var vertical_extent := ROOM_OUTSIDE_MASK_EXTENT.y
	_add_shell_rect(parent, "OutsideMaskTop", Vector2(0.0, -ROOM_SHELL_BACKDROP_HALF_SIZE.y - vertical_extent * 0.5), Vector2(horizontal_extent * 2.0, vertical_extent), mask_color, -4)
	_add_shell_rect(parent, "OutsideMaskBottom", Vector2(0.0, ROOM_SHELL_BACKDROP_HALF_SIZE.y + vertical_extent * 0.5), Vector2(horizontal_extent * 2.0, vertical_extent), mask_color, -4)
	_add_shell_rect(parent, "OutsideMaskLeft", Vector2(-ROOM_SHELL_BACKDROP_HALF_SIZE.x - horizontal_extent * 0.5, 0.0), Vector2(horizontal_extent, ROOM_OUTSIDE_MASK_EXTENT.y * 2.0), mask_color, -4)
	_add_shell_rect(parent, "OutsideMaskRight", Vector2(ROOM_SHELL_BACKDROP_HALF_SIZE.x + horizontal_extent * 0.5, 0.0), Vector2(horizontal_extent, ROOM_OUTSIDE_MASK_EXTENT.y * 2.0), mask_color, -4)


func _add_shell_grid(parent: Node2D, half_size: Vector2, color: Color) -> void:
	var grid := Node2D.new()
	grid.name = "FloorGrid"
	grid.z_index = 1
	parent.add_child(grid)
	var cell_size := 88.0
	var x := -half_size.x
	while x <= half_size.x:
		var line := Line2D.new()
		line.width = 2.0
		line.default_color = Color(color.r, color.g, color.b, 0.12)
		line.points = PackedVector2Array([
			Vector2(x, -half_size.y),
			Vector2(x, half_size.y)
		])
		grid.add_child(line)
		x += cell_size
	var y := -half_size.y
	while y <= half_size.y:
		var line := Line2D.new()
		line.width = 2.0
		line.default_color = Color(color.r, color.g, color.b, 0.10)
		line.points = PackedVector2Array([
			Vector2(-half_size.x, y),
			Vector2(half_size.x, y)
		])
		grid.add_child(line)
		y += cell_size


func _add_floor_tiles(parent: Node2D, half_size: Vector2, color_a: Color, color_b: Color, grout_color: Color) -> void:
	var tile_root := Node2D.new()
	tile_root.name = "FloorTiles"
	tile_root.z_index = 1
	parent.add_child(tile_root)
	var step_x := ROOM_TILE_SIZE.x + ROOM_TILE_GAP
	var step_y := ROOM_TILE_SIZE.y + ROOM_TILE_GAP
	var start_x := -half_size.x + ROOM_TILE_SIZE.x * 0.5 + ROOM_TILE_GAP * 0.5
	var start_y := -half_size.y + ROOM_TILE_SIZE.y * 0.5 + ROOM_TILE_GAP * 0.5
	var row := 0
	var y := start_y
	while y <= half_size.y - ROOM_TILE_SIZE.y * 0.5:
		var column := 0
		var x := start_x + (step_x * 0.5 if row % 2 == 1 else 0.0)
		while x <= half_size.x - ROOM_TILE_SIZE.x * 0.5:
			var tile_color := color_a if ((row + column) % 2 == 0) else color_b
			_add_shell_rect(tile_root, "Tile_%d_%d" % [column, row], Vector2(x, y), ROOM_TILE_SIZE, tile_color, 1)
			var trim := Line2D.new()
			trim.name = "TileTrim_%d_%d" % [column, row]
			trim.width = 2.0
			trim.z_index = 2
			trim.closed = true
			trim.default_color = grout_color
			var half := ROOM_TILE_SIZE * 0.5
			trim.points = PackedVector2Array([
				Vector2(x - half.x, y - half.y),
				Vector2(x + half.x, y - half.y),
				Vector2(x + half.x, y + half.y),
				Vector2(x - half.x, y + half.y)
			])
			tile_root.add_child(trim)
			x += step_x
			column += 1
		y += step_y
		row += 1


func _add_wall_band(
	parent: Node2D,
	edge_name: String,
	axis: String,
	axis_position: float,
	half_length: float,
	thickness: float,
	door_half: float,
	color: Color,
	open_door: bool
) -> void:
	var bevel_color := color.lightened(0.08)
	if open_door:
		var segment_half_length := (half_length - door_half) * 0.5
		if axis == "horizontal":
			_add_shell_rect(parent, "%sWallLeft" % edge_name, Vector2(-(door_half + segment_half_length), axis_position), Vector2(segment_half_length * 2.0, thickness), color, 3)
			_add_shell_rect(parent, "%sWallRight" % edge_name, Vector2(door_half + segment_half_length, axis_position), Vector2(segment_half_length * 2.0, thickness), color, 3)
			_add_shell_rect(parent, "%sWallLeftBevel" % edge_name, Vector2(-(door_half + segment_half_length), axis_position - thickness * 0.24), Vector2(segment_half_length * 2.0, 12.0), bevel_color, 4)
			_add_shell_rect(parent, "%sWallRightBevel" % edge_name, Vector2(door_half + segment_half_length, axis_position - thickness * 0.24), Vector2(segment_half_length * 2.0, 12.0), bevel_color, 4)
		else:
			_add_shell_rect(parent, "%sWallTop" % edge_name, Vector2(axis_position, -(door_half + segment_half_length)), Vector2(thickness, segment_half_length * 2.0), color, 3)
			_add_shell_rect(parent, "%sWallBottom" % edge_name, Vector2(axis_position, door_half + segment_half_length), Vector2(thickness, segment_half_length * 2.0), color, 3)
			_add_shell_rect(parent, "%sWallTopBevel" % edge_name, Vector2(axis_position - thickness * 0.24, -(door_half + segment_half_length)), Vector2(12.0, segment_half_length * 2.0), bevel_color, 4)
			_add_shell_rect(parent, "%sWallBottomBevel" % edge_name, Vector2(axis_position - thickness * 0.24, door_half + segment_half_length), Vector2(12.0, segment_half_length * 2.0), bevel_color, 4)
		return
	if axis == "horizontal":
		_add_shell_rect(parent, "%sWallFull" % edge_name, Vector2(0.0, axis_position), Vector2(half_length * 2.0, thickness), color, 3)
		_add_shell_rect(parent, "%sWallBevel" % edge_name, Vector2(0.0, axis_position - thickness * 0.24), Vector2(half_length * 2.0, 12.0), bevel_color, 4)
	else:
		_add_shell_rect(parent, "%sWallFull" % edge_name, Vector2(axis_position, 0.0), Vector2(thickness, half_length * 2.0), color, 3)
		_add_shell_rect(parent, "%sWallBevel" % edge_name, Vector2(axis_position - thickness * 0.24, 0.0), Vector2(12.0, half_length * 2.0), bevel_color, 4)


func _add_corner_blocks(parent: Node2D, color: Color) -> void:
	var corner_half := ROOM_SHELL_HALF_SIZE - ROOM_SHELL_CORNER_SIZE * 0.5
	for corner in [
		Vector2(-corner_half.x, -corner_half.y),
		Vector2(corner_half.x, -corner_half.y),
		Vector2(-corner_half.x, corner_half.y),
		Vector2(corner_half.x, corner_half.y)
		]:
			_add_shell_rect(parent, "CornerBlock_%s_%s" % [int(corner.x), int(corner.y)], corner, ROOM_SHELL_CORNER_SIZE, color.darkened(0.10), 5)
			_add_shell_rect(parent, "CornerCap_%s_%s" % [int(corner.x), int(corner.y)], corner + Vector2(-signf(corner.x) * 8.0, -signf(corner.y) * 8.0), ROOM_SHELL_CORNER_SIZE * 0.62, color.lightened(0.06), 6)


func _add_corner_shadows(parent: Node2D, shadow_color: Color) -> void:
	var shadow_root := Node2D.new()
	shadow_root.name = "CornerShadows"
	shadow_root.z_index = 2
	parent.add_child(shadow_root)
	var inner_color := Color(shadow_color.r, shadow_color.g, shadow_color.b, 0.18)
	for direction in [
		Vector2(-1.0, -1.0),
		Vector2(1.0, -1.0),
		Vector2(-1.0, 1.0),
		Vector2(1.0, 1.0)
	]:
		var corner := Vector2(ROOM_SHELL_INNER_HALF_SIZE.x * direction.x, ROOM_SHELL_INNER_HALF_SIZE.y * direction.y)
		var outer_shadow := Polygon2D.new()
		outer_shadow.name = "CornerShadowOuter_%s_%s" % [int(direction.x), int(direction.y)]
		outer_shadow.color = shadow_color
		outer_shadow.z_index = 2
		outer_shadow.polygon = PackedVector2Array([
			corner,
			corner + Vector2(-direction.x * ROOM_CORNER_SHADOW_SIZE.x, 0.0),
			corner + Vector2(0.0, -direction.y * ROOM_CORNER_SHADOW_SIZE.y)
		])
		shadow_root.add_child(outer_shadow)
		var inner_shadow := Polygon2D.new()
		inner_shadow.name = "CornerShadowInner_%s_%s" % [int(direction.x), int(direction.y)]
		inner_shadow.color = inner_color
		inner_shadow.z_index = 3
		inner_shadow.polygon = PackedVector2Array([
			corner,
			corner + Vector2(-direction.x * ROOM_CORNER_SHADOW_SIZE.x * 0.54, 0.0),
			corner + Vector2(0.0, -direction.y * ROOM_CORNER_SHADOW_SIZE.y * 0.54)
		])
		shadow_root.add_child(inner_shadow)


func _add_door_caps(parent: Node2D, color: Color, open_sides: Array[String]) -> void:
	if open_sides.has("North"):
		_add_shell_rect(parent, "NorthDoorCap", Vector2(0.0, -ROOM_SHELL_HALF_SIZE.y + ROOM_SHELL_WALL_THICKNESS * 0.55), Vector2(ROOM_SHELL_DOOR_HALF_WIDTH * 1.68, 16.0), color, 6)
	if open_sides.has("South"):
		_add_shell_rect(parent, "SouthDoorCap", Vector2(0.0, ROOM_SHELL_HALF_SIZE.y - ROOM_SHELL_WALL_THICKNESS * 0.55), Vector2(ROOM_SHELL_DOOR_HALF_WIDTH * 1.68, 16.0), color, 6)
	if open_sides.has("West"):
		_add_shell_rect(parent, "WestDoorCap", Vector2(-ROOM_SHELL_HALF_SIZE.x + ROOM_SHELL_WALL_THICKNESS * 0.55, 0.0), Vector2(16.0, ROOM_SHELL_DOOR_HALF_HEIGHT * 1.68), color, 6)
	if open_sides.has("East"):
		_add_shell_rect(parent, "EastDoorCap", Vector2(ROOM_SHELL_HALF_SIZE.x - ROOM_SHELL_WALL_THICKNESS * 0.55, 0.0), Vector2(16.0, ROOM_SHELL_DOOR_HALF_HEIGHT * 1.68), color, 6)


func _add_corridor_stubs(parent: Node2D, open_sides: Array[String], floor_color: Color, rail_color: Color, trim_color: Color) -> void:
	var corridor_root := Node2D.new()
	corridor_root.name = "CorridorStubs"
	corridor_root.z_index = 4
	parent.add_child(corridor_root)
	for side in open_sides:
		match side:
			"North":
				var size_n := Vector2(ROOM_SHELL_DOOR_HALF_WIDTH * ROOM_CORRIDOR_STUB_WIDTH_MULT * 2.0, ROOM_CORRIDOR_STUB_LENGTH)
				var pos_n := Vector2(0.0, -ROOM_SHELL_HALF_SIZE.y - size_n.y * 0.5 + 18.0)
				_add_shell_rect(corridor_root, "NorthCorridorFloor", pos_n, size_n, floor_color, 4)
				_add_shell_rect(corridor_root, "NorthCorridorRailLeft", pos_n + Vector2(-size_n.x * 0.5 + ROOM_CORRIDOR_RAIL_THICKNESS * 0.5, 0.0), Vector2(ROOM_CORRIDOR_RAIL_THICKNESS, size_n.y), rail_color, 5)
				_add_shell_rect(corridor_root, "NorthCorridorRailRight", pos_n + Vector2(size_n.x * 0.5 - ROOM_CORRIDOR_RAIL_THICKNESS * 0.5, 0.0), Vector2(ROOM_CORRIDOR_RAIL_THICKNESS, size_n.y), rail_color, 5)
				_add_shell_rect(corridor_root, "NorthCorridorTrim", pos_n + Vector2(0.0, -size_n.y * 0.5 + 8.0), Vector2(size_n.x, 8.0), trim_color, 6)
			"South":
				var size_s := Vector2(ROOM_SHELL_DOOR_HALF_WIDTH * ROOM_CORRIDOR_STUB_WIDTH_MULT * 2.0, ROOM_CORRIDOR_STUB_LENGTH)
				var pos_s := Vector2(0.0, ROOM_SHELL_HALF_SIZE.y + size_s.y * 0.5 - 18.0)
				_add_shell_rect(corridor_root, "SouthCorridorFloor", pos_s, size_s, floor_color, 4)
				_add_shell_rect(corridor_root, "SouthCorridorRailLeft", pos_s + Vector2(-size_s.x * 0.5 + ROOM_CORRIDOR_RAIL_THICKNESS * 0.5, 0.0), Vector2(ROOM_CORRIDOR_RAIL_THICKNESS, size_s.y), rail_color, 5)
				_add_shell_rect(corridor_root, "SouthCorridorRailRight", pos_s + Vector2(size_s.x * 0.5 - ROOM_CORRIDOR_RAIL_THICKNESS * 0.5, 0.0), Vector2(ROOM_CORRIDOR_RAIL_THICKNESS, size_s.y), rail_color, 5)
				_add_shell_rect(corridor_root, "SouthCorridorTrim", pos_s + Vector2(0.0, size_s.y * 0.5 - 8.0), Vector2(size_s.x, 8.0), trim_color, 6)
			"West":
				var size_w := Vector2(ROOM_CORRIDOR_STUB_LENGTH, ROOM_SHELL_DOOR_HALF_HEIGHT * ROOM_CORRIDOR_STUB_WIDTH_MULT * 2.0)
				var pos_w := Vector2(-ROOM_SHELL_HALF_SIZE.x - size_w.x * 0.5 + 18.0, 0.0)
				_add_shell_rect(corridor_root, "WestCorridorFloor", pos_w, size_w, floor_color, 4)
				_add_shell_rect(corridor_root, "WestCorridorRailTop", pos_w + Vector2(0.0, -size_w.y * 0.5 + ROOM_CORRIDOR_RAIL_THICKNESS * 0.5), Vector2(size_w.x, ROOM_CORRIDOR_RAIL_THICKNESS), rail_color, 5)
				_add_shell_rect(corridor_root, "WestCorridorRailBottom", pos_w + Vector2(0.0, size_w.y * 0.5 - ROOM_CORRIDOR_RAIL_THICKNESS * 0.5), Vector2(size_w.x, ROOM_CORRIDOR_RAIL_THICKNESS), rail_color, 5)
				_add_shell_rect(corridor_root, "WestCorridorTrim", pos_w + Vector2(-size_w.x * 0.5 + 8.0, 0.0), Vector2(8.0, size_w.y), trim_color, 6)
			"East":
				var size_e := Vector2(ROOM_CORRIDOR_STUB_LENGTH, ROOM_SHELL_DOOR_HALF_HEIGHT * ROOM_CORRIDOR_STUB_WIDTH_MULT * 2.0)
				var pos_e := Vector2(ROOM_SHELL_HALF_SIZE.x + size_e.x * 0.5 - 18.0, 0.0)
				_add_shell_rect(corridor_root, "EastCorridorFloor", pos_e, size_e, floor_color, 4)
				_add_shell_rect(corridor_root, "EastCorridorRailTop", pos_e + Vector2(0.0, -size_e.y * 0.5 + ROOM_CORRIDOR_RAIL_THICKNESS * 0.5), Vector2(size_e.x, ROOM_CORRIDOR_RAIL_THICKNESS), rail_color, 5)
				_add_shell_rect(corridor_root, "EastCorridorRailBottom", pos_e + Vector2(0.0, size_e.y * 0.5 - ROOM_CORRIDOR_RAIL_THICKNESS * 0.5), Vector2(size_e.x, ROOM_CORRIDOR_RAIL_THICKNESS), rail_color, 5)
				_add_shell_rect(corridor_root, "EastCorridorTrim", pos_e + Vector2(size_e.x * 0.5 - 8.0, 0.0), Vector2(8.0, size_e.y), trim_color, 6)


func _add_doorway_planks(parent: Node2D, open_sides: Array[String], base_color: Color, board_color: Color, rail_color: Color) -> void:
	var plank_root := Node2D.new()
	plank_root.name = "DoorwayPlanks"
	plank_root.z_index = 6
	parent.add_child(plank_root)
	for side in open_sides:
		match side:
			"North":
				_add_horizontal_doorway_plank_set(plank_root, "North", Vector2(0.0, -ROOM_SHELL_HALF_SIZE.y + ROOM_DOORWAY_PLANK_DEPTH * 0.62), base_color, board_color, rail_color)
			"South":
				_add_horizontal_doorway_plank_set(plank_root, "South", Vector2(0.0, ROOM_SHELL_HALF_SIZE.y - ROOM_DOORWAY_PLANK_DEPTH * 0.62), base_color.darkened(0.06), board_color, rail_color)
			"West":
				_add_vertical_doorway_plank_set(plank_root, "West", Vector2(-ROOM_SHELL_HALF_SIZE.x + ROOM_DOORWAY_PLANK_DEPTH * 0.62, 0.0), base_color, board_color, rail_color)
			"East":
				_add_vertical_doorway_plank_set(plank_root, "East", Vector2(ROOM_SHELL_HALF_SIZE.x - ROOM_DOORWAY_PLANK_DEPTH * 0.62, 0.0), base_color, board_color, rail_color)


func _add_horizontal_doorway_plank_set(parent: Node2D, side_name: String, position: Vector2, base_color: Color, board_color: Color, rail_color: Color) -> void:
	var deck_width := ROOM_SHELL_DOOR_HALF_WIDTH * ROOM_DOORWAY_PLANK_WIDTH_MULT * 2.0
	var deck_size := Vector2(deck_width, ROOM_DOORWAY_PLANK_DEPTH)
	_add_shell_rect(parent, "%sPlankDeck" % side_name, position, deck_size, base_color, 6)
	_add_shell_rect(parent, "%sPlankRailNorth" % side_name, position + Vector2(0.0, -deck_size.y * 0.5 + ROOM_DOORWAY_RAIL_THICKNESS * 0.5), Vector2(deck_size.x, ROOM_DOORWAY_RAIL_THICKNESS), rail_color, 7)
	_add_shell_rect(parent, "%sPlankRailSouth" % side_name, position + Vector2(0.0, deck_size.y * 0.5 - ROOM_DOORWAY_RAIL_THICKNESS * 0.5), Vector2(deck_size.x, ROOM_DOORWAY_RAIL_THICKNESS), rail_color, 7)
	var board_y := position.y - deck_size.y * 0.5 + ROOM_DOORWAY_RAIL_THICKNESS + ROOM_DOORWAY_BOARD_THICKNESS * 0.5
	var max_y := position.y + deck_size.y * 0.5 - ROOM_DOORWAY_RAIL_THICKNESS - ROOM_DOORWAY_BOARD_THICKNESS * 0.5
	var board_index := 0
	while board_y <= max_y:
		var board := Polygon2D.new()
		board.name = "%sPlankBoard_%d" % [side_name, board_index]
		board.position = Vector2(position.x, board_y)
		board.color = board_color.darkened(0.03 * float(board_index % 2))
		board.z_index = 8
		var half := Vector2(deck_size.x * 0.5 - ROOM_DOORWAY_RAIL_THICKNESS * 0.6, ROOM_DOORWAY_BOARD_THICKNESS * 0.5)
		board.polygon = PackedVector2Array([
			Vector2(-half.x, -half.y),
			Vector2(half.x, -half.y),
			Vector2(half.x, half.y),
			Vector2(-half.x, half.y)
		])
		parent.add_child(board)
		board_y += ROOM_DOORWAY_BOARD_THICKNESS + ROOM_DOORWAY_BOARD_GAP
		board_index += 1


func _add_vertical_doorway_plank_set(parent: Node2D, side_name: String, position: Vector2, base_color: Color, board_color: Color, rail_color: Color) -> void:
	var deck_height := ROOM_SHELL_DOOR_HALF_HEIGHT * ROOM_DOORWAY_PLANK_WIDTH_MULT * 2.0
	var deck_size := Vector2(ROOM_DOORWAY_PLANK_DEPTH, deck_height)
	_add_shell_rect(parent, "%sPlankDeck" % side_name, position, deck_size, base_color, 6)
	_add_shell_rect(parent, "%sPlankRailWest" % side_name, position + Vector2(-deck_size.x * 0.5 + ROOM_DOORWAY_RAIL_THICKNESS * 0.5, 0.0), Vector2(ROOM_DOORWAY_RAIL_THICKNESS, deck_size.y), rail_color, 7)
	_add_shell_rect(parent, "%sPlankRailEast" % side_name, position + Vector2(deck_size.x * 0.5 - ROOM_DOORWAY_RAIL_THICKNESS * 0.5, 0.0), Vector2(ROOM_DOORWAY_RAIL_THICKNESS, deck_size.y), rail_color, 7)
	var board_x := position.x - deck_size.x * 0.5 + ROOM_DOORWAY_RAIL_THICKNESS + ROOM_DOORWAY_BOARD_THICKNESS * 0.5
	var max_x := position.x + deck_size.x * 0.5 - ROOM_DOORWAY_RAIL_THICKNESS - ROOM_DOORWAY_BOARD_THICKNESS * 0.5
	var board_index := 0
	while board_x <= max_x:
		var board := Polygon2D.new()
		board.name = "%sPlankBoard_%d" % [side_name, board_index]
		board.position = Vector2(board_x, position.y)
		board.color = board_color.darkened(0.03 * float(board_index % 2))
		board.z_index = 8
		var half := Vector2(ROOM_DOORWAY_BOARD_THICKNESS * 0.5, deck_size.y * 0.5 - ROOM_DOORWAY_RAIL_THICKNESS * 0.6)
		board.polygon = PackedVector2Array([
			Vector2(-half.x, -half.y),
			Vector2(half.x, -half.y),
			Vector2(half.x, half.y),
			Vector2(-half.x, half.y)
		])
		parent.add_child(board)
		board_x += ROOM_DOORWAY_BOARD_THICKNESS + ROOM_DOORWAY_BOARD_GAP
		board_index += 1


func _gather_exit_snapshots(exit_nodes: Array) -> Array[Dictionary]:
	var snapshots: Array[Dictionary] = []
	for exit_node in exit_nodes:
		if exit_node == null or not is_instance_valid(exit_node):
			continue
		if not exit_node.has_method("get_snapshot"):
			continue
		var snapshot_variant: Variant = exit_node.call("get_snapshot")
		if snapshot_variant is Dictionary:
			snapshots.append((snapshot_variant as Dictionary).duplicate(true))
	return snapshots


func _refresh_runtime_door_state() -> void:
	if _active_room_node == null or not is_instance_valid(_active_room_node) or _current_room == null:
		return
	_refresh_runtime_door_state_for_node(
		_active_room_node,
		_current_room,
		_gather_exit_snapshots(_active_exit_nodes),
		_current_room_entry_anchor_side,
		false
	)


func _refresh_runtime_door_state_for_node(
	room_node: Node2D,
	room_state: RoomState,
	exit_snapshots: Array[Dictionary] = [],
	entry_anchor_side: String = "",
	force_open_entry: bool = false
) -> void:
	if room_node == null or room_state == null:
		return
	var shell_root := room_node.get_node_or_null(ROOM_SHELL_NODE_NAME)
	if shell_root == null:
		return
	var existing_root := shell_root.get_node_or_null("DoorState")
	if existing_root != null:
		shell_root.remove_child(existing_root)
		existing_root.queue_free()
	var visible_sides := _resolve_room_open_sides(room_state, entry_anchor_side)
	if visible_sides.is_empty():
		return
	var lock_by_side: Dictionary = {}
	for exit_snapshot in exit_snapshots:
		var side_name := String(exit_snapshot.get("anchor_side", "")).strip_edges()
		if side_name.is_empty():
			continue
		lock_by_side[side_name] = bool(exit_snapshot.get("locked", false))
	var door_root := Node2D.new()
	door_root.name = "DoorState"
	door_root.z_index = 9
	shell_root.add_child(door_root)
	for side_name in visible_sides:
		var has_forward_exit := lock_by_side.has(side_name)
		var locked := false
		if has_forward_exit:
			locked = bool(lock_by_side.get(side_name, false))
		elif side_name == entry_anchor_side:
			locked = not force_open_entry
		elif room_state.locks_on_entry and room_state.status != RoomState.STATUS_CLEARED:
			locked = true
		_add_room_door_state_visual(door_root, side_name, locked)


func _add_room_door_state_visual(parent: Node2D, side_name: String, locked: bool) -> void:
	var normalized_side := side_name.strip_edges()
	var door_width := ROOM_SHELL_DOOR_HALF_WIDTH * 1.84
	var door_height := ROOM_SHELL_DOOR_HALF_HEIGHT * 1.84
	match normalized_side:
		"North":
			if locked:
				_add_horizontal_closed_door(parent, normalized_side, Vector2(0.0, -ROOM_SHELL_HALF_SIZE.y + ROOM_SHELL_WALL_THICKNESS * 0.18), door_width)
			else:
				_add_horizontal_open_door(parent, normalized_side, Vector2(0.0, -ROOM_SHELL_HALF_SIZE.y + ROOM_DOOR_PANEL_DEPTH * 0.42), door_width)
		"South":
			if locked:
				_add_horizontal_closed_door(parent, normalized_side, Vector2(0.0, ROOM_SHELL_HALF_SIZE.y - ROOM_SHELL_WALL_THICKNESS * 0.18), door_width)
			else:
				_add_horizontal_open_door(parent, normalized_side, Vector2(0.0, ROOM_SHELL_HALF_SIZE.y - ROOM_DOOR_PANEL_DEPTH * 0.42), door_width)
		"West":
			if locked:
				_add_vertical_closed_door(parent, normalized_side, Vector2(-ROOM_SHELL_HALF_SIZE.x + ROOM_SHELL_WALL_THICKNESS * 0.18, 0.0), door_height)
			else:
				_add_vertical_open_door(parent, normalized_side, Vector2(-ROOM_SHELL_HALF_SIZE.x + ROOM_DOOR_PANEL_DEPTH * 0.42, 0.0), door_height)
		"East":
			if locked:
				_add_vertical_closed_door(parent, normalized_side, Vector2(ROOM_SHELL_HALF_SIZE.x - ROOM_SHELL_WALL_THICKNESS * 0.18, 0.0), door_height)
			else:
				_add_vertical_open_door(parent, normalized_side, Vector2(ROOM_SHELL_HALF_SIZE.x - ROOM_DOOR_PANEL_DEPTH * 0.42, 0.0), door_height)


func _add_horizontal_closed_door(parent: Node2D, side_name: String, center: Vector2, door_width: float) -> void:
	var gate_color := Color(0.22, 0.27, 0.32, 0.98)
	var slat_color := Color(0.56, 0.63, 0.71, 0.96)
	var glow_color := Color(0.98, 0.72, 0.44, 0.16)
	_add_shell_rect(parent, "DoorClosed_%s_Core" % side_name, center, Vector2(door_width, ROOM_DOOR_PANEL_THICKNESS), gate_color, 9)
	_add_shell_rect(parent, "DoorClosed_%s_Seal" % side_name, center, Vector2(door_width * 0.86, ROOM_DOOR_CENTER_SEAL), glow_color, 10)
	var slat_step := door_width / 6.0
	for slat_index in range(5):
		var x_offset := -door_width * 0.5 + slat_step * float(slat_index + 1)
		_add_shell_rect(parent, "DoorClosed_%s_Slat_%d" % [side_name, slat_index], center + Vector2(x_offset, 0.0), Vector2(ROOM_DOOR_POST_THICKNESS, ROOM_DOOR_PANEL_THICKNESS + 18.0), slat_color, 10)


func _add_vertical_closed_door(parent: Node2D, side_name: String, center: Vector2, door_height: float) -> void:
	var gate_color := Color(0.22, 0.27, 0.32, 0.98)
	var slat_color := Color(0.56, 0.63, 0.71, 0.96)
	var glow_color := Color(0.98, 0.72, 0.44, 0.16)
	_add_shell_rect(parent, "DoorClosed_%s_Core" % side_name, center, Vector2(ROOM_DOOR_PANEL_THICKNESS, door_height), gate_color, 9)
	_add_shell_rect(parent, "DoorClosed_%s_Seal" % side_name, center, Vector2(ROOM_DOOR_CENTER_SEAL, door_height * 0.86), glow_color, 10)
	var slat_step := door_height / 6.0
	for slat_index in range(5):
		var y_offset := -door_height * 0.5 + slat_step * float(slat_index + 1)
		_add_shell_rect(parent, "DoorClosed_%s_Slat_%d" % [side_name, slat_index], center + Vector2(0.0, y_offset), Vector2(ROOM_DOOR_PANEL_THICKNESS + 18.0, ROOM_DOOR_POST_THICKNESS), slat_color, 10)


func _add_horizontal_open_door(parent: Node2D, side_name: String, center: Vector2, door_width: float) -> void:
	var panel_color := Color(0.44, 0.34, 0.24, 0.98)
	var trim_color := Color(0.83, 0.90, 0.96, 0.78)
	var glow_color := Color(0.40, 0.86, 1.0, 0.20)
	var wing_half := Vector2(ROOM_DOOR_PANEL_THICKNESS * 0.5, ROOM_DOOR_PANEL_DEPTH * 0.5)
	var wing_x := door_width * 0.5 - wing_half.x
	_add_shell_rect(parent, "DoorOpen_%s_LeftWing" % side_name, center + Vector2(-wing_x, 0.0), wing_half * 2.0, panel_color, 9)
	_add_shell_rect(parent, "DoorOpen_%s_RightWing" % side_name, center + Vector2(wing_x, 0.0), wing_half * 2.0, panel_color.darkened(0.05), 9)
	_add_shell_rect(parent, "DoorOpen_%s_LeftTrim" % side_name, center + Vector2(-wing_x, 0.0), Vector2(ROOM_DOOR_GLOW_THICKNESS, ROOM_DOOR_PANEL_DEPTH * 0.86), trim_color, 10)
	_add_shell_rect(parent, "DoorOpen_%s_RightTrim" % side_name, center + Vector2(wing_x, 0.0), Vector2(ROOM_DOOR_GLOW_THICKNESS, ROOM_DOOR_PANEL_DEPTH * 0.86), trim_color, 10)
	_add_shell_rect(parent, "DoorOpen_%s_Glow" % side_name, center, Vector2(door_width * 0.72, ROOM_DOOR_GLOW_THICKNESS), glow_color, 8)


func _add_vertical_open_door(parent: Node2D, side_name: String, center: Vector2, door_height: float) -> void:
	var panel_color := Color(0.44, 0.34, 0.24, 0.98)
	var trim_color := Color(0.83, 0.90, 0.96, 0.78)
	var glow_color := Color(0.40, 0.86, 1.0, 0.20)
	var wing_half := Vector2(ROOM_DOOR_PANEL_DEPTH * 0.5, ROOM_DOOR_PANEL_THICKNESS * 0.5)
	var wing_y := door_height * 0.5 - wing_half.y
	_add_shell_rect(parent, "DoorOpen_%s_TopWing" % side_name, center + Vector2(0.0, -wing_y), wing_half * 2.0, panel_color, 9)
	_add_shell_rect(parent, "DoorOpen_%s_BottomWing" % side_name, center + Vector2(0.0, wing_y), wing_half * 2.0, panel_color.darkened(0.05), 9)
	_add_shell_rect(parent, "DoorOpen_%s_TopTrim" % side_name, center + Vector2(0.0, -wing_y), Vector2(ROOM_DOOR_PANEL_DEPTH * 0.86, ROOM_DOOR_GLOW_THICKNESS), trim_color, 10)
	_add_shell_rect(parent, "DoorOpen_%s_BottomTrim" % side_name, center + Vector2(0.0, wing_y), Vector2(ROOM_DOOR_PANEL_DEPTH * 0.86, ROOM_DOOR_GLOW_THICKNESS), trim_color, 10)
	_add_shell_rect(parent, "DoorOpen_%s_Glow" % side_name, center, Vector2(ROOM_DOOR_GLOW_THICKNESS, door_height * 0.72), glow_color, 8)


func _add_shell_outline(parent: Node2D, color: Color) -> void:
	var outline := Line2D.new()
	outline.name = "ShellOutline"
	outline.width = 12.0
	outline.default_color = color
	outline.closed = true
	outline.z_index = 8
	outline.points = PackedVector2Array([
		Vector2(-ROOM_SHELL_HALF_SIZE.x, -ROOM_SHELL_HALF_SIZE.y),
		Vector2(ROOM_SHELL_HALF_SIZE.x, -ROOM_SHELL_HALF_SIZE.y),
		Vector2(ROOM_SHELL_HALF_SIZE.x, ROOM_SHELL_HALF_SIZE.y),
		Vector2(-ROOM_SHELL_HALF_SIZE.x, ROOM_SHELL_HALF_SIZE.y)
	])
	parent.add_child(outline)


func _resolve_room_mount() -> Node:
	if _world == null or not is_instance_valid(_world):
		return self
	if _world.has_method("get_runtime_room_root"):
		var root_variant: Variant = _world.call("get_runtime_room_root")
		if root_variant is Node:
			return root_variant
	return _world


func _clear_active_exit_nodes() -> void:
	for exit_node in _active_exit_nodes:
		if exit_node == null or not is_instance_valid(exit_node):
			continue
		exit_node.queue_free()
	_active_exit_nodes.clear()


func _spawn_exit_nodes(room_state: RoomState) -> void:
	_clear_active_exit_nodes()
	if _active_room_node == null:
		return
	var floor_state = _get_current_floor()
	if floor_state == null:
		return
	var connections: Array[String] = _get_visible_room_connections(room_state, floor_state)
	if connections.is_empty():
		return
	var anchor_root := _active_room_node.get_node_or_null("ExitAnchors")
	var anchor_names: Array[String] = _resolve_connection_anchor_names(room_state, floor_state, connections)
	for index in range(connections.size()):
		var target_room_id := connections[index]
		var anchor_name := String(anchor_names[min(index, anchor_names.size() - 1)] if not anchor_names.is_empty() else "East")
		var anchor := _find_named_child(anchor_root, anchor_name)
		var exit_node := RoomExitClass.new()
		var target_room: RoomState = floor_state.get_room(target_room_id)
		exit_node.position = (anchor as Node2D).position if anchor is Node2D else Vector2.ZERO
		exit_node.configure(
			"%s_exit_%d" % [room_state.room_id, index],
			target_room_id,
			target_room.label if target_room != null else target_room_id,
			anchor_name,
			target_room.room_type_id if target_room != null else "",
			target_room.status if target_room != null else RoomState.STATUS_UNEXPLORED,
			room_state.locks_on_entry and room_state.status != RoomState.STATUS_CLEARED,
			target_room.exit_color if target_room != null else Color(0.44, 0.76, 0.92, 1.0)
		)
		exit_node.exit_selected.connect(_on_exit_selected)
		_active_room_node.add_child(exit_node)
		_active_exit_nodes.append(exit_node)
	_refresh_runtime_door_state()


func _lock_active_exits(locked: bool) -> void:
	for exit_node in _active_exit_nodes:
		if exit_node == null or not is_instance_valid(exit_node):
			continue
		if exit_node.has_method("set_locked"):
			exit_node.call("set_locked", locked)
	_refresh_runtime_door_state()


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


func _start_room_objective(payload: Dictionary) -> void:
	_objective_runtime_controller.begin_room(_active_room_node, payload, _build_objective_runtime_context())


func _update_room_objective(delta: float) -> void:
	var result := _objective_runtime_controller.update(delta, _build_objective_runtime_context())
	if not result.is_empty():
		_handle_objective_runtime_result(result)
	elif _run_state == STATE_ROOM_LOCKED:
		_update_ui()


func _complete_room_objective(force_clear: bool = false) -> void:
	var result := _objective_runtime_controller.complete_objective(force_clear, _build_objective_runtime_context())
	_handle_objective_runtime_result(result)


func _clear_room_objective_runtime() -> void:
	_objective_runtime_controller.clear_runtime(_build_objective_runtime_context())


func _has_active_objective() -> bool:
	return _objective_runtime_controller.has_active_objective()


func _should_defer_room_resolution() -> bool:
	return _objective_runtime_controller.should_defer_room_resolution()


func _sync_objective_hold_open() -> void:
	_objective_runtime_controller.sync_hold_open(_build_objective_runtime_context())


func _get_objective_node_count() -> int:
	return _objective_runtime_controller.get_objective_node_count()


func _resolve_objective_status_text() -> String:
	return _objective_runtime_controller.get_status_text()


func _on_room_objective_node_destroyed(_objective_id: String) -> void:
	var result := _objective_runtime_controller.handle_objective_node_destroyed(_objective_id, _build_objective_runtime_context())
	if not result.is_empty():
		_handle_objective_runtime_result(result)
	elif _run_state == STATE_ROOM_LOCKED:
		_update_ui()


func _build_objective_runtime_context() -> Dictionary:
	return {
		"room_id": _current_room.room_id if _current_room != null else "",
		"player": _get_player(),
		"enemy_manager": _enemy_manager,
		"objective_root_name": ROOM_OBJECTIVE_ROOT_NODE_NAME,
		"objective_root_z_index": ROOM_COVER_PROXY_LAYER_Z + 2,
		"objective_destroyed_callback": Callable(self, "_on_room_objective_node_destroyed")
	}


func _handle_objective_runtime_result(result: Dictionary) -> void:
	if result.is_empty():
		return
	var materials_variant: Variant = result.get("success_bonus_materials", {})
	if materials_variant is Dictionary and _extraction_controller != null:
		_extraction_controller.record_bonus_materials(materials_variant)
	if bool(result.get("handled_by_enemy_manager", false)):
		_update_ui()
		return
	if bool(result.get("should_mark_room_cleared", false)):
		_mark_current_room_cleared()
		if _current_room != null and _current_room.reward_on_enter and not _current_room.reward_claimed:
			_claim_room_reward(_current_room)
		if _present_room_clear_rewards():
			_update_ui()
			return
		if _current_room != null and _current_room.is_goal and _current_room.connections.is_empty():
			_complete_or_advance_floor()
		else:
			_last_room_note = _tr("night.run.note.choose_door")
			_update_ui()
		return
	_update_ui()


func _duplicate_dictionary(value: Variant) -> Dictionary:
	return value.duplicate(true) if value is Dictionary else {}


func _duplicate_dictionary_array(value: Variant) -> Array:
	var rows: Array = []
	if not (value is Array):
		return rows
	for row_variant in value:
		if row_variant is Dictionary:
			rows.append((row_variant as Dictionary).duplicate(true))
	return rows


func _duplicate_string_array(value: Variant) -> Array[String]:
	var rows: Array[String] = []
	if not (value is Array):
		return rows
	for row_variant in value:
		var normalized := String(row_variant).strip_edges()
		if normalized.is_empty():
			continue
		rows.append(normalized)
	return rows


func _coerce_vector2(value: Variant) -> Vector2:
	if value is Vector2:
		return value
	if value is Array:
		var parts: Array = value
		if parts.size() >= 2:
			return Vector2(float(parts[0]), float(parts[1]))
	if value is Dictionary:
		var payload: Dictionary = value
		return Vector2(float(payload.get("x", 0.0)), float(payload.get("y", 0.0)))
	return Vector2.ZERO


func _begin_room_transition(target_room_id: String, anchor_side: String) -> void:
	if _completion_emitted or _current_room == null:
		return
	var floor_state = _get_current_floor()
	if floor_state == null or not floor_state.has_room(target_room_id):
		return
	var target_room: RoomState = floor_state.get_room(target_room_id)
	if target_room == null:
		return
	_run_state = STATE_TRANSITING
	_transition_target_room_id = target_room.room_id
	_transition_anchor_side = anchor_side
	_transition_target_room = target_room
	_transition_elapsed_sec = 0.0
	_pending_entry_anchor_side = _invert_anchor_side(anchor_side)
	_last_room_note = _tr("night.run.note.crossing_corridor")
	_update_ui()
	_set_player_input_locked(true)
	_set_transition_camera_zoom(ROOM_TRANSITION_CAMERA_ZOOM)
	_cleanup_transition_nodes()
	_transition_preview_room_node = _instantiate_room_node(target_room)
	if _transition_preview_room_node == null:
		_transition_target_room = null
		_set_player_input_locked(false)
		_clear_transition_camera_zoom()
		_enter_room(target_room)
		return
	_prepare_preview_room_node(_transition_preview_room_node, target_room, anchor_side)
	_transition_corridor_node = _build_transition_corridor_bridge(_active_room_node, _transition_preview_room_node, anchor_side)
	var player := _get_player()
	var destination := _resolve_transition_destination(_transition_preview_room_node, anchor_side)
	_transition_end_position = destination
	if player is Node2D:
		_transition_start_position = (player as Node2D).global_position
	else:
		_transition_start_position = destination
		_transition_elapsed_sec = ROOM_TRANSITION_DURATION_SEC


func _complete_room_transition(target_room: RoomState) -> void:
	_transition_target_room = null
	_transition_elapsed_sec = 0.0
	_transition_start_position = Vector2.ZERO
	_transition_end_position = Vector2.ZERO
	_cleanup_transition_nodes()
	_enter_room(target_room)


func _cleanup_transition_nodes() -> void:
	if _transition_corridor_node != null and is_instance_valid(_transition_corridor_node):
		_transition_corridor_node.queue_free()
	_transition_corridor_node = null
	if _transition_preview_room_node != null and is_instance_valid(_transition_preview_room_node):
		_transition_preview_room_node.queue_free()
	_transition_preview_room_node = null


func _instantiate_room_node(room_state: RoomState) -> Node2D:
	var room_scene: PackedScene = load(room_state.scene_path)
	if room_scene == null:
		push_error("NightRunController could not load room scene: %s" % room_state.scene_path)
		return null
	var room_variant: Variant = room_scene.instantiate()
	if not (room_variant is Node2D):
		push_error("NightRunController expected a Node2D room scene: %s" % room_state.scene_path)
		return null
	var room_node := room_variant as Node2D
	room_node.z_index = 0
	_suppress_base_room_shell_visuals()
	_apply_room_layout_scale_to_node(room_node, room_state)
	return room_node


func _prepare_preview_room_node(room_node: Node2D, room_state: RoomState, anchor_side: String) -> void:
	if room_node == null:
		return
	room_node.name = "%s_%s" % [ROOM_TRANSITION_PREVIEW_NODE_NAME, room_state.room_id]
	room_node.position = _resolve_preview_room_position(room_node.scale, anchor_side)
	_resolve_room_mount().add_child(room_node)
	_rebuild_runtime_room_shell_for_node(room_node, room_state, _invert_anchor_side(anchor_side))
	_rebuild_runtime_cover_proxies_for_node(room_node)
	_apply_room_visual_theme_to_node(room_node, room_state)
	_refresh_runtime_door_state_for_node(room_node, room_state, [], _invert_anchor_side(anchor_side), true)


func _resolve_preview_room_position(preview_scale: Vector2, anchor_side: String) -> Vector2:
	if _active_room_node == null:
		return Vector2.ZERO
	var current_position := _active_room_node.position
	match anchor_side:
		"West":
			return current_position + Vector2(-ROOM_TRANSITION_HORIZONTAL_SPACING, 0.0)
		"North":
			return current_position + Vector2(0.0, -ROOM_TRANSITION_VERTICAL_SPACING)
		"South":
			return current_position + Vector2(0.0, ROOM_TRANSITION_VERTICAL_SPACING)
		_:
			return current_position + Vector2(ROOM_TRANSITION_HORIZONTAL_SPACING, 0.0)


func _resolve_transition_destination(preview_room: Node2D, anchor_side: String) -> Vector2:
	if preview_room == null:
		var player := _get_player()
		return player.global_position if player is Node2D else Vector2.ZERO
	var spawn_node := preview_room.get_node_or_null("PlayerSpawn")
	if spawn_node is Node2D:
		return (spawn_node as Node2D).global_position
	var direction := _anchor_side_to_vector(anchor_side)
	return preview_room.global_position - direction * 96.0


func _build_transition_corridor_bridge(current_room: Node2D, preview_room: Node2D, anchor_side: String) -> Node2D:
	if current_room == null or preview_room == null:
		return null
	var bridge_root := Node2D.new()
	bridge_root.name = ROOM_TRANSITION_CORRIDOR_NODE_NAME
	bridge_root.z_as_relative = false
	bridge_root.z_index = 18
	_resolve_room_mount().add_child(bridge_root)
	var current_half := Vector2(ROOM_SHELL_HALF_SIZE.x * current_room.scale.x, ROOM_SHELL_HALF_SIZE.y * current_room.scale.y)
	var preview_half := Vector2(ROOM_SHELL_HALF_SIZE.x * preview_room.scale.x, ROOM_SHELL_HALF_SIZE.y * preview_room.scale.y)
	var trim_color := Color(0.86, 0.93, 0.98, 0.94)
	var wall_color := Color(0.64, 0.71, 0.78, 1.0)
	var floor_color := Color(0.23, 0.29, 0.34, 0.98)
	match anchor_side:
		"West":
			var start_x_w := preview_room.position.x + preview_half.x
			var end_x_w := current_room.position.x - current_half.x
			_add_transition_horizontal_corridor(bridge_root, start_x_w, end_x_w, current_room.position.y, floor_color, wall_color, trim_color)
		"North":
			var start_y_n := preview_room.position.y + preview_half.y
			var end_y_n := current_room.position.y - current_half.y
			_add_transition_vertical_corridor(bridge_root, start_y_n, end_y_n, current_room.position.x, floor_color, wall_color, trim_color)
		"South":
			var start_y_s := current_room.position.y + current_half.y
			var end_y_s := preview_room.position.y - preview_half.y
			_add_transition_vertical_corridor(bridge_root, start_y_s, end_y_s, current_room.position.x, floor_color, wall_color, trim_color)
		_:
			var start_x := current_room.position.x + current_half.x
			var end_x := preview_room.position.x - preview_half.x
			_add_transition_horizontal_corridor(bridge_root, start_x, end_x, current_room.position.y, floor_color, wall_color, trim_color)
	return bridge_root


func _add_transition_horizontal_corridor(parent: Node2D, start_x: float, end_x: float, y: float, floor_color: Color, wall_color: Color, trim_color: Color) -> void:
	var length := absf(end_x - start_x)
	if length <= 0.0:
		return
	var center := Vector2((start_x + end_x) * 0.5, y)
	_add_shell_rect(parent, "CorridorFloor", center, Vector2(length, ROOM_TRANSITION_CORRIDOR_WIDTH), floor_color, 0)
	_add_shell_rect(parent, "CorridorWallNorth", center + Vector2(0.0, -ROOM_TRANSITION_CORRIDOR_WIDTH * 0.5 + ROOM_TRANSITION_CORRIDOR_WALL_THICKNESS * 0.5), Vector2(length, ROOM_TRANSITION_CORRIDOR_WALL_THICKNESS), wall_color, 1)
	_add_shell_rect(parent, "CorridorWallSouth", center + Vector2(0.0, ROOM_TRANSITION_CORRIDOR_WIDTH * 0.5 - ROOM_TRANSITION_CORRIDOR_WALL_THICKNESS * 0.5), Vector2(length, ROOM_TRANSITION_CORRIDOR_WALL_THICKNESS), wall_color.darkened(0.06), 1)
	_add_shell_rect(parent, "CorridorTrim", center, Vector2(length, 8.0), trim_color, 2)


func _add_transition_vertical_corridor(parent: Node2D, start_y: float, end_y: float, x: float, floor_color: Color, wall_color: Color, trim_color: Color) -> void:
	var length := absf(end_y - start_y)
	if length <= 0.0:
		return
	var center := Vector2(x, (start_y + end_y) * 0.5)
	_add_shell_rect(parent, "CorridorFloor", center, Vector2(ROOM_TRANSITION_CORRIDOR_WIDTH, length), floor_color, 0)
	_add_shell_rect(parent, "CorridorWallWest", center + Vector2(-ROOM_TRANSITION_CORRIDOR_WIDTH * 0.5 + ROOM_TRANSITION_CORRIDOR_WALL_THICKNESS * 0.5, 0.0), Vector2(ROOM_TRANSITION_CORRIDOR_WALL_THICKNESS, length), wall_color, 1)
	_add_shell_rect(parent, "CorridorWallEast", center + Vector2(ROOM_TRANSITION_CORRIDOR_WIDTH * 0.5 - ROOM_TRANSITION_CORRIDOR_WALL_THICKNESS * 0.5, 0.0), Vector2(ROOM_TRANSITION_CORRIDOR_WALL_THICKNESS, length), wall_color.darkened(0.06), 1)
	_add_shell_rect(parent, "CorridorTrim", center, Vector2(8.0, length), trim_color, 2)


func _resolve_exit_anchor_side(exit_id: String, target_room_id: String) -> String:
	for exit_node in _active_exit_nodes:
		if exit_node == null or not is_instance_valid(exit_node):
			continue
		var snapshot_variant: Variant = exit_node.call("get_snapshot") if exit_node.has_method("get_snapshot") else {}
		if not (snapshot_variant is Dictionary):
			continue
		var snapshot: Dictionary = snapshot_variant
		var matches_exit := exit_id.strip_edges().is_empty() or String(snapshot.get("exit_id", "")) == exit_id.strip_edges()
		var matches_target := target_room_id.strip_edges().is_empty() or String(snapshot.get("target_room_id", "")) == target_room_id.strip_edges()
		if matches_exit and matches_target:
			return String(snapshot.get("anchor_side", "East")).strip_edges()
	return "East"


func _invert_anchor_side(anchor_side: String) -> String:
	match anchor_side.strip_edges():
		"West":
			return "East"
		"North":
			return "South"
		"South":
			return "North"
		_:
			return "West"


func _anchor_side_to_vector(anchor_side: String) -> Vector2:
	match anchor_side:
		"West":
			return Vector2.LEFT
		"North":
			return Vector2.UP
		"South":
			return Vector2.DOWN
		_:
			return Vector2.RIGHT


func _set_player_input_locked(locked: bool) -> void:
	var player := _get_player()
	if player != null and is_instance_valid(player) and player.has_method("set_input_locked"):
		player.call("set_input_locked", locked)


func _set_transition_camera_zoom(zoom: Vector2) -> void:
	if _world != null and is_instance_valid(_world) and _world.has_method("set_clear_dungeon_camera_zoom_override"):
		_world.call("set_clear_dungeon_camera_zoom_override", zoom)


func _clear_transition_camera_zoom() -> void:
	if _world != null and is_instance_valid(_world) and _world.has_method("clear_clear_dungeon_camera_zoom_override"):
		_world.call("clear_clear_dungeon_camera_zoom_override")


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
		_rebuild_runtime_room_shell(_current_room)
		_spawn_exit_nodes(_current_room)
	_clear_room_objective_runtime()
	_run_state = STATE_ROOM_CLEARED
	_update_ui()


func _present_room_clear_rewards() -> bool:
	if _current_room == null or _current_room.reward_claimed or not _current_room.is_combat_room():
		return false
	_pending_reward_context = {
		"source": "combat_clear"
	}
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
	_last_room_note = _tr("night.run.note.choose_reward")
	_refresh_reward_panel()
	return true


func _claim_pending_room_reward(option_index: int) -> bool:
	if _current_room == null or _pending_room_rewards.is_empty():
		return false
	if option_index < 0 or option_index >= _pending_room_rewards.size():
		return false
	var offer: Dictionary = _pending_room_rewards[option_index].duplicate(true)
	var interaction_note := ""
	if String(_pending_reward_context.get("source", "")).strip_edges().to_lower() == "interaction":
		var cost_result := _apply_interaction_cost(offer)
		if not bool(cost_result.get("paid", false)):
			return false
		interaction_note = String(cost_result.get("note", "")).strip_edges()
	var applied := _run_modifier_state.apply_offer(offer, _build_reward_context())
	if applied.is_empty():
		return false
	_current_room.mark_reward_claimed()
	if String(_pending_reward_context.get("source", "")).strip_edges().to_lower() == "interaction":
		_clear_room_interactions()
	_clear_pending_room_rewards()
	var applied_label := String(applied.get("label", _tr("night.reward.kind.reward")))
	if interaction_note.is_empty():
		_last_room_note = _tr("night.run.note.reward_claimed", {"value": applied_label})
	else:
		_last_room_note = "%s · %s" % [interaction_note, applied_label]
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
			_last_room_note = _tr("night.run.note.treasure_claimed")
		RoomState.TYPE_REST:
			_claim_rest_reward(reward)
			_last_room_note = _tr("night.run.note.rest_claimed")
		RoomState.TYPE_EVENT:
			_claim_event_reward(reward)
			_last_room_note = _tr("night.run.note.event_resolved")
		_:
			_last_room_note = _tr("night.run.note.room_reward_claimed")
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
	_last_room_note = _tr("night.run.note.floor_secured")
	_update_ui()
	if _current_floor_index + 1 < _floors.size():
		_current_floor_index += 1
		var next_floor = _get_current_floor()
		if next_floor != null and _enter_floor_start_room(next_floor):
			return
	_complete_run()


func _apply_floor_mutator(floor_state) -> void:
	_floor_mutator_controller.enter_floor(floor_state, _run_modifier_state, _build_reward_context())


func _enter_floor_start_room(floor_state) -> bool:
	if floor_state == null:
		return false
	var start_room = floor_state.get_room(String(floor_state.start_room_id))
	if start_room == null:
		_run_state = STATE_ABORTED
		_last_room_note = _tr("night.run.note.invalid_floor_start")
		_update_ui()
		_emit_bootstrap_result(false)
		push_error(
			"NightRunController could not enter floor '%s': missing start room '%s'."
			% [String(floor_state.floor_id), String(floor_state.start_room_id)]
		)
		return false
	_apply_floor_mutator(floor_state)
	_enter_room(start_room)
	return true


func _complete_run() -> void:
	_complete_run_with_reason("completed")


func _complete_run_with_reason(exit_reason: String) -> void:
	if _completion_emitted or _game_root == null or not is_instance_valid(_game_root):
		return
	_run_state = STATE_COMPLETED
	var normalized_exit_reason := exit_reason.strip_edges().to_lower()
	match normalized_exit_reason:
		"extracted":
			_last_room_note = _tr("night.run.note.extracted")
		"completed":
			_last_room_note = _tr("night.run.note.completed")
		_:
			_last_room_note = _tr("night.run.note.completed_generic")
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
	if _has_active_objective() and not _objective_runtime_controller.is_completed():
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
		_last_room_note = _tr("night.run.note.choose_door")
		_update_ui()


func _on_exit_selected(_exit_id: String, target_room_id: String) -> void:
	if _completion_emitted or _current_room == null or _run_state == STATE_TRANSITING:
		return
	if _current_room.locks_on_entry and _current_room.status != RoomState.STATUS_CLEARED:
		return
	if _has_pending_room_rewards():
		_last_room_note = _tr("night.run.note.claim_reward_before_move")
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
	if not _get_visible_room_connections(_current_room, floor_state).has(normalized_target):
		return
	_lock_active_exits(true)
	var anchor_side := _resolve_exit_anchor_side(_exit_id, normalized_target)
	call_deferred("_begin_room_transition", normalized_target, anchor_side)


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
	payload["dungeon_system_modifiers"] = modifier_snapshot.get("system_modifiers", [])
	payload["dungeon_reward_multipliers"] = modifier_snapshot.get("reward_multipliers", {})
	var floor_mutator_summary := _floor_mutator_controller.build_summary_payload()
	for key_variant in floor_mutator_summary.keys():
		payload[String(key_variant)] = floor_mutator_summary[key_variant]
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
	_clear_active_exit_nodes()
	_clear_room_objective_runtime()
	_clear_room_interactions()
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
	_pending_reward_context.clear()
	_run_modifier_state.reset({})
	_run_state = STATE_BOOTING
	_boot_attempts = 0
	_bootstrap_reported = false
	_completion_emitted = false
	_rooms_cleared_total = 0
	_visited_room_ids.clear()
	_last_room_note = ""
	_pending_entry_anchor_side = ""
	_current_room_entry_anchor_side = ""
	_boss_climax_snapshot = _boss_room_controller.get_snapshot()
	_extraction_snapshot.clear()
	_objective_runtime_controller.reset(_build_objective_runtime_context())
	_floor_mutator_controller.reset()
	_update_ui()


func _emit_bootstrap_result(success: bool) -> void:
	if _bootstrap_reported:
		return
	_bootstrap_reported = true
	session_bootstrapped.emit(success)


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
	var cover_proxy_count := 0
	var cover_proxy_root := _active_room_node.get_node_or_null(ROOM_COVER_PROXY_NODE_NAME)
	if cover_proxy_root != null:
		cover_proxy_count = cover_proxy_root.get_child_count()
	if _active_room_node.has_method("get_room_content_snapshot"):
		var snapshot_variant: Variant = _active_room_node.call("get_room_content_snapshot")
		if snapshot_variant is Dictionary:
			var snapshot: Dictionary = snapshot_variant
			snapshot["cover_proxy_count"] = cover_proxy_count
			snapshot["objective_count"] = _get_objective_node_count()
			snapshot["interaction_count"] = _active_room_interactions.size()
			return snapshot
		return {
			"cover_proxy_count": cover_proxy_count,
			"objective_count": _get_objective_node_count(),
			"interaction_count": _active_room_interactions.size()
		}
	return {
		"cover_proxy_count": cover_proxy_count,
		"objective_count": _get_objective_node_count(),
		"interaction_count": _active_room_interactions.size()
	}


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
		if not _should_show_room_on_map(room, floor_state):
			continue
		var room_snapshot := room.to_dictionary()
		room_snapshot["connections"] = _get_visible_room_connections(room, floor_state)
		room_snapshot["hidden_room"] = bool(room.metadata.get("hidden_room", false))
		room_snapshot["revealed"] = _is_hidden_room_revealed(room.room_id, floor_state)
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
		"layout_mode": "spatial",
		"floor_label": _resolve_floor_label(),
		"floor_mutator": _floor_mutator_controller.get_current_mutator(),
		"current_room_id": _current_room.room_id if _current_room != null else "",
		"current_room_label": _current_room.label if _current_room != null else "",
		"current_room_type_label": _resolve_current_room_focus_label(),
		"rooms": _build_floor_rooms_snapshot(),
		"grid_spacing": floor_state.map_grid_spacing if floor_state != null else Vector2(1180.0, 860.0),
		"corridor_width": floor_state.map_corridor_width if floor_state != null else 96.0,
		"template_id": floor_state.template_id if floor_state != null else ""
	}


func _resolve_floor_label() -> String:
	var floor_state = _get_current_floor()
	if floor_state == null:
		return _tr("night.run.title")
	return floor_state.label


func _resolve_current_room_focus_label() -> String:
	if _current_room == null:
		return _tr("night.run.staging_chamber")
	var encounter_label := String(_current_room_payload.get("encounter_category_label", "")).strip_edges()
	if _current_room.is_combat_room() and not encounter_label.is_empty():
		return encounter_label
	return _current_room.room_type_label


func _resolve_status_text() -> String:
	var objective_status := _resolve_objective_status_text()
	if _run_state == STATE_ROOM_LOCKED and not objective_status.is_empty():
		return objective_status
	if not _last_room_note.is_empty():
		return _last_room_note
	match _run_state:
		STATE_BOOTING:
			return _tr("night.run.status.booting")
		STATE_ENTERING_ROOM:
			return _tr("night.run.status.entering_room")
		STATE_ROOM_LOCKED:
			return _tr("night.run.status.room_locked")
		STATE_REWARD_PENDING:
			return _tr("night.run.status.reward_pending")
		STATE_ROOM_CLEARED:
			return _tr("night.run.status.room_cleared")
		STATE_FLOOR_CLEARED:
			return _tr("night.run.status.floor_cleared")
		STATE_COMPLETED:
			if bool(_extraction_snapshot.get("available", false)):
				return _tr("night.run.status.completed_extract_ready")
			return _tr("night.run.status.completed")
		STATE_ABORTED:
			return _tr("night.run.status.aborted")
	return ""


func _update_ui() -> void:
	if floor_label != null:
		floor_label.text = _resolve_floor_label()
	if room_label != null:
		if _current_room == null:
			room_label.text = _tr("night.run.staging_chamber")
		else:
			room_label.text = "%s · %s" % [_current_room.label, _resolve_current_room_focus_label()]
	if status_label != null:
		status_label.text = _resolve_status_text()
	_refresh_reward_panel()
	_refresh_interaction_panel()
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
		var title_text := String(_pending_reward_context.get("panel_title", "")).strip_edges()
		reward_title_label.text = title_text if not title_text.is_empty() else _tr("night.reward.panel_title")
	if reward_subtitle_label != null:
		var subtitle_text := String(_pending_reward_context.get("panel_subtitle", "")).strip_edges()
		if subtitle_text.is_empty():
			subtitle_text = "%s · %s" % [
				_current_room.label if _current_room != null else _tr("night.reward.unknown_room"),
				_resolve_current_room_focus_label()
			]
		reward_subtitle_label.text = subtitle_text
	if reward_hint_label != null:
		var hint_text := String(_pending_reward_context.get("panel_hint", "")).strip_edges()
		reward_hint_label.text = hint_text if not hint_text.is_empty() else _tr("night.reward.panel_hint")
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
		button.disabled = not _is_offer_affordable(offer)
		button.text = _format_reward_button_text(offer)


func _format_reward_button_text(offer: Dictionary) -> String:
	var reward_kind := String(offer.get("reward_kind_label", "")).strip_edges()
	if reward_kind.is_empty():
		reward_kind = _localized_reward_kind(String(offer.get("reward_kind", "reward")).strip_edges())
	var label := String(offer.get("label", _tr("night.reward.kind.reward"))).strip_edges()
	var summary := String(offer.get("summary", offer.get("description", ""))).strip_edges()
	var text := "%s\n%s" % [reward_kind, label]
	if not summary.is_empty():
		text += "\n%s" % summary
	var cost_label := String(offer.get("cost_label", "")).strip_edges()
	if not cost_label.is_empty():
		text += "\n%s" % cost_label
	return text


func _hide_reward_panel() -> void:
	if reward_panel != null:
		reward_panel.visible = false


func _hide_interaction_panel() -> void:
	if interaction_panel != null:
		interaction_panel.visible = false
	if interaction_label != null:
		interaction_label.text = ""


func _clear_pending_room_rewards() -> void:
	_pending_room_rewards.clear()
	_pending_reward_context.clear()
	_hide_reward_panel()


func _has_pending_room_rewards() -> bool:
	return not _pending_room_rewards.is_empty()


func _refresh_interaction_panel() -> void:
	if interaction_panel == null:
		return
	if _has_pending_room_rewards() or _current_room == null or _current_room.reward_claimed:
		_hide_interaction_panel()
		return
	var interaction_node := _find_room_interaction_by_id(_focused_room_interaction_id)
	if interaction_node == null or not is_instance_valid(interaction_node):
		_hide_interaction_panel()
		return
	var prompt := ""
	if interaction_node.has_method("get_snapshot"):
		var snapshot_variant: Variant = interaction_node.call("get_snapshot")
		if snapshot_variant is Dictionary:
			prompt = String((snapshot_variant as Dictionary).get("prompt_text", "")).strip_edges()
	if prompt.is_empty():
		prompt = _interaction_prompt_for_kind(String(interaction_node.get("interaction_kind")), String(interaction_node.get("label")))
	interaction_panel.visible = true
	if interaction_label != null:
		interaction_label.text = prompt


func _spawn_room_interactions(room_state: RoomState) -> bool:
	_clear_room_interactions()
	if room_state == null or room_state.reward_claimed or _active_room_node == null or not is_instance_valid(_active_room_node):
		return false
	var metadata: Dictionary = room_state.metadata if room_state.metadata is Dictionary else {}
	var interaction_kind := String(metadata.get("special_room_kind", "")).strip_edges().to_lower()
	if interaction_kind.is_empty():
		return false
	var interaction_root := Node2D.new()
	interaction_root.name = ROOM_INTERACTION_ROOT_NODE_NAME
	interaction_root.z_index = ROOM_COVER_PROXY_LAYER_Z + 2
	_active_room_node.add_child(interaction_root)
	var interaction_variant: Variant = RoomInteractableScene.instantiate()
	if not (interaction_variant is Node2D):
		interaction_root.queue_free()
		return false
	var interaction_node: Node2D = interaction_variant
	interaction_node.name = "RoomInteraction_%s" % interaction_kind
	interaction_node.position = _resolve_room_interaction_local_position(room_state, interaction_kind)
	interaction_root.add_child(interaction_node)
	if interaction_node.has_method("configure_from_payload"):
		interaction_node.call("configure_from_payload", {
			"interaction_id": "%s_%s" % [room_state.room_id, interaction_kind],
			"interaction_kind": interaction_kind,
			"label": room_state.label,
			"prompt_text": _interaction_prompt_for_kind(interaction_kind, room_state.label),
			"radius": float(metadata.get("interaction_radius", 92.0))
		})
	_active_room_interactions = [interaction_node]
	_focused_room_interaction_id = ""
	_refresh_interaction_panel()
	return true


func _clear_room_interactions() -> void:
	for interaction_node in _active_room_interactions:
		if interaction_node == null or not is_instance_valid(interaction_node):
			continue
		interaction_node.queue_free()
	_active_room_interactions.clear()
	_focused_room_interaction_id = ""
	_hide_interaction_panel()


func _update_room_interaction_focus() -> void:
	if _active_room_interactions.is_empty():
		if not _focused_room_interaction_id.is_empty():
			_focused_room_interaction_id = ""
			_refresh_interaction_panel()
		return
	if _has_pending_room_rewards() or _run_state == STATE_TRANSITING:
		for interaction_node in _active_room_interactions:
			if interaction_node != null and is_instance_valid(interaction_node) and interaction_node.has_method("set_focused"):
				interaction_node.call("set_focused", false)
		if not _focused_room_interaction_id.is_empty():
			_focused_room_interaction_id = ""
			_refresh_interaction_panel()
		return
	var player := _get_player()
	if not (player is Node2D):
		return
	var best_id := ""
	var best_distance := INF
	var player_position := (player as Node2D).global_position
	for interaction_node in _active_room_interactions:
		if interaction_node == null or not is_instance_valid(interaction_node):
			continue
		var contains := false
		if interaction_node.has_method("contains_world_point"):
			contains = bool(interaction_node.call("contains_world_point", player_position))
		if not contains:
			if interaction_node.has_method("set_focused"):
				interaction_node.call("set_focused", false)
			continue
		var interaction_id := String(interaction_node.get("interaction_id")).strip_edges()
		var distance := (interaction_node as Node2D).global_position.distance_to(player_position)
		if distance < best_distance:
			best_distance = distance
			best_id = interaction_id
	for interaction_node in _active_room_interactions:
		if interaction_node == null or not is_instance_valid(interaction_node):
			continue
		if not interaction_node.has_method("set_focused"):
			continue
		var interaction_id := String(interaction_node.get("interaction_id")).strip_edges()
		interaction_node.call("set_focused", interaction_id == best_id and not best_id.is_empty())
	if best_id != _focused_room_interaction_id:
		_focused_room_interaction_id = best_id
		_refresh_interaction_panel()


func _find_room_interaction_by_id(interaction_id: String) -> Node2D:
	var normalized_interaction_id := interaction_id.strip_edges()
	if normalized_interaction_id.is_empty():
		return null
	for interaction_node in _active_room_interactions:
		if interaction_node == null or not is_instance_valid(interaction_node):
			continue
		if String(interaction_node.get("interaction_id")).strip_edges() == normalized_interaction_id:
			return interaction_node
	return null


func _try_activate_room_interaction(interaction_id: String = "") -> bool:
	if _current_room == null or _current_room.reward_claimed or _has_pending_room_rewards():
		return false
	var normalized_interaction_id := interaction_id.strip_edges()
	if normalized_interaction_id.is_empty():
		normalized_interaction_id = _focused_room_interaction_id
	var interaction_node := _find_room_interaction_by_id(normalized_interaction_id)
	if interaction_node == null:
		return false
	return _present_special_room_rewards(_current_room, interaction_node)


func _present_special_room_rewards(room_state: RoomState, interaction_node: Node2D) -> bool:
	if room_state == null or interaction_node == null or not is_instance_valid(interaction_node):
		return false
	var interaction_kind := String(interaction_node.get("interaction_kind")).strip_edges().to_lower()
	var offers: Array[Dictionary] = []
	match interaction_kind:
		"shrine":
			offers = _build_shrine_offers(room_state)
		"shop":
			offers = _build_shop_offers(room_state)
		_:
			return false
	if offers.is_empty():
		return false
	_pending_room_rewards = offers
	_pending_reward_context = {
		"source": "interaction",
		"interaction_id": String(interaction_node.get("interaction_id")).strip_edges(),
		"interaction_kind": interaction_kind,
		"panel_title": _interaction_panel_title_for_kind(interaction_kind),
		"panel_subtitle": room_state.label,
		"panel_hint": _interaction_panel_hint_for_kind(interaction_kind)
	}
	_run_state = STATE_REWARD_PENDING
	_refresh_reward_panel()
	_refresh_interaction_panel()
	_update_ui()
	return true


func _build_shrine_offers(room_state: RoomState) -> Array[Dictionary]:
	var offers: Array[Dictionary] = []
	if room_state == null:
		return offers
	var metadata: Dictionary = room_state.metadata if room_state.metadata is Dictionary else {}
	var pool_id := String(metadata.get("shrine_pool_id", "")).strip_edges().to_lower()
	var pool_variant: Variant = SHRINE_BLESSING_POOLS.get(pool_id, [])
	if not (pool_variant is Array):
		return offers
	var base_pool: Array = _filter_available_modifier_ids(pool_variant as Array)
	if base_pool.is_empty():
		base_pool = pool_variant as Array
	var offer_ids := _pick_unique_offer_ids(base_pool, _build_interaction_seed(room_state, "shrine"), 3)
	var cost_type := String(metadata.get("cost_type", "hp_or_noise")).strip_edges().to_lower()
	var cost_value := maxi(0, int(metadata.get("cost_value", 0)))
	var cost_label := _interaction_cost_label(cost_type, cost_value)
	for modifier_id in offer_ids:
		var offer_variant: Variant = _run_modifier_state.build_modifier_offer(modifier_id)
		if not (offer_variant is Dictionary) or (offer_variant as Dictionary).is_empty():
			continue
		var offer: Dictionary = (offer_variant as Dictionary).duplicate(true)
		offer["cost_type"] = cost_type
		offer["cost_value"] = cost_value
		offer["cost_label"] = cost_label
		offers.append(offer)
	return offers


func _build_shop_offers(room_state: RoomState) -> Array[Dictionary]:
	var offers: Array[Dictionary] = []
	if room_state == null:
		return offers
	var metadata: Dictionary = room_state.metadata if room_state.metadata is Dictionary else {}
	var inventory_id := String(metadata.get("shop_inventory_id", "")).strip_edges().to_lower()
	var inventory_variant: Variant = SHOP_INVENTORY_POOLS.get(inventory_id, {})
	if not (inventory_variant is Dictionary):
		return offers
	var inventory: Dictionary = inventory_variant
	var base_price := maxi(12, int(metadata.get("shop_price_xp", 36)))
	var price_offsets_variant: Variant = inventory.get("price_offsets", [-12, 0, 12])
	var price_offsets: Array = [-12, 0, 12]
	if price_offsets_variant is Array:
		price_offsets = (price_offsets_variant as Array).duplicate()
	var bundle_pool_variant: Variant = inventory.get("bundle_entries", [])
	if bundle_pool_variant is Array:
		var bundle_ids := _pick_unique_offer_ids(bundle_pool_variant as Array, _build_interaction_seed(room_state, "shop_bundle"), 1)
		if not bundle_ids.is_empty():
			var bundle_offer := _room_reward_picker.build_bundle_offer(String(bundle_ids[0]))
			if not bundle_offer.is_empty():
				var bundle_price: int = maxi(12, base_price - 12)
				if not price_offsets.is_empty():
					bundle_price = base_price + int(price_offsets[0])
				bundle_offer["cost_type"] = "xp"
				bundle_offer["cost_value"] = maxi(12, bundle_price)
				bundle_offer["cost_label"] = _interaction_cost_label("xp", int(bundle_offer.get("cost_value", 0)))
				offers.append(bundle_offer)
	var trait_pool_variant: Variant = inventory.get("trait_entries", [])
	if trait_pool_variant is Array:
		var filtered_trait_pool: Array = _filter_available_modifier_ids(trait_pool_variant as Array)
		if filtered_trait_pool.is_empty():
			filtered_trait_pool = trait_pool_variant as Array
		var trait_ids := _pick_unique_offer_ids(filtered_trait_pool, _build_interaction_seed(room_state, "shop_traits"), 2)
		for trait_index in range(trait_ids.size()):
			var offer_variant: Variant = _run_modifier_state.build_modifier_offer(String(trait_ids[trait_index]))
			if not (offer_variant is Dictionary) or (offer_variant as Dictionary).is_empty():
				continue
			var offer: Dictionary = (offer_variant as Dictionary).duplicate(true)
			var price_index := trait_index + 1
			if not price_offsets.is_empty():
				price_index = mini(price_offsets.size() - 1, trait_index + 1)
			var trait_price := base_price
			if price_index >= 0 and price_index < price_offsets.size():
				trait_price = base_price + int(price_offsets[price_index])
			offer["cost_type"] = "xp"
			offer["cost_value"] = maxi(12, trait_price)
			offer["cost_label"] = _interaction_cost_label("xp", int(offer.get("cost_value", 0)))
			offers.append(offer)
	return offers


func _pick_unique_offer_ids(pool: Array, seed_value: int, count: int) -> Array[String]:
	var picks: Array[String] = []
	var normalized_pool: Array[String] = []
	for entry_variant in pool:
		var entry_id := String(entry_variant).strip_edges().to_lower()
		if entry_id.is_empty() or normalized_pool.has(entry_id):
			continue
		normalized_pool.append(entry_id)
	if normalized_pool.is_empty():
		return picks
	var rng := RandomNumberGenerator.new()
	rng.seed = maxi(1, abs(seed_value))
	var working_pool: Array[String] = normalized_pool.duplicate()
	for _pick in range(mini(maxi(0, count), working_pool.size())):
		var index := rng.randi_range(0, working_pool.size() - 1)
		picks.append(working_pool[index])
		working_pool.remove_at(index)
	return picks


func _filter_available_modifier_ids(pool: Array) -> Array:
	var filtered: Array = []
	for modifier_id_variant in pool:
		var modifier_id := String(modifier_id_variant).strip_edges().to_lower()
		if modifier_id.is_empty():
			continue
		if _run_modifier_state.has_method("has_modifier") and bool(_run_modifier_state.call("has_modifier", modifier_id)):
			continue
		filtered.append(modifier_id)
	return filtered


func _is_offer_affordable(offer: Dictionary) -> bool:
	var player := _get_player()
	if player == null or not is_instance_valid(player):
		return false
	var cost_type := String(offer.get("cost_type", "")).strip_edges().to_lower()
	var cost_value := maxi(0, int(offer.get("cost_value", 0)))
	match cost_type:
		"xp":
			return float(player.get("xp")) + 0.001 >= float(cost_value)
		"hp":
			return float(player.get("hp")) > float(cost_value)
		_:
			return true


func _apply_interaction_cost(offer: Dictionary) -> Dictionary:
	var player := _get_player()
	if player == null or not is_instance_valid(player):
		return {"paid": false}
	var cost_type := String(offer.get("cost_type", "")).strip_edges().to_lower()
	var cost_value := maxi(0, int(offer.get("cost_value", 0)))
	if cost_type.is_empty() or cost_value <= 0:
		return {"paid": true, "note": ""}
	match cost_type:
		"xp":
			var xp_value := float(player.get("xp"))
			if xp_value + 0.001 < float(cost_value):
				_last_room_note = _tr("night.run.note.interaction_insufficient_xp")
				_update_ui()
				return {"paid": false}
			player.set("xp", maxf(0.0, xp_value - float(cost_value)))
			if player.has_method("emit_stats_changed"):
				player.call("emit_stats_changed")
			return {"paid": true, "note": _interaction_cost_label(cost_type, cost_value)}
		"hp":
			var hp_value := float(player.get("hp"))
			if hp_value <= float(cost_value):
				return {"paid": false}
			player.set("hp", maxf(1.0, hp_value - float(cost_value)))
			if player.has_method("emit_stats_changed"):
				player.call("emit_stats_changed")
			return {"paid": true, "note": _tr("night.run.note.interaction_paid_hp", {"value": cost_value})}
		"noise":
			if player.has_method("add_noise_delta"):
				player.call("add_noise_delta", float(cost_value))
			if player.has_method("emit_stats_changed"):
				player.call("emit_stats_changed")
			return {"paid": true, "note": _tr("night.run.note.interaction_paid_noise", {"value": cost_value})}
		"hp_or_noise":
			var current_hp := float(player.get("hp"))
			var max_hp := maxf(1.0, float(player.get("max_hp")))
			var hp_threshold := float(cost_value) + minf(18.0, maxf(10.0, max_hp * 0.15))
			if current_hp > hp_threshold:
				player.set("hp", maxf(1.0, current_hp - float(cost_value)))
				if player.has_method("emit_stats_changed"):
					player.call("emit_stats_changed")
				return {"paid": true, "note": _tr("night.run.note.interaction_paid_hp", {"value": cost_value})}
			if player.has_method("add_noise_delta"):
				player.call("add_noise_delta", float(cost_value))
			if player.has_method("emit_stats_changed"):
				player.call("emit_stats_changed")
			return {"paid": true, "note": _tr("night.run.note.interaction_paid_noise", {"value": cost_value})}
	return {"paid": false}


func _build_room_interaction_snapshot() -> Array[Dictionary]:
	var snapshots: Array[Dictionary] = []
	for interaction_node in _active_room_interactions:
		if interaction_node == null or not is_instance_valid(interaction_node):
			continue
		if interaction_node.has_method("get_snapshot"):
			snapshots.append(interaction_node.call("get_snapshot"))
	return snapshots


func _interaction_prompt_for_kind(kind: String, label: String) -> String:
	var normalized_kind := kind.strip_edges().to_lower()
	var key := "night.interaction.prompt.%s" % normalized_kind
	if normalized_kind != "shrine" and normalized_kind != "shop":
		key = "night.interaction.prompt.generic"
	return _tr(key, {"value": label})


func _interaction_panel_title_for_kind(kind: String) -> String:
	var normalized_kind := kind.strip_edges().to_lower()
	match normalized_kind:
		"shrine":
			return _tr("night.interaction.panel_title.shrine")
		"shop":
			return _tr("night.interaction.panel_title.shop")
	return _tr("night.reward.panel_title")


func _interaction_panel_hint_for_kind(kind: String) -> String:
	var normalized_kind := kind.strip_edges().to_lower()
	match normalized_kind:
		"shrine":
			return _tr("night.interaction.panel_hint.shrine")
		"shop":
			return _tr("night.interaction.panel_hint.shop")
	return _tr("night.interaction.prompt.generic", {"value": _current_room.label if _current_room != null else _tr("night.reward.unknown_room")})


func _interaction_cost_label(kind: String, value: int) -> String:
	var normalized_kind := kind.strip_edges().to_lower()
	if value <= 0:
		return ""
	match normalized_kind:
		"hp":
			return _tr("night.interaction.cost.hp", {"value": value})
		"noise":
			return _tr("night.interaction.cost.noise", {"value": value})
		"xp":
			return _tr("night.interaction.cost.xp", {"value": value})
		"hp_or_noise":
			return _tr("night.interaction.cost.hp_or_noise", {"value": value})
	return ""


func _resolve_room_interaction_local_position(room_state: RoomState, interaction_kind: String) -> Vector2:
	if _active_room_node == null or not is_instance_valid(_active_room_node):
		return Vector2.ZERO
	var metadata: Dictionary = room_state.metadata if room_state.metadata is Dictionary else {}
	var offset: Vector2 = _coerce_vector2(ROOM_INTERACTION_OFFSETS.get(
		interaction_kind,
		ROOM_INTERACTION_OFFSETS["generic"]
	))
	offset += _coerce_vector2(metadata.get("interaction_offset", Vector2.ZERO))
	var marker_name := String(metadata.get("interaction_marker", "Center")).strip_edges()
	var spawn_points := _active_room_node.get_node_or_null("SpawnPoints")
	var marker := _find_named_child(spawn_points, marker_name)
	if marker == null:
		marker = _find_named_child(spawn_points, "Center")
	if marker is Node2D:
		return (marker as Node2D).position + offset
	var anchor := _active_room_node.get_node_or_null("EncounterAnchor")
	if anchor is Node2D:
		return (anchor as Node2D).position + offset
	return offset


func _build_interaction_seed(room_state: RoomState, salt: String) -> int:
	return maxi(1, abs(hash("%s|%s|%s|%s" % [
		int(_active_request.get("seed", 0)),
		room_state.room_id,
		String(room_state.metadata.get("special_room_kind", "")),
		salt
	])))


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
		boss_title_label.text = String(snapshot.get("title", _tr("night.boss.title_default")))
	if boss_phase_label != null:
		boss_phase_label.text = String(snapshot.get("phase_label", _tr("night.boss.phase_default")))
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
		extraction_title_label.text = String(_extraction_snapshot.get("title", _tr("night.extraction.title")))
	if extraction_status_label != null:
		extraction_status_label.text = String(_extraction_snapshot.get("subtitle", ""))
	if extract_button != null:
		extract_button.text = String(_extraction_snapshot.get("button_text", _tr("night.extraction.button.extract")))
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
	_last_room_note = _tr("night.run.note.boss_engaged")
	_update_ui()


func _on_boss_phase_changed(boss_id: String, phase_id: String, telegraph_text: String) -> void:
	_boss_climax_snapshot = _boss_room_controller.on_boss_phase_changed(boss_id, phase_id, telegraph_text)
	_last_room_note = _tr("night.run.note.boss_phase_shift")
	_update_ui()


func _on_boss_defeated(boss_id: String) -> void:
	_boss_climax_snapshot = _boss_room_controller.on_boss_defeated(boss_id)
	var bonus_payload := _boss_room_controller.get_completion_bonus()
	if not bonus_payload.is_empty():
		_extraction_controller.record_boss_bonus(bonus_payload)
	_last_room_note = _tr("night.run.note.boss_down_reward")
	_update_ui()


func _tr(key: String, args: Dictionary = {}) -> String:
	if Localization != null and Localization.has_method("t"):
		return String(Localization.call("t", key, args))
	return key


func _localized_reward_kind(reward_kind: String) -> String:
	var normalized := reward_kind.strip_edges().to_lower()
	return _tr("night.reward.kind.%s" % normalized)
