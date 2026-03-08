extends Control
class_name ShopController

signal back_requested
signal seed_purchase_requested(seed_id: String)
signal sell_requested(material_id: String)
signal upgrade_purchase_requested(upgrade_id: String)

@onready var content_vbox: VBoxContainer = $ContentPanel/Margin/VBox
@onready var title_label: Label = $ContentPanel/Margin/VBox/Title
@onready var subtitle_label: Label = $ContentPanel/Margin/VBox/Subtitle
@onready var stats_label: Label = $ContentPanel/Margin/VBox/StatsLabel
@onready var inventory_label: Label = $ContentPanel/Margin/VBox/InventoryLabel
@onready var owned_upgrades_label: Label = $ContentPanel/Margin/VBox/OwnedUpgradesLabel
@onready var status_label: Label = $ContentPanel/Margin/VBox/StatusLabel
@onready var panels_row: HBoxContainer = $ContentPanel/Margin/VBox/Panels
@onready var seed_title_label: Label = $ContentPanel/Margin/VBox/Panels/SeedPanel/Margin/VBox/Title
@onready var seed_hint_label: Label = $ContentPanel/Margin/VBox/Panels/SeedPanel/Margin/VBox/Hint
@onready var seed_scroll: ScrollContainer = $ContentPanel/Margin/VBox/Panels/SeedPanel/Margin/VBox/Scroll
@onready var seed_list: VBoxContainer = $ContentPanel/Margin/VBox/Panels/SeedPanel/Margin/VBox/Scroll/List
@onready var sell_title_label: Label = $ContentPanel/Margin/VBox/Panels/SellPanel/Margin/VBox/Title
@onready var sell_hint_label: Label = $ContentPanel/Margin/VBox/Panels/SellPanel/Margin/VBox/Hint
@onready var sell_scroll: ScrollContainer = $ContentPanel/Margin/VBox/Panels/SellPanel/Margin/VBox/Scroll
@onready var sell_list: VBoxContainer = $ContentPanel/Margin/VBox/Panels/SellPanel/Margin/VBox/Scroll/List
@onready var upgrade_title_label: Label = $ContentPanel/Margin/VBox/Panels/UpgradePanel/Margin/VBox/Title
@onready var upgrade_hint_label: Label = $ContentPanel/Margin/VBox/Panels/UpgradePanel/Margin/VBox/Hint
@onready var upgrade_scroll: ScrollContainer = $ContentPanel/Margin/VBox/Panels/UpgradePanel/Margin/VBox/Scroll
@onready var upgrade_list: VBoxContainer = $ContentPanel/Margin/VBox/Panels/UpgradePanel/Margin/VBox/Scroll/List
@onready var back_button: Button = $ContentPanel/Margin/VBox/BackButton

var _view_model: Dictionary = {}


func _ready() -> void:
	visible = false
	back_button.pressed.connect(func() -> void:
		back_requested.emit()
	)
	if Localization != null and Localization.has_signal("language_changed"):
		Localization.language_changed.connect(_on_language_changed)
	resized.connect(_sync_layout)
	content_vbox.resized.connect(_sync_layout)
	seed_scroll.resized.connect(_sync_scroll_content_widths)
	sell_scroll.resized.connect(_sync_scroll_content_widths)
	upgrade_scroll.resized.connect(_sync_scroll_content_widths)
	_apply_view_model()
	_sync_layout.call_deferred()
	_sync_scroll_content_widths.call_deferred()


func set_view_model(model: Dictionary) -> void:
	_view_model = model.duplicate(true)
	_apply_view_model()


