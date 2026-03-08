extends Node2D
class_name DayWorldView

signal farm_requested
signal farm_plot_action_requested(plot_index: int, action_id: String, seed_id: String)
signal restaurant_requested
signal shop_requested
signal wait_requested
signal night_requested
signal menu_requested
signal legacy_requested

const FARM_BUILDING_TEXTURE := preload("res://assets/source/pixel_packs/tiny_swords/Tiny Swords (Free Pack)/Buildings/Yellow Buildings/House1.png")
const RESTAURANT_TEXTURE := preload("res://assets/source/pixel_packs/tiny_swords/Tiny Swords (Free Pack)/Buildings/Yellow Buildings/Barracks.png")
const SHOP_TEXTURE := preload("res://assets/source/pixel_packs/tiny_swords/Tiny Swords (Free Pack)/Buildings/Yellow Buildings/Archery.png")
const NIGHT_TOWER_TEXTURE := preload("res://assets/source/pixel_packs/tiny_swords/Tiny Swords (Free Pack)/Buildings/Yellow Buildings/Tower.png")
const TREE_TEXTURE := preload("res://assets/source/pixel_packs/tiny_swords/Tiny Swords (Free Pack)/Terrain/Resources/Wood/Trees/Tree1.png")
const STUMP_TEXTURE := preload("res://assets/source/pixel_packs/tiny_swords/Tiny Swords (Free Pack)/Terrain/Resources/Wood/Trees/Stump 1.png")
const BUSH_TEXTURE := preload("res://assets/source/pixel_packs/tiny_swords/Tiny Swords (Free Pack)/Terrain/Decorations/Bushes/Bushe2.png")
const ROCK_TEXTURE := preload("res://assets/source/pixel_packs/tiny_swords/Tiny Swords (Free Pack)/Terrain/Decorations/Rocks/Rock2.png")
const BARRIER_TEXTURE := preload("res://assets/textures/pixel/maps/props/barrier_segment.png")

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

@onready var backdrop: Node2D = $Backdrop
@onready var environment: Node2D = $Environment
@onready var zones_root: Node2D = $Zones
@onready var spawn_point: Marker2D = $SpawnPoint
@onready var day_player: DayPlayerController = $DayPlayer
@onready var hud: DayHud = $HUDLayer/DayHud
@onready var daily_orders_board: DailyOrdersBoardView = $HUDLayer/DailyOrdersBoard

var _view_model: Dictionary = {}
var _farm_model: Dictionary = {}
var _zones: Dictionary = {}
var _farm_plot_zones: Dictionary = {}
var _focused_zone_id: String = ""
var _world_built: bool = false
var _farm_plots_root: Node2D = null
var _selected_farm_tool_key: String = ""
var _tile_root: Node2D = null
var _ground_tiles: TileMapLayer = null
var _detail_tiles: TileMapLayer = null
var _scenery_root: Node2D = null
var _world_tile_set: TileSet = null


func _ready() -> void:
	visible = false
	_build_world_if_needed()
	_register_zones()
	_rebuild_farm_plots()
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
	_apply_view_model()
	_sync_visibility_state()


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if daily_orders_board != null and daily_orders_board.visible:
		return
	if event.is_action_pressed("day_cycle_farm_tool_prev"):
		_cycle_farm_tool(-1)
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("day_cycle_farm_tool_next"):
		_cycle_farm_tool(1)
		get_viewport().set_input_as_handled()


func set_view_model(model: Dictionary) -> void:
	_view_model = model.duplicate(true)
	_apply_view_model()


func set_farm_model(model: Dictionary) -> void:
	_farm_model = model.duplicate(true)
	_sync_selected_farm_tool()
	_rebuild_farm_plots()
	_apply_view_model()


func debug_activate_zone(zone_id: String) -> bool:
	return _activate_zone(zone_id.strip_edges().to_lower())


func debug_select_farm_tool(action_id: String, seed_id: String = "") -> bool:
	var target_key := _build_tool_key_from_parts(action_id, seed_id)
	for tool in _get_farm_tools():
		if _build_tool_key(tool) != target_key:
			continue
		_selected_farm_tool_key = target_key
		_apply_view_model()
		return true
	return false


