extends Node2D
class_name DayWorldView

signal farm_requested
signal farm_plot_action_requested(plot_index: int, action_id: String, seed_id: String)
signal world_pickup_requested(pickup_id: String)
signal restaurant_requested
signal shop_requested
signal wait_requested
signal night_requested
signal menu_requested
signal legacy_requested

const FARM_BUILDING_TEXTURE := preload("res://assets/source/pixel_packs/tiny_swords/Tiny Swords (Free Pack)/Buildings/Yellow Buildings/House1.png")
const FARM_SHED_TEXTURE := preload("res://assets/source/pixel_packs/tiny_swords/Tiny Swords (Free Pack)/Buildings/Yellow Buildings/House2.png")
const RESTAURANT_TEXTURE := preload("res://assets/source/pixel_packs/tiny_swords/Tiny Swords (Free Pack)/Buildings/Red Buildings/Barracks.png")
const SHOP_TEXTURE := preload("res://assets/source/pixel_packs/tiny_swords/Tiny Swords (Free Pack)/Buildings/Blue Buildings/Archery.png")
const NIGHT_TOWER_TEXTURE := preload("res://assets/source/pixel_packs/tiny_swords/Tiny Swords (Free Pack)/Buildings/Black Buildings/Tower.png")
const ZED_VILLAGE_SHEET_PATH := "res://assets/external/dayworld_visual_pass_2/unpacked/village/Pixel 16 v2 village free/Pixel 16 v2 village free.png"
const ZED_FOREST_SHEET_PATH := "res://assets/external/dayworld_visual_pass_2/unpacked/forest/pixel_16_woods v2 free/free_pixel_16_woods.png"
const TREE_SHEETS := [
	preload("res://assets/source/pixel_packs/tiny_swords/Tiny Swords (Free Pack)/Terrain/Resources/Wood/Trees/Tree1.png"),
	preload("res://assets/source/pixel_packs/tiny_swords/Tiny Swords (Free Pack)/Terrain/Resources/Wood/Trees/Tree2.png"),
	preload("res://assets/source/pixel_packs/tiny_swords/Tiny Swords (Free Pack)/Terrain/Resources/Wood/Trees/Tree3.png"),
	preload("res://assets/source/pixel_packs/tiny_swords/Tiny Swords (Free Pack)/Terrain/Resources/Wood/Trees/Tree4.png")
]
const STUMP_TEXTURE := preload("res://assets/source/pixel_packs/tiny_swords/Tiny Swords (Free Pack)/Terrain/Resources/Wood/Trees/Stump 1.png")
const BUSH_SHEETS := [
	preload("res://assets/source/pixel_packs/tiny_swords/Tiny Swords (Free Pack)/Terrain/Decorations/Bushes/Bushe1.png"),
	preload("res://assets/source/pixel_packs/tiny_swords/Tiny Swords (Free Pack)/Terrain/Decorations/Bushes/Bushe2.png"),
	preload("res://assets/source/pixel_packs/tiny_swords/Tiny Swords (Free Pack)/Terrain/Decorations/Bushes/Bushe3.png"),
	preload("res://assets/source/pixel_packs/tiny_swords/Tiny Swords (Free Pack)/Terrain/Decorations/Bushes/Bushe4.png")
]
const ROCK_TEXTURES := [
	preload("res://assets/source/pixel_packs/tiny_swords/Tiny Swords (Free Pack)/Terrain/Decorations/Rocks/Rock1.png"),
	preload("res://assets/source/pixel_packs/tiny_swords/Tiny Swords (Free Pack)/Terrain/Decorations/Rocks/Rock2.png"),
	preload("res://assets/source/pixel_packs/tiny_swords/Tiny Swords (Free Pack)/Terrain/Decorations/Rocks/Rock3.png"),
	preload("res://assets/source/pixel_packs/tiny_swords/Tiny Swords (Free Pack)/Terrain/Decorations/Rocks/Rock4.png")
]
const WATER_ROCK_SHEETS := [
	preload("res://assets/source/pixel_packs/tiny_swords/Tiny Swords (Free Pack)/Terrain/Decorations/Rocks in the Water/Water Rocks_01.png"),
	preload("res://assets/source/pixel_packs/tiny_swords/Tiny Swords (Free Pack)/Terrain/Decorations/Rocks in the Water/Water Rocks_02.png"),
	preload("res://assets/source/pixel_packs/tiny_swords/Tiny Swords (Free Pack)/Terrain/Decorations/Rocks in the Water/Water Rocks_03.png"),
	preload("res://assets/source/pixel_packs/tiny_swords/Tiny Swords (Free Pack)/Terrain/Decorations/Rocks in the Water/Water Rocks_04.png")
]
const ZED_VILLAGE_STALL_REGION := Rect2i(19, 120, 43, 40)
const ZED_VILLAGE_RESTAURANT_REGION := Rect2i(68, 123, 72, 101)
const ZED_VILLAGE_FARMHOUSE_REGION := Rect2i(148, 155, 115, 69)
const ZED_VILLAGE_LAMP_REGION := Rect2i(160, 16, 40, 64)
const ZED_VILLAGE_BENCH_REGION := Rect2i(208, 24, 32, 24)
const ZED_VILLAGE_PLANTER_WOOD_REGION := Rect2i(104, 48, 32, 16)
const ZED_VILLAGE_PLANTER_STONE_REGION := Rect2i(102, 80, 36, 16)
const ZED_VILLAGE_POT_BLUE_REGION := Rect2i(192, 64, 16, 16)
const ZED_VILLAGE_POT_ORANGE_REGION := Rect2i(192, 80, 16, 16)
const ZED_VILLAGE_POT_YELLOW_REGION := Rect2i(208, 80, 16, 16)
const ZED_VILLAGE_POT_SKY_REGION := Rect2i(224, 80, 16, 16)
const ZED_VILLAGE_CRATE_REGIONS := [
	Rect2i(208, 64, 16, 16),
	Rect2i(224, 64, 16, 16),
	Rect2i(240, 64, 16, 16)
]
const ZED_FOREST_TREE_LIGHT_REGION := Rect2i(275, 10, 59, 70)
const ZED_FOREST_TREE_DARK_REGION := Rect2i(17, 100, 78, 75)
const ZED_FOREST_TREE_ROUND_REGION := Rect2i(23, 24, 66, 65)
const ZED_FOREST_TREE_SMALL_REGION := Rect2i(275, 92, 28, 36)
const ZED_FOREST_TREE_PINE_REGION := Rect2i(308, 97, 25, 31)
const ZED_FOREST_PATCH_LIGHT_REGION := Rect2i(23, 24, 66, 65)
const ZED_FOREST_PATCH_DARK_REGION := Rect2i(151, 23, 66, 66)
const ZED_FOREST_POND_REGION := Rect2i(144, 96, 80, 80)
const ZED_FOREST_CLIFF_REGION := Rect2i(80, 112, 48, 64)
const ZED_FOREST_ROCK_LARGE_REGION := Rect2i(224, 36, 16, 16)
const ZED_FOREST_ROCK_SMALL_REGION := Rect2i(240, 128, 16, 16)
const ZED_FOREST_WATER_PLANTS_REGION := Rect2i(224, 128, 48, 16)
const PHASE_ORDER := ["morning", "noon", "afternoon", "evening"]

const WORLD_BOUNDS := Rect2(Vector2(56.0, 144.0), Vector2(1488.0, 748.0))
const TILE_SIZE := 48
const GROUND_COLUMNS := 34
const GROUND_ROWS := 18
const GROUND_ORIGIN := Vector2(0.0, 120.0)
const TILE_GRASS := Vector2i(0, 0)
const TILE_MEADOW := Vector2i(1, 0)
const TILE_PATH := Vector2i(2, 0)
const TILE_STONE := Vector2i(3, 0)
const TILE_SOIL := Vector2i(4, 0)
const TILE_WATER := Vector2i(5, 0)
const TILE_DOCK := Vector2i(6, 0)
const TILE_DARK_GRASS := Vector2i(7, 0)
const TILE_FLOWERS := Vector2i(8, 0)
const TILE_SAND := Vector2i(9, 0)
const TILE_FOAM := Vector2i(10, 0)
const FARM_PLOT_ORIGIN := Vector2(214.0, 628.0)
const FARM_PLOT_STEP := Vector2(104.0, 84.0)
const FARM_PLOT_SIZE := Vector2(82.0, 60.0)
const NIGHT_DOCK_POSITION := Vector2(1218.0, 818.0)
const NIGHT_TRANSITION_SECONDS := 0.55
const HOTBAR_HAND_KEY := "hand::"
const HOTBAR_DIRECT_ACTIONS := [
	"day_hotbar_slot_1",
	"day_hotbar_slot_2",
	"day_hotbar_slot_3",
	"day_hotbar_slot_4",
	"day_hotbar_slot_5",
	"day_hotbar_slot_6"
]
const PROMPT_REVEAL_SECONDS := 0.18
const DIRECT_PROMPT_REVEAL_SECONDS := 0.08
const FEEDBACK_DURATION := 0.42

@onready var backdrop: Node2D = $Backdrop
@onready var environment: Node2D = $Environment
@onready var zones_root: Node2D = $Zones
@onready var spawn_point: Marker2D = $SpawnPoint
@onready var day_player: DayPlayerController = $DayPlayer
@onready var hud_layer: CanvasLayer = $HUDLayer
@onready var hud: DayHud = $HUDLayer/DayHud
@onready var daily_orders_board: DailyOrdersBoardView = $HUDLayer/DailyOrdersBoard

var _view_model: Dictionary = {}
var _farm_model: Dictionary = {}
var _zones: Dictionary = {}
var _farm_plot_zones: Dictionary = {}
var _focused_zone_id: String = ""
var _world_built: bool = false
var _farm_plots_root: Node2D = null
var _pickup_root: Node2D = null
var _selected_farm_tool_key: String = ""
var _tile_root: Node2D = null
var _ground_tiles: TileMapLayer = null
var _detail_tiles: TileMapLayer = null
var _scenery_root: Node2D = null
var _ambient_root: Node2D = null
var _world_tile_set: TileSet = null
var _zed_village_sheet: Texture2D = null
var _zed_forest_sheet: Texture2D = null
var _sky_rect: Polygon2D = null
var _cloud_band: Polygon2D = null
var _horizon_glow: Polygon2D = null
var _phase_overlay: Polygon2D = null
var _sun_glow: Polygon2D = null
var _harbor_glow: Polygon2D = null
var _shop_sign: Polygon2D = null
var _restaurant_sign: Polygon2D = null
var _night_beacon_glow: Polygon2D = null
var _shop_open_glows: Array[Polygon2D] = []
var _shop_open_props: Array[CanvasItem] = []
var _dock_ready_glows: Array[Polygon2D] = []
var _dock_ready_props: Array[CanvasItem] = []
var _farm_window_glows: Array[Polygon2D] = []
var _restaurant_window_glows: Array[Polygon2D] = []
var _shop_window_glows: Array[Polygon2D] = []
var _dock_gate_root: Node2D = null
var _dock_gate_items: Array[CanvasItem] = []
var _lamp_glows: Array[Polygon2D] = []
var _lamp_lanterns: Array[Polygon2D] = []
var _town_npc_nodes: Dictionary = {}
var _pickup_zones: Dictionary = {}
var _phase_visual_id: String = ""
var _overlay_blocked: bool = false
var _night_popup: Panel = null
var _night_popup_title_label: Label = null
var _night_popup_body_label: Label = null
var _night_popup_confirm_button: Button = null
var _night_popup_cancel_button: Button = null
var _transition_shade: ColorRect = null
var _transition_title_label: Label = null
var _transition_body_label: Label = null
var _night_popup_open: bool = false
var _transition_active: bool = false
var _was_visible: bool = false
var _ambient_motion_time: float = 0.0
var _ambient_motion_items: Array[Dictionary] = []
var _ambient_character_nodes: Dictionary = {}
var _guide_glows: Dictionary = {}
var _guide_glow_targets: Dictionary = {}
var _guide_glow_colors: Dictionary = {}
var _feedback_root: Node2D = null
var _feedback_items: Array[Dictionary] = []
var _prompt_reveal_elapsed: float = 0.0
var _prompt_is_revealed: bool = false


func _ready() -> void:
	visible = false
	_build_world_if_needed()
	_build_overlay_ui()
	_register_zones()
	_rebuild_farm_plots()
	_rebuild_pickups()
	day_player.set_world_bounds(WORLD_BOUNDS)
	day_player.reset_to_position(spawn_point.global_position)
	day_player.focus_changed.connect(_on_player_focus_changed)
	day_player.interaction_requested.connect(_on_player_interaction_requested)
	hud.daily_orders_requested.connect(_toggle_daily_orders_board)
	hud.legacy_requested.connect(func() -> void:
		legacy_requested.emit()
	)
	daily_orders_board.closed.connect(_on_daily_orders_board_closed)
	if Localization != null and Localization.has_signal("language_changed"):
		Localization.language_changed.connect(_on_language_changed)
	if DailyOrders != null and DailyOrders.has_signal("state_changed"):
		DailyOrders.state_changed.connect(_on_daily_orders_state_changed)
	if DailyOrders != null and DailyOrders.has_signal("reward_claimed"):
		DailyOrders.reward_claimed.connect(_on_daily_order_reward_claimed)
	visibility_changed.connect(_on_visibility_changed)
	set_process(true)
	_apply_view_model()
	_sync_visibility_state()


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if _night_popup_open:
		if event.is_action_pressed("ui_cancel"):
			_close_night_popup()
			get_viewport().set_input_as_handled()
		return
	if daily_orders_board != null and daily_orders_board.visible:
		return
	if _overlay_blocked:
		return
	for slot_index in range(HOTBAR_DIRECT_ACTIONS.size()):
		if not event.is_action_pressed(HOTBAR_DIRECT_ACTIONS[slot_index]):
			continue
		_select_hotbar_slot_by_index(slot_index)
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("day_cycle_farm_tool_prev"):
		_cycle_farm_tool(-1)
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("day_cycle_farm_tool_next"):
		_cycle_farm_tool(1)
		get_viewport().set_input_as_handled()


func _process(delta: float) -> void:
	if not _world_built:
		return
	if visible:
		_ambient_motion_time += delta
		_update_prompt_reveal(delta)
	else:
		_prompt_reveal_elapsed = 0.0
		_prompt_is_revealed = false
	_update_ambient_motion()
	_update_guide_glows()
	_update_feedback_effects(delta)


func set_view_model(model: Dictionary) -> void:
	_view_model = model.duplicate(true)
	_rebuild_pickups()
	_apply_view_model()


func set_farm_model(model: Dictionary) -> void:
	_farm_model = model.duplicate(true)
	_sync_selected_farm_tool()
	_rebuild_farm_plots()
	_apply_view_model()


func set_overlay_blocked(blocked: bool) -> void:
	_overlay_blocked = blocked
	if blocked:
		_close_night_popup()
	_sync_visibility_state()
	_apply_view_model()


func snap_player_to_night_dock() -> void:
	if day_player == null:
		return
	day_player.reset_to_position(NIGHT_DOCK_POSITION)


func debug_activate_zone(zone_id: String) -> bool:
	return _activate_zone(zone_id.strip_edges().to_lower())


func debug_attempt_world_interaction(zone_id: String) -> bool:
	var normalized_id := zone_id.strip_edges().to_lower()
	if not visible or normalized_id.is_empty():
		return false
	if _overlay_blocked or _transition_active or _night_popup_open:
		return false
	if daily_orders_board != null and daily_orders_board.visible:
		return false
	return _activate_zone(normalized_id)


func debug_select_farm_tool(action_id: String, seed_id: String = "") -> bool:
	var target_key := _build_tool_key_from_parts(action_id, seed_id)
	if action_id.strip_edges().to_lower() == "hand":
		_selected_farm_tool_key = HOTBAR_HAND_KEY
		_apply_view_model()
		return true
	for tool in _get_farm_tools():
		if _build_tool_key(tool) != target_key:
			continue
		_selected_farm_tool_key = target_key
		_apply_view_model()
		return true
	return false


func debug_interact_farm_plot(plot_index: int) -> bool:
	return _activate_zone("farm_plot_%d" % plot_index)


func debug_confirm_night_departure() -> bool:
	if not _night_popup_open or _transition_active or _overlay_blocked:
		return false
	_begin_night_departure_transition()
	return true


func debug_close_orders_board() -> bool:
	if not visible or daily_orders_board == null or not daily_orders_board.visible:
		return false
	daily_orders_board.close_board()
	return true


func debug_cancel_night_departure() -> bool:
	if not visible or not _night_popup_open or _transition_active:
		return false
	_close_night_popup()
	return true


func debug_get_snapshot() -> Dictionary:
	var selected_tool := _get_selected_farm_tool()
	var selected_slot := _get_selected_hotbar_slot()
	var hud_snapshot: Dictionary = {}
	var orders_board_snapshot: Dictionary = {}
	if hud != null and hud.has_method("debug_get_snapshot"):
		var hud_variant: Variant = hud.call("debug_get_snapshot")
		hud_snapshot = hud_variant if hud_variant is Dictionary else {}
	if daily_orders_board != null and daily_orders_board.has_method("debug_get_snapshot"):
		var orders_variant: Variant = daily_orders_board.call("debug_get_snapshot")
		orders_board_snapshot = orders_variant if orders_variant is Dictionary else {}
	return {
		"focused_zone_id": _focused_zone_id,
		"prompt_text": _build_prompt_text(),
		"phase_idle_cue": _build_phase_idle_cue(),
		"restaurant_cue": _build_restaurant_cue(),
		"shop_cue": _build_shop_cue(),
		"wait_cue": _build_wait_cue(),
		"night_cue": _build_night_cue(),
		"orders_open": daily_orders_board.visible if daily_orders_board != null else false,
		"player_position": day_player.global_position if day_player != null else Vector2.ZERO,
		"phase_visual_id": _phase_visual_id,
		"night_ready": bool(_view_model.get("night_ready", false)),
		"night_enabled": _is_zone_enabled("night"),
		"wait_enabled": _is_zone_enabled("wait"),
		"dock_gate_open": _dock_gate_root == null or not _dock_gate_root.visible,
		"visible_town_npc_count": _count_visible_town_npcs(),
		"overlay_blocked": _overlay_blocked,
		"night_popup_open": _night_popup_open,
		"transition_active": _transition_active,
		"hud_phase": String(hud_snapshot.get("phase", "")),
		"hud_actions_until_evening": int(hud_snapshot.get("actions_until_evening", 0)),
		"hud_clock_status_text": String(hud_snapshot.get("clock_status_text", "")),
		"hud_departure_text": String(hud_snapshot.get("departure_text", "")),
		"hud_prompt_text": String(hud_snapshot.get("prompt_text", "")),
		"hud_guide_title": String(hud_snapshot.get("guide_title", "")),
		"hud_guide_text": String(hud_snapshot.get("guide_text", "")),
		"hud_phase_track_active_index": int(hud_snapshot.get("phase_track_active_index", 0)),
		"orders_board_title_text": String(orders_board_snapshot.get("title_text", "")),
		"orders_board_subtitle_text": String(orders_board_snapshot.get("subtitle_text", "")),
		"orders_board_summary_text": String(orders_board_snapshot.get("summary_text", "")),
		"orders_board_status_text": String(orders_board_snapshot.get("status_text", "")),
		"orders_board_featured_titles": (orders_board_snapshot.get("featured_titles", []) as Array).duplicate(true) if orders_board_snapshot.get("featured_titles", []) is Array else [],
		"orders_board_ordered_titles": (orders_board_snapshot.get("ordered_titles", []) as Array).duplicate(true) if orders_board_snapshot.get("ordered_titles", []) is Array else [],
		"orders_board_ready_count": int(orders_board_snapshot.get("ready_count", 0)),
		"orders_board_featured_count": int(orders_board_snapshot.get("featured_count", 0)),
		"visible_pickup_ids": _get_visible_pickup_ids(),
		"selected_hotbar_id": String(selected_slot.get("id", "")),
		"selected_hotbar_label": String(selected_slot.get("label", "")),
		"selected_farm_tool_action_id": String(selected_slot.get("id", selected_tool.get("id", ""))),
		"selected_farm_tool_seed_id": String(selected_slot.get("seed_id", selected_tool.get("seed_id", ""))),
		"selected_farm_tool_label": String(selected_slot.get("label", _farm_tool_title(selected_tool)))
	}


func apply_restore_state(state_variant: Variant) -> void:
	var state: Dictionary = state_variant if state_variant is Dictionary else {}
	var action_id := String(state.get("day_world_tool_action_id", "hand")).strip_edges().to_lower()
	var seed_id := String(state.get("day_world_tool_seed_id", "")).strip_edges().to_lower()
	if action_id.is_empty():
		action_id = "hand"
	if not debug_select_farm_tool(action_id, seed_id):
		_selected_farm_tool_key = HOTBAR_HAND_KEY
	var orders_open := bool(state.get("day_world_orders_open", false))
	if daily_orders_board != null:
		if orders_open:
			daily_orders_board.open_board()
		else:
			daily_orders_board.close_board()
	if not orders_open and bool(state.get("day_world_night_popup_open", false)) and bool(_view_model.get("night_ready", false)):
		_open_night_popup()
	else:
		_close_night_popup()
	_sync_visibility_state()
	_apply_view_model()


