extends Control
class_name RestaurantController

signal back_requested
signal recipe_toggled(recipe_id: String)
signal clear_menu_requested
signal service_requested

const INTERIOR_BOUNDS := Rect2(Vector2(112.0, 148.0), Vector2(1376.0, 696.0))
const TILE_SIZE := 48
const FLOOR_COLUMNS := 30
const FLOOR_ROWS := 16
const FLOOR_ORIGIN := Vector2(80.0, 128.0)
const TILE_WOOD_LIGHT := Vector2i(0, 0)
const TILE_WOOD_DARK := Vector2i(1, 0)
const TILE_CHECKER_LIGHT := Vector2i(2, 0)
const TILE_CHECKER_DARK := Vector2i(3, 0)
const TILE_RUG := Vector2i(4, 0)
const TILE_WALL := Vector2i(5, 0)
const TILE_MAT := Vector2i(6, 0)
const TABLE_POSITIONS := [
	Vector2(756.0, 428.0),
	Vector2(1000.0, 462.0),
	Vector2(728.0, 616.0),
	Vector2(1018.0, 612.0)
]
const PATRON_POSITIONS := [
	Vector2(706.0, 426.0),
	Vector2(1046.0, 452.0),
	Vector2(690.0, 616.0),
	Vector2(1062.0, 604.0),
	Vector2(1170.0, 332.0)
]
const PATRON_COLORS := [
	Color(0.92, 0.63, 0.41, 1.0),
	Color(0.45, 0.70, 0.90, 1.0),
	Color(0.82, 0.78, 0.43, 1.0),
	Color(0.66, 0.83, 0.58, 1.0),
	Color(0.87, 0.54, 0.63, 1.0)
]

@onready var world_root: Node2D = $WorldRoot
@onready var backdrop: Node2D = $WorldRoot/Backdrop
@onready var environment: Node2D = $WorldRoot/Environment
@onready var zones_root: Node2D = $WorldRoot/Zones
@onready var spawn_point: Marker2D = $WorldRoot/SpawnPoint
@onready var restaurant_player: DayPlayerController = $WorldRoot/RestaurantPlayer
@onready var info_title_label: Label = $HUDLayer/InfoPanel/Margin/VBox/Title
@onready var info_stats_label: Label = $HUDLayer/InfoPanel/Margin/VBox/Stats
@onready var info_bridge_label: Label = $HUDLayer/InfoPanel/Margin/VBox/Bridge
@onready var leave_button: Button = $HUDLayer/LeaveButton
@onready var status_panel: Panel = $HUDLayer/StatusPanel
@onready var status_label: Label = $HUDLayer/StatusPanel/Margin/Status
@onready var hint_label: Label = $HUDLayer/PromptPanel/Margin/VBox/Hint
@onready var prompt_label: Label = $HUDLayer/PromptPanel/Margin/VBox/Prompt
@onready var popup_shade: ColorRect = $HUDLayer/PopupShade
@onready var menu_popup: Panel = $HUDLayer/PopupHost/MenuPopup
@onready var menu_title_label: Label = $HUDLayer/PopupHost/MenuPopup/Margin/VBox/Title
@onready var menu_subtitle_label: Label = $HUDLayer/PopupHost/MenuPopup/Margin/VBox/Subtitle
@onready var menu_bridge_label: Label = $HUDLayer/PopupHost/MenuPopup/Margin/VBox/Bridge
@onready var menu_recipes_title_label: Label = $HUDLayer/PopupHost/MenuPopup/Margin/VBox/Columns/RecipesCard/Margin/VBox/Title
@onready var menu_recipes_scroll: ScrollContainer = $HUDLayer/PopupHost/MenuPopup/Margin/VBox/Columns/RecipesCard/Margin/VBox/RecipesScroll
@onready var menu_recipes_list: VBoxContainer = $HUDLayer/PopupHost/MenuPopup/Margin/VBox/Columns/RecipesCard/Margin/VBox/RecipesScroll/RecipesList
@onready var menu_selected_title_label: Label = $HUDLayer/PopupHost/MenuPopup/Margin/VBox/Columns/MenuCard/Margin/VBox/Title
@onready var menu_hint_label: Label = $HUDLayer/PopupHost/MenuPopup/Margin/VBox/Columns/MenuCard/Margin/VBox/MenuHint
@onready var menu_selected_scroll: ScrollContainer = $HUDLayer/PopupHost/MenuPopup/Margin/VBox/Columns/MenuCard/Margin/VBox/MenuScroll
@onready var menu_selected_list: VBoxContainer = $HUDLayer/PopupHost/MenuPopup/Margin/VBox/Columns/MenuCard/Margin/VBox/MenuScroll/MenuList
@onready var menu_clear_button: Button = $HUDLayer/PopupHost/MenuPopup/Margin/VBox/Buttons/ClearButton
@onready var menu_close_button: Button = $HUDLayer/PopupHost/MenuPopup/Margin/VBox/Buttons/CloseButton
@onready var prep_popup: Panel = $HUDLayer/PopupHost/PrepPopup
@onready var prep_title_label: Label = $HUDLayer/PopupHost/PrepPopup/Margin/VBox/Title
@onready var prep_subtitle_label: Label = $HUDLayer/PopupHost/PrepPopup/Margin/VBox/Subtitle
@onready var prep_pantry_title_label: Label = $HUDLayer/PopupHost/PrepPopup/Margin/VBox/PantryCard/Margin/VBox/Title
@onready var prep_pantry_label: Label = $HUDLayer/PopupHost/PrepPopup/Margin/VBox/PantryCard/Margin/VBox/Value
@onready var prep_menu_title_label: Label = $HUDLayer/PopupHost/PrepPopup/Margin/VBox/MenuCard/Margin/VBox/Title
@onready var prep_menu_list: VBoxContainer = $HUDLayer/PopupHost/PrepPopup/Margin/VBox/MenuCard/Margin/VBox/MenuList
@onready var prep_close_button: Button = $HUDLayer/PopupHost/PrepPopup/Margin/VBox/CloseButton
@onready var service_popup: Panel = $HUDLayer/PopupHost/ServicePopup
@onready var service_title_label: Label = $HUDLayer/PopupHost/ServicePopup/Margin/VBox/Title
@onready var service_subtitle_label: Label = $HUDLayer/PopupHost/ServicePopup/Margin/VBox/Subtitle
@onready var service_summary_label: Label = $HUDLayer/PopupHost/ServicePopup/Margin/VBox/Summary
@onready var service_status_label: Label = $HUDLayer/PopupHost/ServicePopup/Margin/VBox/Status
@onready var service_button: Button = $HUDLayer/PopupHost/ServicePopup/Margin/VBox/Buttons/ServiceButton
@onready var service_close_button: Button = $HUDLayer/PopupHost/ServicePopup/Margin/VBox/Buttons/CloseButton
@onready var result_popup: Panel = $HUDLayer/PopupHost/ResultPopup
@onready var result_popup_title_label: Label = $HUDLayer/PopupHost/ResultPopup/Margin/VBox/Title
@onready var result_title_label: Label = $HUDLayer/PopupHost/ResultPopup/Margin/VBox/ServiceTitle
@onready var result_summary_label: Label = $HUDLayer/PopupHost/ResultPopup/Margin/VBox/Summary
@onready var result_feedback_label: Label = $HUDLayer/PopupHost/ResultPopup/Margin/VBox/Feedback
@onready var sold_stats_label: Label = $HUDLayer/PopupHost/ResultPopup/Margin/VBox/SoldStats
@onready var result_close_button: Button = $HUDLayer/PopupHost/ResultPopup/Margin/VBox/CloseButton