func debug_interact_farm_plot(plot_index: int) -> bool:
	return _activate_zone("farm_plot_%d" % plot_index)


func debug_get_snapshot() -> Dictionary:
	var selected_tool := _get_selected_farm_tool()
	return {
		"focused_zone_id": _focused_zone_id,
		"prompt_text": _build_prompt_text(),
		"orders_open": daily_orders_board.visible if daily_orders_board != null else false,
		"player_position": day_player.global_position if day_player != null else Vector2.ZERO,
		"selected_farm_tool_action_id": String(selected_tool.get("id", "")),
		"selected_farm_tool_seed_id": String(selected_tool.get("seed_id", "")),
		"selected_farm_tool_label": _farm_tool_title(selected_tool)
	}


func _build_world_if_needed() -> void:
	if _world_built:
		return
	_world_built = true

	_add_rect(backdrop, "Sky", Rect2(0.0, 0.0, 1600.0, 980.0), Color(0.65, 0.83, 0.94, 1.0), -20)
	_add_rect(backdrop, "CloudBand", Rect2(0.0, 24.0, 1600.0, 132.0), Color(0.93, 0.97, 0.99, 0.38), -19)
	_add_rect(backdrop, "HorizonGlow", Rect2(0.0, 112.0, 1600.0, 220.0), Color(0.93, 0.92, 0.74, 0.24), -18)
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


func _build_world_tileset() -> TileSet:
	if _world_tile_set != null:
		return _world_tile_set
	var tile_count := 11
	var atlas_image := Image.create(TILE_SIZE * tile_count, TILE_SIZE, false, Image.FORMAT_RGBA8)
	_draw_grass_tile(atlas_image, 0, Color(0.55, 0.72, 0.40, 1.0), Color(0.63, 0.80, 0.48, 1.0), Color(0.38, 0.55, 0.28, 1.0))
	_draw_grass_tile(atlas_image, 1, Color(0.60, 0.74, 0.44, 1.0), Color(0.70, 0.84, 0.54, 1.0), Color(0.42, 0.58, 0.31, 1.0))
	_draw_path_tile(atlas_image, 2, Color(0.69, 0.58, 0.42, 1.0), Color(0.80, 0.68, 0.50, 1.0), Color(0.51, 0.41, 0.29, 1.0))
	_draw_stone_tile(atlas_image, 3, Color(0.73, 0.72, 0.62, 1.0), Color(0.84, 0.83, 0.74, 1.0), Color(0.56, 0.54, 0.46, 1.0))
	_draw_soil_tile(atlas_image, 4, Color(0.53, 0.37, 0.20, 1.0), Color(0.66, 0.47, 0.28, 1.0), Color(0.37, 0.24, 0.13, 1.0))
	_draw_water_tile(atlas_image, 5, Color(0.32, 0.70, 0.73, 1.0), Color(0.56, 0.88, 0.90, 1.0), Color(0.19, 0.46, 0.53, 1.0))
	_draw_dock_tile(atlas_image, 6, Color(0.56, 0.42, 0.26, 1.0), Color(0.74, 0.56, 0.33, 1.0), Color(0.37, 0.27, 0.18, 1.0))
	_draw_grass_tile(atlas_image, 7, Color(0.44, 0.62, 0.33, 1.0), Color(0.54, 0.71, 0.42, 1.0), Color(0.29, 0.45, 0.24, 1.0))
	_draw_flower_tile(atlas_image, 8)
	_draw_path_tile(atlas_image, 9, Color(0.80, 0.73, 0.56, 1.0), Color(0.90, 0.85, 0.68, 1.0), Color(0.63, 0.55, 0.40, 1.0))
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


func _draw_grass_tile(image: Image, tile_index: int, base: Color, light: Color, dark: Color) -> void:
	_fill_tile_background(image, tile_index, base)
	for y in range(TILE_SIZE):
		for x in range(TILE_SIZE):
			var value := int((x * 11 + y * 17 + tile_index * 7) % 19)
			if value < 4:
				_set_tile_pixel(image, tile_index, x, y, light)
			elif value == 7:
				_set_tile_pixel(image, tile_index, x, y, dark)
	for stripe_y in range(4, TILE_SIZE, 9):
		for stripe_x in range((stripe_y / 3) % 6, TILE_SIZE, 6):
			_set_tile_pixel(image, tile_index, stripe_x, stripe_y, light)
			if stripe_y + 1 < TILE_SIZE:
				_set_tile_pixel(image, tile_index, stripe_x, stripe_y + 1, dark)


