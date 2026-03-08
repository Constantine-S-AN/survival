extends Node


func _ready() -> void:
	var dialogue_manager: Node = get_node_or_null("/root/DialogueManager")
	if dialogue_manager == null:
		push_error("DialogueManager autoload missing")
		get_tree().quit(1)
		return
	if not dialogue_manager.has_method("show_dialogue_balloon"):
		push_error("DialogueManager runtime API missing show_dialogue_balloon")
		get_tree().quit(1)
		return
	print("DialogueManager smoke PASS")
	get_tree().quit()
