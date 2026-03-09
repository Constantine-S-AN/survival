extends Control
class_name ShopController

const StardewLikeAssets := preload("res://scripts/day/stardew_like_asset_library.gd")

signal back_requested
signal seed_purchase_requested(seed_id: String)
signal sell_requested(material_id: String)
signal upgrade_purchase_requested(upgrade_id: String)

const INTERIOR_BOUNDS := Rect2(Vector2(104.0, 144.0), Vector2(1392.0, 704.0))
const TILE_SIZE := 48
const FLOOR_COLUMNS := 30
const FLOOR_ROWS := 16
const FLOOR_ORIGIN := Vector2(80.0, 128.0)
const TILE_WOOD_LIGHT := Vector2i(0, 0)
const TILE_WOOD_DARK := Vector2i(1, 0)
const TILE_STONE := Vector2i(2, 0)
const TILE_RUG := Vector2i(3, 0)
const TILE_MAT := Vector2i(4, 0)
const CAINOS_STONE_SHEET_PATH := "res://assets/external/stardew_like_candidates/unpacked/Pixel-Art-Top-Down---Basic-v1-2-3/Texture/TX Tileset Stone Ground.png"
const HARVEST_TILE_SHEET_PATH := "res://assets/external/stardew_like_candidates/unpacked/Harvest-Farm---Free-pack/Tilesets/harvest_farm_tileset.png"
const ZED_VILLAGE_SHEET_PATH := "res://assets/external/dayworld_visual_pass_2/unpacked/village/Pixel 16 v2 village free/Pixel 16 v2 village free.png"
const ZED_INTERIOR_SHEET_PATH := "res://assets/external/dayworld_visual_pass_2/unpacked/interior/Pixel_16_interiors_v2_free/tiles and items.png"
const ZED_VILLAGE_CRATE_REGIONS := [
	Rect2i(208, 64, 16, 16),
	Rect2i(224, 64, 16, 16),
	Rect2i(240, 64, 16, 16)
]
const ZED_INTERIOR_RUG_GREEN_REGION := Rect2i(144, 96, 16, 16)
const ZED_INTERIOR_WALL_REGION := Rect2i(96, 32, 48, 16)
const ZED_INTERIOR_WINDOW_REGION := Rect2i(144, 32, 16, 16)
const ZED_INTERIOR_TABLE_REGION := Rect2i(49, 107, 30, 21)
const ZED_INTERIOR_SOFA_REGION := Rect2i(82, 131, 44, 29)
const ZED_INTERIOR_PLANT_REGION := Rect2i(49, 140, 12, 20)
const ZED_INTERIOR_STOOL_REGION := Rect2i(99, 115, 12, 13)
const ZED_INTERIOR_CHAIR_LEFT_REGION := Rect2i(145, 142, 14, 18)
const ZED_INTERIOR_CHAIR_RIGHT_REGION := Rect2i(161, 141, 13, 19)
const PROMPT_REVEAL_SECONDS := 0.14
const INFO_PANEL_PREVIEW_ITEMS := 2
const INFO_PANEL_ENTRY_MAX_LENGTH := 18
const PROMPT_LINE_MAX_LENGTH := 58
const PROMPT_MAX_LINES := 2

@onready var world_root: Node2D = $WorldRoot
@onready var hud_layer: CanvasLayer = $HUDLayer
@onready var backdrop: Node2D = $WorldRoot/Backdrop
@onready var environment: Node2D = $WorldRoot/Environment
@onready var zones_root: Node2D = $WorldRoot/Zones
@onready var spawn_point: Marker2D = $WorldRoot/SpawnPoint
@onready var shop_player: DayPlayerController = $WorldRoot/ShopPlayer
@onready var info_title_label: Label = $HUDLayer/InfoPanel/Margin/VBox/Title
@onready var info_stats_label: Label = $HUDLayer/InfoPanel/Margin/VBox/Stats
@onready var info_inventory_label: Label = $HUDLayer/InfoPanel/Margin/VBox/Inventory
@onready var leave_button: Button = $HUDLayer/LeaveButton
@onready var status_panel: Panel = $HUDLayer/StatusPanel
@onready var status_label: Label = $HUDLayer/StatusPanel/Margin/Status
@onready var prompt_panel: Panel = $HUDLayer/PromptPanel
@onready var hint_label: Label = $HUDLayer/PromptPanel/Margin/VBox/Hint
@onready var prompt_label: Label = $HUDLayer/PromptPanel/Margin/VBox/Prompt
@onready var popup_shade: ColorRect = $HUDLayer/PopupShade
@onready var merchant_popup: Panel = $HUDLayer/PopupHost/MerchantPopup
@onready var merchant_title_label: Label = $HUDLayer/PopupHost/MerchantPopup/Margin/VBox/Title
@onready var merchant_subtitle_label: Label = $HUDLayer/PopupHost/MerchantPopup/Margin/VBox/Subtitle
@onready var merchant_dialogue_label: Label = $HUDLayer/PopupHost/MerchantPopup/Margin/VBox/Dialogue
@onready var merchant_inventory_label: Label = $HUDLayer/PopupHost/MerchantPopup/Margin/VBox/Inventory
@onready var merchant_upgrades_label: Label = $HUDLayer/PopupHost/MerchantPopup/Margin/VBox/Upgrades
@onready var seed_title_label: Label = $HUDLayer/PopupHost/MerchantPopup/Margin/VBox/Columns/SeedCard/Margin/VBox/Title
@onready var seed_hint_label: Label = $HUDLayer/PopupHost/MerchantPopup/Margin/VBox/Columns/SeedCard/Margin/VBox/Hint
@onready var seed_scroll: ScrollContainer = $HUDLayer/PopupHost/MerchantPopup/Margin/VBox/Columns/SeedCard/Margin/VBox/Scroll
@onready var seed_list: VBoxContainer = $HUDLayer/PopupHost/MerchantPopup/Margin/VBox/Columns/SeedCard/Margin/VBox/Scroll/List
@onready var sell_title_label: Label = $HUDLayer/PopupHost/MerchantPopup/Margin/VBox/Columns/SellCard/Margin/VBox/Title
@onready var sell_hint_label: Label = $HUDLayer/PopupHost/MerchantPopup/Margin/VBox/Columns/SellCard/Margin/VBox/Hint
@onready var sell_scroll: ScrollContainer = $HUDLayer/PopupHost/MerchantPopup/Margin/VBox/Columns/SellCard/Margin/VBox/Scroll
@onready var sell_list: VBoxContainer = $HUDLayer/PopupHost/MerchantPopup/Margin/VBox/Columns/SellCard/Margin/VBox/Scroll/List
@onready var upgrade_title_label: Label = $HUDLayer/PopupHost/MerchantPopup/Margin/VBox/Columns/UpgradeCard/Margin/VBox/Title
@onready var upgrade_hint_label: Label = $HUDLayer/PopupHost/MerchantPopup/Margin/VBox/Columns/UpgradeCard/Margin/VBox/Hint
@onready var upgrade_scroll: ScrollContainer = $HUDLayer/PopupHost/MerchantPopup/Margin/VBox/Columns/UpgradeCard/Margin/VBox/Scroll
@onready var upgrade_list: VBoxContainer = $HUDLayer/PopupHost/MerchantPopup/Margin/VBox/Columns/UpgradeCard/Margin/VBox/Scroll/List
@onready var merchant_close_button: Button = $HUDLayer/PopupHost/MerchantPopup/Margin/VBox/CloseButton
@onready var customer_popup: Panel = $HUDLayer/PopupHost/CustomerPopup
@onready var customer_title_label: Label = $HUDLayer/PopupHost/CustomerPopup/Margin/VBox/Title
@onready var customer_dialogue_label: Label = $HUDLayer/PopupHost/CustomerPopup/Margin/VBox/Dialogue
@onready var request_title_label: Label = $HUDLayer/PopupHost/CustomerPopup/Margin/VBox/RequestCard/Margin/VBox/RequestTitle
@onready var request_scroll: ScrollContainer = $HUDLayer/PopupHost/CustomerPopup/Margin/VBox/RequestCard/Margin/VBox/RequestScroll
@onready var request_body_box: VBoxContainer = $HUDLayer/PopupHost/CustomerPopup/Margin/VBox/RequestCard/Margin/VBox/RequestScroll/BodyVBox
@onready var request_body_label: Label = $HUDLayer/PopupHost/CustomerPopup/Margin/VBox/RequestCard/Margin/VBox/RequestScroll/BodyVBox/RequestBody
@onready var request_reward_label: Label = $HUDLayer/PopupHost/CustomerPopup/Margin/VBox/RequestCard/Margin/VBox/Reward
@onready var request_status_label: Label = $HUDLayer/PopupHost/CustomerPopup/Margin/VBox/RequestCard/Margin/VBox/Status
@onready var customer_close_button: Button = $HUDLayer/PopupHost/CustomerPopup/Margin/VBox/CloseButton