func _draw_path_tile(image: Image, tile_index: int, base: Color, light: Color, dark: Color) -> void:
	_fill_tile_background(image, tile_index, base)
	for y in range(TILE_SIZE):
		for x in range(TILE_SIZE):
			var value := int((x * 5 + y * 13 + tile_index * 17) % 23)
			if value < 3:
				_set_tile_pixel(image, tile_index, x, y, light)
			elif value == 8 or value == 11:
				_set_tile_pixel(image, tile_index, x, y, dark)
	for seam_y in [12, 24, 36]:
		for seam_x in range(TILE_SIZE):
			_set_tile_pixel(image, tile_index, seam_x, seam_y, dark)


func _draw_stone_tile(image: Image, tile_index: int, base: Color, light: Color, dark: Color) -> void:
	_fill_tile_background(image, tile_index, base)
	for seam_y in range(0, TILE_SIZE, 16):
		for x in range(TILE_SIZE):
			_set_tile_pixel(image, tile_index, x, seam_y, dark)
	for seam_x in range(0, TILE_SIZE, 16):
		for y in range(TILE_SIZE):
			_set_tile_pixel(image, tile_index, seam_x, y, dark)
	for y in range(1, TILE_SIZE, 6):
		for x in range((y * 3) % 8, TILE_SIZE, 8):
			_set_tile_pixel(image, tile_index, x, y, light)


func _draw_soil_tile(image: Image, tile_index: int, base: Color, light: Color, dark: Color) -> void:
	_fill_tile_background(image, tile_index, base)
	for furrow_y in range(6, TILE_SIZE, 10):
		for x in range(2, TILE_SIZE - 2):
			_set_tile_pixel(image, tile_index, x, furrow_y, dark)
			if furrow_y + 1 < TILE_SIZE:
				_set_tile_pixel(image, tile_index, x, furrow_y + 1, light)
	for y in range(TILE_SIZE):
		for x in range(TILE_SIZE):
			var value := int((x * 9 + y * 7 + tile_index) % 29)
			if value == 0:
				_set_tile_pixel(image, tile_index, x, y, light)


func _draw_water_tile(image: Image, tile_index: int, base: Color, light: Color, dark: Color) -> void:
	_fill_tile_background(image, tile_index, base)
	for wave_y in [8, 20, 32, 42]:
		for x in range(2, TILE_SIZE - 2):
			if (x + wave_y) % 11 < 5:
				_set_tile_pixel(image, tile_index, x, wave_y, light)
			elif (x + wave_y) % 7 == 0:
				_set_tile_pixel(image, tile_index, x, wave_y + 1 if wave_y + 1 < TILE_SIZE else wave_y, dark)
	for y in range(TILE_SIZE):
		for x in range(TILE_SIZE):
			if int((x * 7 + y * 3 + tile_index * 5) % 31) == 0:
				_set_tile_pixel(image, tile_index, x, y, light)


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
			var cell := Vector2i(x, y)
			var tile := TILE_GRASS
			var variation := int((x * 17 + y * 31 + x * y * 3) % 11)
			if variation == 0 or variation == 5:
				tile = TILE_MEADOW
			elif variation == 2 and y > 8:
				tile = TILE_DARK_GRASS
			_ground_tiles.set_cell(cell, 0, tile)
			if tile == TILE_GRASS and int((x * 11 + y * 19) % 17) == 0:
				_detail_tiles.set_cell(cell, 0, TILE_FLOWERS)

	_fill_tile_rect(_ground_tiles, Rect2i(2, 8, 8, 8), TILE_DARK_GRASS)
	_fill_tile_rect(_ground_tiles, Rect2i(3, 10, 4, 4), TILE_SOIL)
	_fill_tile_rect(_ground_tiles, Rect2i(8, 8, 2, 8), TILE_PATH)
	_fill_tile_rect(_ground_tiles, Rect2i(3, 7, 28, 2), TILE_PATH)
	_fill_tile_rect(_ground_tiles, Rect2i(15, 2, 2, 11), TILE_PATH)
	_fill_tile_rect(_ground_tiles, Rect2i(12, 5, 8, 6), TILE_STONE)
	_fill_tile_rect(_ground_tiles, Rect2i(19, 2, 5, 4), TILE_STONE)
	_fill_tile_rect(_ground_tiles, Rect2i(25, 3, 4, 4), TILE_STONE)
	_fill_tile_rect(_ground_tiles, Rect2i(21, 10, 2, 8), TILE_SAND)
	_fill_tile_rect(_ground_tiles, Rect2i(22, 10, 12, 8), TILE_WATER)
	_fill_tile_rect(_ground_tiles, Rect2i(24, 12, 5, 3), TILE_DOCK)
	for foam_x in range(22, 34):
		_detail_tiles.set_cell(Vector2i(foam_x, 10), 0, TILE_FOAM)
	for foam_y in range(10, 18):
		_detail_tiles.set_cell(Vector2i(22, foam_y), 0, TILE_FOAM)