var _view_model: Dictionary = {}
var _zones: Dictionary = {}
var _focused_zone_id: String = ""
var _active_popup_id: String = ""
var _world_built: bool = false
var _tile_root: Node2D = null
var _ground_tiles: TileMapLayer = null
var _detail_tiles: TileMapLayer = null
var _world_tile_set: TileSet = null
var _props_root: Node2D = null
var _ambient_root: Node2D = null
var _patron_root: Node2D = null
var _popup_panels: Dictionary = {}
var _lights_on: bool = false
var _customer_count: int = 0
var _was_visible: bool = false


func _ready() -> void:
	visible = false
	_build_world_if_needed()
	_register_zones()
	_popup_panels = {
		"menu": menu_popup,
		"prep": prep_popup,
		"service": service_popup,
		"summary": result_popup
	}
	restaurant_player.set_world_bounds(INTERIOR_BOUNDS)
	restaurant_player.reset_to_position(spawn_point.global_position)
	restaurant_player.focus_changed.connect(_on_player_focus_changed)
	restaurant_player.interaction_requested.connect(_on_player_interaction_requested)
	leave_button.pressed.connect(func() -> void:
		back_requested.emit()
	)
	menu_clear_button.pressed.connect(func() -> void:
		clear_menu_requested.emit()
	)
	menu_close_button.pressed.connect(_close_popups)
	prep_close_button.pressed.connect(_close_popups)
	service_close_button.pressed.connect(_close_popups)
	result_close_button.pressed.connect(_close_popups)
	service_button.pressed.connect(_on_service_button_pressed)
	if Localization != null and Localization.has_signal("language_changed"):
		Localization.language_changed.connect(_on_language_changed)
	visibility_changed.connect(_on_visibility_changed)
	_apply_view_model()
	_sync_visibility_state()


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if _active_popup_id.is_empty():
		return
	if not event.is_action_pressed("ui_cancel"):
		return
	_close_popups()
	get_viewport().set_input_as_handled()


func set_view_model(model: Dictionary) -> void:
	var had_previous_model := not _view_model.is_empty()
	var previous_service_day := int(_view_model.get("last_service_day", 0))
	_view_model = model.duplicate(true)
	_apply_view_model()
	var current_service_day := int(_view_model.get("last_service_day", 0))
	if had_previous_model and current_service_day > previous_service_day and current_service_day == int(_view_model.get("current_day", 1)):
		_open_popup("summary")


func debug_activate_zone(zone_id: String) -> bool:
	return _activate_zone(zone_id.strip_edges().to_lower())


func debug_attempt_world_interaction(zone_id: String) -> bool:
	var normalized_id := zone_id.strip_edges().to_lower()
	if not visible or normalized_id.is_empty() or not _active_popup_id.is_empty():
		return false
	return _activate_zone(normalized_id)


func debug_toggle_recipe_card(recipe_id: String) -> bool:
	if _active_popup_id != "menu":
		return false
	var normalized_id := recipe_id.strip_edges().to_lower()
	if normalized_id.is_empty():
		return false
	recipe_toggled.emit(normalized_id)
	return true


func debug_request_service() -> bool:
	if _active_popup_id != "service" or service_button.disabled:
		return false
	service_requested.emit()
	return true


func debug_close_popup() -> bool:
	if not visible or _active_popup_id.is_empty():
		return false
	_close_popups()
	return true


func debug_get_snapshot() -> Dictionary:
	return {
		"focused_zone_id": _focused_zone_id,
		"active_popup_id": _active_popup_id,
		"prompt_text": _build_prompt_text(),
		"player_position": restaurant_player.global_position if restaurant_player != null else Vector2.ZERO,
		"customer_count": _customer_count,
		"lights_on": _lights_on
	}


func apply_restore_state(popup_id: String) -> void:
	var normalized_popup_id := popup_id.strip_edges().to_lower()
	if normalized_popup_id.is_empty() or not _popup_panels.has(normalized_popup_id):
		_close_popups()
		return
	_open_popup(normalized_popup_id)


func _build_world_if_needed() -> void:
	if _world_built:
		return
	_world_built = true
	_add_rect(backdrop, "WallBack", Rect2(0.0, 0.0, 1600.0, 980.0), Color(0.14, 0.11, 0.08, 1.0), -20)
	_add_rect(backdrop, "WarmBloom", Rect2(0.0, 0.0, 1600.0, 240.0), Color(0.72, 0.54, 0.32, 0.10), -19)
	_add_rect(backdrop, "FloorShadow", Rect2(64.0, 118.0, 1472.0, 780.0), Color(0.02, 0.01, 0.01, 0.28), -18)
	_ensure_world_layers()
	_paint_floor_tiles()
	_build_static_props()
	_create_zone("menu", "meta.restaurant.station_menu", Vector2(320.0, 274.0), Vector2(148.0, 110.0), Color(0.91, 0.76, 0.38, 1.0))
	_create_zone("prep", "meta.restaurant.station_prep", Vector2(360.0, 516.0), Vector2(148.0, 120.0), Color(0.52, 0.80, 0.54, 1.0))
	_create_zone("service", "meta.restaurant.station_service", Vector2(972.0, 312.0), Vector2(188.0, 118.0), Color(0.96, 0.60, 0.38, 1.0))
	_create_zone("results", "meta.restaurant.station_results", Vector2(1216.0, 640.0), Vector2(154.0, 102.0), Color(0.48, 0.76, 0.88, 1.0))
	_create_zone("door", "meta.restaurant.station_exit", Vector2(796.0, 780.0), Vector2(154.0, 102.0), Color(0.72, 0.85, 0.97, 1.0))
	_refresh_service_ambience()


