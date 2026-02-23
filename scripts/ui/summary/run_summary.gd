extends Panel
class_name RunSummaryView

signal retry_requested
signal back_to_menu_requested

const RunSummaryStateClass := preload("res://scripts/ui/summary/run_summary_state.gd")
const UIMotionClass := preload("res://scripts/ui/ui_motion.gd")
const UISfx := preload("res://scripts/ui/ui_sfx.gd")
const IconRegistry := preload("res://scripts/ui/icon_registry.gd")
const TAG_ICON_CODES: Dictionary = {
	"sonar": "SO",
	"silence": "SI",
	"heat": "HT",
	"crit": "CR",
	"pierce": "PI",
	"chain": "CH",
	"aoe": "AO",
	"pickup": "PK",
	"shield": "SH",
	"speed": "SP",
	"trap": "TR",
	"control": "CT",
	"summon": "SM",
	"economy": "EC",
	"damage": "DM",
	"weapon": "WP",
	"tempo": "TP",
	"noise": "NS",
	"mobility": "MB",
	"defense": "DF",
	"hull": "HL"
}

@onready var backdrop_rect: ColorRect = $Backdrop
@onready var title_label: Label = $Margin/VBox/Header/TitleGroup/Title
@onready var subtitle_label: Label = $Margin/VBox/Header/TitleGroup/Subtitle
@onready var seed_label: Label = $Margin/VBox/Header/SeedBox/Seed
@onready var seed_copy_button: Button = $Margin/VBox/Header/SeedBox/CopySeedButton
@onready var unlock_toast: PanelContainer = $Margin/VBox/UnlockToast
@onready var unlock_toast_text: Label = $Margin/VBox/UnlockToast/UnlockToastMargin/UnlockToastText

@onready var time_value: Label = $Margin/VBox/Columns/LeftColumn/StatsCard/Margin/Content/HeroValues/TimeValue
@onready var kills_value: Label = $Margin/VBox/Columns/LeftColumn/StatsCard/Margin/Content/HeroValues/KillsValue
@onready var level_badge: PanelContainer = $Margin/VBox/Columns/LeftColumn/StatsCard/Margin/Content/StatsBadges/LevelBadge
@onready var noise_badge: PanelContainer = $Margin/VBox/Columns/LeftColumn/StatsCard/Margin/Content/StatsBadges/NoiseBadge
@onready var enemies_badge: PanelContainer = $Margin/VBox/Columns/LeftColumn/StatsCard/Margin/Content/StatsBadges/EnemiesBadge
@onready var revealed_badge: PanelContainer = $Margin/VBox/Columns/LeftColumn/StatsCard/Margin/Content/StatsBadges/RevealedBadge
@onready var boss_progress_label: Label = $Margin/VBox/Columns/LeftColumn/StatsCard/Margin/Content/BossProgress

@onready var weapon_icon: TextureRect = $Margin/VBox/Columns/RightColumn/BuildCard/Margin/Content/WeaponRow/WeaponIcon
@onready var weapon_label: Label = $Margin/VBox/Columns/RightColumn/BuildCard/Margin/Content/WeaponRow/WeaponLabel
@onready var top_tags_flow: HFlowContainer = $Margin/VBox/Columns/RightColumn/BuildCard/Margin/Content/TopTagsFlow
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
var _copy_seed_tween: Tween
var _progress_tween: Tween
var _unlock_toast_tween: Tween
var _backdrop_material: ShaderMaterial
var _backdrop_time: float = 0.0


func _ready() -> void:
	visible = false
	if backdrop_rect != null and backdrop_rect.material is ShaderMaterial:
		_backdrop_material = backdrop_rect.material
	retry_button.pressed.connect(func() -> void:
		retry_requested.emit()
	)
	menu_button.pressed.connect(func() -> void:
		back_to_menu_requested.emit()
	)
	seed_copy_button.pressed.connect(_on_copy_seed_pressed)
	if retry_button.has_method("set_motion_enabled"):
		retry_button.call("set_motion_enabled", true)
	if retry_button.has_method("set_button_role"):
		retry_button.call("set_button_role", 0)
	if menu_button.has_method("set_motion_enabled"):
		menu_button.call("set_motion_enabled", true)
	if unlock_toast != null:
		unlock_toast.visible = false
	set_process(true)


func _process(delta: float) -> void:
	if not visible:
		return
	if _backdrop_material == null:
		return
	_backdrop_time += delta
	_backdrop_material.set_shader_parameter("time_sec", _backdrop_time)


func show_summary(data: Dictionary) -> void:
	set_summary_data(data)
	visible = true
	UIMotionClass.panel_pop_in(self, 0.18, 10.0)
	if UIMotionClass.is_motion_enabled():
		UIMotionClass.press_bounce(retry_button, 0.12)
	if _should_play_reward_sfx():
		UISfx.play_reward()
	retry_button.grab_focus()


