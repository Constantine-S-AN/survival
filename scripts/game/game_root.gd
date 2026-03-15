extends Node
class_name GameRoot

signal embedded_session_finished(summary: Dictionary)

const STATE_PLAYING := "playing"
const STATE_PAUSED := "paused"
const STATE_LEVEL_UP := "level_up"
const STATE_GAME_OVER := "game_over"
const STATE_MENU := "menu"
const STATE_CHARACTER_SELECT := "character_select"
const STATE_MAP_SELECT := "map_select"
const STATE_CONTRACT_SELECT := "contract_select"
const PRESENTATION_PROFILE_CLEAR_DUNGEON := "clear_dungeon"
const InputConfig := preload("res://scripts/core/input_config.gd")
const RunStatsClass := preload("res://scripts/core/run_stats.gd")
const CombatPaletteClass := preload("res://scripts/visual/combat_palette.gd")
const KILL_STREAK_WINDOW_SEC := 4.2
const KILL_STREAK_STEP := 6
const KILL_STREAK_MAX_REWARD_TIER := 8
const HITSTOP_MIN_DURATION_SEC := 0.016
const HITSTOP_MAX_DURATION_SEC := 0.086
const HITSTOP_BASE_SCALE := 0.24
const HITSTOP_MIN_SCALE := 0.055
const HITSTOP_KILL_SCALE_BONUS := 0.05
const HITSTOP_RECOVER_SEC := 0.050

@onready var world = $World
@onready var ui = $UI

var rng := RandomNumberGenerator.new()
var run_seed := 0
var elapsed_time := 0.0
var kills := 0
var run_state := STATE_MENU
var hitstop_active := false
var hitstop_end_usec: int = 0
var hitstop_recovering := false
var hitstop_recover_start_usec: int = 0
var hitstop_recover_end_usec: int = 0
var hitstop_recover_start_scale: float = 1.0
var hitstop_low_scale: float = 1.0
var fog_enabled: bool = true
var sonar_visual_enabled: bool = true
var fixed_noise_enabled: bool = false
var fixed_noise_value: float = 0.0
var selected_character_id: String = ""
var selected_map_id: String = ""
var selected_contract_ids: Array[String] = []
var presentation_profile: String = ""
var last_fog_overlay_signature: String = ""
var run_started: bool = false
var run_stats = RunStatsClass.new()
var telegraph_last_emit_by_key: Dictionary = {}
var run_reward_multipliers: Dictionary = {
	"xp": 1.0,
	"rarity": 1.0,
	"drop": 1.0,
	"meta_currency": 1.0
}
var reward_rng := RandomNumberGenerator.new()
var runtime_drop_pickups_spawned: int = 0
var last_sonar_ping_sequence: int = 0
var _level_up_option_ids: Dictionary = {}
var _game_over_latched: bool = false
var kill_streak_count: int = 0
var kill_streak_timer: float = 0.0
var kill_streak_reward_tier: int = 0
var embedded_session_mode: bool = false
var embedded_session_request: Dictionary = {}
var embedded_session_duration_sec: float = 0.0
var _last_generated_seed: int = 0


func set_embedded_session_request(request: Dictionary) -> void:
	embedded_session_mode = true
	embedded_session_request = request.duplicate(true)
	embedded_session_duration_sec = maxf(0.0, float(embedded_session_request.get("session_duration_sec", 0.0)))


func is_embedded_session_mode() -> bool:
	return embedded_session_mode


func _has_embedded_session_request() -> bool:
	return embedded_session_mode and not embedded_session_request.is_empty()


func get_presentation_profile() -> String:
	return presentation_profile


func _resolve_presentation_profile() -> String:
	if not _has_embedded_session_request():
		return ""
	return String(embedded_session_request.get("presentation_profile", "")).strip_edges().to_lower()


func _uses_clear_dungeon_presentation() -> bool:
	return presentation_profile == PRESENTATION_PROFILE_CLEAR_DUNGEON


func _apply_runtime_presentation_profile() -> void:
	presentation_profile = _resolve_presentation_profile()
	var clear_dungeon := _uses_clear_dungeon_presentation()
	if clear_dungeon:
		fog_enabled = false
		sonar_visual_enabled = false
	if world != null:
		if world.has_method("set_clear_dungeon_presentation"):
			world.call("set_clear_dungeon_presentation", clear_dungeon)
		world.set_fog_enabled(fog_enabled)
		world.set_sonar_visual_enabled(sonar_visual_enabled)
		if world.enemy_manager != null and world.enemy_manager.has_method("set_force_revealed"):
			world.enemy_manager.call("set_force_revealed", clear_dungeon)
		if world.player != null and world.player.has_method("set_clear_dungeon_visibility_mode"):
			world.player.call("set_clear_dungeon_visibility_mode", clear_dungeon)
	if ui != null:
		ui.set_fog_overlay_enabled(fog_enabled)


func _boot_embedded_session() -> void:
	if not _has_embedded_session_request():
		return
	var request := embedded_session_request.duplicate(true)
	var character_id := String(request.get("character_id", selected_character_id)).strip_edges()
	var map_id := String(request.get("map_id", selected_map_id)).strip_edges()
	var contract_ids: Array = []
	var contract_ids_variant: Variant = request.get("contract_ids", [])
	if contract_ids_variant is Array:
		contract_ids = (contract_ids_variant as Array).duplicate()
	var seed_override := int(request.get("seed", 0))
	_start_run(character_id, map_id, contract_ids, true, seed_override)


func _next_runtime_seed() -> int:
	var wall_usec: int = int(floor(Time.get_unix_time_from_system() * 1000000.0))
	var tick_usec: int = int(Time.get_ticks_usec())
	var seed: int = abs(wall_usec ^ (tick_usec << 11) ^ (tick_usec >> 3))
	if seed == 0:
		seed = 1
	if seed <= _last_generated_seed:
		seed = _last_generated_seed + 1
	_last_generated_seed = seed
	return seed


func get_runtime_reward_multipliers() -> Dictionary:
	return run_reward_multipliers.duplicate(true)


