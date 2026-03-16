extends SceneTree

const ROUTE_A_SEED := 9004
const ROUTE_B_SEED := 9005
const ROUTE_A_TEMPLATE_ID := "harbor_rift_v3_objective_pack_a"
const ROUTE_B_TEMPLATE_ID := "sunken_exchange_v3_objective_pack_b"
const PASS_MARKER := "Night V3 objective pack smoke PASS"

var failed: int = 0
var _completed: bool = false
var _summary: Dictionary = {}
var _finish_requested: bool = false


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_bootstrap_script_mode_singletons()
	await _run_route_a()
	await _run_route_b()
	_finish()


func _run_route_a() -> void:
	var seed := ROUTE_A_SEED
	var stage := "route_a"
	var run_node := await _start_run(seed, stage)
	if run_node == null:
		return
	var snapshot: Dictionary = run_node.call("debug_get_snapshot")
	_assert_stage_equal(seed, stage, String(snapshot.get("floor_template_id", "")), ROUTE_A_TEMPLATE_ID, "seed 9004 resolves the route-a objective pack template")

	await _enter_objective_room(run_node, seed, stage, "convoy_slip", "escort", "escort")
	await _complete_escort_objective(run_node, seed, stage)
	await _claim_combat_reward(run_node, seed, stage, 0)

	await _enter_objective_room(run_node, seed, stage, "payload_span", "payload_hack", "hack")
	await _complete_payload_hack_objective(run_node, seed, stage)
	await _claim_combat_reward(run_node, seed, stage, 1)

	await _enter_objective_room(run_node, seed, stage, "apex_guardian", "survive_timer", "survive")
	await _complete_survive_timer_objective(run_node, seed, stage)
	await _claim_combat_reward(run_node, seed, stage, 0)
	await _wait_for_completion(seed, stage)
	_assert_stage_true(seed, stage, _completed, "route-a objective pack completes the run after the goal-room reward")
	var route_a_peak_room := _summary_peak_room("payload_span")
	_assert_stage_equal(seed, stage, String(route_a_peak_room.get("peak_room_kind", "")), "miniboss", "route-a objective pack summary preserves the fixed payload-span peak room kind")
	_assert_stage_equal(seed, stage, String(route_a_peak_room.get("reward_table_id", "")), "combat_challenge_v2", "route-a objective pack summary preserves the upgraded peak-room reward table")
	_assert_stage_equal(seed, stage, int(_summary.get("dungeon_peak_clear_count", 0)), 1, "route-a objective pack summary records one cleared peak room")

	await _dispose_run_node(run_node)


func _run_route_b() -> void:
	var seed := ROUTE_B_SEED
	var stage := "route_b"
	var run_node := await _start_run(seed, stage)
	if run_node == null:
		return
	var snapshot: Dictionary = run_node.call("debug_get_snapshot")
	_assert_stage_equal(seed, stage, String(snapshot.get("floor_template_id", "")), ROUTE_B_TEMPLATE_ID, "seed 9005 resolves the route-b objective pack template")

	await _enter_objective_room(run_node, seed, stage, "pursuit_lane", "elite_hunt", "elite")
	await _complete_elite_hunt_objective(run_node, seed, stage)
	await _claim_combat_reward(run_node, seed, stage, 0)

	await _enter_objective_room(run_node, seed, stage, "relay_switchyard", "power_reroute", "relay")
	await _complete_power_reroute_objective(run_node, seed, stage)
	await _claim_combat_reward(run_node, seed, stage, 1)

	await _enter_objective_room(run_node, seed, stage, "apex_guardian", "cursed_cache", "curse")
	await _complete_cursed_cache_objective(run_node, seed, stage)
	await _claim_combat_reward(run_node, seed, stage, 0)
	await _wait_for_completion(seed, stage)
	_assert_stage_true(seed, stage, _completed, "route-b objective pack completes the run after the goal-room reward")
	var route_b_peak_room := _summary_peak_room("pursuit_lane")
	_assert_stage_equal(seed, stage, String(route_b_peak_room.get("peak_room_kind", "")), "hunter", "route-b objective pack summary preserves the fixed pursuit-lane peak room kind")
	_assert_stage_equal(seed, stage, String(route_b_peak_room.get("reward_table_id", "")), "combat_challenge_v2", "route-b objective pack summary preserves the upgraded hunter-room reward table")
	_assert_stage_equal(seed, stage, int(_summary.get("dungeon_peak_clear_count", 0)), 1, "route-b objective pack summary records one cleared peak room")

	await _dispose_run_node(run_node)


