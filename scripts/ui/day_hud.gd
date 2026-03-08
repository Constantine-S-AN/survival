extends Control
class_name DayHud

signal daily_orders_requested
signal legacy_requested

const PHASE_ORDER := ["morning", "noon", "afternoon", "evening"]
const HUD_FONT := preload("res://assets/fonts/google/Exo2-Variable.ttf")

@onready var info_panel: Panel = $InfoPanel
@onready var title_label: Label = $InfoPanel/Margin/VBox/Title
@onready var subtitle_label: Label = $InfoPanel/Margin/VBox/Subtitle
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
@onready var farm_tool_slots: HBoxContainer = $BottomLeftColumn/FarmToolPanel/Margin/VBox/ToolSlots
@onready var farm_tool_body_label: Label = $BottomLeftColumn/FarmToolPanel/Margin/VBox/ToolBody
@onready var farm_tool_hint_label: Label = $BottomLeftColumn/FarmToolPanel/Margin/VBox/ToolHint
@onready var guide_panel: Panel = $ActionsColumn/GuidePanel
@onready var guide_title_label: Label = $ActionsColumn/GuidePanel/Margin/VBox/GuideTitle
@onready var guide_body_label: Label = $ActionsColumn/GuidePanel/Margin/VBox/GuideBody
@onready var prompt_panel: Panel = $PromptPanel
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


func debug_get_snapshot() -> Dictionary:
	return {
		"phase": String(_hud_model.get("phase", "morning")),
		"actions_until_evening": maxi(0, int(_hud_model.get("actions_until_evening", 0))),
		"night_ready": bool(_hud_model.get("night_ready", false)),
		"clock_status_text": clock_status_label.text if clock_status_label != null else "",
		"departure_text": departure_label.text if departure_label != null else "",
		"prompt_text": prompt_label.text if prompt_label != null else "",
		"guide_title": guide_title_label.text if guide_title_label != null else "",
		"guide_text": guide_body_label.text if guide_body_label != null else "",
		"phase_track_active_index": _phase_index(String(_hud_model.get("phase", "morning")))
	}


func _apply_hud_model() -> void:
	var phase := String(_hud_model.get("phase", "morning"))
	var actions_until_evening := maxi(0, int(_hud_model.get("actions_until_evening", 0)))
	var night_ready := bool(_hud_model.get("night_ready", false))
	title_label.text = _t("meta.hub.day", {"value": int(_hud_model.get("current_day", 1))})
	subtitle_label.text = _t("meta.world.title")
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
	farm_tool_title_label.text = _t("meta.day_hud.hotbar")
	var hotbar_slots_variant: Variant = _hud_model.get("hotbar_slots", [])
	var hotbar_slots: Array = hotbar_slots_variant if hotbar_slots_variant is Array else []
	_rebuild_hotbar_slots(hotbar_slots, String(_hud_model.get("selected_hotbar_key", "")))
	farm_tool_body_label.text = String(_hud_model.get("hotbar_selected_text", _t("meta.farm.tool_none")))
	farm_tool_hint_label.text = String(_hud_model.get("hotbar_hint", _t("meta.day_hud.hotbar_hint")))
	farm_tool_panel.visible = bool(_hud_model.get("farm_tool_visible", false))
	var guide_title := String(_hud_model.get("guide_title", "")).strip_edges()
	var guide_text := String(_hud_model.get("guide_text", "")).strip_edges()
	guide_panel.visible = not guide_title.is_empty() or not guide_text.is_empty()
	guide_title_label.text = guide_title
	guide_body_label.text = guide_text
	prompt_label.text = String(_hud_model.get("prompt_text", _t("meta.world.prompt_idle")))
	hint_label.text = String(_hud_model.get("move_hint", _t("meta.world.move_hint")))
	var prompt_visible := bool(_hud_model.get("prompt_visible", true))
	prompt_panel.visible = prompt_visible and (not prompt_label.text.strip_edges().is_empty() or not hint_label.text.strip_edges().is_empty())
	hint_label.visible = prompt_panel.visible
	_apply_visual_theme(phase, night_ready)