func set_runtime_reward_multipliers(multipliers: Dictionary = {}) -> void:
	run_reward_multipliers = _normalize_runtime_reward_multipliers(multipliers)
	if world != null and world.has_method("set_runtime_reward_multipliers"):
		world.set_runtime_reward_multipliers(run_reward_multipliers)
	if world != null and world.player != null and world.player.has_method("set_run_reward_multipliers"):
		world.player.set_run_reward_multipliers(run_reward_multipliers)
	if run_state == STATE_PLAYING and ui != null:
		_refresh_hud()


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_apply_default_window_mode()
	if world != null:
		world.process_mode = Node.PROCESS_MODE_PAUSABLE
	if ui != null:
		ui.process_mode = Node.PROCESS_MODE_ALWAYS
	_clear_hitstop_state(true)
	InputConfig.ensure_default_actions()
	if not DataRegistry.ensure_loaded():
		push_error("DataRegistry failed to load JSON. Check console for details.")
	var default_character_id := DataRegistry.get_default_character_id()
	var default_map_id := DataRegistry.get_default_map_id()
	ProfileStore.load_profile(
		default_character_id if not default_character_id.is_empty() else "diver",
		default_map_id
	)
	if not ProfileStore.is_character_unlocked(default_character_id):
		ProfileStore.unlock_character(default_character_id)
	if OS.is_debug_build():
		ProfileStore.unlock_all_characters(DataRegistry.get_characters())
	selected_character_id = ProfileStore.get_selected_character_id(default_character_id)
	if not ProfileStore.is_character_unlocked(selected_character_id):
		selected_character_id = default_character_id
	selected_map_id = ProfileStore.get_selected_map_id(default_map_id)
	if selected_map_id.is_empty() or not DataRegistry.has_map(selected_map_id):
		selected_map_id = default_map_id
	selected_contract_ids = DataRegistry.normalize_contract_selection(ProfileStore.get_selected_contract_ids())
	presentation_profile = _resolve_presentation_profile()

	var fog_cfg: Dictionary = DataRegistry.get_fog_config()
	fog_enabled = bool(fog_cfg.get("enabled", true))
	world.apply_fog_config(fog_cfg)
	world.set_fog_enabled(fog_enabled)
	ui.apply_fog_overlay_config(fog_cfg)
	ui.set_fog_overlay_enabled(fog_enabled)
	var sonar_cfg: Dictionary = DataRegistry.get_sonar_config()
	sonar_visual_enabled = bool(sonar_cfg.get("enabled", true))
	world.apply_sonar_config(sonar_cfg)
	world.set_sonar_visual_enabled(sonar_visual_enabled)
	world.player.apply_noise_config(DataRegistry.get_noise_config())
	_apply_runtime_presentation_profile()

	world.player.died.connect(_on_player_died)
	world.player.level_up_requested.connect(_on_player_level_up_requested)
	world.player.attack_mode_changed.connect(_on_player_attack_mode_changed)
	world.enemy_manager.enemy_killed.connect(_on_enemy_killed)
	world.enemy_manager.pursuer_spawned.connect(_on_pursuer_spawned)
	world.enemy_manager.boss_spawned.connect(_on_boss_spawned)
	world.enemy_manager.boss_phase_changed.connect(_on_boss_phase_changed)
	world.enemy_manager.boss_defeated.connect(_on_boss_defeated)
	world.enemy_manager.boss_telegraph_requested.connect(_on_boss_attack_telegraph_requested)
	world.enemy_manager.boss_echoes_spawned.connect(_on_boss_echoes_spawned)
	world.enemy_manager.boss_true_form_revealed.connect(_on_boss_true_form_revealed)
	world.map_event_triggered.connect(_on_map_event_triggered)
	world.hazard_state_changed.connect(_on_hazard_state_changed)
	if FeedbackBus.has_signal("hit_landed_detailed"):
		FeedbackBus.hit_landed_detailed.connect(_on_hit_landed_detailed)
	else:
		FeedbackBus.hit_landed.connect(_on_hit_landed)
	FeedbackBus.pickup_collected.connect(_on_pickup_collected)
	if not TelegraphBus.warning_emitted.is_connected(_on_telegraph_warning_emitted):
		TelegraphBus.warning_emitted.connect(_on_telegraph_warning_emitted)

	ui.upgrade_selected.connect(_on_upgrade_selected)
	ui.retry_requested.connect(_on_retry_requested)
	ui.main_menu_start_requested.connect(_on_main_menu_start_requested)
	ui.start_run_requested.connect(_on_start_run_requested)
	ui.character_select_back_requested.connect(_on_character_select_back_requested)
	ui.map_select_start_requested.connect(_on_map_select_start_requested)
	ui.map_select_back_requested.connect(_on_map_select_back_requested)
	ui.contract_select_start_requested.connect(_on_contract_select_start_requested)
	ui.contract_select_back_requested.connect(_on_contract_select_back_requested)
	ui.run_setup_start_requested.connect(_on_run_setup_start_requested)
	ui.unlock_all_debug_requested.connect(_on_unlock_all_debug_requested)
	if ui.has_signal("pause_resume_requested"):
		ui.pause_resume_requested.connect(_on_pause_resume_requested)
	if ui.has_signal("pause_main_menu_requested"):
		ui.pause_main_menu_requested.connect(_on_pause_main_menu_requested)
	if ui.has_signal("pause_quit_requested"):
		ui.pause_quit_requested.connect(_on_pause_quit_requested)
	if ui.has_signal("pause_settings_requested"):
		ui.pause_settings_requested.connect(_on_pause_settings_requested)
	if ui.has_signal("summary_back_to_menu_requested"):
		ui.summary_back_to_menu_requested.connect(_on_summary_back_to_menu_requested)

	ui.configure_character_select(
		DataRegistry.get_characters(),
		ProfileStore.get_unlocked_characters(),
		selected_character_id
	)
	ui.configure_map_select(DataRegistry.get_maps(), selected_map_id)
	ui.configure_contract_select(
		DataRegistry.get_contracts(),
		selected_contract_ids,
		DataRegistry.get_contract_max_select()
	)

	if _has_embedded_session_request():
		call_deferred("_boot_embedded_session")
	else:
		_set_state(STATE_MENU)
	if _can_use_scene_transition() and SceneTransition.has_method("fade_in"):
		SceneTransition.fade_in(0.16)
	_refresh_hud()


func _process(delta: float) -> void:
	var now_usec := Time.get_ticks_usec()
	if hitstop_active and now_usec >= hitstop_end_usec:
		hitstop_active = false
		hitstop_recovering = true
		hitstop_recover_start_usec = now_usec
		hitstop_recover_end_usec = now_usec + int(HITSTOP_RECOVER_SEC * 1000000.0)
		hitstop_recover_start_scale = clampf(Engine.time_scale, 0.0, 1.0)
	if hitstop_recovering:
		var recover_total := maxf(1.0, float(hitstop_recover_end_usec - hitstop_recover_start_usec))
		var recover_t := clampf(float(now_usec - hitstop_recover_start_usec) / recover_total, 0.0, 1.0)
		var eased := recover_t * recover_t * (3.0 - 2.0 * recover_t)
		Engine.time_scale = lerpf(hitstop_recover_start_scale, 1.0, eased)
		if recover_t >= 1.0:
			_clear_hitstop_state(true)

	if run_state == STATE_LEVEL_UP and not get_tree().paused:
		get_tree().paused = true

	var player_noise := fixed_noise_value
	if world != null and world.player != null:
		var player_node: Node = world.player
		if fixed_noise_enabled:
			if player_node.has_method("set_noise_value"):
				player_node.call("set_noise_value", fixed_noise_value)
		else:
			if player_node.has_method("get_noise_value"):
				player_noise = float(player_node.call("get_noise_value"))
			else:
				var legacy_noise: Variant = player_node.get("noise")
				if typeof(legacy_noise) == TYPE_FLOAT or typeof(legacy_noise) == TYPE_INT:
					player_noise = float(legacy_noise)
			fixed_noise_value = player_noise
	if run_state == STATE_PLAYING and kill_streak_timer > 0.0:
		kill_streak_timer = maxf(0.0, kill_streak_timer - delta)
		if kill_streak_timer <= 0.0:
			_reset_kill_streak_state()

	if run_state != STATE_PLAYING:
		if hitstop_active or hitstop_recovering:
			_clear_hitstop_state(true)
		_push_debug_snapshot()
		return
	elapsed_time += delta
	run_stats.survive_time_seconds = elapsed_time
	if embedded_session_mode and embedded_session_duration_sec > 0.0 and elapsed_time >= embedded_session_duration_sec:
		_complete_embedded_session()
		_push_debug_snapshot()
		return
	var map_snapshot: Dictionary = world.update_map_runtime(delta)
	if not map_snapshot.is_empty():
		_sync_runtime_fog_overlay()
	run_stats.max_noise_reached = maxf(run_stats.max_noise_reached, player_noise)
	var noise_tier: Dictionary = DataRegistry.get_noise_tier(player_noise)
	run_stats.max_noise_tier_id = String(noise_tier.get("id", run_stats.max_noise_tier_id))
	world.enemy_manager.update_difficulty(elapsed_time, player_noise)
	_refresh_hud()
	_push_debug_snapshot()


func _on_enemy_killed(enemy_id: String, xp_reward: int, world_position: Vector2, meta: Dictionary = {}) -> void:
	kills += 1
	run_stats.total_kills += 1
	var elite_or_pursuer_kill := bool(meta.get("is_elite", false)) or bool(meta.get("is_pursuer", false))
	var enemy_def := DataRegistry.get_enemy(enemy_id)
	var tags_variant: Variant = enemy_def.get("tags", [])
	if not elite_or_pursuer_kill and tags_variant is Array:
		var tags: Array = tags_variant
		if tags.has("elite") or tags.has("pursuer"):
			elite_or_pursuer_kill = true
	if not elite_or_pursuer_kill and enemy_id.find("pursuer") >= 0:
		elite_or_pursuer_kill = true
	if elite_or_pursuer_kill:
		run_stats.elite_or_pursuer_kills += 1
	var drop_mult := maxf(0.0, float(run_reward_multipliers.get("drop", 1.0)))
	var spawn_count := 1
	if not is_equal_approx(drop_mult, 1.0):
		if drop_mult < 1.0:
			spawn_count = 1 if reward_rng.randf() < drop_mult else 0
		else:
			spawn_count = int(floor(drop_mult))
			if reward_rng.randf() < (drop_mult - float(spawn_count)):
				spawn_count += 1
	if spawn_count > 0:
		runtime_drop_pickups_spawned += spawn_count
		for i in range(spawn_count):
			var spawn_position := world_position
			if spawn_count > 1:
				var angle := reward_rng.randf_range(0.0, TAU)
				var radius := reward_rng.randf_range(8.0, 22.0)
				spawn_position = world_position + Vector2.RIGHT.rotated(angle) * radius
			world.call_deferred("spawn_xp_pickup", spawn_position, xp_reward)
	_register_kill_streak(world_position)


func _on_pickup_collected(_world_position: Vector2, _amount: int) -> void:
	run_stats.pickups_collected += 1


