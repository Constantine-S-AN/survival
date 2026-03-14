extends Control
class_name ReturnSummaryView

signal continue_requested
signal menu_requested

@onready var background: ColorRect = $Background
@onready var content_panel: Panel = $ContentPanel
@onready var header_box: VBoxContainer = $ContentPanel/Margin/VBox/Header
@onready var title_label: Label = $ContentPanel/Margin/VBox/Header/Title
@onready var subtitle_label: Label = $ContentPanel/Margin/VBox/Header/Subtitle
@onready var input_hint_label: Label = $ContentPanel/Margin/VBox/Header/InputHint
@onready var summary_scroll: ScrollContainer = $ContentPanel/Margin/VBox/Scroll
@onready var outcome_label: Label = $ContentPanel/Margin/VBox/Scroll/SummaryVBox/OutcomeLabel
@onready var run_label: Label = $ContentPanel/Margin/VBox/Scroll/SummaryVBox/RunLabel
@onready var rewards_label: Label = $ContentPanel/Margin/VBox/Scroll/SummaryVBox/RewardsLabel
@onready var carryover_label: Label = $ContentPanel/Margin/VBox/Scroll/SummaryVBox/CarryoverLabel
@onready var unlocks_label: Label = $ContentPanel/Margin/VBox/Scroll/SummaryVBox/UnlocksLabel
@onready var progress_label: Label = $ContentPanel/Margin/VBox/Scroll/SummaryVBox/ProgressLabel
@onready var penalty_label: Label = $ContentPanel/Margin/VBox/Scroll/SummaryVBox/PenaltyLabel
@onready var inventory_label: Label = $ContentPanel/Margin/VBox/Scroll/SummaryVBox/InventoryLabel
@onready var actions_box: HBoxContainer = $ContentPanel/Margin/VBox/Actions
@onready var continue_button: Button = $ContentPanel/Margin/VBox/Actions/ContinueButton
@onready var menu_button: Button = $ContentPanel/Margin/VBox/Actions/MenuButton

var _summary: Dictionary = {}
var _enter_tween: Tween = null
var _animate_in_on_visible: bool = false
var _summary_rows: Array[Control] = []


func _ready() -> void:
	visible = false
	visibility_changed.connect(_on_visibility_changed)
	_bind_button_feedback(continue_button, true)
	_bind_button_feedback(menu_button, false)
	continue_button.pressed.connect(_emit_continue_requested)
	menu_button.pressed.connect(_emit_menu_requested)
	_summary_rows = [
		header_box,
		summary_scroll,
		actions_box
	]
	if Localization != null and Localization.has_signal("language_changed"):
		Localization.language_changed.connect(_on_language_changed)
	_apply_summary()
	_reset_presentation_state()


func set_summary(summary: Dictionary) -> void:
	_summary = summary.duplicate(true)
	_apply_summary()


func present_summary(summary: Dictionary, animate_in: bool = false) -> void:
	set_summary(summary)
	_animate_in_on_visible = animate_in
	if visible:
		if animate_in:
			_play_enter_animation()
		else:
			_reset_presentation_state()