func _build_world_if_needed() -> void:
	if _world_built:
		return
	_world_built = true

	_sky_rect = _add_rect(backdrop, "Sky", Rect2(0.0, 0.0, 1600.0, 980.0), Color(0.65, 0.83, 0.94, 1.0), -20)
	_cloud_band = _add_rect(backdrop, "CloudBand", Rect2(0.0, 24.0, 1600.0, 132.0), Color(0.93, 0.97, 0.99, 0.38), -19)
	_horizon_glow = _add_rect(backdrop, "HorizonGlow", Rect2(0.0, 112.0, 1600.0, 220.0), Color(0.93, 0.92, 0.74, 0.24), -18)
	_phase_overlay = _add_rect(backdrop, "PhaseOverlay", Rect2(0.0, 0.0, 1600.0, 980.0), Color(0.0, 0.0, 0.0, 0.0), -17)
	_sun_glow = _add_ellipse(backdrop, "SunGlow", Vector2(1298.0, 118.0), Vector2(258.0, 178.0), Color(1.0, 0.93, 0.62, 0.18), -18)
	_harbor_glow = _add_ellipse(backdrop, "HarborGlow", Vector2(1186.0, 756.0), Vector2(520.0, 190.0), Color(0.96, 0.79, 0.48, 0.0), -16)
	_ensure_world_layers()
	_paint_world_tiles()
	_build_world_landmarks()

	_create_zone("restaurant", "meta.world.area_restaurant", Vector2(1000.0, 430.0), Vector2(146.0, 96.0), Color(0.96, 0.63, 0.35, 1.0))
	_create_zone("shop", "meta.world.area_shop", Vector2(1296.0, 480.0), Vector2(136.0, 92.0), Color(0.96, 0.82, 0.39, 1.0))
	_create_zone("orders", "meta.world.area_orders", Vector2(1078.0, 598.0), Vector2(124.0, 90.0), Color(0.84, 0.74, 0.42, 1.0))
	_create_zone("wait", "meta.world.area_wait", Vector2(704.0, 772.0), Vector2(132.0, 84.0), Color(0.58, 0.74, 0.44, 1.0))
	_create_zone("night", "meta.world.area_night", Vector2(1252.0, 824.0), Vector2(176.0, 96.0), Color(0.39, 0.74, 0.95, 1.0))

	_farm_plots_root = Node2D.new()
	_farm_plots_root.name = "FarmPlots"
	_farm_plots_root.z_index = 6
	zones_root.add_child(_farm_plots_root)
	_pickup_root = Node2D.new()
	_pickup_root.name = "WorldPickups"
	_pickup_root.z_index = 6
	zones_root.add_child(_pickup_root)
	_feedback_root = Node2D.new()
	_feedback_root.name = "WorldFeedback"
	_feedback_root.z_index = 20
	environment.add_child(_feedback_root)
	_apply_phase_presentation()


func _build_overlay_ui() -> void:
	if hud_layer == null or _night_popup != null:
		return
	_transition_shade = ColorRect.new()
	_transition_shade.name = "NightTransitionShade"
	_transition_shade.visible = false
	_transition_shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_transition_shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	_transition_shade.color = Color(0.04, 0.07, 0.12, 0.0)
	hud_layer.add_child(_transition_shade)

	var transition_margin := MarginContainer.new()
	transition_margin.name = "TransitionMargin"
	transition_margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	transition_margin.add_theme_constant_override("margin_left", 24)
	transition_margin.add_theme_constant_override("margin_top", 24)
	transition_margin.add_theme_constant_override("margin_right", 24)
	transition_margin.add_theme_constant_override("margin_bottom", 24)
	_transition_shade.add_child(transition_margin)

	var transition_box := VBoxContainer.new()
	transition_box.name = "TransitionBox"
	transition_box.alignment = BoxContainer.ALIGNMENT_CENTER
	transition_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	transition_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	transition_box.add_theme_constant_override("separation", 10)
	transition_margin.add_child(transition_box)

	_transition_title_label = Label.new()
	_transition_title_label.theme_type_variation = &"HeadingLabel"
	_transition_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_transition_title_label.text = _t("meta.world.night_transition_title")
	transition_box.add_child(_transition_title_label)

	_transition_body_label = Label.new()
	_transition_body_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_transition_body_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_transition_body_label.theme_type_variation = &"BodyMutedLabel"
	_transition_body_label.text = _t("meta.world.night_transition_body")
	transition_box.add_child(_transition_body_label)

	_night_popup = Panel.new()
	_night_popup.name = "NightDeparturePopup"
	_night_popup.visible = false
	_night_popup.custom_minimum_size = Vector2(480.0, 0.0)
	_night_popup.position = Vector2(560.0, 176.0)
	_night_popup.theme_type_variation = &"OverlayPanel"
	hud_layer.add_child(_night_popup)

	var popup_margin := MarginContainer.new()
	popup_margin.name = "Margin"
	popup_margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	popup_margin.add_theme_constant_override("margin_left", 18)
	popup_margin.add_theme_constant_override("margin_top", 16)
	popup_margin.add_theme_constant_override("margin_right", 18)
	popup_margin.add_theme_constant_override("margin_bottom", 16)
	_night_popup.add_child(popup_margin)

	var popup_vbox := VBoxContainer.new()
	popup_vbox.name = "VBox"
	popup_vbox.add_theme_constant_override("separation", 10)
	popup_margin.add_child(popup_vbox)

	_night_popup_title_label = Label.new()
	_night_popup_title_label.theme_type_variation = &"HeadingLabel"
	popup_vbox.add_child(_night_popup_title_label)

	_night_popup_body_label = Label.new()
	_night_popup_body_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	popup_vbox.add_child(_night_popup_body_label)

	var button_row := HBoxContainer.new()
	button_row.name = "Buttons"
	button_row.add_theme_constant_override("separation", 10)
	popup_vbox.add_child(button_row)

	_night_popup_confirm_button = Button.new()
	_night_popup_confirm_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_night_popup_confirm_button.custom_minimum_size = Vector2(0.0, 42.0)
	_night_popup_confirm_button.theme_type_variation = &"PrimaryButton"
	_night_popup_confirm_button.pressed.connect(_begin_night_departure_transition)
	button_row.add_child(_night_popup_confirm_button)

	_night_popup_cancel_button = Button.new()
	_night_popup_cancel_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_night_popup_cancel_button.custom_minimum_size = Vector2(0.0, 42.0)
	_night_popup_cancel_button.theme_type_variation = &"SecondaryButton"
	_night_popup_cancel_button.pressed.connect(_close_night_popup)
	button_row.add_child(_night_popup_cancel_button)

	_update_night_popup_copy()


func _ensure_world_layers() -> void:
	if _tile_root == null:
		_tile_root = Node2D.new()
		_tile_root.name = "TileRoot"
		add_child(_tile_root)
		move_child(_tile_root, environment.get_index())
	if _ground_tiles == null:
		_ground_tiles = TileMapLayer.new()
		_ground_tiles.name = "GroundTiles"
		_ground_tiles.position = GROUND_ORIGIN
		_ground_tiles.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		_ground_tiles.tile_set = _build_world_tileset()
		_tile_root.add_child(_ground_tiles)
	if _detail_tiles == null:
		_detail_tiles = TileMapLayer.new()
		_detail_tiles.name = "DetailTiles"
		_detail_tiles.position = GROUND_ORIGIN
		_detail_tiles.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		_detail_tiles.tile_set = _build_world_tileset()
		_detail_tiles.z_index = 1
		_tile_root.add_child(_detail_tiles)
	if _scenery_root == null:
		_scenery_root = Node2D.new()
		_scenery_root.name = "Scenery"
		_scenery_root.y_sort_enabled = true
		environment.add_child(_scenery_root)
	if _ambient_root == null:
		_ambient_root = Node2D.new()
		_ambient_root.name = "Ambient"
		_ambient_root.y_sort_enabled = true
		environment.add_child(_ambient_root)


func _build_world_tileset() -> TileSet:
	if _world_tile_set != null:
		return _world_tile_set
	var tile_count := 11
	var atlas_image := Image.create(TILE_SIZE * tile_count, TILE_SIZE, false, Image.FORMAT_RGBA8)
	_draw_grass_tile(atlas_image, 0, Color(0.49, 0.70, 0.27, 1.0), Color(0.58, 0.79, 0.35, 1.0), Color(0.39, 0.58, 0.21, 1.0))
	_draw_grass_tile(atlas_image, 1, Color(0.55, 0.74, 0.31, 1.0), Color(0.64, 0.82, 0.39, 1.0), Color(0.45, 0.62, 0.24, 1.0))
	_draw_path_tile(atlas_image, 2, Color(0.72, 0.54, 0.32, 1.0), Color(0.82, 0.64, 0.42, 1.0), Color(0.58, 0.41, 0.23, 1.0))
	_draw_stone_tile(atlas_image, 3, Color(0.68, 0.60, 0.50, 1.0), Color(0.79, 0.71, 0.61, 1.0), Color(0.53, 0.45, 0.37, 1.0))
	_draw_soil_tile(atlas_image, 4, Color(0.46, 0.29, 0.16, 1.0), Color(0.58, 0.38, 0.22, 1.0), Color(0.32, 0.19, 0.11, 1.0))
	_draw_water_tile(atlas_image, 5, Color(0.42, 0.64, 0.78, 1.0), Color(0.66, 0.83, 0.92, 1.0), Color(0.28, 0.47, 0.61, 1.0))
	_draw_dock_tile(atlas_image, 6, Color(0.55, 0.39, 0.24, 1.0), Color(0.71, 0.53, 0.31, 1.0), Color(0.36, 0.25, 0.16, 1.0))
	_draw_grass_tile(atlas_image, 7, Color(0.41, 0.59, 0.21, 1.0), Color(0.49, 0.68, 0.28, 1.0), Color(0.31, 0.47, 0.17, 1.0))
	_draw_flower_tile(atlas_image, 8)
	_draw_path_tile(atlas_image, 9, Color(0.80, 0.67, 0.42, 1.0), Color(0.89, 0.75, 0.49, 1.0), Color(0.64, 0.51, 0.30, 1.0))
	_draw_foam_tile(atlas_image, 10)
	var atlas_texture := ImageTexture.create_from_image(atlas_image)
	var tile_set := TileSet.new()
	tile_set.tile_size = Vector2i(TILE_SIZE, TILE_SIZE)
	var source := TileSetAtlasSource.new()
	source.texture = atlas_texture
	source.texture_region_size = Vector2i(TILE_SIZE, TILE_SIZE)
	for tile_index in range(tile_count):
		source.create_tile(Vector2i(tile_index, 0))
	tile_set.add_source(source, 0)
	_world_tile_set = tile_set
	return _world_tile_set


func _get_zed_village_sheet() -> Texture2D:
	if _zed_village_sheet == null:
		_zed_village_sheet = load(ZED_VILLAGE_SHEET_PATH) as Texture2D
	return _zed_village_sheet


func _get_zed_forest_sheet() -> Texture2D:
	if _zed_forest_sheet == null:
		_zed_forest_sheet = load(ZED_FOREST_SHEET_PATH) as Texture2D
	return _zed_forest_sheet


func _draw_grass_tile(image: Image, tile_index: int, base: Color, light: Color, dark: Color) -> void:
	_fill_tile_background(image, tile_index, base)
	for y in range(TILE_SIZE):
		for x in range(TILE_SIZE):
			var value := int((x * 11 + y * 17 + tile_index * 13) % 37)
			if value < 4:
				_set_tile_pixel(image, tile_index, x, y, light)
			elif value == 8 or value == 21:
				_set_tile_pixel(image, tile_index, x, y, dark)
			elif value == 15 and y > 3:
				_set_tile_pixel(image, tile_index, x, y, light)
				_set_tile_pixel(image, tile_index, x, y - 1, dark)
	for clump_y in range(6, TILE_SIZE - 4, 10):
		for clump_x in range(4 + int((clump_y + tile_index * 5) % 7), TILE_SIZE - 4, 12):
			for offset in [
				Vector2i(-1, 1),
				Vector2i(0, 0),
				Vector2i(1, -1),
				Vector2i(2, 1)
			]:
				var sample_x: int = clump_x + offset.x
				var sample_y: int = clump_y + offset.y
				if sample_x < 0 or sample_x >= TILE_SIZE or sample_y < 0 or sample_y >= TILE_SIZE:
					continue
				_set_tile_pixel(image, tile_index, sample_x, sample_y, light)
				if sample_y + 1 < TILE_SIZE:
					_set_tile_pixel(image, tile_index, sample_x, sample_y + 1, dark)


func _draw_path_tile(image: Image, tile_index: int, base: Color, light: Color, dark: Color) -> void:
	_fill_tile_background(image, tile_index, base)
	for y in range(TILE_SIZE):
		for x in range(TILE_SIZE):
			var value := int((x * 7 + y * 9 + tile_index * 19) % 29)
			if value < 3:
				_set_tile_pixel(image, tile_index, x, y, light)
			elif value == 8 or value == 15:
				_set_tile_pixel(image, tile_index, x, y, dark)
	for pebble_y in range(8, TILE_SIZE - 6, 12):
		for pebble_x in range(5 + int((pebble_y * 3 + tile_index) % 9), TILE_SIZE - 4, 13):
			for offset in [Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1)]:
				var sample_x: int = pebble_x + offset.x
				var sample_y: int = pebble_y + offset.y
				if sample_x >= TILE_SIZE or sample_y >= TILE_SIZE:
					continue
				_set_tile_pixel(image, tile_index, sample_x, sample_y, light)
	for rut_y in [10, 24, 38]:
		for rut_x in range(4, TILE_SIZE - 4):
			if int((rut_x + rut_y + tile_index) % 7) < 3:
				_set_tile_pixel(image, tile_index, rut_x, rut_y, dark)


func _draw_stone_tile(image: Image, tile_index: int, base: Color, light: Color, dark: Color) -> void:
	_fill_tile_background(image, tile_index, base)
	for row in range(4):
		var seam_y := 4 + row * 11
		var x_offset := 2 + int(((row + tile_index) * 5) % 8)
		for seam_x in range(0, TILE_SIZE, 12):
			for sample_x in range(seam_x, mini(TILE_SIZE, seam_x + 10)):
				_set_tile_pixel(image, tile_index, sample_x, seam_y, dark)
		for x in range(TILE_SIZE):
			if x % 12 == x_offset or x % 12 == x_offset + 1:
				for sample_y in range(maxi(0, seam_y - 3), mini(TILE_SIZE, seam_y + 4)):
					_set_tile_pixel(image, tile_index, x, sample_y, dark)
	for chip_y in range(2, TILE_SIZE, 7):
		for chip_x in range((chip_y * 5 + tile_index) % 9, TILE_SIZE, 11):
			_set_tile_pixel(image, tile_index, chip_x, chip_y, light)


func _draw_soil_tile(image: Image, tile_index: int, base: Color, light: Color, dark: Color) -> void:
	_fill_tile_background(image, tile_index, base)
	for furrow_y in range(6, TILE_SIZE, 10):
		for x in range(2, TILE_SIZE - 2):
			_set_tile_pixel(image, tile_index, x, furrow_y, dark)
			if furrow_y + 1 < TILE_SIZE:
				_set_tile_pixel(image, tile_index, x, furrow_y + 1, light)
	for y in range(TILE_SIZE):
		for x in range(TILE_SIZE):
			var value := int((x * 9 + y * 7 + tile_index) % 31)
			if value == 0 or value == 11:
				_set_tile_pixel(image, tile_index, x, y, light)


func _draw_water_tile(image: Image, tile_index: int, base: Color, light: Color, dark: Color) -> void:
	_fill_tile_background(image, tile_index, base)
	for wave_y in [8, 18, 30, 40]:
		for x in range(2, TILE_SIZE - 2):
			if (x + wave_y) % 11 < 5:
				_set_tile_pixel(image, tile_index, x, wave_y, light)
			elif (x + wave_y) % 7 == 0:
				_set_tile_pixel(image, tile_index, x, wave_y + 1 if wave_y + 1 < TILE_SIZE else wave_y, dark)
	for y in range(TILE_SIZE):
		for x in range(TILE_SIZE):
			if int((x * 7 + y * 3 + tile_index * 5) % 31) == 0:
				_set_tile_pixel(image, tile_index, x, y, light)
	for reed_x in [6, 18, 30, 42]:
		_set_tile_pixel(image, tile_index, reed_x, TILE_SIZE - 10, dark)
		_set_tile_pixel(image, tile_index, reed_x + 1 if reed_x + 1 < TILE_SIZE else reed_x, TILE_SIZE - 12, light)


func _draw_dock_tile(image: Image, tile_index: int, base: Color, light: Color, dark: Color) -> void:
	_fill_tile_background(image, tile_index, base)
	for seam_x in [12, 24, 36]:
		for y in range(TILE_SIZE):
			_set_tile_pixel(image, tile_index, seam_x, y, dark)
	for plank_y in [9, 19, 30, 41]:
		for x in range(2, TILE_SIZE - 2):
			_set_tile_pixel(image, tile_index, x, plank_y, light if (x + plank_y) % 8 < 4 else dark)
	for nail_x in [8, 20, 32, 44]:
		for nail_y in [7, 27, 39]:
			_set_tile_pixel(image, tile_index, nail_x, nail_y, dark)


func _draw_flower_tile(image: Image, tile_index: int) -> void:
	_draw_grass_tile(image, tile_index, Color(0.60, 0.76, 0.46, 0.0), Color(0.73, 0.87, 0.60, 0.0), Color(0.42, 0.59, 0.33, 0.0))
	for y in range(TILE_SIZE):
		for x in range(TILE_SIZE):
			if image.get_pixel(tile_index * TILE_SIZE + x, y).a <= 0.0:
				image.set_pixel(tile_index * TILE_SIZE + x, y, Color(0.0, 0.0, 0.0, 0.0))
	var flower_colors := [
		Color(0.96, 0.92, 0.57, 1.0),
		Color(0.96, 0.74, 0.81, 1.0),
		Color(0.86, 0.92, 0.98, 1.0)
	]
	for i in range(10):
		var flower_x := 6 + int((i * 11) % 34)
		var flower_y := 8 + int((i * 7) % 28)
		_set_tile_pixel(image, tile_index, flower_x, flower_y, flower_colors[i % flower_colors.size()])


func _draw_foam_tile(image: Image, tile_index: int) -> void:
	_fill_tile_background(image, tile_index, Color(0.0, 0.0, 0.0, 0.0))
	for bubble_x in [4, 12, 20, 28, 36, 44]:
		for y in range(6, 14):
			for x in range(-3, 4):
				var sample_x: int = int(bubble_x) + x
				if sample_x < 0 or sample_x >= TILE_SIZE:
					continue
				if absf(float(x)) + absf(float(y - 10)) > 5.0:
					continue
				_set_tile_pixel(image, tile_index, sample_x, y, Color(0.91, 0.97, 0.98, 0.92))


func _fill_tile_background(image: Image, tile_index: int, color: Color) -> void:
	for y in range(TILE_SIZE):
		for x in range(TILE_SIZE):
			_set_tile_pixel(image, tile_index, x, y, color)


func _set_tile_pixel(image: Image, tile_index: int, x: int, y: int, color: Color) -> void:
	image.set_pixel(tile_index * TILE_SIZE + x, y, color)


