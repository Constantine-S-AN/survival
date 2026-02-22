extends Node
class_name GameRoot

const STATE_PLAYING := "playing"
const STATE_LEVEL_UP := "level_up"
const STATE_GAME_OVER := "game_over"
const STATE_MENU := "menu"
const STATE_CHARACTER_SELECT := "character_select"
const STATE_MAP_SELECT := "map_select"
const STATE_CONTRACT_SELECT := "contract_select"
const InputConfig := preload("res://scripts/core/input_config.gd")
const RunStatsClass := preload("res://scripts/core/run_stats.gd")

@onready var world = $World
@onready var ui = $UI

var rng := RandomNumberGenerator.new()
var run_seed := 0
var elapsed_time := 0.0
var kills := 0
var run_state := STATE_MENU
var hitstop_active := false
var hitstop_end_usec: int = 0
var fog_enabled: bool = true
var sonar_visual_enabled: bool = true
var fixed_noise_enabled: bool = false
var fixed_noise_value: float = 0.0
var selected_character_id: String = ""
var selected_map_id: String = ""
var selected_contract_ids: Array[String] = []
var last_fog_overlay_signature: String = ""
var run_started: bool = false
var run_stats = RunStatsClass.new()


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	Engine.time_scale = 1.0
	InputConfig.ensure_default_actions()
	if not DataRegistry.load_all():
		push_error("DataRegistry failed to load JSON. Check console for details.")
	var default_character_id := DataRegistry.get_default_character_id()
	var default_map_id := DataRegistry.get_default_map_id()
	ProfileStore.load_profile(
		default_character_id if not default_character_id.is_empty() else "diver",
		default_map_id
	)
	if not ProfileStore.is_character_unlocked(default_character_id):
		ProfileStore.unlock_character(default_character_id)
	selected_character_id = ProfileStore.get_selected_character_id(default_character_id)
	if not ProfileStore.is_character_unlocked(selected_character_id):
		selected_character_id = default_character_id
	selected_map_id = ProfileStore.get_selected_map_id(default_map_id)
	if selected_map_id.is_empty() or not DataRegistry.has_map(selected_map_id):
		selected_map_id = default_map_id
	selected_contract_ids = DataRegistry.normalize_contract_selection(ProfileStore.get_selected_contract_ids())

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

	world.player.died.connect(_on_player_died)
	world.player.level_up_requested.connect(_on_player_level_up_requested)
	world.player.attack_mode_changed.connect(_on_player_attack_mode_changed)
	world.enemy_manager.enemy_killed.connect(_on_enemy_killed)
	world.enemy_manager.pursuer_spawned.connect(_on_pursuer_spawned)
	world.enemy_manager.boss_spawned.connect(_on_boss_spawned)
	world.enemy_manager.boss_phase_changed.connect(_on_boss_phase_changed)
	world.enemy_manager.boss_defeated.connect(_on_boss_defeated)
	world.map_event_triggered.connect(_on_map_event_triggered)
	world.hazard_state_changed.connect(_on_hazard_state_changed)
	FeedbackBus.hit_landed.connect(_on_hit_landed)
	FeedbackBus.pickup_collected.connect(_on_pickup_collected)

	ui.upgrade_selected.connect(_on_upgrade_selected)
	ui.retry_requested.connect(_on_retry_requested)
	ui.main_menu_start_requested.connect(_on_main_menu_start_requested)
	ui.start_run_requested.connect(_on_start_run_requested)
	ui.character_select_back_requested.connect(_on_character_select_back_requested)
	ui.map_select_start_requested.connect(_on_map_select_start_requested)
	ui.map_select_back_requested.connect(_on_map_select_back_requested)
	ui.contract_select_start_requested.connect(_on_contract_select_start_requested)
	ui.contract_select_back_requested.connect(_on_contract_select_back_requested)
	ui.unlock_all_debug_requested.connect(_on_unlock_all_debug_requested)

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

	_set_state(STATE_MENU)
	_refresh_hud()


