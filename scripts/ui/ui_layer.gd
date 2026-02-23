extends CanvasLayer
class_name UILayer

signal upgrade_selected(upgrade_id: String)
signal retry_requested
signal main_menu_start_requested
signal start_run_requested(character_id: String)
signal character_select_back_requested
signal map_select_start_requested(map_id: String)
signal map_select_back_requested
signal contract_select_start_requested(contract_ids: Array[String])
signal contract_select_back_requested
signal run_setup_start_requested(run_config: Dictionary)
signal unlock_all_debug_requested

const FOG_SHADER := preload("res://assets/shaders/fog_scan_noise.gdshader")
const NEON_THEME := preload("res://ui/theme/NeonTheme.tres")
const MAIN_MENU_SCENE := preload("res://scenes/ui/menu/MainMenu.tscn")
const RUN_SETUP_SCENE := preload("res://scenes/ui/run_setup/RunSetup.tscn")
const UPGRADE_SELECT_SCENE := preload("res://scenes/ui/upgrade/UpgradeSelect.tscn")
const CHARACTER_SELECT_SCENE := preload("res://scenes/ui/CharacterSelect.tscn")
const MAP_SELECT_SCENE := preload("res://scenes/ui/MapSelect.tscn")
const CONTRACT_SELECT_SCENE := preload("res://scenes/ui/ContractSelect.tscn")
const TAG_DISPLAY_NAMES: Dictionary = {
	"sonar": "Sonar",
	"silence": "Silence",
	"heat": "Heat",
	"crit": "Crit",
	"pierce": "Pierce",
	"chain": "Chain",
	"aoe": "AOE",
	"pickup": "Pickup",
	"shield": "Shield",
	"speed": "Speed",
	"trap": "Trap",
	"control": "Control",
	"summon": "Summon",
	"economy": "Economy",
	"damage": "Damage",
	"weapon": "Weapon",
	"tempo": "Tempo",
	"noise": "Noise",
	"mobility": "Mobility",
	"defense": "Defense",
	"hull": "Hull"
}
const UPGRADE_STAT_DISPLAY_NAMES: Dictionary = {
	"damage_mult": "Damage",
	"attack_speed_mult": "Attack Speed",
	"projectile_speed_mult": "Projectile Speed",
	"projectile_count_bonus": "Projectile Count",
	"pierce_bonus": "Pierce",
	"move_speed_bonus": "Move Speed",
	"dash_cooldown_reduction": "Dash Cooldown",
	"max_hp": "Max HP",
	"heal": "Heal",
	"regen_per_second": "Regen",
	"xp_gain_mult": "XP Gain",
	"noise_generation_mult": "Noise Gain",
	"noise_decay_bonus": "Noise Decay",
	"dash_noise_mult": "Dash Noise",
	"sonar_reveal_duration_mult": "Reveal Duration",
	"revealed_damage_mult": "Revealed Target Damage",
	"low_noise_damage_mult": "Low-Noise Damage",
	"pickup_radius_mult": "Pickup Radius",
	"summon_cap_bonus": "Summon Cap",
	"summon_resistance": "Summon Resistance",
	"weapon_level_up": "Weapon Level",
	"weapon_level_up_active": "Active Weapon Level",
	"weapon_damage_mult": "Weapon Damage",
	"weapon_attack_rate_mult": "Weapon Attack Rate",
	"weapon_range_mult": "Weapon Range",
	"weapon_projectile_speed_mult": "Weapon Projectile Speed",
	"weapon_pierce_bonus": "Weapon Pierce",
	"weapon_crit_chance_add": "Weapon Crit Chance",
	"weapon_crit_multiplier_add": "Weapon Crit Multiplier",
	"weapon_aoe_radius_mult": "Weapon AOE Radius",
	"weapon_noise_mult": "Weapon Noise",
	"weapon_noise_add": "Weapon Noise Flat",
	"weapon_projectile_count_bonus": "Weapon Projectile Count",
	"weapon_reveal_bonus_add": "Weapon Reveal Bonus",
	"weapon_summon_cap_bonus": "Weapon Summon Cap",
	"chain_bonus": "Chain Chance"
}
const PERCENT_STAT_KEYS: Dictionary = {
	"damage_mult": true,
	"attack_speed_mult": true,
	"projectile_speed_mult": true,
	"dash_cooldown_reduction": true,
	"xp_gain_mult": true,
	"noise_generation_mult": true,
	"dash_noise_mult": true,
	"sonar_reveal_duration_mult": true,
	"revealed_damage_mult": true,
	"low_noise_damage_mult": true,
	"pickup_radius_mult": true,
	"summon_resistance": true,
	"weapon_damage_mult": true,
	"weapon_attack_rate_mult": true,
	"weapon_range_mult": true,
	"weapon_projectile_speed_mult": true,
	"weapon_crit_chance_add": true,
	"weapon_crit_multiplier_add": true,
	"weapon_aoe_radius_mult": true,
	"weapon_noise_mult": true,
	"chain_bonus": true
}
const INT_STAT_KEYS: Dictionary = {
	"projectile_count_bonus": true,
	"pierce_bonus": true,
	"summon_cap_bonus": true,
	"weapon_level_up": true,
	"weapon_level_up_active": true,
	"weapon_pierce_bonus": true,
	"weapon_projectile_count_bonus": true,
	"weapon_summon_cap_bonus": true
}
const SECONDS_STAT_KEYS: Dictionary = {
	"weapon_reveal_bonus_add": true
}