func _fill_tile_rect(layer: TileMapLayer, rect: Rect2i, atlas_coords: Vector2i) -> void:
	for y in range(rect.position.y, rect.position.y + rect.size.y):
		for x in range(rect.position.x, rect.position.x + rect.size.x):
			layer.set_cell(Vector2i(x, y), 0, atlas_coords)


func _build_world_landmarks() -> void:
	if _scenery_root == null:
		return
	for child in _scenery_root.get_children():
		child.free()

	_add_shadow(_scenery_root, "FarmShadow", Vector2(266.0, 568.0), Vector2(116.0, 36.0), Color(0.10, 0.13, 0.12, 0.20), -1)
	_add_sprite(_scenery_root, "FarmHouse", FARM_BUILDING_TEXTURE, Vector2(266.0, 472.0), Vector2(0.84, 0.84), Color.WHITE, 0)
	_add_rect(_scenery_root, "FarmStep", Rect2(236.0, 552.0, 58.0, 22.0), Color(0.78, 0.68, 0.48, 1.0), -1)

	_add_shadow(_scenery_root, "RestaurantShadow", Vector2(996.0, 420.0), Vector2(170.0, 42.0), Color(0.10, 0.13, 0.12, 0.20), -1)
	_add_sprite(_scenery_root, "RestaurantHall", RESTAURANT_TEXTURE, Vector2(996.0, 316.0), Vector2(0.70, 0.70), Color.WHITE, 0)
	_add_rect(_scenery_root, "RestaurantStep", Rect2(948.0, 414.0, 96.0, 24.0), Color(0.82, 0.63, 0.41, 1.0), -1)

	_add_shadow(_scenery_root, "ShopShadow", Vector2(1294.0, 470.0), Vector2(154.0, 38.0), Color(0.10, 0.13, 0.12, 0.20), -1)
	_add_sprite(_scenery_root, "ShopStall", SHOP_TEXTURE, Vector2(1294.0, 366.0), Vector2(0.66, 0.66), Color.WHITE, 0)
	_add_rect(_scenery_root, "ShopStep", Rect2(1248.0, 462.0, 92.0, 22.0), Color(0.82, 0.71, 0.46, 1.0), -1)

	_add_shadow(_scenery_root, "NightShadow", Vector2(1238.0, 728.0), Vector2(108.0, 30.0), Color(0.10, 0.13, 0.12, 0.20), -1)
	_add_sprite(_scenery_root, "NightTower", NIGHT_TOWER_TEXTURE, Vector2(1238.0, 646.0), Vector2(0.74, 0.74), Color.WHITE, 0)
	_add_rect(_scenery_root, "DockBeaconStep", Rect2(1206.0, 720.0, 64.0, 20.0), Color(0.73, 0.56, 0.33, 1.0), -1)

	for tree_position in [Vector2(88.0, 334.0), Vector2(154.0, 304.0), Vector2(1448.0, 294.0), Vector2(1504.0, 612.0), Vector2(1444.0, 774.0)]:
		_add_shadow(_scenery_root, "TreeShadow%s" % str(tree_position), tree_position + Vector2(0.0, 8.0), Vector2(62.0, 22.0), Color(0.10, 0.13, 0.12, 0.16), -1)
		_add_sprite(_scenery_root, "Tree%s" % str(tree_position), TREE_TEXTURE, tree_position - Vector2(0.0, 46.0), Vector2(0.56, 0.56), Color.WHITE, 0)

	for stump_position in [Vector2(410.0, 604.0), Vector2(448.0, 640.0)]:
		_add_shadow(_scenery_root, "StumpShadow%s" % str(stump_position), stump_position, Vector2(20.0, 8.0), Color(0.10, 0.13, 0.12, 0.16), -1)
		_add_sprite(_scenery_root, "Stump%s" % str(stump_position), STUMP_TEXTURE, stump_position - Vector2(0.0, 12.0), Vector2(1.0, 1.0), Color.WHITE, 0)

	for bush_position in [Vector2(524.0, 320.0), Vector2(564.0, 352.0), Vector2(1186.0, 508.0), Vector2(1096.0, 786.0)]:
		_add_shadow(_scenery_root, "BushShadow%s" % str(bush_position), bush_position + Vector2(0.0, 6.0), Vector2(28.0, 10.0), Color(0.10, 0.13, 0.12, 0.12), -1)
		_add_sprite(_scenery_root, "Bush%s" % str(bush_position), BUSH_TEXTURE, bush_position - Vector2(0.0, 8.0), Vector2(1.0, 1.0), Color.WHITE, 0)

	for rock_position in [Vector2(1116.0, 696.0), Vector2(1160.0, 746.0)]:
		_add_shadow(_scenery_root, "RockShadow%s" % str(rock_position), rock_position + Vector2(0.0, 5.0), Vector2(24.0, 8.0), Color(0.10, 0.13, 0.12, 0.12), -1)
		_add_sprite(_scenery_root, "Rock%s" % str(rock_position), ROCK_TEXTURE, rock_position, Vector2(1.0, 1.0), Color.WHITE, 0)

	for i in range(3):
		_add_sprite(_scenery_root, "DockBarrier%d" % i, BARRIER_TEXTURE, Vector2(1140.0 + (i * 44.0), 758.0), Vector2(1.2, 1.2), Color(0.92, 0.79, 0.58, 1.0), 0)

	_add_notice_board(Vector2(1078.0, 598.0))
	_add_bench(Vector2(704.0, 772.0))