func _paint_world_tiles() -> void:
	if _ground_tiles == null or _detail_tiles == null:
		return
	_ground_tiles.clear()
	_detail_tiles.clear()
	for y in range(GROUND_ROWS):
		for x in range(GROUND_COLUMNS):
			_ground_tiles.set_cell(Vector2i(x, y), 0, TILE_GRASS)
			if int((x * 7 + y * 13 + x * y) % 29) == 0:
				_detail_tiles.set_cell(Vector2i(x, y), 0, TILE_FLOWERS)

	# Meadow masses and darker border framing keep the scene soft instead of checkerboarded.
	_paint_circle(_ground_tiles, Vector2(5.0, 12.5), Vector2(5.8, 4.6), TILE_MEADOW)
	_paint_circle(_ground_tiles, Vector2(7.2, 15.0), Vector2(3.2, 2.3), TILE_DARK_GRASS)
	_paint_circle(_ground_tiles, Vector2(9.8, 5.6), Vector2(5.4, 2.4), TILE_MEADOW)
	_paint_circle(_ground_tiles, Vector2(20.0, 4.8), Vector2(4.6, 2.4), TILE_MEADOW)
	_paint_circle(_ground_tiles, Vector2(30.0, 6.0), Vector2(3.0, 2.0), TILE_MEADOW)
	_paint_circle(_ground_tiles, Vector2(29.6, 16.1), Vector2(4.2, 2.0), TILE_DARK_GRASS)
	_paint_circle(_ground_tiles, Vector2(2.8, 16.1), Vector2(3.2, 1.8), TILE_DARK_GRASS)

	# Farm courtyard and crop ground.
	_paint_circle(_ground_tiles, Vector2(5.1, 11.9), Vector2(4.2, 2.8), TILE_PATH)
	_paint_circle(_ground_tiles, Vector2(4.0, 12.8), Vector2(2.8, 1.8), TILE_SAND)
	_paint_circle(_ground_tiles, Vector2(5.2, 13.0), Vector2(2.6, 2.0), TILE_SOIL)
	_paint_circle(_ground_tiles, Vector2(7.9, 13.2), Vector2(1.5, 2.3), TILE_PATH)

	# Authored routes from farm to town, then from the square down to the dock.
	_paint_brush_stroke(_ground_tiles, [
		Vector2(0.2, 10.4),
		Vector2(3.4, 10.4),
		Vector2(7.4, 9.8),
		Vector2(11.8, 8.8),
		Vector2(15.8, 8.4)
	], Vector2(1.25, 1.0), TILE_PATH)
	_paint_brush_stroke(_ground_tiles, [
		Vector2(15.0, 8.0),
		Vector2(18.0, 8.0),
		Vector2(21.6, 8.2),
		Vector2(24.8, 8.4)
	], Vector2(1.15, 1.0), TILE_PATH)
	_paint_brush_stroke(_ground_tiles, [
		Vector2(21.8, 10.2),
		Vector2(22.6, 11.8),
		Vector2(23.6, 13.1),
		Vector2(24.6, 14.4)
	], Vector2(1.05, 1.0), TILE_PATH)
	_paint_brush_stroke(_ground_tiles, [
		Vector2(24.8, 14.4),
		Vector2(26.2, 15.0),
		Vector2(28.0, 15.8),
		Vector2(30.0, 16.4)
	], Vector2(1.15, 1.0), TILE_SAND)

	# Town square and dock apron use warmer stone / sand masses instead of flat rectangles.
	_paint_circle(_ground_tiles, Vector2(21.8, 8.0), Vector2(4.8, 3.2), TILE_STONE)
	_paint_circle(_ground_tiles, Vector2(22.8, 10.8), Vector2(3.2, 1.8), TILE_STONE)
	_paint_circle(_ground_tiles, Vector2(24.6, 13.8), Vector2(2.6, 1.6), TILE_SAND)

	# Harbor water and dock.
	_fill_tile_rect(_ground_tiles, Rect2i(26, 10, 8, 8), TILE_WATER)
	_paint_circle(_ground_tiles, Vector2(30.4, 12.5), Vector2(4.8, 3.6), TILE_WATER)
	_paint_circle(_ground_tiles, Vector2(31.2, 16.2), Vector2(3.8, 2.4), TILE_WATER)
	_paint_brush_stroke(_ground_tiles, [
		Vector2(26.0, 12.0),
		Vector2(28.0, 12.0),
		Vector2(29.6, 12.4)
	], Vector2(0.9, 0.8), TILE_DOCK)
	_paint_brush_stroke(_ground_tiles, [
		Vector2(28.6, 12.8),
		Vector2(28.6, 14.8),
		Vector2(28.8, 16.8)
	], Vector2(0.8, 0.8), TILE_DOCK)
	_paint_brush_stroke(_ground_tiles, [
		Vector2(25.2, 13.4),
		Vector2(26.6, 13.4),
		Vector2(27.8, 13.6)
	], Vector2(0.8, 0.7), TILE_DOCK)

	# Edge cleanup so paths look walked-in rather than pasted on top.
	_paint_cells(_ground_tiles, [
		Vector2i(0, 9), Vector2i(1, 9), Vector2i(2, 9), Vector2i(8, 10),
		Vector2i(9, 10), Vector2i(13, 8), Vector2i(16, 9), Vector2i(17, 10),
		Vector2i(18, 10), Vector2i(19, 11), Vector2i(25, 10), Vector2i(25, 14),
		Vector2i(24, 15), Vector2i(24, 16), Vector2i(25, 16)
	], TILE_GRASS)
	_paint_cells(_ground_tiles, [
		Vector2i(3, 11), Vector2i(4, 11), Vector2i(5, 10), Vector2i(6, 10),
		Vector2i(20, 5), Vector2i(21, 5), Vector2i(24, 6), Vector2i(25, 6),
		Vector2i(27, 9), Vector2i(27, 10), Vector2i(28, 10)
	], TILE_MEADOW)

	# Flower borders and bank foam sell the cozy, hand-dressed look.
	_paint_cells(_detail_tiles, [
		Vector2i(1, 10), Vector2i(2, 10), Vector2i(3, 10), Vector2i(3, 9),
		Vector2i(8, 9), Vector2i(9, 9), Vector2i(10, 8), Vector2i(14, 8),
		Vector2i(17, 5), Vector2i(18, 5), Vector2i(19, 5), Vector2i(23, 6),
		Vector2i(24, 6), Vector2i(20, 11), Vector2i(21, 11), Vector2i(22, 11),
		Vector2i(24, 12), Vector2i(24, 13), Vector2i(25, 13), Vector2i(26, 13)
	], TILE_FLOWERS)

	for foam_x in range(26, 34):
		_detail_tiles.set_cell(Vector2i(foam_x, 10), 0, TILE_FOAM)
	for foam_y in range(10, 18):
		_detail_tiles.set_cell(Vector2i(26, foam_y), 0, TILE_FOAM)
	_paint_cells(_detail_tiles, [
		Vector2i(30, 12), Vector2i(30, 13), Vector2i(30, 14), Vector2i(31, 15),
		Vector2i(29, 16), Vector2i(32, 14), Vector2i(33, 15)
	], TILE_FOAM)


func _fill_tile_rect(layer: TileMapLayer, rect: Rect2i, atlas_coords: Vector2i) -> void:
	for y in range(rect.position.y, rect.position.y + rect.size.y):
		for x in range(rect.position.x, rect.position.x + rect.size.x):
			layer.set_cell(Vector2i(x, y), 0, atlas_coords)


func _paint_cells(layer: TileMapLayer, cells: Array, atlas_coords: Vector2i) -> void:
	for cell_variant in cells:
		if not (cell_variant is Vector2i):
			continue
		layer.set_cell(cell_variant, 0, atlas_coords)


func _paint_circle(layer: TileMapLayer, center: Vector2, radius: Vector2, atlas_coords: Vector2i) -> void:
	if radius.x <= 0.0 or radius.y <= 0.0:
		return
	for y in range(maxi(0, int(floor(center.y - radius.y))), mini(GROUND_ROWS, int(ceil(center.y + radius.y)) + 1)):
		for x in range(maxi(0, int(floor(center.x - radius.x))), mini(GROUND_COLUMNS, int(ceil(center.x + radius.x)) + 1)):
			var dx := (float(x) + 0.5 - center.x) / radius.x
			var dy := (float(y) + 0.5 - center.y) / radius.y
			if dx * dx + dy * dy > 1.0:
				continue
			layer.set_cell(Vector2i(x, y), 0, atlas_coords)


func _paint_brush_stroke(layer: TileMapLayer, points: Array, radius: Vector2, atlas_coords: Vector2i) -> void:
	if points.is_empty():
		return
	if points.size() == 1 and points[0] is Vector2:
		_paint_circle(layer, points[0] as Vector2, radius, atlas_coords)
		return
	for point_index in range(points.size() - 1):
		if not (points[point_index] is Vector2) or not (points[point_index + 1] is Vector2):
			continue
		var from := points[point_index] as Vector2
		var to := points[point_index + 1] as Vector2
		var steps := maxi(1, int(ceil(from.distance_to(to) * 6.0)))
		for step in range(steps + 1):
			var sample := from.lerp(to, float(step) / float(steps))
			_paint_circle(layer, sample, radius, atlas_coords)


func _build_world_landmarks() -> void:
	if _scenery_root == null or _ambient_root == null:
		return
	for child in _scenery_root.get_children():
		child.free()
	for child in _ambient_root.get_children():
		child.free()
	_lamp_glows.clear()
	_lamp_lanterns.clear()
	_farm_window_glows.clear()
	_restaurant_window_glows.clear()
	_shop_window_glows.clear()
	_town_npc_nodes.clear()
	_ambient_character_nodes.clear()
	_ambient_motion_items.clear()
	_guide_glows.clear()
	_guide_glow_targets.clear()
	_guide_glow_colors.clear()
	_dock_gate_items.clear()
	_shop_sign = null
	_restaurant_sign = null
	_night_beacon_glow = null
	_shop_open_glows.clear()
	_shop_open_props.clear()
	_dock_ready_glows.clear()
	_dock_ready_props.clear()
	_dock_gate_root = null

	# Farm frontage and working yard
	_add_sprite(_scenery_root, "FarmMeadowPatch", _make_region_texture(_get_zed_forest_sheet(), ZED_FOREST_PATCH_DARK_REGION), Vector2(240.0, 662.0), Vector2(1.55, 1.55), Color(1.0, 1.0, 1.0, 0.52), -2)
	_add_shadow(_scenery_root, "FarmHouseShadow", Vector2(272.0, 566.0), Vector2(116.0, 32.0), Color(0.10, 0.13, 0.12, 0.18), -1)
	_add_sprite(_scenery_root, "FarmHouse", _make_region_texture(_get_zed_village_sheet(), ZED_VILLAGE_FARMHOUSE_REGION), Vector2(272.0, 520.0), Vector2(1.42, 1.42), Color(1.0, 0.98, 0.96, 1.0), 0)
	_add_shadow(_scenery_root, "FarmShedShadow", Vector2(428.0, 606.0), Vector2(84.0, 24.0), Color(0.10, 0.13, 0.12, 0.14), -1)
	_add_sprite(_scenery_root, "FarmStand", _make_region_texture(_get_zed_village_sheet(), ZED_VILLAGE_STALL_REGION), Vector2(430.0, 576.0), Vector2(1.45, 1.45), Color(0.98, 0.94, 0.88, 1.0), 0)
	_add_rect(_scenery_root, "FarmPorch", Rect2(220.0, 554.0, 72.0, 24.0), Color(0.79, 0.67, 0.47, 1.0), -1)
	_add_rect(_scenery_root, "FarmShedStep", Rect2(402.0, 592.0, 66.0, 18.0), Color(0.73, 0.60, 0.40, 1.0), -1)
	_farm_window_glows.append(_add_window_glow(_ambient_root, "FarmWindowGlow", Vector2(256.0, 522.0), Vector2(44.0, 24.0), Color(1.0, 0.86, 0.54, 0.0)))
	_add_stone_wall_line("FarmWallNorth", Vector2(192.0, 546.0), 4, true)
	_add_stone_wall_line("FarmWallEast", Vector2(500.0, 612.0), 3, false)
	_add_stone_wall_line("FarmWallSouth", Vector2(226.0, 796.0), 4, true)
	_add_fence_line("FarmFenceNorth", Vector2(154.0, 588.0), 6, true)
	_add_fence_line("FarmFenceWest", Vector2(132.0, 632.0), 4, false)
	_add_fence_line("FarmFenceEast", Vector2(476.0, 632.0), 4, false)
	_add_fence_line("FarmFenceSouthWest", Vector2(164.0, 770.0), 3, true)
	_add_fence_line("FarmFenceSouthEast", Vector2(350.0, 770.0), 2, true)
	_add_crate_cluster("FarmCrates", Vector2(386.0, 608.0), 2, Color(0.72, 0.55, 0.34, 1.0))
	_add_barrel_prop("FarmBarrel", Vector2(444.0, 620.0), Color(0.58, 0.40, 0.24, 1.0))
	_add_planter_box("FarmHerbPatch", Vector2(454.0, 704.0), Color(0.50, 0.82, 0.42, 1.0))
	_add_planter_box("FarmFlowerBox", Vector2(302.0, 588.0), Color(0.96, 0.76, 0.48, 1.0))
	_add_planter_box("FarmSunflowerBox", Vector2(216.0, 594.0), Color(0.95, 0.84, 0.42, 1.0))
	_add_supply_cart("FarmSupplyCart", Vector2(344.0, 688.0), Color(0.73, 0.55, 0.34, 1.0))
	_add_scarecrow("FarmScarecrow", Vector2(236.0, 724.0))
	_register_guide_glow("farm", Vector2(304.0, 694.0), Vector2(276.0, 112.0), Color(0.56, 0.84, 0.44, 0.0))

	# Restaurant frontage
	_add_sprite(_scenery_root, "RestaurantGardenPatch", _make_region_texture(_get_zed_forest_sheet(), ZED_FOREST_PATCH_LIGHT_REGION), Vector2(980.0, 458.0), Vector2(1.35, 1.35), Color(1.0, 1.0, 1.0, 0.28), -2)
	_add_shadow(_scenery_root, "RestaurantShadow", Vector2(990.0, 446.0), Vector2(144.0, 36.0), Color(0.10, 0.13, 0.12, 0.18), -1)
	_add_sprite(_scenery_root, "RestaurantHall", _make_region_texture(_get_zed_village_sheet(), ZED_VILLAGE_RESTAURANT_REGION), Vector2(990.0, 394.0), Vector2(1.56, 1.56), Color(1.0, 0.98, 0.95, 1.0), 0)
	_add_rect(_scenery_root, "RestaurantPatio", Rect2(934.0, 420.0, 122.0, 30.0), Color(0.84, 0.66, 0.44, 1.0), -1)
	_add_market_canopy("RestaurantAwning", Vector2(994.0, 430.0), Vector2(124.0, 24.0), Color(0.81, 0.38, 0.24, 1.0), Color(0.53, 0.27, 0.17, 1.0))
	_restaurant_window_glows.append(_add_window_glow(_ambient_root, "RestaurantGlowLeft", Vector2(950.0, 414.0), Vector2(46.0, 24.0), Color(1.0, 0.78, 0.45, 0.0)))
	_restaurant_window_glows.append(_add_window_glow(_ambient_root, "RestaurantGlowRight", Vector2(1032.0, 414.0), Vector2(46.0, 24.0), Color(1.0, 0.78, 0.45, 0.0)))
	_add_crate_cluster("RestaurantCrates", Vector2(1072.0, 470.0), 2, Color(0.80, 0.58, 0.34, 1.0))
	_add_barrel_prop("RestaurantBarrel", Vector2(924.0, 476.0), Color(0.58, 0.38, 0.23, 1.0))
	_add_planter_box("RestaurantPlanter", Vector2(1070.0, 436.0), Color(0.95, 0.62, 0.38, 1.0))
	_add_stone_wall_line("RestaurantBorderNorth", Vector2(908.0, 374.0), 4, true)
	_add_stone_wall_line("RestaurantBorderWest", Vector2(886.0, 430.0), 2, false)
	var restaurant_menu_stand := _add_a_frame_sign("RestaurantMenuStand", Vector2(896.0, 468.0), Color(0.66, 0.46, 0.27, 1.0), Color(0.96, 0.68, 0.40, 1.0))
	_register_ambient_motion(restaurant_menu_stand, Vector2(0.0, 1.5), 1.1, 0.4)
	_register_guide_glow("restaurant", Vector2(988.0, 458.0), Vector2(188.0, 80.0), Color(1.0, 0.71, 0.44, 0.0))

	# Market stall
	_add_sprite(_scenery_root, "ShopGardenPatch", _make_region_texture(_get_zed_forest_sheet(), ZED_FOREST_PATCH_LIGHT_REGION), Vector2(1294.0, 520.0), Vector2(1.08, 1.08), Color(1.0, 1.0, 1.0, 0.24), -2)
	_add_shadow(_scenery_root, "ShopShadow", Vector2(1292.0, 492.0), Vector2(116.0, 32.0), Color(0.10, 0.13, 0.12, 0.16), -1)
	_add_sprite(_scenery_root, "ShopStoreRoom", _make_region_texture(_get_zed_village_sheet(), ZED_VILLAGE_FARMHOUSE_REGION), Vector2(1300.0, 430.0), Vector2(1.10, 1.10), Color(0.94, 0.98, 1.0, 0.92), -1)
	_add_sprite(_scenery_root, "ShopStall", _make_region_texture(_get_zed_village_sheet(), ZED_VILLAGE_STALL_REGION), Vector2(1292.0, 466.0), Vector2(2.10, 2.10), Color.WHITE, 0)
	_add_rect(_scenery_root, "ShopPad", Rect2(1244.0, 466.0, 100.0, 24.0), Color(0.80, 0.70, 0.47, 1.0), -1)
	_shop_window_glows.append(_add_window_glow(_ambient_root, "ShopGlowLeft", Vector2(1258.0, 454.0), Vector2(34.0, 18.0), Color(1.0, 0.84, 0.55, 0.0)))
	_shop_window_glows.append(_add_window_glow(_ambient_root, "ShopGlowRight", Vector2(1318.0, 454.0), Vector2(34.0, 18.0), Color(1.0, 0.84, 0.55, 0.0)))
	_add_crate_cluster("ShopCrates", Vector2(1362.0, 520.0), 3, Color(0.77, 0.61, 0.39, 1.0))
	_add_barrel_prop("ShopBarrel", Vector2(1240.0, 522.0), Color(0.55, 0.38, 0.24, 1.0))
	_add_planter_box("ShopPlanter", Vector2(1188.0, 512.0), Color(0.84, 0.89, 0.54, 1.0))
	_add_sack_stack("ShopSeedSacks", Vector2(1198.0, 536.0), Color(0.82, 0.72, 0.44, 1.0), Color(0.29, 0.51, 0.28, 1.0), 3)
	_add_tool_rack("ShopToolRack", Vector2(1376.0, 502.0), Color(0.44, 0.61, 0.82, 1.0))
	_add_market_display("ShopSeedDisplay", Vector2(1320.0, 520.0), [
		Color(0.84, 0.91, 0.50, 1.0),
		Color(0.99, 0.78, 0.40, 1.0),
		Color(0.76, 0.89, 0.54, 1.0)
	])
	_add_stone_wall_line("ShopBorderSouth", Vector2(1198.0, 610.0), 3, true)
	var shop_open_board := _add_a_frame_sign("ShopOpenBoard", Vector2(1216.0, 522.0), Color(0.63, 0.45, 0.24, 1.0), Color(0.97, 0.83, 0.44, 1.0))
	_shop_open_props.append(shop_open_board)
	_register_ambient_motion(shop_open_board, Vector2(0.0, 1.4), 1.0, 1.1)
	var shop_pennants := _add_pennant_string("ShopPennants", Vector2(1228.0, 432.0), 136.0, [
		Color(0.37, 0.58, 0.84, 1.0),
		Color(0.96, 0.80, 0.42, 1.0),
		Color(0.76, 0.91, 0.52, 1.0),
		Color(0.91, 0.59, 0.32, 1.0)
	])
	_shop_open_props.append(shop_pennants)
	_register_ambient_motion(shop_pennants, Vector2(0.0, 3.4), 1.7, 0.8)
	_shop_open_glows.append(_add_ellipse(_ambient_root, "ShopEntryGlow", Vector2(1288.0, 510.0), Vector2(174.0, 72.0), Color(1.0, 0.84, 0.56, 0.0), -1))
	_register_guide_glow("shop", Vector2(1288.0, 514.0), Vector2(192.0, 78.0), Color(1.0, 0.84, 0.52, 0.0))

	# Central board and overlook
	_add_notice_board(Vector2(1078.0, 598.0))
	_add_planter_box("BoardPlanterLeft", Vector2(1034.0, 632.0), Color(0.95, 0.88, 0.54, 1.0))
	_add_planter_box("BoardPlanterRight", Vector2(1124.0, 634.0), Color(0.96, 0.74, 0.58, 1.0))
	_add_bench(Vector2(704.0, 772.0))
	_add_stone_wall_line("BoardTerraceSouth", Vector2(1002.0, 670.0), 4, true)
	_add_fence_line("LookoutRail", Vector2(620.0, 754.0), 4, true)
	_add_planter_box("LookoutFlowersLeft", Vector2(650.0, 804.0), Color(0.95, 0.74, 0.62, 1.0))
	_add_planter_box("LookoutFlowersRight", Vector2(756.0, 804.0), Color(0.90, 0.82, 0.50, 1.0))
	_add_direction_post("TownGuidepost", Vector2(836.0, 630.0), [
		{"direction": "left", "color": Color(0.58, 0.82, 0.42, 1.0)},
		{"direction": "right", "color": Color(0.96, 0.68, 0.40, 1.0)},
		{"direction": "right", "color": Color(0.96, 0.82, 0.44, 1.0)},
		{"direction": "right", "color": Color(0.50, 0.80, 1.0, 1.0)}
	])
	_register_guide_glow("orders", Vector2(1078.0, 612.0), Vector2(162.0, 72.0), Color(0.96, 0.81, 0.44, 0.0))

	# Harbor and departure point
	_add_sprite(_scenery_root, "HarborPatch", _make_region_texture(_get_zed_forest_sheet(), ZED_FOREST_POND_REGION), Vector2(1310.0, 776.0), Vector2(1.04, 1.04), Color(1.0, 1.0, 1.0, 0.70), -2)
	_add_shadow(_scenery_root, "NightShadow", Vector2(1240.0, 736.0), Vector2(94.0, 26.0), Color(0.10, 0.13, 0.12, 0.18), -1)
	_add_sprite(_scenery_root, "DockBeaconPost", _make_region_texture(_get_zed_village_sheet(), ZED_VILLAGE_LAMP_REGION), Vector2(1240.0, 694.0), Vector2(2.20, 2.20), Color(0.96, 0.94, 0.90, 1.0), 0)
	_add_rect(_scenery_root, "DockBeaconStep", Rect2(1206.0, 722.0, 74.0, 22.0), Color(0.72, 0.54, 0.31, 1.0), -1)
	_add_post_rope_span("DockRail", Vector2(1138.0, 790.0), 4, true)
	_add_post_rope_span("PierRail", Vector2(1312.0, 724.0), 3, false)
	_add_crate_cluster("DockCargo", Vector2(1108.0, 764.0), 3, Color(0.73, 0.55, 0.34, 1.0))
	_add_barrel_prop("DockBarrel", Vector2(1164.0, 794.0), Color(0.54, 0.38, 0.24, 1.0))
	var dock_skiff := _add_skiff(Vector2(1394.0, 846.0))
	_register_ambient_motion(dock_skiff, Vector2(4.0, 5.0), 0.76, 1.9, 0.02)
	_add_water_rock_prop("HarborRockA", Vector2(1278.0, 748.0), 0)
	_add_water_rock_prop("HarborRockB", Vector2(1362.0, 780.0), 1)
	_add_water_rock_prop("HarborRockC", Vector2(1460.0, 830.0), 2)
	_add_lamp_post("RestaurantLampLeft", Vector2(920.0, 458.0), Color(1.0, 0.82, 0.47, 1.0))
	_add_lamp_post("RestaurantLampRight", Vector2(1060.0, 458.0), Color(1.0, 0.82, 0.47, 1.0))
	_add_lamp_post("ShopLamp", Vector2(1230.0, 512.0), Color(1.0, 0.84, 0.52, 1.0))
	_add_lamp_post("BoardLamp", Vector2(1138.0, 628.0), Color(0.92, 0.80, 0.56, 1.0))
	_add_lamp_post("DockLampWest", Vector2(1174.0, 770.0), Color(0.74, 0.88, 1.0, 1.0))
	_add_lamp_post("DockLampEast", Vector2(1240.0, 790.0), Color(0.74, 0.88, 1.0, 1.0))
	_restaurant_sign = _add_hanging_sign("RestaurantSign", Vector2(996.0, 420.0), Color(0.95, 0.68, 0.40, 1.0), Color(0.48, 0.25, 0.13, 1.0))
	_shop_sign = _add_hanging_sign("ShopSign", Vector2(1292.0, 470.0), Color(0.96, 0.82, 0.43, 1.0), Color(0.49, 0.33, 0.18, 1.0))
	_register_ambient_motion(_restaurant_sign, Vector2(0.0, 2.0), 1.0, 0.2, 0.05)
	_register_ambient_motion(_shop_sign, Vector2(0.0, 2.0), 1.05, 0.8, 0.05)
	_night_beacon_glow = _add_ellipse(_ambient_root, "NightBeaconGlow", Vector2(1240.0, 614.0), Vector2(206.0, 138.0), Color(0.49, 0.79, 1.0, 0.0), -1)
	var dock_signal_flags := _add_pennant_string("DockSignalFlags", Vector2(1188.0, 692.0), 132.0, [
		Color(0.62, 0.86, 1.0, 1.0),
		Color(0.96, 0.82, 0.44, 1.0),
		Color(0.81, 0.93, 0.58, 1.0),
		Color(0.95, 0.63, 0.38, 1.0)
	])
	_dock_ready_props.append(dock_signal_flags)
	_register_ambient_motion(dock_signal_flags, Vector2(0.0, 4.0), 1.8, 1.7)
	_dock_ready_glows.append(_add_ellipse(_ambient_root, "DockRunwayGlow", Vector2(1208.0, 792.0), Vector2(232.0, 84.0), Color(0.54, 0.82, 1.0, 0.0), -1))
	var dock_departure_stand := _add_a_frame_sign("DockDepartureStand", Vector2(1128.0, 778.0), Color(0.44, 0.33, 0.20, 1.0), Color(0.58, 0.84, 1.0, 1.0))
	_dock_ready_props.append(dock_departure_stand)
	_register_ambient_motion(dock_departure_stand, Vector2(0.0, 1.2), 0.92, 1.3)
	_dock_gate_root = _build_dock_gate(Vector2(1178.0, 786.0))
	_register_guide_glow("dock", Vector2(1218.0, 792.0), Vector2(228.0, 94.0), Color(0.58, 0.84, 1.0, 0.0))

	for tree_data in [
		{"name": "TreeNorthWestA", "position": Vector2(92.0, 338.0), "sheet": 0, "scale": Vector2(0.58, 0.58)},
		{"name": "TreeNorthWestB", "position": Vector2(166.0, 304.0), "sheet": 1, "scale": Vector2(0.56, 0.56)},
		{"name": "TreeNorthMeadow", "position": Vector2(684.0, 300.0), "sheet": 3, "scale": Vector2(0.52, 0.52)},
		{"name": "TreeTownNorth", "position": Vector2(878.0, 286.0), "sheet": 2, "scale": Vector2(0.50, 0.50)},
		{"name": "TreeFarmEdge", "position": Vector2(544.0, 340.0), "sheet": 2, "scale": Vector2(0.54, 0.54)},
		{"name": "TreeShopNorth", "position": Vector2(1184.0, 318.0), "sheet": 0, "scale": Vector2(0.50, 0.50)},
		{"name": "TreeHarborNorth", "position": Vector2(1480.0, 324.0), "sheet": 3, "scale": Vector2(0.56, 0.56)},
		{"name": "TreeHarborEast", "position": Vector2(1506.0, 610.0), "sheet": 0, "scale": Vector2(0.54, 0.54)},
		{"name": "TreeHarborSouth", "position": Vector2(1438.0, 804.0), "sheet": 1, "scale": Vector2(0.54, 0.54)}
	]:
		_add_tree_prop(String(tree_data.get("name", "")), tree_data.get("position", Vector2.ZERO), int(tree_data.get("sheet", 0)), tree_data.get("scale", Vector2.ONE))

	for stump_position in [Vector2(390.0, 616.0), Vector2(432.0, 654.0)]:
		_add_shadow(_scenery_root, "StumpShadow%s" % str(stump_position), stump_position, Vector2(20.0, 8.0), Color(0.10, 0.13, 0.12, 0.16), -1)
		_add_sprite(_scenery_root, "Stump%s" % str(stump_position), STUMP_TEXTURE, stump_position - Vector2(0.0, 12.0), Vector2(1.0, 1.0), Color.WHITE, 0)

	for bush_data in [
		{"name": "BushFarmLane", "position": Vector2(542.0, 330.0), "sheet": 0},
		{"name": "BushFarmYard", "position": Vector2(562.0, 366.0), "sheet": 2},
		{"name": "BushTownGuide", "position": Vector2(778.0, 612.0), "sheet": 0},
		{"name": "BushRestaurantWalk", "position": Vector2(878.0, 452.0), "sheet": 1},
		{"name": "BushBoard", "position": Vector2(1184.0, 514.0), "sheet": 1},
		{"name": "BushShopEdge", "position": Vector2(1424.0, 520.0), "sheet": 2},
		{"name": "BushLookout", "position": Vector2(1102.0, 792.0), "sheet": 3},
		{"name": "BushFarmSouth", "position": Vector2(154.0, 818.0), "sheet": 2}
	]:
		_add_bush_prop(String(bush_data.get("name", "")), bush_data.get("position", Vector2.ZERO), int(bush_data.get("sheet", 0)))

	for rock_data in [
		{"name": "FarmRock", "position": Vector2(522.0, 676.0), "texture": 0},
		{"name": "HarborRock", "position": Vector2(1114.0, 708.0), "texture": 2},
		{"name": "PierRock", "position": Vector2(1188.0, 750.0), "texture": 1}
	]:
		_add_rock_prop(String(rock_data.get("name", "")), rock_data.get("position", Vector2.ZERO), int(rock_data.get("texture", 0)))

	_town_npc_nodes["shopkeeper"] = _add_town_npc("ShopkeeperStall", Vector2(1352.0, 554.0), Color(0.76, 0.57, 0.34, 1.0), Color(0.27, 0.45, 0.33, 1.0))
	_town_npc_nodes["regular"] = _add_town_npc("RegularWanderer", Vector2(986.0, 640.0), Color(0.52, 0.72, 0.84, 1.0), Color(0.61, 0.43, 0.25, 1.0))
	_register_ambient_motion(_town_npc_nodes["shopkeeper"] as Node2D, Vector2(0.0, 2.4), 1.2, 0.9)
	_register_ambient_motion(_town_npc_nodes["regular"] as Node2D, Vector2(0.0, 2.8), 1.4, 1.8)
	_ambient_character_nodes["farmhand"] = _add_town_npc("Farmhand", Vector2(398.0, 696.0), Color(0.66, 0.78, 0.46, 1.0), Color(0.58, 0.39, 0.24, 1.0))
	_ambient_character_nodes["restaurant_patron"] = _add_town_npc("RestaurantPatron", Vector2(912.0, 470.0), Color(0.93, 0.62, 0.42, 1.0), Color(0.69, 0.28, 0.22, 1.0))
	_ambient_character_nodes["board_reader"] = _add_town_npc("BoardReader", Vector2(1142.0, 646.0), Color(0.48, 0.67, 0.84, 1.0), Color(0.58, 0.42, 0.26, 1.0))
	_ambient_character_nodes["dockhand"] = _add_town_npc("Dockhand", Vector2(1140.0, 760.0), Color(0.62, 0.82, 0.90, 1.0), Color(0.44, 0.35, 0.25, 1.0))
	_register_ambient_motion(_ambient_character_nodes["farmhand"] as Node2D, Vector2(0.0, 2.4), 1.2, 0.1)
	_register_ambient_motion(_ambient_character_nodes["restaurant_patron"] as Node2D, Vector2(0.0, 2.8), 1.4, 0.7)
	_register_ambient_motion(_ambient_character_nodes["board_reader"] as Node2D, Vector2(0.0, 2.0), 1.0, 1.4)
	_register_ambient_motion(_ambient_character_nodes["dockhand"] as Node2D, Vector2(0.0, 2.6), 1.3, 2.2)


