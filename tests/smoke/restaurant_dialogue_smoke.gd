extends Node


func _ready() -> void:
	var layer_script: Script = load("res://scripts/meta/day_hub_intro_dialogue_layer.gd")
	if layer_script == null:
		push_error("Failed to load dialogue layer script")
		get_tree().quit(1)
		return
	var layer: CanvasLayer = layer_script.new()
	var field_stew_summary := {
		"sold_dishes": {
			"field_stew": 2
		},
		"reputation_delta": 1
	}
	var other_summary := {
		"sold_dishes": {
			"herb_tea": 1
		},
		"reputation_delta": 1
	}
	if layer.call("_select_restaurant_dialogue_id", field_stew_summary, 1, 1, []) != "restaurant_special_customer_field_stew":
		push_error("Field stew service did not select the restaurant special-customer dialogue")
		get_tree().quit(1)
		return
	if layer.call("_select_restaurant_dialogue_id", field_stew_summary, 2, 1, []) != "":
		push_error("Restaurant dialogue triggered for an old service day")
		layer.free()
		get_tree().quit(1)
		return
	if layer.call("_select_restaurant_dialogue_id", other_summary, 1, 1, []) != "":
		push_error("Restaurant dialogue triggered without the target dish")
		layer.free()
		get_tree().quit(1)
		return
	if layer.call("_select_restaurant_dialogue_id", field_stew_summary, 1, 1, ["restaurant_special_customer_field_stew"]) != "":
		push_error("Seen restaurant special-customer dialogue was not suppressed")
		layer.free()
		get_tree().quit(1)
		return
	layer.free()
	print("Restaurant dialogue smoke PASS")
	get_tree().quit()
