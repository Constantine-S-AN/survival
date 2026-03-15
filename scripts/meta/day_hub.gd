extends Control
class_name DayHubView

signal farm_requested
signal restaurant_requested
signal shop_requested
signal wait_requested
signal night_requested
signal menu_requested
signal world_requested

@onready var title_label: Label = $ContentPanel/Margin/VBox/Title
@onready var subtitle_label: Label = $ContentPanel/Margin/VBox/Subtitle
@onready var guide_panel: Panel = $ContentPanel/Margin/VBox/GuidePanel
@onready var guide_title_label: Label = $ContentPanel/Margin/VBox/GuidePanel/Margin/VBox/GuideTitle
@onready var guide_body_label: Label = $ContentPanel/Margin/VBox/GuidePanel/Margin/VBox/GuideBody
@onready var day_label: Label = $ContentPanel/Margin/VBox/Stats/DayLabel
@onready var gold_label: Label = $ContentPanel/Margin/VBox/Stats/GoldLabel
@onready var reputation_label: Label = $ContentPanel/Margin/VBox/Stats/ReputationLabel
@onready var stamina_label: Label = $ContentPanel/Margin/VBox/Stats/StaminaLabel
@onready var action_budget_label: Label = $ContentPanel/Margin/VBox/Stats/ActionBudgetLabel
@onready var phase_label: Label = $ContentPanel/Margin/VBox/Stats/PhaseLabel
@onready var inventory_label: Label = $ContentPanel/Margin/VBox/InventoryLabel
@onready var seeds_label: Label = $ContentPanel/Margin/VBox/SeedsLabel
@onready var recipes_label: Label = $ContentPanel/Margin/VBox/RecipesLabel
@onready var bonus_label: Label = $ContentPanel/Margin/VBox/BonusLabel
@onready var bridge_label: Label = $ContentPanel/Margin/VBox/BridgeLabel
@onready var status_label: Label = $ContentPanel/Margin/VBox/StatusLabel
@onready var farm_button: Button = $ContentPanel/Margin/VBox/Actions/FarmButton
@onready var restaurant_button: Button = $ContentPanel/Margin/VBox/Actions/RestaurantButton
@onready var orders_button: Button = $ContentPanel/Margin/VBox/Actions/OrdersButton
@onready var shop_button: Button = $ContentPanel/Margin/VBox/Actions/ShopButton
@onready var wait_button: Button = $ContentPanel/Margin/VBox/Actions/WaitButton
@onready var night_button: Button = $ContentPanel/Margin/VBox/Actions/NightButton
@onready var world_button: Button = $ContentPanel/Margin/VBox/Actions/WorldButton
@onready var menu_button: Button = $ContentPanel/Margin/VBox/Actions/MenuButton
@onready var daily_orders_board: DailyOrdersBoardView = $DailyOrdersBoard

var _view_model: Dictionary = {}


func _ready() -> void:
	visible = false
	_apply_ui_font_overrides()
	farm_button.pressed.connect(func() -> void:
		farm_requested.emit()
	)
	restaurant_button.pressed.connect(func() -> void:
		restaurant_requested.emit()
	)
	orders_button.pressed.connect(_on_orders_button_pressed)
	shop_button.pressed.connect(func() -> void:
		shop_requested.emit()
	)
	wait_button.pressed.connect(func() -> void:
		wait_requested.emit()
	)
	night_button.pressed.connect(func() -> void:
		night_requested.emit()
	)
	world_button.pressed.connect(func() -> void:
		world_requested.emit()
	)
	menu_button.pressed.connect(func() -> void:
		menu_requested.emit()
	)
	if daily_orders_board != null:
		daily_orders_board.closed.connect(_on_daily_orders_board_closed)
	if Localization != null and Localization.has_signal("language_changed"):
		Localization.language_changed.connect(_on_language_changed)
	if DailyOrders != null and DailyOrders.has_signal("state_changed"):
		DailyOrders.state_changed.connect(_on_daily_orders_state_changed)
	if DailyOrders != null and DailyOrders.has_signal("reward_claimed"):
		DailyOrders.reward_claimed.connect(_on_daily_order_reward_claimed)
	_apply_view_model()


