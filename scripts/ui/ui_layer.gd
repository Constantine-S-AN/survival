extends CanvasLayer
class_name UILayer

signal upgrade_selected(upgrade_id: String)
signal retry_requested

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


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	level_up_panel.visible = false
	game_over_panel.visible = false

	for i in range(upgrade_buttons.size()):
		upgrade_buttons[i].pressed.connect(_on_upgrade_button_pressed.bind(i))
	retry_button.pressed.connect(func() -> void:
		retry_requested.emit()
	)


func update_hud(data: Dictionary) -> void:
	hp_label.text = "HP: %d / %d" % [int(round(float(data.get("hp", 0.0)))), int(round(float(data.get("max_hp", 0.0))))]
	xp_label.text = "XP: %d / %d" % [int(round(float(data.get("xp", 0.0)))), int(round(float(data.get("xp_to_next", 1.0))))]
	level_label.text = "Level: %d" % int(data.get("level", 1))
	noise_label.text = "Noise: %d" % int(round(float(data.get("noise", 0.0))))
	mode_label.text = "Attack: %s" % String(data.get("attack_mode", "AUTO"))
	time_label.text = "Time: %s" % _format_time(float(data.get("elapsed_time", 0.0)))
	kills_label.text = "Kills: %d" % int(data.get("kills", 0))
	enemies_label.text = "Enemies: %d" % int(data.get("enemy_count", 0))


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