func _process(delta: float) -> void:
	if hitstop_active and Time.get_ticks_usec() >= hitstop_end_usec:
		Engine.time_scale = 1.0
		hitstop_active = false

	if fixed_noise_enabled:
		world.player.set_noise_value(fixed_noise_value)
	else:
		fixed_noise_value = world.player.noise

	if run_state != STATE_PLAYING:
		_push_debug_snapshot()
		return
	elapsed_time += delta
	run_stats.survive_time_seconds = elapsed_time
	var map_snapshot: Dictionary = world.update_map_runtime(delta)
	if not map_snapshot.is_empty():
		_sync_runtime_fog_overlay()
	run_stats.max_noise_reached = maxf(run_stats.max_noise_reached, world.player.noise)
	var noise_tier: Dictionary = DataRegistry.get_noise_tier(world.player.noise)
	run_stats.max_noise_tier_id = String(noise_tier.get("id", run_stats.max_noise_tier_id))
	world.enemy_manager.update_difficulty(elapsed_time, world.player.noise)
	_refresh_hud()
	_push_debug_snapshot()


func _on_enemy_killed(enemy_id: String, xp_reward: int, world_position: Vector2, meta: Dictionary = {}) -> void:
	kills += 1
	run_stats.total_kills += 1
	var enemy_def := DataRegistry.get_enemy(enemy_id)
	var tags_variant: Variant = enemy_def.get("tags", [])
	if tags_variant is Array:
		var tags: Array = tags_variant
		if tags.has("elite") or tags.has("pursuer"):
			run_stats.elite_or_pursuer_kills += 1
	if bool(meta.get("is_elite", false)) or bool(meta.get("is_pursuer", false)):
		run_stats.elite_or_pursuer_kills += 1
	if enemy_id.find("pursuer") >= 0 or bool(meta.get("is_pursuer", false)):
		run_stats.elite_or_pursuer_kills += 1
	world.call_deferred("spawn_xp_pickup", world_position, xp_reward)


func _on_pickup_collected(_world_position: Vector2, _amount: int) -> void:
	run_stats.pickups_collected += 1


func _on_pursuer_spawned(_enemy_id: String, _world_position: Vector2, spawned_total: int, next_eta: float) -> void:
	if run_state != STATE_PLAYING:
		return
	ui.show_system_message("Pursuer inbound! (%d) next ETA %.1fs" % [spawned_total, next_eta], true)
	world.play_pursuer_warning_sfx()


func _on_boss_spawned(_boss_id: String, _phase_id: String, telegraph_text: String) -> void:
	if run_state != STATE_PLAYING:
		return
	ui.show_system_message(telegraph_text if not telegraph_text.is_empty() else "Boss detected", true)
	world.play_boss_warning_sfx()


func _on_boss_phase_changed(_boss_id: String, _phase_id: String, telegraph_text: String) -> void:
	if run_state != STATE_PLAYING:
		return
	ui.show_system_message(telegraph_text if not telegraph_text.is_empty() else "Boss phase shift", true)
	world.play_boss_warning_sfx()


func _on_boss_defeated(_boss_id: String) -> void:
	if run_state != STATE_PLAYING:
		return
	ui.show_system_message("Boss eliminated. Signal field stabilizing.", false)


func _on_player_level_up_requested(options: Array) -> void:
	_set_state(STATE_LEVEL_UP)
	ui.show_level_up(options)


func _on_upgrade_selected(upgrade_id: String) -> void:
	ui.hide_level_up()
	world.player.apply_upgrade(upgrade_id)
	if not world.player.level_up_open:
		_set_state(STATE_PLAYING)
	_refresh_hud()


func _on_player_attack_mode_changed(_is_auto: bool) -> void:
	_refresh_hud()


func _on_hit_landed(_world_position: Vector2, intensity: float, _killed: bool) -> void:
	if run_state != STATE_PLAYING:
		return
	world.apply_screen_shake(0.06 + intensity * 0.14)
	_apply_hitstop(0.038 + intensity * 0.04)


func _on_map_event_triggered(_event_id: String, event_name: String, message: String) -> void:
	if run_state != STATE_PLAYING:
		return
	var text := message
	if text.strip_edges().is_empty():
		text = "%s triggered" % event_name
	ui.show_system_message(text, false)


func _on_hazard_state_changed(active: bool, warning_text: String) -> void:
	if run_state != STATE_PLAYING:
		return
	var text := warning_text.strip_edges()
	if text.is_empty():
		text = "Hazard shift"
	if active:
		ui.show_system_message("%s (ACTIVE)" % text, true)
	else:
		ui.show_system_message(text, false)


func _apply_hitstop(duration: float) -> void:
	if hitstop_active:
		return
	hitstop_active = true
	Engine.time_scale = 0.08
	hitstop_end_usec = Time.get_ticks_usec() + int(duration * 1000000.0)