var _view_model: Dictionary = {}
var _zones: Dictionary = {}
var _focused_zone_id: String = ""
var _active_popup_id: String = ""
var _world_built: bool = false
var _tile_root: Node2D = null
var _ground_tiles: TileMapLayer = null
var _detail_tiles: TileMapLayer = null
var _world_tile_set: TileSet = null
var _zed_village_sheet: Texture2D = null
var _zed_interior_sheet: Texture2D = null
var _props_root: Node2D = null
var _npc_root: Node2D = null
var _ambient_root: Node2D = null
var _ambient_glows: Array[Polygon2D] = []
var _popup_panels: Dictionary = {}
var _was_visible: bool = false
var _ambient_motion_time: float = 0.0
var _ambient_motion_items: Array[Dictionary] = []
var _shopkeeper_npc: Node2D = null
var _regular_npc: Node2D = null
var _prompt_reveal_elapsed: float = 0.0
var _prompt_is_revealed: bool = false
var _feedback_ready: bool = false
var _control_tweens: Dictionary = {}


func _ready() -> void:
	visible = false
	_build_world_if_needed()
	_register_zones()
	_apply_ui_font_overrides()
	_popup_panels = {
		"merchant": merchant_popup,
		"customer": customer_popup
	}
	shop_player.set_world_bounds(INTERIOR_BOUNDS)
	shop_player.reset_to_position(spawn_point.global_position)
	shop_player.focus_changed.connect(_on_player_focus_changed)
	shop_player.interaction_requested.connect(_on_player_interaction_requested)
	_bind_button_feedback(leave_button, false)
	_bind_button_feedback(merchant_close_button, false)
	_bind_button_feedback(customer_close_button, false)
	leave_button.pressed.connect(func() -> void:
		back_requested.emit()
	)
	merchant_close_button.pressed.connect(_close_popups)
	customer_close_button.pressed.connect(_close_popups)
	if Localization != null and Localization.has_signal("language_changed"):
		Localization.language_changed.connect(_on_language_changed)
	visibility_changed.connect(_on_visibility_changed)
	seed_scroll.resized.connect(_sync_scroll_content_widths)
	sell_scroll.resized.connect(_sync_scroll_content_widths)
	upgrade_scroll.resized.connect(_sync_scroll_content_widths)
	request_scroll.resized.connect(_sync_customer_request_width)
	set_process(true)
	_apply_view_model()
	_sync_visibility_state()


func _apply_ui_font_overrides() -> void:
	info_title_label.add_theme_font_size_override("font_size", 19)
	info_stats_label.add_theme_font_size_override("font_size", 12)
	info_inventory_label.add_theme_font_size_override("font_size", 12)
	status_label.add_theme_font_size_override("font_size", 13)
	prompt_label.add_theme_font_size_override("font_size", 15)
	hint_label.add_theme_font_size_override("font_size", 12)
	customer_dialogue_label.add_theme_font_size_override("font_size", 13)
	request_body_label.add_theme_font_size_override("font_size", 13)
	request_reward_label.add_theme_font_size_override("font_size", 13)
	request_status_label.add_theme_font_size_override("font_size", 13)


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if _active_popup_id.is_empty():
		return
	if not event.is_action_pressed("ui_cancel"):
		return
	_close_popups()
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


func set_view_model(model: Dictionary) -> void:
	_view_model = model.duplicate(true)
	_apply_view_model()


func debug_activate_zone(zone_id: String) -> bool:
	return _activate_zone(zone_id.strip_edges().to_lower())


func debug_attempt_world_interaction(zone_id: String) -> bool:
	var normalized_id := zone_id.strip_edges().to_lower()
	if not visible or normalized_id.is_empty() or not _active_popup_id.is_empty():
		return false
	return _activate_zone(normalized_id)


func debug_purchase_seed(seed_id: String) -> bool:
	return _emit_offer_action("merchant", _view_model.get("seed_offers", []), seed_id, seed_purchase_requested)


func debug_sell_material(material_id: String) -> bool:
	return _emit_offer_action("merchant", _view_model.get("sell_offers", []), material_id, sell_requested)


func debug_buy_upgrade(upgrade_id: String) -> bool:
	return _emit_offer_action("merchant", _view_model.get("upgrade_offers", []), upgrade_id, upgrade_purchase_requested)


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
		"player_position": shop_player.global_position if shop_player != null else Vector2.ZERO,
		"request_title": String(_view_model.get("request_title", "")),
		"request_status": String(_view_model.get("request_status", "")),
		"shopkeeper_line": String(_view_model.get("shopkeeper_line", "")),
		"customer_line": String(_view_model.get("customer_line", ""))
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
	StardewLikeAssets.configure_sprite(shop_player.sprite, "base_idle_strip9", 4)
	shop_player.sprite.scale = Vector2(0.82, 0.82)
	_add_rect(backdrop, "WallBack", Rect2(0.0, 0.0, 1600.0, 980.0), Color(0.15, 0.11, 0.08, 1.0), -20)
	_add_rect(backdrop, "WindowGlow", Rect2(0.0, 0.0, 1600.0, 260.0), Color(0.86, 0.75, 0.51, 0.10), -19)
	_ensure_world_layers()
	_paint_floor_tiles()
	_build_static_props()
	_create_zone("shopkeeper", "meta.shop.station_shopkeeper", Vector2(1040.0, 338.0), Vector2(214.0, 116.0), Color(0.97, 0.80, 0.39, 1.0))
	_create_zone("regular", "meta.shop.station_regular", Vector2(478.0, 604.0), Vector2(132.0, 112.0), Color(0.55, 0.83, 0.65, 1.0))
	_create_zone("door", "meta.shop.station_exit", Vector2(798.0, 782.0), Vector2(152.0, 102.0), Color(0.73, 0.86, 0.98, 1.0))


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
	if _npc_root == null:
		_npc_root = Node2D.new()
		_npc_root.name = "NPCs"
		_npc_root.y_sort_enabled = true
		environment.add_child(_npc_root)
	if _ambient_root == null:
		_ambient_root = Node2D.new()
		_ambient_root.name = "Ambient"
		_ambient_root.y_sort_enabled = true
		environment.add_child(_ambient_root)


func _build_world_tileset() -> TileSet:
	if _world_tile_set != null:
		return _world_tile_set
	var atlas_image := Image.create(TILE_SIZE * 5, TILE_SIZE, false, Image.FORMAT_RGBA8)
	atlas_image.fill(Color(0.0, 0.0, 0.0, 0.0))
	_draw_wood_tile(
		atlas_image,
		TILE_WOOD_LIGHT.x,
		Color(0.56, 0.39, 0.22, 1.0),
		Color(0.67, 0.49, 0.29, 1.0),
		Color(0.39, 0.25, 0.15, 1.0)
	)
	_draw_wood_tile(
		atlas_image,
		TILE_WOOD_DARK.x,
		Color(0.48, 0.32, 0.19, 1.0),
		Color(0.58, 0.41, 0.25, 1.0),
		Color(0.32, 0.20, 0.12, 1.0)
	)
	_draw_stone_tile(atlas_image, TILE_STONE.x)
	_draw_rug_tile(atlas_image, TILE_RUG.x)
	_draw_mat_tile(atlas_image, TILE_MAT.x)
	_world_tile_set = StardewLikeAssets.build_tileset_from_atlas_image(atlas_image, 5, TILE_SIZE)
	return _world_tile_set


func _get_zed_village_sheet() -> Texture2D:
	if _zed_village_sheet == null:
		_zed_village_sheet = load(ZED_VILLAGE_SHEET_PATH) as Texture2D
	return _zed_village_sheet


func _get_zed_interior_sheet() -> Texture2D:
	if _zed_interior_sheet == null:
		_zed_interior_sheet = load(ZED_INTERIOR_SHEET_PATH) as Texture2D
	return _zed_interior_sheet


func _make_region_texture(texture_sheet: Texture2D, region: Rect2i) -> AtlasTexture:
	var atlas := AtlasTexture.new()
	atlas.atlas = texture_sheet
	atlas.region = Rect2(region.position, region.size)
	return atlas


func _add_external_sprite(
	parent: Node,
	name: String,
	sprite_name: String,
	position: Vector2,
	scale_value: Vector2,
	z_index: int
) -> Sprite2D:
	var sprite := Sprite2D.new()
	sprite.name = name
	StardewLikeAssets.configure_sprite(sprite, sprite_name)
	sprite.position = position
	sprite.scale = scale_value
	sprite.z_index = z_index
	parent.add_child(sprite)
	return sprite


