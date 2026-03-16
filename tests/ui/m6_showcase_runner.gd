extends Node

const GAME_ROOT_SCENE := preload("res://scenes/game/GameRoot.tscn")
const LOG_PATH := "res://tmp/logs/m6_showcase_flow.log"
const SESSION_TAG := "m6_showcase_runner"

const SHOT_MENU := "res://tmp/logs/m6_menu_static.png"
const SHOT_RUNSETUP := "res://tmp/logs/m6_runsetup_contracts.png"
const SHOT_UPGRADE := "res://tmp/logs/m6_upgrade_cards.png"
const SHOT_HUD := "res://tmp/logs/m6_hud_overview.png"
const SHOT_SUMMARY := "res://tmp/logs/m6_summary_overview.png"
const SHOT_FOCUS := "res://tmp/logs/m6_focus_hover.png"
const DEFAULT_SHOWCASE_SECONDS := 45.0
const SUMMARY_TRIGGER_GAP_SECONDS := 8.0
const FORCE_SUMMARY_ENV := "M6_FORCE_SUMMARY"
const FORCE_SUMMARY_CONFIRM_ENV := "M6_FORCE_SUMMARY_KILL"

var _game: Node = null
var _start_usec: int = 0
var _showcase_seconds: float = DEFAULT_SHOWCASE_SECONDS
var _summary_trigger_seconds: float = DEFAULT_SHOWCASE_SECONDS - SUMMARY_TRIGGER_GAP_SECONDS
var _force_summary_capture: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	await get_tree().process_frame
	await _run()


func _run() -> void:
	_setup_profile_isolation(SESSION_TAG)
	_start_usec = Time.get_ticks_usec()
	_showcase_seconds = _resolve_showcase_seconds()
	_summary_trigger_seconds = _resolve_summary_trigger_seconds(_showcase_seconds)
	_force_summary_capture = _resolve_force_summary_capture()
	var lines: Array[String] = []
	_game = GAME_ROOT_SCENE.instantiate()
	add_child(_game)

	await _wait_frames(6)
	_capture(SHOT_MENU)
	lines.append("captured_menu=true")

	var menu := _game.get_node_or_null("UI/Root/MainMenuPanel")
	if menu != null and menu.has_method("focus_button_by_id"):
		menu.call("focus_button_by_id", "quit")
		await _wait_frames(3)
		_capture(SHOT_FOCUS)
		lines.append("captured_focus=true")

	_game.call("_on_main_menu_start_requested")
	if not await _wait_for_state(_game, String(_game.get("STATE_CHARACTER_SELECT")), 2.4):
		await _fail(lines, "failed to enter run setup")
		return

	await _wait_frames(8)
	var run_setup := _game.get_node_or_null("UI/Root/RunSetup")
	if run_setup == null:
		await _fail(lines, "run setup panel missing")
		return
	run_setup.call("debug_select_character", "diver")
	run_setup.call("debug_select_map", "map_trench_lab")
	run_setup.call("debug_toggle_contract", "contract_rich_pickups")
	await _wait_frames(4)
	_capture(SHOT_RUNSETUP)
	lines.append("captured_run_setup=true")

	var preview := DataRegistry.get_contract_reward_preview(["contract_rich_pickups"])
	var run_config := {
		"character_id": "diver",
		"map_id": "map_trench_lab",
		"contract_ids": ["contract_rich_pickups"],
		"multipliers": {
			"xp": float(preview.get("xp_mult", 1.0)),
			"rarity": float(preview.get("rarity_mult", 1.0)),
			"drop": float(preview.get("drop_mult", 1.0)),
			"meta_currency": float(preview.get("meta_currency_mult", 1.0))
		}
	}
	_game.call("_on_run_setup_start_requested", run_config)
	if not await _wait_for_state(_game, String(_game.get("STATE_PLAYING")), 2.8):
		await _fail(lines, "failed to enter playing state")
		return

	await _wait_frames(14)
	_capture(SHOT_HUD)
	lines.append("captured_hud=true")

	var player := _game.get_node_or_null("World/Player")
	if player == null:
		await _fail(lines, "player missing")
		return
	_trigger_single_level_up(player)
	if not await _wait_for_state(_game, String(_game.get("STATE_LEVEL_UP")), 2.6):
		await _fail(lines, "level up panel missing")
		return

	await _wait_frames(6)
	_capture(SHOT_UPGRADE)
	lines.append("captured_upgrade=true")

	var upgrade_panel := _game.get_node_or_null("UI/Root/UpgradeSelect")
	if upgrade_panel != null:
		upgrade_panel.call("debug_focus_index", 1)
		await _wait_frames(4)
		_capture(SHOT_FOCUS)
		upgrade_panel.call("debug_select_index", 0)

	if not await _wait_for_state(_game, String(_game.get("STATE_PLAYING")), 2.6):
		await _fail(lines, "failed to return to playing after upgrade")
		return

	lines.append("force_summary_capture=%s" % str(_force_summary_capture))
	if _force_summary_capture:
		player = _game.get_node_or_null("World/Player")
		if player != null:
			# Keep the showcase alive until the planned trigger without debug HP inflation.
			player.set("invuln_remaining", maxf(float(player.get("invuln_remaining")), _summary_trigger_seconds + 1.0))
		lines.append("summary_trigger_target_sec=%.2f" % _summary_trigger_seconds)
		if not await _wait_until_seconds_guarding_state(_game, _summary_trigger_seconds):
			await _fail(lines, "summary entered before trigger second")
			return
		if player != null and player.has_method("take_damage"):
			player.set("invuln_remaining", 0.0)
			var lethal_damage := maxf(1.0, float(player.get("hp")) + 1.0)
			player.call("take_damage", lethal_damage)
		if not await _wait_for_state(_game, String(_game.get("STATE_GAME_OVER")), 3.0):
			await _fail(lines, "failed to enter summary state")
			return
		lines.append("summary_entered_at_sec=%.2f" % _elapsed_seconds())
		await _wait_frames(8)
		_capture(SHOT_SUMMARY)
		lines.append("captured_summary=true")
	else:
		lines.append("captured_summary=skipped")

	await _wait_until_seconds(_showcase_seconds)
	lines.append("m6 showcase: PASS")
	_write_log(lines)
	print("m6 showcase: PASS")
	await _shutdown(0)


