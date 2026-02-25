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
const WEAPON_ICON_ANIM_SEC := 0.20

@onready var backdrop_rect: ColorRect = $Backdrop
@onready var title_label: Label = $Margin/VBox/Header/TitleGroup/Title
@onready var subtitle_label: Label = $Margin/VBox/Header/TitleGroup/Subtitle
@onready var seed_label: Label = $Margin/VBox/Header/SeedBox/Seed
@onready var seed_copy_button: Button = $Margin/VBox/Header/SeedBox/CopySeedButton
@onready var unlock_toast: PanelContainer = $Margin/VBox/UnlockToast
@onready var unlock_toast_text: Label = $Margin/VBox/UnlockToast/UnlockToastMargin/UnlockToastText

@onready var stats_title_label: Label = $Margin/VBox/Columns/LeftColumn/StatsCard/Margin/Content/Title
@onready var time_value: Label = $Margin/VBox/Columns/LeftColumn/StatsCard/Margin/Content/HeroValues/TimeValue
@onready var kills_value: Label = $Margin/VBox/Columns/LeftColumn/StatsCard/Margin/Content/HeroValues/KillsValue
@onready var time_unit_label: Label = $Margin/VBox/Columns/LeftColumn/StatsCard/Margin/Content/HeroUnits/TimeUnit
@onready var kills_unit_label: Label = $Margin/VBox/Columns/LeftColumn/StatsCard/Margin/Content/HeroUnits/KillsUnit
@onready var level_badge: PanelContainer = $Margin/VBox/Columns/LeftColumn/StatsCard/Margin/Content/StatsBadges/LevelBadge
@onready var noise_badge: PanelContainer = $Margin/VBox/Columns/LeftColumn/StatsCard/Margin/Content/StatsBadges/NoiseBadge
@onready var enemies_badge: PanelContainer = $Margin/VBox/Columns/LeftColumn/StatsCard/Margin/Content/StatsBadges/EnemiesBadge
@onready var revealed_badge: PanelContainer = $Margin/VBox/Columns/LeftColumn/StatsCard/Margin/Content/StatsBadges/RevealedBadge
@onready var boss_progress_label: Label = $Margin/VBox/Columns/LeftColumn/StatsCard/Margin/Content/BossProgress

@onready var build_title_label: Label = $Margin/VBox/Columns/RightColumn/BuildCard/Margin/Content/Title
@onready var weapon_icon: TextureRect = $Margin/VBox/Columns/RightColumn/BuildCard/Margin/Content/WeaponRow/WeaponIcon
@onready var weapon_label: Label = $Margin/VBox/Columns/RightColumn/BuildCard/Margin/Content/WeaponRow/WeaponLabel
@onready var top_tags_title_label: Label = $Margin/VBox/Columns/RightColumn/BuildCard/Margin/Content/TopTagsTitle
@onready var top_tags_flow: HFlowContainer = $Margin/VBox/Columns/RightColumn/BuildCard/Margin/Content/TopTagsFlow
@onready var upgrades_label: Label = $Margin/VBox/Columns/RightColumn/BuildCard/Margin/Content/UpgradesLabel
@onready var map_contracts_label: Label = $Margin/VBox/Columns/RightColumn/BuildCard/Margin/Content/MapContractsLabel
@onready var multipliers_label: Label = $Margin/VBox/Columns/RightColumn/BuildCard/Margin/Content/MultipliersLabel
@onready var meta_currency_label: Label = $Margin/VBox/Columns/RightColumn/BuildCard/Margin/Content/MetaCurrencyLabel

@onready var progress_title_label: Label = $Margin/VBox/Columns/RightColumn/ProgressCard/Margin/Content/Title
@onready var progress_target_label: Label = $Margin/VBox/Columns/RightColumn/ProgressCard/Margin/Content/ProgressTarget
@onready var progress_bar: ProgressBar = $Margin/VBox/Columns/RightColumn/ProgressCard/Margin/Content/ProgressBar
@onready var progress_detail_label: Label = $Margin/VBox/Columns/RightColumn/ProgressCard/Margin/Content/ProgressDetail
@onready var newly_unlocked_label: Label = $Margin/VBox/Columns/RightColumn/ProgressCard/Margin/Content/NewlyUnlocked
@onready var progress_card: PanelContainer = $Margin/VBox/Columns/RightColumn/ProgressCard