func _ensure_world_layers() -> void:
	if _tile_root == null:
		_tile_root = Node2D.new()
		_tile_root.name = "TileRoot"
		world_root.add_child(_tile_root)
		world_root.move_child(_tile_root, environment.get_index())
	if _ground_tiles == null:
		_ground_tiles = TileMapLayer.new()
		_ground_tiles.name = "GroundTiles"
		_ground_tiles.position = FLOOR_ORIGIN
		_ground_tiles.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		_ground_tiles.tile_set = _build_world_tileset()
		_tile_root.add_child(_ground_tiles)
	if _detail_tiles == null:
		_detail_tiles = TileMapLayer.new()
		_detail_tiles.name = "DetailTiles"
		_detail_tiles.position = FLOOR_ORIGIN
		_detail_tiles.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		_detail_tiles.tile_set = _build_world_tileset()
		_detail_tiles.z_index = 1
		_tile_root.add_child(_detail_tiles)
	if _props_root == null:
		_props_root = Node2D.new()
		_props_root.name = "Props"
		_props_root.y_sort_enabled = true
		environment.add_child(_props_root)
	if _ambient_root == null:
		_ambient_root = Node2D.new()
		_ambient_root.name = "Ambient"
		_ambient_root.y_sort_enabled = true
		environment.add_child(_ambient_root)
	if _patron_root == null:
		_patron_root = Node2D.new()
		_patron_root.name = "Patrons"
		_patron_root.y_sort_enabled = true
		environment.add_child(_patron_root)


func _build_world_tileset() -> TileSet:
	if _world_tile_set != null:
		return _world_tile_set
	var tile_count := 7
	var atlas_image := Image.create(TILE_SIZE * tile_count, TILE_SIZE, false, Image.FORMAT_RGBA8)
	_draw_wood_tile(atlas_image, 0, Color(0.37, 0.25, 0.15, 1.0), Color(0.47, 0.33, 0.20, 1.0), Color(0.24, 0.16, 0.10, 1.0))
	_draw_wood_tile(atlas_image, 1, Color(0.31, 0.21, 0.13, 1.0), Color(0.40, 0.28, 0.18, 1.0), Color(0.20, 0.13, 0.08, 1.0))
	_draw_checker_tile(atlas_image, 2, Color(0.71, 0.68, 0.58, 1.0), Color(0.56, 0.52, 0.43, 1.0))
	_draw_checker_tile(atlas_image, 3, Color(0.63, 0.58, 0.48, 1.0), Color(0.48, 0.44, 0.36, 1.0))
	_draw_rug_tile(atlas_image, 4)
	_draw_wall_tile(atlas_image, 5)
	_draw_mat_tile(atlas_image, 6)
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


func _draw_wood_tile(image: Image, tile_index: int, base: Color, light: Color, dark: Color) -> void:
	_fill_tile_background(image, tile_index, base)
	for seam_y in [10, 24, 38]:
		for x in range(TILE_SIZE):
			_set_tile_pixel(image, tile_index, x, seam_y, dark)
	for y in range(TILE_SIZE):
		for x in range(TILE_SIZE):
			var value := int((x * 7 + y * 11 + tile_index * 5) % 23)
			if value < 3:
				_set_tile_pixel(image, tile_index, x, y, light)
			elif value == 9:
				_set_tile_pixel(image, tile_index, x, y, dark)
	for nail_x in [6, 18, 30, 42]:
		for nail_y in [8, 22, 36]:
			_set_tile_pixel(image, tile_index, nail_x, nail_y, dark)


func _draw_checker_tile(image: Image, tile_index: int, light: Color, dark: Color) -> void:
	_fill_tile_background(image, tile_index, light)
	for y in range(TILE_SIZE):
		for x in range(TILE_SIZE):
			if int((x / 8) + (y / 8) + tile_index) % 2 == 0:
				_set_tile_pixel(image, tile_index, x, y, dark)
	for seam_x in [0, 16, 32]:
		for y in range(TILE_SIZE):
			_set_tile_pixel(image, tile_index, seam_x, y, Color(0.18, 0.15, 0.12, 0.25))
	for seam_y in [0, 16, 32]:
		for x in range(TILE_SIZE):
			_set_tile_pixel(image, tile_index, x, seam_y, Color(0.18, 0.15, 0.12, 0.25))


func _draw_rug_tile(image: Image, tile_index: int) -> void:
	_fill_tile_background(image, tile_index, Color(0.46, 0.18, 0.14, 1.0))
	for y in range(TILE_SIZE):
		for x in range(TILE_SIZE):
			if x < 4 or x >= TILE_SIZE - 4 or y < 4 or y >= TILE_SIZE - 4:
				_set_tile_pixel(image, tile_index, x, y, Color(0.78, 0.62, 0.28, 1.0))
			elif int((x * 5 + y * 3) % 17) == 0:
				_set_tile_pixel(image, tile_index, x, y, Color(0.88, 0.78, 0.42, 1.0))


func _draw_wall_tile(image: Image, tile_index: int) -> void:
	_fill_tile_background(image, tile_index, Color(0.28, 0.21, 0.15, 1.0))
	for y in range(0, TILE_SIZE, 12):
		for x in range(TILE_SIZE):
			_set_tile_pixel(image, tile_index, x, y, Color(0.18, 0.13, 0.10, 1.0))
	for x in range(0, TILE_SIZE, 12):
		for y in range(TILE_SIZE):
			_set_tile_pixel(image, tile_index, x, y, Color(0.33, 0.25, 0.18, 1.0))


func _draw_mat_tile(image: Image, tile_index: int) -> void:
	_fill_tile_background(image, tile_index, Color(0.62, 0.49, 0.32, 1.0))
	for y in range(TILE_SIZE):
		for x in range(TILE_SIZE):
			if x < 3 or x >= TILE_SIZE - 3 or y < 3 or y >= TILE_SIZE - 3:
				_set_tile_pixel(image, tile_index, x, y, Color(0.81, 0.66, 0.38, 1.0))
			elif int((x + y) % 9) == 0:
				_set_tile_pixel(image, tile_index, x, y, Color(0.70, 0.57, 0.35, 1.0))


