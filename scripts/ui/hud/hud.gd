extends Control
class_name RunHUD

const HUDStateClass := preload("res://scripts/ui/hud/hud_state.gd")
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

@onready var noise_panel: PanelContainer = $TopNoise/NoisePanel
@onready var noise_meter: VBoxContainer = $TopNoise/NoisePanel/Margin/VBox/NoiseMeter
@onready var noise_value_label: Label = $TopNoise/NoisePanel/Margin/VBox/Header/NoiseReadout/NoiseValue
@onready var tier_index_label: Label = $TopNoise/NoisePanel/Margin/VBox/Header/TierIndex
@onready var threshold_bar: ProgressBar = $TopNoise/NoisePanel/Margin/VBox/ThresholdBar
@onready var threshold_label: Label = $TopNoise/NoisePanel/Margin/VBox/ThresholdLabel
@onready var threat_flash_label: Label = $TopNoise/NoisePanel/Margin/VBox/ThreatFlash

@onready var hp_bar: ProgressBar = $LeftSurvival/SurvivalPanel/Margin/VBox/HPBar
@onready var hp_value_label: Label = $LeftSurvival/SurvivalPanel/Margin/VBox/HPValue
@onready var level_badge: PanelContainer = $LeftSurvival/SurvivalPanel/Margin/VBox/Badges/LevelBadge
@onready var kills_badge: PanelContainer = $LeftSurvival/SurvivalPanel/Margin/VBox/Badges/KillsBadge
@onready var time_badge: PanelContainer = $LeftSurvival/SurvivalPanel/Margin/VBox/Badges/TimeBadge
@onready var enemy_info_label: Label = $LeftSurvival/SurvivalPanel/Margin/VBox/EnemyInfo

@onready var weapon_name_label: Label = $RightBuild/BuildCard/BuildMargin/BuildVBox/WeaponRow/WeaponName
@onready var weapon_icon: TextureRect = $RightBuild/BuildCard/BuildMargin/BuildVBox/WeaponRow/WeaponIcon
@onready var key_tags_label: Label = $RightBuild/BuildCard/BuildMargin/BuildVBox/KeyTags

@onready var sonar_block: VBoxContainer = $BottomActions/ActionPanel/Margin/Row/SonarBlock
@onready var sonar_icon: TextureRect = $BottomActions/ActionPanel/Margin/Row/SonarBlock/SonarHeader/SonarIcon
@onready var sonar_bar: ProgressBar = $BottomActions/ActionPanel/Margin/Row/SonarBlock/SonarBar
@onready var sonar_hint_label: Label = $BottomActions/ActionPanel/Margin/Row/SonarBlock/SonarHint
@onready var dash_block: VBoxContainer = $BottomActions/ActionPanel/Margin/Row/DashBlock
@onready var dash_icon: TextureRect = $BottomActions/ActionPanel/Margin/Row/DashBlock/DashHeader/DashIcon
@onready var dash_bar: ProgressBar = $BottomActions/ActionPanel/Margin/Row/DashBlock/DashBar
@onready var dash_hint_label: Label = $BottomActions/ActionPanel/Margin/Row/DashBlock/DashHint
@onready var contract_status_label: Label = $BottomActions/ActionPanel/Margin/Row/ContractStatusLabel

@onready var damage_flash: ColorRect = $DamageFlash

var _last_tier_id: String = ""
var _last_hp_ratio: float = 1.0
var _last_sonar_ping_sequence: int = 0
var _tier_tween: Tween
var _threat_tween: Tween
var _damage_tween: Tween
var _sonar_tween: Tween
var _intro_played: bool = false


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	threat_flash_label.visible = false
	threshold_bar.min_value = 0.0
	threshold_bar.max_value = 1.0
	threshold_bar.value = 0.0
	sonar_bar.min_value = 0.0
	dash_bar.min_value = 0.0
	sonar_hint_label.text = "Ready"
	contract_status_label.visible = false
	if sonar_icon != null:
		sonar_icon.texture = IconRegistry.get_skill_icon("sonar")
	if dash_icon != null:
		dash_icon.texture = IconRegistry.get_skill_icon("dash")
	if noise_meter != null:
		var title := noise_meter.get_node_or_null("Title") as Label
		var tier := noise_meter.get_node_or_null("Tier") as Label
		if title != null:
			title.visible = false
		if tier != null:
			tier.visible = false
	visibility_changed.connect(_on_visibility_changed)