func _register_kill_streak(world_position: Vector2) -> void:
	if run_state != STATE_PLAYING or world == null:
		return
	if kill_streak_timer <= 0.0:
		kill_streak_count = 0
		kill_streak_reward_tier = 0
	kill_streak_count += 1
	kill_streak_timer = KILL_STREAK_WINDOW_SEC
	var target_tier := clampi(kill_streak_count / KILL_STREAK_STEP, 0, KILL_STREAK_MAX_REWARD_TIER)
	while kill_streak_reward_tier < target_tier:
		kill_streak_reward_tier += 1
		_grant_kill_streak_reward(kill_streak_reward_tier, world_position)


func _grant_kill_streak_reward(tier: int, origin: Vector2) -> void:
	if world == null or world.player == null:
		return
	var pickup_count := clampi(2 + tier, 3, 12)
	var pickup_xp := clampi(3 + tier * 2, 4, 24)
	runtime_drop_pickups_spawned += pickup_count
	for i in range(pickup_count):
		var angle := reward_rng.randf_range(0.0, TAU)
		var radius := reward_rng.randf_range(26.0, 96.0)
		var spawn_pos := origin + Vector2.RIGHT.rotated(angle) * radius
		world.call_deferred("spawn_xp_pickup", spawn_pos, pickup_xp)

	if world.player.has_method("add_noise_delta"):
		world.player.call("add_noise_delta", -2.0 - float(tier) * 0.75)
	world.player.skill_cd_remaining = maxf(
		0.0,
		float(world.player.skill_cd_remaining) - (0.30 + float(tier) * 0.20)
	)
	if tier % 2 == 0:
		FeedbackBus.emit_sonar_pulse(origin, {
			"source": "flare",
			"strength": 0.82 + float(tier) * 0.06,
			"screen_flash": 1.10,
			"radius_scale": 1.12,
			"speed": 920.0
		})
	if ui != null:
		ui.show_system_message(_t("sys.kill_streak_reward", {"streak": kill_streak_count, "tier": tier}), false)


func _reset_kill_streak_state() -> void:
	kill_streak_count = 0
	kill_streak_timer = 0.0
	kill_streak_reward_tier = 0


func _on_pursuer_spawned(_enemy_id: String, _world_position: Vector2, spawned_total: int, next_eta: float) -> void:
	if run_state != STATE_PLAYING:
		return
	_emit_telegraph_warning(
		"pursuer",
		1.75,
		2.2,
		"pursuer_inbound",
		{
			"spawned_total": spawned_total,
			"next_eta": next_eta
		}
	)


func _on_boss_spawned(_boss_id: String, _phase_id: String, telegraph_text: String) -> void:
	if run_state != STATE_PLAYING:
		return
	_emit_telegraph_warning(
		"boss",
		2.1,
		2.4,
		"boss_spawn",
		{
			"telegraph_text": telegraph_text
		}
	)


func _on_boss_phase_changed(_boss_id: String, _phase_id: String, telegraph_text: String) -> void:
	if run_state != STATE_PLAYING:
		return
	_emit_telegraph_warning(
		"boss",
		2.45 if _phase_id == "phase_2" else 2.0,
		2.2,
		"boss_phase_shift",
		{
			"telegraph_text": telegraph_text,
			"phase_id": _phase_id
		}
	)


func _on_boss_attack_telegraph_requested(telegraph_type: String, _payload: Dictionary) -> void:
	if run_state != STATE_PLAYING:
		return
	var kind := telegraph_type.strip_edges().to_lower()
	if kind != "line" and kind != "cone":
		return
	_emit_telegraph_warning(
		"boss_attack",
		2.05,
		1.0,
		"boss_attack_warning",
		{
			"telegraph_type": kind
		},
		"boss_attack_major",
		0.9
	)


func _on_boss_defeated(_boss_id: String) -> void:
	if run_state != STATE_PLAYING:
		return
	ui.show_system_message(_t("sys.boss_eliminated"), false)


func _on_boss_echoes_spawned(_boss_id: String, count: int, _world_position: Vector2) -> void:
	if run_state != STATE_PLAYING:
		return
	_emit_telegraph_warning(
		"boss",
		2.25,
		1.9,
		"boss_echoes",
		{
			"count": count
		}
	)


func _on_boss_true_form_revealed(_boss_id: String, _world_position: Vector2) -> void:
	if run_state != STATE_PLAYING:
		return
	_emit_telegraph_warning(
		"boss",
		2.35,
		1.8,
		"boss_true_form_revealed",
		{}
	)


func _on_player_level_up_requested(options: Array) -> void:
	_level_up_option_ids.clear()
	for option_variant in options:
		if not (option_variant is Dictionary):
			continue
		var option: Dictionary = option_variant
		var option_id := String(option.get("id", "")).strip_edges()
		if option_id.is_empty():
			continue
		_level_up_option_ids[option_id] = true
	if _level_up_option_ids.is_empty():
		push_warning("Level-up requested without valid options; ignoring.")
		return
	_set_state(STATE_LEVEL_UP)
	ui.show_level_up(options)


func _on_upgrade_selected(upgrade_id: String) -> void:
	if run_state != STATE_LEVEL_UP:
		return
	var resolved_upgrade_id := upgrade_id.strip_edges()
	if resolved_upgrade_id.is_empty() or not _level_up_option_ids.has(resolved_upgrade_id):
		push_warning("Ignoring unexpected upgrade selection outside current level-up options: %s" % upgrade_id)
		return
	_level_up_option_ids.clear()
	ui.hide_level_up()
	world.player.apply_upgrade(resolved_upgrade_id)
	if not world.player.level_up_open:
		_set_state(STATE_PLAYING)
	_refresh_hud()


func _on_player_attack_mode_changed(_is_auto: bool) -> void:
	_refresh_hud()


func _normalize_hit_payload_tags(tags_variant: Variant) -> Array:
	var tags: Array = []
	if not (tags_variant is Array):
		return tags
	for item in (tags_variant as Array):
		var tag := String(item).strip_edges().to_lower()
		if tag.is_empty() or tags.has(tag):
			continue
		tags.append(tag)
	return tags


func _resolve_hit_feedback_style(payload: Dictionary) -> Dictionary:
	var weapon_id := String(payload.get("weapon_id", "")).strip_edges().to_lower()
	var attack_model := String(payload.get("attack_model", "")).strip_edges().to_lower()
	var tags := _normalize_hit_payload_tags(payload.get("weapon_tags", payload.get("tags", [])))
	var fx_color_hex := String(payload.get("fx_color", "")).strip_edges()
	if (attack_model.is_empty() or tags.is_empty() or fx_color_hex.is_empty()) and not weapon_id.is_empty():
		var weapon_def := DataRegistry.get_weapon_runtime(weapon_id)
		if attack_model.is_empty():
			attack_model = String(weapon_def.get("attack_model", "")).strip_edges().to_lower()
		if tags.is_empty():
			tags = _normalize_hit_payload_tags(weapon_def.get("tags", []))
		if fx_color_hex.is_empty():
			fx_color_hex = String(weapon_def.get("fx_color", "")).strip_edges()
	var fx_color := Color(0.0, 0.0, 0.0, 0.0)
	if not fx_color_hex.is_empty():
		fx_color = Color.from_string(fx_color_hex, Color(0.0, 0.0, 0.0, 0.0))
	var style_variant: Variant = CombatPaletteClass.hit_feedback_profile(attack_model, tags, fx_color, weapon_id)
	return style_variant if style_variant is Dictionary else {}