func _enter_objective_room(run_node: Node, seed: int, stage: String, room_id: String, objective_id: String, required_tag: String) -> void:
	_set_player_survival_buffer(run_node)
	run_node.call("debug_use_exit", room_id)
	await _wait_for_room_id(run_node, room_id)
	var snapshot: Dictionary = run_node.call("debug_get_snapshot")
	var objective: Dictionary = snapshot.get("objective", {})
	_assert_stage_equal(seed, stage, String(snapshot.get("room_id", "")), room_id, "enters the expected objective room %s" % room_id)
	_assert_stage_equal(seed, stage, String(objective.get("objective_id", "")), objective_id, "room snapshot exposes the expected objective id")
	_assert_stage_true(seed, stage, not String(snapshot.get("status_text", "")).strip_edges().is_empty(), "objective room publishes non-empty HUD status text")
	var tags_variant: Variant = (snapshot.get("room_payload", {}) as Dictionary).get("tags", [])
	var tags: Array = tags_variant if tags_variant is Array else []
	_assert_stage_true(seed, stage, tags.has(required_tag), "objective room payload keeps its authored reward tag %s" % required_tag)


func _complete_escort_objective(run_node: Node, seed: int, stage: String) -> void:
	for _step in range(180):
		var snapshot: Dictionary = run_node.call("debug_get_snapshot")
		if bool(snapshot.get("reward_panel_visible", false)):
			return
		var objective: Dictionary = snapshot.get("objective", {})
		var target_position = objective.get("active_target_position", Vector2.ZERO)
		_assert_stage_true(seed, stage, target_position is Vector2, "escort objective exposes an active target position")
		_set_player_survival_buffer(run_node)
		_teleport_player(run_node, target_position)
		await _wait_frames(12)
	_fail(_stage_label(seed, stage, "escort objective did not resolve in time"))


func _complete_payload_hack_objective(run_node: Node, seed: int, stage: String) -> void:
	for _step in range(2400):
		var snapshot: Dictionary = run_node.call("debug_get_snapshot")
		if bool(snapshot.get("reward_panel_visible", false)):
			return
		var objective: Dictionary = snapshot.get("objective", {})
		var elapsed_sec := float(objective.get("elapsed_sec", 0.0))
		var time_limit_sec := float(objective.get("time_limit_sec", 0.0))
		if bool(objective.get("failed", false)):
			break
		if time_limit_sec > 0.0 and elapsed_sec >= time_limit_sec + 0.5:
			break
		var target_position = objective.get("active_target_position", Vector2.ZERO)
		_set_player_survival_buffer(run_node)
		_teleport_player(run_node, target_position)
		if not bool(objective.get("interaction_started", false)):
			var interaction_snapshot := await _wait_for_objective_interaction(run_node, 18)
			_assert_stage_true(seed, stage, not interaction_snapshot.is_empty(), "payload-hack objective exposes an interaction prompt on the active relay")
			var prompt_text := String(interaction_snapshot.get("prompt_text", "")).strip_edges()
			_assert_stage_true(seed, stage, not prompt_text.is_empty(), "payload-hack interaction snapshot carries prompt text")
			var interaction_id := String(interaction_snapshot.get("interaction_id", "")).strip_edges()
			_assert_stage_true(seed, stage, bool(run_node.call("debug_interact_room_feature", interaction_id)), "payload-hack objective can start from the active relay prompt")
			await _wait_frames(1)
			continue
		await _wait_frames(1)
	_fail(_stage_label(seed, stage, "payload-hack objective did not resolve in time"))


func _complete_survive_timer_objective(run_node: Node, seed: int, stage: String) -> void:
	for _step in range(260):
		var snapshot: Dictionary = run_node.call("debug_get_snapshot")
		if bool(snapshot.get("reward_panel_visible", false)):
			return
		_set_player_survival_buffer(run_node)
		await _wait_frames(4)
	_fail(_stage_label(seed, stage, "survive-timer objective did not resolve in time"))


func _complete_elite_hunt_objective(run_node: Node, seed: int, stage: String) -> void:
	for _step in range(120):
		var snapshot: Dictionary = run_node.call("debug_get_snapshot")
		if bool(snapshot.get("reward_panel_visible", false)):
			return
		_set_player_survival_buffer(run_node)
		for enemy in _find_live_enemies(run_node):
			if enemy == null or not is_instance_valid(enemy):
				continue
			var behavior := String(enemy.get("behavior")).strip_edges().to_lower()
			var is_elite := bool(enemy.get("is_elite"))
			if behavior != "pursuer" and not is_elite:
				continue
			if enemy.has_method("take_hit"):
				enemy.call("take_hit", 9999.0, Vector2.ZERO)
		await _wait_frames(8)
	_fail(_stage_label(seed, stage, "elite-hunt objective did not resolve in time"))


