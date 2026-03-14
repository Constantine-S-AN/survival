extends SceneTree

var failed: int = 0
var _completed: bool = false
var _summary: Dictionary = {}


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_bootstrap_script_mode_singletons()
	var run_scene: PackedScene = load("res://scenes/night/NightRun.tscn")
	if run_scene == null:
		_fail("night run scaffold test could not load NightRun.tscn")
		_finish()
		return
	var run_node: Node = run_scene.instantiate()
	root.add_child(run_node)
	if run_node.has_signal("session_completed"):
		run_node.connect("session_completed", Callable(self, "_on_session_completed"))
	run_node.call("start_session", {
		"day": 1,
		"character_id": _registry().call("get_default_character_id"),
		"map_id": _registry().call("get_default_map_id"),
		"contract_ids": [],
		"seed": 9001,
		"session_duration_sec": 60.0
	})

	await _wait_frames(10)
	var snapshot: Dictionary = run_node.call("debug_get_snapshot")
	_assert_equal(String(snapshot.get("room_id", "")), "entry", "night run starts in the entry room")
	_assert_true(bool(snapshot.get("room_cleared", false)), "entry room is immediately open for route selection")
	_assert_equal(int((snapshot.get("available_exits", []) as Array).size()), 2, "entry room exposes two route choices")

	run_node.call("debug_use_exit", "reef_patrol")
	await _wait_frames(6)
	snapshot = run_node.call("debug_get_snapshot")
	_assert_equal(String(snapshot.get("room_id", "")), "reef_patrol", "selecting an exit advances into the chosen combat room")
	_assert_equal(String(snapshot.get("room_kind", "")), "combat", "reef patrol room is treated as a combat room")
	_assert_true(not bool(snapshot.get("room_cleared", true)), "combat room remains uncleared until the encounter is resolved")
	_assert_true(_snapshot_has_locked_exit(snapshot), "combat room keeps its exit locked while enemies are alive")

	run_node.call("debug_force_clear_room")
	await _wait_frames(2)
	snapshot = run_node.call("debug_get_snapshot")
	_assert_true(bool(snapshot.get("room_cleared", false)), "forcing the encounter clear marks the room as cleared")
	_assert_true(not _snapshot_has_locked_exit(snapshot), "clearing the room unlocks its exit")

	run_node.call("debug_use_exit", "lab_crossfire")
	await _wait_frames(6)
	snapshot = run_node.call("debug_get_snapshot")
	_assert_equal(String(snapshot.get("room_id", "")), "lab_crossfire", "branch rooms converge into the shared follow-up combat room")
	run_node.call("debug_force_clear_room")
	await _wait_frames(2)
	run_node.call("debug_use_exit", "goal")
	await _wait_frames(8)

	_assert_true(_completed, "reaching the goal room completes the night run")
	_assert_equal(String(_summary.get("exit_reason", "")), "completed", "goal-room completion preserves the normal completed return flow")
	_assert_true(int(_summary.get("dungeon_rooms_cleared", 0)) >= 2, "summary tracks cleared combat rooms across the run")
	var room_path: Array = _summary.get("dungeon_room_path", [])
	_assert_true(room_path.has("entry"), "summary records the entry room in the dungeon path")
	_assert_true(room_path.has("reef_patrol"), "summary records the chosen branch room in the dungeon path")
	_assert_true(room_path.has("lab_crossfire"), "summary records the merged combat room in the dungeon path")
	_assert_true(room_path.has("goal"), "summary records the goal room in the dungeon path")

	if run_node != null and is_instance_valid(run_node):
		run_node.queue_free()
	await process_frame
	_finish()


func _bootstrap_script_mode_singletons() -> void:
	if root.get_node_or_null("DataRegistry") == null:
		var registry_script: Script = load("res://scripts/core/data_registry.gd")
		var registry_instance: Node = registry_script.new()
		registry_instance.name = "DataRegistry"
		root.add_child(registry_instance)
	if root.get_node_or_null("FeedbackBus") == null:
		var feedback_script: Script = load("res://scripts/core/feedback_bus.gd")
		var feedback_instance: Node = feedback_script.new()
		feedback_instance.name = "FeedbackBus"
		root.add_child(feedback_instance)
	if root.get_node_or_null("TelegraphBus") == null:
		var telegraph_script: Script = load("res://scripts/core/telegraph_bus.gd")
		var telegraph_instance: Node = telegraph_script.new()
		telegraph_instance.name = "TelegraphBus"
		root.add_child(telegraph_instance)
	if root.get_node_or_null("ProfileStore") == null:
		var profile_script: Script = load("res://scripts/core/profile_store.gd")
		var profile_instance: Node = profile_script.new()
		profile_instance.name = "ProfileStore"
		root.add_child(profile_instance)
	if not bool(_registry().call("ensure_loaded")):
		_fail("night run scaffold test could not load DataRegistry")
		return
	_profile_store().call(
		"load_profile",
		_registry().call("get_default_character_id"),
		_registry().call("get_default_map_id")
	)


func _snapshot_has_locked_exit(snapshot: Dictionary) -> bool:
	var exits: Array = snapshot.get("available_exits", [])
	for exit_variant in exits:
		if not (exit_variant is Dictionary):
			continue
		if bool((exit_variant as Dictionary).get("locked", false)):
			return true
	return false


func _registry() -> Node:
	return root.get_node_or_null("DataRegistry")


func _profile_store() -> Node:
	return root.get_node_or_null("ProfileStore")


func _wait_frames(count: int) -> void:
	for _index in range(maxi(1, count)):
		await process_frame


func _on_session_completed(summary: Dictionary) -> void:
	_completed = true
	_summary = summary.duplicate(true)


func _assert_true(condition: bool, label: String) -> void:
	if condition:
		print("PASS: %s" % label)
		return
	_fail(label)


func _assert_equal(actual, expected, label: String) -> void:
	if actual == expected:
		print("PASS: %s" % label)
		return
	_fail("%s (expected=%s actual=%s)" % [label, str(expected), str(actual)])


func _fail(message: String) -> void:
	failed += 1
	push_error(message)
	print("FAIL: %s" % message)


func _finish() -> void:
	print("NightRun scaffold test finished. failed=%d" % failed)
	quit(failed)