func _fill_tile_background(image: Image, tile_index: int, color: Color) -> void:
	for y in range(TILE_SIZE):
		for x in range(TILE_SIZE):
			_set_tile_pixel(image, tile_index, x, y, color)


func _set_tile_pixel(image: Image, tile_index: int, x: int, y: int, color: Color) -> void:
	image.set_pixel(tile_index * TILE_SIZE + x, y, color)


func _paint_floor_tiles() -> void:
	if _ground_tiles == null or _detail_tiles == null:
		return
	_ground_tiles.clear()
	_detail_tiles.clear()
	for y in range(FLOOR_ROWS):
		for x in range(FLOOR_COLUMNS):
			var tile := TILE_WOOD_LIGHT if int((x + y) % 2) == 0 else TILE_WOOD_DARK
			_ground_tiles.set_cell(Vector2i(x, y), 0, tile)
	_fill_tile_rect(_ground_tiles, Rect2i(0, 0, FLOOR_COLUMNS, 2), TILE_WALL)
	_fill_tile_rect(_ground_tiles, Rect2i(0, 0, 2, FLOOR_ROWS), TILE_WALL)
	_fill_tile_rect(_ground_tiles, Rect2i(FLOOR_COLUMNS - 2, 0, 2, FLOOR_ROWS), TILE_WALL)
	_fill_checker_rect(Rect2i(2, 3, 8, 6))
	_fill_tile_rect(_ground_tiles, Rect2i(11, 6, 8, 5), TILE_RUG)
	_fill_tile_rect(_ground_tiles, Rect2i(14, 14, 3, 2), TILE_MAT)


func _fill_tile_rect(layer: TileMapLayer, rect: Rect2i, atlas_coords: Vector2i) -> void:
	for y in range(rect.position.y, rect.position.y + rect.size.y):
		for x in range(rect.position.x, rect.position.x + rect.size.x):
			layer.set_cell(Vector2i(x, y), 0, atlas_coords)


func _fill_checker_rect(rect: Rect2i) -> void:
	for y in range(rect.position.y, rect.position.y + rect.size.y):
		for x in range(rect.position.x, rect.position.x + rect.size.x):
			var tile := TILE_CHECKER_LIGHT if int((x + y) % 2) == 0 else TILE_CHECKER_DARK
			_ground_tiles.set_cell(Vector2i(x, y), 0, tile)


func _build_static_props() -> void:
	if _props_root == null:
		return
	for child in _props_root.get_children():
		child.free()
	_add_rect(_props_root, "TopTrim", Rect2(146.0, 166.0, 1308.0, 22.0), Color(0.56, 0.39, 0.24, 1.0), -1)
	_add_rect(_props_root, "TopLintel", Rect2(146.0, 192.0, 1308.0, 22.0), Color(0.30, 0.22, 0.15, 1.0), -1)
	_add_rect(_props_root, "LeftWall", Rect2(146.0, 214.0, 44.0, 592.0), Color(0.26, 0.19, 0.13, 1.0), -1)
	_add_rect(_props_root, "RightWall", Rect2(1410.0, 214.0, 44.0, 592.0), Color(0.26, 0.19, 0.13, 1.0), -1)
	_add_window_frame(Vector2(456.0, 204.0))
	_add_window_frame(Vector2(820.0, 204.0))
	_add_window_frame(Vector2(1184.0, 204.0))
	_add_board_station(Vector2(322.0, 264.0))
	_add_prep_station(Vector2(356.0, 512.0))
	_add_service_counter(Vector2(968.0, 300.0))
	_add_summary_nook(Vector2(1216.0, 640.0))
	for table_position in TABLE_POSITIONS:
		_add_table(table_position)
	_add_entry_door(Vector2(796.0, 776.0))


func _refresh_service_ambience() -> void:
	if _ambient_root == null or _patron_root == null:
		return
	for child in _ambient_root.get_children():
		child.free()
	for child in _patron_root.get_children():
		child.free()
	_customer_count = 0
	var selected_menu_count := _selected_menu_count()
	var service_completed_today := _service_completed_today()
	_lights_on = selected_menu_count > 0 or service_completed_today
	if _lights_on:
		for glow_position in [Vector2(456.0, 236.0), Vector2(820.0, 236.0), Vector2(1184.0, 236.0), Vector2(964.0, 298.0)]:
			_add_glow(_ambient_root, glow_position, Vector2(140.0, 74.0), Color(1.0, 0.76, 0.42, 0.14))
		for table_position in TABLE_POSITIONS:
			_add_plate_cluster(_ambient_root, table_position + Vector2(0.0, -6.0))
	if not service_completed_today:
		return
	var served_customers := int(_get_last_service_summary().get("served_customers", 0))
	var patron_count := clampi(int(ceil(float(served_customers) / 4.0)), 2, PATRON_POSITIONS.size())
	for patron_index in range(patron_count):
		_add_patron(PATRON_POSITIONS[patron_index], PATRON_COLORS[patron_index % PATRON_COLORS.size()])
	_customer_count = patron_count


func _add_window_frame(position: Vector2) -> void:
	_add_shadow(_props_root, "WindowShadow%s" % str(position), position + Vector2(0.0, 10.0), Vector2(140.0, 28.0), Color(0.04, 0.02, 0.01, 0.18), -2)
	var frame := Polygon2D.new()
	frame.name = "WindowFrame%s" % str(position)
	frame.position = position
	frame.polygon = _rect_polygon(Vector2(132.0, 26.0))
	frame.color = Color(0.63, 0.46, 0.26, 1.0)
	_props_root.add_child(frame)
	var glass := Polygon2D.new()
	glass.name = "WindowGlass%s" % str(position)
	glass.position = position
	glass.polygon = _rect_polygon(Vector2(118.0, 16.0))
	glass.color = Color(0.86, 0.92, 0.98, 0.48)
	_props_root.add_child(glass)


