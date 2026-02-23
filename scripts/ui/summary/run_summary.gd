extends Panel
class_name RunSummaryView

signal retry_requested
signal back_to_menu_requested

const RunSummaryStateClass := preload("res://scripts/ui/summary/run_summary_state.gd")
const UIMotionClass := preload("res://scripts/ui/ui_motion.gd")

@onready var title_label: Label = $Margin/VBox/Header/TitleGroup/Title
@onready var subtitle_label: Label = $Margin/VBox/Header/TitleGroup/Subtitle
@onready var seed_label: Label = $Margin/VBox/Header/Seed

@onready var time_value: Label = $Margin/VBox/Columns/LeftColumn/StatsCard/Margin/Content/HeroValues/TimeValue
@onready var kills_value: Label = $Margin/VBox/Columns/LeftColumn/StatsCard/Margin/Content/HeroValues/KillsValue
@onready var level_badge: PanelContainer = $Margin/VBox/Columns/LeftColumn/StatsCard/Margin/Content/StatsBadges/LevelBadge
@onready var noise_badge: PanelContainer = $Margin/VBox/Columns/LeftColumn/StatsCard/Margin/Content/StatsBadges/NoiseBadge
@onready var enemies_badge: PanelContainer = $Margin/VBox/Columns/LeftColumn/StatsCard/Margin/Content/StatsBadges/EnemiesBadge
@onready var revealed_badge: PanelContainer = $Margin/VBox/Columns/LeftColumn/StatsCard/Margin/Content/StatsBadges/RevealedBadge
@onready var boss_progress_label: Label = $Margin/VBox/Columns/LeftColumn/StatsCard/Margin/Content/BossProgress

@onready var weapon_label: Label = $Margin/VBox/Columns/RightColumn/BuildCard/Margin/Content/WeaponLabel
@onready var top_tags_label: Label = $Margin/VBox/Columns/RightColumn/BuildCard/Margin/Content/TopTagsLabel
@onready var upgrades_label: Label = $Margin/VBox/Columns/RightColumn/BuildCard/Margin/Content/UpgradesLabel
@onready var map_contracts_label: Label = $Margin/VBox/Columns/RightColumn/BuildCard/Margin/Content/MapContractsLabel
@onready var multipliers_label: Label = $Margin/VBox/Columns/RightColumn/BuildCard/Margin/Content/MultipliersLabel
@onready var meta_currency_label: Label = $Margin/VBox/Columns/RightColumn/BuildCard/Margin/Content/MetaCurrencyLabel

@onready var progress_target_label: Label = $Margin/VBox/Columns/RightColumn/ProgressCard/Margin/Content/ProgressTarget
@onready var progress_bar: ProgressBar = $Margin/VBox/Columns/RightColumn/ProgressCard/Margin/Content/ProgressBar
@onready var progress_detail_label: Label = $Margin/VBox/Columns/RightColumn/ProgressCard/Margin/Content/ProgressDetail
@onready var newly_unlocked_label: Label = $Margin/VBox/Columns/RightColumn/ProgressCard/Margin/Content/NewlyUnlocked
@onready var progress_card: PanelContainer = $Margin/VBox/Columns/RightColumn/ProgressCard

@onready var retry_button: Button = $Margin/VBox/CTA/RetryButton
@onready var menu_button: Button = $Margin/VBox/CTA/MenuButton

var _state: Dictionary = {}
var _rendered_key_fields: int = 0


func _ready() -> void:
	visible = false
	retry_button.pressed.connect(func() -> void:
		retry_requested.emit()
	)
	menu_button.pressed.connect(func() -> void:
		back_to_menu_requested.emit()
	)
	if retry_button.has_method("set_motion_enabled"):
		retry_button.call("set_motion_enabled", true)
	if menu_button.has_method("set_motion_enabled"):
		menu_button.call("set_motion_enabled", true)


func show_summary(data: Dictionary) -> void:
	set_summary_data(data)
	visible = true
	retry_button.grab_focus()


func hide_summary() -> void:
	visible = false


func set_summary_data(data: Dictionary) -> void:
	_state = RunSummaryStateClass.from_dict(data)
	_render()


func debug_get_snapshot() -> Dictionary:
	return {
		"visible": visible,
		"rendered_key_fields": _rendered_key_fields,
		"title": title_label.text,
		"weapon": weapon_label.text,
		"progress_target": progress_target_label.text,
		"retry_disabled": retry_button.disabled
	}


func debug_focus_retry() -> void:
	retry_button.grab_focus()


func debug_press_retry() -> void:
	retry_button.emit_signal("pressed")


func debug_pulse_progress() -> void:
	if not UIMotionClass.is_motion_enabled():
		return
	UIMotionClass.press_bounce(progress_card, 0.12)


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if not (event is InputEventKey):
		return
	if not event.pressed or event.echo:
		return
	if event.keycode == KEY_ESCAPE:
		back_to_menu_requested.emit()
		accept_event()


