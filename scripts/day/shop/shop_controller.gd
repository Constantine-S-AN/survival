extends Control
class_name ShopController

signal back_requested
signal seed_purchase_requested(seed_id: String)
signal sell_requested(material_id: String)
signal upgrade_purchase_requested(upgrade_id: String)

@onready var title_label: Label = $ContentPanel/Margin/VBox/Title
@onready var subtitle_label: Label = $ContentPanel/Margin/VBox/Subtitle
@onready var stats_label: Label = $ContentPanel/Margin/VBox/StatsLabel
@onready var inventory_label: Label = $ContentPanel/Margin/VBox/InventoryLabel
@onready var owned_upgrades_label: Label = $ContentPanel/Margin/VBox/OwnedUpgradesLabel
@onready var status_label: Label = $ContentPanel/Margin/VBox/StatusLabel
@onready var seed_title_label: Label = $ContentPanel/Margin/VBox/Panels/SeedPanel/Margin/VBox/Title
@onready var seed_hint_label: Label = $ContentPanel/Margin/VBox/Panels/SeedPanel/Margin/VBox/Hint
@onready var seed_list: VBoxContainer = $ContentPanel/Margin/VBox/Panels/SeedPanel/Margin/VBox/Scroll/List
@onready var sell_title_label: Label = $ContentPanel/Margin/VBox/Panels/SellPanel/Margin/VBox/Title
@onready var sell_hint_label: Label = $ContentPanel/Margin/VBox/Panels/SellPanel/Margin/VBox/Hint
@onready var sell_list: VBoxContainer = $ContentPanel/Margin/VBox/Panels/SellPanel/Margin/VBox/Scroll/List
@onready var upgrade_title_label: Label = $ContentPanel/Margin/VBox/Panels/UpgradePanel/Margin/VBox/Title
@onready var upgrade_hint_label: Label = $ContentPanel/Margin/VBox/Panels/UpgradePanel/Margin/VBox/Hint
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
	_apply_view_model()


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
		button.disabled = not bool(item.get("enabled", false))
		button.text = String(item.get("label", ""))
		button.tooltip_text = String(item.get("tooltip", ""))
		button.pressed.connect(handler.bind(String(item.get("id", ""))))
		container.add_child(button)


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


func _t(key: String, args: Dictionary = {}) -> String:
	if Localization == null or not Localization.has_method("t"):
		return key
	return String(Localization.call("t", key, args))
