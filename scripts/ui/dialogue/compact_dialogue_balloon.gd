extends "res://addons/dialogue_manager/example_balloon/example_balloon.gd"

@onready var continue_hint_label: Label = %ContinueHintLabel


func _ready() -> void:
	next_action = &"day_interact"
	super._ready()
	_refresh_continue_hint()


func _process(delta: float) -> void:
	super._process(delta)
	_refresh_continue_hint()


func _refresh_continue_hint() -> void:
	if continue_hint_label == null:
		return
	if not balloon.visible:
		continue_hint_label.visible = false
		return
	continue_hint_label.visible = true
	if dialogue_line == null:
		continue_hint_label.text = _t("meta.dialogue.advance_hint")
		return
	if dialogue_line.responses.size() > 0:
		continue_hint_label.text = _t("meta.dialogue.responses_hint")
		return
	if dialogue_label != null and dialogue_label.is_typing:
		continue_hint_label.text = _t("meta.dialogue.reveal_hint")
		return
	if is_waiting_for_input:
		continue_hint_label.text = _t("meta.dialogue.advance_hint")
		return
	continue_hint_label.text = _t("meta.dialogue.reveal_hint")


func _t(key: String, args: Dictionary = {}) -> String:
	if Localization != null and Localization.has_method("t"):
		return String(Localization.call("t", key, args))
	return key