func _build_hit_shake_profile(
	world_position: Vector2,
	intensity: float,
	is_crit: bool,
	killed: bool,
	style: Dictionary
) -> Dictionary:
	var family := String(style.get("family", "tech")).strip_edges().to_lower()
	var profile := {
		"amplitude_mult": 1.0,
		"freq_mult": 1.0,
		"decay_mult": 1.0,
		"response_mult": 1.0,
		"rotation_mult": 1.0,
		"axis_scale": Vector2.ONE,
		"direction": Vector2.ZERO,
		"directional_impulse": 0.16,
		"directional_decay": 9.0,
		"afterimage_strength": 0.16,
		"afterimage_decay": 5.8,
		"afterimage_curve": 1.45
	}
	match family:
		"ballistic":
			profile["amplitude_mult"] = 1.06
			profile["freq_mult"] = 1.32
			profile["decay_mult"] = 1.08
			profile["response_mult"] = 1.18
			profile["rotation_mult"] = 1.02
			profile["axis_scale"] = Vector2(1.28, 0.92)
			profile["directional_impulse"] = 0.24
			profile["directional_decay"] = 11.0
			profile["afterimage_strength"] = 0.14
			profile["afterimage_decay"] = 6.4
			profile["afterimage_curve"] = 1.35
		"pulse":
			profile["amplitude_mult"] = 0.98
			profile["freq_mult"] = 0.94
			profile["decay_mult"] = 0.82
			profile["response_mult"] = 0.92
			profile["rotation_mult"] = 0.86
			profile["axis_scale"] = Vector2(0.88, 1.22)
			profile["directional_impulse"] = 0.12
			profile["directional_decay"] = 7.2
			profile["afterimage_strength"] = 0.36
			profile["afterimage_decay"] = 4.8
			profile["afterimage_curve"] = 1.90
		"beam":
			profile["amplitude_mult"] = 1.10
			profile["freq_mult"] = 1.12
			profile["decay_mult"] = 0.96
			profile["response_mult"] = 1.06
			profile["rotation_mult"] = 1.25
			profile["axis_scale"] = Vector2(1.36, 0.74)
			profile["directional_impulse"] = 0.20
			profile["directional_decay"] = 9.8
			profile["afterimage_strength"] = 0.28
			profile["afterimage_decay"] = 5.2
			profile["afterimage_curve"] = 1.65
		"chain":
			profile["amplitude_mult"] = 1.12
			profile["freq_mult"] = 1.48
			profile["decay_mult"] = 1.18
			profile["response_mult"] = 1.22
			profile["rotation_mult"] = 1.14
			profile["axis_scale"] = Vector2(1.22, 1.10)
			profile["directional_impulse"] = 0.26
			profile["directional_decay"] = 12.0
			profile["afterimage_strength"] = 0.24
			profile["afterimage_decay"] = 6.8
			profile["afterimage_curve"] = 1.38
		"ordnance":
			profile["amplitude_mult"] = 1.22
			profile["freq_mult"] = 0.72
			profile["decay_mult"] = 0.74
			profile["response_mult"] = 0.84
			profile["rotation_mult"] = 0.72
			profile["axis_scale"] = Vector2(0.96, 1.42)
			profile["directional_impulse"] = 0.34
			profile["directional_decay"] = 8.4
			profile["afterimage_strength"] = 0.44
			profile["afterimage_decay"] = 3.6
			profile["afterimage_curve"] = 2.20
		"summon":
			profile["amplitude_mult"] = 0.96
			profile["freq_mult"] = 1.22
			profile["decay_mult"] = 0.92
			profile["response_mult"] = 1.08
			profile["rotation_mult"] = 0.90
			profile["axis_scale"] = Vector2(0.90, 1.06)
			profile["directional_impulse"] = 0.14
			profile["directional_decay"] = 8.2
			profile["afterimage_strength"] = 0.30
			profile["afterimage_decay"] = 5.5
			profile["afterimage_curve"] = 1.70
		"blade":
			profile["amplitude_mult"] = 1.18
			profile["freq_mult"] = 1.36
			profile["decay_mult"] = 1.16
			profile["response_mult"] = 1.26
			profile["rotation_mult"] = 1.32
			profile["axis_scale"] = Vector2(1.30, 0.86)
			profile["directional_impulse"] = 0.30
			profile["directional_decay"] = 11.2
			profile["afterimage_strength"] = 0.18
			profile["afterimage_decay"] = 6.0
			profile["afterimage_curve"] = 1.28
		"sonic":
			profile["amplitude_mult"] = 1.00
			profile["freq_mult"] = 1.08
			profile["decay_mult"] = 0.88
			profile["response_mult"] = 1.04
			profile["rotation_mult"] = 0.88
			profile["axis_scale"] = Vector2(0.84, 1.28)
			profile["directional_impulse"] = 0.16
			profile["directional_decay"] = 7.6
			profile["afterimage_strength"] = 0.38
			profile["afterimage_decay"] = 4.4
			profile["afterimage_curve"] = 2.10
		_:
			pass
	var normalized := clampf(intensity, 0.04, 1.0)
	profile["directional_impulse"] = clampf(
		float(profile.get("directional_impulse", 0.16))
		+ normalized * 0.22
		+ (0.08 if is_crit else 0.0)
		+ (0.10 if killed else 0.0),
		0.0,
		1.0
	)
	profile["afterimage_strength"] = clampf(
		float(profile.get("afterimage_strength", 0.16))
		+ normalized * 0.26
		+ (0.09 if is_crit else 0.0)
		+ (0.07 if killed else 0.0),
		0.0,
		1.0
	)
	profile["amplitude_mult"] = clampf(
		float(profile.get("amplitude_mult", 1.0))
		+ normalized * 0.14
		+ (0.06 if is_crit else 0.0)
		+ (0.08 if killed else 0.0),
		0.60,
		1.90
	)
	var direction := Vector2.ZERO
	if world != null and world.player != null and world.player is Node2D:
		var player_node := world.player as Node2D
		var from_player: Vector2 = world_position - player_node.global_position
		if from_player.length() > 0.01:
			direction = from_player.normalized()
	if direction.length() <= 0.01:
		direction = Vector2.RIGHT.rotated(rng.randf_range(0.0, TAU))
	profile["direction"] = direction
	return profile


func _on_hit_landed_detailed(world_position: Vector2, intensity: float, killed: bool, payload: Dictionary) -> void:
	_on_hit_landed(world_position, intensity, killed, payload)


func _on_hit_landed(world_position: Vector2, intensity: float, killed: bool, payload: Dictionary = {}) -> void:
	if run_state != STATE_PLAYING:
		return
	var is_crit := bool(payload.get("is_crit", payload.get("crit", false)))
	var style := _resolve_hit_feedback_style(payload)
	var shake_profile := _build_hit_shake_profile(world_position, intensity, is_crit, killed, style)
	var amplitude_mult := clampf(float(shake_profile.get("amplitude_mult", 1.0)), 0.60, 1.90)
	var shake := (0.06 + intensity * 0.14 + (0.04 if is_crit else 0.0) + (0.03 if killed else 0.0)) * amplitude_mult
	world.apply_screen_shake(shake, shake_profile)
	var hitstop_duration := 0.030 + intensity * 0.050 + (0.010 if killed else 0.0) + (0.008 if is_crit else 0.0)
	var hitstop_intensity := intensity + (0.14 if is_crit else 0.0) + (0.08 if killed else 0.0)
	_apply_hitstop(hitstop_duration, hitstop_intensity, killed)


func _on_map_event_triggered(_event_id: String, event_name: String, message: String) -> void:
	if run_state != STATE_PLAYING:
		return
	var text := message
	if text.strip_edges().is_empty():
		text = _t("sys.event_triggered", {"name": event_name})
	ui.show_system_message(text, false)


func _on_hazard_state_changed(active: bool, warning_text: String) -> void:
	if run_state != STATE_PLAYING:
		return
	var text := warning_text.strip_edges()
	if text.is_empty():
		text = _t("sys.hazard_shift")
	_emit_telegraph_warning(
		"hazard",
		1.85 if active else 1.2,
		2.0 if active else 1.4,
		"hazard_active" if active else "hazard_warning",
		{
			"warning_text": text
		}
	)


func _apply_hitstop(duration: float, intensity: float = 0.5, killed: bool = false) -> void:
	if run_state != STATE_PLAYING:
		return
	var clamped_duration := clampf(duration, HITSTOP_MIN_DURATION_SEC, HITSTOP_MAX_DURATION_SEC)
	var normalized_intensity := clampf(intensity, 0.0, 1.0)
	var target_scale := lerpf(HITSTOP_BASE_SCALE, HITSTOP_MIN_SCALE, pow(normalized_intensity, 0.72))
	if killed:
		target_scale = maxf(0.03, target_scale - HITSTOP_KILL_SCALE_BONUS)
	var now_usec := Time.get_ticks_usec()
	if not hitstop_active:
		hitstop_low_scale = target_scale
	else:
		hitstop_low_scale = minf(hitstop_low_scale, target_scale)
	hitstop_active = true
	hitstop_recovering = false
	hitstop_end_usec = maxi(hitstop_end_usec, now_usec + int(clamped_duration * 1000000.0))
	Engine.time_scale = minf(Engine.time_scale, hitstop_low_scale)


func _clear_hitstop_state(reset_time_scale: bool = false) -> void:
	hitstop_active = false
	hitstop_end_usec = 0
	hitstop_recovering = false
	hitstop_recover_start_usec = 0
	hitstop_recover_end_usec = 0
	hitstop_recover_start_scale = 1.0
	hitstop_low_scale = 1.0
	if reset_time_scale:
		Engine.time_scale = 1.0


