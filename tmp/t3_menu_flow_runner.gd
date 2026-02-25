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
	ui.call("on_game_state_changed", "menu")
	await get_tree().process_frame

	var menu: Node = ui.get_node_or_null("Root/MainMenuPanel")
	if menu == null:
		push_error("Main menu scene not found")
		get_tree().quit(1)
		return

	menu.emit_signal("play_pressed")
	await get_tree().create_timer(0.35).timeout

	var run_state := String(game.get("run_state"))
	var expected := String(game.get("STATE_CHARACTER_SELECT"))
	if run_state != expected:
		push_error("Menu->Play flow failed: got %s expected %s" % [run_state, expected])
		get_tree().quit(1)
		return

	print("menu -> play -> character_select flow: PASS")
	get_tree().quit(0)