func _add_board_station(position: Vector2) -> void:
	var root := Node2D.new()
	root.name = "MenuBoardStation"
	root.position = position
	_props_root.add_child(root)
	_add_shadow(root, "Shadow", Vector2(0.0, 34.0), Vector2(176.0, 34.0), Color(0.04, 0.02, 0.01, 0.18), -2)
	var counter := Polygon2D.new()
	counter.position = Vector2(0.0, 30.0)
	counter.polygon = _rect_polygon(Vector2(168.0, 44.0))
	counter.color = Color(0.50, 0.34, 0.21, 1.0)
	root.add_child(counter)
	var surface := Polygon2D.new()
	surface.position = Vector2(0.0, 12.0)
	surface.polygon = _rect_polygon(Vector2(176.0, 18.0))
	surface.color = Color(0.72, 0.54, 0.32, 1.0)
	root.add_child(surface)
	var board := Polygon2D.new()
	board.position = Vector2(0.0, -46.0)
	board.polygon = _rect_polygon(Vector2(118.0, 76.0))
	board.color = Color(0.16, 0.22, 0.16, 1.0)
	root.add_child(board)
	for note_position in [Vector2(-22.0, -58.0), Vector2(16.0, -48.0), Vector2(2.0, -30.0)]:
		var note := Polygon2D.new()
		note.position = note_position
		note.polygon = _rect_polygon(Vector2(22.0, 16.0))
		note.color = Color(0.96, 0.91, 0.76, 1.0)
		root.add_child(note)


func _add_prep_station(position: Vector2) -> void:
	var root := Node2D.new()
	root.name = "PrepStation"
	root.position = position
	_props_root.add_child(root)
	_add_shadow(root, "Shadow", Vector2(0.0, 34.0), Vector2(168.0, 34.0), Color(0.04, 0.02, 0.01, 0.18), -2)
	var island := Polygon2D.new()
	island.position = Vector2(0.0, 14.0)
	island.polygon = _rect_polygon(Vector2(160.0, 54.0))
	island.color = Color(0.44, 0.31, 0.20, 1.0)
	root.add_child(island)
	var surface := Polygon2D.new()
	surface.position = Vector2(0.0, -8.0)
	surface.polygon = _rect_polygon(Vector2(168.0, 20.0))
	surface.color = Color(0.76, 0.69, 0.57, 1.0)
	root.add_child(surface)
	var chopping_block := Polygon2D.new()
	chopping_block.position = Vector2(-34.0, -12.0)
	chopping_block.polygon = _rect_polygon(Vector2(34.0, 24.0))
	chopping_block.color = Color(0.59, 0.40, 0.22, 1.0)
	root.add_child(chopping_block)
	var prep_bowl := Polygon2D.new()
	prep_bowl.position = Vector2(34.0, -10.0)
	prep_bowl.polygon = _ellipse_polygon(Vector2(34.0, 22.0), 10)
	prep_bowl.color = Color(0.62, 0.77, 0.88, 1.0)
	root.add_child(prep_bowl)
	_add_rect(root, "Shelf", Rect2(-96.0, -74.0, 32.0, 92.0), Color(0.35, 0.25, 0.18, 1.0), 0)
	_add_rect(root, "ShelfTop", Rect2(-102.0, -78.0, 44.0, 10.0), Color(0.65, 0.47, 0.27, 1.0), 1)


func _add_service_counter(position: Vector2) -> void:
	var root := Node2D.new()
	root.name = "ServiceCounter"
	root.position = position
	_props_root.add_child(root)
	_add_shadow(root, "Shadow", Vector2(0.0, 42.0), Vector2(260.0, 42.0), Color(0.04, 0.02, 0.01, 0.18), -2)
	var counter := Polygon2D.new()
	counter.position = Vector2(0.0, 28.0)
	counter.polygon = _rect_polygon(Vector2(244.0, 56.0))
	counter.color = Color(0.46, 0.30, 0.18, 1.0)
	root.add_child(counter)
	var surface := Polygon2D.new()
	surface.position = Vector2(0.0, 0.0)
	surface.polygon = _rect_polygon(Vector2(258.0, 18.0))
	surface.color = Color(0.74, 0.56, 0.33, 1.0)
	root.add_child(surface)
	for stool_x in [-76.0, 0.0, 76.0]:
		var stool := Polygon2D.new()
		stool.position = Vector2(stool_x, 74.0)
		stool.polygon = _ellipse_polygon(Vector2(28.0, 18.0), 10)
		stool.color = Color(0.60, 0.42, 0.24, 1.0)
		root.add_child(stool)
	var bell := Polygon2D.new()
	bell.position = Vector2(80.0, -8.0)
	bell.polygon = _ellipse_polygon(Vector2(18.0, 16.0), 10)
	bell.color = Color(0.88, 0.76, 0.32, 1.0)
	root.add_child(bell)


func _add_summary_nook(position: Vector2) -> void:
	var root := Node2D.new()
	root.name = "SummaryNook"
	root.position = position
	_props_root.add_child(root)
	_add_shadow(root, "Shadow", Vector2(0.0, 26.0), Vector2(142.0, 28.0), Color(0.04, 0.02, 0.01, 0.18), -2)
	var booth := Polygon2D.new()
	booth.position = Vector2(0.0, 14.0)
	booth.polygon = _rect_polygon(Vector2(128.0, 58.0))
	booth.color = Color(0.53, 0.22, 0.18, 1.0)
	root.add_child(booth)
	var table := Polygon2D.new()
	table.position = Vector2(0.0, -8.0)
	table.polygon = _ellipse_polygon(Vector2(90.0, 34.0), 12)
	table.color = Color(0.67, 0.49, 0.28, 1.0)
	root.add_child(table)
	var ledger := Polygon2D.new()
	ledger.position = Vector2(18.0, -14.0)
	ledger.polygon = _rect_polygon(Vector2(30.0, 20.0))
	ledger.color = Color(0.94, 0.88, 0.76, 1.0)
	root.add_child(ledger)
	var frame := Polygon2D.new()
	frame.position = Vector2(0.0, -72.0)
	frame.polygon = _rect_polygon(Vector2(86.0, 52.0))
	frame.color = Color(0.68, 0.50, 0.29, 1.0)
	root.add_child(frame)
	var insert := Polygon2D.new()
	insert.position = Vector2(0.0, -72.0)
	insert.polygon = _rect_polygon(Vector2(70.0, 36.0))
	insert.color = Color(0.19, 0.25, 0.18, 1.0)
	root.add_child(insert)