func _on_player_died() -> void:
	if run_state != STATE_PLAYING:
		return
	if _game_over_latched:
		return
	_game_over_latched = true
	var summary_state := _build_embedded_session_summary("abandoned")
	if _can_use_scene_transition() and SceneTransition.has_method("play_pulse"):
		SceneTransition.play_pulse(0.18)
	_set_state(STATE_GAME_OVER)
	if embedded_session_mode:
		embedded_session_finished.emit(summary_state)
		return
	ui.show_game_over(summary_state)


func _complete_embedded_session(exit_reason: String = "completed") -> void:
	if run_state != STATE_PLAYING or not embedded_session_mode or _game_over_latched:
		return
	_game_over_latched = true
	var normalized_exit_reason := exit_reason.strip_edges().to_lower()
	if normalized_exit_reason != "completed" and normalized_exit_reason != "extracted":
		normalized_exit_reason = "completed"
	var summary_state := _build_embedded_session_summary(normalized_exit_reason)
	_set_state(STATE_GAME_OVER)
	embedded_session_finished.emit(summary_state)


func _on_retry_requested() -> void:
	get_tree().set_deferred("paused", false)
	_clear_hitstop_state(true)
	if _can_use_scene_transition() and SceneTransition.has_method("transition_call"):
		SceneTransition.transition_call(Callable(self, "_retry_run"), 0.18)
		return
	_retry_run()


func _on_summary_back_to_menu_requested() -> void:
	get_tree().set_deferred("paused", false)
	_clear_hitstop_state(true)
	if _can_use_scene_transition() and SceneTransition.has_method("transition_call"):
		SceneTransition.transition_call(Callable(self, "_return_to_menu"), 0.16)
		return
	_return_to_menu()


func _on_main_menu_start_requested() -> void:
	ui.configure_character_select(
		DataRegistry.get_characters(),
		ProfileStore.get_unlocked_characters(),
		selected_character_id
	)
	ui.configure_map_select(DataRegistry.get_maps(), selected_map_id)
	ui.configure_contract_select(
		DataRegistry.get_contracts(),
		selected_contract_ids,
		DataRegistry.get_contract_max_select()
	)
	_transition_to_state(STATE_CHARACTER_SELECT, 0.14)


func _on_pause_resume_requested() -> void:
	if run_state != STATE_PAUSED:
		return
	_set_state(STATE_PLAYING)
	_refresh_hud()


func _on_pause_main_menu_requested() -> void:
	if run_state != STATE_PAUSED:
		return
	get_tree().set_deferred("paused", false)
	_clear_hitstop_state(true)
	if embedded_session_mode:
		var summary_state := _build_embedded_session_summary("abandoned")
		_set_state(STATE_GAME_OVER)
		embedded_session_finished.emit(summary_state)
		return
	if _can_use_scene_transition() and SceneTransition.has_method("transition_call"):
		SceneTransition.transition_call(Callable(self, "_return_to_menu"), 0.16)
		return
	_return_to_menu()


func _on_pause_quit_requested() -> void:
	get_tree().quit()


func _on_pause_settings_requested() -> void:
	ui.show_system_message(_t("sys.settings_coming"), false)


func _on_start_run_requested(character_id: String) -> void:
	var chosen_id := character_id.strip_edges()
	if chosen_id.is_empty():
		chosen_id = DataRegistry.get_default_character_id()
	if not ProfileStore.is_character_unlocked(chosen_id):
		ui.show_system_message(_t("sys.character_locked"), true)
		return
	selected_character_id = chosen_id
	ProfileStore.set_selected_character_id(selected_character_id)
	ui.configure_map_select(DataRegistry.get_maps(), selected_map_id)
	_transition_to_state(STATE_MAP_SELECT, 0.14)


func _on_character_select_back_requested() -> void:
	_transition_to_state(STATE_MENU, 0.12)


func _on_map_select_start_requested(map_id: String) -> void:
	selected_map_id = map_id
	ui.configure_contract_select(
		DataRegistry.get_contracts(),
		selected_contract_ids,
		DataRegistry.get_contract_max_select()
	)
	_transition_to_state(STATE_CONTRACT_SELECT, 0.14)


func _on_map_select_back_requested() -> void:
	_transition_to_state(STATE_CHARACTER_SELECT, 0.12)


func _on_contract_select_start_requested(contract_ids: Array[String]) -> void:
	_start_run(selected_character_id, selected_map_id, contract_ids)


func _on_run_setup_start_requested(run_config: Dictionary) -> void:
	var character_id := String(run_config.get("character_id", selected_character_id)).strip_edges()
	var map_id := String(run_config.get("map_id", selected_map_id)).strip_edges()
	var contract_ids: Array = []
	var contract_ids_variant: Variant = run_config.get("contract_ids", [])
	if contract_ids_variant is Array:
		contract_ids = (contract_ids_variant as Array).duplicate()
	_start_run(character_id, map_id, contract_ids)


func _on_contract_select_back_requested() -> void:
	_transition_to_state(STATE_MAP_SELECT, 0.12)


func _on_unlock_all_debug_requested() -> void:
	if not OS.is_debug_build():
		return
	ProfileStore.unlock_all_characters(DataRegistry.get_characters())
	ui.refresh_character_unlocks(ProfileStore.get_unlocked_characters())
	ui.show_system_message(_t("sys.debug_unlock_all"), false)


func _start_run(character_id: String, map_id: String = "", contract_ids: Array = [], skip_play_transition: bool = false, seed_override: int = 0) -> void:
	var chosen_id := character_id.strip_edges()
	if chosen_id.is_empty():
		chosen_id = DataRegistry.get_default_character_id()
	if not ProfileStore.is_character_unlocked(chosen_id):
		ui.show_system_message(_t("sys.character_locked"), true)
		return
	var chosen_map_id := map_id.strip_edges()
	if chosen_map_id.is_empty() or not DataRegistry.has_map(chosen_map_id):
		chosen_map_id = DataRegistry.get_default_map_id()
	if chosen_map_id.is_empty() or not DataRegistry.has_map(chosen_map_id):
		ui.show_system_message(_t("sys.map_unavailable"), true)
		return

	selected_character_id = chosen_id
	selected_map_id = chosen_map_id
	selected_contract_ids = DataRegistry.normalize_contract_selection(contract_ids)
	var contract_modifiers := DataRegistry.compose_contract_modifiers(selected_contract_ids)
	var reward_preview := DataRegistry.get_contract_reward_preview(selected_contract_ids)
	set_runtime_reward_multipliers({
		"xp": float(reward_preview.get("xp_mult", 1.0)),
		"rarity": float(reward_preview.get("rarity_mult", 1.0)),
		"drop": float(reward_preview.get("drop_mult", 1.0)),
		"meta_currency": float(reward_preview.get("meta_currency_mult", 1.0))
	})
	ProfileStore.set_selected_character_id(selected_character_id)
	ProfileStore.set_selected_map_id(selected_map_id)
	ProfileStore.set_selected_contract_ids(selected_contract_ids)
	run_seed = seed_override if seed_override != 0 else _next_runtime_seed()
	rng.seed = run_seed
	reward_rng.seed = run_seed ^ 0x5F3759DF
	elapsed_time = 0.0
	kills = 0
	runtime_drop_pickups_spawned = 0
	last_sonar_ping_sequence = 0
	_reset_kill_streak_state()
	_level_up_option_ids.clear()
	_game_over_latched = false
	run_started = true
	run_stats.reset(run_seed)
	telegraph_last_emit_by_key.clear()

	var character_def := DataRegistry.get_character(selected_character_id)
	world.setup_run(rng, character_def, selected_map_id, run_seed, contract_modifiers, selected_contract_ids)
	_apply_runtime_presentation_profile()
	set_runtime_reward_multipliers(run_reward_multipliers)
	if ui != null and ui.has_method("clear_run_summary"):
		ui.clear_run_summary()
	if world != null and world.has_method("begin_run"):
		world.begin_run()
	_sync_runtime_fog_overlay(true)
	fixed_noise_value = _get_player_noise(fixed_noise_value)
	_clear_hitstop_state(true)
	_set_state(STATE_PLAYING)
	if not skip_play_transition and _can_use_scene_transition() and SceneTransition.has_method("play_pulse"):
		SceneTransition.play_pulse(0.14)
	_refresh_hud()