func _add_notice_board(base_position: Vector2) -> void:
	var root := Node2D.new()
	root.name = "OrdersBoardProp"
	root.position = base_position
	_scenery_root.add_child(root)
	var post_left := Polygon2D.new()
	post_left.polygon = _rect_polygon(Vector2(8.0, 42.0))
	post_left.position = Vector2(-18.0, -22.0)
	post_left.color = Color(0.49, 0.33, 0.18, 1.0)
	root.add_child(post_left)
	var post_right := post_left.duplicate() as Polygon2D
	post_right.position = Vector2(18.0, -22.0)
	root.add_child(post_right)
	var board := Polygon2D.new()
	board.polygon = _rect_polygon(Vector2(62.0, 42.0))
	board.position = Vector2(0.0, -50.0)
	board.color = Color(0.79, 0.69, 0.49, 1.0)
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
	var bench_shadow := Polygon2D.new()
	bench_shadow.polygon = _ellipse_polygon(Vector2(72.0, 16.0), 10)
	bench_shadow.position = Vector2(0.0, 6.0)
	bench_shadow.color = Color(0.10, 0.13, 0.12, 0.14)
	root.add_child(bench_shadow)
	var seat := Polygon2D.new()
	seat.polygon = _rect_polygon(Vector2(64.0, 12.0))
	seat.position = Vector2(0.0, -8.0)
	seat.color = Color(0.56, 0.38, 0.23, 1.0)
	root.add_child(seat)
	var back := Polygon2D.new()
	back.polygon = _rect_polygon(Vector2(68.0, 10.0))
	back.position = Vector2(0.0, -22.0)
	back.color = Color(0.67, 0.46, 0.29, 1.0)
	root.add_child(back)
	for leg_x in [-22.0, 22.0]:
		var leg := Polygon2D.new()
		leg.polygon = _rect_polygon(Vector2(8.0, 20.0))
		leg.position = Vector2(leg_x, 4.0)
		leg.color = Color(0.42, 0.28, 0.18, 1.0)
		root.add_child(leg)


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
		if zone_root_variant == _farm_plots_root or not (zone_root_variant is Node2D):
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
	var selected_tool := _get_selected_farm_tool()
	hud.set_hud_model({
		"current_day": int(_view_model.get("current_day", 1)),
		"phase": String(_view_model.get("phase", "morning")),
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
		"ready_orders": ready_to_claim,
		"farm_tool_visible": not _get_cycleable_farm_tools().is_empty(),
		"farm_tool_text": _farm_tool_label(selected_tool) if not selected_tool.is_empty() else _t("meta.farm.tool_none"),
		"farm_tool_hint": _t("meta.day_hud.farm_tool_hint")
	})
	_refresh_zone_visuals()


