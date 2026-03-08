extends Node


func _ready() -> void:
	var layer_script: Script = load("res://scripts/meta/day_hub_intro_dialogue_layer.gd")
	if layer_script == null:
		push_error("Failed to load dialogue layer script")
		get_tree().quit(1)
		return
	var layer: CanvasLayer = layer_script.new()
	var first_summary := {
		"exit_reason": "abandoned",
		"materials_reward": {
			"scrap": 2,
			"abyssfin": 1
		},
		"unlock_names": []
	}
	var rare_summary := {
		"exit_reason": "completed",
		"materials_reward": {
			"glow_kelp": 1
		},
		"unlock_names": []
	}
	var poor_summary := {
		"exit_reason": "abandoned",
		"materials_reward": {
			"scrap": 1
		},
		"unlock_names": []
	}
	if layer.call("_select_return_summary_dialogue_id", first_summary, []) != "return_summary_first_return":
		push_error("First return summary did not select the first-return dialogue")
		get_tree().quit(1)
		return
	if layer.call("_select_return_summary_dialogue_id", rare_summary, ["return_summary_first_return"]) != "return_summary_rare_loot":
		push_error("Rare loot summary did not select the rare-loot dialogue")
		get_tree().quit(1)
		return
	if layer.call("_select_return_summary_dialogue_id", poor_summary, ["return_summary_first_return", "return_summary_rare_loot"]) != "return_summary_poor_run":
		push_error("Poor run summary did not select the poor-run dialogue")
		get_tree().quit(1)
		return
	if layer.call("_select_return_summary_dialogue_id", poor_summary, ["return_summary_first_return", "return_summary_rare_loot", "return_summary_poor_run"]) != "":
		push_error("Seen return-summary dialogues were not suppressed")
		layer.free()
		get_tree().quit(1)
		return
	layer.free()
	print("Return summary dialogue smoke PASS")
	get_tree().quit()