func _evaluate_character_unlocks() -> Array[String]:
	if not run_started:
		return []
	run_started = false
	var summary: Dictionary = run_stats.to_dict()
	summary["survive_time_seconds"] = elapsed_time
	summary["max_noise_reached"] = maxf(float(summary.get("max_noise_reached", 0.0)), _get_player_noise(0.0))
	var noise_tier: Dictionary = DataRegistry.get_noise_tier(float(summary.get("max_noise_reached", 0.0)))
	summary["max_noise_tier_id"] = String(noise_tier.get("id", summary.get("max_noise_tier_id", "silent")))
	var level_reached := 1
	if world != null and world.player != null:
		var hud_data: Dictionary = _get_player_hud_data()
		level_reached = int(hud_data.get("level", level_reached))
	var meta_currency := _calculate_meta_currency_earned(level_reached)
	summary["meta_currency_earned_total"] = int(meta_currency.get("total", 0))
	return ProfileStore.evaluate_character_unlocks(DataRegistry.get_characters(), summary)


func _retry_run() -> void:
	_start_run(selected_character_id, selected_map_id, selected_contract_ids, true)


func _return_to_menu() -> void:
	run_started = false
	_game_over_latched = false
	_set_state(STATE_MENU)


func _build_embedded_session_summary(exit_reason: String) -> Dictionary:
	var newly_unlocked_ids := _evaluate_character_unlocks()
	if not newly_unlocked_ids.is_empty():
		ui.refresh_character_unlocks(ProfileStore.get_unlocked_characters())
	var summary_state := _build_run_summary_state(newly_unlocked_ids)
	summary_state["exit_reason"] = exit_reason
	summary_state["abandoned"] = exit_reason == "abandoned"
	return summary_state


func _build_run_summary_state(newly_unlocked_ids: Array[String]) -> Dictionary:
	var map_def := DataRegistry.get_map(selected_map_id)
	var map_name := String(map_def.get("name", selected_map_id))
	var contract_names: Array[String] = []
	for contract_id in selected_contract_ids:
		var contract := DataRegistry.get_contract(contract_id)
		contract_names.append(String(contract.get("name", contract_id)))

	var reward_preview := run_reward_multipliers
	var top_tags: Array[Dictionary] = []
	var chosen_upgrades: Array[Dictionary] = []
	var weapon_id := ""
	var weapon_name := "--"
	var level_reached := 1
	var revealed_count := 0
	var enemies_seen := kills
	var noise_peak_tier := String(run_stats.max_noise_tier_id)
	var boss_progress := ""
	var boss_debug: Dictionary = {}
	if world != null and world.player != null:
		var hud_data: Dictionary = _get_player_hud_data()
		weapon_id = String(hud_data.get("active_weapon_id", ""))
		weapon_name = String(hud_data.get("active_weapon_name", hud_data.get("active_weapon_id", "--")))
		level_reached = int(hud_data.get("level", level_reached))
		top_tags = _build_summary_top_tags(hud_data.get("acquired_tags", {}))
		chosen_upgrades = _build_summary_chosen_upgrades(hud_data.get("upgrade_stacks", {}))
		var peak_tier := DataRegistry.get_noise_tier(float(run_stats.max_noise_reached))
		noise_peak_tier = String(peak_tier.get("name", noise_peak_tier))
		revealed_count = world.get_revealed_enemy_count()
	if world != null and world.enemy_manager != null:
		enemies_seen = kills + int(world.enemy_manager.get_alive_enemy_count())
		boss_debug = world.enemy_manager.get_noise_debug_snapshot()
		boss_progress = String(boss_debug.get("boss_state", "")).strip_edges()

	var unlock_progress := _build_summary_unlock_progress()
	var meta_currency_earned := _calculate_meta_currency_earned(level_reached)
	var newly_unlocked_names: Array[String] = []
	for character_id in newly_unlocked_ids:
		var character := DataRegistry.get_character(character_id)
		newly_unlocked_names.append(String(character.get("display_name", character_id)))

	return {
		"time_survived_sec": elapsed_time,
		"kills": kills,
		"level": level_reached,
		"noise_peak_tier": noise_peak_tier,
		"enemies_seen": enemies_seen,
		"revealed_count": revealed_count,
		"boss_progress": boss_progress,
		"weapon_id": weapon_id,
		"weapon_name": weapon_name,
		"top_tags": top_tags,
		"chosen_upgrades": chosen_upgrades,
		"map_id": selected_map_id,
		"map_name": map_name,
		"contract_ids": selected_contract_ids.duplicate(),
		"contract_names": contract_names,
		"drop_pickups_spawned": runtime_drop_pickups_spawned,
		"multipliers": {
			"xp": float(reward_preview.get("xp", reward_preview.get("xp_mult", 1.0))),
			"rarity": float(reward_preview.get("rarity", reward_preview.get("rarity_mult", 1.0))),
			"drop": float(reward_preview.get("drop", reward_preview.get("drop_mult", 1.0))),
			"meta_currency": float(reward_preview.get("meta_currency", reward_preview.get("meta_currency_mult", 1.0)))
		},
		"meta_currency_earned": meta_currency_earned,
		"unlock_progress": unlock_progress,
		"newly_unlocked_names": newly_unlocked_names,
		"seed": run_seed
	}


func _calculate_meta_currency_earned(level_reached: int) -> Dictionary:
	var safe_level := maxi(1, level_reached)
	var base := maxi(1, int(floor(elapsed_time / 30.0)) + int(floor(float(kills) / 12.0)) + int(floor(float(safe_level) / 2.0)))
	var mult := maxf(0.0, float(run_reward_multipliers.get("meta_currency", 1.0)))
	var total := maxi(0, int(round(float(base) * mult)))
	return {
		"base": base,
		"multiplier": mult,
		"total": total
	}


func _normalize_runtime_reward_multipliers(multipliers: Dictionary = {}) -> Dictionary:
	return {
		"xp": maxf(0.0, float(multipliers.get("xp", multipliers.get("xp_mult", 1.0)))),
		"rarity": maxf(0.0, float(multipliers.get("rarity", multipliers.get("rarity_mult", 1.0)))),
		"drop": maxf(0.0, float(multipliers.get("drop", multipliers.get("drop_mult", 1.0)))),
		"meta_currency": maxf(0.0, float(multipliers.get("meta_currency", multipliers.get("meta_currency_mult", 1.0))))
	}


func _build_summary_top_tags(acquired_variant: Variant) -> Array[Dictionary]:
	if not (acquired_variant is Dictionary):
		return []
	var acquired_tags: Dictionary = acquired_variant
	var rows: Array[Dictionary] = []
	for key_variant in acquired_tags.keys():
		var tag := String(key_variant).strip_edges().to_lower()
		var weight := int(acquired_tags.get(key_variant, 0))
		if tag.is_empty() or weight <= 0:
			continue
		rows.append({"tag": tag, "weight": weight})
	rows.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var av := int(a.get("weight", 0))
		var bv := int(b.get("weight", 0))
		if av == bv:
			return String(a.get("tag", "")) < String(b.get("tag", ""))
		return av > bv
	)
	if rows.size() > 5:
		rows.resize(5)
	return rows


func _build_summary_chosen_upgrades(stacks_variant: Variant) -> Array[Dictionary]:
	if not (stacks_variant is Dictionary):
		return []
	var stacks: Dictionary = stacks_variant
	var rows: Array[Dictionary] = []
	for key_variant in stacks.keys():
		var upgrade_id := String(key_variant).strip_edges()
		var count := int(stacks.get(key_variant, 0))
		if upgrade_id.is_empty() or count <= 0:
			continue
		var upgrade := DataRegistry.get_upgrade(upgrade_id)
		var rarity := String(upgrade.get("rarity", "common")).to_lower()
		rows.append({
			"id": upgrade_id,
			"name": String(upgrade.get("name", upgrade_id)),
			"rarity": rarity,
			"tags": upgrade.get("tags", []),
			"count": count,
			"rarity_score": _summary_rarity_score(rarity)
		})
	rows.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var ar := int(a.get("rarity_score", 0))
		var br := int(b.get("rarity_score", 0))
		if ar == br:
			return int(a.get("count", 0)) > int(b.get("count", 0))
		return ar > br
	)
	if rows.size() > 6:
		rows.resize(6)
	return rows


func _build_summary_unlock_progress() -> Array[Dictionary]:
	var rows: Array[Dictionary] = []
	for character_variant in DataRegistry.get_characters():
		if not (character_variant is Dictionary):
			continue
		var character: Dictionary = character_variant
		var character_id := String(character.get("id", "")).strip_edges()
		if character_id.is_empty() or ProfileStore.is_character_unlocked(character_id):
			continue
		var unlock_variant: Variant = character.get("unlock", {})
		if not (unlock_variant is Dictionary):
			continue
		var unlock_req: Dictionary = unlock_variant
		var progress := ProfileStore.get_requirement_progress(unlock_req)
		rows.append({
			"character_id": character_id,
			"name": String(character.get("display_name", character_id)),
			"display": String(unlock_req.get("display", "")),
			"ratio": float(progress.get("ratio", 0.0)),
			"text": String(progress.get("text", "")),
			"met": bool(progress.get("met", false))
		})
	rows.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var ar := float(a.get("ratio", 0.0))
		var br := float(b.get("ratio", 0.0))
		if is_equal_approx(ar, br):
			return String(a.get("name", "")) < String(b.get("name", ""))
		return ar > br
	)
	if rows.size() > 3:
		rows.resize(3)
	return rows


