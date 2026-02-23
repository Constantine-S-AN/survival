extends Node

const GAME_ROOT_SCENE := preload("res://scenes/game/GameRoot.tscn")
const LOG_PATH := "res://tmp/logs/t7_summary_flow.log"
const SHOT_OVERVIEW := "res://tmp/logs/t7_summary_overview.png"
const SHOT_RETRY := "res://tmp/logs/t7_summary_retry_focus.png"
const SHOT_PROGRESS := "res://tmp/logs/t7_summary_progress.png"


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	var lines: Array[String] = []
	var game := GAME_ROOT_SCENE.instantiate()
	add_child(game)
	await _wait_frames(3)

	if String(game.get("run_state")) != String(game.get("STATE_MENU")):
		_fail(lines, "expected initial menu state")
		return
	lines.append("initial_state=menu")

	game.call("_on_run_setup_start_requested", {
		"character_id": "diver",
		"map_id": "map_trench_lab",
		"contract_ids": ["contract_loud_world"]
	})

	var entered_run := await _wait_for_state(game, String(game.get("STATE_PLAYING")), 4.0)
	if not entered_run:
		_fail(lines, "failed to enter run")
		return
	lines.append("entered_state=playing")

	var player := game.get_node_or_null("World/Player")
	if player == null:
		_fail(lines, "missing player")
		return
	player.call("apply_upgrade", "u_sonar_scope_matrix")
	game.call("_refresh_hud")
	await get_tree().create_timer(0.12).timeout

	player.call("take_damage", 9999.0)
	var entered_summary := await _wait_for_state(game, String(game.get("STATE_GAME_OVER")), 2.4)
	if not entered_summary:
		_fail(lines, "failed to enter summary state")
		return

	var summary := game.get_node_or_null("UI/Root/RunSummary")
	if summary == null:
		_fail(lines, "RunSummary panel missing")
		return
	if not bool(summary.visible):
		_fail(lines, "RunSummary panel not visible")
		return

	var snapshot: Dictionary = summary.call("debug_get_snapshot")
	lines.append("summary_snapshot=%s" % JSON.stringify(snapshot))
	if int(snapshot.get("rendered_key_fields", 0)) < 5:
		_fail(lines, "summary rendered fields below threshold")
		return

	await _wait_draw()
	_capture(SHOT_OVERVIEW)

	summary.call("debug_focus_retry")
	await get_tree().process_frame
	await _wait_draw()
	_capture(SHOT_RETRY)

	summary.call("debug_pulse_progress")
	await get_tree().create_timer(0.15).timeout
	await _wait_draw()
	_capture(SHOT_PROGRESS)

	summary.call("debug_press_retry")
	var retry_ok := await _wait_for_state(game, String(game.get("STATE_PLAYING")), 4.0)
	if not retry_ok:
		_fail(lines, "retry did not start a new run")
		return
	lines.append("retry_state=playing")
	lines.append("t7 summary flow: PASS")
	_write_log(lines)
	print("t7 summary flow: PASS")
	get_tree().quit(0)


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