@onready var root: Control = $Root
@onready var stats_box: VBoxContainer = $Root/HUD/Stats
@onready var hp_label: Label = $Root/HUD/Stats/HPLabel
@onready var xp_label: Label = $Root/HUD/Stats/XPLabel
@onready var level_label: Label = $Root/HUD/Stats/LevelLabel
@onready var noise_label: Label = $Root/HUD/Stats/NoiseLabel
@onready var mode_label: Label = $Root/HUD/Stats/ModeLabel
@onready var time_label: Label = $Root/HUD/Stats/TimeLabel
@onready var kills_label: Label = $Root/HUD/Stats/KillsLabel
@onready var enemies_label: Label = $Root/HUD/Stats/EnemiesLabel
@onready var run_hud: Control = $Root/RunHUD

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
var fog_line_strength_base: float = 0.08
var fog_noise_strength_base: float = 0.05
var fog_pulse_speed_base: float = 0.65
var noise_bar: ProgressBar
var noise_tier_label: Label
var weapon_label: Label
var contract_status_label: Label
var debug_panel: Panel
var debug_label: RichTextLabel
var system_msg_label: Label
var system_msg_timer: Timer
var last_noise_tier_id: String = ""
var main_menu_panel: CanvasItem
var run_setup_panel: CanvasItem
var upgrade_select_panel: CanvasItem
var character_select_panel: CanvasItem
var map_select_panel: CanvasItem
var contract_select_panel: CanvasItem
var unlock_toast_label: Label
var telegraph_flash_overlay: ColorRect
var telegraph_flash_tween: Tween
var latest_hud_data: Dictionary = {}
var latest_run_multipliers: Dictionary = {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	if root.theme == null:
		root.theme = NEON_THEME
	_create_fog_overlay()
	_create_telegraph_flash_overlay()
	apply_fog_overlay_config(DataRegistry.get_fog_config())
	set_fog_overlay_enabled(bool(DataRegistry.get_fog_config().get("enabled", true)))
	_create_runtime_hud_widgets()
	_create_debug_panel()
	_create_system_message_widget()
	_create_main_menu_panel()
	_create_run_setup_panel()
	_create_upgrade_select_panel()
	_create_unlock_toast_widget()
	set_debug_visible(false)

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


func _create_telegraph_flash_overlay() -> void:
	telegraph_flash_overlay = ColorRect.new()
	telegraph_flash_overlay.name = "TelegraphFlashOverlay"
	telegraph_flash_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	telegraph_flash_overlay.offset_left = 0.0
	telegraph_flash_overlay.offset_top = 0.0
	telegraph_flash_overlay.offset_right = 0.0
	telegraph_flash_overlay.offset_bottom = 0.0
	telegraph_flash_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	telegraph_flash_overlay.visible = false
	telegraph_flash_overlay.color = Color(0.72, 0.95, 1.0, 0.0)
	root.add_child(telegraph_flash_overlay)
	root.move_child(telegraph_flash_overlay, 1)


func _create_runtime_hud_widgets() -> void:
	if $Root/HUD != null:
		$Root/HUD.visible = false
	if run_hud == null:
		return
	if run_hud.has_method("get_contract_status_label"):
		var label_variant: Variant = run_hud.call("get_contract_status_label")
		if label_variant is Label:
			contract_status_label = label_variant


func _create_debug_panel() -> void:
	debug_panel = Panel.new()
	debug_panel.name = "DebugPanel"
	debug_panel.theme_type_variation = &"SurfacePanel"
	debug_panel.visible = false
	debug_panel.position = Vector2(1180.0, 18.0)
	debug_panel.size = Vector2(390.0, 340.0)

	var margin := MarginContainer.new()
	margin.name = "Margin"
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.offset_left = 10.0
	margin.offset_top = 10.0
	margin.offset_right = -10.0
	margin.offset_bottom = -10.0
	debug_panel.add_child(margin)

	debug_label = RichTextLabel.new()
	debug_label.fit_content = false
	debug_label.scroll_active = false
	debug_label.bbcode_enabled = false
	debug_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	debug_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	margin.add_child(debug_label)

	root.add_child(debug_panel)


func _create_system_message_widget() -> void:
	system_msg_label = Label.new()
	system_msg_label.name = "SystemMessage"
	system_msg_label.theme_type_variation = &"SubheadingLabel"
	system_msg_label.visible = false
	system_msg_label.position = Vector2(560.0, 16.0)
	system_msg_label.size = Vector2(480.0, 30.0)
	system_msg_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	system_msg_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	system_msg_label.modulate = Color(0.72, 0.96, 1.0, 0.0)
	root.add_child(system_msg_label)

	system_msg_timer = Timer.new()
	system_msg_timer.one_shot = true
	system_msg_timer.timeout.connect(func() -> void:
		if system_msg_label == null:
			return
		var tween := create_tween()
		tween.tween_property(system_msg_label, "modulate:a", 0.0, 0.28)
		tween.finished.connect(func() -> void:
			system_msg_label.visible = false
		)
	)
	add_child(system_msg_timer)


func _create_main_menu_panel() -> void:
	if MAIN_MENU_SCENE == null:
		return
	var panel_variant := MAIN_MENU_SCENE.instantiate()
	if panel_variant == null:
		return
	main_menu_panel = panel_variant
	main_menu_panel.name = "MainMenuPanel"
	main_menu_panel.visible = false
	root.add_child(main_menu_panel)
	if main_menu_panel.has_signal("play_pressed"):
		main_menu_panel.connect("play_pressed", Callable(self, "_on_main_menu_play_pressed"))
	if main_menu_panel.has_signal("profile_pressed"):
		main_menu_panel.connect("profile_pressed", Callable(self, "_on_main_menu_profile_pressed"))
	if main_menu_panel.has_signal("settings_pressed"):
		main_menu_panel.connect("settings_pressed", Callable(self, "_on_main_menu_settings_pressed"))
	if main_menu_panel.has_signal("quit_pressed"):
		main_menu_panel.connect("quit_pressed", Callable(self, "_on_main_menu_quit_pressed"))


func _create_character_select_panel() -> void:
	if CHARACTER_SELECT_SCENE == null:
		return
	var panel_variant := CHARACTER_SELECT_SCENE.instantiate()
	if panel_variant == null:
		return
	character_select_panel = panel_variant
	character_select_panel.visible = false
	root.add_child(character_select_panel)
	if character_select_panel.has_signal("start_pressed"):
		character_select_panel.connect("start_pressed", Callable(self, "_on_character_select_start_pressed"))
	if character_select_panel.has_signal("back_pressed"):
		character_select_panel.connect("back_pressed", Callable(self, "_on_character_select_back_pressed"))
	if character_select_panel.has_signal("debug_unlock_all_pressed"):
		character_select_panel.connect("debug_unlock_all_pressed", Callable(self, "_on_character_select_unlock_all_pressed"))


func _create_run_setup_panel() -> void:
	if RUN_SETUP_SCENE == null:
		return
	var panel_variant := RUN_SETUP_SCENE.instantiate()
	if panel_variant == null:
		return
	run_setup_panel = panel_variant
	run_setup_panel.name = "RunSetup"
	run_setup_panel.visible = false
	root.add_child(run_setup_panel)
	if run_setup_panel.has_signal("run_submitted"):
		run_setup_panel.connect("run_submitted", Callable(self, "_on_run_setup_submitted"))
	if run_setup_panel.has_signal("back_requested"):
		run_setup_panel.connect("back_requested", Callable(self, "_on_run_setup_back_requested"))


func _create_upgrade_select_panel() -> void:
	if UPGRADE_SELECT_SCENE == null:
		return
	var panel_variant := UPGRADE_SELECT_SCENE.instantiate()
	if panel_variant == null:
		return
	upgrade_select_panel = panel_variant
	upgrade_select_panel.name = "UpgradeSelect"
	upgrade_select_panel.visible = false
	root.add_child(upgrade_select_panel)
	if upgrade_select_panel.has_signal("upgrade_selected"):
		upgrade_select_panel.connect("upgrade_selected", Callable(self, "_on_upgrade_select_upgrade_selected"))
	if upgrade_select_panel.has_signal("cancel_requested"):
		upgrade_select_panel.connect("cancel_requested", Callable(self, "_on_upgrade_select_cancel_requested"))


func _create_map_select_panel() -> void:
	if MAP_SELECT_SCENE == null:
		return
	var panel_variant := MAP_SELECT_SCENE.instantiate()
	if panel_variant == null:
		return
	map_select_panel = panel_variant
	map_select_panel.visible = false
	root.add_child(map_select_panel)
	if map_select_panel.has_signal("start_pressed"):
		map_select_panel.connect("start_pressed", Callable(self, "_on_map_select_start_pressed"))
	if map_select_panel.has_signal("back_pressed"):
		map_select_panel.connect("back_pressed", Callable(self, "_on_map_select_back_pressed"))


func _create_contract_select_panel() -> void:
	if CONTRACT_SELECT_SCENE == null:
		return
	var panel_variant := CONTRACT_SELECT_SCENE.instantiate()
	if panel_variant == null:
		return
	contract_select_panel = panel_variant
	contract_select_panel.visible = false
	root.add_child(contract_select_panel)
	if contract_select_panel.has_signal("start_pressed"):
		contract_select_panel.connect("start_pressed", Callable(self, "_on_contract_select_start_pressed"))
	if contract_select_panel.has_signal("back_pressed"):
		contract_select_panel.connect("back_pressed", Callable(self, "_on_contract_select_back_pressed"))


func _create_unlock_toast_widget() -> void:
	unlock_toast_label = Label.new()
	unlock_toast_label.name = "UnlockToast"
	unlock_toast_label.visible = false
	unlock_toast_label.position = Vector2(1180.0, 70.0)
	unlock_toast_label.size = Vector2(380.0, 120.0)
	unlock_toast_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	unlock_toast_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	unlock_toast_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	unlock_toast_label.modulate = Color(0.9, 1.0, 1.0, 0.0)
	root.add_child(unlock_toast_label)


func _on_character_select_start_pressed(character_id: String) -> void:
	start_run_requested.emit(character_id)


func _on_run_setup_submitted(run_config: Dictionary) -> void:
	run_setup_start_requested.emit(run_config)


func _on_run_setup_back_requested() -> void:
	character_select_back_requested.emit()


func _on_upgrade_select_upgrade_selected(upgrade_id: String) -> void:
	upgrade_selected.emit(upgrade_id)


func _on_upgrade_select_cancel_requested() -> void:
	show_system_message("Upgrade selection must be confirmed to continue.", false)


func _on_main_menu_play_pressed() -> void:
	main_menu_start_requested.emit()


func _on_main_menu_profile_pressed() -> void:
	show_system_message("Profile page is coming in a follow-up update.", false)


func _on_main_menu_settings_pressed() -> void:
	show_system_message("Settings page is coming in a follow-up update.", false)


func _on_main_menu_quit_pressed() -> void:
	get_tree().quit()


func _on_character_select_back_pressed() -> void:
	character_select_back_requested.emit()


func _on_character_select_unlock_all_pressed() -> void:
	unlock_all_debug_requested.emit()


func _on_map_select_start_pressed(map_id: String) -> void:
	map_select_start_requested.emit(map_id)


func _on_map_select_back_pressed() -> void:
	map_select_back_requested.emit()


func _on_contract_select_start_pressed(contract_ids: Array[String]) -> void:
	contract_select_start_requested.emit(contract_ids)


func _on_contract_select_back_pressed() -> void:
	contract_select_back_requested.emit()


func apply_fog_overlay_config(config: Dictionary) -> void:
	if fog_overlay_material == null:
		return
	fog_overlay_allowed = bool(config.get("scanline_enabled", true))
	fog_line_strength_base = float(config.get("scanline_strength", 0.08))
	fog_noise_strength_base = float(config.get("noise_strength", 0.05))
	fog_pulse_speed_base = float(config.get("pulse_speed", 0.65))
	var tint_color := Color.from_string(String(config.get("tint_color", "#0b1a2a")), Color(0.05, 0.10, 0.16))
	fog_overlay_material.set_shader_parameter("line_density", float(config.get("scanline_density", 320.0)))
	fog_overlay_material.set_shader_parameter("line_strength", fog_line_strength_base)
	fog_overlay_material.set_shader_parameter("noise_strength", fog_noise_strength_base)
	fog_overlay_material.set_shader_parameter("tint_color", tint_color)
	fog_overlay_material.set_shader_parameter("tint_alpha", float(config.get("tint_alpha", 0.30)))
	fog_overlay_material.set_shader_parameter("pulse_speed", fog_pulse_speed_base)
	fog_overlay_material.set_shader_parameter("effect_enabled", fog_overlay_allowed)
	fog_overlay.visible = fog_overlay_allowed


func set_fog_overlay_enabled(enabled: bool) -> void:
	if fog_overlay_material == null:
		return
	var final_enabled := enabled and fog_overlay_allowed
	fog_overlay_material.set_shader_parameter("effect_enabled", final_enabled)
	fog_overlay.visible = final_enabled


func update_hud(data: Dictionary) -> void:
	latest_hud_data = data.duplicate(true)
	latest_run_multipliers = _extract_run_multipliers(data)

	if run_hud != null and run_hud.has_method("apply_hud_dict"):
		run_hud.call("apply_hud_dict", data)
		if run_hud.has_method("get_contract_status_label"):
			var label_variant: Variant = run_hud.call("get_contract_status_label")
			if label_variant is Label:
				contract_status_label = label_variant
	if upgrade_select_panel != null and upgrade_select_panel.visible and upgrade_select_panel.has_method("update_build_context"):
		upgrade_select_panel.call("update_build_context", latest_hud_data, latest_run_multipliers)
	if run_hud != null and run_hud.has_method("apply_hud_dict"):
		return

	# Fallback legacy HUD path for scenes that do not include RunHUD.
	hp_label.text = "HP: %d / %d" % [int(round(float(data.get("hp", 0.0)))), int(round(float(data.get("max_hp", 0.0))))]
	xp_label.text = "XP: %d / %d" % [int(round(float(data.get("xp", 0.0)))), int(round(float(data.get("xp_to_next", 1.0))))]
	level_label.text = "Level: %d" % int(data.get("level", 1))
	mode_label.text = "Attack: %s" % String(data.get("attack_mode", "AUTO"))
	time_label.text = "Time: %s" % _format_time(float(data.get("elapsed_time", 0.0)))
	kills_label.text = "Kills: %d" % int(data.get("kills", 0))
	enemies_label.text = "Enemies: %d  Revealed: %d" % [int(data.get("enemy_count", 0)), int(data.get("revealed_count", 0))]
	if contract_status_label != null:
		var dash_disabled := bool(data.get("contract_dash_disabled", false))
		contract_status_label.visible = dash_disabled
		contract_status_label.text = "Dash Disabled" if dash_disabled else ""


func set_debug_visible(enabled: bool) -> void:
	if debug_panel != null:
		debug_panel.visible = enabled


func is_debug_visible() -> bool:
	if debug_panel == null:
		return false
	return debug_panel.visible


func update_debug_data(data: Dictionary) -> void:
	if debug_label == null:
		return
	if not is_debug_visible():
		return
	debug_label.text = "\n".join([
		"DEBUG (F1)",
		"fps: %d" % int(data.get("fps", 0)),
		"entities: enemy=%d projectile=%d pickup=%d" % [
			int(data.get("enemy_count", 0)),
			int(data.get("projectile_count", 0)),
			int(data.get("pickup_count", 0))
		],
		"pool_hit_rate: %s" % ("N/A" if float(data.get("pool_hit_rate", -1.0)) < 0.0 else "%.2f" % float(data.get("pool_hit_rate", 0.0))),
		"pool_hits/misses: %d / %d" % [
			int(data.get("pool_hits", 0)),
			int(data.get("pool_misses", 0))
		],
		"enemy_pool_hit_rate: %s" % ("N/A" if float(data.get("enemy_pool_hit_rate", -1.0)) < 0.0 else "%.2f" % float(data.get("enemy_pool_hit_rate", 0.0))),
		"enemy_pool_hits/misses: %d / %d" % [
			int(data.get("enemy_pool_hits", 0)),
			int(data.get("enemy_pool_misses", 0))
		],
		"target_query_count_per_sec: %.1f" % float(data.get("target_query_count_per_sec", 0.0)),
		"current_weapon(s): %s" % str(data.get("current_weapons", [])),
		"weapon_tags: %s" % str(data.get("weapon_tags", [])),
		"weapon_dps~: %.1f" % float(data.get("weapon_dps_estimate", 0.0)),
		"weapon_noise_rate: %.2f/s" % float(data.get("weapon_noise_rate", 0.0)),
		"chain: %s chance=%.2f hops=%d" % [
			"ON" if bool(data.get("chain_enabled", false)) else "OFF",
			float(data.get("chain_chance", 0.0)),
			int(data.get("chain_max_hops", 0))
		],
		"summon_resistance: %.2f" % float(data.get("summon_resistance", 0.0)),
		"character: %s" % String(data.get("selected_character", "")),
		"noise: %.1f" % float(data.get("noise", 0.0)),
		"noise_tier: %s" % String(data.get("noise_tier_name", "静默")),
		"spawn_rate_multiplier(total): %.2f" % float(data.get("total_spawn_multiplier", float(data.get("spawn_rate_multiplier", 1.0)))),
		"spawn components n/m/c: %.2f / %.2f / %.2f" % [
			float(data.get("noise_spawn_rate_multiplier", 1.0)),
			float(data.get("map_spawn_rate_multiplier", 1.0)),
			float(data.get("contract_spawn_rate_multiplier", 1.0))
		],
		"pursuer_chance: %.3f" % float(data.get("pursuer_chance", 0.0)),
		"elite_chance: %.3f  elite_count: %d" % [
			float(data.get("elite_chance", 0.0)),
			int(data.get("elite_count", 0))
		],
		"pursuer_count: %d  spawned_total: %d  next_eta: %.1fs" % [
			int(data.get("pursuer_count", 0)),
			int(data.get("pursuer_spawned_total", 0)),
			float(data.get("next_pursuer_eta", -1.0))
		],
		"map_spawn_multiplier: %.2f" % float(data.get("map_spawn_multiplier", 1.0)),
		"boss_state: %s (%s)" % [
			String(data.get("boss_state", "idle")),
			String(data.get("boss_id", ""))
		],
		"boss_decoys: %d  true_form: %s  telegraphs: %d" % [
			int(data.get("boss_decoy_count", 0)),
			"YES" if bool(data.get("boss_true_form_revealed", false)) else "NO",
			int(data.get("boss_telegraph_count", 0))
		],
		"contracts_active: %s" % str(data.get("contracts_active", [])),
		"contract_event_rate_mult: %.2f" % float(data.get("contract_event_rate_mult", 1.0)),
		"revealed_count: %d" % int(data.get("revealed_count", 0)),
		"timeline_progress: %.2f" % float(data.get("timeline_progress", 0.0)),
		"map_id: %s" % String(data.get("current_map_id", "")),
		"hazard_active: %s  timer: %.1fs" % [
			"ON" if bool(data.get("hazard_active", false)) else "OFF",
			float(data.get("hazard_timer", 0.0))
		],
		"last_event: %s" % String(data.get("last_event_triggered", "-")),
		"fog_radius: %.1f  map_noise_gain: %.2f" % [
			float(data.get("fog_radius", 0.0)),
			float(data.get("map_noise_gain_multiplier", 1.0))
		],
		"fixed_noise: %s (%.1f)" % [
			"ON" if bool(data.get("fixed_noise_enabled", false)) else "OFF",
			float(data.get("fixed_noise_value", 0.0))
		],
		"fog: %s  sonar_visual: %s" % [
			"ON" if bool(data.get("fog_enabled", true)) else "OFF",
			"ON" if bool(data.get("sonar_visual_enabled", true)) else "OFF"
		],
		"config fog: v%d @ %s" % [int(data.get("fog_version", -1)), String(data.get("fog_path", ""))],
		"config sonar: v%d @ %s" % [int(data.get("sonar_version", -1)), String(data.get("sonar_path", ""))],
		"config noise: v%d @ %s" % [int(data.get("noise_version", -1)), String(data.get("noise_path", ""))],
		"config maps: v%d @ %s" % [int(data.get("maps_version", -1)), String(data.get("maps_path", ""))],
		"config hazards: v%d @ %s" % [int(data.get("hazards_version", -1)), String(data.get("hazards_path", ""))],
		"config events: v%d @ %s" % [int(data.get("events_version", -1)), String(data.get("events_path", ""))],
		"hot reload: F5",
		"fixed noise: F6 toggle, F7 -, F8 +",
		"fog F2, sonar visual F3"
		])


func show_system_message(text: String, is_error: bool = false) -> void:
	if system_msg_label == null:
		return
	system_msg_label.text = text
	system_msg_label.modulate = Color(1.0, 0.72, 0.72, 1.0) if is_error else Color(0.72, 0.96, 1.0, 1.0)
	system_msg_label.visible = true
	if system_msg_timer != null:
		system_msg_timer.start(2.0)


func show_telegraph_warning(payload: Dictionary, message: String = "") -> void:
	var severity := clampf(float(payload.get("severity", 1.0)), 0.1, 3.0)
	var sfx_bucket := String(payload.get("sfx_bucket", "warning")).strip_edges().to_lower()
	var resolved_text := message.strip_edges()
	if resolved_text.is_empty():
		resolved_text = String(payload.get("message", "")).strip_edges()
	if not resolved_text.is_empty():
		show_system_message(resolved_text, severity >= 1.75)
	_play_telegraph_flash(severity, sfx_bucket)


func _play_telegraph_flash(severity: float, bucket: String) -> void:
	var bucket_color := _get_telegraph_bucket_color(bucket)
	if telegraph_flash_overlay != null:
		telegraph_flash_overlay.visible = true
		telegraph_flash_overlay.color = bucket_color
		telegraph_flash_overlay.modulate.a = 0.0
	if telegraph_flash_tween != null and is_instance_valid(telegraph_flash_tween):
		telegraph_flash_tween.kill()
	telegraph_flash_tween = create_tween()
	if telegraph_flash_overlay != null:
		var peak_alpha := clampf(0.05 + severity * 0.045, 0.08, 0.18)
		telegraph_flash_tween.tween_property(telegraph_flash_overlay, "modulate:a", peak_alpha, 0.07)
		telegraph_flash_tween.tween_property(telegraph_flash_overlay, "modulate:a", 0.0, 0.20)
		telegraph_flash_tween.finished.connect(func() -> void:
			if telegraph_flash_overlay != null:
				telegraph_flash_overlay.visible = false
		)
	if fog_overlay_material != null and fog_overlay_allowed:
		var line_peak := fog_line_strength_base + 0.02 * severity
		var noise_peak := fog_noise_strength_base + 0.02 * severity
		var pulse_peak := fog_pulse_speed_base + 0.12 * severity
		fog_overlay_material.set_shader_parameter("line_strength", line_peak)
		fog_overlay_material.set_shader_parameter("noise_strength", noise_peak)
		fog_overlay_material.set_shader_parameter("pulse_speed", pulse_peak)
		telegraph_flash_tween.parallel().tween_method(
			func(v: float) -> void:
				if fog_overlay_material == null:
					return
				fog_overlay_material.set_shader_parameter("line_strength", lerpf(line_peak, fog_line_strength_base, v))
				fog_overlay_material.set_shader_parameter("noise_strength", lerpf(noise_peak, fog_noise_strength_base, v))
				fog_overlay_material.set_shader_parameter("pulse_speed", lerpf(pulse_peak, fog_pulse_speed_base, v)),
			0.0,
			1.0,
			0.24
		)


func _get_telegraph_bucket_color(bucket: String) -> Color:
	match bucket:
		"boss":
			return Color(1.0, 0.68, 0.82, 1.0)
		"alert":
			return Color(1.0, 0.76, 0.52, 1.0)
		_:
			return Color(0.72, 0.95, 1.0, 1.0)


func _play_noise_tier_change(tier_color: Color) -> void:
	if noise_bar == null or noise_tier_label == null:
		return
	noise_bar.scale = Vector2(1.0, 1.0)
	var tween := create_tween()
	tween.tween_property(noise_bar, "scale", Vector2(1.03, 1.18), 0.08)
	tween.tween_property(noise_bar, "scale", Vector2(1.0, 1.0), 0.16)
	var label_tween := create_tween()
	label_tween.tween_property(noise_tier_label, "modulate", tier_color.lightened(0.24), 0.07)
	label_tween.tween_property(noise_tier_label, "modulate", tier_color, 0.16)


func set_main_menu_visible(enabled: bool) -> void:
	if main_menu_panel != null:
		main_menu_panel.visible = enabled
	if enabled and run_setup_panel != null:
		run_setup_panel.visible = false
	if enabled and character_select_panel != null:
		character_select_panel.visible = false
	if enabled and map_select_panel != null:
		map_select_panel.visible = false
	if enabled and contract_select_panel != null:
		contract_select_panel.visible = false
	_set_hud_visible(not enabled)


func set_character_select_visible(enabled: bool) -> void:
	if run_setup_panel != null:
		run_setup_panel.visible = enabled
		if enabled and run_setup_panel.has_method("set_step_by_state"):
			run_setup_panel.call("set_step_by_state", "character_select")
	if character_select_panel != null:
		character_select_panel.visible = false
	if enabled and main_menu_panel != null:
		main_menu_panel.visible = false
	if enabled and map_select_panel != null:
		map_select_panel.visible = false
	if enabled and contract_select_panel != null:
		contract_select_panel.visible = false
	_set_hud_visible(not enabled)


func set_map_select_visible(enabled: bool) -> void:
	if run_setup_panel != null:
		run_setup_panel.visible = enabled
		if enabled and run_setup_panel.has_method("set_step_by_state"):
			run_setup_panel.call("set_step_by_state", "map_select")
	if map_select_panel != null:
		map_select_panel.visible = false
	if enabled and main_menu_panel != null:
		main_menu_panel.visible = false
	if enabled and character_select_panel != null:
		character_select_panel.visible = false
	if enabled and contract_select_panel != null:
		contract_select_panel.visible = false
	_set_hud_visible(not enabled)


func set_contract_select_visible(enabled: bool) -> void:
	if run_setup_panel != null:
		run_setup_panel.visible = enabled
		if enabled and run_setup_panel.has_method("set_step_by_state"):
			run_setup_panel.call("set_step_by_state", "contract_select")
	if contract_select_panel != null:
		contract_select_panel.visible = false
	if enabled and main_menu_panel != null:
		main_menu_panel.visible = false
	if enabled and character_select_panel != null:
		character_select_panel.visible = false
	if enabled and map_select_panel != null:
		map_select_panel.visible = false
	_set_hud_visible(not enabled)


func configure_character_select(characters: Array, unlocked_character_ids: Array[String], selected_id: String) -> void:
	if run_setup_panel != null and run_setup_panel.has_method("set_character_data"):
		run_setup_panel.call("set_character_data", characters, unlocked_character_ids, selected_id)
	if character_select_panel == null:
		return
	if character_select_panel.has_method("set_character_data"):
		character_select_panel.call("set_character_data", characters, unlocked_character_ids, selected_id)


func configure_map_select(maps: Array, selected_map_id: String) -> void:
	if run_setup_panel != null and run_setup_panel.has_method("set_map_data"):
		run_setup_panel.call("set_map_data", maps, selected_map_id)
	if map_select_panel == null:
		return
	if map_select_panel.has_method("set_map_data"):
		map_select_panel.call("set_map_data", maps, selected_map_id)


func configure_contract_select(contracts: Array, selected_contract_ids: Array[String], max_select: int) -> void:
	if run_setup_panel != null and run_setup_panel.has_method("set_contract_data"):
		run_setup_panel.call("set_contract_data", contracts, selected_contract_ids, max_select)
	if contract_select_panel == null:
		return
	if contract_select_panel.has_method("set_contract_data"):
		contract_select_panel.call("set_contract_data", contracts, selected_contract_ids, max_select)


func refresh_character_unlocks(unlocked_character_ids: Array[String]) -> void:
	if run_setup_panel != null and run_setup_panel.has_method("refresh_unlocks"):
		run_setup_panel.call("refresh_unlocks", unlocked_character_ids)
	if character_select_panel == null:
		return
	if character_select_panel.has_method("refresh_unlocks"):
		character_select_panel.call("refresh_unlocks", unlocked_character_ids)


func show_unlock_toast(unlocked_character_names: Array[String]) -> void:
	if unlock_toast_label == null or unlocked_character_names.is_empty():
		return
	unlock_toast_label.text = "Unlocked:\n%s" % "\n".join(unlocked_character_names)
	unlock_toast_label.visible = true
	unlock_toast_label.modulate = Color(0.72, 0.96, 1.0, 0.0)
	var tween := create_tween()
	tween.tween_property(unlock_toast_label, "modulate:a", 1.0, 0.22)
	tween.tween_interval(2.2)
	tween.tween_property(unlock_toast_label, "modulate:a", 0.0, 0.28)
	tween.finished.connect(func() -> void:
		unlock_toast_label.visible = false
	)


func _set_hud_visible(visible_state: bool) -> void:
	if run_hud != null:
		run_hud.visible = visible_state
	if $Root/HUD != null:
		$Root/HUD.visible = false


func _set_upgrade_select_visible(visible_state: bool) -> void:
	if upgrade_select_panel == null:
		return
	upgrade_select_panel.visible = visible_state and not current_options.is_empty()
	if upgrade_select_panel.visible and upgrade_select_panel.has_method("update_build_context"):
		upgrade_select_panel.call("update_build_context", latest_hud_data, latest_run_multipliers)


func _set_root_input_passthrough(enabled: bool) -> void:
	if root == null:
		return
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE if enabled else Control.MOUSE_FILTER_STOP


func show_level_up(options: Array) -> void:
	current_options = options
	game_over_panel.visible = false
	if upgrade_select_panel != null and upgrade_select_panel.has_method("show_options"):
		level_up_panel.visible = false
		upgrade_select_panel.visible = true
		upgrade_select_panel.call("show_options", current_options, latest_hud_data, latest_run_multipliers)
		return

	level_up_title.text = "Signal Upgrade - Choose One"
	for i in range(upgrade_buttons.size()):
		var button := upgrade_buttons[i]
		if i < current_options.size():
			var option_variant: Variant = current_options[i]
			var option: Dictionary = {}
			if option_variant is Dictionary:
				option = option_variant
			var tags_text := _format_tags_text(option.get("tags", []))
			var effects_text := _format_upgrade_effects(option.get("effects", []))
			button.disabled = false
			button.visible = true
			button.text = "%s [%s]\nTags: %s\n%s\n%s" % [
				String(option.get("name", "Unknown")),
				String(option.get("rarity", "common")).to_upper(),
				tags_text,
				String(option.get("description", "")),
				effects_text
			]
		else:
			button.disabled = true
			button.visible = false
	level_up_panel.visible = true


func hide_level_up() -> void:
	if upgrade_select_panel != null:
		upgrade_select_panel.visible = false
		if upgrade_select_panel.has_method("hide_panel"):
			upgrade_select_panel.call("hide_panel")
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
	var unlocked_count := int(summary.get("unlocked_count", 0))
	if unlocked_count > 0:
		lines.append("New Unlocks: %d" % unlocked_count)
	game_over_summary.text = "\n".join(lines)
	level_up_panel.visible = false
	game_over_panel.visible = true


func on_game_state_changed(state: String) -> void:
	match state:
		"menu":
			_set_root_input_passthrough(false)
			level_up_panel.visible = false
			_set_upgrade_select_visible(false)
			game_over_panel.visible = false
			set_main_menu_visible(true)
		"character_select":
			_set_root_input_passthrough(false)
			level_up_panel.visible = false
			_set_upgrade_select_visible(false)
			game_over_panel.visible = false
			set_character_select_visible(true)
		"map_select":
			_set_root_input_passthrough(false)
			level_up_panel.visible = false
			_set_upgrade_select_visible(false)
			game_over_panel.visible = false
			set_map_select_visible(true)
		"contract_select":
			_set_root_input_passthrough(false)
			level_up_panel.visible = false
			_set_upgrade_select_visible(false)
			game_over_panel.visible = false
			set_contract_select_visible(true)
		"playing":
			_set_root_input_passthrough(true)
			level_up_panel.visible = false
			_set_upgrade_select_visible(false)
			game_over_panel.visible = false
			set_main_menu_visible(false)
			set_character_select_visible(false)
			set_map_select_visible(false)
			set_contract_select_visible(false)
			_set_hud_visible(true)
		"level_up":
			_set_root_input_passthrough(false)
			_set_upgrade_select_visible(true)
			game_over_panel.visible = false
			set_main_menu_visible(false)
			set_character_select_visible(false)
			set_map_select_visible(false)
			set_contract_select_visible(false)
			_set_hud_visible(true)
		"game_over":
			_set_root_input_passthrough(false)
			_set_upgrade_select_visible(false)
			set_main_menu_visible(false)
			set_character_select_visible(false)
			set_map_select_visible(false)
			set_contract_select_visible(false)
			_set_hud_visible(false)
		_:
			pass


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


func _format_tags_text(tags_variant: Variant) -> String:
	if not (tags_variant is Array):
		return "-"
	var tags: Array = tags_variant
	var out: Array[String] = []
	for tag_variant in tags:
		var tag := String(tag_variant).strip_edges().to_lower()
		if tag.is_empty():
			continue
		out.append(String(TAG_DISPLAY_NAMES.get(tag, tag)))
	if out.is_empty():
		return "-"
	return ", ".join(out)


func _format_upgrade_effects(effects_variant: Variant) -> String:
	if not (effects_variant is Array):
		return "Affects: -"
	var effects: Array = effects_variant
	var lines: Array[String] = []
	for effect_variant in effects:
		if not (effect_variant is Dictionary):
			continue
		var effect: Dictionary = effect_variant
		lines.append(_format_upgrade_effect_line(effect))
	if lines.is_empty():
		return "Affects: -"
	return "Affects: %s" % " | ".join(lines)


func _format_upgrade_effect_line(effect: Dictionary) -> String:
	var stat := String(effect.get("stat", "")).strip_edges()
	var stat_name := String(UPGRADE_STAT_DISPLAY_NAMES.get(stat, "Attribute"))
	var add_value := float(effect.get("add", 0.0))
	var value_text := _format_upgrade_effect_value(stat, add_value)
	var target_text := _format_upgrade_target(effect)
	return "%s %s (%s)" % [stat_name, value_text, target_text]


func _format_upgrade_effect_value(stat: String, add_value: float) -> String:
	var sign := "+" if add_value >= 0.0 else ""
	if PERCENT_STAT_KEYS.has(stat):
		return "%s%d%%" % [sign, int(round(add_value * 100.0))]
	if INT_STAT_KEYS.has(stat):
		return "%s%d" % [sign, int(round(add_value))]
	if SECONDS_STAT_KEYS.has(stat):
		return "%s%.2fs" % [sign, add_value]
	if stat == "noise_decay_bonus":
		return "%s%.2f/s" % [sign, add_value]
	if stat == "move_speed_bonus" or stat == "max_hp" or stat == "heal":
		return "%s%d" % [sign, int(round(add_value))]
	return "%s%.2f" % [sign, add_value]


func _format_upgrade_target(effect: Dictionary) -> String:
	var target_variant: Variant = effect.get("target", null)
	if not (target_variant is Dictionary):
		return "Target: Global"
	var target: Dictionary = target_variant
	var target_type := String(target.get("type", "")).strip_edges().to_lower()
	var target_value := String(target.get("value", "")).strip_edges().to_lower()
	if target_type == "weapon_id":
		var weapon_name := String(DataRegistry.get_weapon(target_value).get("name", target_value))
		return "Target: %s" % weapon_name
	if target_type == "tag":
		var tag_name := String(TAG_DISPLAY_NAMES.get(target_value, target_value))
		return "Target: Tag %s" % tag_name
	return "Target: Global"


func _extract_run_multipliers(hud_data: Dictionary) -> Dictionary:
	var reward_variant: Variant = hud_data.get("run_reward_multipliers", {})
	if reward_variant is Dictionary:
		var reward: Dictionary = reward_variant
		return {
			"xp": float(reward.get("xp", reward.get("xp_mult", 1.0))),
			"rarity": float(reward.get("rarity", reward.get("rarity_mult", 1.0))),
			"drop": float(reward.get("drop", reward.get("drop_mult", 1.0))),
			"meta_currency": float(reward.get("meta_currency", reward.get("meta_currency_mult", 1.0)))
		}
	return {
		"xp": float(hud_data.get("env_xp_gain_multiplier", 1.0)),
		"rarity": 1.0,
		"drop": 1.0,
		"meta_currency": 1.0
	}