func _summary_rarity_score(rarity: String) -> int:
	match rarity:
		"legendary":
			return 5
		"epic":
			return 4
		"rare":
			return 3
		"uncommon":
			return 2
		_:
			return 1


func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey):
		return
	if not event.pressed or event.echo:
		return
	if event.keycode == KEY_ESCAPE:
		if run_state == STATE_PLAYING:
			_set_state(STATE_PAUSED)
			return
		if run_state == STATE_PAUSED:
			_set_state(STATE_PLAYING)
			_refresh_hud()
			return
	if event.keycode == KEY_F2:
		if _uses_clear_dungeon_presentation():
			return
		fog_enabled = not fog_enabled
		world.set_fog_enabled(fog_enabled)
		ui.set_fog_overlay_enabled(fog_enabled)
	elif event.keycode == KEY_F1:
		ui.set_debug_visible(not ui.is_debug_visible())
	elif event.keycode == KEY_F3:
		if _uses_clear_dungeon_presentation():
			return
		sonar_visual_enabled = not sonar_visual_enabled
		world.set_sonar_visual_enabled(sonar_visual_enabled)
	elif event.keycode == KEY_F5:
		_reload_runtime_data()
	elif event.keycode == KEY_F6:
		fixed_noise_enabled = not fixed_noise_enabled
	elif event.keycode == KEY_F7:
		fixed_noise_value = clampf(fixed_noise_value - 10.0, 0.0, 100.0)
		if fixed_noise_enabled and world != null and world.player != null and world.player.has_method("set_noise_value"):
			world.player.call("set_noise_value", fixed_noise_value)
	elif event.keycode == KEY_F8:
		fixed_noise_value = clampf(fixed_noise_value + 10.0, 0.0, 100.0)
		if fixed_noise_enabled and world != null and world.player != null and world.player.has_method("set_noise_value"):
			world.player.call("set_noise_value", fixed_noise_value)


func _set_state(next_state: String) -> void:
	run_state = next_state
	if run_state != STATE_LEVEL_UP:
		_level_up_option_ids.clear()
	if run_state == STATE_PLAYING:
		_clear_hitstop_state(true)
		get_tree().paused = false
	else:
		_clear_hitstop_state(true)
		get_tree().paused = true
		if run_state != STATE_LEVEL_UP and run_state != STATE_PAUSED:
			_reset_kill_streak_state()
	ui.on_game_state_changed(run_state)


func _transition_to_state(next_state: String, duration: float = 0.14) -> void:
	if not _can_use_scene_transition():
		_set_state(next_state)
		return
	if not SceneTransition.has_method("transition_call"):
		_set_state(next_state)
		return
	SceneTransition.transition_call(Callable(self, "_set_state").bind(next_state), duration)


func _can_use_scene_transition() -> bool:
	if DisplayServer.get_name() == "headless":
		return false
	return SceneTransition != null


func _apply_default_window_mode() -> void:
	if DisplayServer.get_name() == "headless":
		return
	if OS.has_feature("web"):
		return
	var mode := DisplayServer.window_get_mode()
	if mode != DisplayServer.WINDOW_MODE_FULLSCREEN and mode != DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED)


func _refresh_hud() -> void:
	var hud: Dictionary = _get_player_hud_data()
	var player_noise := _get_player_noise(fixed_noise_value)
	hud["elapsed_time"] = elapsed_time
	hud["kills"] = kills
	hud["seed"] = run_seed
	hud["enemy_count"] = world.enemy_manager.get_alive_enemy_count()
	hud["revealed_count"] = world.get_revealed_enemy_count()
	var noise_tier: Dictionary = DataRegistry.get_noise_tier(player_noise)
	hud["noise_tier_name"] = String(noise_tier.get("name", "Silent"))
	hud["noise_tier_color"] = String(noise_tier.get("hud_color", "#74e7ff"))
	hud["noise_tier_id"] = String(noise_tier.get("id", "silent"))
	if world.enemy_manager.has_method("populate_hud_debug_fields"):
		world.enemy_manager.populate_hud_debug_fields(hud)
	else:
		var noise_debug: Dictionary = world.enemy_manager.get_noise_debug_snapshot()
		hud["spawn_rate_multiplier"] = float(noise_debug.get("spawn_rate_multiplier", 1.0))
		hud["pursuer_chance"] = float(noise_debug.get("pursuer_chance", 0.0))
		hud["elite_count"] = int(noise_debug.get("elite_count", 0))
		hud["pursuer_count"] = int(noise_debug.get("pursuer_count", 0))
		hud["pursuer_spawned_total"] = int(noise_debug.get("pursuer_spawned_total", 0))
		hud["boss_state"] = String(noise_debug.get("boss_state", "idle"))
		hud["noise_spawn_rate_multiplier"] = float(noise_debug.get("noise_spawn_rate_multiplier", 1.0))
		hud["map_spawn_rate_multiplier"] = float(noise_debug.get("map_spawn_rate_multiplier", 1.0))
		hud["contract_spawn_rate_multiplier"] = float(noise_debug.get("contract_spawn_rate_multiplier", 1.0))
	if world.enemy_manager.has_method("populate_boss_hud_fields"):
		world.enemy_manager.populate_boss_hud_fields(hud)
	else:
		var boss_hud: Dictionary = world.enemy_manager.get_boss_hud_snapshot()
		for key_variant in boss_hud.keys():
			hud[String(key_variant)] = boss_hud.get(key_variant)
	hud["state"] = run_state
	hud["current_map_id"] = world.get_current_map_id()
	hud["contracts_active"] = selected_contract_ids.duplicate()
	hud["kill_streak"] = kill_streak_count
	hud["kill_streak_timer"] = kill_streak_timer
	hud["kill_streak_window"] = KILL_STREAK_WINDOW_SEC
	hud["kill_streak_step"] = KILL_STREAK_STEP
	hud["run_reward_multipliers"] = {
		"xp": float(run_reward_multipliers.get("xp", run_reward_multipliers.get("xp_mult", 1.0))),
		"rarity": float(run_reward_multipliers.get("rarity", run_reward_multipliers.get("rarity_mult", 1.0))),
		"drop": float(run_reward_multipliers.get("drop", run_reward_multipliers.get("drop_mult", 1.0))),
		"meta_currency": float(run_reward_multipliers.get("meta_currency", run_reward_multipliers.get("meta_currency_mult", 1.0)))
	}
	var sonar_ping_sequence := int(hud.get("sonar_ping_sequence", 0))
	if run_state == STATE_PLAYING and sonar_ping_sequence > last_sonar_ping_sequence:
		last_sonar_ping_sequence = sonar_ping_sequence
		var sonar_ping_count := int(hud.get("sonar_ping_count", -1))
		if sonar_ping_count >= 0:
			ui.show_system_message(_t("sys.sonar_ping", {"count": sonar_ping_count}), false)
	ui.update_hud(hud)