func _add_external_anim_sprite(
	parent: Node,
	name: String,
	sprite_name: String,
	position: Vector2,
	scale_value: Vector2,
	z_index: int,
	fps: float
) -> AnimatedSprite2D:
	var sprite := AnimatedSprite2D.new()
	sprite.name = name
	StardewLikeAssets.configure_animated_sprite(sprite, sprite_name, fps)
	sprite.position = position
	sprite.scale = scale_value
	sprite.z_index = z_index
	parent.add_child(sprite)
	return sprite


func _draw_wood_tile(image: Image, tile_index: int, base: Color, light: Color, dark: Color) -> void:
	_fill_tile_background(image, tile_index, base)
	for seam_y in [10, 24, 38]:
		for x in range(TILE_SIZE):
			_set_tile_pixel(image, tile_index, x, seam_y, dark)
	for y in range(TILE_SIZE):
		for x in range(TILE_SIZE):
			var value := int((x * 9 + y * 7 + tile_index * 5) % 21)
			if value < 3:
				_set_tile_pixel(image, tile_index, x, y, light)
			elif value == 7:
				_set_tile_pixel(image, tile_index, x, y, dark)


func _draw_stone_tile(image: Image, tile_index: int) -> void:
	_fill_tile_background(image, tile_index, Color(0.68, 0.64, 0.54, 1.0))
	for seam_y in range(0, TILE_SIZE, 16):
		for x in range(TILE_SIZE):
			_set_tile_pixel(image, tile_index, x, seam_y, Color(0.48, 0.45, 0.37, 1.0))
	for seam_x in range(0, TILE_SIZE, 16):
		for y in range(TILE_SIZE):
			_set_tile_pixel(image, tile_index, seam_x, y, Color(0.48, 0.45, 0.37, 1.0))


func _draw_rug_tile(image: Image, tile_index: int) -> void:
	_fill_tile_background(image, tile_index, Color(0.25, 0.43, 0.33, 1.0))
	for y in range(TILE_SIZE):
		for x in range(TILE_SIZE):
			if x < 4 or x >= TILE_SIZE - 4 or y < 4 or y >= TILE_SIZE - 4:
				_set_tile_pixel(image, tile_index, x, y, Color(0.86, 0.74, 0.39, 1.0))
			elif int((x * 3 + y * 5) % 19) == 0:
				_set_tile_pixel(image, tile_index, x, y, Color(0.66, 0.88, 0.71, 1.0))


func _draw_mat_tile(image: Image, tile_index: int) -> void:
	_fill_tile_background(image, tile_index, Color(0.56, 0.42, 0.24, 1.0))
	for y in range(TILE_SIZE):
		for x in range(TILE_SIZE):
			if x < 3 or x >= TILE_SIZE - 3 or y < 3 or y >= TILE_SIZE - 3:
				_set_tile_pixel(image, tile_index, x, y, Color(0.79, 0.64, 0.34, 1.0))


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
	_fill_tile_rect(_ground_tiles, Rect2i(0, 0, FLOOR_COLUMNS, 2), TILE_STONE)
	_fill_tile_rect(_ground_tiles, Rect2i(11, 12, 8, 4), TILE_MAT)
	_fill_tile_rect(_ground_tiles, Rect2i(3, 4, 10, 6), TILE_RUG)
	_fill_tile_rect(_ground_tiles, Rect2i(20, 4, 7, 6), TILE_RUG)
	_fill_tile_rect(_ground_tiles, Rect2i(12, 3, 6, 3), TILE_MAT)
	_fill_tile_rect(_ground_tiles, Rect2i(2, 10, 5, 2), TILE_MAT)
	for threshold_cell in [
		Vector2i(10, 12), Vector2i(11, 12), Vector2i(18, 12), Vector2i(19, 12),
		Vector2i(13, 11), Vector2i(14, 11), Vector2i(15, 11), Vector2i(16, 11),
		Vector2i(6, 10), Vector2i(7, 10), Vector2i(20, 10), Vector2i(21, 10)
	]:
		_ground_tiles.set_cell(threshold_cell, 0, TILE_STONE)


func _fill_tile_rect(layer: TileMapLayer, rect: Rect2i, atlas_coords: Vector2i) -> void:
	for y in range(rect.position.y, rect.position.y + rect.size.y):
		for x in range(rect.position.x, rect.position.x + rect.size.x):
			layer.set_cell(Vector2i(x, y), 0, atlas_coords)