func _apply_ui_font_overrides() -> void:
	title_label.add_theme_font_size_override("font_size", 24)
	subtitle_label.add_theme_font_size_override("font_size", 14)
	guide_title_label.add_theme_font_size_override("font_size", 17)
	guide_body_label.add_theme_font_size_override("font_size", 13)
	for stat_label in [day_label, gold_label, reputation_label, stamina_label, action_budget_label, phase_label]:
		if stat_label == null:
			continue
		stat_label.add_theme_font_size_override("font_size", 14)
	for body_label in [inventory_label, seeds_label, recipes_label, bonus_label, bridge_label, status_label]:
		if body_label == null:
			continue
		body_label.add_theme_font_size_override("font_size", 13)
	for action_button in [farm_button, restaurant_button, orders_button, shop_button, wait_button, night_button, world_button, menu_button]:
		if action_button == null:
			continue
		action_button.add_theme_font_size_override("font_size", 14)


func set_view_model(model: Dictionary) -> void:
	_view_model = model.duplicate(true)
	_apply_view_model()


func _apply_view_model() -> void:
	title_label.text = _t("meta.hub.title")
	subtitle_label.text = _t("meta.hub.subtitle")
	farm_button.text = _t("meta.hub.farm")
	farm_button.tooltip_text = String(_view_model.get("farm_button_tooltip", ""))
	restaurant_button.text = _t("meta.hub.restaurant")
	restaurant_button.tooltip_text = String(_view_model.get("restaurant_button_tooltip", ""))
	var ready_to_claim := 0
	if DailyOrders != null and DailyOrders.has_method("get_ready_to_claim_count"):
		ready_to_claim = int(DailyOrders.call("get_ready_to_claim_count"))
	orders_button.text = _t("meta.hub.orders_ready", {"value": ready_to_claim}) if ready_to_claim > 0 else _t("meta.hub.orders")
	orders_button.tooltip_text = _t("meta.hub.orders_tooltip")
	shop_button.text = String(_view_model.get("shop_button_text", _t("meta.hub.shop")))
	shop_button.tooltip_text = String(_view_model.get("shop_button_tooltip", ""))
	night_button.text = _t("meta.hub.launch_night")
	world_button.text = _t("meta.hub.walkable_world")
	world_button.tooltip_text = _t("meta.hub.walkable_world_tooltip")
	menu_button.text = _t("meta.hub.menu")
	var guide_title := String(_view_model.get("guide_title", "")).strip_edges()
	var guide_text := String(_view_model.get("guide_text", "")).strip_edges()
	var guide_display_text := _compact_multiline_text(guide_text, 3, 40)
	guide_panel.visible = not guide_title.is_empty() or not guide_display_text.is_empty()
	guide_title_label.text = guide_title
	guide_title_label.visible = not guide_title.is_empty()
	guide_body_label.text = guide_display_text
	guide_body_label.visible = not guide_display_text.is_empty()
	guide_panel.tooltip_text = _build_tooltip_text(guide_text)
	guide_title_label.tooltip_text = guide_text
	guide_body_label.tooltip_text = guide_text
	day_label.text = _t("meta.hub.day", {"value": int(_view_model.get("current_day", 1))})
	gold_label.text = _t("meta.hub.gold", {"value": int(_view_model.get("gold", 0))})
	reputation_label.text = _t("meta.hub.reputation", {"value": int(_view_model.get("reputation", 1))})
	stamina_label.text = _t("meta.hub.stamina", {
		"current": int(_view_model.get("stamina", 0)),
		"max": int(_view_model.get("max_stamina", 0))
	})
	action_budget_label.text = _t("meta.hub.actions", {
		"current": int(_view_model.get("action_budget", 0)),
		"max": int(_view_model.get("max_action_budget", 0))
	})
	phase_label.text = _t("meta.hub.phase", {
		"value": _t("meta.phase.%s" % String(_view_model.get("phase", "morning")))
	})
	var inventory_summary := String(_view_model.get("inventory_summary", "-"))
	inventory_label.text = _t("meta.hub.inventory", {
		"value": _compact_csv_text(inventory_summary, 4, 54)
	})
	inventory_label.tooltip_text = _build_tooltip_text(
		inventory_summary,
		String(_view_model.get("inventory_tooltip", ""))
	)
	var seed_summary := String(_view_model.get("seed_summary", "-"))
	seeds_label.text = _t("meta.hub.seeds", {
		"value": _compact_csv_text(seed_summary, 4, 54)
	})
	seeds_label.tooltip_text = _build_tooltip_text(
		seed_summary,
		String(_view_model.get("seed_tooltip", ""))
	)
	var recipe_summary := String(_view_model.get("recipe_summary", "-"))
	recipes_label.text = _t("meta.hub.recipes", {
		"value": _compact_csv_text(recipe_summary, 3, 54)
	})
	recipes_label.tooltip_text = _build_tooltip_text(
		recipe_summary,
		String(_view_model.get("recipe_tooltip", ""))
	)
	var bonus_summary := String(_view_model.get("night_bonus_summary", _t("meta.common.none")))
	bonus_label.text = _t("meta.hub.night_bonus", {
		"value": _compact_multiline_text(bonus_summary, 2, 54)
	})
	bonus_label.tooltip_text = _build_tooltip_text(
		bonus_summary,
		String(_view_model.get("bonus_tooltip", ""))
	)
	var bridge_summary := String(_view_model.get("bridge_summary", _t("meta.bridge.summary_none")))
	bridge_label.text = _t("meta.hub.bridge", {
		"value": _compact_multiline_text(bridge_summary, 2, 54)
	})
	bridge_label.tooltip_text = _build_tooltip_text(
		bridge_summary,
		String(_view_model.get("bridge_tooltip", ""))
	)
	var status_text := String(_view_model.get("status_text", ""))
	status_label.text = _compact_multiline_text(status_text, 2, 58)
	status_label.tooltip_text = status_text
	wait_button.text = String(_view_model.get("wait_button_text", _t("meta.hub.wait_evening")))
	wait_button.tooltip_text = String(_view_model.get("wait_button_tooltip", ""))
	wait_button.disabled = bool(_view_model.get("wait_button_disabled", false))
	night_button.disabled = bool(_view_model.get("night_button_disabled", false))
	night_button.tooltip_text = String(_view_model.get("night_button_tooltip", ""))


