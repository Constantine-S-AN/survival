extends Node

const GAME_ROOT_SCENE := preload("res://scenes/game/GameRoot.tscn")
const LOG_PATH := "res://tmp/logs/t5_hud_runner.log"
const SHOT_OVERVIEW := "res://tmp/logs/t5_hud_overview.png"
const SHOT_TIER := "res://tmp/logs/t5_hud_tier_pulse.png"
const SHOT_LOW_HP := "res://tmp/logs/t5_hud_low_hp.png"
const SESSION_TAG := "t5_hud_runner"


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	_setup_profile_isolation(SESSION_TAG)
	var lines: Array[String] = []
	var game := GAME_ROOT_SCENE.instantiate()
	add_child(game)
	await _wait_frames(3)

	game.call("_start_run", "diver", "map_trench_lab", [])
	await get_tree().create_timer(0.8).timeout

	var ui := game.get_node_or_null("UI")
	if ui == null:
		_fail(lines, "UI node not found")
		return
	var run_hud := ui.get_node_or_null("Root/RunHUD")
	if run_hud == null:
		_fail(lines, "RunHUD node not found")
		return

	game.call("_refresh_hud")
	await _wait_draw()
	_capture(SHOT_OVERVIEW)
	var snap_before: Dictionary = run_hud.call("get_debug_snapshot")
	lines.append("snapshot_before=%s" % JSON.stringify(snap_before))

	var player := game.get_node_or_null("World/Player")
	if player == null:
		_fail(lines, "World/Player not found")
		return

	player.call("set_noise_value", 8.0)
	game.call("_refresh_hud")
	await get_tree().create_timer(0.12).timeout
	player.call("set_noise_value", 72.0)
	game.call("_refresh_hud")
	await get_tree().create_timer(0.18).timeout
	await _wait_draw()
	_capture(SHOT_TIER)
	var snap_tier: Dictionary = run_hud.call("get_debug_snapshot")
	lines.append("snapshot_tier=%s" % JSON.stringify(snap_tier))

	var max_hp := float(player.get("max_hp"))
	player.set("hp", maxf(1.0, max_hp * 0.18))
	game.call("_refresh_hud")
	await get_tree().create_timer(0.18).timeout
	await _wait_draw()
	_capture(SHOT_LOW_HP)
	var snap_low: Dictionary = run_hud.call("get_debug_snapshot")
	lines.append("snapshot_low=%s" % JSON.stringify(snap_low))

	var tier_changed := String(snap_before.get("tier_text", "")) != String(snap_tier.get("tier_text", ""))
	var low_hp_ok := float(snap_low.get("hp_ratio", 1.0)) < 0.30
	lines.append("tier_changed=%s" % str(tier_changed))
	lines.append("low_hp_ok=%s" % str(low_hp_ok))

	if not tier_changed:
		_fail(lines, "Noise tier did not change")
		return
	if not low_hp_ok:
		_fail(lines, "Low HP feedback state not reached")
		return

	lines.append("t5 hud runner: PASS")
	_write_log(lines)
	print("t5 hud runner: PASS")
	_cleanup_profile_isolation()
	get_tree().quit(0)


func _fail(lines: Array[String], reason: String) -> void:
	lines.append("t5 hud runner: FAIL - %s" % reason)
	_write_log(lines)
	push_error(reason)
	_cleanup_profile_isolation()
	get_tree().quit(1)


func _write_log(lines: Array[String]) -> void:
	var abs_path := ProjectSettings.globalize_path(LOG_PATH)
	var dir := abs_path.get_base_dir()
	DirAccess.make_dir_recursive_absolute(dir)
	var file := FileAccess.open(abs_path, FileAccess.WRITE)
	if file == null:
		return
	for line in lines:
		file.store_line(line)


func _capture(path: String) -> void:
	var image := get_viewport().get_texture().get_image()
	if image == null:
		return
	var abs_path := ProjectSettings.globalize_path(path)
	DirAccess.make_dir_recursive_absolute(abs_path.get_base_dir())
	image.save_png(abs_path)


func _wait_draw() -> void:
	await RenderingServer.frame_post_draw


func _wait_frames(count: int) -> void:
	for _i in range(maxi(1, count)):
		await get_tree().process_frame


func _setup_profile_isolation(tag: String) -> void:
	if ProfileStore == null or not ProfileStore.has_method("begin_test_session"):
		return
	var session_id := "%s_%d_%d" % [tag, int(Time.get_unix_time_from_system()), int(Time.get_ticks_usec() % 1000000)]
	ProfileStore.begin_test_session(session_id, true)
	if ProfileStore.has_method("load_profile"):
		ProfileStore.load_profile("diver", "map_trench_lab")


func _cleanup_profile_isolation() -> void:
	if ProfileStore == null or not ProfileStore.has_method("end_test_session"):
		return
	ProfileStore.end_test_session(true)
