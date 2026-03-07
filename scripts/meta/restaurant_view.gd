extends Control
class_name RestaurantView

signal back_requested
signal recipe_requested(recipe_id: String)

@onready var title_label: Label = $ContentPanel/Margin/VBox/Title
@onready var subtitle_label: Label = $ContentPanel/Margin/VBox/Subtitle
@onready var stats_label: Label = $ContentPanel/Margin/VBox/StatsLabel
@onready var inventory_label: Label = $ContentPanel/Margin/VBox/InventoryLabel
@onready var status_label: Label = $ContentPanel/Margin/VBox/StatusLabel
@onready var action_button_1: Button = $ContentPanel/Margin/VBox/Actions/ActionButton1
@onready var action_button_2: Button = $ContentPanel/Margin/VBox/Actions/ActionButton2
@onready var back_button: Button = $ContentPanel/Margin/VBox/BackButton

var _view_model: Dictionary = {}
var _recipe_ids: Array[String] = []


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
	title_label.text = _t("meta.restaurant.title")
	subtitle_label.text = _t("meta.restaurant.subtitle")
	stats_label.text = _t("meta.restaurant.stats", {
		"day": int(_view_model.get("current_day", 1)),
		"stamina": int(_view_model.get("stamina", 0)),
		"max": int(_view_model.get("max_stamina", 0))
	})
	inventory_label.text = _t("meta.restaurant.inventory", {"value": String(_view_model.get("inventory_summary", "-"))})
	status_label.text = String(_view_model.get("status_text", ""))
	back_button.text = _t("meta.common.back")
	var recipes_variant: Variant = _view_model.get("recipes", [])
	var recipes: Array = recipes_variant if recipes_variant is Array else []
	_recipe_ids.clear()
	_apply_recipe_button(action_button_1, recipes, 0)
	_apply_recipe_button(action_button_2, recipes, 1)


func _apply_recipe_button(button: Button, recipes: Array, index: int) -> void:
	if index < 0 or index >= recipes.size():
		button.visible = false
		button.disabled = true
		_recipe_ids.append("")
		return
	var recipe_variant: Variant = recipes[index]
	if not (recipe_variant is Dictionary):
		button.visible = false
		button.disabled = true
		_recipe_ids.append("")
		return
	var recipe: Dictionary = recipe_variant
	button.visible = true
	button.disabled = not bool(recipe.get("enabled", false))
	button.text = String(recipe.get("label", ""))
	_recipe_ids.append(String(recipe.get("id", "")))


func _on_action_button_pressed(index: int) -> void:
	if index < 0 or index >= _recipe_ids.size():
		return
	var recipe_id := String(_recipe_ids[index]).strip_edges()
	if recipe_id.is_empty():
		return
	recipe_requested.emit(recipe_id)


func _on_language_changed(_language_code: String) -> void:
	_apply_view_model()


func _t(key: String, args: Dictionary = {}) -> String:
	if Localization == null or not Localization.has_method("t"):
		return key
	return String(Localization.call("t", key, args))
