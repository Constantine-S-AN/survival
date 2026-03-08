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

const HOUSE_TEXTURE := preload("res://assets/textures/pixel/maps/props/house_neon.png")
const RESTAURANT_TEXTURE := preload("res://assets/textures/pixel/maps/props/barracks_neon.png")
const SHOP_TEXTURE := preload("res://assets/textures/pixel/maps/props/tower_neon.png")
const HEDGE_TEXTURE := preload("res://assets/textures/pixel/maps/props/terrain_hedge_strip.png")
const CRATE_TEXTURE := preload("res://assets/textures/pixel/maps/props/crate_metal.png")
const BARRIER_TEXTURE := preload("res://assets/textures/pixel/maps/props/barrier_segment.png")

const WORLD_BOUNDS := Rect2(Vector2(40.0, 60.0), Vector2(1520.0, 820.0))
const FARM_PLOT_ORIGIN := Vector2(178.0, 572.0)
const FARM_PLOT_STEP := Vector2(114.0, 98.0)
const FARM_PLOT_SIZE := Vector2(92.0, 70.0)

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

	_add_rect(backdrop, "Sky", Rect2(0.0, 0.0, 1600.0, 980.0), Color(0.035, 0.066, 0.109, 1.0), -20)
	_add_rect(backdrop, "HarborGlow", Rect2(0.0, 0.0, 1600.0, 260.0), Color(0.082, 0.188, 0.231, 0.38), -19)
	_add_rect(environment, "Ground", Rect2(0.0, 110.0, 1600.0, 830.0), Color(0.084, 0.125, 0.109, 1.0), -8)
	_add_rect(environment, "CrossRoadEastWest", Rect2(154.0, 468.0, 1292.0, 84.0), Color(0.177, 0.209, 0.196, 1.0), -6)
	_add_rect(environment, "CrossRoadNorthSouth", Rect2(738.0, 182.0, 126.0, 620.0), Color(0.177, 0.209, 0.196, 1.0), -6)
	_add_rect(environment, "CentralPlaza", Rect2(622.0, 394.0, 360.0, 232.0), Color(0.239, 0.258, 0.243, 1.0), -5)
	_add_rect(environment, "FarmField", Rect2(92.0, 486.0, 372.0, 278.0), Color(0.149, 0.243, 0.145, 1.0), -7)
	_add_rect(environment, "FarmApron", Rect2(124.0, 524.0, 314.0, 214.0), Color(0.196, 0.282, 0.133, 1.0), -6)
	_add_rect(environment, "WaterFront", Rect2(1056.0, 654.0, 446.0, 182.0), Color(0.039, 0.156, 0.231, 1.0), -7)
	_add_rect(environment, "Dock", Rect2(1118.0, 690.0, 210.0, 88.0), Color(0.266, 0.203, 0.137, 1.0), -5)
	_add_rect(environment, "RestaurantPatio", Rect2(776.0, 178.0, 336.0, 138.0), Color(0.258, 0.188, 0.145, 1.0), -7)
	_add_rect(environment, "ShopPad", Rect2(1212.0, 284.0, 220.0, 150.0), Color(0.165, 0.180, 0.188, 1.0), -7)

	_add_sprite(environment, "RestaurantBuilding", RESTAURANT_TEXTURE, Vector2(950.0, 188.0), Vector2(2.6, 2.6), Color(1.00, 0.86, 0.78, 1.0), -1)
	_add_sprite(environment, "ShopBuilding", SHOP_TEXTURE, Vector2(1310.0, 272.0), Vector2(2.1, 2.1), Color(0.86, 0.96, 1.0, 1.0), -1)
	_add_sprite(environment, "FarmShed", HOUSE_TEXTURE, Vector2(270.0, 500.0), Vector2(2.1, 2.1), Color(0.82, 1.0, 0.82, 1.0), -1)
	_add_sprite(environment, "HarborOffice", HOUSE_TEXTURE, Vector2(1134.0, 646.0), Vector2(1.8, 1.8), Color(1.0, 0.84, 0.84, 1.0), -1)

	for i in range(4):
		_add_sprite(environment, "FarmFence%d" % i, HEDGE_TEXTURE, Vector2(156.0 + (i * 72.0), 450.0), Vector2(1.7, 1.4), Color(0.55, 0.84, 0.58, 1.0), -2)
	for i in range(3):
		_add_sprite(environment, "DockBarrier%d" % i, BARRIER_TEXTURE, Vector2(1122.0 + (i * 54.0), 760.0), Vector2(1.5, 1.5), Color(0.88, 0.66, 0.46, 1.0), -2)
	for i in range(2):
		_add_sprite(environment, "MarketCrate%d" % i, CRATE_TEXTURE, Vector2(1180.0 + (i * 48.0), 570.0), Vector2(1.35, 1.35), Color(0.84, 0.90, 1.0, 1.0), -2)
	for i in range(3):
		_add_rect(environment, "FarmRow%d" % i, Rect2(140.0 + (i * 104.0), 540.0, 74.0, 182.0), Color(0.247, 0.184, 0.109, 0.22), -5)

	_create_zone("restaurant", "meta.world.area_restaurant", Vector2(944.0, 310.0), Vector2(250.0, 124.0), Color(0.98, 0.66, 0.38, 1.0))
	_create_zone("shop", "meta.world.area_shop", Vector2(1306.0, 426.0), Vector2(214.0, 124.0), Color(0.54, 0.84, 1.0, 1.0))
	_create_zone("orders", "meta.world.area_orders", Vector2(1198.0, 608.0), Vector2(176.0, 116.0), Color(0.95, 0.81, 0.36, 1.0))
	_create_zone("wait", "meta.world.area_wait", Vector2(622.0, 744.0), Vector2(192.0, 110.0), Color(0.72, 0.68, 0.92, 1.0))
	_create_zone("night", "meta.world.area_night", Vector2(1188.0, 806.0), Vector2(232.0, 112.0), Color(0.98, 0.50, 0.54, 1.0))

	_farm_plots_root = Node2D.new()
	_farm_plots_root.name = "FarmPlots"
	_farm_plots_root.z_index = 6
	zones_root.add_child(_farm_plots_root)


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
	pulse.polygon = PackedVector2Array([
		Vector2(0.0, -42.0),
		Vector2(54.0, 0.0),
		Vector2(0.0, 42.0),
		Vector2(-54.0, 0.0)
	])
	pulse.color = Color(accent.r, accent.g, accent.b, 0.12)
	pulse.z_index = 2
	zone_root.add_child(pulse)

	var marker := Polygon2D.new()
	marker.name = "Marker"
	marker.polygon = PackedVector2Array([
		Vector2(0.0, -26.0),
		Vector2(32.0, 0.0),
		Vector2(0.0, 26.0),
		Vector2(-32.0, 0.0)
	])
	marker.color = Color(accent.r, accent.g, accent.b, 0.42)
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
	pulse.polygon = PackedVector2Array([
		Vector2(0.0, -48.0),
		Vector2(60.0, 0.0),
		Vector2(0.0, 48.0),
		Vector2(-60.0, 0.0)
	])
	pulse.color = Color(accent.r, accent.g, accent.b, 0.10)
	pulse.z_index = 1
	plot_root.add_child(pulse)

	var marker := Polygon2D.new()
	marker.name = "Marker"
	marker.polygon = PackedVector2Array([
		Vector2(0.0, -22.0),
		Vector2(24.0, 0.0),
		Vector2(0.0, 22.0),
		Vector2(-24.0, 0.0)
	])
	marker.position = Vector2(0.0, -56.0)
	marker.color = Color(accent.r, accent.g, accent.b, 0.26)
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
