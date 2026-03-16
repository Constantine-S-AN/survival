extends Node

const GAME_ROOT_SCENE := preload("res://scenes/game/GameRoot.tscn")
const LOG_PATH := "res://tmp/logs/t7_summary_flow.log"
const SHOT_OVERVIEW := "res://tmp/logs/t7_summary_overview.png"
const SHOT_RETRY := "res://tmp/logs/t7_summary_retry_focus.png"
const SHOT_PROGRESS := "res://tmp/logs/t7_summary_progress.png"
const SESSION_TAG := "t7_summary_runner"

var _game: Node = null


func _ready() -> void:
	await get_tree().process_frame
	await _run()


func _run() -> void:
	_setup_profile_isolation(SESSION_TAG)
	var lines: Array[String] = []
	_game = GAME_ROOT_SCENE.instantiate()
	add_child(_game)
	await _wait_frames(3)

	if String(_game.get("run_state")) != String(_game.get("STATE_MENU")):
		await _fail(lines, "expected initial menu state")
		return
	lines.append("initial_state=menu")

	_game.call("_on_run_setup_start_requested", {
		"character_id": "diver",
		"map_id": "map_trench_lab",
		"contract_ids": ["contract_loud_world"]
	})

	var entered_run := await _wait_for_state(_game, String(_game.get("STATE_PLAYING")), 4.0)
	if not entered_run:
		await _fail(lines, "failed to enter run")
		return
	lines.append("entered_state=playing")
	var summary_before_death := _game.get_node_or_null("UI/Root/RunSummary")
	if summary_before_death != null and bool(summary_before_death.visible):
		await _fail(lines, "RunSummary should stay hidden while playing")
		return

	var player := _game.get_node_or_null("World/Player")
	if player == null:
		await _fail(lines, "missing player")
		return
	player.call("apply_upgrade", "u_sonar_scope_matrix")
	_game.call("_refresh_hud")
	await get_tree().create_timer(0.12).timeout

	var lethal_damage := maxf(1.0, float(player.get("hp")) + 1.0)
	player.call("take_damage", lethal_damage)
	var entered_summary := await _wait_for_state(_game, String(_game.get("STATE_GAME_OVER")), 2.4)
	if not entered_summary:
		await _fail(lines, "failed to enter summary state")
		return

	var summary := _game.get_node_or_null("UI/Root/RunSummary")
	if summary == null:
		await _fail(lines, "RunSummary panel missing")
		return
	if not bool(summary.visible):
		await _fail(lines, "RunSummary panel not visible")
		return

	var snapshot: Dictionary = summary.call("debug_get_snapshot")
	lines.append("summary_snapshot=%s" % JSON.stringify(snapshot))
	if int(snapshot.get("rendered_key_fields", 0)) < 5:
		await _fail(lines, "summary rendered fields below threshold")
		return

	if _can_capture_viewport():
		await _wait_draw()
	_capture(SHOT_OVERVIEW)

	summary.call("debug_focus_retry")
	await get_tree().process_frame
	if _can_capture_viewport():
		await _wait_draw()
	_capture(SHOT_RETRY)

	summary.call("debug_pulse_progress")
	await get_tree().create_timer(0.15).timeout
	if _can_capture_viewport():
		await _wait_draw()
	_capture(SHOT_PROGRESS)

	summary.call("debug_press_retry")
	var retry_ok := await _wait_for_state(_game, String(_game.get("STATE_PLAYING")), 4.0)
	if not retry_ok:
		await _fail(lines, "retry did not start a new run")
		return
	lines.append("retry_state=playing")
	lines.append("t7 summary flow: PASS")
	_write_log(lines)
	print("t7 summary flow: PASS")
	await _shutdown(0)


func _wait_for_state(game: Node, target_state: String, timeout_sec: float) -> bool:
	var elapsed := 0.0
	while elapsed < timeout_sec:
		if String(game.get("run_state")) == target_state:
			return true
		await get_tree().process_frame
		elapsed += get_process_delta_time()
	return false


func _fail(lines: Array[String], reason: String) -> void:
	lines.append("t7 summary flow: FAIL - %s" % reason)
	_write_log(lines)
	push_error(reason)
	await _shutdown(1)


func _write_log(lines: Array[String]) -> void:
	var abs_path := ProjectSettings.globalize_path(LOG_PATH)
	DirAccess.make_dir_recursive_absolute(abs_path.get_base_dir())
	var file := FileAccess.open(abs_path, FileAccess.WRITE)
	if file == null:
		return
	for line in lines:
		file.store_line(line)


func _capture(path: String) -> void:
	if not _can_capture_viewport():
		return
	var viewport := get_viewport()
	if viewport == null:
		return
	var viewport_texture := viewport.get_texture()
	if viewport_texture == null:
		return
	var image := viewport_texture.get_image()
	if image == null:
		return
	var abs_path := ProjectSettings.globalize_path(path)
	DirAccess.make_dir_recursive_absolute(abs_path.get_base_dir())
	image.save_png(abs_path)


func _wait_draw() -> void:
	await RenderingServer.frame_post_draw


func _can_capture_viewport() -> bool:
	return DisplayServer.get_name().strip_edges().to_lower() != "headless"


func _wait_frames(count: int) -> void:
	for _i in range(maxi(1, count)):
		await get_tree().process_frame


func _await_stable_frames(count: int = 3) -> void:
	for _i in range(maxi(1, count)):
		await get_tree().physics_frame
		await get_tree().process_frame


func _shutdown(exit_code: int) -> void:
	if _game != null and is_instance_valid(_game):
		if _game.has_method("stop_session"):
			_game.call("stop_session")
		await _await_stable_frames(2)
		_game.queue_free()
		await _await_stable_frames(3)
	_game = null
	_cleanup_profile_isolation()
	await _await_stable_frames(1)
	get_tree().quit(exit_code)


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