func hide_summary() -> void:
	visible = false
	modulate = Color(1.0, 1.0, 1.0, 1.0)
	if unlock_toast != null:
		unlock_toast.visible = false


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
	match event.keycode:
		KEY_ESCAPE:
			back_to_menu_requested.emit()
			accept_event()
		KEY_ENTER, KEY_KP_ENTER:
			if not retry_button.disabled:
				retry_requested.emit()
				accept_event()
		_:
			pass


func _render() -> void:
	_rendered_key_fields = 0
	title_label.text = "Run Summary"
	subtitle_label.text = "Build recap and progression snapshot"
	seed_label.text = "Seed %d" % int(_state.get("seed", 0))
	seed_copy_button.text = "Copy"
	seed_copy_button.disabled = int(_state.get("seed", 0)) <= 0

	time_value.text = RunSummaryStateClass.format_time(float(_state.get("time_survived_sec", 0.0)))
	kills_value.text = str(int(_state.get("kills", 0)))
	_set_badge(level_badge, "Level", str(int(_state.get("level", 1))))
	_set_badge(noise_badge, "Noise Peak", String(_state.get("noise_peak_tier", "-")))
	_set_badge(enemies_badge, "Enemies", str(int(_state.get("enemies_seen", 0))))
	_set_badge(revealed_badge, "Revealed", str(int(_state.get("revealed_count", 0))))
	_rendered_key_fields += 4

	var boss_progress := String(_state.get("boss_progress", "")).strip_edges()
	var boss_normalized := boss_progress.to_lower()
	var hide_boss_progress := boss_normalized.is_empty() or boss_normalized == "idle" or boss_normalized == "none"
	boss_progress_label.visible = not hide_boss_progress
	if boss_progress_label.visible:
		boss_progress_label.text = "Boss progress: %s" % boss_progress.capitalize()
		_rendered_key_fields += 1

	weapon_label.text = "Weapon: %s" % String(_state.get("weapon_name", "--"))
	if weapon_icon != null:
		weapon_icon.texture = IconRegistry.get_weapon_icon(String(_state.get("weapon_id", "")))
	if not String(_state.get("weapon_name", "")).strip_edges().is_empty():
		_rendered_key_fields += 1

	_render_top_tag_badges(_state.get("top_tags", []))
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
		_animate_progress(1.0)
		progress_detail_label.text = "No pending target"
	else:
		var row_variant: Variant = unlock_rows[0]
		if row_variant is Dictionary:
			var row: Dictionary = row_variant
			progress_target_label.text = "Next target: %s" % String(row.get("name", "Unknown"))
			_animate_progress(clampf(float(row.get("ratio", 0.0)), 0.0, 1.0))
			var display_text := String(row.get("display", "")).strip_edges()
			var value_text := String(row.get("text", "")).strip_edges()
			progress_detail_label.text = "%s\nProgress: %s" % [display_text, value_text]
			_rendered_key_fields += 1

	var newly_unlocked: Array[String] = _state.get("newly_unlocked_names", [])
	if newly_unlocked.is_empty():
		newly_unlocked_label.text = "New unlocks: —"
	else:
		newly_unlocked_label.text = "New unlocks: %s" % ", ".join(newly_unlocked)
		_show_unlock_toast(newly_unlocked)
		_rendered_key_fields += 1

	retry_button.disabled = false


func _set_badge(badge_node: PanelContainer, label: String, value: String) -> void:
	if badge_node == null:
		return
	if badge_node.has_method("set_badge"):
		badge_node.call("set_badge", label, value)


func _render_top_tag_badges(value: Variant) -> void:
	for child in top_tags_flow.get_children():
		child.queue_free()
	if not (value is Array):
		_append_tag_badge("—")
		return
	var rows: Array[Dictionary] = []
	for row_variant in (value as Array):
		if not (row_variant is Dictionary):
			continue
		var row: Dictionary = row_variant
		rows.append(row)
	if rows.is_empty():
		_append_tag_badge("—")
		return

	var max_badges := 4
	var has_rows := false
	var visible_count := mini(rows.size(), max_badges)
	for i in range(visible_count):
		var row: Dictionary = rows[i]
		var label := String(row.get("label", "Tag"))
		var weight := int(row.get("weight", 0))
		var tag_key := String(row.get("tag", "")).strip_edges().to_lower()
		var icon_code := String(TAG_ICON_CODES.get(tag_key, "TG"))
		_append_tag_badge("%s %s x%d" % [icon_code, label, weight])
		has_rows = true
	if rows.size() > max_badges:
		_append_tag_badge("+%d more" % (rows.size() - max_badges))
	if not has_rows:
		_append_tag_badge("—")


