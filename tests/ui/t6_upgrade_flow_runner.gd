extends Node

const GAME_ROOT_SCENE := preload("res://scenes/game/GameRoot.tscn")
const LOG_PATH := "res://tmp/logs/t6_upgrade_flow.log"
const SHOT_CARDS := "res://tmp/logs/t6_upgrade_cards.png"
const SHOT_FOCUS := "res://tmp/logs/t6_upgrade_focus.png"
const SHOT_AFTER := "res://tmp/logs/t6_upgrade_after_select.png"
const SESSION_TAG := "t6_upgrade_runner"


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	_setup_profile_isolation(SESSION_TAG)
	var lines: Array[String] = []
	const FIXED_SEED := 424242
	var game := GAME_ROOT_SCENE.instantiate()
	add_child(game)
	await _wait_frames(3)

	game.call("_start_run", "diver", "map_trench_lab", [])
	await get_tree().create_timer(0.8).timeout

	var player := game.get_node_or_null("World/Player")
	if player == null:
		_fail(lines, "player missing")
		return
	var player_rng_variant: Variant = player.get("rng")
	if player_rng_variant is RandomNumberGenerator:
		var player_rng: RandomNumberGenerator = player_rng_variant
		player_rng.seed = FIXED_SEED
		lines.append("fixed_player_seed=%d" % FIXED_SEED)
	var ui := game.get_node_or_null("UI")
	if ui == null:
		_fail(lines, "ui missing")
		return

	_trigger_single_level_up(player)
	var levelup_ready := await _wait_for_levelup(game, ui, 2.8)
	if not levelup_ready:
		_fail(lines, "level up panel did not appear")
		return

	var panel := ui.get_node_or_null("Root/UpgradeSelect")
	if panel == null:
		_fail(lines, "UpgradeSelect panel not found")
		return
	var snapshot_before: Dictionary = panel.call("debug_get_snapshot")
	lines.append("snapshot_before=%s" % JSON.stringify(snapshot_before))
	if int(snapshot_before.get("card_count", 0)) < 3:
		_fail(lines, "expected 3 upgrade cards")
		return

	await _wait_draw()
	_capture(SHOT_CARDS)

	panel.call("debug_focus_index", 1)
	await get_tree().process_frame
	await _wait_draw()
	_capture(SHOT_FOCUS)

	panel.call("debug_select_index", 0)
	await get_tree().create_timer(0.4).timeout

	var run_state := String(game.get("run_state"))
	var expected_playing := String(game.get("STATE_PLAYING"))
	if run_state != expected_playing:
		_fail(lines, "run state should return to playing")
		return

	_trigger_single_level_up(player)
	var second_ready := await _wait_for_levelup(game, ui, 2.8)
	if not second_ready:
		_fail(lines, "second level up panel did not appear")
		return

	var snapshot_after: Dictionary = panel.call("debug_get_snapshot")
	lines.append("snapshot_after=%s" % JSON.stringify(snapshot_after))
	await _wait_draw()
	_capture(SHOT_AFTER)

	var before_build := String((snapshot_before.get("build", {}) as Dictionary).get("key_passives", ""))
	var after_build := String((snapshot_after.get("build", {}) as Dictionary).get("key_passives", ""))
	var changed := before_build != after_build
	lines.append("build_changed=%s" % str(changed))
	if not changed:
		_fail(lines, "build panel did not update after selecting upgrade")
		return

	lines.append("t6 upgrade flow: PASS")
	_write_log(lines)
	print("t6 upgrade flow: PASS")
	_cleanup_profile_isolation()
	get_tree().quit(0)


func _wait_for_levelup(game: Node, ui: Node, timeout_seconds: float) -> bool:
	var waited := 0.0
	while waited < timeout_seconds:
		var state := String(game.get("run_state"))
		var expected := String(game.get("STATE_LEVEL_UP"))
		var panel := ui.get_node_or_null("Root/UpgradeSelect")
		if state == expected and panel != null and bool(panel.visible):
			return true
		await get_tree().process_frame
		waited += get_process_delta_time()
	return false


func _trigger_single_level_up(player: Node) -> void:
	var xp_to_next := float(player.get("xp_to_next"))
	player.set("xp", clampf(xp_to_next - 1.0, 0.0, xp_to_next))
	player.call("gain_xp", 1)


func _fail(lines: Array[String], reason: String) -> void:
	lines.append("t6 upgrade flow: FAIL - %s" % reason)
	_write_log(lines)
	push_error(reason)
	_cleanup_profile_isolation()
	get_tree().quit(1)


func _write_log(lines: Array[String]) -> void:
	var abs_path := ProjectSettings.globalize_path(LOG_PATH)
	DirAccess.make_dir_recursive_absolute(abs_path.get_base_dir())
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
