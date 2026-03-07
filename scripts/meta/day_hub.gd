extends Control
class_name DayHubView

signal farm_requested
signal restaurant_requested
signal night_requested
signal menu_requested

@onready var title_label: Label = $ContentPanel/Margin/VBox/Title
@onready var subtitle_label: Label = $ContentPanel/Margin/VBox/Subtitle
@onready var day_label: Label = $ContentPanel/Margin/VBox/Stats/DayLabel
@onready var gold_label: Label = $ContentPanel/Margin/VBox/Stats/GoldLabel
@onready var reputation_label: Label = $ContentPanel/Margin/VBox/Stats/ReputationLabel
@onready var stamina_label: Label = $ContentPanel/Margin/VBox/Stats/StaminaLabel
@onready var phase_label: Label = $ContentPanel/Margin/VBox/Stats/PhaseLabel
@onready var inventory_label: Label = $ContentPanel/Margin/VBox/InventoryLabel
@onready var seeds_label: Label = $ContentPanel/Margin/VBox/SeedsLabel
@onready var recipes_label: Label = $ContentPanel/Margin/VBox/RecipesLabel
@onready var bonus_label: Label = $ContentPanel/Margin/VBox/BonusLabel
@onready var farm_button: Button = $ContentPanel/Margin/VBox/Actions/FarmButton
@onready var restaurant_button: Button = $ContentPanel/Margin/VBox/Actions/RestaurantButton
@onready var night_button: Button = $ContentPanel/Margin/VBox/Actions/NightButton
@onready var menu_button: Button = $ContentPanel/Margin/VBox/Actions/MenuButton

var _view_model: Dictionary = {}


func _ready() -> void:
	visible = false
	farm_button.pressed.connect(func() -> void:
		farm_requested.emit()
	)
	restaurant_button.pressed.connect(func() -> void:
		restaurant_requested.emit()
	)
	night_button.pressed.connect(func() -> void:
		night_requested.emit()
	)
	menu_button.pressed.connect(func() -> void:
		menu_requested.emit()
	)
	if Localization != null and Localization.has_signal("language_changed"):
		Localization.language_changed.connect(_on_language_changed)
	_apply_view_model()


func set_view_model(model: Dictionary) -> void:
	_view_model = model.duplicate(true)
	_apply_view_model()


func _apply_view_model() -> void:
	title_label.text = _t("meta.hub.title")
	subtitle_label.text = _t("meta.hub.subtitle")
	farm_button.text = _t("meta.hub.farm")
	restaurant_button.text = _t("meta.hub.restaurant")
	night_button.text = _t("meta.hub.launch_night")
	menu_button.text = _t("meta.hub.menu")
	day_label.text = _t("meta.hub.day", {"value": int(_view_model.get("current_day", 1))})
	gold_label.text = _t("meta.hub.gold", {"value": int(_view_model.get("gold", 0))})
	reputation_label.text = _t("meta.hub.reputation", {"value": int(_view_model.get("reputation", 1))})
	stamina_label.text = _t("meta.hub.stamina", {
		"current": int(_view_model.get("stamina", 0)),
		"max": int(_view_model.get("max_stamina", 0))
	})
	phase_label.text = _t("meta.hub.phase", {
		"value": _t("meta.phase.%s" % String(_view_model.get("phase", "day")))
	})
	inventory_label.text = _t("meta.hub.inventory", {"value": String(_view_model.get("inventory_summary", "-"))})
	seeds_label.text = _t("meta.hub.seeds", {"value": String(_view_model.get("seed_summary", "-"))})
	recipes_label.text = _t("meta.hub.recipes", {"value": String(_view_model.get("recipe_summary", "-"))})
	bonus_label.text = _t("meta.hub.night_bonus", {"value": String(_view_model.get("night_bonus_summary", _t("meta.common.none")))})
	night_button.disabled = bool(_view_model.get("night_button_disabled", false))


func _on_language_changed(_language_code: String) -> void:
	_apply_view_model()


func _t(key: String, args: Dictionary = {}) -> String:
	if Localization == null or not Localization.has_method("t"):
		return key
	return String(Localization.call("t", key, args))