func _on_player_died() -> void:
	var newly_unlocked_ids := _evaluate_character_unlocks()
	var unlocked_names: Array[String] = []
	for character_id in newly_unlocked_ids:
		var character := DataRegistry.get_character(character_id)
		unlocked_names.append(String(character.get("display_name", character_id)))
	if not unlocked_names.is_empty():
		ui.show_unlock_toast(unlocked_names)
		ui.refresh_character_unlocks(ProfileStore.get_unlocked_characters())
	_set_state(STATE_GAME_OVER)
	ui.show_game_over({
		"time": elapsed_time,
		"kills": kills,
		"level": world.player.level,
		"seed": run_seed,
		"unlocked_count": unlocked_names.size()
	})


func _on_retry_requested() -> void:
	get_tree().paused = false
	Engine.time_scale = 1.0
	get_tree().reload_current_scene()


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
	_set_state(STATE_CHARACTER_SELECT)


func _on_start_run_requested(character_id: String) -> void:
	var chosen_id := character_id.strip_edges()
	if chosen_id.is_empty():
		chosen_id = DataRegistry.get_default_character_id()
	if not ProfileStore.is_character_unlocked(chosen_id):
		ui.show_system_message("Character is locked.", true)
		return
	selected_character_id = chosen_id
	ProfileStore.set_selected_character_id(selected_character_id)
	ui.configure_map_select(DataRegistry.get_maps(), selected_map_id)
	_set_state(STATE_MAP_SELECT)


func _on_character_select_back_requested() -> void:
	_set_state(STATE_MENU)


func _on_map_select_start_requested(map_id: String) -> void:
	selected_map_id = map_id
	ui.configure_contract_select(
		DataRegistry.get_contracts(),
		selected_contract_ids,
		DataRegistry.get_contract_max_select()
	)
	_set_state(STATE_CONTRACT_SELECT)


func _on_map_select_back_requested() -> void:
	_set_state(STATE_CHARACTER_SELECT)


func _on_contract_select_start_requested(contract_ids: Array[String]) -> void:
	_start_run(selected_character_id, selected_map_id, contract_ids)


func _on_contract_select_back_requested() -> void:
	_set_state(STATE_MAP_SELECT)


func _on_unlock_all_debug_requested() -> void:
	if not OS.is_debug_build():
		return
	ProfileStore.unlock_all_characters(DataRegistry.get_characters())
	ui.refresh_character_unlocks(ProfileStore.get_unlocked_characters())
	ui.show_system_message("Debug: all characters unlocked.", false)


func _start_run(character_id: String, map_id: String = "", contract_ids: Array = []) -> void:
	var chosen_id := character_id.strip_edges()
	if chosen_id.is_empty():
		chosen_id = DataRegistry.get_default_character_id()
	if not ProfileStore.is_character_unlocked(chosen_id):
		ui.show_system_message("Character is locked.", true)
		return
	var chosen_map_id := map_id.strip_edges()
	if chosen_map_id.is_empty() or not DataRegistry.has_map(chosen_map_id):
		chosen_map_id = DataRegistry.get_default_map_id()
	if chosen_map_id.is_empty() or not DataRegistry.has_map(chosen_map_id):
		ui.show_system_message("Map data unavailable.", true)
		return

	selected_character_id = chosen_id
	selected_map_id = chosen_map_id
	selected_contract_ids = DataRegistry.normalize_contract_selection(contract_ids)
	var contract_modifiers := DataRegistry.compose_contract_modifiers(selected_contract_ids)
	ProfileStore.set_selected_character_id(selected_character_id)
	ProfileStore.set_selected_map_id(selected_map_id)
	ProfileStore.set_selected_contract_ids(selected_contract_ids)
	run_seed = int(Time.get_unix_time_from_system())
	rng.seed = run_seed
	elapsed_time = 0.0
	kills = 0
	run_started = true
	run_stats.reset(run_seed)

	var character_def := DataRegistry.get_character(selected_character_id)
	world.setup_run(rng, character_def, selected_map_id, run_seed, contract_modifiers, selected_contract_ids)
	_sync_runtime_fog_overlay(true)
	fixed_noise_value = world.player.noise
	_set_state(STATE_PLAYING)
	_refresh_hud()


func _evaluate_character_unlocks() -> Array[String]:
	if not run_started:
		return []
	run_started = false
	var summary: Dictionary = run_stats.to_dict()
	summary["survive_time_seconds"] = elapsed_time
	summary["max_noise_reached"] = maxf(float(summary.get("max_noise_reached", 0.0)), world.player.noise)
	var noise_tier: Dictionary = DataRegistry.get_noise_tier(float(summary.get("max_noise_reached", 0.0)))
	summary["max_noise_tier_id"] = String(noise_tier.get("id", summary.get("max_noise_tier_id", "silent")))
	return ProfileStore.evaluate_character_unlocks(DataRegistry.get_characters(), summary)