func _push_debug_snapshot() -> void:
	var snapshot: Dictionary = _get_player_hud_data()
	var noise_tier_debug: Dictionary = DataRegistry.get_noise_tier(_get_player_noise(fixed_noise_value))
	var noise_debug: Dictionary = world.enemy_manager.get_noise_debug_snapshot()
	var entity_counts: Dictionary = world.get_runtime_entity_counts()
	var pool_stats: Dictionary = world.get_pool_stats()
	var enemy_pool_stats: Dictionary = world.get_enemy_pool_stats()
	var map_debug: Dictionary = world.get_map_debug_snapshot()
	snapshot["noise_tier_name"] = String(noise_tier_debug.get("name", "Silent"))
	snapshot["spawn_rate_multiplier"] = float(noise_debug.get("spawn_rate_multiplier", 1.0))
	snapshot["pursuer_chance"] = float(noise_debug.get("pursuer_chance", 0.0))
	snapshot["elite_count"] = int(noise_debug.get("elite_count", 0))
	snapshot["pursuer_count"] = int(noise_debug.get("pursuer_count", 0))
	snapshot["pursuer_spawned_total"] = int(noise_debug.get("pursuer_spawned_total", 0))
	snapshot["next_pursuer_eta"] = float(noise_debug.get("next_pursuer_eta", -1.0))
	snapshot["boss_state"] = String(noise_debug.get("boss_state", "idle"))
	snapshot["boss_id"] = String(noise_debug.get("boss_id", ""))
	snapshot["boss_decoy_count"] = int(noise_debug.get("boss_decoy_count", 0))
	snapshot["boss_true_form_revealed"] = bool(noise_debug.get("boss_true_form_revealed", false))
	snapshot["boss_telegraph_count"] = world.get_active_boss_telegraph_count()
	snapshot["elite_chance"] = float(noise_debug.get("elite_chance", 0.0))
	snapshot["noise_spawn_rate_multiplier"] = float(noise_debug.get("noise_spawn_rate_multiplier", 1.0))
	snapshot["map_spawn_rate_multiplier"] = float(noise_debug.get("map_spawn_rate_multiplier", 1.0))
	snapshot["contract_spawn_rate_multiplier"] = float(noise_debug.get("contract_spawn_rate_multiplier", 1.0))
	snapshot["revealed_count"] = world.get_revealed_enemy_count()
	snapshot["fps"] = Engine.get_frames_per_second()
	snapshot["enemy_count"] = int(entity_counts.get("enemies", 0))
	snapshot["projectile_count"] = int(entity_counts.get("projectiles", 0))
	snapshot["pickup_count"] = int(entity_counts.get("pickups", 0))
	snapshot["pool_hit_rate"] = float(pool_stats.get("hit_rate", -1.0))
	snapshot["pool_hits"] = int(pool_stats.get("hits", 0))
	snapshot["pool_misses"] = int(pool_stats.get("misses", 0))
	snapshot["enemy_pool_hit_rate"] = float(enemy_pool_stats.get("hit_rate", -1.0))
	snapshot["enemy_pool_hits"] = int(enemy_pool_stats.get("hits", 0))
	snapshot["enemy_pool_misses"] = int(enemy_pool_stats.get("misses", 0))
	snapshot["target_query_count_per_sec"] = float(snapshot.get("target_query_count_per_sec", 0.0))
	snapshot["timeline_progress"] = DataRegistry.get_timeline_progress(elapsed_time)
	snapshot["fixed_noise_enabled"] = fixed_noise_enabled
	snapshot["fixed_noise_value"] = fixed_noise_value
	snapshot["fog_enabled"] = fog_enabled
	snapshot["sonar_visual_enabled"] = sonar_visual_enabled
	snapshot["presentation_profile"] = presentation_profile
	snapshot["fog_version"] = DataRegistry.get_data_version("fog")
	snapshot["sonar_version"] = DataRegistry.get_data_version("sonar")
	snapshot["noise_version"] = DataRegistry.get_data_version("noise")
	snapshot["fog_path"] = DataRegistry.get_data_path("fog")
	snapshot["sonar_path"] = DataRegistry.get_data_path("sonar")
	snapshot["noise_path"] = DataRegistry.get_data_path("noise")
	snapshot["selected_character"] = selected_character_id
	snapshot["selected_map_id"] = selected_map_id
	snapshot["contracts_active"] = world.get_active_contract_ids()
	snapshot["current_map_id"] = String(map_debug.get("current_map_id", ""))
	snapshot["hazard_active"] = bool(map_debug.get("hazard_active", false))
	snapshot["hazard_timer"] = float(map_debug.get("hazard_timer", 0.0))
	snapshot["last_event_triggered"] = String(map_debug.get("last_event_triggered", ""))
	snapshot["map_spawn_multiplier"] = float(map_debug.get("map_spawn_multiplier", 1.0))
	snapshot["total_spawn_multiplier"] = float(noise_debug.get("spawn_rate_multiplier", 1.0))
	snapshot["fog_radius"] = float(map_debug.get("fog_radius", 0.0))
	snapshot["map_noise_gain_multiplier"] = float(map_debug.get("noise_gain_multiplier", 1.0))
	snapshot["contract_event_rate_mult"] = float(map_debug.get("contract_event_rate_mult", 1.0))
	snapshot["maps_version"] = DataRegistry.get_data_version("maps")
	snapshot["hazards_version"] = DataRegistry.get_data_version("hazards")
	snapshot["events_version"] = DataRegistry.get_data_version("events")
	snapshot["maps_path"] = DataRegistry.get_data_path("maps")
	snapshot["hazards_path"] = DataRegistry.get_data_path("hazards")
	snapshot["events_path"] = DataRegistry.get_data_path("events")
	ui.update_debug_data(snapshot)


func _get_player_hud_data() -> Dictionary:
	if world == null or world.player == null:
		return {}
	var player_node: Node = world.player
	if player_node.has_method("get_hud_data"):
		var payload: Variant = player_node.call("get_hud_data")
		if payload is Dictionary:
			return payload as Dictionary
	return {}


func _get_player_noise(default_value: float = 0.0) -> float:
	if world == null or world.player == null:
		return default_value
	var player_node: Node = world.player
	if player_node.has_method("get_noise_value"):
		return float(player_node.call("get_noise_value"))
	var noise_variant: Variant = player_node.get("noise")
	if typeof(noise_variant) == TYPE_FLOAT or typeof(noise_variant) == TYPE_INT:
		return float(noise_variant)
	return default_value


func _sync_runtime_fog_overlay(force: bool = false) -> void:
	var effective_fog: Dictionary = world.get_effective_fog_config()
	if effective_fog.is_empty():
		return
	var signature := JSON.stringify(effective_fog, "")
	if not force and signature == last_fog_overlay_signature:
		return
	last_fog_overlay_signature = signature
	ui.apply_fog_overlay_config(effective_fog)
	ui.set_fog_overlay_enabled(fog_enabled)


func _reload_runtime_data() -> void:
	if not DataRegistry.reload_in_debug():
		var errs: Array[String] = DataRegistry.get_validation_errors()
		var msg := _t("sys.data_reload_failed")
		if not errs.is_empty():
			msg += " " + errs[0]
		ui.show_system_message(msg, true)
		return
	world.player.apply_noise_config(DataRegistry.get_noise_config())
	var fog_cfg: Dictionary = DataRegistry.get_fog_config()
	world.apply_fog_config(fog_cfg)
	world.set_fog_enabled(fog_enabled)
	_sync_runtime_fog_overlay(true)
	var sonar_cfg: Dictionary = DataRegistry.get_sonar_config()
	world.apply_sonar_config(sonar_cfg)
	world.set_sonar_visual_enabled(sonar_visual_enabled)
	_apply_runtime_presentation_profile()
	if selected_map_id.is_empty() or not DataRegistry.has_map(selected_map_id):
		selected_map_id = DataRegistry.get_default_map_id()
	world.set_current_map(selected_map_id, run_seed)
	ui.configure_character_select(
		DataRegistry.get_characters(),
		ProfileStore.get_unlocked_characters(),
		selected_character_id
	)
	ui.configure_map_select(DataRegistry.get_maps(), selected_map_id)
	ui.configure_contract_select(
		DataRegistry.get_contracts(),
		selected_contract_ids,
		DataRegistry.get_contract_max_select()
	)
	ui.show_system_message(_t("sys.data_reloaded"), false)


func _emit_telegraph_warning(
	warning_type: String,
	severity: float,
	duration: float,
	text_key: String,
	context: Dictionary = {},
	throttle_key: String = "",
	throttle_seconds: float = 0.0
) -> void:
	var effective_key := throttle_key.strip_edges()
	if throttle_seconds > 0.0 and not effective_key.is_empty():
		var now_sec := float(Time.get_ticks_msec()) * 0.001
		var last_emit := float(telegraph_last_emit_by_key.get(effective_key, -9999.0))
		if now_sec - last_emit < throttle_seconds:
			return
		telegraph_last_emit_by_key[effective_key] = now_sec
	TelegraphBus.emit_warning(warning_type, severity, duration, text_key, context)


func _on_telegraph_warning_emitted(payload: Dictionary) -> void:
	if run_state != STATE_PLAYING:
		return
	var message := String(payload.get("message", "")).strip_edges()
	if message.is_empty():
		message = TelegraphBus.resolve_text(payload)
	ui.show_telegraph_warning(payload, message)
	world.play_telegraph_sfx(
		String(payload.get("sfx_bucket", "warning")),
		float(payload.get("severity", 1.0)),
		String(payload.get("text_key", ""))
	)


func _t(key: String, args: Dictionary = {}) -> String:
	if Localization == null or not Localization.has_method("t"):
		return key
	return String(Localization.call("t", key, args))


func _exit_tree() -> void:
	if run_started and run_state == STATE_PLAYING:
		_evaluate_character_unlocks()
	_clear_hitstop_state(true)