func _build_prompt_text() -> String:
	if daily_orders_board != null and daily_orders_board.visible:
		return _t("meta.world.prompt_orders_open")
	if _focused_zone_id.is_empty():
		return _t("meta.world.prompt_idle")
	if _is_farm_plot_zone(_focused_zone_id):
		var plot := _get_farm_plot_model(_focused_zone_id)
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


func _refresh_zone_visuals() -> void:
	for zone_id_variant in _zones.keys():
		var zone_id := String(zone_id_variant)
		_apply_zone_visual(zone_id, _zones.get(zone_id, {}) as Dictionary, _is_zone_enabled(zone_id), zone_id == _focused_zone_id)
	for zone_id_variant in _farm_plot_zones.keys():
		var zone_id := String(zone_id_variant)
		_apply_zone_visual(zone_id, _farm_plot_zones.get(zone_id, {}) as Dictionary, _is_zone_enabled(zone_id), zone_id == _focused_zone_id)


func _apply_zone_visual(zone_id: String, zone: Dictionary, enabled: bool, focused: bool) -> void:
	var marker := zone.get("marker", null) as Polygon2D
	var pulse := zone.get("pulse", null) as Polygon2D
	var accent_variant: Variant = zone.get("accent", Color.WHITE)
	var accent: Color = accent_variant if accent_variant is Color else Color.WHITE
	if marker != null:
		marker.scale = Vector2.ONE * (1.18 if focused else 1.0)
		marker.color = Color(accent.r, accent.g, accent.b, 0.96 if focused else (0.82 if enabled else 0.24))
	if pulse != null:
		pulse.scale = Vector2.ONE * (1.36 if focused else 1.0)
		pulse.color = Color(accent.r, accent.g, accent.b, 0.26 if enabled else 0.08)


func _is_zone_enabled(zone_id: String) -> bool:
	if _is_farm_plot_zone(zone_id):
		var tool := _get_selected_farm_tool()
		return not tool.is_empty() and bool(tool.get("available", true))
	match zone_id:
		"wait":
			return not bool(_view_model.get("wait_button_disabled", false))
		"night":
			return not bool(_view_model.get("night_button_disabled", false))
	return true


func _get_zone_name(zone_id: String) -> String:
	if _is_farm_plot_zone(zone_id):
		return _farm_plot_name(_get_farm_plot_model(zone_id))
	var zone: Dictionary = _zones.get(zone_id, {}) as Dictionary
	var label_key := String(zone.get("label_key", ""))
	return _t(label_key) if not label_key.is_empty() else zone_id.capitalize()


func _get_zone_tooltip(zone_id: String) -> String:
	if _is_farm_plot_zone(zone_id):
		return _farm_plot_summary(_get_farm_plot_model(zone_id))
	match zone_id:
		"restaurant":
			return String(_view_model.get("restaurant_button_tooltip", ""))
		"shop":
			return String(_view_model.get("shop_button_tooltip", ""))
		"wait":
			return String(_view_model.get("wait_button_tooltip", ""))
		"night":
			return String(_view_model.get("night_button_tooltip", ""))
		"orders":
			return _t("meta.world.orders_tooltip")
	return ""