func _on_language_changed(_language_code: String) -> void:
	_apply_view_model()


func _on_orders_button_pressed() -> void:
	if daily_orders_board == null:
		return
	if bool(daily_orders_board.visible):
		daily_orders_board.call("close_board")
	else:
		daily_orders_board.call("open_board")


func _on_daily_orders_board_closed() -> void:
	orders_button.grab_focus()


func _on_daily_orders_state_changed() -> void:
	_apply_view_model()


func _on_daily_order_reward_claimed(_order_id: int, _reward: Dictionary) -> void:
	var meta_progress: Dictionary = ProfileStore.get_meta_progress_state()
	var economy_variant: Variant = meta_progress.get("economy", {})
	var economy: Dictionary = economy_variant if economy_variant is Dictionary else {}
	_view_model["gold"] = int(economy.get("gold", _view_model.get("gold", 0)))
	_apply_view_model()


func _t(key: String, args: Dictionary = {}) -> String:
	if Localization == null or not Localization.has_method("t"):
		return key
	return String(Localization.call("t", key, args))


func _compact_csv_text(text: String, max_items: int, max_length: int) -> String:
	var source := text.strip_edges()
	if source.is_empty():
		return "-"
	var parts: Array[String] = []
	for part_variant in source.split(",", false):
		var part := String(part_variant).strip_edges()
		if part.is_empty():
			continue
		parts.append(part)
	if parts.is_empty():
		return _trim_panel_line(source, max_length)
	var visible_parts := parts.slice(0, mini(parts.size(), max_items))
	var compact_text := ", ".join(visible_parts)
	if parts.size() > max_items:
		compact_text += ", ..."
	return _trim_panel_line(compact_text, max_length)


func _compact_multiline_text(text: String, max_lines: int, max_length: int) -> String:
	var source := text.strip_edges()
	if source.is_empty():
		return ""
	var compact_lines: Array[String] = []
	for line_variant in source.split("\n", false):
		var line := String(line_variant).strip_edges()
		if line.is_empty():
			continue
		if line.begins_with("- "):
			line = "• %s" % line.substr(2).strip_edges()
		elif line.begins_with("-"):
			line = "• %s" % line.substr(1).strip_edges()
		compact_lines.append(_trim_panel_line(line, max_length))
		if compact_lines.size() >= max_lines:
			break
	if compact_lines.is_empty():
		return _trim_panel_line(source, max_length)
	if source.split("\n", false).size() > max_lines:
		compact_lines.append("...")
	return "\n".join(compact_lines)


func _trim_panel_line(text: String, max_length: int) -> String:
	if text.length() <= max_length:
		return text
	return "%s..." % text.substr(0, maxi(0, max_length - 3)).strip_edges()


func _build_tooltip_text(primary_text: String, secondary_text: String = "") -> String:
	var sections: Array[String] = []
	var primary := primary_text.strip_edges()
	if not primary.is_empty():
		sections.append(primary)
	var secondary := secondary_text.strip_edges()
	if not secondary.is_empty():
		sections.append(secondary)
	return "\n\n".join(sections)