func _make_sheet_frame(texture_sheet: Texture2D, frame_size: Vector2i, frame_index: int = 0) -> AtlasTexture:
	var atlas := AtlasTexture.new()
	var texture_size := texture_sheet.get_size()
	var frame_count := maxi(1, int(texture_size.x / float(frame_size.x)))
	atlas.atlas = texture_sheet
	atlas.region = Rect2(posmod(frame_index, frame_count) * frame_size.x, 0.0, frame_size.x, frame_size.y)
	return atlas


func _make_region_texture(texture_sheet: Texture2D, region: Rect2i) -> AtlasTexture:
	var atlas := AtlasTexture.new()
	atlas.atlas = texture_sheet
	atlas.region = Rect2(region.position, region.size)
	return atlas


func _add_tree_prop(name: String, base_position: Vector2, sheet_index: int, scale_value: Vector2 = Vector2(0.56, 0.56)) -> void:
	var scale_factor := (scale_value.x + scale_value.y) * 0.5
	var region := ZED_FOREST_TREE_LIGHT_REGION
	match posmod(sheet_index, 5):
		1:
			region = ZED_FOREST_TREE_DARK_REGION
		2:
			region = ZED_FOREST_TREE_ROUND_REGION
		3:
			region = ZED_FOREST_TREE_SMALL_REGION
		4:
			region = ZED_FOREST_TREE_PINE_REGION
	var texture := _make_region_texture(_get_zed_forest_sheet(), region)
	_add_shadow(_scenery_root, "%sShadow" % name, base_position + Vector2(0.0, 12.0), Vector2(84.0, 26.0) * scale_factor, Color(0.10, 0.13, 0.12, 0.14), -1)
	_add_sprite(_scenery_root, name, texture, base_position - Vector2(0.0, float(region.size.y) * scale_value.y * 0.46), scale_value * 1.9, Color.WHITE, 0)


func _add_bush_prop(name: String, base_position: Vector2, sheet_index: int, scale_value: Vector2 = Vector2(0.92, 0.92)) -> void:
	var scale_factor := (scale_value.x + scale_value.y) * 0.5
	var region := ZED_FOREST_PATCH_LIGHT_REGION if posmod(sheet_index, 2) == 0 else ZED_FOREST_PATCH_DARK_REGION
	_add_shadow(_scenery_root, "%sShadow" % name, base_position + Vector2(0.0, 6.0), Vector2(50.0, 16.0) * scale_factor, Color(0.10, 0.13, 0.12, 0.10), -1)
	_add_sprite(_scenery_root, name, _make_region_texture(_get_zed_forest_sheet(), region), base_position - Vector2(0.0, 18.0 * scale_value.y), scale_value * 0.72, Color(1.0, 1.0, 1.0, 0.92), 0)


func _add_rock_prop(name: String, base_position: Vector2, texture_index: int, scale_value: Vector2 = Vector2.ONE) -> void:
	var scale_factor := (scale_value.x + scale_value.y) * 0.5
	var region := ZED_FOREST_ROCK_LARGE_REGION if posmod(texture_index, 2) == 0 else ZED_FOREST_ROCK_SMALL_REGION
	_add_shadow(_scenery_root, "%sShadow" % name, base_position + Vector2(0.0, 5.0), Vector2(24.0, 8.0) * scale_factor, Color(0.10, 0.13, 0.12, 0.12), -1)
	_add_sprite(_scenery_root, name, _make_region_texture(_get_zed_forest_sheet(), region), base_position, scale_value * 1.5, Color.WHITE, 0)


func _add_water_rock_prop(name: String, base_position: Vector2, sheet_index: int) -> void:
	var region := ZED_FOREST_WATER_PLANTS_REGION if posmod(sheet_index, 2) == 0 else ZED_FOREST_ROCK_SMALL_REGION
	var scale_value := Vector2(1.2, 1.2) if region == ZED_FOREST_WATER_PLANTS_REGION else Vector2.ONE
	_add_sprite(_ambient_root, name, _make_region_texture(_get_zed_forest_sheet(), region), base_position, scale_value, Color.WHITE, 0)


func _add_fence_line(name: String, start_position: Vector2, segments: int, horizontal: bool) -> Node2D:
	var root := Node2D.new()
	root.name = name
	root.position = start_position
	_scenery_root.add_child(root)
	var spacing := 46.0
	for post_index in range(segments + 1):
		var post := Polygon2D.new()
		post.polygon = _rect_polygon(Vector2(8.0, 28.0))
		post.position = Vector2(post_index * spacing, -12.0) if horizontal else Vector2(0.0, post_index * spacing - 12.0)
		post.color = Color(0.53, 0.35, 0.20, 1.0)
		root.add_child(post)
	for segment_index in range(segments):
		for rail_y in [-16.0, -4.0]:
			var rail := Polygon2D.new()
			rail.polygon = _rect_polygon(Vector2(spacing - 10.0, 6.0))
			rail.position = Vector2(segment_index * spacing + (spacing * 0.5), rail_y) if horizontal else Vector2(0.0, segment_index * spacing + (spacing * 0.5))
			rail.rotation = 0.0 if horizontal else PI * 0.5
			rail.color = Color(0.67, 0.48, 0.28, 1.0)
			root.add_child(rail)
	return root


func _add_stone_wall_line(name: String, start_position: Vector2, segments: int, horizontal: bool) -> Node2D:
	var root := Node2D.new()
	root.name = name
	root.position = start_position
	_scenery_root.add_child(root)
	var spacing := 42.0
	for segment_index in range(segments):
		var stone := Polygon2D.new()
		stone.polygon = _rect_polygon(Vector2(spacing - 6.0, 12.0))
		stone.position = Vector2(segment_index * spacing + spacing * 0.5, 0.0) if horizontal else Vector2(0.0, segment_index * spacing + spacing * 0.5)
		stone.rotation = 0.0 if horizontal else PI * 0.5
		stone.color = Color(0.62, 0.56, 0.48, 1.0)
		root.add_child(stone)
		var cap := Polygon2D.new()
		cap.polygon = _rect_polygon(Vector2(spacing - 10.0, 4.0))
		cap.position = stone.position + (Vector2(0.0, -4.0) if horizontal else Vector2(4.0, 0.0))
		cap.rotation = stone.rotation
		cap.color = Color(0.77, 0.70, 0.62, 1.0)
		root.add_child(cap)
	for post_index in range(segments + 1):
		var post := Polygon2D.new()
		post.polygon = _rect_polygon(Vector2(10.0, 16.0))
		post.position = Vector2(post_index * spacing, 0.0) if horizontal else Vector2(0.0, post_index * spacing)
		post.color = Color(0.55, 0.48, 0.40, 1.0)
		root.add_child(post)
	return root


func _add_crate_cluster(name: String, position: Vector2, crate_count: int, wood_color: Color) -> Node2D:
	var root := Node2D.new()
	root.name = name
	root.position = position
	_scenery_root.add_child(root)
	for crate_index in range(crate_count):
		var offset := Vector2(crate_index * 20.0, float(crate_index % 2) * 12.0)
		_add_shadow(root, "Shadow%d" % crate_index, offset + Vector2(0.0, 8.0), Vector2(24.0, 10.0), Color(0.08, 0.09, 0.08, 0.12), -2)
		var region: Rect2i = ZED_VILLAGE_CRATE_REGIONS[posmod(crate_index, ZED_VILLAGE_CRATE_REGIONS.size())]
		_add_sprite(root, "Crate%d" % crate_index, _make_region_texture(_get_zed_village_sheet(), region), offset, Vector2(1.3, 1.3), Color.WHITE, 0)
	return root


func _add_barrel_prop(name: String, position: Vector2, body_color: Color) -> Node2D:
	var root := Node2D.new()
	root.name = name
	root.position = position
	_scenery_root.add_child(root)
	var shadow := Polygon2D.new()
	shadow.polygon = _ellipse_polygon(Vector2(22.0, 8.0), 10)
	shadow.position = Vector2(0.0, 10.0)
	shadow.color = Color(0.08, 0.09, 0.08, 0.12)
	root.add_child(shadow)
	var body := Polygon2D.new()
	body.polygon = _rect_polygon(Vector2(18.0, 24.0))
	body.position = Vector2(0.0, -2.0)
	body.color = body_color
	root.add_child(body)
	var band_top := Polygon2D.new()
	band_top.polygon = _rect_polygon(Vector2(20.0, 4.0))
	band_top.position = Vector2(0.0, -10.0)
	band_top.color = Color(0.32, 0.23, 0.17, 1.0)
	root.add_child(band_top)
	var band_bottom := band_top.duplicate() as Polygon2D
	band_bottom.position = Vector2(0.0, 2.0)
	root.add_child(band_bottom)
	return root


func _add_planter_box(name: String, position: Vector2, flower_color: Color) -> Node2D:
	var root := Node2D.new()
	root.name = name
	root.position = position
	_scenery_root.add_child(root)
	_add_shadow(root, "Shadow", Vector2(0.0, 8.0), Vector2(34.0, 10.0), Color(0.08, 0.09, 0.08, 0.10), -2)
	var planter_region := ZED_VILLAGE_PLANTER_WOOD_REGION if flower_color.r > flower_color.g else ZED_VILLAGE_PLANTER_STONE_REGION
	_add_sprite(root, "Planter", _make_region_texture(_get_zed_village_sheet(), planter_region), Vector2.ZERO, Vector2(1.5, 1.5), Color.WHITE, 0)
	var pot_region := ZED_VILLAGE_POT_ORANGE_REGION if flower_color.r > flower_color.b else (ZED_VILLAGE_POT_SKY_REGION if flower_color.b > flower_color.g else ZED_VILLAGE_POT_YELLOW_REGION)
	_add_sprite(root, "Bloom", _make_region_texture(_get_zed_village_sheet(), pot_region), Vector2(0.0, -18.0), Vector2(1.2, 1.2), Color.WHITE, 1)
	return root


func _add_market_canopy(name: String, position: Vector2, size: Vector2, cloth_color: Color, trim_color: Color) -> Node2D:
	var root := Node2D.new()
	root.name = name
	root.position = position
	_scenery_root.add_child(root)
	for pole_x in [-size.x * 0.42, size.x * 0.42]:
		var pole := Polygon2D.new()
		pole.polygon = _rect_polygon(Vector2(8.0, 34.0))
		pole.position = Vector2(pole_x, 6.0)
		pole.color = Color(0.55, 0.38, 0.24, 1.0)
		root.add_child(pole)
	var cloth := Polygon2D.new()
	cloth.polygon = PackedVector2Array([
		Vector2(-size.x * 0.5, -size.y * 0.5),
		Vector2(size.x * 0.5, -size.y * 0.5),
		Vector2(size.x * 0.42, size.y * 0.5),
		Vector2(-size.x * 0.42, size.y * 0.5)
	])
	cloth.color = cloth_color
	root.add_child(cloth)
	var trim := Polygon2D.new()
	trim.polygon = _rect_polygon(Vector2(size.x * 0.9, 6.0))
	trim.position = Vector2(0.0, size.y * 0.5)
	trim.color = trim_color
	root.add_child(trim)
	return root


func _add_window_glow(parent: Node, name: String, position: Vector2, size: Vector2, color: Color) -> Polygon2D:
	return _add_ellipse(parent, name, position, size, color, -1)


func _add_post_rope_span(name: String, start_position: Vector2, post_count: int, horizontal: bool) -> Node2D:
	var root := Node2D.new()
	root.name = name
	root.position = start_position
	_ambient_root.add_child(root)
	var spacing := 48.0
	for post_index in range(post_count):
		var post := Polygon2D.new()
		post.polygon = _rect_polygon(Vector2(10.0, 30.0))
		post.position = Vector2(post_index * spacing, -10.0) if horizontal else Vector2(0.0, post_index * spacing - 10.0)
		post.color = Color(0.54, 0.37, 0.23, 1.0)
		root.add_child(post)
		if post_index == post_count - 1:
			continue
		var rope := Polygon2D.new()
		rope.polygon = _rect_polygon(Vector2(spacing - 10.0, 4.0))
		rope.position = Vector2(post_index * spacing + (spacing * 0.5), -12.0) if horizontal else Vector2(0.0, post_index * spacing + (spacing * 0.5) - 12.0)
		rope.rotation = 0.0 if horizontal else PI * 0.5
		rope.color = Color(0.40, 0.29, 0.18, 1.0)
		root.add_child(rope)
	return root


func _add_skiff(position: Vector2) -> Node2D:
	var root := Node2D.new()
	root.name = "DockSkiff"
	root.position = position
	_ambient_root.add_child(root)
	var shadow := Polygon2D.new()
	shadow.polygon = _ellipse_polygon(Vector2(88.0, 22.0), 14)
	shadow.position = Vector2(0.0, 12.0)
	shadow.color = Color(0.05, 0.08, 0.10, 0.18)
	root.add_child(shadow)
	var hull := Polygon2D.new()
	hull.polygon = PackedVector2Array([
		Vector2(-38.0, 6.0),
		Vector2(-22.0, -12.0),
		Vector2(28.0, -10.0),
		Vector2(42.0, 4.0),
		Vector2(30.0, 12.0),
		Vector2(-26.0, 14.0)
	])
	hull.color = Color(0.33, 0.23, 0.18, 1.0)
	root.add_child(hull)
	var trim := Polygon2D.new()
	trim.polygon = _rect_polygon(Vector2(58.0, 4.0))
	trim.position = Vector2(2.0, -8.0)
	trim.color = Color(0.72, 0.56, 0.37, 1.0)
	root.add_child(trim)
	var mast := Polygon2D.new()
	mast.polygon = _rect_polygon(Vector2(6.0, 42.0))
	mast.position = Vector2(-4.0, -24.0)
	mast.color = Color(0.56, 0.39, 0.24, 1.0)
	root.add_child(mast)
	var lantern := Polygon2D.new()
	lantern.polygon = _rect_polygon(Vector2(10.0, 12.0))
	lantern.position = Vector2(-4.0, -44.0)
	lantern.color = Color(0.92, 0.79, 0.48, 1.0)
	root.add_child(lantern)
	return root