func _complete_power_reroute_objective(run_node: Node, seed: int, stage: String) -> void:
	for _step in range(160):
		var snapshot: Dictionary = run_node.call("debug_get_snapshot")
		if bool(snapshot.get("reward_panel_visible", false)):
			return
		var objective: Dictionary = snapshot.get("objective", {})
		var target_position = objective.get("active_target_position", Vector2.ZERO)
		_set_player_survival_buffer(run_node)
		_teleport_player(run_node, target_position)
		var interaction_snapshot := await _wait_for_objective_interaction(run_node, 18)
		_assert_stage_true(seed, stage, not interaction_snapshot.is_empty(), "power-reroute objective exposes an interaction prompt on the active relay")
		var interaction_id := String(interaction_snapshot.get("interaction_id", "")).strip_edges()
		_assert_stage_true(seed, stage, bool(run_node.call("debug_interact_room_feature", interaction_id)), "power-reroute objective can advance from the active relay prompt")
		await _wait_frames(4)
	_fail(_stage_label(seed, stage, "power-reroute objective did not resolve in time"))


func _complete_cursed_cache_objective(run_node: Node, seed: int, stage: String) -> void:
	for _step in range(120):
		var snapshot: Dictionary = run_node.call("debug_get_snapshot")
		var objective: Dictionary = snapshot.get("objective", {})
		if int(objective.get("progress_count", 0)) >= int(objective.get("required_count", 0)):
			break
		_set_player_survival_buffer(run_node)
		for objective_node in _find_objective_nodes(run_node):
			if objective_node == null or not is_instance_valid(objective_node):
				continue
			if objective_node.has_method("take_hit"):
				objective_node.call("take_hit", 9999.0, Vector2.ZERO)
		await _wait_frames(6)
	var ready_snapshot: Dictionary = run_node.call("debug_get_snapshot")
	var interactions: Array = ready_snapshot.get("interactions", [])
	_assert_stage_equal(seed, stage, int(interactions.size()), 1, "cursed-cache objective enables one cache interaction after both seals break")
	var prompt_text := String((interactions[0] as Dictionary).get("prompt_text", "")) if not interactions.is_empty() and interactions[0] is Dictionary else ""
	_assert_stage_true(seed, stage, not prompt_text.is_empty(), "cursed-cache interaction snapshot carries prompt text")
	var target_position = (ready_snapshot.get("objective", {}) as Dictionary).get("active_target_position", Vector2.ZERO)
	_set_player_survival_buffer(run_node)
	_teleport_player(run_node, target_position)
	var interaction_id := String((interactions[0] as Dictionary).get("interaction_id", "")) if not interactions.is_empty() and interactions[0] is Dictionary else ""
	_assert_stage_true(seed, stage, bool(run_node.call("debug_interact_room_feature", interaction_id)), "cursed-cache objective can open the cache from the runtime prompt")
	var reward_snapshot := await _wait_for_reward_panel(run_node)
	_assert_stage_true(seed, stage, bool(reward_snapshot.get("reward_panel_visible", false)), "cursed-cache objective opens the reward panel after the cache interaction")


func _claim_combat_reward(run_node: Node, seed: int, stage: String, reward_index: int) -> void:
	var reward_snapshot := await _wait_for_reward_panel(run_node)
	_assert_stage_true(seed, stage, bool(reward_snapshot.get("reward_panel_visible", false)), "objective room still opens the shared combat reward panel")
	_assert_stage_true(seed, stage, bool(run_node.call("debug_select_room_reward", reward_index)), "objective room reward can be claimed after completion")
	await _wait_frames(2)


func _teleport_player(run_node: Node, world_position: Variant) -> void:
	if not (world_position is Vector2):
		return
	var player := _find_player(run_node)
	if player == null or not is_instance_valid(player):
		return
	player.global_position = world_position
	if player is CharacterBody2D:
		(player as CharacterBody2D).velocity = Vector2.ZERO


func _set_player_survival_buffer(run_node: Node) -> void:
	var player := _find_player(run_node)
	if player == null or not is_instance_valid(player):
		return
	player.set("hp", 999.0)
	player.set("noise", 0.0)
	if player.has_method("emit_stats_changed"):
		player.call("emit_stats_changed")


func _find_live_enemies(run_node: Node) -> Array:
	var enemies: Array = []
	if run_node == null or not is_instance_valid(run_node):
		return enemies
	for node in run_node.find_children("*", "Node", true, false):
		if node == null or not is_instance_valid(node):
			continue
		if not node.has_method("take_hit"):
			continue
		var enemy_id := String(node.get("enemy_id")).strip_edges()
		var behavior := String(node.get("behavior")).strip_edges()
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


