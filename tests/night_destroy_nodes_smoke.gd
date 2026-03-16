extends SceneTree

const SEED := 9003
const TARGET_ROOM_ID := "salt_vault"
const TARGET_TEMPLATE_ID := "sunken_exchange_v2_route_b"
const PASS_MARKER := "Night destroy-nodes smoke PASS"

var failed: int = 0
var _finish_requested: bool = false


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_bootstrap_script_mode_singletons()
	var run_node: Node = await _start_run()
	if run_node == null:
		_finish()
		return
	await _wait_for_room(run_node, TARGET_ROOM_ID)
	var snapshot: Dictionary = run_node.call("debug_get_snapshot")
	var objective: Dictionary = snapshot.get("objective", {})
	_assert_equal(String(snapshot.get("floor_template_id", "")), TARGET_TEMPLATE_ID, "destroy-nodes seed resolves the expected route template")
	_assert_equal(String(snapshot.get("room_id", "")), TARGET_ROOM_ID, "destroy-nodes smoke reaches the authored room")
	_assert_equal(String(objective.get("objective_id", "")), "destroy_nodes", "destroy-nodes smoke enters the objective room")
	_assert_equal(int(objective.get("required_count", 0)), 4, "destroy-nodes room requires four objective nodes")
	_assert_equal(_find_objective_nodes(run_node).size(), 4, "destroy-nodes room spawns four runtime objective nodes")

	await _drain_live_enemies(run_node)
	snapshot = run_node.call("debug_get_snapshot")
	objective = snapshot.get("objective", {})
	_assert_equal(int(objective.get("progress_count", 0)), 0, "destroy-nodes progress stays locked before the turrets break")
	_assert_true(not bool(snapshot.get("room_cleared", false)), "destroy-nodes room stays uncleared when only enemies are removed")
	var extraction: Dictionary = snapshot.get("extraction", {})
	_assert_equal(
		String(extraction.get("subtitle", "")),
		String(snapshot.get("status_text", "")),
		"destroy-nodes extraction panel surfaces the active objective status while the room is locked"
	)

	_destroy_objective_nodes(run_node)
	await _wait_frames(8)
	snapshot = run_node.call("debug_get_snapshot")
	objective = snapshot.get("objective", {})
	_assert_true(bool(objective.get("completed", false)), "destroy-nodes objective completes after all turrets are destroyed")
	await _drain_live_enemies(run_node)
	snapshot = run_node.call("debug_get_snapshot")
	_assert_true(bool(snapshot.get("room_cleared", false)), "destroy-nodes room becomes cleared after the objective resolves")
	_assert_true(bool(snapshot.get("reward_panel_visible", false)), "destroy-nodes room opens the reward panel after completion")

	await _dispose_run_node(run_node)
	_finish()


func _start_run() -> Node:
	var run_scene: PackedScene = load("res://scenes/night/NightRun.tscn")
	if run_scene == null:
		_fail("destroy-nodes smoke could not load NightRun.tscn")
		return null
	var run_node: Node = run_scene.instantiate()
	root.add_child(run_node)
	run_node.call("start_session", {
		"day": 1,
		"character_id": _registry().call("get_default_character_id"),
		"map_id": _registry().call("get_default_map_id"),
		"contract_ids": [],
		"seed": SEED,
		"session_duration_sec": 60.0
	})
	await _wait_frames(10)
	run_node.call("debug_use_exit", TARGET_ROOM_ID)
	return run_node


func _wait_for_room(run_node: Node, room_id: String, max_frames: int = 720) -> void:
	for _frame in range(max_frames):
		var snapshot: Dictionary = run_node.call("debug_get_snapshot")
		if String(snapshot.get("room_id", "")) == room_id:
			return
		await process_frame
	_fail("destroy-nodes smoke timed out waiting for room %s" % room_id)