func _add_notice_board(base_position: Vector2) -> void:
	var root := Node2D.new()
	root.name = "OrdersBoardProp"
	root.position = base_position
	_scenery_root.add_child(root)
	var shadow := Polygon2D.new()
	shadow.polygon = _ellipse_polygon(Vector2(84.0, 18.0), 12)
	shadow.position = Vector2(0.0, 10.0)
	shadow.color = Color(0.10, 0.13, 0.12, 0.14)
	root.add_child(shadow)
	var post_left := Polygon2D.new()
	post_left.polygon = _rect_polygon(Vector2(10.0, 50.0))
	post_left.position = Vector2(-20.0, -18.0)
	post_left.color = Color(0.49, 0.33, 0.18, 1.0)
	root.add_child(post_left)
	var post_right := post_left.duplicate() as Polygon2D
	post_right.position = Vector2(20.0, -18.0)
	root.add_child(post_right)
	var roof := Polygon2D.new()
	roof.polygon = PackedVector2Array([
		Vector2(-38.0, -70.0),
		Vector2(38.0, -70.0),
		Vector2(26.0, -86.0),
		Vector2(-26.0, -86.0)
	])
	roof.color = Color(0.63, 0.44, 0.26, 1.0)
	root.add_child(roof)
	var board := Polygon2D.new()
	board.polygon = _rect_polygon(Vector2(66.0, 44.0))
	board.position = Vector2(0.0, -48.0)
	board.color = Color(0.81, 0.70, 0.48, 1.0)
	root.add_child(board)
	for note_position in [Vector2(-12.0, -56.0), Vector2(8.0, -48.0), Vector2(0.0, -40.0)]:
		var note := Polygon2D.new()
		note.polygon = _rect_polygon(Vector2(14.0, 12.0))
		note.position = note_position
		note.color = Color(0.97, 0.93, 0.82, 1.0)
		root.add_child(note)


func _add_bench(base_position: Vector2) -> void:
	var root := Node2D.new()
	root.name = "WatchBenchProp"
	root.position = base_position
	_scenery_root.add_child(root)
	_add_shadow(root, "Shadow", Vector2(0.0, 10.0), Vector2(66.0, 16.0), Color(0.10, 0.13, 0.12, 0.14), -2)
	_add_sprite(root, "Bench", _make_region_texture(_get_zed_village_sheet(), ZED_VILLAGE_BENCH_REGION), Vector2.ZERO, Vector2(1.8, 1.8), Color.WHITE, 0)


func _add_supply_cart(name: String, position: Vector2, wood_color: Color) -> Node2D:
	var root := Node2D.new()
	root.name = name
	root.position = position
	_scenery_root.add_child(root)
	_add_shadow(root, "Shadow", Vector2(0.0, 18.0), Vector2(118.0, 24.0), Color(0.10, 0.13, 0.12, 0.16), -2)
	var tray := Polygon2D.new()
	tray.polygon = _rect_polygon(Vector2(92.0, 24.0))
	tray.position = Vector2(0.0, -6.0)
	tray.color = wood_color
	root.add_child(tray)
	var lip := Polygon2D.new()
	lip.polygon = _rect_polygon(Vector2(98.0, 8.0))
	lip.position = Vector2(0.0, -16.0)
	lip.color = Color(wood_color.r * 1.08, wood_color.g * 1.06, wood_color.b * 1.02, 1.0)
	root.add_child(lip)
	for wheel_x in [-28.0, 28.0]:
		var wheel := Polygon2D.new()
		wheel.polygon = _ellipse_polygon(Vector2(22.0, 22.0), 12)
		wheel.position = Vector2(wheel_x, 12.0)
		wheel.color = Color(0.30, 0.22, 0.16, 1.0)
		root.add_child(wheel)
	for crate_offset in [Vector2(-18.0, -18.0), Vector2(18.0, -18.0)]:
		var crate := Polygon2D.new()
		crate.polygon = _rect_polygon(Vector2(28.0, 20.0))
		crate.position = crate_offset
		crate.color = Color(0.77, 0.60, 0.38, 1.0)
		root.add_child(crate)
	return root


func _add_scarecrow(name: String, position: Vector2) -> Node2D:
	var root := Node2D.new()
	root.name = name
	root.position = position
	_ambient_root.add_child(root)
	_add_shadow(root, "Shadow", Vector2(0.0, 16.0), Vector2(36.0, 12.0), Color(0.06, 0.04, 0.03, 0.18), -2)
	var pole := Polygon2D.new()
	pole.polygon = _rect_polygon(Vector2(8.0, 64.0))
	pole.position = Vector2(0.0, -18.0)
	pole.color = Color(0.54, 0.37, 0.23, 1.0)
	root.add_child(pole)
	var arm := Polygon2D.new()
	arm.polygon = _rect_polygon(Vector2(46.0, 6.0))
	arm.position = Vector2(0.0, -46.0)
	arm.color = Color(0.62, 0.44, 0.27, 1.0)
	root.add_child(arm)
	var shirt := Polygon2D.new()
	shirt.polygon = PackedVector2Array([
		Vector2(-18.0, -40.0),
		Vector2(18.0, -40.0),
		Vector2(24.0, -14.0),
		Vector2(-24.0, -14.0)
	])
	shirt.color = Color(0.74, 0.53, 0.29, 1.0)
	root.add_child(shirt)
	var head := Polygon2D.new()
	head.polygon = _ellipse_polygon(Vector2(16.0, 16.0), 10)
	head.position = Vector2(0.0, -56.0)
	head.color = Color(0.93, 0.80, 0.54, 1.0)
	root.add_child(head)
	var hat := Polygon2D.new()
	hat.polygon = PackedVector2Array([
		Vector2(-14.0, -64.0),
		Vector2(14.0, -64.0),
		Vector2(8.0, -76.0),
		Vector2(-8.0, -76.0)
	])
	hat.color = Color(0.45, 0.31, 0.18, 1.0)
	root.add_child(hat)
	return root


func _add_sack_stack(name: String, position: Vector2, sack_color: Color, tie_color: Color, sack_count: int) -> Node2D:
	var root := Node2D.new()
	root.name = name
	root.position = position
	_scenery_root.add_child(root)
	_add_shadow(root, "Shadow", Vector2(0.0, 12.0), Vector2(74.0, 18.0), Color(0.08, 0.09, 0.08, 0.14), -2)
	for sack_index in range(sack_count):
		var x_offset := -20.0 + float(sack_index * 20)
		var y_offset := -6.0 + float(sack_index % 2) * -8.0
		var sack := Polygon2D.new()
		sack.polygon = _ellipse_polygon(Vector2(28.0, 30.0), 12)
		sack.position = Vector2(x_offset, y_offset)
		sack.color = sack_color
		root.add_child(sack)
		var tie := Polygon2D.new()
		tie.polygon = _rect_polygon(Vector2(8.0, 10.0))
		tie.position = Vector2(x_offset, y_offset - 10.0)
		tie.color = tie_color
		root.add_child(tie)
	return root


func _add_tool_rack(name: String, position: Vector2, accent_color: Color) -> Node2D:
	var root := Node2D.new()
	root.name = name
	root.position = position
	_scenery_root.add_child(root)
	_add_shadow(root, "Shadow", Vector2(0.0, 12.0), Vector2(56.0, 16.0), Color(0.08, 0.09, 0.08, 0.12), -2)
	for post_x in [-18.0, 18.0]:
		var post := Polygon2D.new()
		post.polygon = _rect_polygon(Vector2(8.0, 58.0))
		post.position = Vector2(post_x, -18.0)
		post.color = Color(0.55, 0.38, 0.22, 1.0)
		root.add_child(post)
	var rail := Polygon2D.new()
	rail.polygon = _rect_polygon(Vector2(44.0, 8.0))
	rail.position = Vector2(0.0, -42.0)
	rail.color = Color(0.66, 0.49, 0.28, 1.0)
	root.add_child(rail)
	for tool_x in [-14.0, 0.0, 14.0]:
		var handle := Polygon2D.new()
		handle.polygon = _rect_polygon(Vector2(4.0, 28.0))
		handle.position = Vector2(tool_x, -22.0)
		handle.color = Color(0.44, 0.31, 0.19, 1.0)
		root.add_child(handle)
		var head := Polygon2D.new()
		head.polygon = _rect_polygon(Vector2(12.0, 8.0))
		head.position = Vector2(tool_x + 2.0, -10.0)
		head.color = accent_color
		root.add_child(head)
	return root


func _add_market_display(name: String, position: Vector2, item_colors: Array) -> Node2D:
	var root := Node2D.new()
	root.name = name
	root.position = position
	_scenery_root.add_child(root)
	_add_shadow(root, "Shadow", Vector2(0.0, 10.0), Vector2(64.0, 16.0), Color(0.08, 0.09, 0.08, 0.12), -2)
	var table := Polygon2D.new()
	table.polygon = _rect_polygon(Vector2(58.0, 14.0))
	table.position = Vector2(0.0, 0.0)
	table.color = Color(0.66, 0.47, 0.27, 1.0)
	root.add_child(table)
	for item_index in range(item_colors.size()):
		var color_variant: Variant = item_colors[item_index]
		var color: Color = color_variant if color_variant is Color else Color(0.84, 0.88, 0.50, 1.0)
		var item := Polygon2D.new()
		item.polygon = _ellipse_polygon(Vector2(18.0, 14.0), 10)
		item.position = Vector2(-16.0 + float(item_index * 16), -10.0)
		item.color = color
		root.add_child(item)
	return root


func _add_a_frame_sign(name: String, position: Vector2, board_color: Color, accent_color: Color) -> Node2D:
	var root := Node2D.new()
	root.name = name
	root.position = position
	_scenery_root.add_child(root)
	_add_shadow(root, "Shadow", Vector2(0.0, 10.0), Vector2(42.0, 12.0), Color(0.08, 0.09, 0.08, 0.12), -2)
	for leg_x in [-10.0, 10.0]:
		var leg := Polygon2D.new()
		leg.polygon = _rect_polygon(Vector2(4.0, 28.0))
		leg.position = Vector2(leg_x, 0.0)
		leg.color = Color(0.42, 0.29, 0.18, 1.0)
		root.add_child(leg)
	var board := Polygon2D.new()
	board.polygon = _rect_polygon(Vector2(30.0, 24.0))
	board.position = Vector2(0.0, -10.0)
	board.color = board_color
	root.add_child(board)
	var stripe := Polygon2D.new()
	stripe.polygon = _rect_polygon(Vector2(20.0, 6.0))
	stripe.position = Vector2(0.0, -14.0)
	stripe.color = accent_color
	root.add_child(stripe)
	var pin := Polygon2D.new()
	pin.polygon = _ellipse_polygon(Vector2(8.0, 8.0), 8)
	pin.position = Vector2(0.0, -4.0)
	pin.color = Color(0.97, 0.92, 0.78, 1.0)
	root.add_child(pin)
	return root


func _add_direction_post(name: String, position: Vector2, signs: Array) -> Node2D:
	var root := Node2D.new()
	root.name = name
	root.position = position
	_ambient_root.add_child(root)
	_add_shadow(root, "Shadow", Vector2(0.0, 14.0), Vector2(48.0, 14.0), Color(0.06, 0.04, 0.03, 0.14), -2)
	var post := Polygon2D.new()
	post.polygon = _rect_polygon(Vector2(10.0, 86.0))
	post.position = Vector2(0.0, -34.0)
	post.color = Color(0.49, 0.33, 0.19, 1.0)
	root.add_child(post)
	for sign_index in range(signs.size()):
		var sign_variant: Variant = signs[sign_index]
		if not (sign_variant is Dictionary):
			continue
		var sign: Dictionary = sign_variant
		var direction := String(sign.get("direction", "right")).strip_edges().to_lower()
		var side := -1.0 if direction == "left" else 1.0
		var color_variant: Variant = sign.get("color", Color(0.82, 0.72, 0.44, 1.0))
		var sign_color: Color = color_variant if color_variant is Color else Color(0.82, 0.72, 0.44, 1.0)
		var y_offset := -58.0 + float(sign_index * 18)
		var plank := Polygon2D.new()
		plank.polygon = _rect_polygon(Vector2(46.0, 12.0))
		plank.position = Vector2(20.0 * side, y_offset)
		plank.color = sign_color
		root.add_child(plank)
		var pointer := Polygon2D.new()
		pointer.polygon = PackedVector2Array([
			Vector2(10.0 * side, -6.0),
			Vector2(22.0 * side, 0.0),
			Vector2(10.0 * side, 6.0)
		])
		pointer.position = Vector2(41.0 * side, y_offset)
		pointer.color = sign_color
		root.add_child(pointer)
	return root


func _add_pennant_string(name: String, position: Vector2, span: float, pennant_colors: Array) -> Node2D:
	var root := Node2D.new()
	root.name = name
	root.position = position
	_ambient_root.add_child(root)
	var rope := Polygon2D.new()
	rope.polygon = _rect_polygon(Vector2(span, 4.0))
	rope.position = Vector2(span * 0.5, 0.0)
	rope.color = Color(0.39, 0.28, 0.18, 1.0)
	root.add_child(rope)
	var count := maxi(1, pennant_colors.size())
	for pennant_index in range(count):
		var color_variant: Variant = pennant_colors[pennant_index]
		var pennant_color: Color = color_variant if color_variant is Color else Color(0.92, 0.80, 0.42, 1.0)
		var pennant := Polygon2D.new()
		pennant.polygon = PackedVector2Array([
			Vector2(-8.0, 0.0),
			Vector2(8.0, 0.0),
			Vector2(0.0, 18.0)
		])
		pennant.position = Vector2((float(pennant_index) + 0.5) * (span / float(count)), 1.0 + float(pennant_index % 2) * 3.0)
		pennant.color = pennant_color
		root.add_child(pennant)
	return root


func _add_hanging_sign(name: String, position: Vector2, sign_color: Color, trim_color: Color) -> Polygon2D:
	var beam := Polygon2D.new()
	beam.name = "%sBeam" % name
	beam.position = position + Vector2(0.0, -24.0)
	beam.polygon = _rect_polygon(Vector2(42.0, 8.0))
	beam.color = Color(0.43, 0.29, 0.18, 1.0)
	_scenery_root.add_child(beam)
	var chain := Polygon2D.new()
	chain.name = "%sChain" % name
	chain.position = position + Vector2(0.0, -12.0)
	chain.polygon = _rect_polygon(Vector2(6.0, 24.0))
	chain.color = Color(0.39, 0.27, 0.16, 1.0)
	_scenery_root.add_child(chain)
	var sign := Polygon2D.new()
	sign.name = name
	sign.position = position
	sign.polygon = _rect_polygon(Vector2(58.0, 24.0))
	sign.color = sign_color
	_scenery_root.add_child(sign)
	var trim := Polygon2D.new()
	trim.name = "%sTrim" % name
	trim.position = position
	trim.polygon = _rect_polygon(Vector2(42.0, 8.0))
	trim.color = trim_color
	_scenery_root.add_child(trim)
	return sign


func _add_lamp_post(name: String, position: Vector2, glow_color: Color) -> void:
	var root := Node2D.new()
	root.name = name
	root.position = position
	_ambient_root.add_child(root)
	_add_shadow(root, "Shadow", Vector2(0.0, 10.0), Vector2(40.0, 12.0), Color(0.10, 0.13, 0.12, 0.12), -2)
	_add_sprite(root, "Lamp", _make_region_texture(_get_zed_village_sheet(), ZED_VILLAGE_LAMP_REGION), Vector2.ZERO, Vector2(1.7, 1.7), Color.WHITE, 0)
	var glow := _add_ellipse(root, "Glow", Vector2(10.0, -26.0), Vector2(90.0, 60.0), glow_color, -1)
	var lantern := Polygon2D.new()
	lantern.name = "Lantern"
	lantern.position = Vector2(8.0, -26.0)
	lantern.polygon = _rect_polygon(Vector2(14.0, 18.0))
	lantern.color = Color(0.95, 0.80, 0.46, 0.82)
	root.add_child(lantern)
	_lamp_glows.append(glow)
	_lamp_lanterns.append(lantern)


func _build_dock_gate(position: Vector2) -> Node2D:
	var root := Node2D.new()
	root.name = "DockGate"
	root.position = position
	_ambient_root.add_child(root)
	for side in [-1.0, 1.0]:
		var post := Polygon2D.new()
		post.name = "Post%s" % str(side)
		post.position = Vector2(68.0 * side, -12.0)
		post.polygon = _rect_polygon(Vector2(12.0, 40.0))
		post.color = Color(0.54, 0.37, 0.23, 1.0)
		root.add_child(post)
		_dock_gate_items.append(post)
	for plank_index in range(3):
		var plank := Polygon2D.new()
		plank.name = "Plank%d" % plank_index
		plank.polygon = _rect_polygon(Vector2(104.0, 10.0))
		plank.position = Vector2(0.0, -18.0 + (plank_index * 14.0))
		plank.rotation = -0.14 + (plank_index * 0.02)
		plank.color = Color(0.72, 0.55, 0.32, 1.0)
		root.add_child(plank)
		_dock_gate_items.append(plank)
	var rope := Polygon2D.new()
	rope.name = "Rope"
	rope.polygon = _rect_polygon(Vector2(148.0, 6.0))
	rope.position = Vector2(0.0, -30.0)
	rope.color = Color(0.39, 0.28, 0.18, 1.0)
	root.add_child(rope)
	_dock_gate_items.append(rope)
	for side in [-1.0, 1.0]:
		var brace := Polygon2D.new()
		brace.name = "Brace%s" % str(side)
		brace.position = Vector2(56.0 * side, -2.0)
		brace.polygon = _rect_polygon(Vector2(18.0, 28.0))
		brace.color = Color(0.46, 0.34, 0.22, 1.0)
		root.add_child(brace)
		_dock_gate_items.append(brace)
	return root


func _add_town_npc(name: String, position: Vector2, body_color: Color, accent_color: Color) -> Node2D:
	var root := Node2D.new()
	root.name = name
	root.position = position
	_ambient_root.add_child(root)
	var shadow := _add_ellipse(root, "Shadow", Vector2(0.0, 14.0), Vector2(34.0, 12.0), Color(0.03, 0.02, 0.01, 0.22), -2)
	shadow.modulate = Color(1.0, 1.0, 1.0, 0.9)
	var body := Polygon2D.new()
	body.position = Vector2(0.0, 2.0)
	body.polygon = _rect_polygon(Vector2(20.0, 32.0))
	body.color = body_color
	root.add_child(body)
	var accent := Polygon2D.new()
	accent.position = Vector2(6.0, 10.0)
	accent.polygon = _rect_polygon(Vector2(10.0, 14.0))
	accent.color = accent_color
	root.add_child(accent)
	var head := Polygon2D.new()
	head.position = Vector2(0.0, -18.0)
	head.polygon = _ellipse_polygon(Vector2(18.0, 18.0), 10)
	head.color = Color(0.95, 0.76, 0.60, 1.0)
	root.add_child(head)
	return root


func _add_ellipse(parent: Node, name: String, position: Vector2, size: Vector2, color: Color, z_index: int) -> Polygon2D:
	var polygon := Polygon2D.new()
	polygon.name = name
	polygon.position = position
	polygon.polygon = _ellipse_polygon(size, 20)
	polygon.color = color
	polygon.z_index = z_index
	parent.add_child(polygon)
	return polygon


func _add_shadow(parent: Node2D, name: String, position: Vector2, size: Vector2, color: Color, z_index: int) -> void:
	var shadow := Polygon2D.new()
	shadow.name = name
	shadow.position = position
	shadow.polygon = _ellipse_polygon(size, 12)
	shadow.color = color
	shadow.z_index = z_index
	parent.add_child(shadow)


func _ellipse_polygon(size: Vector2, segments: int) -> PackedVector2Array:
	var points := PackedVector2Array()
	var half_size := size * 0.5
	for i in range(segments):
		var angle := TAU * float(i) / float(segments)
		points.append(Vector2(cos(angle) * half_size.x, sin(angle) * half_size.y))
	return points


func _rect_polygon(size: Vector2) -> PackedVector2Array:
	var half_size := size * 0.5
	return PackedVector2Array([
		Vector2(-half_size.x, -half_size.y),
		Vector2(half_size.x, -half_size.y),
		Vector2(half_size.x, half_size.y),
		Vector2(-half_size.x, half_size.y)
	])


func _register_zones() -> void:
	_zones.clear()
	for zone_root_variant in zones_root.get_children():
		if zone_root_variant == _farm_plots_root or zone_root_variant == _pickup_root or not (zone_root_variant is Node2D):
			continue
		var zone_root := zone_root_variant as Node2D
		var area := zone_root.get_node_or_null("Area2D") as Area2D
		var marker := zone_root.get_node_or_null("Marker") as Polygon2D
		var pulse := zone_root.get_node_or_null("Pulse") as Polygon2D
		if area == null:
			continue
		var zone_id := _zone_id_from_area(area)
		_zones[zone_id] = {
			"area": area,
			"marker": marker,
			"pulse": pulse,
			"label_key": String(zone_root.get_meta("label_key", "")),
			"accent": zone_root.get_meta("accent_color", Color.WHITE)
		}


func _rebuild_farm_plots() -> void:
	if _farm_plots_root == null:
		return
	for child in _farm_plots_root.get_children():
		child.free()
	_farm_plot_zones.clear()
	var columns := maxi(1, int(_farm_model.get("columns", 3)))
	var plots_variant: Variant = _farm_model.get("plots", [])
	if not (plots_variant is Array):
		_schedule_focus_refresh()
		return
	for plot_variant in plots_variant:
		if not (plot_variant is Dictionary):
			continue
		_create_farm_plot(plot_variant as Dictionary, columns)
	_schedule_focus_refresh()


