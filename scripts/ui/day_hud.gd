extends Control
class_name DayHud

signal daily_orders_requested
signal legacy_requested

@onready var title_label: Label = $InfoPanel/Margin/VBox/Title
@onready var resources_label: Label = $InfoPanel/Margin/VBox/Resources
@onready var status_panel: Panel = $BottomLeftColumn/StatusPanel
@onready var status_label: Label = $BottomLeftColumn/StatusPanel/Margin/Status
@onready var orders_button: Button = $ActionsColumn/Buttons/OrdersButton
@onready var legacy_button: Button = $ActionsColumn/Buttons/LegacyButton
@onready var farm_tool_panel: Panel = $BottomLeftColumn/FarmToolPanel
@onready var farm_tool_title_label: Label = $BottomLeftColumn/FarmToolPanel/Margin/VBox/ToolTitle
@onready var farm_tool_body_label: Label = $BottomLeftColumn/FarmToolPanel/Margin/VBox/ToolBody
@onready var farm_tool_hint_label: Label = $BottomLeftColumn/FarmToolPanel/Margin/VBox/ToolHint
@onready var guide_panel: Panel = $ActionsColumn/GuidePanel
@onready var guide_title_label: Label = $ActionsColumn/GuidePanel/Margin/VBox/GuideTitle
@onready var guide_body_label: Label = $ActionsColumn/GuidePanel/Margin/VBox/GuideBody
@onready var hint_label: Label = $PromptPanel/Margin/VBox/Hint
@onready var prompt_label: Label = $PromptPanel/Margin/VBox/Prompt

var _hud_model: Dictionary = {}


func _ready() -> void:
	if Localization != null and Localization.has_signal("language_changed"):
		Localization.language_changed.connect(_on_language_changed)
	orders_button.pressed.connect(func() -> void:
		daily_orders_requested.emit()
	)
	legacy_button.pressed.connect(func() -> void:
		legacy_requested.emit()
	)
	_apply_hud_model()


func set_hud_model(model: Dictionary) -> void:
	_hud_model = model.duplicate(true)
	_apply_hud_model()


func _apply_hud_model() -> void:
	title_label.text = "%s  |  %s" % [
		_t("meta.hub.day", {"value": int(_hud_model.get("current_day", 1))}),
		_t("meta.phase.%s" % String(_hud_model.get("phase", "morning")))
	]
	resources_label.text = "%s  |  %s  |  %s" % [
		_t("meta.hub.gold", {"value": int(_hud_model.get("gold", 0))}),
		_t("meta.hub.stamina", {
			"current": int(_hud_model.get("stamina", 0)),
			"max": int(_hud_model.get("max_stamina", 0))
		}),
		_t("meta.hub.actions", {
			"current": int(_hud_model.get("action_budget", 0)),
			"max": int(_hud_model.get("max_action_budget", 0))
		})
	]
	status_label.text = String(_hud_model.get("status_text", ""))
	status_panel.visible = not status_label.text.strip_edges().is_empty()
	var ready_orders := int(_hud_model.get("ready_orders", 0))
	orders_button.text = _t("meta.day_hud.orders_ready", {"value": ready_orders}) if ready_orders > 0 else _t("meta.day_hud.orders")
	orders_button.tooltip_text = _t("meta.day_hud.orders_tooltip")
	legacy_button.text = _t("meta.world.legacy_hub")
	legacy_button.tooltip_text = _t("meta.world.legacy_hub_tooltip")
	farm_tool_title_label.text = _t("meta.day_hud.farm_tool")
	farm_tool_body_label.text = String(_hud_model.get("farm_tool_text", _t("meta.farm.tool_none")))
	farm_tool_hint_label.text = String(_hud_model.get("farm_tool_hint", _t("meta.day_hud.farm_tool_hint")))
	farm_tool_panel.visible = bool(_hud_model.get("farm_tool_visible", false))
	var guide_title := String(_hud_model.get("guide_title", "")).strip_edges()
	var guide_text := String(_hud_model.get("guide_text", "")).strip_edges()
	guide_panel.visible = not guide_title.is_empty() or not guide_text.is_empty()
	guide_title_label.text = guide_title
	guide_body_label.text = guide_text
	hint_label.text = String(_hud_model.get("move_hint", _t("meta.world.move_hint")))
	prompt_label.text = String(_hud_model.get("prompt_text", _t("meta.world.prompt_idle")))


func _on_language_changed(_language_code: String) -> void:
	_apply_hud_model()


func _t(key: String, args: Dictionary = {}) -> String:
	if Localization == null or not Localization.has_method("t"):
		return key
	return String(Localization.call("t", key, args))
