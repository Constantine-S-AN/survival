extends Node

const GAME_ROOT_SCENE := preload("res://scenes/game/GameRoot.tscn")


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	var game := GAME_ROOT_SCENE.instantiate()
	add_child(game)
	await get_tree().process_frame
	await get_tree().process_frame

	var ui: Node = game.get_node_or_null("UI")
	if ui == null:
		push_error("UI not found")
		get_tree().quit(1)
		return

	var menu := ui.get_node_or_null("Root/MainMenuPanel")
	if menu == null:
		push_error("Main menu panel missing")
		get_tree().quit(1)
		return
	menu.emit_signal("play_pressed")
	await get_tree().create_timer(0.40).timeout

	var run_setup := ui.get_node_or_null("Root/RunSetup")
	if run_setup == null:
		push_error("RunSetup panel missing")
		get_tree().quit(1)
		return

	run_setup.call("debug_select_character", "diver")
	run_setup.call("debug_select_map", "map_trench_lab")
	run_setup.call("debug_toggle_contract", "contract_small_vision")
	run_setup.call("debug_submit")
	await get_tree().create_timer(0.50).timeout

	var current_state := String(game.get("run_state"))
	var expected_state := String(game.get("STATE_PLAYING"))
	if current_state != expected_state:
		push_error("RunSetup flow failed: got %s expected %s" % [current_state, expected_state])
		get_tree().quit(1)
		return

	print("t4 run setup flow: PASS")
	get_tree().quit(0)