@onready var retry_button: Button = $Margin/VBox/CTA/RetryButton
@onready var menu_button: Button = $Margin/VBox/CTA/MenuButton
@onready var key_hint_label: Label = $Margin/VBox/KeyHint

var _state: Dictionary = {}
var _rendered_key_fields: int = 0
var _copy_seed_tween: Tween
var _progress_tween: Tween
var _unlock_toast_tween: Tween
var _backdrop_material: ShaderMaterial
var _backdrop_time: float = 0.0
var _weapon_icon_frames: Array[Texture2D] = []
var _weapon_icon_timer: float = 0.0
var _weapon_icon_frame_idx: int = 0


func _ready() -> void:
	visible = false
	if Localization != null and Localization.has_signal("language_changed"):
		Localization.language_changed.connect(_on_language_changed)
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
		_tick_weapon_icon(delta)
		return
	_backdrop_time += delta
	_backdrop_material.set_shader_parameter("time_sec", _backdrop_time)
	_tick_weapon_icon(delta)


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
	title_label.text = _t("summary.title")
	subtitle_label.text = _t("summary.subtitle")
	stats_title_label.text = _t("summary.run_stats")
	time_unit_label.text = _t("summary.survival_unit")
	kills_unit_label.text = _t("summary.kills_unit")
	build_title_label.text = _t("summary.build_recap")
	top_tags_title_label.text = _t("summary.top_tags_title")
	progress_title_label.text = _t("summary.progress_title")
	seed_label.text = _t("summary.seed", {"value": int(_state.get("seed", 0))})
	seed_copy_button.text = _t("summary.copy")
	seed_copy_button.disabled = int(_state.get("seed", 0)) <= 0
	retry_button.text = _t("summary.retry")
	menu_button.text = _t("summary.menu")
	key_hint_label.text = _t("summary.input_hint")

	time_value.text = RunSummaryStateClass.format_time(float(_state.get("time_survived_sec", 0.0)))
	kills_value.text = str(int(_state.get("kills", 0)))
	_set_badge(level_badge, _t("summary.badge.level"), str(int(_state.get("level", 1))))
	_set_badge(noise_badge, _t("summary.badge.noise"), String(_state.get("noise_peak_tier", "-")))
	_set_badge(enemies_badge, _t("summary.badge.enemies"), str(int(_state.get("enemies_seen", 0))))
	_set_badge(revealed_badge, _t("summary.badge.revealed"), str(int(_state.get("revealed_count", 0))))
	_rendered_key_fields += 4

	var boss_progress := String(_state.get("boss_progress", "")).strip_edges()
	var boss_normalized := boss_progress.to_lower()
	var hide_boss_progress := boss_normalized.is_empty() or boss_normalized == "idle" or boss_normalized == "none"
	boss_progress_label.visible = not hide_boss_progress
	if boss_progress_label.visible:
		boss_progress_label.text = _t("summary.boss", {"value": boss_progress.capitalize()})
		_rendered_key_fields += 1

	weapon_label.text = _t("summary.weapon", {"value": _resolve_weapon_name()})
	if weapon_icon != null:
		_set_weapon_icon_frames(IconRegistry.get_weapon_icon_frames(String(_state.get("weapon_id", ""))))
	if not _resolve_weapon_name().strip_edges().is_empty():
		_rendered_key_fields += 1

	_render_top_tag_badges(_state.get("top_tags", []))
	upgrades_label.text = _t("summary.chosen", {"value": _format_upgrades(_state.get("chosen_upgrades", []))})
	map_contracts_label.text = _t("summary.map_contracts", {
		"map": _resolve_map_name(),
		"contracts": _format_contracts(_resolve_contract_names())
	})
	multipliers_label.text = _format_multipliers(_state.get("multipliers", {}))
	meta_currency_label.text = _format_meta_currency(_state.get("meta_currency_earned", null))
	_rendered_key_fields += 3

	var unlock_rows: Array = _state.get("unlock_progress", [])
	if unlock_rows.is_empty():
		progress_target_label.text = _t("summary.progress_all")
		_animate_progress(1.0)
		progress_detail_label.text = _t("summary.progress_none")
	else:
		var row_variant: Variant = unlock_rows[0]
		if row_variant is Dictionary:
			var row: Dictionary = row_variant
			progress_target_label.text = _t("summary.progress_next", {"value": String(row.get("name", _t("upgrade.unknown")))})
			_animate_progress(clampf(float(row.get("ratio", 0.0)), 0.0, 1.0))
			var display_text := String(row.get("display", "")).strip_edges()
			var value_text := String(row.get("text", "")).strip_edges()
			progress_detail_label.text = _t("summary.progress_detail", {"display": display_text, "text": value_text})
			_rendered_key_fields += 1

	var newly_unlocked: Array[String] = _state.get("newly_unlocked_names", [])
	if newly_unlocked.is_empty():
		newly_unlocked_label.text = _t("summary.new_unlocks_none")
	else:
		newly_unlocked_label.text = _t("summary.new_unlocks", {"value": ", ".join(newly_unlocked)})
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
		_append_tag_badge(_t("build.none"))
		return
	var rows: Array[Dictionary] = []
	for row_variant in (value as Array):
		if not (row_variant is Dictionary):
			continue
		var row: Dictionary = row_variant
		rows.append(row)
	if rows.is_empty():
		_append_tag_badge(_t("build.none"))
		return

	var max_badges := 4
	var has_rows := false
	var visible_count := mini(rows.size(), max_badges)
	for i in range(visible_count):
		var row: Dictionary = rows[i]
		var tag_key := String(row.get("tag", "")).strip_edges().to_lower()
		var label := _tag_name(tag_key) if not tag_key.is_empty() else String(row.get("label", "Tag"))
		var weight := int(row.get("weight", 0))
		var icon_code := String(TAG_ICON_CODES.get(tag_key, "TG"))
		_append_tag_badge("%s %s x%d" % [icon_code, label, weight])
		has_rows = true
	if rows.size() > max_badges:
		_append_tag_badge(_t("build.more", {"count": rows.size() - max_badges}))
	if not has_rows:
		_append_tag_badge(_t("build.none"))


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


