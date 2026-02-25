extends Node

const GAME_ROOT_SCENE := preload("res://scenes/game/GameRoot.tscn")


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	var game := GAME_ROOT_SCENE.instantiate()
	add_child(game)
	await get_tree().process_frame
	await get_tree().process_frame

	game.call("_on_main_menu_start_requested")
	game.call("_on_main_menu_start_requested")
	game.call("_on_main_menu_start_requested")
	game.call("_on_main_menu_start_requested")

	await get_tree().create_timer(0.45).timeout
	var state: String = String(game.get("run_state"))
	if state != String(game.get("STATE_CHARACTER_SELECT")):
		push_error("last-wins failed: expected STATE_CHARACTER_SELECT, got %s" % state)
		get_tree().quit(1)
		return
	print("last-wins transition queue: PASS")
	get_tree().quit(0)