func _activate_zone(zone_id: String) -> bool:
	if zone_id.is_empty():
		return false
	if _is_farm_plot_zone(zone_id):
		return _activate_farm_plot(zone_id)
	if not _is_zone_enabled(zone_id):
		_apply_view_model()
		return false
	match zone_id:
		"restaurant":
			restaurant_requested.emit()
			return true
		"shop":
			shop_requested.emit()
			return true
		"orders":
			_toggle_daily_orders_board()
			return true
		"wait":
			wait_requested.emit()
			return true
		"night":
			night_requested.emit()
			return true
	return false


func _activate_farm_plot(zone_id: String) -> bool:
	var tool := _get_selected_farm_tool()
	var plot := _get_farm_plot_model(zone_id)
	if tool.is_empty() or plot.is_empty():
		_apply_view_model()
		return false
	farm_plot_action_requested.emit(
		int(plot.get("index", -1)),
		String(tool.get("id", "")),
		String(tool.get("seed_id", ""))
	)
	return true


func _toggle_daily_orders_board() -> void:
	if daily_orders_board == null:
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
		day_player.set_controls_enabled(ui_visible and (daily_orders_board == null or not daily_orders_board.visible))
	_schedule_focus_refresh()


func _schedule_focus_refresh() -> void:
	if day_player != null and day_player.has_method("refresh_interaction_focus"):
		day_player.call_deferred("refresh_interaction_focus")


func _cycle_farm_tool(direction: int) -> void:
	var tools := _get_cycleable_farm_tools()
	if tools.is_empty():
		return
	var current_index := 0
	for tool_index in range(tools.size()):
		if _build_tool_key(tools[tool_index]) != _selected_farm_tool_key:
			continue
		current_index = tool_index
		break
	var next_index := posmod(current_index + direction, tools.size())
	_selected_farm_tool_key = _build_tool_key(tools[next_index])
	_apply_view_model()


func _get_cycleable_farm_tools() -> Array:
	var cycleable: Array = []
	for tool in _get_farm_tools():
		if not bool(tool.get("available", false)):
			continue
		cycleable.append(tool)
	return cycleable


func _get_farm_tools() -> Array:
	var tools_variant: Variant = _farm_model.get("tools", [])
	var tools_source: Array = tools_variant if tools_variant is Array else []
	var tools: Array = []
	for tool_variant in tools_source:
		if not (tool_variant is Dictionary):
			continue
		tools.append((tool_variant as Dictionary).duplicate(true))
	return tools


func _get_selected_farm_tool() -> Dictionary:
	for tool in _get_farm_tools():
		if _build_tool_key(tool) == _selected_farm_tool_key:
			return tool
	return {}


func _sync_selected_farm_tool() -> void:
	var tools := _get_cycleable_farm_tools()
	if tools.is_empty():
		_selected_farm_tool_key = ""
		return
	for tool in tools:
		if _build_tool_key(tool) == _selected_farm_tool_key:
			return
	_selected_farm_tool_key = _build_tool_key(tools[0])


func _build_tool_key(tool: Dictionary) -> String:
	return _build_tool_key_from_parts(String(tool.get("id", "")), String(tool.get("seed_id", "")))


func _build_tool_key_from_parts(action_id: String, seed_id: String) -> String:
	return "%s::%s" % [action_id.strip_edges().to_lower(), seed_id.strip_edges().to_lower()]


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


func _is_farm_plot_zone(zone_id: String) -> bool:
	return zone_id.begins_with("farm_plot_")


func _get_farm_plot_model(zone_id: String) -> Dictionary:
	var zone: Dictionary = _farm_plot_zones.get(zone_id, {}) as Dictionary
	var plot_variant: Variant = zone.get("plot", {})
	return plot_variant if plot_variant is Dictionary else {}


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
	_apply_view_model()


func _on_player_interaction_requested(zone_id: String) -> void:
	_activate_zone(zone_id)


func _on_visibility_changed() -> void:
	_sync_visibility_state()
	_apply_view_model()


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
