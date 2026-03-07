extends Control
class_name FarmView

signal back_requested
signal action_requested(action_id: String)

@onready var title_label: Label = $ContentPanel/Margin/VBox/Title
@onready var subtitle_label: Label = $ContentPanel/Margin/VBox/Subtitle
@onready var stats_label: Label = $ContentPanel/Margin/VBox/StatsLabel
@onready var inventory_label: Label = $ContentPanel/Margin/VBox/InventoryLabel
@onready var status_label: Label = $ContentPanel/Margin/VBox/StatusLabel
@onready var action_button_1: Button = $ContentPanel/Margin/VBox/Actions/ActionButton1
@onready var action_button_2: Button = $ContentPanel/Margin/VBox/Actions/ActionButton2
@onready var back_button: Button = $ContentPanel/Margin/VBox/BackButton

var _view_model: Dictionary = {}
var _action_ids: Array[String] = []


func _ready() -> void:
	visible = false
	action_button_1.pressed.connect(_on_action_button_pressed.bind(0))
	action_button_2.pressed.connect(_on_action_button_pressed.bind(1))
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
	title_label.text = _t("meta.farm.title")
	subtitle_label.text = _t("meta.farm.subtitle")
	stats_label.text = _t("meta.farm.stats", {
		"day": int(_view_model.get("current_day", 1)),
		"stamina": int(_view_model.get("stamina", 0)),
		"max": int(_view_model.get("max_stamina", 0))
	})
	inventory_label.text = _t("meta.farm.inventory", {"value": String(_view_model.get("inventory_summary", "-"))})
	status_label.text = String(_view_model.get("status_text", ""))
	back_button.text = _t("meta.common.back")
	var actions_variant: Variant = _view_model.get("actions", [])
	var actions: Array = actions_variant if actions_variant is Array else []
	_action_ids.clear()
	_apply_action_button(action_button_1, actions, 0)
	_apply_action_button(action_button_2, actions, 1)


func _apply_action_button(button: Button, actions: Array, index: int) -> void:
	if index < 0 or index >= actions.size():
		button.visible = false
		button.disabled = true
		_action_ids.append("")
		return
	var action_variant: Variant = actions[index]
	if not (action_variant is Dictionary):
		button.visible = false
		button.disabled = true
		_action_ids.append("")
		return
	var action: Dictionary = action_variant
	button.visible = true
	button.disabled = not bool(action.get("enabled", false))
	button.text = String(action.get("label", ""))
	_action_ids.append(String(action.get("id", "")))


func _on_action_button_pressed(index: int) -> void:
	if index < 0 or index >= _action_ids.size():
		return
	var action_id := String(_action_ids[index]).strip_edges()
	if action_id.is_empty():
		return
	action_requested.emit(action_id)


func _on_language_changed(_language_code: String) -> void:
	_apply_view_model()


func _t(key: String, args: Dictionary = {}) -> String:
	if Localization == null or not Localization.has_method("t"):
		return key
	return String(Localization.call("t", key, args))