func _rebuild_pickups() -> void:
	if _pickup_root == null:
		return
	for child in _pickup_root.get_children():
		child.free()
	_pickup_zones.clear()
	for pickup_variant in _get_day_world_pickups():
		if not (pickup_variant is Dictionary):
			continue
		_create_pickup_zone(pickup_variant as Dictionary)
	_schedule_focus_refresh()


func _create_pickup_zone(pickup: Dictionary) -> void:
	var pickup_id := String(pickup.get("id", "")).strip_edges().to_lower()
	if pickup_id.is_empty():
		return
	var zone_id := "pickup_%s" % pickup_id
	var variant := String(pickup.get("variant", "forage"))
	var accent := _pickup_accent(variant)
	var pickup_root := Node2D.new()
	pickup_root.name = "Pickup%s" % pickup_id.capitalize()
	pickup_root.position = pickup.get("position", Vector2.ZERO)
	_pickup_root.add_child(pickup_root)

	var pulse := Polygon2D.new()
	pulse.name = "Pulse"
	pulse.polygon = _ellipse_polygon(Vector2(44.0, 18.0), 10)
	pulse.position = Vector2(0.0, 10.0)
	pulse.color = Color(accent.r, accent.g, accent.b, 0.14)
	pulse.z_index = 1
	pickup_root.add_child(pulse)

	var shadow := Polygon2D.new()
	shadow.name = "Shadow"
	shadow.polygon = _ellipse_polygon(Vector2(30.0, 10.0), 10)
	shadow.position = Vector2(0.0, 12.0)
	shadow.color = Color(0.04, 0.03, 0.02, 0.28)
	shadow.z_index = 0
	pickup_root.add_child(shadow)

	if variant == "salvage":
		var crate := Polygon2D.new()
		crate.name = "Crate"
		crate.polygon = _rect_polygon(Vector2(26.0, 22.0))
		crate.position = Vector2(0.0, -2.0)
		crate.color = Color(0.63, 0.49, 0.29, 1.0)
		crate.z_index = 3
		pickup_root.add_child(crate)
		for scrap_position in [Vector2(-8.0, -14.0), Vector2(8.0, -10.0)]:
			var scrap := Polygon2D.new()
			scrap.polygon = PackedVector2Array([
				Vector2(-6.0, 2.0),
				Vector2(-2.0, -6.0),
				Vector2(4.0, -4.0),
				Vector2(6.0, 4.0),
				Vector2(-2.0, 6.0)
			])
			scrap.position = scrap_position
			scrap.color = Color(0.76, 0.82, 0.88, 1.0)
			scrap.z_index = 4
			pickup_root.add_child(scrap)
	else:
		var stem := Polygon2D.new()
		stem.name = "Stem"
		stem.polygon = _rect_polygon(Vector2(4.0, 18.0))
		stem.position = Vector2(0.0, -3.0)
		stem.color = Color(0.27, 0.52, 0.20, 1.0)
		stem.z_index = 3
		pickup_root.add_child(stem)
		for leaf_points in [
			PackedVector2Array([Vector2(-2.0, 0.0), Vector2(-18.0, -10.0), Vector2(-8.0, -22.0), Vector2(2.0, -6.0)]),
			PackedVector2Array([Vector2(2.0, 0.0), Vector2(18.0, -10.0), Vector2(8.0, -22.0), Vector2(-2.0, -6.0)]),
			PackedVector2Array([Vector2(0.0, -6.0), Vector2(-10.0, -24.0), Vector2(0.0, -30.0), Vector2(10.0, -24.0)])
		]:
			var leaf := Polygon2D.new()
			leaf.polygon = leaf_points
			leaf.color = accent
			leaf.z_index = 4
			pickup_root.add_child(leaf)

	var marker := Polygon2D.new()
	marker.name = "Marker"
	marker.polygon = PackedVector2Array([
		Vector2(0.0, -12.0),
		Vector2(12.0, 0.0),
		Vector2(0.0, 12.0),
		Vector2(-12.0, 0.0)
	])
	marker.position = Vector2(0.0, -34.0)
	marker.color = Color(accent.r, accent.g, accent.b, 0.34)
	marker.z_index = 5
	pickup_root.add_child(marker)

	var area := Area2D.new()
	area.name = "Pickup%sZone" % pickup_id.capitalize()
	area.set_meta("interaction_id", zone_id)
	area.add_to_group("day_interaction_zone")
	pickup_root.add_child(area)

	var shape := CollisionShape2D.new()
	var rectangle := RectangleShape2D.new()
	rectangle.size = Vector2(52.0, 42.0)
	shape.shape = rectangle
	area.add_child(shape)

	_pickup_zones[zone_id] = {
		"area": area,
		"marker": marker,
		"pulse": pulse,
		"accent": accent,
		"pickup": pickup.duplicate(true)
	}


func _create_zone(zone_id: String, label_key: String, position: Vector2, size: Vector2, accent: Color) -> void:
	var zone_root := Node2D.new()
	zone_root.name = "%sZoneRoot" % zone_id.capitalize()
	zone_root.position = position
	zone_root.set_meta("label_key", label_key)
	zone_root.set_meta("accent_color", accent)
	zones_root.add_child(zone_root)

	var pulse := Polygon2D.new()
	pulse.name = "Pulse"
	pulse.polygon = _ellipse_polygon(Vector2(58.0, 26.0), 10)
	pulse.position = Vector2(0.0, 12.0)
	pulse.color = Color(accent.r, accent.g, accent.b, 0.10)
	pulse.z_index = 2
	zone_root.add_child(pulse)

	var marker := Polygon2D.new()
	marker.name = "Marker"
	marker.polygon = PackedVector2Array([
		Vector2(0.0, -12.0),
		Vector2(12.0, 0.0),
		Vector2(0.0, 12.0),
		Vector2(-12.0, 0.0)
	])
	marker.position = Vector2(0.0, -4.0)
	marker.color = Color(accent.r, accent.g, accent.b, 0.28)
	marker.z_index = 3
	zone_root.add_child(marker)

	var area := Area2D.new()
	area.name = "%sZone" % zone_id.capitalize()
	area.set_meta("interaction_id", zone_id)
	area.add_to_group("day_interaction_zone")
	zone_root.add_child(area)

	var shape := CollisionShape2D.new()
	var rectangle := RectangleShape2D.new()
	rectangle.size = size
	shape.shape = rectangle
	area.add_child(shape)


func _create_farm_plot(plot: Dictionary, columns: int) -> void:
	var plot_index := int(plot.get("index", 0))
	var zone_id := "farm_plot_%d" % plot_index
	var state_id := String(plot.get("state_id", "empty"))
	var accent := _farm_plot_accent(state_id)
	var plot_root := Node2D.new()
	plot_root.name = "FarmPlot%d" % plot_index
	plot_root.position = _farm_plot_position(plot_index, columns)
	_farm_plots_root.add_child(plot_root)

	var pulse := Polygon2D.new()
	pulse.name = "Pulse"
	pulse.polygon = _ellipse_polygon(Vector2(54.0, 24.0), 10)
	pulse.position = Vector2(0.0, 12.0)
	pulse.color = Color(accent.r, accent.g, accent.b, 0.08)
	pulse.z_index = 1
	plot_root.add_child(pulse)

	var marker := Polygon2D.new()
	marker.name = "Marker"
	marker.polygon = PackedVector2Array([
		Vector2(0.0, -12.0),
		Vector2(12.0, 0.0),
		Vector2(0.0, 12.0),
		Vector2(-12.0, 0.0)
	])
	marker.position = Vector2(0.0, -36.0)
	marker.color = Color(accent.r, accent.g, accent.b, 0.18)
	marker.z_index = 5
	plot_root.add_child(marker)

	var shadow := Polygon2D.new()
	shadow.name = "Shadow"
	shadow.position = Vector2(0.0, 18.0)
	shadow.polygon = _plot_polygon(FARM_PLOT_SIZE + Vector2(12.0, 12.0))
	shadow.color = Color(0.04, 0.03, 0.02, 0.34)
	shadow.z_index = 0
	plot_root.add_child(shadow)

	var soil := Polygon2D.new()
	soil.name = "Soil"
	soil.polygon = _plot_polygon(FARM_PLOT_SIZE)
	soil.color = _farm_plot_soil_color(state_id)
	soil.z_index = 2
	plot_root.add_child(soil)

	var moisture := Polygon2D.new()
	moisture.name = "Moisture"
	moisture.position = Vector2(0.0, 4.0)
	moisture.polygon = _plot_polygon(FARM_PLOT_SIZE - Vector2(18.0, 24.0))
	moisture.color = Color(0.22, 0.52, 0.72, 0.34 if state_id == "watered" or state_id == "harvestable" else 0.0)
	moisture.z_index = 3
	plot_root.add_child(moisture)

	var crop_root := _create_farm_crop_visual(state_id)
	crop_root.name = "Crop"
	crop_root.position = Vector2(0.0, -10.0)
	crop_root.z_index = 4
	plot_root.add_child(crop_root)

	var area := Area2D.new()
	area.name = "FarmPlot%dZone" % plot_index
	area.set_meta("interaction_id", zone_id)
	area.add_to_group("day_interaction_zone")
	plot_root.add_child(area)

	var shape := CollisionShape2D.new()
	var rectangle := RectangleShape2D.new()
	rectangle.size = Vector2(FARM_PLOT_SIZE.x + 8.0, FARM_PLOT_SIZE.y + 14.0)
	shape.shape = rectangle
	area.add_child(shape)

	_farm_plot_zones[zone_id] = {
		"area": area,
		"marker": marker,
		"pulse": pulse,
		"accent": accent,
		"plot": plot.duplicate(true)
	}


func _create_farm_crop_visual(state_id: String) -> Node2D:
	var crop_root := Node2D.new()
	if state_id == "empty" or state_id == "tilled":
		var furrow := Polygon2D.new()
		furrow.polygon = PackedVector2Array([
			Vector2(-22.0, 12.0),
			Vector2(-18.0, -12.0),
			Vector2(-8.0, -12.0),
			Vector2(-12.0, 12.0)
		])
		furrow.color = Color(0.35, 0.22, 0.12, 0.42 if state_id == "tilled" else 0.16)
		crop_root.add_child(furrow)
		var furrow_right := furrow.duplicate() as Polygon2D
		furrow_right.position = Vector2(18.0, 0.0)
		crop_root.add_child(furrow_right)
		return crop_root

	var stem := Polygon2D.new()
	stem.polygon = PackedVector2Array([
		Vector2(-4.0, 18.0),
		Vector2(-2.0, -8.0),
		Vector2(2.0, -8.0),
		Vector2(4.0, 18.0)
	])
	stem.color = Color(0.25, 0.56, 0.18, 1.0)
	crop_root.add_child(stem)

	var leaf_left := Polygon2D.new()
	leaf_left.polygon = PackedVector2Array([
		Vector2(-2.0, 2.0),
		Vector2(-26.0, -8.0),
		Vector2(-10.0, -22.0),
		Vector2(2.0, -4.0)
	])
	leaf_left.color = Color(0.36, 0.70, 0.22, 1.0)
	crop_root.add_child(leaf_left)

	var leaf_right := Polygon2D.new()
	leaf_right.polygon = PackedVector2Array([
		Vector2(2.0, 2.0),
		Vector2(26.0, -8.0),
		Vector2(10.0, -22.0),
		Vector2(-2.0, -4.0)
	])
	leaf_right.color = Color(0.42, 0.76, 0.26, 1.0)
	crop_root.add_child(leaf_right)

	if state_id == "planted" or state_id == "watered":
		stem.scale = Vector2(0.72, 0.72)
		leaf_left.scale = Vector2(0.72, 0.72)
		leaf_right.scale = Vector2(0.72, 0.72)
		if state_id == "watered":
			leaf_left.modulate = Color(0.76, 1.0, 0.82, 1.0)
			leaf_right.modulate = Color(0.82, 1.0, 0.88, 1.0)
		return crop_root

	var fruit_left := Polygon2D.new()
	fruit_left.polygon = PackedVector2Array([
		Vector2(-14.0, -6.0),
		Vector2(-6.0, -14.0),
		Vector2(2.0, -6.0),
		Vector2(-6.0, 2.0)
	])
	fruit_left.color = Color(0.98, 0.78, 0.24, 1.0)
	crop_root.add_child(fruit_left)

	var fruit_right := fruit_left.duplicate() as Polygon2D
	fruit_right.position = Vector2(14.0, 6.0)
	fruit_right.color = Color(0.95, 0.56, 0.26, 1.0)
	crop_root.add_child(fruit_right)
	return crop_root


func _plot_polygon(size: Vector2) -> PackedVector2Array:
	var half_width := size.x * 0.5
	var half_height := size.y * 0.5
	return PackedVector2Array([
		Vector2(-half_width * 0.82, 10.0),
		Vector2(-half_width, -half_height * 0.18),
		Vector2(-half_width * 0.58, -half_height),
		Vector2(half_width * 0.58, -half_height),
		Vector2(half_width, -half_height * 0.18),
		Vector2(half_width * 0.82, 10.0),
		Vector2(half_width * 0.56, half_height),
		Vector2(-half_width * 0.56, half_height)
	])


func _farm_plot_position(plot_index: int, columns: int) -> Vector2:
	var safe_columns := maxi(1, columns)
	var column := plot_index % safe_columns
	var row := int(plot_index / safe_columns)
	return FARM_PLOT_ORIGIN + Vector2(column * FARM_PLOT_STEP.x, row * FARM_PLOT_STEP.y)


func _farm_plot_soil_color(state_id: String) -> Color:
	match state_id:
		"empty":
			return Color(0.20, 0.34, 0.18, 1.0)
		"tilled":
			return Color(0.46, 0.29, 0.14, 1.0)
		"planted":
			return Color(0.42, 0.27, 0.13, 1.0)
		"watered":
			return Color(0.31, 0.24, 0.17, 1.0)
		"harvestable":
			return Color(0.49, 0.30, 0.14, 1.0)
	return Color(0.20, 0.34, 0.18, 1.0)


func _farm_plot_accent(state_id: String) -> Color:
	match state_id:
		"empty":
			return Color(0.42, 0.74, 0.38, 1.0)
		"tilled":
			return Color(0.79, 0.58, 0.30, 1.0)
		"planted":
			return Color(0.39, 0.92, 0.44, 1.0)
		"watered":
			return Color(0.34, 0.82, 1.0, 1.0)
		"harvestable":
			return Color(0.99, 0.83, 0.36, 1.0)
	return Color(0.78, 0.88, 0.82, 1.0)


func _pickup_accent(variant: String) -> Color:
	return Color(0.72, 0.84, 0.36, 1.0) if variant == "forage" else Color(0.72, 0.84, 0.94, 1.0)


func _add_rect(parent: Node, name: String, rect: Rect2, color: Color, z_index: int) -> Polygon2D:
	var polygon := Polygon2D.new()
	polygon.name = name
	polygon.position = rect.position
	polygon.polygon = PackedVector2Array([
		Vector2.ZERO,
		Vector2(rect.size.x, 0.0),
		Vector2(rect.size.x, rect.size.y),
		Vector2(0.0, rect.size.y)
	])
	polygon.color = color
	polygon.z_index = z_index
	parent.add_child(polygon)
	return polygon


func _add_sprite(
	parent: Node,
	name: String,
	texture: Texture2D,
	position: Vector2,
	scale_value: Vector2,
	modulate_color: Color,
	z_index: int
) -> Sprite2D:
	var sprite := Sprite2D.new()
	sprite.name = name
	sprite.texture = texture
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.position = position
	sprite.scale = scale_value
	sprite.modulate = modulate_color
	sprite.z_index = z_index
	parent.add_child(sprite)
	return sprite


func _apply_view_model() -> void:
	if hud == null:
		return
	var ready_to_claim: int = 0
	if DailyOrders != null and DailyOrders.has_method("get_ready_to_claim_count"):
		ready_to_claim = int(DailyOrders.call("get_ready_to_claim_count"))
	var selected_slot := _get_selected_hotbar_slot()
	var actions_until_evening := maxi(0, int(_view_model.get("actions_until_evening", 0)))
	var night_ready := bool(_view_model.get("night_ready", false))
	_apply_phase_presentation()
	hud.set_hud_model({
		"current_day": int(_view_model.get("current_day", 1)),
		"phase": String(_view_model.get("phase", "morning")),
		"actions_until_evening": actions_until_evening,
		"night_ready": night_ready,
		"gold": int(_view_model.get("gold", 0)),
		"stamina": int(_view_model.get("stamina", 0)),
		"max_stamina": int(_view_model.get("max_stamina", 0)),
		"action_budget": int(_view_model.get("action_budget", 0)),
		"max_action_budget": int(_view_model.get("max_action_budget", 0)),
		"status_text": String(_view_model.get("status_text", "")),
		"guide_title": String(_view_model.get("guide_title", "")),
		"guide_text": String(_view_model.get("guide_text", "")),
		"move_hint": _t("meta.world.move_hint"),
		"prompt_text": _build_prompt_text(),
		"prompt_visible": _should_show_context_prompt(),
		"ready_orders": ready_to_claim,
		"farm_tool_visible": not _get_hotbar_slots().is_empty(),
		"hotbar_slots": _get_hotbar_slots(),
		"selected_hotbar_key": String(selected_slot.get("key", HOTBAR_HAND_KEY)),
		"hotbar_selected_text": _hotbar_description(selected_slot),
		"hotbar_hint": _t("meta.day_hud.hotbar_hint")
	})
	_update_night_popup_copy()
	_refresh_zone_visuals()


func _update_night_popup_copy() -> void:
	if _night_popup == null:
		return
	if _night_popup_title_label != null:
		_night_popup_title_label.text = _t("meta.world.night_confirm_title")
	if _night_popup_body_label != null:
		_night_popup_body_label.text = _build_night_confirmation_text()
	if _night_popup_confirm_button != null:
		_night_popup_confirm_button.text = _t("meta.world.night_confirm_launch")
		_night_popup_confirm_button.disabled = _transition_active or not bool(_view_model.get("night_ready", false))
	if _night_popup_cancel_button != null:
		_night_popup_cancel_button.text = _t("meta.world.night_confirm_cancel")
	_night_popup.visible = visible and _night_popup_open
	if _transition_title_label != null:
		_transition_title_label.text = _t("meta.world.night_transition_title")
	if _transition_body_label != null:
		_transition_body_label.text = _t("meta.world.night_transition_body")


func _build_night_confirmation_text() -> String:
	if bool(_view_model.get("night_ready", false)):
		return _t("meta.world.night_confirm_ready")
	return _build_night_cue()


func _open_night_popup() -> void:
	if _overlay_blocked or _transition_active or not bool(_view_model.get("night_ready", false)):
		return
	_night_popup_open = true
	_update_night_popup_copy()
	_sync_visibility_state()
	_apply_view_model()


func _close_night_popup() -> void:
	_night_popup_open = false
	if _night_popup != null:
		_night_popup.visible = false
	_sync_visibility_state()
	_apply_view_model()


func _begin_night_departure_transition() -> void:
	if _overlay_blocked or _transition_active or not bool(_view_model.get("night_ready", false)):
		return
	_night_popup_open = false
	_transition_active = true
	_set_transition_visible(true)
	_sync_visibility_state()
	var timer := get_tree().create_timer(NIGHT_TRANSITION_SECONDS)
	timer.timeout.connect(_emit_night_departure, CONNECT_ONE_SHOT)


func _emit_night_departure() -> void:
	if not _transition_active:
		return
	_transition_active = false
	_set_transition_visible(false)
	night_requested.emit()


func _set_transition_visible(active: bool) -> void:
	if _transition_shade == null:
		return
	_transition_shade.visible = active and visible
	_transition_shade.color = Color(0.04, 0.07, 0.12, 0.82 if active else 0.0)


