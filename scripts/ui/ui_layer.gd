extends CanvasLayer
class_name UILayer

signal upgrade_selected(upgrade_id: String)
signal retry_requested

const FOG_SHADER := preload("res://assets/shaders/fog_scan_noise.gdshader")

@onready var root: Control = $Root
@onready var hp_label: Label = $Root/HUD/Stats/HPLabel
@onready var xp_label: Label = $Root/HUD/Stats/XPLabel
@onready var level_label: Label = $Root/HUD/Stats/LevelLabel
@onready var noise_label: Label = $Root/HUD/Stats/NoiseLabel
@onready var mode_label: Label = $Root/HUD/Stats/ModeLabel
@onready var time_label: Label = $Root/HUD/Stats/TimeLabel
@onready var kills_label: Label = $Root/HUD/Stats/KillsLabel
@onready var enemies_label: Label = $Root/HUD/Stats/EnemiesLabel

@onready var level_up_panel: Panel = $Root/LevelUpPanel
@onready var level_up_title: Label = $Root/LevelUpPanel/PanelMargin/VBox/TitleLabel
@onready var upgrade_buttons: Array[Button] = [
	$Root/LevelUpPanel/PanelMargin/VBox/Choices/UpgradeBtn1,
	$Root/LevelUpPanel/PanelMargin/VBox/Choices/UpgradeBtn2,
	$Root/LevelUpPanel/PanelMargin/VBox/Choices/UpgradeBtn3
]

@onready var game_over_panel: Panel = $Root/GameOverPanel
@onready var game_over_summary: Label = $Root/GameOverPanel/PanelMargin/VBox/SummaryLabel
@onready var retry_button: Button = $Root/GameOverPanel/PanelMargin/VBox/RetryButton

var current_options: Array = []
var fog_overlay: ColorRect
var fog_overlay_material: ShaderMaterial
var fog_overlay_allowed: bool = true


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	_create_fog_overlay()
	apply_fog_overlay_config(DataRegistry.get_fog_config())
	set_fog_overlay_enabled(bool(DataRegistry.get_fog_config().get("enabled", true)))
	level_up_panel.visible = false
	game_over_panel.visible = false

	for i in range(upgrade_buttons.size()):
		upgrade_buttons[i].pressed.connect(_on_upgrade_button_pressed.bind(i))
	retry_button.pressed.connect(func() -> void:
		retry_requested.emit()
	)


func _create_fog_overlay() -> void:
	fog_overlay = ColorRect.new()
	fog_overlay.name = "FogOverlay"
	fog_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	fog_overlay.offset_left = 0.0
	fog_overlay.offset_top = 0.0
	fog_overlay.offset_right = 0.0
	fog_overlay.offset_bottom = 0.0
	fog_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fog_overlay.color = Color(1.0, 1.0, 1.0, 1.0)

	fog_overlay_material = ShaderMaterial.new()
	fog_overlay_material.shader = FOG_SHADER
	fog_overlay.material = fog_overlay_material

	root.add_child(fog_overlay)
	root.move_child(fog_overlay, 0)


func apply_fog_overlay_config(config: Dictionary) -> void:
	if fog_overlay_material == null:
		return
	fog_overlay_allowed = bool(config.get("scanline_enabled", true))
	var tint_color := Color.from_string(String(config.get("tint_color", "#0b1a2a")), Color(0.05, 0.10, 0.16))
	fog_overlay_material.set_shader_parameter("line_density", float(config.get("scanline_density", 320.0)))
	fog_overlay_material.set_shader_parameter("line_strength", float(config.get("scanline_strength", 0.08)))
	fog_overlay_material.set_shader_parameter("noise_strength", float(config.get("noise_strength", 0.05)))
	fog_overlay_material.set_shader_parameter("tint_color", tint_color)
	fog_overlay_material.set_shader_parameter("tint_alpha", float(config.get("tint_alpha", 0.30)))
	fog_overlay_material.set_shader_parameter("pulse_speed", float(config.get("pulse_speed", 0.65)))
	fog_overlay_material.set_shader_parameter("effect_enabled", fog_overlay_allowed)
	fog_overlay.visible = fog_overlay_allowed


func set_fog_overlay_enabled(enabled: bool) -> void:
	if fog_overlay_material == null:
		return
	var final_enabled := enabled and fog_overlay_allowed
	fog_overlay_material.set_shader_parameter("effect_enabled", final_enabled)
	fog_overlay.visible = final_enabled


func update_hud(data: Dictionary) -> void:
	hp_label.text = "HP: %d / %d" % [int(round(float(data.get("hp", 0.0)))), int(round(float(data.get("max_hp", 0.0))))]
	xp_label.text = "XP: %d / %d" % [int(round(float(data.get("xp", 0.0)))), int(round(float(data.get("xp_to_next", 1.0))))]
	level_label.text = "Level: %d" % int(data.get("level", 1))
	noise_label.text = "Noise: %d [%s]" % [
		int(round(float(data.get("noise", 0.0)))),
		String(data.get("noise_tier_name", "静默"))
	]
	mode_label.text = "Attack: %s" % String(data.get("attack_mode", "AUTO"))
	time_label.text = "Time: %s" % _format_time(float(data.get("elapsed_time", 0.0)))
	kills_label.text = "Kills: %d" % int(data.get("kills", 0))
	enemies_label.text = "Enemies: %d  Revealed: %d" % [
		int(data.get("enemy_count", 0)),
		int(data.get("revealed_count", 0))
	]


func show_level_up(options: Array) -> void:
	current_options = options
	level_up_title.text = "Signal Upgrade - Choose One"
	for i in range(upgrade_buttons.size()):
		var button := upgrade_buttons[i]
		if i < current_options.size():
			var option_variant: Variant = current_options[i]
			var option: Dictionary = {}
			if option_variant is Dictionary:
				option = option_variant
			button.disabled = false
			button.visible = true
			button.text = "%s [%s]\n%s" % [
				String(option.get("name", "Unknown")),
				String(option.get("rarity", "common")).to_upper(),
				String(option.get("description", ""))
			]
		else:
			button.disabled = true
			button.visible = false

	game_over_panel.visible = false
	level_up_panel.visible = true


func hide_level_up() -> void:
	level_up_panel.visible = false
	current_options.clear()


func show_game_over(summary: Dictionary) -> void:
	var lines := [
		"Run Ended",
		"Time: %s" % _format_time(float(summary.get("time", 0.0))),
		"Kills: %d" % int(summary.get("kills", 0)),
		"Level: %d" % int(summary.get("level", 1)),
		"Seed: %d" % int(summary.get("seed", 0))
	]
	game_over_summary.text = "\n".join(lines)
	level_up_panel.visible = false
	game_over_panel.visible = true


func on_game_state_changed(state: String) -> void:
	if state == "playing":
		level_up_panel.visible = false
		game_over_panel.visible = false
	elif state == "level_up":
		game_over_panel.visible = false


func _on_upgrade_button_pressed(index: int) -> void:
	if index < 0 or index >= current_options.size():
		return
	var upgrade_id := String(current_options[index].get("id", ""))
	if upgrade_id.is_empty():
		return
	upgrade_selected.emit(upgrade_id)


func _format_time(total_seconds: float) -> String:
	var s := int(floor(total_seconds))
	var minutes := s / 60
	var seconds := s % 60
	return "%02d:%02d" % [minutes, seconds]
