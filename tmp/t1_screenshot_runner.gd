extends Node

const GAME_ROOT_SCENE := preload("res://scenes/game/GameRoot.tscn")


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	var game_root := GAME_ROOT_SCENE.instantiate()
	add_child(game_root)
	await get_tree().process_frame
	await get_tree().process_frame

	var ui: Node = game_root.get_node("UI")
	if ui == null:
		push_error("UI node not found")
		get_tree().quit(1)
		return

	ui.call("on_game_state_changed", "menu")
	await get_tree().process_frame
	_capture("tmp/logs/t1_menu.png")

	ui.call("on_game_state_changed", "character_select")
	await get_tree().process_frame
	_capture("tmp/logs/t1_character_select.png")

	ui.call("on_game_state_changed", "contract_select")
	await get_tree().process_frame
	_capture("tmp/logs/t1_contract_select.png")

	get_tree().quit(0)


func _capture(path: String) -> void:
	var image: Image = get_viewport().get_texture().get_image()
	if image == null:
		push_error("Failed to capture viewport image: %s" % path)
		return
	image.save_png(path)
