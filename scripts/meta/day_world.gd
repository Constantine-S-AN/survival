extends Node2D
class_name DayWorldView

signal farm_requested
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

@onready var backdrop: Node2D = $Backdrop
@onready var environment: Node2D = $Environment
@onready var zones_root: Node2D = $Zones
@onready var spawn_point: Marker2D = $SpawnPoint
@onready var day_player: DayPlayerController = $DayPlayer
@onready var hud: DayHud = $HUDLayer/DayHud
@onready var daily_orders_board: DailyOrdersBoardView = $HUDLayer/DailyOrdersBoard

var _view_model: Dictionary = {}
var _zones: Dictionary = {}
var _focused_zone_id: String = ""
var _world_built: bool = false


func _ready() -> void:
	visible = false
	_build_world_if_needed()
	_register_zones()
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


func set_view_model(model: Dictionary) -> void:
	_view_model = model.duplicate(true)
	_apply_view_model()


func debug_activate_zone(zone_id: String) -> bool:
	return _activate_zone(zone_id.strip_edges().to_lower())


func debug_get_snapshot() -> Dictionary:
	return {
		"focused_zone_id": _focused_zone_id,
		"prompt_text": _build_prompt_text(),
		"orders_open": daily_orders_board.visible if daily_orders_board != null else false,
		"player_position": day_player.global_position if day_player != null else Vector2.ZERO
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

	_create_zone("farm", "meta.world.area_farm", Vector2(292.0, 620.0), Vector2(240.0, 150.0), Color(0.49, 0.90, 0.56, 1.0))
	_create_zone("restaurant", "meta.world.area_restaurant", Vector2(944.0, 310.0), Vector2(250.0, 124.0), Color(0.98, 0.66, 0.38, 1.0))
	_create_zone("shop", "meta.world.area_shop", Vector2(1306.0, 426.0), Vector2(214.0, 124.0), Color(0.54, 0.84, 1.0, 1.0))
	_create_zone("orders", "meta.world.area_orders", Vector2(1198.0, 608.0), Vector2(176.0, 116.0), Color(0.95, 0.81, 0.36, 1.0))
	_create_zone("wait", "meta.world.area_wait", Vector2(622.0, 744.0), Vector2(192.0, 110.0), Color(0.72, 0.68, 0.92, 1.0))
	_create_zone("night", "meta.world.area_night", Vector2(1188.0, 806.0), Vector2(232.0, 112.0), Color(0.98, 0.50, 0.54, 1.0))


func _register_zones() -> void:
	_zones.clear()
	for zone_root in zones_root.get_children():
		if not (zone_root is Node2D):
			continue
		var area := zone_root.get_node_or_null("Area2D") as Area2D
		var marker := zone_root.get_node_or_null("Marker") as Polygon2D
		var pulse := zone_root.get_node_or_null("Pulse") as Polygon2D
		if area == null:
			continue
		var zone_id := area.name.trim_suffix("Zone").to_lower()
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
	area.add_to_group("day_interaction_zone")
	zone_root.add_child(area)

	var shape := CollisionShape2D.new()
	var rectangle := RectangleShape2D.new()
	rectangle.size = size
	shape.shape = rectangle
	area.add_child(shape)


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
		"ready_orders": ready_to_claim
	})
	_refresh_zone_visuals()


func _build_prompt_text() -> String:
	if daily_orders_board != null and daily_orders_board.visible:
		return _t("meta.world.prompt_orders_open")
	if _focused_zone_id.is_empty():
		return _t("meta.world.prompt_idle")
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
	for zone_id in _zones.keys():
		var zone: Dictionary = _zones.get(zone_id, {}) as Dictionary
		var marker := zone.get("marker", null) as Polygon2D
		var pulse := zone.get("pulse", null) as Polygon2D
		var accent_variant: Variant = zone.get("accent", Color.WHITE)
		var accent: Color = accent_variant if accent_variant is Color else Color.WHITE
		var enabled := _is_zone_enabled(String(zone_id))
		var focused := String(zone_id) == _focused_zone_id
		if marker != null:
			marker.scale = Vector2.ONE * (1.22 if focused else 1.0)
			marker.color = Color(accent.r, accent.g, accent.b, 0.94 if enabled else 0.28)
		if pulse != null:
			pulse.scale = Vector2.ONE * (1.34 if focused else 1.0)
			pulse.color = Color(accent.r, accent.g, accent.b, 0.24 if enabled else 0.10)


func _is_zone_enabled(zone_id: String) -> bool:
	match zone_id:
		"wait":
			return not bool(_view_model.get("wait_button_disabled", false))
		"night":
			return not bool(_view_model.get("night_button_disabled", false))
	return true


func _get_zone_name(zone_id: String) -> String:
	var zone: Dictionary = _zones.get(zone_id, {}) as Dictionary
	var label_key := String(zone.get("label_key", ""))
	return _t(label_key) if not label_key.is_empty() else zone_id.capitalize()


func _get_zone_tooltip(zone_id: String) -> String:
	match zone_id:
		"farm":
			return String(_view_model.get("farm_button_tooltip", ""))
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
	if not _is_zone_enabled(zone_id):
		_apply_view_model()
		return false
	match zone_id:
		"farm":
			farm_requested.emit()
			return true
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
