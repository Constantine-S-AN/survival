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

	_capture("tmp/logs/t3_menu_static.png")

	var menu: Node = ui.get_node_or_null("Root/MainMenuPanel")
	if menu != null and menu.has_method("focus_button_by_id"):
		menu.call("focus_button_by_id", "settings")
	await get_tree().process_frame
	_capture("tmp/logs/t3_menu_focus.png")

	get_tree().quit(0)


func _capture(path: String) -> void:
	var image: Image = get_viewport().get_texture().get_image()
	if image == null:
		push_error("Failed to capture viewport image: %s" % path)
		return
	image.save_png(path)