func _apply_summary() -> void:
	var next_day := int(_summary.get("next_day", int(_summary.get("current_day", 1)) + 1))
	title_label.text = _t("meta.summary.title")
	subtitle_label.text = _resolve_arrival_text()
	input_hint_label.text = _t("meta.summary.input_hint", {"day": next_day})
	continue_button.text = _t("meta.summary.continue", {"day": next_day})
	continue_button.tooltip_text = _t("meta.summary.input_hint", {"day": next_day})
	menu_button.text = _t("meta.hub.menu")
	menu_button.tooltip_text = _t("meta.hub.menu")
	var exit_reason := String(_summary.get("exit_reason", "completed"))
	var outcome_key := "meta.summary.outcome_completed"
	if exit_reason == "abandoned":
		outcome_key = "meta.summary.outcome_abandoned"
	elif exit_reason == "extracted":
		outcome_key = "meta.summary.outcome_extracted"
	outcome_label.text = _t(outcome_key, {
		"day": int(_summary.get("current_day", 1)),
		"next_day": int(_summary.get("next_day", int(_summary.get("current_day", 1)) + 1))
	})
	run_label.text = _t("meta.summary.run", {
		"time": String(_summary.get("time_text", "00:00")),
		"kills": int(_summary.get("kills", 0)),
		"seed": int(_summary.get("seed", 0))
	})
	rewards_label.text = _t("meta.summary.tonight", {
		"value": String(_summary.get("loot_text", _t("meta.common.none"))),
		"bonus": String(_summary.get("night_bonus_text", _t("meta.common.none")))
	})
	if carryover_label != null:
		carryover_label.text = _t("meta.summary.carryover_card", {
			"value": _build_carryover_text()
		})
	var unlocks_text := String(_summary.get("unlock_text", _t("meta.common.none")))
	unlocks_label.text = _t("meta.summary.unlocks_card", {"value": unlocks_text})
	progress_label.text = _t("meta.summary.progress_card", {
		"value": String(_summary.get("unlock_progress_text", _t("meta.common.none")))
	})
	penalty_label.text = _t("meta.summary.condition_card", {
		"value": String(_summary.get("penalty_text", _t("meta.summary.condition_none")))
	})
	inventory_label.text = _t("meta.summary.tomorrow_card", {
		"value": _resolve_tomorrow_text(),
		"inventory": String(_summary.get("inventory_summary", "-"))
	})
	if summary_scroll != null:
		summary_scroll.scroll_vertical = 0


func _on_language_changed(_language_code: String) -> void:
	_apply_summary()


func _on_visibility_changed() -> void:
	if not visible:
		_reset_presentation_state()
		return
	if _animate_in_on_visible:
		_play_enter_animation()
	else:
		_reset_presentation_state()
	_animate_in_on_visible = false
	call_deferred("_focus_continue_button")


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("ui_accept") or event.is_action_pressed("day_interact"):
		_emit_continue_requested()
		get_viewport().set_input_as_handled()


func _play_enter_animation() -> void:
	_reset_presentation_state()
	if _enter_tween != null and is_instance_valid(_enter_tween):
		_enter_tween.kill()
	if background != null:
		background.color.a = 0.0
	if content_panel != null:
		content_panel.pivot_offset = content_panel.size * 0.5
		content_panel.scale = Vector2(0.98, 0.98)
		content_panel.modulate = Color(1.0, 1.0, 1.0, 0.0)
	for row in _summary_rows:
		if row == null:
			continue
		row.pivot_offset = row.size * 0.5
		row.scale = Vector2(0.985, 0.985)
		row.modulate = Color(1.0, 1.0, 1.0, 0.0)
	_enter_tween = create_tween()
	_enter_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	if background != null:
		_enter_tween.parallel().tween_property(background, "color:a", 0.32, 0.24)
	if content_panel != null:
		_enter_tween.parallel().tween_property(content_panel, "scale", Vector2.ONE, 0.28).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		_enter_tween.parallel().tween_property(content_panel, "modulate:a", 1.0, 0.22).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	var row_delay := 0.05
	for row_index in range(_summary_rows.size()):
		var row := _summary_rows[row_index]
		if row == null:
			continue
		var delay := 0.07 + (float(row_index) * row_delay * 0.45)
		_enter_tween.parallel().tween_property(row, "scale", Vector2.ONE, 0.20).set_delay(delay).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		_enter_tween.parallel().tween_property(row, "modulate:a", 1.0, 0.18).set_delay(delay).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_play_summary_feedback()
	call_deferred("_focus_continue_button")


func _reset_presentation_state() -> void:
	if _enter_tween != null and is_instance_valid(_enter_tween):
		_enter_tween.kill()
	_enter_tween = null
	if background != null:
		background.color.a = 0.32
	if content_panel != null:
		content_panel.scale = Vector2.ONE
		content_panel.modulate = Color.WHITE
	for row in _summary_rows:
		if row == null:
			continue
		row.scale = Vector2.ONE
		row.modulate = Color.WHITE