func apply_hud_dict(data: Dictionary) -> void:
	apply_state(HUDStateClass.from_dict(data))


func apply_state(state) -> void:
	if state == null:
		return

	var hp_current := float(state.get("hp_current", 0.0))
	var hp_max := maxf(1.0, float(state.get("hp_max", 100.0)))
	var hp_ratio := clampf(hp_current / hp_max, 0.0, 1.0)
	var level := int(state.get("level", 1))
	var kills := int(state.get("kills", 0))
	var elapsed_time := float(state.get("elapsed_time", 0.0))
	var enemy_count := int(state.get("enemy_count", 0))
	var revealed_count := int(state.get("revealed_count", 0))
	var noise_value := float(state.get("noise_value", 0.0))
	var noise_min := float(state.get("noise_min", 0.0))
	var noise_max := maxf(noise_min + 1.0, float(state.get("noise_max", 100.0)))
	var noise_tier_name := String(state.get("noise_tier_name", "Silent"))
	var noise_tier_id := String(state.get("noise_tier_id", "silent"))
	var noise_tier_color := Color(state.get("noise_tier_color", Color(0.45, 0.9, 1.0, 1.0)))
	var weapon_id := String(state.get("weapon_id", ""))
	var weapon_name := String(state.get("weapon_name", "--"))
	var build_tags: Array[String] = HUDStateClass._string_array(state.get("build_tags", []))
	var weapon_tags: Array[String] = HUDStateClass._string_array(state.get("weapon_tags", []))
	var sonar_cd_remaining := float(state.get("sonar_cd_remaining", 0.0))
	var sonar_cd_total := float(state.get("sonar_cd_total", 0.0))
	var sonar_feedback_timer := float(state.get("sonar_feedback_timer", 0.0))
	var sonar_ping_count := int(state.get("sonar_ping_count", 0))
	var sonar_ping_sequence := int(state.get("sonar_ping_sequence", 0))
	var dash_cd_remaining := float(state.get("dash_cd_remaining", 0.0))
	var dash_cd_total := float(state.get("dash_cd_total", 0.0))
	var contract_dash_disabled := bool(state.get("contract_dash_disabled", false))

	hp_bar.min_value = 0.0
	hp_bar.max_value = hp_max
	hp_bar.value = hp_current
	hp_value_label.text = "HP %d/%d" % [int(round(hp_current)), int(round(hp_max))]
	if hp_ratio < 0.35:
		hp_value_label.modulate = Color(1.0, 0.74, 0.74, 1.0)
	else:
		hp_value_label.modulate = Color(1.0, 1.0, 1.0, 1.0)

	_set_badge(level_badge, "Lvl", str(level))
	_set_badge(kills_badge, "Kills", str(kills))
	_set_badge(time_badge, "Time", _format_time(elapsed_time))
	enemy_info_label.text = "Enemies %d | Revealed %d" % [enemy_count, revealed_count]

	noise_value_label.text = "%d" % int(round(noise_value))
	var tier_index := _resolve_tier_index(state)
	tier_index_label.text = "TIER %d · %s" % [maxi(0, tier_index), noise_tier_name]
	tier_index_label.modulate = Color(1.0, 1.0, 1.0, 1.0).lerp(noise_tier_color, 0.24)
	if noise_meter != null and noise_meter.has_method("update_meter"):
		noise_meter.call("update_meter", noise_value, noise_min, noise_max, noise_tier_name, noise_tier_color)
	_update_threshold_progress(state, tier_index)

	if noise_tier_id != _last_tier_id:
		_play_tier_change_feedback(tier_index, noise_tier_color)
		_last_tier_id = noise_tier_id

	weapon_name_label.text = "Weapon: %s" % weapon_name
	if weapon_icon != null:
		weapon_icon.texture = IconRegistry.get_weapon_icon(weapon_id)
	var tags: Array[String] = build_tags if not build_tags.is_empty() else weapon_tags
	_update_key_tags(tags)

	_update_sonar_block(sonar_cd_remaining, sonar_cd_total, sonar_feedback_timer, sonar_ping_count, sonar_ping_sequence)

	if contract_dash_disabled:
		dash_block.visible = true
		dash_bar.min_value = 0.0
		dash_bar.max_value = 1.0
		dash_bar.value = 0.0
		dash_hint_label.text = "Disabled by Contract"
		contract_status_label.visible = true
		contract_status_label.text = "Dash Disabled"
	else:
		_update_cooldown_block(dash_block, dash_bar, dash_hint_label, dash_cd_remaining, dash_cd_total, "Space Dash")
		contract_status_label.visible = false

	_update_damage_feedback(hp_ratio)