func _apply_phase_presentation() -> void:
	var phase := String(_view_model.get("phase", "morning")).strip_edges().to_lower()
	var night_ready := bool(_view_model.get("night_ready", false))
	var palette := _get_phase_palette(phase)
	_phase_visual_id = phase
	if _sky_rect != null:
		_sky_rect.color = palette["sky"]
	if _cloud_band != null:
		_cloud_band.color = palette["cloud"]
	if _horizon_glow != null:
		_horizon_glow.color = palette["horizon"]
	if _phase_overlay != null:
		_phase_overlay.color = palette["overlay"]
	if _sun_glow != null:
		_sun_glow.color = palette["sun"]
		_sun_glow.position = Vector2(1266.0, 102.0) if phase == "morning" else (Vector2(1322.0, 112.0) if phase == "noon" else (Vector2(1382.0, 132.0) if phase == "afternoon" else Vector2(1428.0, 178.0)))
	if _harbor_glow != null:
		_harbor_glow.color = palette["harbor"]
	if _tile_root != null:
		_tile_root.modulate = palette["ground_modulate"]
	if _scenery_root != null:
		_scenery_root.modulate = palette["scenery_modulate"]
	if _ambient_root != null:
		_ambient_root.modulate = palette["ambient_modulate"]
	if _restaurant_sign != null:
		_restaurant_sign.color = palette["restaurant_sign"]
	if _shop_sign != null:
		_shop_sign.color = palette["shop_sign"]
	var lamp_alpha := float(palette["lamp_alpha"])
	for glow in _lamp_glows:
		if glow == null:
			continue
		glow.color.a = lamp_alpha
	for lantern in _lamp_lanterns:
		if lantern == null:
			continue
		lantern.modulate = Color(1.0, 1.0, 1.0, 0.62 + (lamp_alpha * 0.9))
	for glow in _farm_window_glows:
		if glow == null:
			continue
		glow.color.a = float(palette["farm_window_alpha"])
	for glow in _restaurant_window_glows:
		if glow == null:
			continue
		glow.color.a = float(palette["restaurant_window_alpha"])
	for glow in _shop_window_glows:
		if glow == null:
			continue
		glow.color.a = float(palette["shop_window_alpha"])
	var shop_open_alpha := 0.0
	var shop_open_glow_alpha := 0.0
	match phase:
		"morning":
			shop_open_alpha = 0.70
			shop_open_glow_alpha = 0.08
		"noon":
			shop_open_alpha = 0.82
			shop_open_glow_alpha = 0.12
		"afternoon":
			shop_open_alpha = 0.92
			shop_open_glow_alpha = 0.18
		"evening":
			shop_open_alpha = 1.0
			shop_open_glow_alpha = 0.30
	for cue in _shop_open_props:
		if cue == null:
			continue
		cue.modulate = Color(1.0, 1.0, 1.0, shop_open_alpha)
	for glow in _shop_open_glows:
		if glow == null:
			continue
		glow.color.a = shop_open_glow_alpha
	if _night_beacon_glow != null:
		var beacon_alpha := 0.18 if not night_ready else 0.58
		if phase == "night":
			beacon_alpha += 0.08
		_night_beacon_glow.color = Color(0.50, 0.82, 1.0, beacon_alpha)
	var dock_ready_alpha := 0.18
	var dock_ready_glow_alpha := 0.04
	if night_ready:
		dock_ready_alpha = 1.0
		dock_ready_glow_alpha = 0.26 if phase != "night" else 0.34
	elif phase == "afternoon":
		dock_ready_alpha = 0.34
		dock_ready_glow_alpha = 0.08
	for cue in _dock_ready_props:
		if cue == null:
			continue
		cue.modulate = Color(1.0, 1.0, 1.0, dock_ready_alpha)
	for glow in _dock_ready_glows:
		if glow == null:
			continue
		glow.color.a = dock_ready_glow_alpha
	if _dock_gate_root != null:
		_dock_gate_root.visible = not night_ready
	for gate_item in _dock_gate_items:
		if gate_item == null:
			continue
		gate_item.modulate = Color(1.0, 1.0, 1.0, 0.92 if not night_ready else 0.0)
	_apply_town_npc_phase_state(phase)
	_apply_ambient_character_phase_state(phase, night_ready)
	_apply_landmark_guide_state(phase, night_ready)


func _apply_town_npc_phase_state(phase: String) -> void:
	var regular_alpha := 1.0
	var shopkeeper_alpha := 1.0
	match phase:
		"morning":
			regular_alpha = 0.86
		"noon":
			regular_alpha = 1.0
			shopkeeper_alpha = 1.0
		"afternoon":
			regular_alpha = 0.74
			shopkeeper_alpha = 0.88
		"evening":
			regular_alpha = 0.16
			shopkeeper_alpha = 0.0
		"night":
			regular_alpha = 0.0
			shopkeeper_alpha = 0.0
	_update_town_npc_alpha("regular", regular_alpha)
	_update_town_npc_alpha("shopkeeper", shopkeeper_alpha)


func _update_town_npc_alpha(npc_id: String, alpha: float) -> void:
	var npc := _town_npc_nodes.get(npc_id, null) as Node2D
	if npc == null:
		return
	npc.visible = alpha > 0.03
	npc.modulate = Color(1.0, 1.0, 1.0, clampf(alpha, 0.0, 1.0))


func _update_ambient_character_alpha(npc_id: String, alpha: float) -> void:
	var npc := _ambient_character_nodes.get(npc_id, null) as Node2D
	if npc == null:
		return
	npc.visible = alpha > 0.03
	npc.modulate = Color(1.0, 1.0, 1.0, clampf(alpha, 0.0, 1.0))


func _apply_ambient_character_phase_state(phase: String, night_ready: bool) -> void:
	var farmhand_alpha := 0.0
	var patio_alpha := 0.0
	var board_alpha := 0.0
	var dockhand_alpha := 0.0
	match phase:
		"morning":
			farmhand_alpha = 0.86
			board_alpha = 0.58
		"noon":
			farmhand_alpha = 0.44
			board_alpha = 0.70
			patio_alpha = 0.28
		"afternoon":
			board_alpha = 0.20
			patio_alpha = 0.86
			dockhand_alpha = 0.36
		"evening":
			patio_alpha = 0.54
			dockhand_alpha = 0.66
		"night":
			dockhand_alpha = 0.22
	if night_ready:
		dockhand_alpha = maxf(dockhand_alpha, 0.96)
	_update_ambient_character_alpha("farmhand", farmhand_alpha)
	_update_ambient_character_alpha("restaurant_patron", patio_alpha)
	_update_ambient_character_alpha("board_reader", board_alpha)
	_update_ambient_character_alpha("dockhand", dockhand_alpha)


func _register_ambient_motion(node: Node2D, amplitude: Vector2, speed: float, phase_offset: float, rotation_amplitude: float = 0.0) -> void:
	if node == null:
		return
	_ambient_motion_items.append({
		"node": node,
		"base_position": node.position,
		"base_rotation": node.rotation,
		"amplitude": amplitude,
		"speed": speed,
		"phase_offset": phase_offset,
		"rotation_amplitude": rotation_amplitude
	})


func _update_ambient_motion() -> void:
	for item_variant in _ambient_motion_items:
		if not (item_variant is Dictionary):
			continue
		var item := item_variant as Dictionary
		var node := item.get("node", null) as Node2D
		if node == null:
			continue
		var base_position_variant: Variant = item.get("base_position", node.position)
		var base_position: Vector2 = base_position_variant if base_position_variant is Vector2 else node.position
		var amplitude_variant: Variant = item.get("amplitude", Vector2.ZERO)
		var amplitude: Vector2 = amplitude_variant if amplitude_variant is Vector2 else Vector2.ZERO
		var speed := float(item.get("speed", 1.0))
		var phase_offset := float(item.get("phase_offset", 0.0))
		var wave := sin((_ambient_motion_time * speed) + phase_offset)
		var sway := cos((_ambient_motion_time * speed * 0.62) + (phase_offset * 0.7))
		node.position = base_position + Vector2(amplitude.x * sway, amplitude.y * wave)
		node.rotation = float(item.get("base_rotation", 0.0)) + (float(item.get("rotation_amplitude", 0.0)) * wave)


func _register_guide_glow(guide_id: String, position: Vector2, size: Vector2, color: Color) -> void:
	var glow := _add_ellipse(_ambient_root, "%sGuideGlow" % guide_id.capitalize(), position, size, color, -1)
	_guide_glows[guide_id] = glow
	_guide_glow_colors[guide_id] = Color(color.r, color.g, color.b, 1.0)
	_guide_glow_targets[guide_id] = 0.0


func _build_landmark_guide_weights(phase: String, night_ready: bool) -> Dictionary:
	var current_day := maxi(1, int(_view_model.get("current_day", 1)))
	var weights := {
		"farm": 0.0,
		"orders": 0.0,
		"restaurant": 0.0,
		"shop": 0.0,
		"dock": 0.0
	}
	match current_day:
		1:
			weights["farm"] = 0.18 if phase in ["morning", "noon"] else 0.08
			weights["orders"] = 0.12
			weights["restaurant"] = 0.06 if phase == "morning" else 0.12
			weights["shop"] = 0.10 if phase != "evening" else 0.06
			weights["dock"] = 0.06 if phase != "evening" else 0.14
		2:
			weights["farm"] = 0.12 if phase in ["morning", "noon"] else 0.04
			weights["orders"] = 0.10
			weights["restaurant"] = 0.08
			weights["shop"] = 0.08
		_:
			weights["orders"] = 0.06
	if night_ready:
		weights["dock"] = 0.26 if current_day == 1 else 0.18
	var ready_orders := 0
	if DailyOrders != null and DailyOrders.has_method("get_ready_to_claim_count"):
		ready_orders = int(DailyOrders.call("get_ready_to_claim_count"))
	if ready_orders > 0:
		weights["orders"] = maxf(float(weights.get("orders", 0.0)), 0.22)
	if _focused_zone_id == "orders":
		weights["orders"] = float(weights.get("orders", 0.0)) * 0.35
	if _focused_zone_id == "restaurant":
		weights["restaurant"] = float(weights.get("restaurant", 0.0)) * 0.35
	if _focused_zone_id == "shop":
		weights["shop"] = float(weights.get("shop", 0.0)) * 0.35
	if _focused_zone_id == "night":
		weights["dock"] = float(weights.get("dock", 0.0)) * 0.35
	if _is_farm_plot_zone(_focused_zone_id):
		weights["farm"] = float(weights.get("farm", 0.0)) * 0.45
	return weights


func _apply_landmark_guide_state(phase: String, night_ready: bool) -> void:
	var weights := _build_landmark_guide_weights(phase, night_ready)
	for guide_id_variant in _guide_glows.keys():
		var guide_id := String(guide_id_variant)
		_guide_glow_targets[guide_id] = clampf(float(weights.get(guide_id, 0.0)), 0.0, 1.0)


func _update_guide_glows() -> void:
	for guide_id_variant in _guide_glows.keys():
		var guide_id := String(guide_id_variant)
		var glow := _guide_glows.get(guide_id, null) as Polygon2D
		if glow == null:
			continue
		var base_color_variant: Variant = _guide_glow_colors.get(guide_id, Color.WHITE)
		var base_color: Color = base_color_variant if base_color_variant is Color else Color.WHITE
		var target_alpha := clampf(float(_guide_glow_targets.get(guide_id, 0.0)), 0.0, 1.0)
		var wave := 0.82 + (0.18 * sin((_ambient_motion_time * 2.0) + float(posmod(guide_id.hash(), 11))))
		glow.color = Color(base_color.r, base_color.g, base_color.b, target_alpha * wave)


func _count_visible_town_npcs() -> int:
	var count := 0
	for npc_variant in _town_npc_nodes.values():
		if not (npc_variant is Node2D):
			continue
		var npc := npc_variant as Node2D
		if npc.visible and npc.modulate.a > 0.03:
			count += 1
	return count


func _get_phase_palette(phase: String) -> Dictionary:
	match phase:
		"noon":
			return {
				"sky": Color(0.58, 0.81, 0.95, 1.0),
				"cloud": Color(0.99, 0.99, 1.0, 0.22),
				"horizon": Color(0.99, 0.90, 0.66, 0.12),
				"overlay": Color(1.0, 0.95, 0.78, 0.03),
				"sun": Color(1.0, 0.95, 0.68, 0.20),
				"harbor": Color(0.96, 0.77, 0.42, 0.04),
				"ground_modulate": Color(1.02, 1.01, 0.99, 1.0),
				"scenery_modulate": Color(1.03, 1.02, 1.0, 1.0),
				"ambient_modulate": Color(1.0, 1.0, 1.0, 1.0),
				"restaurant_sign": Color(0.98, 0.74, 0.44, 1.0),
				"shop_sign": Color(0.99, 0.86, 0.47, 1.0),
				"lamp_alpha": 0.0,
				"farm_window_alpha": 0.0,
				"restaurant_window_alpha": 0.02,
				"shop_window_alpha": 0.0
			}
		"afternoon":
			return {
				"sky": Color(0.76, 0.78, 0.86, 1.0),
				"cloud": Color(0.99, 0.94, 0.88, 0.18),
				"horizon": Color(0.99, 0.80, 0.52, 0.24),
				"overlay": Color(0.98, 0.74, 0.46, 0.11),
				"sun": Color(0.99, 0.78, 0.47, 0.22),
				"harbor": Color(0.99, 0.72, 0.36, 0.12),
				"ground_modulate": Color(1.0, 0.97, 0.93, 1.0),
				"scenery_modulate": Color(1.02, 0.97, 0.91, 1.0),
				"ambient_modulate": Color(1.0, 0.98, 0.94, 1.0),
				"restaurant_sign": Color(0.96, 0.65, 0.37, 1.0),
				"shop_sign": Color(0.97, 0.78, 0.42, 1.0),
				"lamp_alpha": 0.12,
				"farm_window_alpha": 0.04,
				"restaurant_window_alpha": 0.10,
				"shop_window_alpha": 0.06
			}
		"evening":
			return {
				"sky": Color(0.35, 0.47, 0.67, 1.0),
				"cloud": Color(0.80, 0.74, 0.82, 0.14),
				"horizon": Color(0.98, 0.60, 0.38, 0.34),
				"overlay": Color(0.18, 0.20, 0.31, 0.18),
				"sun": Color(0.99, 0.60, 0.38, 0.14),
				"harbor": Color(0.54, 0.78, 1.0, 0.16),
				"ground_modulate": Color(0.90, 0.90, 0.97, 1.0),
				"scenery_modulate": Color(0.88, 0.89, 0.98, 1.0),
				"ambient_modulate": Color(0.96, 0.95, 1.0, 1.0),
				"restaurant_sign": Color(0.97, 0.73, 0.46, 1.0),
				"shop_sign": Color(0.99, 0.85, 0.50, 1.0),
				"lamp_alpha": 0.34,
				"farm_window_alpha": 0.08,
				"restaurant_window_alpha": 0.44,
				"shop_window_alpha": 0.28
			}
		"night":
			return {
				"sky": Color(0.11, 0.16, 0.28, 1.0),
				"cloud": Color(0.42, 0.46, 0.62, 0.12),
				"horizon": Color(0.24, 0.34, 0.48, 0.20),
				"overlay": Color(0.04, 0.08, 0.18, 0.30),
				"sun": Color(0.40, 0.55, 0.82, 0.06),
				"harbor": Color(0.30, 0.58, 0.90, 0.14),
				"ground_modulate": Color(0.72, 0.78, 0.92, 1.0),
				"scenery_modulate": Color(0.68, 0.74, 0.91, 1.0),
				"ambient_modulate": Color(0.92, 0.95, 1.0, 1.0),
				"restaurant_sign": Color(0.90, 0.73, 0.52, 1.0),
				"shop_sign": Color(0.92, 0.82, 0.54, 1.0),
				"lamp_alpha": 0.46,
				"farm_window_alpha": 0.06,
				"restaurant_window_alpha": 0.16,
				"shop_window_alpha": 0.0
			}
		_:
			return {
				"sky": Color(0.65, 0.83, 0.94, 1.0),
				"cloud": Color(0.93, 0.97, 0.99, 0.38),
				"horizon": Color(0.93, 0.92, 0.74, 0.24),
				"overlay": Color(1.0, 0.98, 0.88, 0.03),
				"sun": Color(1.0, 0.93, 0.62, 0.18),
				"harbor": Color(0.98, 0.84, 0.48, 0.04),
				"ground_modulate": Color(1.0, 1.0, 1.0, 1.0),
				"scenery_modulate": Color(1.0, 1.0, 1.0, 1.0),
				"ambient_modulate": Color(1.0, 1.0, 1.0, 1.0),
				"restaurant_sign": Color(0.95, 0.68, 0.40, 1.0),
				"shop_sign": Color(0.96, 0.82, 0.43, 1.0),
				"lamp_alpha": 0.0,
				"farm_window_alpha": 0.03,
				"restaurant_window_alpha": 0.10,
				"shop_window_alpha": 0.04
			}


func _build_phase_idle_cue() -> String:
	match String(_view_model.get("phase", "morning")).strip_edges().to_lower():
		"noon":
			return _t("meta.world.phase_cue_noon")
		"afternoon":
			return _t("meta.world.phase_cue_afternoon")
		"evening":
			return _t("meta.world.phase_cue_evening")
		"night":
			return _t("meta.world.phase_cue_night")
		_:
			return _t("meta.world.phase_cue_morning")


func _build_restaurant_cue() -> String:
	var phase := String(_view_model.get("phase", "morning"))
	if phase == "night":
		return _t("meta.world.restaurant_cue_night")
	if phase == "evening":
		return _t("meta.world.restaurant_cue_evening")
	return _t("meta.world.restaurant_cue_day")


func _build_shop_cue() -> String:
	var phase := String(_view_model.get("phase", "morning"))
	if phase == "night":
		return _t("meta.world.shop_cue_night")
	if phase == "evening":
		return _t("meta.world.shop_cue_evening")
	return _t("meta.world.shop_cue_day")


func _build_orders_cue() -> String:
	var ready_orders := 0
	if DailyOrders != null and DailyOrders.has_method("get_ready_to_claim_count"):
		ready_orders = int(DailyOrders.call("get_ready_to_claim_count"))
	if ready_orders > 0:
		return _t("meta.world.orders_ready_cue", {"value": ready_orders})
	return _t("meta.world.orders_cue")


func _build_wait_cue() -> String:
	var actions_until_evening := maxi(0, int(_view_model.get("actions_until_evening", 0)))
	if bool(_view_model.get("night_ready", false)):
		return _t("meta.world.wait_cue_ready")
	return _t("meta.world.wait_cue_progress", {"value": actions_until_evening})


func _build_night_cue() -> String:
	var actions_until_evening := maxi(0, int(_view_model.get("actions_until_evening", 0)))
	if bool(_view_model.get("night_ready", false)):
		return _t("meta.world.night_cue_ready")
	return _t("meta.world.night_cue_locked", {"value": actions_until_evening})


func _build_prompt_text() -> String:
	if daily_orders_board != null and daily_orders_board.visible:
		return _t("meta.world.prompt_orders_open")
	if _transition_active:
		return "%s\n%s" % [_t("meta.world.night_transition_title"), _t("meta.world.night_transition_body")]
	if _night_popup_open:
		return "%s\n%s" % [_t("meta.world.night_confirm_title"), _build_night_confirmation_text()]
	if _overlay_blocked:
		return _build_phase_idle_cue()
	if _focused_zone_id.is_empty():
		return "%s\n%s" % [_t("meta.world.prompt_idle"), _build_phase_idle_cue()]
	if _is_pickup_zone(_focused_zone_id):
		return "%s\n%s" % [
			_t("meta.world.prompt_pickup", {"value": _get_zone_name(_focused_zone_id)}),
			_get_zone_tooltip(_focused_zone_id)
		]
	if _is_farm_plot_zone(_focused_zone_id):
		var plot := _get_farm_plot_model(_focused_zone_id)
		if _is_hand_selected():
			var hand_key := "meta.world.prompt_farm_harvest" if _plot_is_harvestable(plot) else "meta.world.prompt_farm_switch"
			return "%s\n%s" % [
				_t(hand_key, {"target": _farm_plot_name(plot)}),
				_farm_plot_summary(plot)
			]
		var tool := _get_selected_farm_tool()
		var plot_summary := _farm_plot_summary(plot)
		if tool.is_empty():
			return "%s\n%s" % [
				_t("meta.world.prompt_farm_unavailable", {"value": _t("meta.farm.tool_none")}),
				plot_summary
			]
		var tool_name := _farm_tool_title(tool)
		var headline := _t("meta.world.prompt_farm_use", {
			"value": tool_name,
			"target": _farm_plot_name(plot)
		})
		if not bool(tool.get("enabled", false)):
			headline = _t("meta.world.prompt_farm_unavailable", {"value": tool_name})
		return "%s\n%s" % [headline, plot_summary]
	var zone_name := _get_zone_name(_focused_zone_id)
	if not _is_zone_enabled(_focused_zone_id):
		return "%s\n%s" % [
			_t("meta.world.prompt_locked", {"value": zone_name}),
			_get_zone_tooltip(_focused_zone_id)
		]
	return "%s\n%s" % [
		_t("meta.world.prompt_interact", {"value": zone_name}),
		_get_zone_tooltip(_focused_zone_id)
	]


func _prompt_reveal_delay(zone_id: String) -> float:
	if _is_pickup_zone(zone_id) or _is_farm_plot_zone(zone_id):
		return DIRECT_PROMPT_REVEAL_SECONDS
	return PROMPT_REVEAL_SECONDS


func _update_prompt_reveal(delta: float) -> void:
	var can_reveal := (
		not _focused_zone_id.is_empty()
		and (daily_orders_board == null or not daily_orders_board.visible)
		and not _transition_active
		and not _night_popup_open
		and not _overlay_blocked
	)
	var changed := false
	if not can_reveal:
		changed = _prompt_is_revealed or _prompt_reveal_elapsed > 0.0
		_prompt_is_revealed = false
		_prompt_reveal_elapsed = 0.0
	else:
		_prompt_reveal_elapsed += delta
		if not _prompt_is_revealed and _prompt_reveal_elapsed >= _prompt_reveal_delay(_focused_zone_id):
			_prompt_is_revealed = true
			changed = true
	if changed:
		_apply_view_model()


func _should_show_context_prompt() -> bool:
	if daily_orders_board != null and daily_orders_board.visible:
		return false
	if _transition_active or _night_popup_open or _overlay_blocked:
		return false
	return not _focused_zone_id.is_empty() and _prompt_is_revealed


func _refresh_zone_visuals() -> void:
	for zone_id_variant in _zones.keys():
		var zone_id := String(zone_id_variant)
		_apply_zone_visual(zone_id, _zones.get(zone_id, {}) as Dictionary, _is_zone_enabled(zone_id), zone_id == _focused_zone_id)
	for zone_id_variant in _pickup_zones.keys():
		var zone_id := String(zone_id_variant)
		_apply_zone_visual(zone_id, _pickup_zones.get(zone_id, {}) as Dictionary, _is_zone_enabled(zone_id), zone_id == _focused_zone_id)
	for zone_id_variant in _farm_plot_zones.keys():
		var zone_id := String(zone_id_variant)
		_apply_zone_visual(zone_id, _farm_plot_zones.get(zone_id, {}) as Dictionary, _is_zone_enabled(zone_id), zone_id == _focused_zone_id)


