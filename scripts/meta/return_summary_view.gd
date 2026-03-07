extends Control
class_name ReturnSummaryView

signal continue_requested
signal menu_requested

@onready var title_label: Label = $ContentPanel/Margin/VBox/Title
@onready var subtitle_label: Label = $ContentPanel/Margin/VBox/Subtitle
@onready var outcome_label: Label = $ContentPanel/Margin/VBox/OutcomeLabel
@onready var run_label: Label = $ContentPanel/Margin/VBox/RunLabel
@onready var rewards_label: Label = $ContentPanel/Margin/VBox/RewardsLabel
@onready var unlocks_label: Label = $ContentPanel/Margin/VBox/UnlocksLabel
@onready var inventory_label: Label = $ContentPanel/Margin/VBox/InventoryLabel
@onready var continue_button: Button = $ContentPanel/Margin/VBox/Actions/ContinueButton
@onready var menu_button: Button = $ContentPanel/Margin/VBox/Actions/MenuButton

var _summary: Dictionary = {}


func _ready() -> void:
	visible = false
	continue_button.pressed.connect(func() -> void:
		continue_requested.emit()
	)
	menu_button.pressed.connect(func() -> void:
		menu_requested.emit()
	)
	if Localization != null and Localization.has_signal("language_changed"):
		Localization.language_changed.connect(_on_language_changed)
	_apply_summary()


func set_summary(summary: Dictionary) -> void:
	_summary = summary.duplicate(true)
	_apply_summary()


func _apply_summary() -> void:
	title_label.text = _t("meta.summary.title")
	subtitle_label.text = _t("meta.summary.subtitle")
	continue_button.text = _t("meta.summary.continue")
	menu_button.text = _t("meta.hub.menu")
	var exit_reason := String(_summary.get("exit_reason", "completed"))
	var outcome_key := "meta.summary.outcome_completed"
	if exit_reason == "abandoned":
		outcome_key = "meta.summary.outcome_abandoned"
	outcome_label.text = _t(outcome_key, {
		"day": int(_summary.get("current_day", 1)),
		"next_day": int(_summary.get("next_day", int(_summary.get("current_day", 1)) + 1))
	})
	run_label.text = _t("meta.summary.run", {
		"time": String(_summary.get("time_text", "00:00")),
		"kills": int(_summary.get("kills", 0)),
		"seed": int(_summary.get("seed", 0))
	})
	rewards_label.text = _t("meta.summary.rewards", {
		"gold": int(_summary.get("gold_reward", 0)),
		"materials": String(_summary.get("materials_reward_text", "-")),
		"bonus": String(_summary.get("night_bonus_text", _t("meta.common.none")))
	})
	var unlocks_text := String(_summary.get("unlock_text", _t("meta.common.none")))
	unlocks_label.text = _t("meta.summary.unlocks", {"value": unlocks_text})
	inventory_label.text = _t("meta.summary.inventory", {"value": String(_summary.get("inventory_summary", "-"))})


func _on_language_changed(_language_code: String) -> void:
	_apply_summary()


func _t(key: String, args: Dictionary = {}) -> String:
	if Localization == null or not Localization.has_method("t"):
		return key
	return String(Localization.call("t", key, args))