func get_contract_status_label() -> Label:
	return contract_status_label


func get_debug_snapshot() -> Dictionary:
	return {
		"tier_id": _last_tier_id,
		"tier_text": tier_index_label.text,
		"noise_value": noise_value_label.text,
		"hp_text": hp_value_label.text,
		"hp_ratio": clampf(hp_bar.value / maxf(1.0, hp_bar.max_value), 0.0, 1.0),
		"sonar_hint": sonar_hint_label.text,
		"sonar_ping_sequence": _last_sonar_ping_sequence,
		"dash_hint": dash_hint_label.text,
		"contract_visible": contract_status_label.visible
	}


func _update_threshold_progress(state, tier_index: int) -> void:
	var tiers := _get_noise_tiers()
	var current_min: float = float(state.get("noise_min", 0.0))
	var next_min: float = float(state.get("noise_max", 100.0))
	var noise_value := float(state.get("noise_value", 0.0))
	if tier_index >= 0 and tier_index < tiers.size():
		var current_tier_variant: Variant = tiers[tier_index]
		if current_tier_variant is Dictionary:
			var current_tier: Dictionary = current_tier_variant
			current_min = float(current_tier.get("min", current_min))
	if tier_index + 1 >= 0 and tier_index + 1 < tiers.size():
		var next_tier_variant: Variant = tiers[tier_index + 1]
		if next_tier_variant is Dictionary:
			var next_tier: Dictionary = next_tier_variant
			next_min = float(next_tier.get("min", next_min))
	else:
		next_min = float(state.get("noise_max", 100.0))

	if next_min <= current_min + 0.01:
		threshold_bar.value = 1.0
		threshold_label.text = "Maximum threat tier reached"
		return

	var progress := clampf((noise_value - current_min) / (next_min - current_min), 0.0, 1.0)
	threshold_bar.value = progress
	if tier_index + 1 < tiers.size():
		threshold_label.text = "Next tier at %.0f (%.0f%%)" % [next_min, progress * 100.0]
	else:
		threshold_label.text = "Tier stable (%.0f%%)" % [progress * 100.0]


func _update_key_tags(tags: Array[String]) -> void:
	var parts: Array[String] = []
	for i in range(mini(4, tags.size())):
		var tag := String(tags[i]).strip_edges().to_lower()
		var icon_code := String(TAG_ICON_CODES.get(tag, "TG"))
		parts.append("[%s %s]" % [icon_code, tag.capitalize()])
	key_tags_label.text = "Key tags: %s" % (" ".join(parts) if not parts.is_empty() else "-")


func _update_cooldown_block(block: VBoxContainer, bar: ProgressBar, hint: Label, remaining: float, total: float, action_name: String) -> void:
	if total <= 0.01:
		block.visible = false
		return
	block.visible = true
	bar.max_value = total
	bar.value = clampf(total - remaining, 0.0, total)
	if remaining <= 0.01:
		hint.text = ""
	else:
		hint.text = "(%.1fs)" % remaining


func _update_sonar_block(
	remaining: float,
	total: float,
	feedback_timer: float,
	ping_count: int,
	ping_sequence: int
) -> void:
	_update_cooldown_block(sonar_block, sonar_bar, sonar_hint_label, remaining, total, "Q Sonar")
	if ping_sequence > _last_sonar_ping_sequence:
		_last_sonar_ping_sequence = ping_sequence
		_play_sonar_feedback_pulse()
	if total <= 0.01:
		return
	if feedback_timer > 0.0:
		sonar_hint_label.text = "Ping: %d contact%s" % [ping_count, "" if ping_count == 1 else "s"]
		return
	if remaining <= 0.01:
		sonar_hint_label.text = "Ready"
	else:
		sonar_hint_label.text = "(%.1fs)" % remaining


func _play_sonar_feedback_pulse() -> void:
	if _sonar_tween != null and is_instance_valid(_sonar_tween):
		_sonar_tween.kill()
	if not UIMotionClass.is_motion_enabled():
		return
	sonar_block.scale = Vector2.ONE
	sonar_bar.modulate = Color(0.58, 0.96, 1.0, 1.0)
	_sonar_tween = create_tween()
	_sonar_tween.tween_property(sonar_block, "scale", Vector2(1.02, 1.02), 0.08)
	_sonar_tween.parallel().tween_property(sonar_bar, "modulate", Color(0.80, 1.0, 1.0, 1.0), 0.08)
	_sonar_tween.tween_property(sonar_block, "scale", Vector2.ONE, 0.10)
	_sonar_tween.parallel().tween_property(sonar_bar, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.12)