func _rebuild_hotbar_slots(slots: Array, selected_key: String) -> void:
	if farm_tool_slots == null:
		return
	for child in farm_tool_slots.get_children():
		child.free()
	for slot_variant in slots:
		if not (slot_variant is Dictionary):
			continue
		var slot: Dictionary = slot_variant
		var slot_key := String(slot.get("key", ""))
		var panel := Panel.new()
		panel.custom_minimum_size = Vector2(58.0, 56.0)
		panel.add_theme_stylebox_override("panel", _make_hotbar_slot_style(slot, slot_key == selected_key))
		farm_tool_slots.add_child(panel)

		var margin := MarginContainer.new()
		margin.set_anchors_preset(Control.PRESET_FULL_RECT)
		margin.add_theme_constant_override("margin_left", 6)
		margin.add_theme_constant_override("margin_top", 5)
		margin.add_theme_constant_override("margin_right", 6)
		margin.add_theme_constant_override("margin_bottom", 5)
		panel.add_child(margin)

		var vbox := VBoxContainer.new()
		vbox.alignment = BoxContainer.ALIGNMENT_CENTER
		vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
		vbox.add_theme_constant_override("separation", 2)
		margin.add_child(vbox)

		var index_label := Label.new()
		index_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		index_label.theme_type_variation = &"BodyMutedLabel"
		index_label.text = String(slot.get("slot_label", ""))
		index_label.modulate = Color(1.0, 1.0, 1.0, 0.84)
		vbox.add_child(index_label)

		var body_label := Label.new()
		body_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		body_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		body_label.text = String(slot.get("short_label", ""))
		body_label.modulate = Color(1.0, 1.0, 1.0, 1.0 if bool(slot.get("enabled", true)) else 0.56)
		vbox.add_child(body_label)


func _hotbar_slot_modulate(slot: Dictionary, selected: bool) -> Color:
	if selected:
		return Color(1.0, 0.96, 0.82, 1.0)
	if bool(slot.get("enabled", true)):
		return Color(1.0, 1.0, 1.0, 0.92)
	return Color(0.78, 0.82, 0.88, 0.62)


func _apply_visual_theme(phase: String, night_ready: bool) -> void:
	var palette := _hud_palette(phase, night_ready)
	info_panel.add_theme_stylebox_override("panel", _make_panel_style(palette["panel_fill"], palette["panel_border"], 18.0, 16.0))
	status_panel.add_theme_stylebox_override("panel", _make_panel_style(palette["subpanel_fill"], palette["subpanel_border"], 14.0, 12.0))
	farm_tool_panel.add_theme_stylebox_override("panel", _make_panel_style(palette["subpanel_fill"], palette["subpanel_border"], 14.0, 12.0))
	guide_panel.add_theme_stylebox_override("panel", _make_panel_style(palette["subpanel_fill"], palette["subpanel_border"], 14.0, 12.0))
	prompt_panel.add_theme_stylebox_override("panel", _make_panel_style(palette["prompt_fill"], palette["prompt_border"], 18.0, 14.0))
	_apply_button_theme(orders_button, palette["primary_button_fill"], palette["primary_button_border"], palette["button_text"])
	_apply_button_theme(legacy_button, palette["secondary_button_fill"], palette["secondary_button_border"], palette["button_text"])

	for text_control in [title_label, resources_label, prompt_label, farm_tool_title_label, farm_tool_body_label, guide_title_label]:
		if text_control == null:
			continue
		text_control.add_theme_color_override("font_color", palette["title_text"])
		text_control.add_theme_font_override("font", HUD_FONT)
	for text_control in [subtitle_label, clock_status_label, departure_label, status_label, farm_tool_hint_label, guide_body_label, hint_label]:
		if text_control == null:
			continue
		text_control.add_theme_color_override("font_color", palette["muted_text"])
		text_control.add_theme_font_override("font", HUD_FONT)
	title_label.add_theme_font_size_override("font_size", 24)
	subtitle_label.add_theme_font_size_override("font_size", 14)
	prompt_label.add_theme_font_size_override("font_size", 16)
	hint_label.add_theme_font_size_override("font_size", 12)
	orders_button.add_theme_font_override("font", HUD_FONT)
	legacy_button.add_theme_font_override("font", HUD_FONT)