func _add_table(position: Vector2) -> void:
	var root := Node2D.new()
	root.name = "DiningTable%s" % str(position)
	root.position = position
	_props_root.add_child(root)
	_add_shadow(root, "Shadow", Vector2(0.0, 18.0), Vector2(112.0, 30.0), Color(0.04, 0.02, 0.01, 0.18), -2)
	var tabletop := Polygon2D.new()
	tabletop.position = Vector2(0.0, 0.0)
	tabletop.polygon = _ellipse_polygon(Vector2(92.0, 38.0), 12)
	tabletop.color = Color(0.71, 0.52, 0.30, 1.0)
	root.add_child(tabletop)
	for chair_offset in [Vector2(-56.0, 0.0), Vector2(56.0, 0.0), Vector2(0.0, -34.0)]:
		var chair := Polygon2D.new()
		chair.position = chair_offset
		chair.polygon = _rect_polygon(Vector2(24.0, 20.0))
		chair.color = Color(0.51, 0.35, 0.21, 1.0)
		root.add_child(chair)


func _add_entry_door(position: Vector2) -> void:
	var root := Node2D.new()
	root.name = "Doorway"
	root.position = position
	_props_root.add_child(root)
	_add_shadow(root, "Shadow", Vector2(0.0, 16.0), Vector2(136.0, 26.0), Color(0.04, 0.02, 0.01, 0.18), -2)
	var mat := Polygon2D.new()
	mat.position = Vector2(0.0, 8.0)
	mat.polygon = _ellipse_polygon(Vector2(122.0, 30.0), 12)
	mat.color = Color(0.34, 0.24, 0.16, 1.0)
	root.add_child(mat)
	var frame := Polygon2D.new()
	frame.position = Vector2(0.0, -34.0)
	frame.polygon = _rect_polygon(Vector2(126.0, 82.0))
	frame.color = Color(0.44, 0.31, 0.20, 1.0)
	root.add_child(frame)
	var opening := Polygon2D.new()
	opening.position = Vector2(0.0, -34.0)
	opening.polygon = _rect_polygon(Vector2(92.0, 64.0))
	opening.color = Color(0.10, 0.08, 0.06, 1.0)
	root.add_child(opening)


func _add_plate_cluster(parent: Node2D, position: Vector2) -> void:
	for plate_offset in [Vector2(-12.0, 0.0), Vector2(12.0, 4.0)]:
		var plate := Polygon2D.new()
		plate.position = position + plate_offset
		plate.polygon = _ellipse_polygon(Vector2(16.0, 12.0), 10)
		plate.color = Color(0.96, 0.93, 0.82, 1.0)
		parent.add_child(plate)


func _add_patron(position: Vector2, body_color: Color) -> void:
	var root := Node2D.new()
	root.name = "Patron%s" % str(position)
	root.position = position
	_patron_root.add_child(root)
	_add_shadow(root, "Shadow", Vector2(0.0, 16.0), Vector2(34.0, 12.0), Color(0.04, 0.02, 0.01, 0.18), -2)
	var body := Polygon2D.new()
	body.position = Vector2(0.0, 2.0)
	body.polygon = _rect_polygon(Vector2(20.0, 30.0))
	body.color = body_color
	root.add_child(body)
	var apron := Polygon2D.new()
	apron.position = Vector2(0.0, 7.0)
	apron.polygon = _rect_polygon(Vector2(10.0, 18.0))
	apron.color = Color(0.17, 0.19, 0.25, 0.70)
	root.add_child(apron)
	var head := Polygon2D.new()
	head.position = Vector2(0.0, -16.0)
	head.polygon = _ellipse_polygon(Vector2(18.0, 18.0), 10)
	head.color = Color(0.96, 0.78, 0.62, 1.0)
	root.add_child(head)


func _add_glow(parent: Node2D, position: Vector2, size: Vector2, color: Color) -> void:
	var glow := Polygon2D.new()
	glow.position = position
	glow.polygon = _ellipse_polygon(size, 16)
	glow.color = color
	parent.add_child(glow)


func _add_shadow(parent: Node2D, name: String, position: Vector2, size: Vector2, color: Color, z_index: int) -> void:
	var shadow := Polygon2D.new()
	shadow.name = name
	shadow.position = position
	shadow.polygon = _ellipse_polygon(size, 16)
	shadow.color = color
	shadow.z_index = z_index
	parent.add_child(shadow)


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
		if not (zone_root_variant is Node2D):
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


func _create_zone(zone_id: String, label_key: String, position: Vector2, size: Vector2, accent: Color) -> void:
	var zone_root := Node2D.new()
	zone_root.name = "%sZoneRoot" % zone_id.capitalize()
	zone_root.position = position
	zone_root.set_meta("label_key", label_key)
	zone_root.set_meta("accent_color", accent)
	zones_root.add_child(zone_root)

	var pulse := Polygon2D.new()
	pulse.name = "Pulse"
	pulse.polygon = _ellipse_polygon(Vector2(maxf(size.x * 0.52, 58.0), 26.0), 14)
	pulse.position = Vector2(0.0, 16.0)
	pulse.color = Color(accent.r, accent.g, accent.b, 0.10)
	pulse.z_index = 1
	zone_root.add_child(pulse)

	var marker := Polygon2D.new()
	marker.name = "Marker"
	marker.polygon = PackedVector2Array([
		Vector2(0.0, -12.0),
		Vector2(12.0, 0.0),
		Vector2(0.0, 12.0),
		Vector2(-12.0, 0.0)
	])
	marker.position = Vector2(0.0, -12.0)
	marker.color = Color(accent.r, accent.g, accent.b, 0.28)
	marker.z_index = 2
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


