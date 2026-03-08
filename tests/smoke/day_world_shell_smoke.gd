extends Node


func _ready() -> void:
	var meta_scene: PackedScene = load("res://scenes/meta/MetaLoopRoot.tscn")
	if meta_scene == null:
		push_error("Failed to load MetaLoopRoot for DayWorld shell smoke")
		get_tree().quit(1)
		return
	var meta_root: Node = meta_scene.instantiate()
	get_tree().root.add_child.call_deferred(meta_root)
	await get_tree().process_frame
	await get_tree().process_frame
	meta_root.call("debug_press_play")
	await get_tree().process_frame
	var snapshot: Dictionary = meta_root.call("debug_get_snapshot")
	if String(snapshot.get("current_screen", "")) != "day_hub":
		push_error("Meta loop did not enter the day hub state")
		_cleanup(meta_root)
		return
	if String(snapshot.get("daytime_shell_mode", "")) != "world":
		push_error("Walkable day shell should be the default daytime presentation")
		_cleanup(meta_root)
		return
	if not bool(meta_root.call("debug_day_world_interact", "farm")):
		push_error("Day world farm entrance should route into the farm view")
		_cleanup(meta_root)
		return
	await get_tree().process_frame
	snapshot = meta_root.call("debug_get_snapshot")
	if String(snapshot.get("current_screen", "")) != "farm":
		push_error("Farm entrance did not open the farm screen")
		_cleanup(meta_root)
		return
	meta_root.call("debug_return_to_hub")
	await get_tree().process_frame
	if not bool(meta_root.call("debug_day_world_interact", "restaurant")):
		push_error("Day world restaurant entrance should route into the restaurant view")
		_cleanup(meta_root)
		return
	await get_tree().process_frame
	snapshot = meta_root.call("debug_get_snapshot")
	if String(snapshot.get("current_screen", "")) != "restaurant":
		push_error("Restaurant entrance did not open the restaurant screen")
		_cleanup(meta_root)
		return
	meta_root.call("debug_return_to_hub")
	await get_tree().process_frame
	if not bool(meta_root.call("debug_day_world_interact", "shop")):
		push_error("Day world shop entrance should route into the shop view")
		_cleanup(meta_root)
		return
	await get_tree().process_frame
	snapshot = meta_root.call("debug_get_snapshot")
	if String(snapshot.get("current_screen", "")) != "shop":
		push_error("Shop entrance did not open the shop screen")
		_cleanup(meta_root)
		return
	meta_root.call("debug_return_to_hub")
	await get_tree().process_frame
	meta_root.call("debug_use_legacy_day_hub")
	await get_tree().process_frame
	snapshot = meta_root.call("debug_get_snapshot")
	if String(snapshot.get("daytime_shell_mode", "")) != "legacy":
		push_error("Legacy day hub fallback did not activate")
		_cleanup(meta_root)
		return
	meta_root.call("debug_use_day_world")
	await get_tree().process_frame
	snapshot = meta_root.call("debug_get_snapshot")
	if String(snapshot.get("daytime_shell_mode", "")) != "world":
		push_error("Walkable day shell did not restore after fallback")
		_cleanup(meta_root)
		return
	if bool(meta_root.call("debug_day_world_interact", "night")):
		push_error("Night dock should stay locked before evening")
		_cleanup(meta_root)
		return
	if not bool(meta_root.call("debug_day_world_interact", "wait")):
		push_error("Watch bench should route through the wait-until-evening flow")
		_cleanup(meta_root)
		return
	await get_tree().process_frame
	if not bool(meta_root.call("debug_day_world_interact", "night")):
		push_error("Night dock should launch combat after evening is reached")
		_cleanup(meta_root)
		return
	await get_tree().process_frame
	snapshot = meta_root.call("debug_get_snapshot")
	if String(snapshot.get("current_screen", "")) != "night":
		push_error("Night dock did not launch the embedded night combat screen")
		_cleanup(meta_root)
		return
	print("Day World shell smoke PASS")
	_cleanup(meta_root, false)


func _cleanup(meta_root: Node, failed: bool = true) -> void:
	if meta_root != null:
		meta_root.free()
	if failed:
		get_tree().quit(1)
		return
	get_tree().quit()