func _apply_zone_visual(zone_id: String, zone: Dictionary, enabled: bool, focused: bool) -> void:
	var marker := zone.get("marker", null) as Polygon2D
	var pulse := zone.get("pulse", null) as Polygon2D
	var accent_variant: Variant = zone.get("accent", Color.WHITE)
	var accent: Color = _zone_accent_for_state(zone_id, accent_variant if accent_variant is Color else Color.WHITE, enabled)
	var subtle_marker_alpha := 0.12 if not _is_farm_plot_zone(zone_id) and not _is_pickup_zone(zone_id) else 0.0
	var subtle_pulse_alpha := 0.06 if not _is_farm_plot_zone(zone_id) and not _is_pickup_zone(zone_id) else 0.0
	var onboarding_boost := _zone_onboarding_boost(zone_id)
	if onboarding_boost > 0.0:
		subtle_marker_alpha += onboarding_boost * 0.14
		subtle_pulse_alpha += onboarding_boost * 0.10
	if not enabled:
		subtle_marker_alpha *= 0.45
		subtle_pulse_alpha *= 0.45
	if marker != null:
		marker.scale = Vector2.ONE * (1.10 if focused else 0.92)
		marker.color = Color(accent.r, accent.g, accent.b, 0.88 if focused else subtle_marker_alpha)
	if pulse != null:
		pulse.scale = Vector2.ONE * (1.22 if focused else 1.0)
		pulse.color = Color(accent.r, accent.g, accent.b, 0.16 if focused else subtle_pulse_alpha)


func _zone_accent_for_state(zone_id: String, base_accent: Color, enabled: bool) -> Color:
	var phase := String(_view_model.get("phase", "morning")).strip_edges().to_lower()
	if zone_id == "night":
		return Color(0.54, 0.86, 1.0, 1.0) if enabled else Color(0.31, 0.53, 0.73, 1.0)
	if zone_id == "restaurant" and phase == "evening":
		return Color(1.0, 0.72, 0.42, 1.0)
	if zone_id == "shop" and phase == "evening":
		return Color(1.0, 0.84, 0.49, 1.0)
	return base_accent


func _zone_onboarding_boost(zone_id: String) -> float:
	var phase := String(_view_model.get("phase", "morning")).strip_edges().to_lower()
	var weights := _build_landmark_guide_weights(phase, bool(_view_model.get("night_ready", false)))
	if _is_farm_plot_zone(zone_id):
		return float(weights.get("farm", 0.0)) * 0.12
	match zone_id:
		"orders":
			return float(weights.get("orders", 0.0))
		"restaurant":
			return float(weights.get("restaurant", 0.0))
		"shop":
			return float(weights.get("shop", 0.0))
		"night":
			return float(weights.get("dock", 0.0))
	return 0.0


func _is_zone_enabled(zone_id: String) -> bool:
	if _is_pickup_zone(zone_id):
		return true
	if _is_farm_plot_zone(zone_id):
		if _is_hand_selected():
			return _plot_is_harvestable(_get_farm_plot_model(zone_id))
		var tool := _get_selected_farm_tool()
		return not tool.is_empty() and bool(tool.get("available", true))
	match zone_id:
		"wait":
			return not bool(_view_model.get("wait_button_disabled", false))
		"night":
			return not bool(_view_model.get("night_button_disabled", false))
	return true


func _get_zone_name(zone_id: String) -> String:
	if _is_pickup_zone(zone_id):
		return String(_get_pickup_model(zone_id).get("name", ""))
	if _is_farm_plot_zone(zone_id):
		return _farm_plot_name(_get_farm_plot_model(zone_id))
	var zone: Dictionary = _zones.get(zone_id, {}) as Dictionary
	var label_key := String(zone.get("label_key", ""))
	return _t(label_key) if not label_key.is_empty() else zone_id.capitalize()


func _get_zone_tooltip(zone_id: String) -> String:
	if _is_pickup_zone(zone_id):
		return String(_get_pickup_model(zone_id).get("summary", ""))
	if _is_farm_plot_zone(zone_id):
		return _farm_plot_summary(_get_farm_plot_model(zone_id))
	match zone_id:
		"restaurant":
			return _build_restaurant_cue()
		"shop":
			return _build_shop_cue()
		"orders":
			return _build_orders_cue()
		"wait":
			return _build_wait_cue()
		"night":
			return _build_night_cue()
	return ""


func _zone_world_position(zone_id: String) -> Vector2:
	var zone: Dictionary = {}
	if _is_pickup_zone(zone_id):
		zone = _pickup_zones.get(zone_id, {}) as Dictionary
	elif _is_farm_plot_zone(zone_id):
		zone = _farm_plot_zones.get(zone_id, {}) as Dictionary
	else:
		zone = _zones.get(zone_id, {}) as Dictionary
	var area := zone.get("area", null) as Area2D
	if area != null and area.get_parent() is Node2D:
		return (area.get_parent() as Node2D).global_position
	return Vector2.ZERO


func _zone_feedback_accent(zone_id: String) -> Color:
	var zone: Dictionary = {}
	if _is_pickup_zone(zone_id):
		zone = _pickup_zones.get(zone_id, {}) as Dictionary
	elif _is_farm_plot_zone(zone_id):
		zone = _farm_plot_zones.get(zone_id, {}) as Dictionary
	else:
		zone = _zones.get(zone_id, {}) as Dictionary
	var accent_variant: Variant = zone.get("accent", Color(0.92, 0.84, 0.58, 1.0))
	var accent: Color = accent_variant if accent_variant is Color else Color(0.92, 0.84, 0.58, 1.0)
	return _zone_accent_for_state(zone_id, accent, _is_zone_enabled(zone_id))


func _spawn_feedback_effect(position: Vector2, accent: Color, feedback_kind: String) -> void:
	if _feedback_root == null:
		return
	var root := Node2D.new()
	root.name = "Feedback%s" % feedback_kind.capitalize()
	root.position = position
	_feedback_root.add_child(root)

	var ring := Polygon2D.new()
	ring.name = "Ring"
	ring.polygon = _ellipse_polygon(Vector2(42.0, 22.0), 18)
	ring.color = Color(accent.r, accent.g, accent.b, 0.42)
	root.add_child(ring)

	var core := Polygon2D.new()
	core.name = "Core"
	core.polygon = PackedVector2Array([
		Vector2(0.0, -10.0),
		Vector2(10.0, 0.0),
		Vector2(0.0, 10.0),
		Vector2(-10.0, 0.0)
	])
	core.position = Vector2(0.0, -8.0)
	core.color = Color(1.0, 1.0, 1.0, 0.84).lerp(accent, 0.34)
	root.add_child(core)

	var duration := FEEDBACK_DURATION
	var lift := 18.0
	match feedback_kind:
		"water":
			duration = 0.34
			lift = 12.0
		"harvest":
			duration = 0.48
			lift = 22.0
			core.scale = Vector2(1.16, 1.16)
		"pickup":
			duration = 0.38
			lift = 16.0
			core.scale = Vector2(0.88, 0.88)
	_feedback_items.append({
		"root": root,
		"ring": ring,
		"core": core,
		"origin": position,
		"ring_scale": ring.scale,
		"core_scale": core.scale,
		"life": 0.0,
		"duration": duration,
		"lift": lift
	})


func _update_feedback_effects(delta: float) -> void:
	if _feedback_items.is_empty():
		return
	var remaining: Array[Dictionary] = []
	for effect_variant in _feedback_items:
		if not (effect_variant is Dictionary):
			continue
		var effect := effect_variant as Dictionary
		var root := effect.get("root", null) as Node2D
		var ring := effect.get("ring", null) as Polygon2D
		var core := effect.get("core", null) as Polygon2D
		if root == null:
			continue
		var life := float(effect.get("life", 0.0)) + delta
		var duration := maxf(0.001, float(effect.get("duration", FEEDBACK_DURATION)))
		var progress := clampf(life / duration, 0.0, 1.0)
		var origin_variant: Variant = effect.get("origin", root.position)
		var origin: Vector2 = origin_variant if origin_variant is Vector2 else root.position
		root.position = origin + Vector2(0.0, -float(effect.get("lift", 18.0)) * progress)
		if ring != null:
			var ring_scale_variant: Variant = effect.get("ring_scale", Vector2.ONE)
			var ring_scale: Vector2 = ring_scale_variant if ring_scale_variant is Vector2 else Vector2.ONE
			ring.scale = ring_scale * lerpf(0.72, 1.92, progress)
			ring.color = Color(ring.color.r, ring.color.g, ring.color.b, (1.0 - progress) * 0.44)
		if core != null:
			var core_scale_variant: Variant = effect.get("core_scale", Vector2.ONE)
			var core_scale: Vector2 = core_scale_variant if core_scale_variant is Vector2 else Vector2.ONE
			core.scale = core_scale.lerp(Vector2(0.18, 0.18), progress)
			core.rotation = progress * 1.9
			core.color = Color(core.color.r, core.color.g, core.color.b, (1.0 - progress) * 0.86)
		if progress >= 1.0:
			root.queue_free()
			continue
		effect["life"] = life
		remaining.append(effect)
	_feedback_items = remaining


func _play_zone_feedback(zone_id: String, feedback_kind: String = "interact") -> void:
	var position := _zone_world_position(zone_id)
	if position == Vector2.ZERO:
		return
	_spawn_feedback_effect(position, _zone_feedback_accent(zone_id), feedback_kind)


func _activate_zone(zone_id: String) -> bool:
	if zone_id.is_empty():
		return false
	if _overlay_blocked or _transition_active:
		return false
	if _is_pickup_zone(zone_id):
		return _activate_pickup(zone_id)
	if _is_farm_plot_zone(zone_id):
		return _activate_farm_plot(zone_id)
	if not _is_zone_enabled(zone_id):
		_apply_view_model()
		return false
	match zone_id:
		"restaurant":
			_play_zone_feedback(zone_id)
			restaurant_requested.emit()
			return true
		"shop":
			_play_zone_feedback(zone_id)
			shop_requested.emit()
			return true
		"orders":
			_play_zone_feedback(zone_id)
			_toggle_daily_orders_board()
			return true
		"wait":
			_play_zone_feedback(zone_id)
			wait_requested.emit()
			return true
		"night":
			_play_zone_feedback(zone_id)
			_open_night_popup()
			return true
	return false


func _activate_farm_plot(zone_id: String) -> bool:
	var plot := _get_farm_plot_model(zone_id)
	if plot.is_empty():
		_apply_view_model()
		return false
	if _is_hand_selected():
		if not _plot_is_harvestable(plot):
			_apply_view_model()
			return false
		_play_zone_feedback(zone_id, "harvest")
		farm_plot_action_requested.emit(
			int(plot.get("index", -1)),
			"harvest",
			""
		)
		return true
	var tool := _get_selected_farm_tool()
	if tool.is_empty():
		_apply_view_model()
		return false
	var tool_id := String(tool.get("id", "")).strip_edges().to_lower()
	_play_zone_feedback(zone_id, tool_id if not tool_id.is_empty() else "interact")
	farm_plot_action_requested.emit(
		int(plot.get("index", -1)),
		tool_id,
		String(tool.get("seed_id", ""))
	)
	return true


func _activate_pickup(zone_id: String) -> bool:
	var pickup := _get_pickup_model(zone_id)
	if pickup.is_empty():
		_apply_view_model()
		return false
	_play_zone_feedback(zone_id, "pickup")
	var area := (_pickup_zones.get(zone_id, {}) as Dictionary).get("area", null) as Area2D
	if area != null and area.get_parent() is Node2D:
		var pickup_root := area.get_parent() as Node2D
		pickup_root.modulate = Color(1.0, 1.0, 1.0, 0.32)
	world_pickup_requested.emit(String(pickup.get("id", "")))
	return true


func _toggle_daily_orders_board() -> void:
	if daily_orders_board == null:
		return
	if _overlay_blocked or _transition_active:
		return
	if daily_orders_board.visible:
		daily_orders_board.close_board()
	else:
		daily_orders_board.open_board()
	_sync_visibility_state()
	_apply_view_model()


func _sync_visibility_state() -> void:
	var ui_visible := visible
	if hud != null:
		hud.visible = ui_visible
	if not ui_visible and daily_orders_board != null and daily_orders_board.visible:
		daily_orders_board.close_board()
	if day_player != null:
		day_player.set_camera_active(ui_visible)
		day_player.set_controls_enabled(
			ui_visible
			and not _overlay_blocked
			and not _transition_active
			and not _night_popup_open
			and (daily_orders_board == null or not daily_orders_board.visible)
		)
	if _night_popup != null:
		_night_popup.visible = ui_visible and _night_popup_open
	if _transition_shade != null:
		_transition_shade.visible = ui_visible and _transition_active
	_schedule_focus_refresh()


func _schedule_focus_refresh() -> void:
	if day_player != null and day_player.has_method("refresh_interaction_focus"):
		day_player.call_deferred("refresh_interaction_focus")


func _cycle_farm_tool(direction: int) -> void:
	var slots := _get_hotbar_slots()
	if slots.is_empty():
		return
	var current_index := 0
	for slot_index in range(slots.size()):
		if String(slots[slot_index].get("key", "")) != _selected_farm_tool_key:
			continue
		current_index = slot_index
		break
	var next_index := posmod(current_index + direction, slots.size())
	_selected_farm_tool_key = String(slots[next_index].get("key", HOTBAR_HAND_KEY))
	_apply_view_model()


func _select_hotbar_slot_by_index(index: int) -> void:
	var slots := _get_hotbar_slots()
	if index < 0 or index >= slots.size():
		return
	_selected_farm_tool_key = String(slots[index].get("key", HOTBAR_HAND_KEY))
	_apply_view_model()


func _get_hotbar_slots() -> Array:
	var slots: Array = [
		{
			"key": HOTBAR_HAND_KEY,
			"id": "hand",
			"seed_id": "",
			"slot_label": "1",
			"short_label": _t("meta.day_hud.hotbar_hand_short"),
			"label": _t("meta.day_hud.hotbar_hand_short"),
			"enabled": true
		}
	]
	var visible_slot_index := 2
	for tool in _get_farm_tools():
		if not bool(tool.get("available", false)):
			continue
		if String(tool.get("id", "")) == "harvest":
			continue
		var slot: Dictionary = tool.duplicate(true)
		slot["key"] = _build_tool_key(slot)
		slot["slot_label"] = str(visible_slot_index)
		slot["short_label"] = _hotbar_short_label(slot)
		slot["label"] = _hotbar_slot_title(slot)
		slots.append(slot)
		visible_slot_index += 1
	return slots


func _get_farm_tools() -> Array:
	var tools_variant: Variant = _farm_model.get("tools", [])
	var tools_source: Array = tools_variant if tools_variant is Array else []
	var tools: Array = []
	for tool_variant in tools_source:
		if not (tool_variant is Dictionary):
			continue
		tools.append((tool_variant as Dictionary).duplicate(true))
	return tools


func _get_selected_hotbar_slot() -> Dictionary:
	for slot_variant in _get_hotbar_slots():
		if not (slot_variant is Dictionary):
			continue
		var slot := slot_variant as Dictionary
		if String(slot.get("key", "")) != _selected_farm_tool_key:
			continue
		return slot
	return {}


func _get_selected_farm_tool() -> Dictionary:
	if _selected_farm_tool_key == HOTBAR_HAND_KEY:
		return {}
	for tool in _get_farm_tools():
		if _build_tool_key(tool) == _selected_farm_tool_key:
			return tool
	return {}


func _sync_selected_farm_tool() -> void:
	var slots := _get_hotbar_slots()
	if slots.is_empty():
		_selected_farm_tool_key = ""
		return
	for slot_variant in slots:
		if not (slot_variant is Dictionary):
			continue
		var slot := slot_variant as Dictionary
		if String(slot.get("key", "")) == _selected_farm_tool_key:
			return
	_selected_farm_tool_key = String(slots[0].get("key", HOTBAR_HAND_KEY))


func _build_tool_key(tool: Dictionary) -> String:
	return _build_tool_key_from_parts(String(tool.get("id", "")), String(tool.get("seed_id", "")))


func _build_tool_key_from_parts(action_id: String, seed_id: String) -> String:
	if action_id.strip_edges().to_lower() == "hand":
		return HOTBAR_HAND_KEY
	return "%s::%s" % [action_id.strip_edges().to_lower(), seed_id.strip_edges().to_lower()]


func _is_hand_selected() -> bool:
	return _selected_farm_tool_key == HOTBAR_HAND_KEY


func _farm_tool_label(tool: Dictionary) -> String:
	return String(tool.get("label", "")).strip_edges()


func _farm_tool_title(tool: Dictionary) -> String:
	var label := _farm_tool_label(tool)
	if label.is_empty():
		return _t("meta.farm.tool_none")
	var newline_index := label.find("\n")
	if newline_index < 0:
		return label
	return label.substr(0, newline_index).strip_edges()


func _hotbar_short_label(slot: Dictionary) -> String:
	var action_id := String(slot.get("id", ""))
	match action_id:
		"till":
			return _t("meta.day_hud.hotbar_hoe_short")
		"water":
			return _t("meta.day_hud.hotbar_water_short")
		"plant":
			return _farm_tool_title(slot)
	return _hotbar_slot_title(slot)


func _hotbar_slot_title(slot: Dictionary) -> String:
	var action_id := String(slot.get("id", ""))
	if action_id == "hand":
		return _t("meta.day_hud.hotbar_hand_short")
	return _farm_tool_title(slot)


func _hotbar_description(slot: Dictionary) -> String:
	var action_id := String(slot.get("id", ""))
	match action_id:
		"hand":
			return _t("meta.day_hud.hotbar_hand_desc")
		"till":
			return _t("meta.day_hud.hotbar_hoe_desc")
		"water":
			return _t("meta.day_hud.hotbar_water_desc")
		"plant":
			return _t("meta.day_hud.hotbar_seed_desc", {"value": _farm_tool_title(slot)})
	return _farm_tool_label(slot)


func _is_farm_plot_zone(zone_id: String) -> bool:
	return zone_id.begins_with("farm_plot_")


func _is_pickup_zone(zone_id: String) -> bool:
	return zone_id.begins_with("pickup_")


func _get_farm_plot_model(zone_id: String) -> Dictionary:
	var zone: Dictionary = _farm_plot_zones.get(zone_id, {}) as Dictionary
	var plot_variant: Variant = zone.get("plot", {})
	return plot_variant if plot_variant is Dictionary else {}


func _get_pickup_model(zone_id: String) -> Dictionary:
	var zone: Dictionary = _pickup_zones.get(zone_id, {}) as Dictionary
	var pickup_variant: Variant = zone.get("pickup", {})
	return pickup_variant if pickup_variant is Dictionary else {}


func _get_day_world_pickups() -> Array:
	var pickups_variant: Variant = _view_model.get("pickups", [])
	var pickups_source: Array = pickups_variant if pickups_variant is Array else []
	var pickups: Array = []
	for pickup_variant in pickups_source:
		if not (pickup_variant is Dictionary):
			continue
		pickups.append((pickup_variant as Dictionary).duplicate(true))
	return pickups


func _get_visible_pickup_ids() -> Array:
	var pickup_ids: Array = []
	for zone_id_variant in _pickup_zones.keys():
		var pickup := _get_pickup_model(String(zone_id_variant))
		var pickup_id := String(pickup.get("id", "")).strip_edges().to_lower()
		if pickup_id.is_empty():
			continue
		pickup_ids.append(pickup_id)
	pickup_ids.sort()
	return pickup_ids


func _plot_is_harvestable(plot: Dictionary) -> bool:
	return String(plot.get("state_id", "")) == "harvestable"


func _farm_plot_name(plot: Dictionary) -> String:
	if plot.is_empty():
		return _t("meta.world.area_farm")
	return _t("meta.farm.plot_number", {"value": int(plot.get("index", 0)) + 1})


func _farm_plot_summary(plot: Dictionary) -> String:
	if plot.is_empty():
		return _t("meta.hub.farm_tooltip")
	var title := String(plot.get("title", "")).strip_edges()
	var subtitle := String(plot.get("subtitle", "")).strip_edges()
	if title.is_empty():
		return subtitle
	if subtitle.is_empty():
		return title
	return "%s · %s" % [title, subtitle]


func _zone_id_from_area(area: Area2D) -> String:
	if area == null or not is_instance_valid(area):
		return ""
	if area.has_meta("interaction_id"):
		return String(area.get_meta("interaction_id", "")).strip_edges().to_lower()
	var zone_name := area.name.strip_edges()
	if zone_name.ends_with("Zone"):
		zone_name = zone_name.substr(0, zone_name.length() - 4)
	return zone_name.to_lower()


func _on_player_focus_changed(zone_id: String) -> void:
	_focused_zone_id = zone_id
	_prompt_reveal_elapsed = 0.0
	_prompt_is_revealed = false
	_apply_view_model()


func _on_player_interaction_requested(zone_id: String) -> void:
	_activate_zone(zone_id)


func _on_visibility_changed() -> void:
	if visible and not _was_visible and _overlay_blocked:
		snap_player_to_night_dock()
	if not visible:
		_night_popup_open = false
		_transition_active = false
		_prompt_reveal_elapsed = 0.0
		_prompt_is_revealed = false
		_set_transition_visible(false)
	_sync_visibility_state()
	_apply_view_model()
	_was_visible = visible


func _on_daily_orders_board_closed() -> void:
	_sync_visibility_state()
	_apply_view_model()


func _on_daily_orders_state_changed() -> void:
	_apply_view_model()


func _on_daily_order_reward_claimed(_order_id: int, _reward: Dictionary) -> void:
	var meta_progress: Dictionary = ProfileStore.get_meta_progress_state()
	var economy_variant: Variant = meta_progress.get("economy", {})
	var economy: Dictionary = economy_variant if economy_variant is Dictionary else {}
	_view_model["gold"] = int(economy.get("gold", _view_model.get("gold", 0)))
	_apply_view_model()


func _on_language_changed(_language_code: String) -> void:
	_apply_view_model()


func _t(key: String, args: Dictionary = {}) -> String:
	if Localization == null or not Localization.has_method("t"):
		return key
	return String(Localization.call("t", key, args))