func _apply_view_model() -> void:
	info_title_label.text = _t("meta.restaurant.world_title")
	info_stats_label.text = _t("meta.restaurant.stats", {
		"day": int(_view_model.get("current_day", 1)),
		"phase": _t("meta.phase.%s" % String(_view_model.get("phase", "morning"))),
		"gold": int(_view_model.get("gold", 0)),
		"reputation": int(_view_model.get("reputation", 0)),
		"actions": int(_view_model.get("action_budget", 0)),
		"action_max": int(_view_model.get("max_action_budget", 0))
	})
	info_bridge_label.text = _t("meta.restaurant.bridge", {
		"value": String(_view_model.get("bridge_summary", _t("meta.bridge.summary_none")))
	})
	info_bridge_label.tooltip_text = String(_view_model.get("bridge_tooltip", ""))
	leave_button.text = _t("meta.restaurant.leave")
	status_label.text = String(_view_model.get("status_text", ""))
	status_panel.visible = not status_label.text.strip_edges().is_empty()
	hint_label.text = _t("meta.restaurant.world_move_hint")
	prompt_label.text = _build_prompt_text()

	menu_title_label.text = _t("meta.restaurant.popup_menu_title")
	menu_subtitle_label.text = _t("meta.restaurant.popup_menu_subtitle")
	menu_bridge_label.text = _t("meta.restaurant.bridge", {
		"value": String(_view_model.get("bridge_summary", _t("meta.bridge.summary_none")))
	})
	menu_bridge_label.tooltip_text = String(_view_model.get("bridge_tooltip", ""))
	menu_recipes_title_label.text = _t("meta.restaurant.recipes_title")
	menu_selected_title_label.text = _t("meta.restaurant.menu_title")
	menu_hint_label.text = String(_view_model.get("menu_hint_text", ""))
	menu_hint_label.tooltip_text = String(_view_model.get("menu_hint_tooltip", ""))
	menu_clear_button.text = _t("meta.restaurant.clear_menu")
	menu_clear_button.disabled = not bool(_view_model.get("clear_button_enabled", false))
	menu_close_button.text = _t("meta.common.close")

	prep_title_label.text = _t("meta.restaurant.popup_prep_title")
	prep_subtitle_label.text = _t("meta.restaurant.popup_prep_subtitle")
	prep_pantry_title_label.text = _t("meta.restaurant.ingredients_title")
	prep_pantry_label.text = String(_view_model.get("ingredient_summary", _t("meta.common.none")))
	prep_pantry_label.tooltip_text = String(_view_model.get("ingredient_tooltip", ""))
	prep_menu_title_label.text = _t("meta.restaurant.menu_title")
	prep_close_button.text = _t("meta.common.close")

	service_title_label.text = _t("meta.restaurant.popup_service_title")
	service_subtitle_label.text = _t("meta.restaurant.popup_service_subtitle")
	service_summary_label.text = _build_service_summary()
	service_status_label.text = _build_service_status()
	service_button.text = String(_view_model.get("service_button_text", _t("meta.restaurant.open_service")))
	service_button.tooltip_text = String(_view_model.get("service_button_tooltip", ""))
	service_button.disabled = not bool(_view_model.get("service_button_enabled", false))
	service_close_button.text = _t("meta.common.close")

	result_popup_title_label.text = _t("meta.restaurant.popup_result_title")
	result_title_label.text = String(_view_model.get("result_title", _t("meta.restaurant.summary_idle_title")))
	result_summary_label.text = String(_view_model.get("result_summary", _t("meta.restaurant.summary_idle")))
	result_feedback_label.text = String(_view_model.get("result_feedback", _t("meta.common.none")))
	sold_stats_label.text = String(_view_model.get("sold_stats_text", ""))
	result_close_button.text = _t("meta.common.close")

	_rebuild_recipe_buttons()
	_rebuild_selected_menu(menu_selected_list)
	_rebuild_selected_menu(prep_menu_list)
	_refresh_service_ambience()
	_refresh_zone_visuals()
	_update_popup_visibility()


func _rebuild_recipe_buttons() -> void:
	for child in menu_recipes_list.get_children():
		child.free()
	var recipe_cards_variant: Variant = _view_model.get("recipe_cards", [])
	var recipe_cards: Array = recipe_cards_variant if recipe_cards_variant is Array else []
	for recipe_variant in recipe_cards:
		if not (recipe_variant is Dictionary):
			continue
		var recipe := recipe_variant as Dictionary
		var button := Button.new()
		button.custom_minimum_size = Vector2(0.0, 92.0)
		button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.toggle_mode = true
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.button_pressed = bool(recipe.get("selected", false))
		button.disabled = not bool(recipe.get("enabled", false))
		button.theme_type_variation = &"SecondaryButton"
		button.text = String(recipe.get("label", ""))
		button.tooltip_text = String(recipe.get("tooltip", ""))
		button.pressed.connect(_on_recipe_button_pressed.bind(String(recipe.get("id", ""))))
		menu_recipes_list.add_child(button)
	_sync_scroll_width(menu_recipes_scroll, menu_recipes_list)


func _rebuild_selected_menu(target: VBoxContainer) -> void:
	for child in target.get_children():
		child.free()
	var selected_menu_variant: Variant = _view_model.get("selected_menu_entries", [])
	var selected_menu_entries: Array = selected_menu_variant if selected_menu_variant is Array else []
	if selected_menu_entries.is_empty():
		var empty_label := Label.new()
		empty_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		empty_label.theme_type_variation = &"BodyMutedLabel"
		empty_label.text = _t("meta.restaurant.menu_empty")
		target.add_child(empty_label)
		return
	for entry_variant in selected_menu_entries:
		if not (entry_variant is Dictionary):
			continue
		var entry_label := Label.new()
		entry_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		entry_label.theme_type_variation = &"BodyMutedLabel"
		entry_label.text = String((entry_variant as Dictionary).get("label", ""))
		target.add_child(entry_label)
	if target == menu_selected_list:
		_sync_scroll_width(menu_selected_scroll, menu_selected_list)


func _sync_scroll_width(scroll: ScrollContainer, container: VBoxContainer) -> void:
	var target_width := maxf(0.0, scroll.size.x - 8.0)
	container.custom_minimum_size = Vector2(target_width, container.custom_minimum_size.y)
	for child in container.get_children():
		if child is Control:
			var child_control := child as Control
			child_control.custom_minimum_size = Vector2(target_width, child_control.custom_minimum_size.y)


func _build_service_summary() -> String:
	var lines: Array[String] = [
		String(_view_model.get("menu_hint_text", "")),
		_t("meta.restaurant.bridge", {
			"value": String(_view_model.get("bridge_summary", _t("meta.bridge.summary_none")))
		})
	]
	var selected_menu_entries: Variant = _view_model.get("selected_menu_entries", [])
	if selected_menu_entries is Array and not (selected_menu_entries as Array).is_empty():
		var names: Array[String] = []
		for entry_variant in selected_menu_entries:
			if not (entry_variant is Dictionary):
				continue
			var label := String((entry_variant as Dictionary).get("label", ""))
			var first_line := label.split("\n", false, 1)
			if not first_line.is_empty():
				names.append(first_line[0])
		if not names.is_empty():
			lines.append(", ".join(names))
	return "\n".join(lines)


