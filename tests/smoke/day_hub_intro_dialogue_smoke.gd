extends Node


func _ready() -> void:
	var layer_script: Script = load("res://scripts/meta/day_hub_intro_dialogue_layer.gd")
	if layer_script == null:
		push_error("Failed to load dialogue layer script")
		get_tree().quit(1)
		return
	if ProfileStore == null:
		push_error("ProfileStore autoload missing")
		get_tree().quit(1)
		return
	var session_id := "day_hub_intro_dialogue_%d" % int(Time.get_ticks_usec() % 1000000)
	ProfileStore.begin_test_session(session_id, true)
	ProfileStore.load_profile("diver", "map_trench_lab")
	var layer: CanvasLayer = layer_script.new()
	var meta_progress := ProfileStore.get_meta_progress_state()
	if not bool(layer.call("_should_show_day_hub_intro_for_state", meta_progress, [])):
		push_error("Day Hub intro dialogue should trigger on a fresh day-1 morning profile")
		_cleanup(layer)
		return
	var day_one_candidate: Dictionary = layer.call("_select_day_hub_morning_dialogue", meta_progress, [])
	if String(day_one_candidate.get("id", "")) != "day_hub_intro":
		push_error("Day Hub morning selector should choose the day-1 intro on a fresh profile")
		_cleanup(layer)
		return
	layer.call("_mark_dialogue_seen", "day_hub_intro")
	var dialogue_state := ProfileStore.get_dialogue_state()
	var seen_ids: Array = dialogue_state.get("seen_dialogue_ids", [])
	if seen_ids.find("day_hub_intro") == -1:
		push_error("Day Hub intro dialogue did not persist its seen guard")
		_cleanup(layer)
		return
	if bool(layer.call("_should_show_day_hub_intro_for_state", meta_progress, seen_ids)):
		push_error("Day Hub intro dialogue guard did not suppress repeat trigger on the same profile")
		_cleanup(layer)
		return
	var day_two_progress := meta_progress.duplicate(true)
	var day_state: Dictionary = (day_two_progress.get("day_state", {}) as Dictionary).duplicate(true)
	day_state["current_day"] = 2
	day_two_progress["day_state"] = day_state
	if bool(layer.call("_should_show_day_hub_intro_for_state", day_two_progress, [])):
		push_error("Day Hub intro dialogue unexpectedly triggered after day 1")
		_cleanup(layer)
		return
	var day_two_candidate: Dictionary = layer.call("_select_day_hub_morning_dialogue", day_two_progress, [])
	if String(day_two_candidate.get("id", "")) != "day_hub_day2_morning":
		push_error("Day Hub morning selector should choose the day-2 authored beat on day 2")
		_cleanup(layer)
		return
	layer.call("_mark_dialogue_seen", "day_hub_day2_morning")
	var seen_day_two_ids: Array = ProfileStore.get_dialogue_state().get("seen_dialogue_ids", [])
	var seen_day_two_candidate: Dictionary = layer.call("_select_day_hub_morning_dialogue", day_two_progress, seen_day_two_ids)
	if not seen_day_two_candidate.is_empty():
		push_error("Day Hub day-2 morning dialogue should not replay once seen")
		_cleanup(layer)
		return
	var day_three_progress := meta_progress.duplicate(true)
	var day_three_state: Dictionary = (day_three_progress.get("day_state", {}) as Dictionary).duplicate(true)
	day_three_state["current_day"] = 3
	day_three_progress["day_state"] = day_three_state
	var day_three_candidate: Dictionary = layer.call("_select_day_hub_morning_dialogue", day_three_progress, [])
	if String(day_three_candidate.get("id", "")) != "day_hub_day3_morning":
		push_error("Day Hub morning selector should choose the day-3 authored beat on day 3")
		_cleanup(layer)
		return
	var pending_summary_progress := meta_progress.duplicate(true)
	pending_summary_progress["pending_return_summary"] = {"exit_reason": "completed"}
	if bool(layer.call("_should_show_day_hub_intro_for_state", pending_summary_progress, [])):
		push_error("Day Hub intro dialogue unexpectedly triggered while a return summary was pending")
		_cleanup(layer)
		return
	layer.free()
	ProfileStore.load_profile("diver", "map_trench_lab")
	var reloaded_seen_ids: Array = ProfileStore.get_dialogue_state().get("seen_dialogue_ids", [])
	if reloaded_seen_ids.find("day_hub_intro") == -1:
		push_error("Day Hub intro dialogue seen guard did not survive reload")
		_cleanup(null)
		return
	print("Day Hub intro dialogue smoke PASS")
	_cleanup(null, false)
	get_tree().quit()


func _cleanup(layer: CanvasLayer, failed: bool = true) -> void:
	if layer != null:
		layer.free()
	if ProfileStore != null:
		ProfileStore.end_test_session(true)
	if failed:
		get_tree().quit(1)