func _build_static_props() -> void:
	if _props_root == null or _npc_root == null or _ambient_root == null:
		return
	for child in _props_root.get_children():
		child.free()
	for child in _npc_root.get_children():
		child.free()
	for child in _ambient_root.get_children():
		child.free()
	_ambient_glows.clear()
	_ambient_motion_items.clear()
	_shopkeeper_npc = null
	_regular_npc = null
	_add_rect(_props_root, "TopWall", Rect2(130.0, 164.0, 1340.0, 46.0), Color(0.60, 0.43, 0.26, 1.0), -1)
	_add_rect(_props_root, "LeftWall", Rect2(130.0, 208.0, 40.0, 592.0), Color(0.35, 0.25, 0.16, 1.0), -1)
	_add_rect(_props_root, "RightWall", Rect2(1430.0, 208.0, 40.0, 592.0), Color(0.35, 0.25, 0.16, 1.0), -1)
	for window_x in [420.0, 1038.0, 1288.0]:
		_add_rect(_props_root, "WindowFrame%s" % str(window_x), Rect2(window_x - 66.0, 182.0, 132.0, 28.0), Color(0.63, 0.46, 0.26, 1.0), -1)
		_add_rect(_props_root, "WindowGlow%s" % str(window_x), Rect2(window_x - 58.0, 188.0, 116.0, 16.0), Color(0.88, 0.93, 0.98, 0.52), 0)

	var seed_shelves := Node2D.new()
	seed_shelves.name = "SeedShelves"
	seed_shelves.position = Vector2(282.0, 298.0)
	_props_root.add_child(seed_shelves)
	for shelf_y in [0.0, 42.0, 84.0]:
		_add_rect(seed_shelves, "Shelf%s" % str(shelf_y), Rect2(-88.0, shelf_y, 176.0, 12.0), Color(0.63, 0.45, 0.24, 1.0), 0)
	_add_external_sprite(seed_shelves, "SeedCrateA", "spr_deco_crate_01", Vector2(-54.0, 6.0), Vector2(2.2, 2.2), 1)
	_add_external_sprite(seed_shelves, "SeedCrateB", "spr_deco_crate_02", Vector2(-4.0, 8.0), Vector2(2.2, 2.2), 1)
	_add_external_sprite(seed_shelves, "SeedJarA", "spr_deco_jar_01", Vector2(48.0, 2.0), Vector2(2.2, 2.2), 1)
	_add_external_sprite(seed_shelves, "SeedBook", "spr_deco_book_01", Vector2(76.0, 4.0), Vector2(2.0, 2.0), 1)
	_add_external_sprite(seed_shelves, "SeedJarB", "spr_deco_jar_02", Vector2(-40.0, 48.0), Vector2(2.2, 2.2), 1)
	_add_external_sprite(seed_shelves, "SeedBucket", "spr_deco_bucket", Vector2(10.0, 52.0), Vector2(2.2, 2.2), 1)
	_add_external_sprite(seed_shelves, "SeedCoins", "spr_deco_coin", Vector2(56.0, 52.0), Vector2(1.8, 1.8), 1)
	_add_external_sprite(seed_shelves, "SeedRug", "spr_deco_rug_01", Vector2(0.0, 138.0), Vector2(2.8, 2.8), -1)

	var counter := Node2D.new()
	counter.name = "Counter"
	counter.position = Vector2(1038.0, 316.0)
	_props_root.add_child(counter)
	_add_shadow(counter, "Shadow", Vector2(0.0, 34.0), Vector2(328.0, 42.0), Color(0.04, 0.02, 0.01, 0.18), -2)
	_add_rect(counter, "Body", Rect2(-148.0, 8.0, 296.0, 68.0), Color(0.47, 0.31, 0.18, 1.0), 0)
	_add_rect(counter, "Top", Rect2(-156.0, -24.0, 312.0, 18.0), Color(0.74, 0.56, 0.31, 1.0), 1)
	_add_external_sprite(counter, "Ledger", "spr_deco_book_02", Vector2(118.0, -18.0), Vector2(2.1, 2.1), 2)
	_add_external_sprite(counter, "Coins", "spr_deco_coins", Vector2(70.0, -18.0), Vector2(1.8, 1.8), 2)
	_add_external_sprite(counter, "JarA", "spr_deco_jar_01", Vector2(-82.0, -16.0), Vector2(2.0, 2.0), 2)
	_add_external_sprite(counter, "JarB", "spr_deco_jar_02", Vector2(-36.0, -16.0), Vector2(2.0, 2.0), 2)
	_add_external_sprite(counter, "Mug", "spr_deco_mug_01", Vector2(18.0, -16.0), Vector2(2.0, 2.0), 2)

	var request_corner := Node2D.new()
	request_corner.name = "RequestCorner"
	request_corner.position = Vector2(470.0, 564.0)
	_props_root.add_child(request_corner)
	_add_external_sprite(request_corner, "BoardCrate", "spr_deco_crate_02", Vector2(-26.0, 0.0), Vector2(2.4, 2.4), 1)
	_add_external_sprite(request_corner, "BoardChest", "spr_deco_chest_01_closed", Vector2(20.0, -8.0), Vector2(2.3, 2.3), 1)
	_add_external_sprite(request_corner, "BoardBook", "spr_deco_book_01", Vector2(8.0, -42.0), Vector2(2.0, 2.0), 2)
	_add_external_sprite(request_corner, "BoardJar", "spr_deco_jar_02", Vector2(-44.0, -34.0), Vector2(2.0, 2.0), 2)

	var display_table := Node2D.new()
	display_table.name = "DisplayTable"
	display_table.position = Vector2(782.0, 566.0)
	_props_root.add_child(display_table)
	_add_external_sprite(display_table, "Table", "spr_deco_sidetable_01", Vector2.ZERO, Vector2(3.0, 3.0), 0)
	_add_external_sprite(display_table, "Plate", "spr_deco_plate_food", Vector2(-22.0, -10.0), Vector2(2.2, 2.2), 1)
	_add_external_sprite(display_table, "Mug", "spr_deco_mug_02", Vector2(22.0, -12.0), Vector2(2.1, 2.1), 1)
	_add_external_sprite(display_table, "Jar", "spr_deco_jar_01", Vector2(0.0, -22.0), Vector2(2.0, 2.0), 1)

	var upgrade_corner := Node2D.new()
	upgrade_corner.name = "UpgradeCorner"
	upgrade_corner.position = Vector2(1286.0, 300.0)
	_props_root.add_child(upgrade_corner)
	for shelf_y in [0.0, 42.0, 84.0]:
		_add_rect(upgrade_corner, "Shelf%s" % str(shelf_y), Rect2(-84.0, shelf_y, 168.0, 12.0), Color(0.58, 0.41, 0.24, 1.0), 0)
	_add_external_sprite(upgrade_corner, "Anvil", "spr_deco_anvil", Vector2(-46.0, 4.0), Vector2(2.4, 2.4), 1)
	_add_external_sprite(upgrade_corner, "UpgradeCrate", "spr_deco_crate_01", Vector2(8.0, 8.0), Vector2(2.2, 2.2), 1)
	_add_external_sprite(upgrade_corner, "UpgradeChest", "spr_deco_chest_02_closed", Vector2(58.0, 4.0), Vector2(2.2, 2.2), 1)
	_add_external_sprite(upgrade_corner, "UpgradeBucket", "spr_deco_bucket", Vector2(-28.0, 48.0), Vector2(2.1, 2.1), 1)
	_add_external_sprite(upgrade_corner, "UpgradeBook", "spr_deco_book_02", Vector2(28.0, 50.0), Vector2(2.0, 2.0), 1)

	var waiting_nook := Node2D.new()
	waiting_nook.name = "WaitingNook"
	waiting_nook.position = Vector2(632.0, 642.0)
	_props_root.add_child(waiting_nook)
	_add_external_sprite(waiting_nook, "Rug", "spr_deco_rug_01", Vector2(0.0, 46.0), Vector2(3.4, 3.4), -1)
	_add_external_sprite(waiting_nook, "Table", "spr_deco_sidetable_01", Vector2(0.0, 0.0), Vector2(3.0, 3.0), 0)
	_add_external_sprite(waiting_nook, "Chair", "spr_deco_chair_01", Vector2(82.0, 18.0), Vector2(2.6, 2.6), 0)
	_add_external_sprite(waiting_nook, "Flowers", "spr_deco_flowers_house_02", Vector2(-86.0, 12.0), Vector2(2.8, 2.8), 1)

	_add_entry_door(Vector2(798.0, 778.0))
	_shopkeeper_npc = _add_shopkeeper_npc(Vector2(1040.0, 286.0))
	_regular_npc = _add_regular_npc(Vector2(478.0, 590.0))
	_register_ambient_motion(_shopkeeper_npc, Vector2(0.0, 2.2), 1.1, 0.4)
	_register_ambient_motion(_regular_npc, Vector2(0.0, 2.8), 1.3, 1.2)
	for glow_position in [Vector2(320.0, 246.0), Vector2(1040.0, 246.0), Vector2(1286.0, 246.0)]:
		_ambient_glows.append(_add_glow(_ambient_root, glow_position, Vector2(144.0, 74.0), Color(1.0, 0.78, 0.42, 0.10)))
	_ambient_glows.append(_add_glow(_ambient_root, Vector2(1038.0, 394.0), Vector2(238.0, 84.0), Color(1.0, 0.82, 0.48, 0.0)))


func _add_back_wall_textures() -> void:
	var wall_texture := _make_region_texture(_get_zed_interior_sheet(), ZED_INTERIOR_WALL_REGION)
	for offset_x in [244.0, 430.0, 616.0, 802.0, 988.0, 1174.0]:
		var wall_strip := Sprite2D.new()
		wall_strip.texture = wall_texture
		wall_strip.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		wall_strip.position = Vector2(offset_x, 188.0)
		wall_strip.scale = Vector2(2.8, 2.0)
		wall_strip.z_index = -1
		_props_root.add_child(wall_strip)
	var window_texture := _make_region_texture(_get_zed_interior_sheet(), ZED_INTERIOR_WINDOW_REGION)
	for window_x in [420.0, 1038.0, 1288.0]:
		var window_sprite := Sprite2D.new()
		window_sprite.texture = window_texture
		window_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		window_sprite.position = Vector2(window_x, 196.0)
		window_sprite.scale = Vector2(2.4, 2.4)
		window_sprite.z_index = 0
		_props_root.add_child(window_sprite)


func _add_waiting_nook(position: Vector2) -> void:
	var root := Node2D.new()
	root.name = "WaitingNook"
	root.position = position
	_props_root.add_child(root)
	_add_shadow(root, "Shadow", Vector2(0.0, 28.0), Vector2(168.0, 34.0), Color(0.04, 0.02, 0.01, 0.14), -2)
	_add_sprite(root, "Sofa", _make_region_texture(_get_zed_interior_sheet(), ZED_INTERIOR_SOFA_REGION), Vector2(0.0, 0.0), Vector2(2.1, 2.1), Color.WHITE, 0)
	_add_sprite(root, "Plant", _make_region_texture(_get_zed_interior_sheet(), ZED_INTERIOR_PLANT_REGION), Vector2(-104.0, 8.0), Vector2(2.2, 2.2), Color.WHITE, 0)
	_add_sprite(root, "Table", _make_region_texture(_get_zed_interior_sheet(), ZED_INTERIOR_TABLE_REGION), Vector2(104.0, -6.0), Vector2(2.0, 2.0), Color.WHITE, 0)
	_add_sprite(root, "ChairLeft", _make_region_texture(_get_zed_interior_sheet(), ZED_INTERIOR_CHAIR_LEFT_REGION), Vector2(84.0, 24.0), Vector2(2.0, 2.0), Color.WHITE, 0)
	_add_sprite(root, "ChairRight", _make_region_texture(_get_zed_interior_sheet(), ZED_INTERIOR_CHAIR_RIGHT_REGION), Vector2(126.0, 22.0), Vector2(2.0, 2.0), Color.WHITE, 0)
	_add_sprite(root, "Rug", _make_region_texture(_get_zed_interior_sheet(), ZED_INTERIOR_RUG_GREEN_REGION), Vector2(-4.0, 54.0), Vector2(3.0, 2.6), Color.WHITE, -1)