func _bind_button_feedback(button: Button, confirm: bool) -> void:
	if button == null:
		return
	button.mouse_entered.connect(func() -> void:
		UISfx.play_hover()
	)
	button.pressed.connect(func() -> void:
		if confirm:
			UISfx.play_confirm()
		else:
			UISfx.play_click()
	)


func _emit_continue_requested() -> void:
	if not visible:
		return
	continue_requested.emit()


func _emit_menu_requested() -> void:
	if not visible:
		return
	menu_requested.emit()


func _focus_continue_button() -> void:
	if continue_button == null or not visible:
		return
	continue_button.grab_focus()


func _play_summary_feedback() -> void:
	var loot_text := String(_summary.get("loot_text", "")).strip_edges()
	var unlock_text := String(_summary.get("unlock_text", "")).strip_edges()
	if not loot_text.is_empty() or (not unlock_text.is_empty() and unlock_text != _t("meta.common.none")):
		UISfx.play_reward()
	else:
		UISfx.play_confirm()


func _t(key: String, args: Dictionary = {}) -> String:
	if Localization == null or not Localization.has_method("t"):
		return key
	return String(Localization.call("t", key, args))


func _resolve_arrival_text() -> String:
	var exit_reason := String(_summary.get("exit_reason", "completed")).strip_edges().to_lower()
	var raw_summary := _raw_summary()
	if exit_reason == "extracted":
		var room_label := String(raw_summary.get("dungeon_extraction_room_label", "")).strip_edges()
		if room_label.is_empty():
			return _t("meta.summary.arrival_extracted")
		return _t("meta.summary.arrival_extracted", {"room": room_label})
	if exit_reason == "completed" and bool(raw_summary.get("dungeon_boss_cleared", false)):
		return _t("meta.summary.arrival_boss_clear")
	return String(_summary.get("arrival_text", _t("meta.summary.subtitle")))


func _resolve_tomorrow_text() -> String:
	var exit_reason := String(_summary.get("exit_reason", "completed")).strip_edges().to_lower()
	if exit_reason != "extracted":
		return String(_summary.get("tomorrow_text", _t("meta.summary.tomorrow_generic")))
	return _t("meta.summary.tomorrow_extracted", {
		"value": _build_carryover_short_text()
	})


func _build_carryover_text() -> String:
	var raw_summary := _raw_summary()
	var rows_variant: Variant = raw_summary.get("dungeon_carryover_rows", [])
	if not (rows_variant is Array) or (rows_variant as Array).is_empty():
		if String(_summary.get("exit_reason", "completed")).strip_edges().to_lower() == "abandoned":
			return _t("meta.summary.carryover_abandoned")
		return _t("meta.common.none")
	var lines: Array[String] = []
	for row_variant in (rows_variant as Array):
		if not (row_variant is Dictionary):
			continue
		var row: Dictionary = row_variant
		var label := String(row.get("label", "Carryover")).strip_edges()
		var summary := String(row.get("summary", "")).strip_edges()
		if summary.is_empty():
			summary = _t("meta.common.none")
		lines.append("%s: %s" % [label, summary])
	return "\n".join(lines) if not lines.is_empty() else _t("meta.common.none")


func _build_carryover_short_text() -> String:
	var raw_summary := _raw_summary()
	var route_label := String(raw_summary.get("dungeon_return_route_label", "")).strip_edges()
	var rows_variant: Variant = raw_summary.get("dungeon_carryover_rows", [])
	if not (rows_variant is Array):
		return route_label if not route_label.is_empty() else _t("meta.summary.tomorrow_generic")
	var secured_count := 0
	for row_variant in (rows_variant as Array):
		if not (row_variant is Dictionary):
			continue
		if bool((row_variant as Dictionary).get("secured", false)):
			secured_count += 1
	if route_label.is_empty():
		return "%d secured carryover cache%s" % [secured_count, "" if secured_count == 1 else "s"]
	return "%s with %d secured cache%s" % [route_label, secured_count, "" if secured_count == 1 else "s"]


func _raw_summary() -> Dictionary:
	var raw_summary_variant: Variant = _summary.get("raw_summary", {})
	return raw_summary_variant if raw_summary_variant is Dictionary else {}