func _build_service_status() -> String:
	var status_text := String(_view_model.get("status_text", "")).strip_edges()
	if not status_text.is_empty():
		return status_text
	return String(_view_model.get("service_button_tooltip", ""))


func _build_prompt_text() -> String:
	if not _active_popup_id.is_empty():
		return _t("meta.restaurant.world_prompt_popup")
	if _focused_zone_id.is_empty():
		return _t("meta.restaurant.world_prompt_idle")
	var zone_name := _zone_name(_focused_zone_id)
	match _focused_zone_id:
		"menu":
			return "%s\n%s" % [
				_t("meta.restaurant.world_prompt_interact", {"value": zone_name}),
				String(_view_model.get("menu_hint_text", ""))
			]
		"prep":
			return "%s\n%s" % [
				_t("meta.restaurant.world_prompt_interact", {"value": zone_name}),
				String(_view_model.get("ingredient_summary", _t("meta.common.none")))
			]
		"service":
			return "%s\n%s" % [
				_t("meta.restaurant.world_prompt_interact", {"value": zone_name}),
				String(_view_model.get("service_button_text", _t("meta.restaurant.open_service")))
			]
		"results":
			return "%s\n%s" % [
				_t("meta.restaurant.world_prompt_interact", {"value": zone_name}),
				String(_view_model.get("result_title", _t("meta.restaurant.summary_idle_title")))
			]
		"door":
			return "%s\n%s" % [
				_t("meta.restaurant.world_prompt_interact", {"value": zone_name}),
				_t("meta.restaurant.leave")
			]
	return _t("meta.restaurant.world_prompt_idle")


func _refresh_zone_visuals() -> void:
	for zone_id_variant in _zones.keys():
		var zone_id := String(zone_id_variant)
		_apply_zone_visual(zone_id, _zones.get(zone_id, {}) as Dictionary, zone_id == _focused_zone_id)


func _apply_zone_visual(zone_id: String, zone: Dictionary, focused: bool) -> void:
	var marker := zone.get("marker", null) as Polygon2D
	var pulse := zone.get("pulse", null) as Polygon2D
	var accent_variant: Variant = zone.get("accent", Color.WHITE)
	var accent: Color = accent_variant if accent_variant is Color else Color.WHITE
	if zone_id == "service" and _service_completed_today():
		accent = Color(0.99, 0.83, 0.43, 1.0)
	if marker != null:
		marker.scale = Vector2.ONE * (1.18 if focused else 1.0)
		marker.color = Color(accent.r, accent.g, accent.b, 0.92 if focused else 0.34)
	if pulse != null:
		pulse.scale = Vector2.ONE * (1.32 if focused else 1.0)
		pulse.color = Color(accent.r, accent.g, accent.b, 0.24 if focused else 0.10)


func _activate_zone(zone_id: String) -> bool:
	if zone_id.is_empty():
		return false
	match zone_id:
		"door":
			back_requested.emit()
			return true
		"menu":
			_open_popup("menu")
			return true
		"prep":
			_open_popup("prep")
			return true
		"service":
			_open_popup("service")
			return true
		"results":
			_open_popup("summary")
			return true
	return false


func _open_popup(popup_id: String) -> void:
	if not _popup_panels.has(popup_id):
		return
	_active_popup_id = popup_id
	_update_popup_visibility()
	_sync_visibility_state()
	_apply_view_model()


func _close_popups() -> void:
	_active_popup_id = ""
	_update_popup_visibility()
	_sync_visibility_state()
	_apply_view_model()


func _update_popup_visibility() -> void:
	popup_shade.visible = visible and not _active_popup_id.is_empty()
	for popup_id_variant in _popup_panels.keys():
		var popup_id := String(popup_id_variant)
		var popup := _popup_panels.get(popup_id, null) as Panel
		if popup == null:
			continue
		popup.visible = visible and popup_id == _active_popup_id


func _sync_visibility_state() -> void:
	var ui_visible := visible
	if restaurant_player != null:
		restaurant_player.set_camera_active(ui_visible)
		restaurant_player.set_controls_enabled(ui_visible and _active_popup_id.is_empty())
	_schedule_focus_refresh()


func _schedule_focus_refresh() -> void:
	if restaurant_player != null and restaurant_player.has_method("refresh_interaction_focus"):
		restaurant_player.call_deferred("refresh_interaction_focus")


func _selected_menu_count() -> int:
	if _view_model.has("selected_menu_count"):
		return int(_view_model.get("selected_menu_count", 0))
	var selected_menu_variant: Variant = _view_model.get("selected_menu_entries", [])
	return (selected_menu_variant as Array).size() if selected_menu_variant is Array else 0


func _get_last_service_summary() -> Dictionary:
	var summary_variant: Variant = _view_model.get("last_service_summary", {})
	return summary_variant if summary_variant is Dictionary else {}


func _service_completed_today() -> bool:
	return int(_view_model.get("last_service_day", 0)) >= int(_view_model.get("current_day", 1))


func _zone_name(zone_id: String) -> String:
	var zone: Dictionary = _zones.get(zone_id, {}) as Dictionary
	var label_key := String(zone.get("label_key", ""))
	return _t(label_key) if not label_key.is_empty() else zone_id.capitalize()


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
	_apply_view_model()


func _on_player_interaction_requested(zone_id: String) -> void:
	_activate_zone(zone_id)


func _on_recipe_button_pressed(recipe_id: String) -> void:
	var normalized_id := recipe_id.strip_edges().to_lower()
	if normalized_id.is_empty():
		return
	recipe_toggled.emit(normalized_id)


func _on_service_button_pressed() -> void:
	if service_button.disabled:
		return
	service_requested.emit()


func _on_language_changed(_language_code: String) -> void:
	_apply_view_model()


func _on_visibility_changed() -> void:
	if visible and not _was_visible and restaurant_player != null:
		restaurant_player.reset_to_position(spawn_point.global_position)
	if not visible and not _active_popup_id.is_empty():
		_active_popup_id = ""
	_update_popup_visibility()
	_sync_visibility_state()
	_apply_view_model()
	_was_visible = visible


func _t(key: String, args: Dictionary = {}) -> String:
	if Localization == null or not Localization.has_method("t"):
		return key
	return String(Localization.call("t", key, args))