func _add_counter(position: Vector2) -> void:
	var root := Node2D.new()
	root.name = "Counter"
	root.position = position
	_props_root.add_child(root)
	_add_shadow(root, "Shadow", Vector2(0.0, 36.0), Vector2(318.0, 44.0), Color(0.04, 0.02, 0.01, 0.18), -2)
	var body := Polygon2D.new()
	body.position = Vector2(0.0, 26.0)
	body.polygon = _rect_polygon(Vector2(296.0, 68.0))
	body.color = Color(0.47, 0.31, 0.18, 1.0)
	root.add_child(body)
	var surface := Polygon2D.new()
	surface.position = Vector2(0.0, -8.0)
	surface.polygon = _rect_polygon(Vector2(312.0, 18.0))
	surface.color = Color(0.74, 0.56, 0.31, 1.0)
	root.add_child(surface)
	for item_offset in [Vector2(-92.0, -18.0), Vector2(-48.0, -16.0), Vector2(34.0, -20.0), Vector2(82.0, -18.0)]:
		var jar := Polygon2D.new()
		jar.position = item_offset
		jar.polygon = _rect_polygon(Vector2(20.0, 30.0))
		jar.color = Color(0.72, 0.83, 0.88, 1.0)
		root.add_child(jar)
	var scale_stand := Polygon2D.new()
	scale_stand.polygon = _rect_polygon(Vector2(10.0, 30.0))
	scale_stand.position = Vector2(-6.0, -18.0)
	scale_stand.color = Color(0.40, 0.29, 0.18, 1.0)
	root.add_child(scale_stand)
	var scale_beam := Polygon2D.new()
	scale_beam.polygon = _rect_polygon(Vector2(42.0, 4.0))
	scale_beam.position = Vector2(-6.0, -30.0)
	scale_beam.color = Color(0.56, 0.40, 0.25, 1.0)
	root.add_child(scale_beam)
	for tray_x in [-22.0, 10.0]:
		var tray := Polygon2D.new()
		tray.polygon = _ellipse_polygon(Vector2(18.0, 10.0), 10)
		tray.position = Vector2(tray_x, -22.0)
		tray.color = Color(0.86, 0.74, 0.52, 1.0)
		root.add_child(tray)
	var ledger := Polygon2D.new()
	ledger.polygon = _rect_polygon(Vector2(28.0, 18.0))
	ledger.position = Vector2(118.0, -24.0)
	ledger.color = Color(0.30, 0.47, 0.29, 1.0)
	root.add_child(ledger)


func _add_seed_shelves(position: Vector2) -> void:
	var root := Node2D.new()
	root.name = "SeedShelves"
	root.position = position
	_props_root.add_child(root)
	for shelf_index in range(3):
		var shelf := Polygon2D.new()
		shelf.position = Vector2(0.0, float(shelf_index * 34))
		shelf.polygon = _rect_polygon(Vector2(152.0, 18.0))
		shelf.color = Color(0.62, 0.44, 0.24, 1.0)
		root.add_child(shelf)
		for jar_index in range(4):
			var jar := Polygon2D.new()
			jar.position = Vector2(-54.0 + float(jar_index * 36), -12.0 + float(shelf_index * 34))
			jar.polygon = _rect_polygon(Vector2(18.0, 22.0))
			jar.color = Color(0.62 + (0.05 * shelf_index), 0.74 + (0.04 * jar_index), 0.44, 1.0)
			root.add_child(jar)
	var banner := Polygon2D.new()
	banner.polygon = _rect_polygon(Vector2(92.0, 16.0))
	banner.position = Vector2(0.0, -30.0)
	banner.color = Color(0.47, 0.68, 0.31, 1.0)
	root.add_child(banner)
	for sack_x in [-52.0, 52.0]:
		var sack := Polygon2D.new()
		sack.polygon = _ellipse_polygon(Vector2(24.0, 28.0), 12)
		sack.position = Vector2(sack_x, 94.0)
		sack.color = Color(0.82, 0.72, 0.44, 1.0)
		root.add_child(sack)


func _add_upgrade_shelves(position: Vector2) -> void:
	var root := Node2D.new()
	root.name = "UpgradeShelves"
	root.position = position
	_props_root.add_child(root)
	for shelf_index in range(3):
		var shelf := Polygon2D.new()
		shelf.position = Vector2(0.0, float(shelf_index * 34))
		shelf.polygon = _rect_polygon(Vector2(144.0, 18.0))
		shelf.color = Color(0.55, 0.40, 0.24, 1.0)
		root.add_child(shelf)
		for crate_index in range(3):
			var crate := Polygon2D.new()
			crate.position = Vector2(-40.0 + float(crate_index * 42), -12.0 + float(shelf_index * 34))
			crate.polygon = _rect_polygon(Vector2(26.0, 24.0))
			crate.color = Color(0.68, 0.63, 0.53, 1.0)
			root.add_child(crate)
	var banner := Polygon2D.new()
	banner.polygon = _rect_polygon(Vector2(96.0, 16.0))
	banner.position = Vector2(0.0, -30.0)
	banner.color = Color(0.58, 0.67, 0.82, 1.0)
	root.add_child(banner)
	for hook_x in [-44.0, 0.0, 44.0]:
		var hook := Polygon2D.new()
		hook.polygon = _rect_polygon(Vector2(6.0, 26.0))
		hook.position = Vector2(hook_x, 92.0)
		hook.color = Color(0.36, 0.28, 0.20, 1.0)
		root.add_child(hook)
		var tool := Polygon2D.new()
		tool.polygon = _rect_polygon(Vector2(16.0, 8.0))
		tool.position = Vector2(hook_x + 2.0, 104.0)
		tool.color = Color(0.74, 0.78, 0.82, 1.0)
		root.add_child(tool)


func _add_parcel_stack(position: Vector2) -> void:
	var root := Node2D.new()
	root.name = "ParcelStack"
	root.position = position
	_props_root.add_child(root)
	_add_shadow(root, "Shadow", Vector2(0.0, 24.0), Vector2(122.0, 26.0), Color(0.04, 0.02, 0.01, 0.18), -2)
	var parcel_offsets: Array[Vector2] = [Vector2(-24.0, 0.0), Vector2(18.0, -8.0), Vector2(0.0, -28.0)]
	for parcel_index in range(3):
		var parcel_offset: Vector2 = parcel_offsets[parcel_index]
		var crate_region: Rect2i = ZED_VILLAGE_CRATE_REGIONS[posmod(parcel_index, ZED_VILLAGE_CRATE_REGIONS.size())]
		_add_sprite(root, "Crate%d" % parcel_index, _make_region_texture(_get_zed_village_sheet(), crate_region), parcel_offset, Vector2(2.1, 2.1), Color.WHITE, 0)


func _add_display_table(position: Vector2) -> void:
	var root := Node2D.new()
	root.name = "DisplayTable"
	root.position = position
	_props_root.add_child(root)
	_add_shadow(root, "Shadow", Vector2(0.0, 18.0), Vector2(156.0, 30.0), Color(0.04, 0.02, 0.01, 0.18), -2)
	var tabletop := Polygon2D.new()
	tabletop.position = Vector2(0.0, 0.0)
	tabletop.polygon = _rect_polygon(Vector2(138.0, 38.0))
	tabletop.color = Color(0.71, 0.51, 0.28, 1.0)
	root.add_child(tabletop)
	var produce_colors := [
		Color(0.72, 0.84, 0.52, 1.0),
		Color(0.96, 0.76, 0.42, 1.0),
		Color(0.81, 0.92, 0.56, 1.0)
	]
	var produce_offsets: Array[Vector2] = [Vector2(-40.0, -8.0), Vector2(0.0, -10.0), Vector2(38.0, -6.0)]
	for produce_index in range(3):
		var produce_offset: Vector2 = produce_offsets[produce_index]
		var produce := Polygon2D.new()
		produce.position = produce_offset
		produce.polygon = _ellipse_polygon(Vector2(24.0, 16.0), 10)
		produce.color = produce_colors[produce_index]
		root.add_child(produce)


func _add_seed_bins(position: Vector2) -> void:
	var root := Node2D.new()
	root.name = "SeedBins"
	root.position = position
	_props_root.add_child(root)
	_add_shadow(root, "Shadow", Vector2(0.0, 16.0), Vector2(98.0, 20.0), Color(0.04, 0.02, 0.01, 0.16), -2)
	for bin_index in range(3):
		var bin := Polygon2D.new()
		bin.polygon = _rect_polygon(Vector2(26.0, 20.0))
		bin.position = Vector2(-28.0 + float(bin_index * 28), -6.0)
		bin.color = Color(0.72, 0.54, 0.30, 1.0)
		root.add_child(bin)
		var fill := Polygon2D.new()
		fill.polygon = _ellipse_polygon(Vector2(18.0, 10.0), 10)
		fill.position = Vector2(-28.0 + float(bin_index * 28), -12.0)
		fill.color = Color(0.84 - float(bin_index) * 0.06, 0.88, 0.52, 1.0)
		root.add_child(fill)