func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey):
		return
	if not event.pressed or event.echo:
		return
	if event.keycode == KEY_F2:
		fog_enabled = not fog_enabled
		world.set_fog_enabled(fog_enabled)
		ui.set_fog_overlay_enabled(fog_enabled)
	elif event.keycode == KEY_F1:
		ui.set_debug_visible(not ui.is_debug_visible())
	elif event.keycode == KEY_F3:
		sonar_visual_enabled = not sonar_visual_enabled
		world.set_sonar_visual_enabled(sonar_visual_enabled)
	elif event.keycode == KEY_F5:
		_reload_runtime_data()
	elif event.keycode == KEY_F6:
		fixed_noise_enabled = not fixed_noise_enabled
	elif event.keycode == KEY_F7:
		fixed_noise_value = clampf(fixed_noise_value - 10.0, 0.0, 100.0)
		if fixed_noise_enabled:
			world.player.set_noise_value(fixed_noise_value)
	elif event.keycode == KEY_F8:
		fixed_noise_value = clampf(fixed_noise_value + 10.0, 0.0, 100.0)
		if fixed_noise_enabled:
			world.player.set_noise_value(fixed_noise_value)


func _set_state(next_state: String) -> void:
	run_state = next_state
	get_tree().paused = run_state != STATE_PLAYING
	ui.on_game_state_changed(run_state)


func _refresh_hud() -> void:
	var hud: Dictionary = world.player.get_hud_data()
	hud["elapsed_time"] = elapsed_time
	hud["kills"] = kills
	hud["seed"] = run_seed
	hud["enemy_count"] = world.enemy_manager.get_alive_enemy_count()
	hud["revealed_count"] = world.get_revealed_enemy_count()
	var noise_tier: Dictionary = DataRegistry.get_noise_tier(world.player.noise)
	hud["noise_tier_name"] = String(noise_tier.get("name", "静默"))
	hud["noise_tier_color"] = String(noise_tier.get("hud_color", "#74e7ff"))
	hud["noise_tier_id"] = String(noise_tier.get("id", "silent"))
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
	hud["state"] = run_state
	hud["contracts_active"] = selected_contract_ids.duplicate()
	ui.update_hud(hud)


func _push_debug_snapshot() -> void:
	var snapshot: Dictionary = world.player.get_hud_data()
	var noise_tier_debug: Dictionary = DataRegistry.get_noise_tier(world.player.noise)
	var noise_debug: Dictionary = world.enemy_manager.get_noise_debug_snapshot()
	var entity_counts: Dictionary = world.get_runtime_entity_counts()
	var pool_stats: Dictionary = world.get_pool_stats()
	var map_debug: Dictionary = world.get_map_debug_snapshot()
	snapshot["noise_tier_name"] = String(noise_tier_debug.get("name", "静默"))
	snapshot["spawn_rate_multiplier"] = float(noise_debug.get("spawn_rate_multiplier", 1.0))
	snapshot["pursuer_chance"] = float(noise_debug.get("pursuer_chance", 0.0))
	snapshot["elite_count"] = int(noise_debug.get("elite_count", 0))
	snapshot["pursuer_count"] = int(noise_debug.get("pursuer_count", 0))
	snapshot["pursuer_spawned_total"] = int(noise_debug.get("pursuer_spawned_total", 0))
	snapshot["next_pursuer_eta"] = float(noise_debug.get("next_pursuer_eta", -1.0))
	snapshot["boss_state"] = String(noise_debug.get("boss_state", "idle"))
	snapshot["boss_id"] = String(noise_debug.get("boss_id", ""))
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
	snapshot["timeline_progress"] = DataRegistry.get_timeline_progress(elapsed_time)
	snapshot["fixed_noise_enabled"] = fixed_noise_enabled
	snapshot["fixed_noise_value"] = fixed_noise_value
	snapshot["fog_enabled"] = fog_enabled
	snapshot["sonar_visual_enabled"] = sonar_visual_enabled
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
		var msg := "Data reload failed."
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
	ui.show_system_message("Data reloaded (fog/sonar/noise/maps).", false)


func _exit_tree() -> void:
	if run_started and run_state == STATE_PLAYING:
		_evaluate_character_unlocks()
	Engine.time_scale = 1.0