func _set_weapon_icon_frames(frames: Array[Texture2D]) -> void:
	if weapon_icon == null:
		return
	if frames.is_empty():
		_weapon_icon_frames.clear()
		weapon_icon.texture = null
		return
	var changed := _weapon_icon_frames.size() != frames.size()
	if not changed:
		for i in range(frames.size()):
			if _weapon_icon_frames[i] != frames[i]:
				changed = true
				break
	if changed:
		_weapon_icon_frames = frames
		_weapon_icon_timer = 0.0
		_weapon_icon_frame_idx = 0
		weapon_icon.texture = _weapon_icon_frames[0]


func _tick_weapon_icon(delta: float) -> void:
	if weapon_icon == null or _weapon_icon_frames.size() <= 1:
		return
	_weapon_icon_timer += delta
	if _weapon_icon_timer < WEAPON_ICON_ANIM_SEC:
		return
	_weapon_icon_timer = 0.0
	_weapon_icon_frame_idx = (_weapon_icon_frame_idx + 1) % _weapon_icon_frames.size()
	weapon_icon.texture = _weapon_icon_frames[_weapon_icon_frame_idx]


func _format_upgrades(value: Variant) -> String:
	if not (value is Array):
		return "-"
	var output: Array[String] = []
	for row_variant in (value as Array):
		if not (row_variant is Dictionary):
			continue
		var row: Dictionary = row_variant
		var rarity := _rarity_name(String(row.get("rarity", "common")))
		var count := int(row.get("count", 1))
		var name := _truncate_text(_localized_upgrade_name(row), 18)
		output.append("• %s [%s] x%d" % [name, rarity, count])
	if output.is_empty():
		return "-"
	var max_rows := 2
	if output.size() > max_rows:
		var hidden_count := output.size() - max_rows
		output.resize(max_rows)
		output.append(_t("summary.more_items", {"count": hidden_count}))
	return "\n".join(output)


func _format_contracts(value: Variant) -> String:
	if not (value is Array):
		return _t("summary.contracts_none")
	var names: Array[String] = value
	if names.is_empty():
		return _t("summary.contracts_none")
	if names.size() <= 2:
		var compact: Array[String] = []
		for name in names:
			compact.append(_truncate_text(String(name), 16))
		return ", ".join(compact)
	var shown: Array[String] = []
	shown.append(_truncate_text(String(names[0]), 16))
	shown.append(_truncate_text(String(names[1]), 16))
	return "%s, %s %s" % [shown[0], shown[1], _t("build.more", {"count": names.size() - 2})]