func _add_request_board(position: Vector2) -> void:
	var root := Node2D.new()
	root.name = "RequestBoard"
	root.position = position
	_props_root.add_child(root)
	_add_shadow(root, "Shadow", Vector2(0.0, 18.0), Vector2(72.0, 18.0), Color(0.04, 0.02, 0.01, 0.16), -2)
	for post_x in [-18.0, 18.0]:
		var post := Polygon2D.new()
		post.polygon = _rect_polygon(Vector2(8.0, 48.0))
		post.position = Vector2(post_x, -10.0)
		post.color = Color(0.49, 0.34, 0.18, 1.0)
		root.add_child(post)
	var board := Polygon2D.new()
	board.polygon = _rect_polygon(Vector2(58.0, 34.0))
	board.position = Vector2(0.0, -34.0)
	board.color = Color(0.82, 0.71, 0.48, 1.0)
	root.add_child(board)
	for note_offset in [Vector2(-12.0, -40.0), Vector2(10.0, -34.0), Vector2(0.0, -26.0)]:
		var note := Polygon2D.new()
		note.polygon = _rect_polygon(Vector2(14.0, 10.0))
		note.position = note_offset
		note.color = Color(0.97, 0.93, 0.84, 1.0)
		root.add_child(note)


func _add_upgrade_display(position: Vector2) -> void:
	var root := Node2D.new()
	root.name = "UpgradeDisplay"
	root.position = position
	_props_root.add_child(root)
	_add_shadow(root, "Shadow", Vector2(0.0, 14.0), Vector2(92.0, 20.0), Color(0.04, 0.02, 0.01, 0.16), -2)
	var stand := Polygon2D.new()
	stand.polygon = _rect_polygon(Vector2(76.0, 18.0))
	stand.position = Vector2(0.0, -2.0)
	stand.color = Color(0.64, 0.47, 0.27, 1.0)
	root.add_child(stand)
	for display_index in range(3):
		var base_x := -24.0 + float(display_index * 24)
		var base := Polygon2D.new()
		base.polygon = _rect_polygon(Vector2(14.0, 18.0))
		base.position = Vector2(base_x, -14.0)
		base.color = Color(0.74, 0.78, 0.82, 1.0)
		root.add_child(base)
		var cap := Polygon2D.new()
		cap.polygon = _ellipse_polygon(Vector2(18.0, 10.0), 10)
		cap.position = Vector2(base_x, -24.0)
		cap.color = Color(0.58, 0.70, 0.86, 1.0)
		root.add_child(cap)


func _add_entry_door(position: Vector2) -> void:
	var root := Node2D.new()
	root.name = "Doorway"
	root.position = position
	_props_root.add_child(root)
	_add_shadow(root, "Shadow", Vector2(0.0, 14.0), Vector2(132.0, 24.0), Color(0.04, 0.02, 0.01, 0.18), -2)
	var mat := Polygon2D.new()
	mat.position = Vector2(0.0, 6.0)
	mat.polygon = _ellipse_polygon(Vector2(118.0, 30.0), 12)
	mat.color = Color(0.37, 0.24, 0.13, 1.0)
	root.add_child(mat)
	var frame := Polygon2D.new()
	frame.position = Vector2(0.0, -34.0)
	frame.polygon = _rect_polygon(Vector2(122.0, 84.0))
	frame.color = Color(0.46, 0.31, 0.18, 1.0)
	root.add_child(frame)
	var opening := Polygon2D.new()
	opening.position = Vector2(0.0, -34.0)
	opening.polygon = _rect_polygon(Vector2(90.0, 66.0))
	opening.color = Color(0.11, 0.08, 0.06, 1.0)
	root.add_child(opening)


func _add_shopkeeper_npc(position: Vector2) -> Node2D:
	var root := Node2D.new()
	root.name = "ShopkeeperNPC"
	root.position = position
	_npc_root.add_child(root)
	_add_shadow(root, "Shadow", Vector2(0.0, 16.0), Vector2(34.0, 12.0), Color(0.04, 0.02, 0.01, 0.18), -2)
	_add_external_anim_sprite(root, "Body", "bowlhair_idle_strip9", Vector2.ZERO, Vector2(0.88, 0.88), 0, 7.0)
	return root


func _add_regular_npc(position: Vector2) -> Node2D:
	var root := Node2D.new()
	root.name = "RegularNPC"
	root.position = position
	_npc_root.add_child(root)
	_add_shadow(root, "Shadow", Vector2(0.0, 16.0), Vector2(32.0, 12.0), Color(0.04, 0.02, 0.01, 0.18), -2)
	_add_external_anim_sprite(root, "Body", "longhair_idle_strip9", Vector2.ZERO, Vector2(0.86, 0.86), 0, 7.0)
	return root