func _hud_palette(phase: String, night_ready: bool) -> Dictionary:
	match phase:
		"noon":
			return {
				"panel_fill": Color(0.11, 0.12, 0.09, 0.80),
				"panel_border": Color(0.71, 0.59, 0.34, 0.95),
				"subpanel_fill": Color(0.14, 0.14, 0.10, 0.78),
				"subpanel_border": Color(0.55, 0.46, 0.28, 0.84),
				"prompt_fill": Color(0.14, 0.12, 0.09, 0.78),
				"prompt_border": Color(0.79, 0.66, 0.38, 0.78),
				"primary_button_fill": Color(0.59, 0.41, 0.21, 0.96),
				"primary_button_border": Color(0.87, 0.72, 0.41, 1.0),
				"secondary_button_fill": Color(0.24, 0.21, 0.15, 0.94),
				"secondary_button_border": Color(0.56, 0.48, 0.33, 0.92),
				"title_text": Color(0.98, 0.95, 0.85, 1.0),
				"muted_text": Color(0.87, 0.82, 0.70, 1.0),
				"button_text": Color(0.99, 0.96, 0.88, 1.0)
			}
		"afternoon":
			return {
				"panel_fill": Color(0.12, 0.11, 0.10, 0.82),
				"panel_border": Color(0.76, 0.52, 0.30, 0.96),
				"subpanel_fill": Color(0.15, 0.13, 0.11, 0.80),
				"subpanel_border": Color(0.60, 0.43, 0.28, 0.84),
				"prompt_fill": Color(0.15, 0.11, 0.10, 0.80),
				"prompt_border": Color(0.82, 0.58, 0.34, 0.82),
				"primary_button_fill": Color(0.62, 0.34, 0.20, 0.96),
				"primary_button_border": Color(0.90, 0.63, 0.39, 1.0),
				"secondary_button_fill": Color(0.25, 0.19, 0.15, 0.94),
				"secondary_button_border": Color(0.59, 0.42, 0.30, 0.92),
				"title_text": Color(0.98, 0.94, 0.87, 1.0),
				"muted_text": Color(0.89, 0.80, 0.72, 1.0),
				"button_text": Color(1.0, 0.96, 0.90, 1.0)
			}
		"evening":
			return {
				"panel_fill": Color(0.11, 0.12, 0.16, 0.84),
				"panel_border": Color(0.88, 0.60, 0.40, 0.98),
				"subpanel_fill": Color(0.14, 0.14, 0.18, 0.82),
				"subpanel_border": Color(0.66, 0.49, 0.36, 0.90),
				"prompt_fill": Color(0.12, 0.10, 0.15, 0.82),
				"prompt_border": Color(0.95, 0.67, 0.44, 0.84),
				"primary_button_fill": Color(0.69, 0.36, 0.23, 0.98),
				"primary_button_border": Color(0.97, 0.72, 0.48, 1.0),
				"secondary_button_fill": Color(0.22, 0.20, 0.25, 0.94),
				"secondary_button_border": Color(0.60, 0.50, 0.43, 0.94),
				"title_text": Color(1.0, 0.95, 0.90, 1.0),
				"muted_text": Color(0.89, 0.84, 0.79, 1.0),
				"button_text": Color(1.0, 0.97, 0.92, 1.0)
			}
		"night":
			return {
				"panel_fill": Color(0.07, 0.10, 0.16, 0.86),
				"panel_border": Color(0.49, 0.68, 0.88, 0.96),
				"subpanel_fill": Color(0.09, 0.12, 0.18, 0.84),
				"subpanel_border": Color(0.36, 0.53, 0.74, 0.90),
				"prompt_fill": Color(0.07, 0.10, 0.18, 0.84),
				"prompt_border": Color(0.56, 0.77, 0.98, 0.84),
				"primary_button_fill": Color(0.22, 0.38, 0.56, 0.98),
				"primary_button_border": Color(0.67, 0.87, 1.0, 1.0),
				"secondary_button_fill": Color(0.15, 0.20, 0.29, 0.94),
				"secondary_button_border": Color(0.38, 0.56, 0.77, 0.94),
				"title_text": Color(0.94, 0.97, 1.0, 1.0),
				"muted_text": Color(0.78, 0.87, 0.96, 1.0),
				"button_text": Color(0.96, 0.98, 1.0, 1.0)
			}
		_:
			return {
				"panel_fill": Color(0.12, 0.13, 0.10, 0.80),
				"panel_border": Color(0.68, 0.56, 0.34, 0.95),
				"subpanel_fill": Color(0.15, 0.15, 0.11, 0.78),
				"subpanel_border": Color(0.52, 0.44, 0.28, 0.84),
				"prompt_fill": Color(0.14, 0.12, 0.10, 0.78),
				"prompt_border": Color(0.78, 0.66, 0.40, 0.80),
				"primary_button_fill": Color(0.56, 0.38, 0.21, 0.96),
				"primary_button_border": Color(0.84, 0.69, 0.42, 1.0),
				"secondary_button_fill": Color(0.24, 0.21, 0.15, 0.94),
				"secondary_button_border": Color(0.56, 0.48, 0.33, 0.92),
				"title_text": Color(0.98, 0.95, 0.86, 1.0),
				"muted_text": Color(0.86, 0.82, 0.72, 1.0),
				"button_text": Color(0.99, 0.96, 0.88, 1.0)
			}