func _wait_for_state(game: Node, expected: String, timeout_seconds: float) -> bool:
	var waited := 0.0
	while waited < timeout_seconds:
		if String(game.get("run_state")) == expected:
			return true
		await _tick()
		waited += 0.016
	return false


func _trigger_single_level_up(player: Node) -> void:
	var xp_to_next := float(player.get("xp_to_next"))
	player.set("xp", clampf(xp_to_next - 1.0, 0.0, xp_to_next))
	player.call("gain_xp", 1)


func _wait_until_seconds(seconds: float) -> void:
	while _elapsed_seconds() < seconds:
		await _tick()


func _wait_until_seconds_guarding_state(game: Node, seconds: float) -> bool:
	var game_over_state := String(game.get("STATE_GAME_OVER"))
	while _elapsed_seconds() < seconds:
		if String(game.get("run_state")) == game_over_state:
			return false
		await _tick()
	return true


func _elapsed_seconds() -> float:
	return float(Time.get_ticks_usec() - _start_usec) / 1000000.0


func _resolve_showcase_seconds() -> float:
	var raw := OS.get_environment("M6_SHOWCASE_MIN_SECONDS").strip_edges()
	if raw.is_empty():
		return DEFAULT_SHOWCASE_SECONDS
	if not raw.is_valid_float():
		return DEFAULT_SHOWCASE_SECONDS
	return maxf(5.0, float(raw))


func _resolve_summary_trigger_seconds(showcase_seconds: float) -> float:
	var fallback := maxf(15.0, showcase_seconds - SUMMARY_TRIGGER_GAP_SECONDS)
	var raw := OS.get_environment("M6_SHOWCASE_SUMMARY_AT_SECONDS").strip_edges()
	if raw.is_empty():
		return clampf(fallback, 5.0, maxf(5.0, showcase_seconds - 1.0))
	if not raw.is_valid_float():
		return clampf(fallback, 5.0, maxf(5.0, showcase_seconds - 1.0))
	return clampf(float(raw), 5.0, maxf(5.0, showcase_seconds - 1.0))


func _resolve_force_summary_capture() -> bool:
	var raw := OS.get_environment(FORCE_SUMMARY_ENV).strip_edges().to_lower()
	var enabled := raw == "1" or raw == "true" or raw == "yes" or raw == "on"
	if not enabled:
		return false
	var confirm_raw := OS.get_environment(FORCE_SUMMARY_CONFIRM_ENV).strip_edges().to_lower()
	return confirm_raw == "1" or confirm_raw == "true" or confirm_raw == "yes" or confirm_raw == "on"


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


func _wait_frames(count: int) -> void:
	for _i in range(maxi(1, count)):
		await _tick()


func _tick() -> void:
	if get_tree().paused:
		get_tree().paused = false
	await get_tree().create_timer(0.016, true, false, true).timeout


func _fail(lines: Array[String], reason: String) -> void:
	lines.append("m6 showcase: FAIL - %s" % reason)
	_write_log(lines)
	push_error(reason)
	await _shutdown(1)


func _can_capture_viewport() -> bool:
	return DisplayServer.get_name().strip_edges().to_lower() != "headless"


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


func _write_log(lines: Array[String]) -> void:
	var abs_path := ProjectSettings.globalize_path(LOG_PATH)
	DirAccess.make_dir_recursive_absolute(abs_path.get_base_dir())
	var file := FileAccess.open(abs_path, FileAccess.WRITE)
	if file == null:
		return
	for line in lines:
		file.store_line(line)


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