func _resolve_weapon_name() -> String:
	var weapon_id := String(_state.get("weapon_id", "")).strip_edges()
	if not weapon_id.is_empty():
		var weapon := DataRegistry.get_weapon(weapon_id)
		if not weapon.is_empty():
			return String(weapon.get("name", weapon_id))
	return String(_state.get("weapon_name", "--"))


func _resolve_map_name() -> String:
	var map_id := String(_state.get("map_id", "")).strip_edges()
	if not map_id.is_empty():
		var map_row := DataRegistry.get_map(map_id)
		if not map_row.is_empty():
			return String(map_row.get("name", map_id))
	return String(_state.get("map_name", "-"))


func _resolve_contract_names() -> Array[String]:
	var contract_ids_variant: Variant = _state.get("contract_ids", [])
	if contract_ids_variant is Array and not (contract_ids_variant as Array).is_empty():
		var names_from_ids: Array[String] = []
		for contract_id_variant in (contract_ids_variant as Array):
			var contract_id := String(contract_id_variant).strip_edges()
			if contract_id.is_empty():
				continue
			var contract := DataRegistry.get_contract(contract_id)
			names_from_ids.append(String(contract.get("name", contract_id)))
		return names_from_ids
	var names_variant: Variant = _state.get("contract_names", [])
	if names_variant is Array:
		var fallback_names: Array[String] = []
		for name_variant in (names_variant as Array):
			fallback_names.append(String(name_variant))
		return fallback_names
	return []


func _localized_upgrade_name(row: Dictionary) -> String:
	var upgrade_id := String(row.get("id", "")).strip_edges()
	if not upgrade_id.is_empty():
		var upgrade := DataRegistry.get_upgrade(upgrade_id)
		if not upgrade.is_empty():
			return String(upgrade.get("name", upgrade_id))
	return String(row.get("name", _t("upgrade.unknown")))


func _format_multipliers(value: Variant) -> String:
	var multipliers: Dictionary = value if value is Dictionary else {}
	return _t("summary.mult", {
		"xp": "%.2f" % float(multipliers.get("xp", 1.0)),
		"rarity": "%.2f" % float(multipliers.get("rarity", 1.0)),
		"drop": "%.2f" % float(multipliers.get("drop", 1.0)),
		"meta": "%.2f" % float(multipliers.get("meta_currency", 1.0))
	})


func _format_meta_currency(value: Variant) -> String:
	if value == null:
		return _t("summary.meta_currency", {"total": "—", "mult": "1.00"})
	if value is Dictionary:
		var payload: Dictionary = value
		var total := int(payload.get("total", payload.get("base", 0)))
		var multiplier := float(payload.get("multiplier", 1.0))
		return _t("summary.meta_currency", {"total": total, "mult": "%.2f" % multiplier})
	return _t("summary.meta_currency", {"total": int(value), "mult": "1.00"})


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
	seed_copy_button.text = _t("summary.copy_done")
	if _copy_seed_tween != null and is_instance_valid(_copy_seed_tween):
		_copy_seed_tween.kill()
	_copy_seed_tween = create_tween()
	_copy_seed_tween.tween_interval(0.7)
	_copy_seed_tween.tween_callback(func() -> void:
		seed_copy_button.text = _t("summary.copy")
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
	unlock_toast_text.text = _t("summary.new_unlocks", {"value": ", ".join(names)})
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


func _on_language_changed(_language_code: String) -> void:
	if _state.is_empty():
		return
	_render()


func _t(key: String, args: Dictionary = {}) -> String:
	if Localization == null or not Localization.has_method("t"):
		return key
	return String(Localization.call("t", key, args))


func _rarity_name(rarity: String) -> String:
	if Localization == null or not Localization.has_method("rarity_name"):
		return rarity.capitalize()
	return String(Localization.call("rarity_name", rarity))


func _tag_name(tag: String) -> String:
	if Localization == null or not Localization.has_method("tag_name"):
		return tag.capitalize()
	return String(Localization.call("tag_name", tag))
