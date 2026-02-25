extends Node

const GAME_ROOT_SCENE := preload("res://scenes/game/GameRoot.tscn")


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	var game_root := GAME_ROOT_SCENE.instantiate()
	add_child(game_root)
	await get_tree().process_frame
	await get_tree().process_frame

	var transition: Node = get_node_or_null("/root/SceneTransition")
	if transition == null:
		push_error("SceneTransition autoload missing")
		get_tree().quit(1)
		return

	_capture("tmp/logs/t2_transition_before.png")
	game_root.call("_on_main_menu_start_requested")
	await get_tree().create_timer(0.07).timeout
	_capture("tmp/logs/t2_transition_mid.png")
	await get_tree().create_timer(0.25).timeout
	_capture("tmp/logs/t2_transition_after.png")
	get_tree().quit(0)


func _capture(path: String) -> void:
	var image: Image = get_viewport().get_texture().get_image()
	if image == null:
		push_error("Failed to capture viewport image: %s" % path)
		return
	image.save_png(path)
