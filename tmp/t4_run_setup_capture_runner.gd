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
		push_error("Main menu missing")
		get_tree().quit(1)
		return
	menu.emit_signal("play_pressed")
	await get_tree().create_timer(0.40).timeout

	var run_setup := ui.get_node_or_null("Root/RunSetup")
	if run_setup == null:
		push_error("RunSetup missing")
		get_tree().quit(1)
		return

	run_setup.call("set_step_by_state", "character_select")
	await get_tree().process_frame
	_capture("tmp/logs/t4_step1_summary.png")

	run_setup.call("debug_select_character", "diver")
	run_setup.call("debug_select_map", "map_trench_lab")
	run_setup.call("set_step_by_state", "map_select")
	await get_tree().process_frame
	_capture("tmp/logs/t4_start_enabled.png")

	run_setup.call("debug_toggle_contract", "contract_small_vision")
	run_setup.call("set_step_by_state", "contract_select")
	await get_tree().process_frame
	_capture("tmp/logs/t4_step3_contracts.png")

	get_tree().quit(0)


func _capture(path: String) -> void:
	var image: Image = get_viewport().get_texture().get_image()
	if image == null:
		push_error("Failed capture: %s" % path)
		return
	image.save_png(path)
