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


func _ready() -> void:
	Engine.time_scale = 1.0
	InputConfig.ensure_default_actions()
	if not DataRegistry.load_all():
		push_error("DataRegistry failed to load JSON. Check console for details.")

	run_seed = int(Time.get_unix_time_from_system())
	rng.seed = run_seed

	world.setup_run(rng)
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
	if run_state != STATE_PLAYING:
		return
	elapsed_time += delta
	world.enemy_manager.update_difficulty(elapsed_time, world.player.noise)
	_refresh_hud()


func _on_enemy_killed(_enemy_id: String, xp_reward: int) -> void:
	kills += 1
	world.player.gain_xp(xp_reward)


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
	hud["state"] = run_state
	ui.update_hud(hud)


func _exit_tree() -> void:
	Engine.time_scale = 1.0