func _render() -> void:
	_rendered_key_fields = 0
	title_label.text = "Run Summary"
	subtitle_label.text = "Build recap and progression snapshot"
	seed_label.text = "Seed %d" % int(_state.get("seed", 0))

	time_value.text = RunSummaryStateClass.format_time(float(_state.get("time_survived_sec", 0.0)))
	kills_value.text = str(int(_state.get("kills", 0)))
	_set_badge(level_badge, "Level", str(int(_state.get("level", 1))))
	_set_badge(noise_badge, "Noise Peak", String(_state.get("noise_peak_tier", "-")))
	_set_badge(enemies_badge, "Enemies", str(int(_state.get("enemies_seen", 0))))
	_set_badge(revealed_badge, "Revealed", str(int(_state.get("revealed_count", 0))))
	_rendered_key_fields += 4

	var boss_progress := String(_state.get("boss_progress", "")).strip_edges()
	boss_progress_label.visible = not boss_progress.is_empty()
	if boss_progress_label.visible:
		boss_progress_label.text = "Boss progress: %s" % boss_progress.capitalize()
		_rendered_key_fields += 1

	weapon_label.text = "Weapon: %s" % String(_state.get("weapon_name", "--"))
	if not String(_state.get("weapon_name", "")).strip_edges().is_empty():
		_rendered_key_fields += 1

	top_tags_label.text = "Top tags: %s" % _format_top_tags(_state.get("top_tags", []))
	upgrades_label.text = "Chosen upgrades:\n%s" % _format_upgrades(_state.get("chosen_upgrades", []))
	map_contracts_label.text = "Map: %s\nContracts: %s" % [
		String(_state.get("map_name", "-")),
		_format_contracts(_state.get("contract_names", []))
	]
	multipliers_label.text = _format_multipliers(_state.get("multipliers", {}))
	meta_currency_label.text = _format_meta_currency(_state.get("meta_currency_earned", null))
	_rendered_key_fields += 3

	var unlock_rows: Array = _state.get("unlock_progress", [])
	if unlock_rows.is_empty():
		progress_target_label.text = "All characters unlocked"
		progress_bar.value = 1.0
		progress_detail_label.text = "No pending target"
	else:
		var row_variant: Variant = unlock_rows[0]
		if row_variant is Dictionary:
			var row: Dictionary = row_variant
			progress_target_label.text = "Next target: %s" % String(row.get("name", "Unknown"))
			progress_bar.value = clampf(float(row.get("ratio", 0.0)), 0.0, 1.0)
			var display_text := String(row.get("display", "")).strip_edges()
			var value_text := String(row.get("text", "")).strip_edges()
			progress_detail_label.text = "%s\nProgress: %s" % [display_text, value_text]
			_rendered_key_fields += 1

	var newly_unlocked: Array[String] = _state.get("newly_unlocked_names", [])
	if newly_unlocked.is_empty():
		newly_unlocked_label.text = "New unlocks: —"
	else:
		newly_unlocked_label.text = "New unlocks: %s" % ", ".join(newly_unlocked)
		_rendered_key_fields += 1

	retry_button.disabled = false


func _set_badge(badge_node: PanelContainer, label: String, value: String) -> void:
	if badge_node == null:
		return
	if badge_node.has_method("set_badge"):
		badge_node.call("set_badge", label, value)


func _format_top_tags(value: Variant) -> String:
	if not (value is Array):
		return "-"
	var output: Array[String] = []
	for row_variant in (value as Array):
		if not (row_variant is Dictionary):
			continue
		var row: Dictionary = row_variant
		output.append("[%s x%d]" % [String(row.get("label", "Tag")), int(row.get("weight", 0))])
	if output.is_empty():
		return "-"
	return " ".join(output)


func _format_upgrades(value: Variant) -> String:
	if not (value is Array):
		return "-"
	var output: Array[String] = []
	for row_variant in (value as Array):
		if not (row_variant is Dictionary):
			continue
		var row: Dictionary = row_variant
		var rarity := String(row.get("rarity", "common")).capitalize()
		var count := int(row.get("count", 1))
		output.append("• %s [%s] x%d" % [String(row.get("name", "Unknown")), rarity, count])
	if output.is_empty():
		return "-"
	if output.size() > 6:
		output.resize(6)
	return "\n".join(output)


func _format_contracts(value: Variant) -> String:
	if not (value is Array):
		return "None"
	var names: Array[String] = value
	if names.is_empty():
		return "None"
	return ", ".join(names)


func _format_multipliers(value: Variant) -> String:
	var multipliers: Dictionary = value if value is Dictionary else {}
	return "XP x%.2f | Rarity x%.2f\nDrop x%.2f | Meta x%.2f" % [
		float(multipliers.get("xp", 1.0)),
		float(multipliers.get("rarity", 1.0)),
		float(multipliers.get("drop", 1.0)),
		float(multipliers.get("meta_currency", 1.0))
	]


func _format_meta_currency(value: Variant) -> String:
	if value == null:
		return "Meta currency earned: —"
	return "Meta currency earned: %d" % int(value)
