extends Node


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	var current_scene_before := get_tree().current_scene
	SceneTransition.transition_to("res://scenes/ui/__missing__.tscn", 0.01)
	await get_tree().process_frame
	await get_tree().process_frame
	var unchanged := get_tree().current_scene == current_scene_before
	if not unchanged:
		push_error("transition_to invalid path changed current scene unexpectedly")
		get_tree().quit(1)
		return
	print("transition_to invalid path fallback: PASS")
	get_tree().quit(0)