func _make_panel_style(fill: Color, border: Color, margin_x: float, margin_y: float) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.border_color = border
	style.content_margin_left = margin_x
	style.content_margin_top = margin_y
	style.content_margin_right = margin_x
	style.content_margin_bottom = margin_y
	style.shadow_color = Color(0.0, 0.0, 0.0, 0.22)
	style.shadow_size = 8
	return style


func _apply_button_theme(button: Button, fill: Color, border: Color, text_color: Color) -> void:
	if button == null:
		return
	var normal := StyleBoxFlat.new()
	normal.bg_color = fill
	normal.border_width_left = 1
	normal.border_width_top = 1
	normal.border_width_right = 1
	normal.border_width_bottom = 1
	normal.border_color = border
	normal.content_margin_left = 14.0
	normal.content_margin_top = 10.0
	normal.content_margin_right = 14.0
	normal.content_margin_bottom = 10.0
	var hover := normal.duplicate() as StyleBoxFlat
	hover.bg_color = fill.lightened(0.08)
	var pressed := normal.duplicate() as StyleBoxFlat
	pressed.bg_color = fill.darkened(0.10)
	var focus := normal.duplicate() as StyleBoxFlat
	focus.border_width_left = 2
	focus.border_width_top = 2
	focus.border_width_right = 2
	focus.border_width_bottom = 2
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", pressed)
	button.add_theme_stylebox_override("focus", focus)
	button.add_theme_color_override("font_color", text_color)
	button.add_theme_color_override("font_hover_color", text_color)
	button.add_theme_color_override("font_pressed_color", text_color)
	button.add_theme_color_override("font_focus_color", text_color)


func _make_hotbar_slot_style(slot: Dictionary, selected: bool) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.content_margin_left = 6.0
	style.content_margin_top = 6.0
	style.content_margin_right = 6.0
	style.content_margin_bottom = 6.0
	if selected:
		style.bg_color = Color(0.30, 0.23, 0.16, 0.96)
		style.border_color = Color(0.90, 0.73, 0.46, 1.0)
	elif bool(slot.get("enabled", true)):
		style.bg_color = Color(0.16, 0.14, 0.10, 0.88)
		style.border_color = Color(0.58, 0.48, 0.32, 0.92)
	else:
		style.bg_color = Color(0.13, 0.12, 0.11, 0.68)
		style.border_color = Color(0.39, 0.36, 0.31, 0.72)
	return style


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