func _append_tag_badge(text: String) -> void:
	var badge := PanelContainer.new()
	badge.theme_type_variation = &"BadgePanel"
	badge.custom_minimum_size = Vector2(0.0, 26.0)
	var margin := MarginContainer.new()
	margin.set("theme_override_constants/margin_left", 8)
	margin.set("theme_override_constants/margin_top", 2)
	margin.set("theme_override_constants/margin_right", 8)
	margin.set("theme_override_constants/margin_bottom", 2)
	var label := Label.new()
	label.text = text
	label.theme_type_variation = &"BodyMutedLabel"
	margin.add_child(label)
	badge.add_child(margin)
	top_tags_flow.add_child(badge)


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
		var name := _truncate_text(String(row.get("name", "Unknown")), 18)
		output.append("• %s [%s] x%d" % [name, rarity, count])
	if output.is_empty():
		return "-"
	var max_rows := 2
	if output.size() > max_rows:
		var hidden_count := output.size() - max_rows
		output.resize(max_rows)
		output.append("• +%d more" % hidden_count)
	return "\n".join(output)


func _format_contracts(value: Variant) -> String:
	if not (value is Array):
		return "None"
	var names: Array[String] = value
	if names.is_empty():
		return "None"
	if names.size() <= 2:
		var compact: Array[String] = []
		for name in names:
			compact.append(_truncate_text(String(name), 16))
		return ", ".join(compact)
	var shown: Array[String] = []
	shown.append(_truncate_text(String(names[0]), 16))
	shown.append(_truncate_text(String(names[1]), 16))
	return "%s, %s +%d" % [shown[0], shown[1], names.size() - 2]


func _format_multipliers(value: Variant) -> String:
	var multipliers: Dictionary = value if value is Dictionary else {}
	return "XP x%.2f\nRARITY x%.2f\nDROP x%.2f\nMETA x%.2f" % [
		float(multipliers.get("xp", 1.0)),
		float(multipliers.get("rarity", 1.0)),
		float(multipliers.get("drop", 1.0)),
		float(multipliers.get("meta_currency", 1.0))
	]


func _format_meta_currency(value: Variant) -> String:
	if value == null:
		return "META CURRENCY: —"
	if value is Dictionary:
		var payload: Dictionary = value
		var total := int(payload.get("total", payload.get("base", 0)))
		var multiplier := float(payload.get("multiplier", 1.0))
		return "META CURRENCY: %d (x%.2f)" % [total, multiplier]
	return "META CURRENCY: %d" % int(value)


func _truncate_text(text: String, max_chars: int) -> String:
	var source := text.strip_edges()
	if source.length() <= max_chars:
		return source
	return "%s…" % source.substr(0, max_chars)


func _on_copy_seed_pressed() -> void:
	var seed_value := int(_state.get("seed", 0))
	if seed_value <= 0:
		return
	DisplayServer.clipboard_set(str(seed_value))
	seed_copy_button.text = "Copied"
	if _copy_seed_tween != null and is_instance_valid(_copy_seed_tween):
		_copy_seed_tween.kill()
	_copy_seed_tween = create_tween()
	_copy_seed_tween.tween_interval(0.7)
	_copy_seed_tween.tween_callback(func() -> void:
		seed_copy_button.text = "Copy"
	)


func _should_play_reward_sfx() -> bool:
	var meta_variant: Variant = _state.get("meta_currency_earned", null)
	if meta_variant == null:
		return false
	if meta_variant is Dictionary:
		var meta: Dictionary = meta_variant
		return int(meta.get("total", 0)) > 0
	return int(meta_variant) > 0


func _animate_progress(target_value: float) -> void:
	if progress_bar == null:
		return
	var clamped := clampf(target_value, 0.0, 1.0)
	if _progress_tween != null and is_instance_valid(_progress_tween):
		_progress_tween.kill()
	if not UIMotionClass.is_motion_enabled():
		progress_bar.value = clamped
		return
	_progress_tween = create_tween()
	_progress_tween.set_trans(Tween.TRANS_SINE)
	_progress_tween.set_ease(Tween.EASE_OUT)
	_progress_tween.tween_property(progress_bar, "value", clamped, 0.30)


func _show_unlock_toast(names: Array[String]) -> void:
	if unlock_toast == null or unlock_toast_text == null:
		return
	unlock_toast_text.text = "UNLOCKED: %s" % ", ".join(names)
	unlock_toast.visible = true
	unlock_toast.modulate = Color(1.0, 1.0, 1.0, 0.0)
	if _unlock_toast_tween != null and is_instance_valid(_unlock_toast_tween):
		_unlock_toast_tween.kill()
	if not UIMotionClass.is_motion_enabled():
		unlock_toast.modulate.a = 1.0
		return
	_unlock_toast_tween = create_tween()
	_unlock_toast_tween.tween_property(unlock_toast, "modulate:a", 1.0, 0.14)
	_unlock_toast_tween.tween_interval(0.9)
	_unlock_toast_tween.tween_property(unlock_toast, "modulate:a", 0.0, 0.24)
	_unlock_toast_tween.finished.connect(func() -> void:
		if unlock_toast != null:
			unlock_toast.visible = false
	)