func _clear_live_enemies(run_node: Node) -> void:
	var enemy_manager: Node = _find_enemy_manager(run_node)
	var enemies: Array = []
	if enemy_manager != null:
		var active_variant: Variant = enemy_manager.get("active_enemies")
		if active_variant is Array:
			enemies = active_variant
	if enemies.is_empty():
		enemies = _find_live_enemies(run_node)
	for enemy in enemies:
		if enemy == null or not is_instance_valid(enemy):
			continue
		if enemy.has_method("take_hit"):
			enemy.call("take_hit", 9999.0, Vector2.ZERO)


func _drain_live_enemies(run_node: Node, max_cycles: int = 24) -> void:
	for _cycle in range(maxi(1, max_cycles)):
		_clear_live_enemies(run_node)
		await _wait_frames(2)
		var enemy_manager: Node = _find_enemy_manager(run_node)
		if enemy_manager == null:
			return
		if int(enemy_manager.get("alive_enemy_count")) <= 0:
			return


func _destroy_objective_nodes(run_node: Node) -> void:
	for objective_node in _find_objective_nodes(run_node):
		if objective_node == null or not is_instance_valid(objective_node):
			continue
		if objective_node.has_method("take_hit"):
			objective_node.call("take_hit", 9999.0, Vector2.ZERO)


func _find_live_enemies(run_node: Node) -> Array:
	var enemies: Array = []
	if run_node == null or not is_instance_valid(run_node):
		return enemies
	for node in run_node.find_children("*", "Node", true, false):
		if node == null or not is_instance_valid(node):
			continue
		if not (node is CharacterBody2D):
			continue
		if not node.has_method("take_hit"):
			continue
		var enemy_id := str(node.get("enemy_id")).strip_edges()
		var behavior := str(node.get("behavior")).strip_edges()
		if enemy_id.is_empty() and behavior.is_empty():
			continue
		enemies.append(node)
	return enemies


func _find_objective_nodes(run_node: Node) -> Array:
	var objective_nodes: Array = []
	if run_node == null or not is_instance_valid(run_node):
		return objective_nodes
	for node in run_node.find_children("*", "Node", true, false):
		if node == null or not is_instance_valid(node):
			continue
		if String(node.name).begins_with("ObjectiveNode_"):
			objective_nodes.append(node)
	return objective_nodes


func _find_enemy_manager(run_node: Node) -> Node:
	if run_node == null or not is_instance_valid(run_node):
		return null
	for node in run_node.find_children("*", "Node", true, false):
		if node == null or not is_instance_valid(node):
			continue
		if node.has_method("get_scripted_encounter_snapshot"):
			return node
	return null


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
	if _registry().call("ensure_loaded") != true:
		_fail("destroy-nodes smoke could not load DataRegistry")
		return
	_profile_store().call("load_profile", _registry().call("get_default_character_id"), _registry().call("get_default_map_id"))


func _registry() -> Node:
	return root.get_node_or_null("DataRegistry")


func _profile_store() -> Node:
	return root.get_node_or_null("ProfileStore")


func _wait_frames(count: int) -> void:
	for _index in range(maxi(1, count)):
		await process_frame


func _dispose_run_node(run_node: Node) -> void:
	if run_node == null or not is_instance_valid(run_node):
		return
	if run_node.has_method("stop_session"):
		run_node.call("stop_session")
	run_node.queue_free()
	await process_frame
	await process_frame


func _assert_true(condition: bool, label: String) -> void:
	if condition:
		print("PASS: %s" % label)
		return
	failed += 1
	push_error("FAIL: %s" % label)


func _assert_equal(actual, expected, label: String) -> void:
	if actual == expected:
		print("PASS: %s" % label)
		return
	failed += 1
	push_error("FAIL: %s (expected=%s actual=%s)" % [label, str(expected), str(actual)])


func _fail(label: String) -> void:
	failed += 1
	push_error("FAIL: %s" % label)


func _finish() -> void:
	if _finish_requested:
		return
	_finish_requested = true
	print(PASS_MARKER if failed == 0 else "Night destroy-nodes smoke FAIL")
	quit(failed)
