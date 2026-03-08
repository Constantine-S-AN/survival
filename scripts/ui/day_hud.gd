extends Control
class_name DayHud

signal daily_orders_requested
signal legacy_requested

const PHASE_ORDER := ["morning", "noon", "afternoon", "evening"]

@onready var title_label: Label = $InfoPanel/Margin/VBox/Title
@onready var clock_status_label: Label = $InfoPanel/Margin/VBox/ClockStatus
@onready var phase_segments: Array[ColorRect] = [
	$InfoPanel/Margin/VBox/PhaseTrack/Morning,
	$InfoPanel/Margin/VBox/PhaseTrack/Noon,
	$InfoPanel/Margin/VBox/PhaseTrack/Afternoon,
	$InfoPanel/Margin/VBox/PhaseTrack/Evening
]
@onready var resources_label: Label = $InfoPanel/Margin/VBox/Resources
@onready var departure_label: Label = $InfoPanel/Margin/VBox/Departure
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
	var phase := String(_hud_model.get("phase", "morning"))
	var actions_until_evening := maxi(0, int(_hud_model.get("actions_until_evening", 0)))
	var night_ready := bool(_hud_model.get("night_ready", false))
	title_label.text = _t("meta.hub.day", {"value": int(_hud_model.get("current_day", 1))})
	clock_status_label.text = (
		_t("meta.day_hud.clock_phase_ready", {
			"phase": _t("meta.phase.%s" % phase)
		})
		if night_ready
		else _t("meta.day_hud.clock_phase_progress", {
			"phase": _t("meta.phase.%s" % phase),
			"value": actions_until_evening
		})
	)
	departure_label.text = (
		_t("meta.day_hud.departure_ready")
		if night_ready
		else _t("meta.day_hud.departure_locked", {"value": actions_until_evening})
	)
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
	_apply_phase_track(phase, night_ready)
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


func _apply_phase_track(phase: String, night_ready: bool) -> void:
	var active_index := _phase_index(phase)
	for index in range(phase_segments.size()):
		var segment := phase_segments[index]
		if segment == null:
			continue
		var color := _phase_color(PHASE_ORDER[index])
		if night_ready and index == phase_segments.size() - 1:
			color = Color(0.56, 0.82, 1.0, 1.0)
		segment.color = color
		segment.modulate = Color(1.0, 1.0, 1.0, 1.0) if index <= active_index else Color(1.0, 1.0, 1.0, 0.24)


func _phase_index(phase: String) -> int:
	var normalized := phase.strip_edges().to_lower()
	if normalized == "night":
		return phase_segments.size() - 1
	var index := PHASE_ORDER.find(normalized)
	return index if index >= 0 else 0


func _phase_color(phase: String) -> Color:
	match phase:
		"morning":
			return Color(0.95, 0.84, 0.46, 1.0)
		"noon":
			return Color(0.99, 0.76, 0.33, 1.0)
		"afternoon":
			return Color(0.92, 0.54, 0.28, 1.0)
		"evening":
			return Color(0.48, 0.66, 0.95, 1.0)
	return Color(0.82, 0.82, 0.82, 1.0)


func _on_language_changed(_language_code: String) -> void:
	_apply_hud_model()


func _t(key: String, args: Dictionary = {}) -> String:
	if Localization == null or not Localization.has_method("t"):
		return key
	return String(Localization.call("t", key, args))