func _start_run(seed_value: int, stage: String) -> Node:
	var run_scene: PackedScene = load("res://scenes/night/NightRun.tscn")
	if run_scene == null:
		_fail(_stage_label(seed_value, stage, "could not load NightRun.tscn"))
		return null
	_completed = false
	_summary.clear()
	var run_node: Node = run_scene.instantiate()
	root.add_child(run_node)
	if run_node.has_signal("session_completed"):
		run_node.connect("session_completed", Callable(self, "_on_session_completed"))
	run_node.call("start_session", {
		"day": 1,
		"character_id": _registry().call("get_default_character_id"),
		"map_id": _registry().call("get_default_map_id"),
		"contract_ids": [],
		"seed": seed_value,
		"session_duration_sec": 60.0
	})
	await _wait_frames(10)
	return run_node


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
		_fail("objective-pack smoke could not load DataRegistry")
		return
	_profile_store().call("load_profile", _registry().call("get_default_character_id"), _registry().call("get_default_map_id"))


func _find_player(run_node: Node) -> Node2D:
	if run_node == null or not is_instance_valid(run_node):
		return null
	for node in run_node.find_children("*", "Node", true, false):
		if String(node.name) == "Player" and node is Node2D:
			return node as Node2D
	return null


func _wait_for_room_id(run_node: Node, expected_room_id: String, max_frames: int = 720) -> void:
	for _frame in range(max_frames):
		var snapshot: Dictionary = run_node.call("debug_get_snapshot")
		if String(snapshot.get("room_id", "")) == expected_room_id:
			return
		await process_frame
	_fail("objective-pack smoke timed out waiting for room %s" % expected_room_id)


func _wait_for_reward_panel(run_node: Node, max_frames: int = 360) -> Dictionary:
	for _frame in range(max_frames):
		var snapshot: Dictionary = run_node.call("debug_get_snapshot")
		if bool(snapshot.get("reward_panel_visible", false)):
			return snapshot
		await process_frame
	_fail("objective-pack smoke timed out waiting for the reward panel")
	return run_node.call("debug_get_snapshot")
	return {}


func _wait_for_objective_interaction(run_node: Node, max_frames: int = 12) -> Dictionary:
	for _frame in range(maxi(1, max_frames)):
		var snapshot: Dictionary = run_node.call("debug_get_snapshot")
		var interactions_variant: Variant = snapshot.get("interactions", [])
		if interactions_variant is Array:
			for interaction_variant in interactions_variant:
				if not (interaction_variant is Dictionary):
					continue
				var interaction: Dictionary = interaction_variant
				if not String(interaction.get("interaction_id", "")).strip_edges().is_empty():
					return interaction.duplicate(true)
		await process_frame
	return {}


func _wait_for_completion(seed_value: int, stage: String, max_frames: int = 360) -> void:
	for _frame in range(max_frames):
		if _completed:
			return
		await process_frame
	_assert_stage_true(seed_value, stage, false, "timed out waiting for session completion")


func _dispose_run_node(run_node: Node) -> void:
	if run_node == null or not is_instance_valid(run_node):
		return
	var completed_callable := Callable(self, "_on_session_completed")
	if run_node.has_signal("session_completed") and run_node.is_connected("session_completed", completed_callable):
		run_node.disconnect("session_completed", completed_callable)
	if run_node.has_method("stop_session"):
		run_node.call("stop_session")
	run_node.queue_free()
	await process_frame
	await process_frame


func _on_session_completed(summary: Dictionary) -> void:
	_completed = true
	_summary = summary.duplicate(true)


func _summary_peak_room(room_id: String) -> Dictionary:
	var normalized_room_id := room_id.strip_edges().to_lower()
	var peak_rooms: Array = _summary.get("dungeon_peak_rooms", [])
	for peak_room_variant in peak_rooms:
		if not (peak_room_variant is Dictionary):
			continue
		var peak_room: Dictionary = peak_room_variant
		if String(peak_room.get("room_id", "")).strip_edges().to_lower() == normalized_room_id:
			return peak_room
	return {}


func _registry() -> Node:
	return root.get_node_or_null("DataRegistry")


func _profile_store() -> Node:
	return root.get_node_or_null("ProfileStore")


func _wait_frames(count: int) -> void:
	for _index in range(maxi(1, count)):
		await process_frame


func _stage_label(seed_value: int, stage: String, label: String) -> String:
	return "[seed=%d stage=%s] %s" % [seed_value, stage, label]


func _assert_stage_true(seed_value: int, stage: String, condition: bool, label: String) -> void:
	_assert_true(condition, _stage_label(seed_value, stage, label))


func _assert_stage_equal(seed_value: int, stage: String, actual, expected, label: String) -> void:
	_assert_equal(actual, expected, _stage_label(seed_value, stage, label))


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
	print(PASS_MARKER if failed == 0 else "Night V3 objective pack smoke FAIL")
	quit(failed)