func _apply_view_model() -> void:
	title_label.text = _t("meta.shop.title")
	subtitle_label.text = _t("meta.shop.subtitle")
	stats_label.text = _t("meta.shop.stats", {
		"day": int(_view_model.get("current_day", 1)),
		"phase": _t("meta.phase.%s" % String(_view_model.get("phase", "morning"))),
		"gold": int(_view_model.get("gold", 0)),
		"actions": int(_view_model.get("action_budget", 0)),
		"action_max": int(_view_model.get("max_action_budget", 0))
	})
	inventory_label.text = _t("meta.shop.inventory", {"value": String(_view_model.get("inventory_summary", _t("meta.common.none")))})
	inventory_label.tooltip_text = String(_view_model.get("inventory_tooltip", ""))
	owned_upgrades_label.text = _t("meta.shop.owned_upgrades", {
		"value": String(_view_model.get("owned_upgrades_summary", _t("meta.shop.owned_none")))
	})
	status_label.text = String(_view_model.get("status_text", ""))
	seed_title_label.text = _t("meta.shop.seed_title")
	seed_hint_label.text = _t("meta.shop.seed_hint")
	sell_title_label.text = _t("meta.shop.sell_title")
	sell_hint_label.text = _t("meta.shop.sell_hint")
	upgrade_title_label.text = _t("meta.shop.upgrade_title")
	upgrade_hint_label.text = _t("meta.shop.upgrade_hint")
	back_button.text = _t("meta.common.back")
	_rebuild_seed_buttons()
	_rebuild_sell_buttons()
	_rebuild_upgrade_buttons()
	_sync_layout.call_deferred()
	_sync_scroll_content_widths.call_deferred()


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
		empty_label.text = _t("meta.shop.empty")
		container.add_child(empty_label)
		return
	for item_variant in items:
		if not (item_variant is Dictionary):
			continue
		var item: Dictionary = item_variant
		var button := Button.new()
		button.custom_minimum_size = Vector2(0.0, 112.0)
		button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.disabled = not bool(item.get("enabled", false))
		button.theme_type_variation = &"SecondaryButton"
		button.text = String(item.get("label", ""))
		button.tooltip_text = String(item.get("tooltip", ""))
		button.pressed.connect(handler.bind(String(item.get("id", ""))))
		container.add_child(button)
	_sync_scroll_content_widths.call_deferred()


func _on_seed_button_pressed(seed_id: String) -> void:
	var normalized_id := seed_id.strip_edges().to_lower()
	if normalized_id.is_empty():
		return
	seed_purchase_requested.emit(normalized_id)


func _on_sell_button_pressed(material_id: String) -> void:
	var normalized_id := material_id.strip_edges().to_lower()
	if normalized_id.is_empty():
		return
	sell_requested.emit(normalized_id)


func _on_upgrade_button_pressed(upgrade_id: String) -> void:
	var normalized_id := upgrade_id.strip_edges().to_lower()
	if normalized_id.is_empty():
		return
	upgrade_purchase_requested.emit(normalized_id)


func _on_language_changed(_language_code: String) -> void:
	_apply_view_model()


func _sync_scroll_content_widths() -> void:
	_sync_scroll_content_width(seed_scroll, seed_list)
	_sync_scroll_content_width(sell_scroll, sell_list)
	_sync_scroll_content_width(upgrade_scroll, upgrade_list)


func _sync_layout() -> void:
	var content_width := maxf(0.0, content_vbox.size.x)
	if content_width <= 0.0:
		return
	panels_row.custom_minimum_size = Vector2(content_width, maxf(420.0, panels_row.custom_minimum_size.y))
	back_button.custom_minimum_size = Vector2(content_width, maxf(56.0, back_button.custom_minimum_size.y))
	seed_scroll.custom_minimum_size = Vector2(maxf(0.0, (panels_row.size.x / 3.0) - 28.0), maxf(260.0, seed_scroll.custom_minimum_size.y))
	sell_scroll.custom_minimum_size = Vector2(maxf(0.0, (panels_row.size.x / 3.0) - 28.0), maxf(260.0, sell_scroll.custom_minimum_size.y))
	upgrade_scroll.custom_minimum_size = Vector2(maxf(0.0, (panels_row.size.x / 3.0) - 28.0), maxf(260.0, upgrade_scroll.custom_minimum_size.y))
	_sync_scroll_content_widths()


func _sync_scroll_content_width(scroll: ScrollContainer, container: VBoxContainer) -> void:
	var target_width := maxf(0.0, scroll.size.x - 8.0)
	container.custom_minimum_size = Vector2(target_width, container.custom_minimum_size.y)
	for child in container.get_children():
		if child is Control:
			var child_control := child as Control
			child_control.custom_minimum_size = Vector2(target_width, child_control.custom_minimum_size.y)
			var target_height := child_control.custom_minimum_size.y
			if target_height <= 0.0:
				target_height = child_control.get_combined_minimum_size().y
			child_control.size = Vector2(target_width, target_height)


func _t(key: String, args: Dictionary = {}) -> String:
	if Localization == null or not Localization.has_method("t"):
		return key
	return String(Localization.call("t", key, args))