func _play_tier_change_feedback(tier_index: int, tier_color: Color) -> void:
	UISfx.play_tier_up()
	threat_flash_label.text = "THREAT TIER %d" % maxi(0, tier_index)
	threat_flash_label.modulate = Color(1.0, 1.0, 1.0, 1.0).lerp(tier_color, 0.30)
	threat_flash_label.visible = true
	if _tier_tween != null and is_instance_valid(_tier_tween):
		_tier_tween.kill()
	if _threat_tween != null and is_instance_valid(_threat_tween):
		_threat_tween.kill()

	var pulse_scale := 1.03 if UIMotionClass.is_motion_enabled() else 1.0
	_tier_tween = create_tween()
	_tier_tween.tween_property(noise_panel, "scale", Vector2(pulse_scale, pulse_scale), 0.07)
	_tier_tween.tween_property(noise_panel, "scale", Vector2.ONE, 0.10)

	_threat_tween = create_tween()
	threat_flash_label.modulate.a = 1.0
	_threat_tween.tween_interval(0.12)
	_threat_tween.tween_property(threat_flash_label, "modulate:a", 0.0, 0.18)
	_threat_tween.finished.connect(func() -> void:
		threat_flash_label.visible = false
	)


func _update_damage_feedback(current_ratio: float) -> void:
	var low_health_alpha := clampf((0.34 - current_ratio) * 0.30, 0.0, 0.10)
	var hit_alpha := 0.0
	if current_ratio + 0.01 < _last_hp_ratio:
		hit_alpha = 0.14
	if _damage_tween != null and is_instance_valid(_damage_tween):
		_damage_tween.kill()
	if hit_alpha > 0.0 and UIMotionClass.is_motion_enabled():
		damage_flash.color.a = hit_alpha
		_damage_tween = create_tween()
		_damage_tween.tween_property(damage_flash, "color:a", low_health_alpha, 0.16)
	else:
		damage_flash.color.a = low_health_alpha
	_last_hp_ratio = current_ratio


func _resolve_tier_index(state) -> int:
	var tiers := _get_noise_tiers()
	var noise_tier_id := String(state.get("noise_tier_id", "silent"))
	var noise_value := float(state.get("noise_value", 0.0))
	var noise_min := float(state.get("noise_min", 0.0))
	var noise_max := float(state.get("noise_max", 100.0))
	for i in range(tiers.size()):
		var tier_variant: Variant = tiers[i]
		if not (tier_variant is Dictionary):
			continue
		var tier: Dictionary = tier_variant
		if String(tier.get("id", "")) == noise_tier_id:
			return i
		var min_value := float(tier.get("min", noise_min))
		var max_value := float(tier.get("max", noise_max))
		if noise_value >= min_value and noise_value < max_value:
			return i
	return 0


func _get_noise_tiers() -> Array:
	if DataRegistry == null:
		return []
	if not DataRegistry.has_method("get_noise_config"):
		return []
	var noise_config: Dictionary = DataRegistry.get_noise_config()
	var tiers_variant: Variant = noise_config.get("tiers", [])
	if tiers_variant is Array:
		return (tiers_variant as Array)
	return []


func _format_time(total_seconds: float) -> String:
	var s := int(floor(total_seconds))
	var minutes := s / 60
	var seconds := s % 60
	return "%02d:%02d" % [minutes, seconds]


func _set_badge(badge: PanelContainer, label_text: String, value_text: String) -> void:
	if badge == null:
		return
	if badge.has_method("set_badge"):
		badge.call("set_badge", label_text, value_text)


func _on_visibility_changed() -> void:
	if not visible:
		_intro_played = false
		return
	if _intro_played:
		return
	_intro_played = true
	UIMotionClass.panel_pop_in(noise_panel, 0.14, 8.0)
	UIMotionClass.panel_pop_in($LeftSurvival/SurvivalPanel, 0.15, 8.0)
	UIMotionClass.panel_pop_in($RightBuild/BuildCard, 0.16, 8.0)
	UIMotionClass.panel_pop_in($BottomActions/ActionPanel, 0.17, 8.0)