func _register_ambient_motion(node: Node2D, amplitude: Vector2, speed: float, phase_offset: float) -> void:
	if node == null:
		return
	_ambient_motion_items.append({
		"node": node,
		"base_position": node.position,
		"amplitude": amplitude,
		"speed": speed,
		"phase_offset": phase_offset
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
		var drift := cos((_ambient_motion_time * speed * 0.64) + (phase_offset * 0.6))
		node.position = base_position + Vector2(amplitude.x * drift, amplitude.y * wave)


func _add_glow(parent: Node2D, position: Vector2, size: Vector2, color: Color) -> Polygon2D:
	var glow := Polygon2D.new()
	glow.position = position
	glow.polygon = _ellipse_polygon(size, 16)
	glow.color = color
	parent.add_child(glow)
	return glow


func _add_shadow(parent: Node2D, name: String, position: Vector2, size: Vector2, color: Color, z_index: int) -> void:
	var shadow := Polygon2D.new()
	shadow.name = name
	shadow.position = position
	shadow.polygon = _ellipse_polygon(size, 14)
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
	pulse.polygon = _ellipse_polygon(Vector2(maxf(size.x * 0.56, 58.0), 26.0), 14)
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
	marker.position = Vector2(0.0, -10.0)
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
	var previous_status_text := status_label.text.strip_edges()
	var previous_prompt_signature := "%s|%s" % [str(prompt_panel.visible), prompt_label.text]
	_apply_phase_ambience(String(_view_model.get("phase", "morning")))
	var inventory_summary := String(_view_model.get("inventory_summary", _t("meta.common.none")))
	info_title_label.text = _t("meta.shop.world_title")
	info_stats_label.text = _t("meta.shop.stats", {
		"day": int(_view_model.get("current_day", 1)),
		"phase": _t("meta.phase.%s" % String(_view_model.get("phase", "morning"))),
		"gold": int(_view_model.get("gold", 0)),
		"actions": int(_view_model.get("action_budget", 0)),
		"action_max": int(_view_model.get("max_action_budget", 0))
	})
	info_inventory_label.text = _t("meta.shop.inventory", {
		"value": _compact_panel_inventory(inventory_summary)
	})
	info_inventory_label.tooltip_text = _build_panel_tooltip(
		inventory_summary,
		String(_view_model.get("inventory_tooltip", ""))
	)
	leave_button.text = _t("meta.shop.leave")
	status_label.text = String(_view_model.get("status_text", ""))
	status_panel.visible = not status_label.text.strip_edges().is_empty()
	hint_label.text = _t("meta.shop.world_move_hint")
	var prompt_text := _build_prompt_text()
	prompt_label.text = _compact_prompt_text(prompt_text)
	prompt_label.tooltip_text = prompt_text
	prompt_panel.visible = _should_show_prompt_panel()
	hint_label.visible = prompt_panel.visible and prompt_label.text.strip_edges().is_empty()

	merchant_title_label.text = _t("meta.shop.popup_merchant_title")
	merchant_subtitle_label.text = _t("meta.shop.subtitle")
	merchant_dialogue_label.text = String(_view_model.get("shopkeeper_line", ""))
	merchant_inventory_label.text = _t("meta.shop.inventory", {
		"value": inventory_summary
	})
	merchant_inventory_label.tooltip_text = _build_panel_tooltip(
		inventory_summary,
		String(_view_model.get("inventory_tooltip", ""))
	)
	merchant_upgrades_label.text = _t("meta.shop.owned_upgrades", {
		"value": String(_view_model.get("owned_upgrades_summary", _t("meta.shop.owned_none")))
	})
	seed_title_label.text = _t("meta.shop.seed_title")
	seed_hint_label.text = _t("meta.shop.seed_hint")
	sell_title_label.text = _t("meta.shop.sell_title")
	sell_hint_label.text = _t("meta.shop.sell_hint")
	upgrade_title_label.text = _t("meta.shop.upgrade_title")
	upgrade_hint_label.text = _t("meta.shop.upgrade_hint")
	merchant_close_button.text = _t("meta.common.close")
	_rebuild_seed_buttons()
	_rebuild_sell_buttons()
	_rebuild_upgrade_buttons()

	customer_title_label.text = _t("meta.shop.popup_customer_title")
	customer_dialogue_label.text = String(_view_model.get("customer_line", ""))
	customer_dialogue_label.tooltip_text = customer_dialogue_label.text
	request_title_label.text = String(_view_model.get("request_title", _t("meta.shop.request_none_title")))
	request_body_label.text = String(_view_model.get("request_body", _t("meta.shop.request_none_body")))
	request_body_label.tooltip_text = request_body_label.text
	var request_reward := String(_view_model.get("request_reward", "")).strip_edges()
	request_reward_label.text = _t("meta.shop.request_reward", {
		"value": request_reward if not request_reward.is_empty() else _t("meta.common.none")
	})
	request_reward_label.tooltip_text = request_reward_label.text
	request_status_label.text = _t("meta.shop.request_status", {
		"value": String(_view_model.get("request_status", _t("meta.shop.request_none_status")))
	})
	request_status_label.tooltip_text = request_status_label.text
	customer_close_button.text = _t("meta.common.close")

	_sync_scroll_content_widths()
	_sync_customer_request_width()
	_refresh_zone_visuals()
	_update_popup_visibility()
	_apply_micro_feedback(
		status_label.text.strip_edges(),
		"%s|%s" % [str(prompt_panel.visible), prompt_label.text],
		previous_status_text,
		previous_prompt_signature
	)


func _apply_phase_ambience(phase: String) -> void:
	var glow_alpha := 0.10
	var shopkeeper_alpha := 1.0
	var regular_alpha := 0.56
	match phase.strip_edges().to_lower():
		"morning":
			regular_alpha = 0.40
		"noon":
			glow_alpha = 0.14
			regular_alpha = 0.68
		"afternoon":
			glow_alpha = 0.18
			regular_alpha = 0.92
		"evening":
			glow_alpha = 0.28
			shopkeeper_alpha = 0.88
			regular_alpha = 0.70
		"night":
			glow_alpha = 0.0
			shopkeeper_alpha = 0.24
			regular_alpha = 0.0
	for glow in _ambient_glows:
		if glow == null:
			continue
		glow.color.a = glow_alpha
	if not String(_view_model.get("request_title", "")).strip_edges().is_empty():
		regular_alpha = maxf(regular_alpha, 0.78)
	if _shopkeeper_npc != null:
		_shopkeeper_npc.visible = shopkeeper_alpha > 0.03
		_shopkeeper_npc.modulate = Color(1.0, 1.0, 1.0, clampf(shopkeeper_alpha, 0.0, 1.0))
	if _regular_npc != null:
		_regular_npc.visible = regular_alpha > 0.03
		_regular_npc.modulate = Color(1.0, 1.0, 1.0, clampf(regular_alpha, 0.0, 1.0))


func _update_prompt_reveal(delta: float) -> void:
	var can_reveal := _active_popup_id.is_empty() and not _focused_zone_id.is_empty()
	var changed := false
	if not can_reveal:
		changed = _prompt_is_revealed or _prompt_reveal_elapsed > 0.0
		_prompt_reveal_elapsed = 0.0
		_prompt_is_revealed = false
	else:
		_prompt_reveal_elapsed += delta
		if not _prompt_is_revealed and _prompt_reveal_elapsed >= PROMPT_REVEAL_SECONDS:
			_prompt_is_revealed = true
			changed = true
			_pulse_zone_feedback(_focused_zone_id)
	if changed:
		_apply_view_model()


func _should_show_prompt_panel() -> bool:
	return _active_popup_id.is_empty() and not _focused_zone_id.is_empty() and _prompt_is_revealed


func _compact_panel_inventory(summary: String) -> String:
	var source := summary.strip_edges()
	if source.is_empty():
		return _t("meta.common.none")
	var parts := source.split(", ", false)
	var preview_parts: Array[String] = []
	var preview_count := mini(INFO_PANEL_PREVIEW_ITEMS, parts.size())
	for part_index in range(preview_count):
		preview_parts.append(_trim_info_panel_entry(String(parts[part_index]).strip_edges()))
	var preview := " · ".join(preview_parts)
	if parts.size() <= preview_count:
		return preview
	return "%s\n%s" % [
		preview,
		_t("meta.shop.inventory_more", {"value": parts.size() - preview_count})
	]


func _trim_info_panel_entry(entry: String) -> String:
	var text := entry.strip_edges()
	if text.length() <= INFO_PANEL_ENTRY_MAX_LENGTH:
		return text
	return "%s..." % text.substr(0, maxi(0, INFO_PANEL_ENTRY_MAX_LENGTH - 3)).strip_edges()


func _compact_panel_line(text: String, max_length: int) -> String:
	var compact := text.replace("\n", "  |  ").strip_edges()
	if compact.length() <= max_length:
		return compact
	return "%s..." % compact.substr(0, maxi(0, max_length - 3)).strip_edges()


func _build_panel_tooltip(summary: String, tooltip: String) -> String:
	var parts: Array[String] = []
	var summary_text := summary.strip_edges()
	var tooltip_text := tooltip.strip_edges()
	if not summary_text.is_empty():
		parts.append(summary_text)
	if not tooltip_text.is_empty():
		parts.append(tooltip_text)
	return "\n\n".join(parts)


func _rebuild_seed_buttons() -> void:
	_rebuild_action_list(seed_list, _view_model.get("seed_offers", []), _on_seed_button_pressed)


func _rebuild_sell_buttons() -> void:
	_rebuild_action_list(sell_list, _view_model.get("sell_offers", []), _on_sell_button_pressed)


func _rebuild_upgrade_buttons() -> void:
	_rebuild_action_list(upgrade_list, _view_model.get("upgrade_offers", []), _on_upgrade_button_pressed)


func _rebuild_action_list(container: VBoxContainer, items_variant: Variant, handler: Callable) -> void:
	for child in container.get_children():
		child.free()
	var items: Array = items_variant if items_variant is Array else []
	if items.is_empty():
		var empty_label := Label.new()
		empty_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		empty_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		empty_label.theme_type_variation = &"BodyMutedLabel"
		empty_label.text = _t("meta.shop.empty")
		container.add_child(empty_label)
		return
	for item_variant in items:
		if not (item_variant is Dictionary):
			continue
		var item: Dictionary = item_variant
		var button := Button.new()
		button.custom_minimum_size = Vector2(0.0, 96.0)
		button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.disabled = not bool(item.get("enabled", false))
		button.theme_type_variation = &"SecondaryButton"
		button.text = String(item.get("label", ""))
		button.tooltip_text = String(item.get("tooltip", ""))
		button.mouse_entered.connect(func() -> void:
			UISfx.play_hover()
		)
		button.pressed.connect(handler.bind(String(item.get("id", ""))))
		container.add_child(button)


func _sync_scroll_content_widths() -> void:
	_sync_scroll_content_width(seed_scroll, seed_list)
	_sync_scroll_content_width(sell_scroll, sell_list)
	_sync_scroll_content_width(upgrade_scroll, upgrade_list)
	_sync_customer_request_width()


func _sync_customer_request_width() -> void:
	if request_scroll == null or request_body_box == null:
		return
	_sync_scroll_content_width(request_scroll, request_body_box)


func _sync_scroll_content_width(scroll: ScrollContainer, container: VBoxContainer) -> void:
	var target_width := maxf(0.0, scroll.size.x - 8.0)
	container.custom_minimum_size = Vector2(target_width, container.custom_minimum_size.y)
	for child in container.get_children():
		if child is Control:
			var child_control := child as Control
			child_control.custom_minimum_size = Vector2(target_width, child_control.custom_minimum_size.y)


func _build_prompt_text() -> String:
	if not _active_popup_id.is_empty():
		return _t("meta.shop.world_prompt_popup")
	if _focused_zone_id.is_empty():
		return _t("meta.shop.world_prompt_idle")
	match _focused_zone_id:
		"shopkeeper":
			return "%s\n%s" % [
				_t("meta.shop.world_prompt_interact", {"value": _zone_name(_focused_zone_id)}),
				String(_view_model.get("shopkeeper_line", ""))
			]
		"regular":
			return "%s\n%s" % [
				_t("meta.shop.world_prompt_interact", {"value": _zone_name(_focused_zone_id)}),
				String(_view_model.get("customer_line", ""))
			]
		"door":
			return "%s\n%s" % [
				_t("meta.shop.world_prompt_interact", {"value": _zone_name(_focused_zone_id)}),
				_t("meta.shop.leave")
			]
	return _t("meta.shop.world_prompt_idle")


func _compact_prompt_text(text: String) -> String:
	var source := text.strip_edges()
	if source.is_empty():
		return ""
	var compact_lines: Array[String] = []
	for line_variant in source.split("\n", false):
		var line := String(line_variant).strip_edges()
		if line.is_empty():
			continue
		compact_lines.append(_compact_panel_line(line, PROMPT_LINE_MAX_LENGTH))
		if compact_lines.size() >= PROMPT_MAX_LINES:
			break
	return "\n".join(compact_lines)


func _refresh_zone_visuals() -> void:
	for zone_id_variant in _zones.keys():
		var zone_id := String(zone_id_variant)
		_apply_zone_visual(zone_id, _zones.get(zone_id, {}) as Dictionary, zone_id == _focused_zone_id)


func _apply_zone_visual(zone_id: String, zone: Dictionary, focused: bool) -> void:
	var marker := zone.get("marker", null) as Polygon2D
	var pulse := zone.get("pulse", null) as Polygon2D
	var accent_variant: Variant = zone.get("accent", Color.WHITE)
	var accent: Color = accent_variant if accent_variant is Color else Color.WHITE
	if zone_id == "regular" and not String(_view_model.get("request_title", "")).strip_edges().is_empty():
		accent = Color(0.58, 0.86, 0.70, 1.0)
	if marker != null:
		marker.scale = Vector2.ONE * (1.14 if focused else 0.92)
		marker.color = Color(accent.r, accent.g, accent.b, 0.92 if focused else 0.08)
	if pulse != null:
		pulse.scale = Vector2.ONE * (1.24 if focused else 1.0)
		pulse.color = Color(accent.r, accent.g, accent.b, 0.22 if focused else 0.04)


func _activate_zone(zone_id: String) -> bool:
	match zone_id:
		"shopkeeper":
			_pulse_zone_feedback(zone_id)
			_open_popup("merchant")
			return true
		"regular":
			_pulse_zone_feedback(zone_id)
			_open_popup("customer")
			return true
		"door":
			_pulse_zone_feedback(zone_id)
			UISfx.play_click()
			back_requested.emit()
			return true
	return false


func _open_popup(popup_id: String) -> void:
	if not _popup_panels.has(popup_id) or _active_popup_id == popup_id:
		return
	_active_popup_id = popup_id
	_update_popup_visibility()
	_sync_visibility_state()
	_apply_view_model()
	UISfx.play_click()
	_animate_popup_open(_popup_panels.get(popup_id, null) as Panel)


func _close_popups() -> void:
	if _active_popup_id.is_empty():
		return
	UISfx.play_click()
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
	if hud_layer != null:
		hud_layer.visible = ui_visible
	if shop_player != null:
		shop_player.set_camera_active(ui_visible)
		shop_player.set_controls_enabled(ui_visible and _active_popup_id.is_empty())
	_schedule_focus_refresh()


func _schedule_focus_refresh() -> void:
	if shop_player != null and shop_player.has_method("refresh_interaction_focus"):
		shop_player.call_deferred("refresh_interaction_focus")


func _emit_offer_action(active_popup: String, items_variant: Variant, target_id: String, signal_value: Signal) -> bool:
	if _active_popup_id != active_popup:
		return false
	var normalized_id := target_id.strip_edges().to_lower()
	if normalized_id.is_empty() or not (items_variant is Array):
		return false
	for item_variant in items_variant:
		if not (item_variant is Dictionary):
			continue
		var item := item_variant as Dictionary
		if String(item.get("id", "")).strip_edges().to_lower() != normalized_id:
			continue
		if not bool(item.get("enabled", false)):
			return false
		signal_value.emit(normalized_id)
		return true
	return false


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
	_prompt_reveal_elapsed = 0.0
	_prompt_is_revealed = false
	_apply_view_model()


func _on_player_interaction_requested(zone_id: String) -> void:
	_activate_zone(zone_id)


func _on_seed_button_pressed(seed_id: String) -> void:
	var normalized_id := seed_id.strip_edges().to_lower()
	if normalized_id.is_empty():
		return
	UISfx.play_confirm()
	seed_purchase_requested.emit(normalized_id)


func _on_sell_button_pressed(material_id: String) -> void:
	var normalized_id := material_id.strip_edges().to_lower()
	if normalized_id.is_empty():
		return
	UISfx.play_confirm()
	sell_requested.emit(normalized_id)


func _on_upgrade_button_pressed(upgrade_id: String) -> void:
	var normalized_id := upgrade_id.strip_edges().to_lower()
	if normalized_id.is_empty():
		return
	UISfx.play_confirm()
	upgrade_purchase_requested.emit(normalized_id)


func _on_language_changed(_language_code: String) -> void:
	_apply_view_model()


func _on_visibility_changed() -> void:
	if visible and not _was_visible and shop_player != null:
		shop_player.reset_to_position(spawn_point.global_position)
	if not visible and not _active_popup_id.is_empty():
		_active_popup_id = ""
	if not visible:
		_prompt_reveal_elapsed = 0.0
		_prompt_is_revealed = false
	_update_popup_visibility()
	_sync_visibility_state()
	_apply_view_model()
	_was_visible = visible


func _t(key: String, args: Dictionary = {}) -> String:
	if Localization == null or not Localization.has_method("t"):
		return key
	return String(Localization.call("t", key, args))


func _bind_button_feedback(button: Button, confirm: bool) -> void:
	if button == null:
		return
	button.mouse_entered.connect(func() -> void:
		UISfx.play_hover()
	)
	button.pressed.connect(func() -> void:
		if confirm:
			UISfx.play_confirm()
		else:
			UISfx.play_click()
	)


func _apply_micro_feedback(
	status_text: String,
	prompt_signature: String,
	previous_status_text: String,
	previous_prompt_signature: String
) -> void:
	if not _feedback_ready:
		_feedback_ready = true
		return
	if not visible or not is_visible_in_tree():
		return
	if prompt_panel.visible and prompt_signature != previous_prompt_signature:
		_pulse_control(prompt_panel, 0.08, 0.988, 0.18)
		UISfx.play_hover()
	if status_panel.visible and status_text != previous_status_text and not status_text.is_empty():
		_pulse_control(status_panel, 0.08, 0.992, 0.18)


func _pulse_control(control: Control, alpha_boost: float, start_scale: float, duration: float) -> void:
	if control == null:
		return
	var tween_key := str(control.get_instance_id())
	var tween_variant: Variant = _control_tweens.get(tween_key, null)
	if tween_variant is Tween:
		var existing_tween := tween_variant as Tween
		if is_instance_valid(existing_tween):
			existing_tween.kill()
	control.pivot_offset = control.size * 0.5
	var target_modulate := control.modulate
	control.scale = Vector2.ONE * start_scale
	control.modulate = Color(
		target_modulate.r,
		target_modulate.g,
		target_modulate.b,
		clampf(target_modulate.a + alpha_boost, 0.0, 1.0)
	)
	var tween := create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.parallel().tween_property(control, "scale", Vector2.ONE, duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(control, "modulate", target_modulate, duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_control_tweens[tween_key] = tween


func _pulse_zone_feedback(zone_id: String) -> void:
	var zone: Dictionary = _zones.get(zone_id, {}) as Dictionary
	if zone.is_empty():
		return
	var marker := zone.get("marker", null) as Polygon2D
	var pulse := zone.get("pulse", null) as Polygon2D
	if marker != null:
		var marker_base_scale := marker.scale
		var marker_base_color := marker.color
		marker.scale = marker_base_scale * 1.03
		marker.color = Color(marker_base_color.r, marker_base_color.g, marker_base_color.b, clampf(marker_base_color.a + 0.10, 0.0, 1.0))
		var marker_tween := create_tween()
		marker_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		marker_tween.parallel().tween_property(marker, "scale", marker_base_scale, 0.18).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		marker_tween.parallel().tween_property(marker, "color", marker_base_color, 0.18).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	if pulse != null:
		var pulse_base_scale := pulse.scale
		var pulse_base_color := pulse.color
		pulse.scale = pulse_base_scale * 1.06
		pulse.color = Color(pulse_base_color.r, pulse_base_color.g, pulse_base_color.b, clampf(pulse_base_color.a + 0.12, 0.0, 1.0))
		var pulse_tween := create_tween()
		pulse_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		pulse_tween.parallel().tween_property(pulse, "scale", pulse_base_scale * 1.24, 0.20).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		pulse_tween.parallel().tween_property(pulse, "color", pulse_base_color, 0.24).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


func _animate_popup_open(popup: Panel) -> void:
	if popup == null:
		return
	popup.pivot_offset = popup.size * 0.5
	popup.scale = Vector2(0.988, 0.988)
	popup.modulate = Color(1.0, 1.0, 1.0, 0.0)
	if popup_shade != null:
		popup_shade.modulate = Color(1.0, 1.0, 1.0, 0.0)
	var tween := create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.parallel().tween_property(popup, "scale", Vector2.ONE, 0.20).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(popup, "modulate:a", 1.0, 0.18).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	if popup_shade != null:
		tween.parallel().tween_property(popup_shade, "modulate:a", 1.0, 0.16).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
