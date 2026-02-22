extends Node
class_name GameRoot

const STATE_PLAYING := "playing"
const STATE_LEVEL_UP := "level_up"
const STATE_GAME_OVER := "game_over"
const InputConfig := preload("res://scripts/core/input_config.gd")

@onready var world = $World
@onready var ui = $UI

var rng := RandomNumberGenerator.new()
var run_seed := 0
var elapsed_time := 0.0
var kills := 0
var run_state := STATE_PLAYING
var hitstop_active := false
var hitstop_end_usec: int = 0
var fog_enabled: bool = true
var sonar_visual_enabled: bool = true
var fixed_noise_enabled: bool = false
var fixed_noise_value: float = 0.0


func _ready() -> void:
	Engine.time_scale = 1.0
	InputConfig.ensure_default_actions()
	if not DataRegistry.load_all():
		push_error("DataRegistry failed to load JSON. Check console for details.")

	run_seed = int(Time.get_unix_time_from_system())
	rng.seed = run_seed

	world.setup_run(rng)
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
	FeedbackBus.hit_landed.connect(_on_hit_landed)

	ui.upgrade_selected.connect(_on_upgrade_selected)
	ui.retry_requested.connect(_on_retry_requested)

	_set_state(STATE_PLAYING)
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
	world.enemy_manager.update_difficulty(elapsed_time, world.player.noise)
	_refresh_hud()
	_push_debug_snapshot()


func _on_enemy_killed(_enemy_id: String, xp_reward: int, world_position: Vector2) -> void:
	kills += 1
	world.call_deferred("spawn_xp_pickup", world_position, xp_reward)


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


func _apply_hitstop(duration: float) -> void:
	if hitstop_active:
		return
	hitstop_active = true
	Engine.time_scale = 0.08
	hitstop_end_usec = Time.get_ticks_usec() + int(duration * 1000000.0)


func _on_player_died() -> void:
	_set_state(STATE_GAME_OVER)
	ui.show_game_over({
		"time": elapsed_time,
		"kills": kills,
		"level": world.player.level,
		"seed": run_seed
	})


func _on_retry_requested() -> void:
	get_tree().paused = false
	Engine.time_scale = 1.0
	get_tree().reload_current_scene()


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
	hud["state"] = run_state
	ui.update_hud(hud)


func _push_debug_snapshot() -> void:
	var snapshot: Dictionary = world.player.get_hud_data()
	var noise_tier_debug: Dictionary = DataRegistry.get_noise_tier(world.player.noise)
	var noise_debug: Dictionary = world.enemy_manager.get_noise_debug_snapshot()
	var entity_counts: Dictionary = world.get_runtime_entity_counts()
	var pool_stats: Dictionary = world.get_pool_stats()
	snapshot["noise_tier_name"] = String(noise_tier_debug.get("name", "静默"))
	snapshot["spawn_rate_multiplier"] = float(noise_debug.get("spawn_rate_multiplier", 1.0))
	snapshot["pursuer_chance"] = float(noise_debug.get("pursuer_chance", 0.0))
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
	ui.update_debug_data(snapshot)


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
	ui.apply_fog_overlay_config(fog_cfg)
	ui.set_fog_overlay_enabled(fog_enabled)
	var sonar_cfg: Dictionary = DataRegistry.get_sonar_config()
	world.apply_sonar_config(sonar_cfg)
	world.set_sonar_visual_enabled(sonar_visual_enabled)
	ui.show_system_message("Data reloaded (fog/sonar/noise).", false)


func _exit_tree() -> void:
	Engine.time_scale = 1.0
