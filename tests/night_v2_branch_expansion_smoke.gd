extends SceneTree

var failed: int = 0
var _original_language_code: String = "en"
var _finish_requested: bool = false


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_bootstrap_script_mode_singletons()
	var localization := _localization()
	if localization != null and localization.has_method("get_language_code"):
		_original_language_code = String(localization.call("get_language_code"))
	if localization != null and localization.has_method("set_language_code"):
		localization.call("set_language_code", "zh_CN")
	await _run_floor_mutator_and_second_shop_flow()
	await _run_hidden_room_flow()
	await _run_second_shrine_flow()
	_finish()


func _run_floor_mutator_and_second_shop_flow() -> void:
	var run_node := await _start_run(9000)
	if run_node == null:
		return
	var snapshot: Dictionary = run_node.call("debug_get_snapshot")
	var floor_mutator: Dictionary = snapshot.get("floor_mutator", {})
	var mutator_id := String(floor_mutator.get("mutator_id", floor_mutator.get("id", "")))
	_assert_true(not mutator_id.is_empty(), "v2 live floor applies a floor mutator on entry")
	var system_modifiers: Array = (snapshot.get("run_modifier_state", {}) as Dictionary).get("system_modifiers", [])
	_assert_equal(int(system_modifiers.size()), 1, "floor mutator is tracked as one system modifier")
	_assert_true(not _snapshot_has_room(snapshot, "smuggler_cut"), "hidden room stays off the initial map snapshot")

	await _clear_and_claim_combat_room(run_node, "turret_cache", 0)
	run_node.call("debug_use_exit", "echo_bazaar")
	await _wait_for_room_id(run_node, "echo_bazaar")

	snapshot = run_node.call("debug_get_snapshot")
	var interactions: Array = snapshot.get("interactions", [])
	_assert_equal(String(snapshot.get("room_id", "")), "echo_bazaar", "second shop room is reachable from the v2 lower branch")
	_assert_equal(int(interactions.size()), 1, "second shop spawns one runtime interaction node")
	if not interactions.is_empty() and interactions[0] is Dictionary:
		_assert_equal(String((interactions[0] as Dictionary).get("interaction_kind", "")), "shop", "second shop interaction is classified as a shop")

	var player := _find_player(run_node)
	if player != null and is_instance_valid(player):
		player.set("xp", 160.0)
		if player.has_method("emit_stats_changed"):
			player.call("emit_stats_changed")
	await _wait_frames(2)
	var xp_before := float(((run_node.call("debug_get_snapshot") as Dictionary).get("player_hud", {}) as Dictionary).get("xp", 0.0))
	_assert_true(run_node.call("debug_interact_room_feature") == true, "second shop opens from the runtime interaction")
	var reward_snapshot := await _wait_for_reward_panel(run_node)
	var reward_choices: Array = reward_snapshot.get("reward_choices", [])
	_assert_equal(int(reward_choices.size()), 3, "second shop presents three purchasable offers")
	if reward_choices.size() >= 3:
		_assert_equal(String((reward_choices[0] as Dictionary).get("reward_kind", "")), "materials", "second shop keeps a bundle slot")
		_assert_equal(String((reward_choices[1] as Dictionary).get("reward_kind", "")), "weapon_trait", "second shop upgrades the trait slot")
		_assert_true(int((reward_choices[1] as Dictionary).get("cost_value", 0)) > 48, "second shop prices are higher than tier-1 shop offers")
	_assert_true(run_node.call("debug_select_room_reward", 1) == true, "second shop purchase can be claimed")
	await _wait_frames(2)
	snapshot = run_node.call("debug_get_snapshot")
	var xp_after := float((snapshot.get("player_hud", {}) as Dictionary).get("xp", 0.0))
	_assert_true(xp_after < xp_before, "second shop purchase deducts XP")
	_assert_true(snapshot.get("room_reward_claimed", false) == true, "second shop claim marks the room reward as claimed")
	await _dispose_run_node(run_node)


func _run_hidden_room_flow() -> void:
	var run_node := await _start_run(9000)
	if run_node == null:
		return
	await _clear_and_claim_combat_room(run_node, "turret_cache", 0)
	run_node.call("debug_use_exit", "swarm_nest")
	await _wait_for_room_id(run_node, "swarm_nest")

	var snapshot: Dictionary = run_node.call("debug_get_snapshot")
	_assert_true(not _snapshot_has_exit(snapshot, "smuggler_cut"), "hidden room exit stays concealed before the source room is cleared")
	_assert_true(not _snapshot_has_room(snapshot, "smuggler_cut"), "hidden room stays off the map before reveal")
	_assert_true(_snapshot_has_room(snapshot, "undertow_altar"), "visible shrine branch still appears on the map")

	run_node.call("debug_force_clear_room")
	var reward_snapshot := await _wait_for_reward_panel(run_node)
	_assert_true(reward_snapshot.get("reward_panel_visible", false) == true, "hidden-room source combat still opens a reward panel")
	snapshot = run_node.call("debug_get_snapshot")
	_assert_true(_snapshot_has_exit(snapshot, "smuggler_cut"), "clearing the source room reveals the hidden exit")
	_assert_true(_snapshot_has_room(snapshot, "smuggler_cut"), "clearing the source room reveals the hidden room on the map")
	_assert_true(run_node.call("debug_select_room_reward", 0) == true, "hidden-room source reward can still be claimed before moving")
	await _wait_frames(2)

	run_node.call("debug_use_exit", "smuggler_cut")
	await _wait_for_room_id(run_node, "smuggler_cut")
	snapshot = run_node.call("debug_get_snapshot")
	_assert_equal(String(snapshot.get("room_id", "")), "smuggler_cut", "revealed hidden room is enterable from the live route")
	_assert_equal(String(snapshot.get("room_type_id", "")), "treasure", "hidden room uses the treasure-room shell")
	_assert_true(snapshot.get("room_reward_claimed", false) == true, "hidden treasure room auto-claims its reward on entry")
	await _dispose_run_node(run_node)


func _run_second_shrine_flow() -> void:
	var run_node := await _start_run(9000)
	if run_node == null:
		return
	await _clear_and_claim_combat_room(run_node, "turret_cache", 0)
	run_node.call("debug_use_exit", "swarm_nest")
	await _wait_for_room_id(run_node, "swarm_nest")
	await _clear_and_claim_combat_room(run_node, "swarm_nest", 1)
	run_node.call("debug_use_exit", "undertow_altar")
	await _wait_for_room_id(run_node, "undertow_altar")

	var snapshot: Dictionary = run_node.call("debug_get_snapshot")
	var interactions: Array = snapshot.get("interactions", [])
	_assert_equal(String(snapshot.get("room_id", "")), "undertow_altar", "second shrine room is reachable from the v2 route")
	_assert_equal(int(interactions.size()), 1, "second shrine spawns one runtime interaction node")
	if not interactions.is_empty() and interactions[0] is Dictionary:
		_assert_equal(String((interactions[0] as Dictionary).get("interaction_kind", "")), "shrine", "second shrine interaction is classified as a shrine")

	var player := _find_player(run_node)
	if player != null and is_instance_valid(player):
		player.set("hp", 40.0)
		player.set("noise", 6.0)
		if player.has_method("emit_stats_changed"):
			player.call("emit_stats_changed")
	await _wait_frames(2)
	_assert_true(run_node.call("debug_interact_room_feature") == true, "second shrine opens from the runtime interaction")
	var reward_snapshot := await _wait_for_reward_panel(run_node)
	var reward_choices: Array = reward_snapshot.get("reward_choices", [])
	_assert_equal(int(reward_choices.size()), 3, "second shrine presents three blessing offers")
	for reward_variant in reward_choices:
		if reward_variant is Dictionary:
			_assert_equal(String((reward_variant as Dictionary).get("reward_kind", "")), "blessing", "second shrine only offers blessings")
	_assert_true(run_node.call("debug_select_room_reward", 0) == true, "second shrine blessing can be claimed")
	await _wait_frames(2)
	snapshot = run_node.call("debug_get_snapshot")
	_assert_true(snapshot.get("room_reward_claimed", false) == true, "second shrine claim marks the room reward as claimed")
	await _dispose_run_node(run_node)


func _start_run(seed_value: int) -> Node:
	var run_scene: PackedScene = load("res://scenes/night/NightRun.tscn")
	if run_scene == null:
		_fail("v2 branch expansion smoke could not load NightRun.tscn")
		return null
	var run_node: Node = run_scene.instantiate()
	root.add_child(run_node)
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


func _clear_and_claim_combat_room(run_node: Node, target_room_id: String, reward_index: int) -> void:
	var snapshot_variant: Variant = run_node.call("debug_get_snapshot")
	if snapshot_variant is Dictionary:
		var snapshot: Dictionary = snapshot_variant
		if String(snapshot.get("room_id", "")) != target_room_id:
			run_node.call("debug_use_exit", target_room_id)
			await _wait_for_room_id(run_node, target_room_id)
	run_node.call("debug_force_clear_room")
	var reward_snapshot := await _wait_for_reward_panel(run_node)
	_assert_true(reward_snapshot.get("reward_panel_visible", false) == true, "room %s opens a reward panel in the v2 expansion route" % target_room_id)
	_assert_true(run_node.call("debug_select_room_reward", reward_index) == true, "room %s reward can be claimed before advancing" % target_room_id)
	await _wait_frames(2)


func _snapshot_has_room(snapshot: Dictionary, room_id: String) -> bool:
	var rooms: Array = snapshot.get("floor_rooms", [])
	for room_variant in rooms:
		if not (room_variant is Dictionary):
			continue
		if String((room_variant as Dictionary).get("id", "")) == room_id:
			return true
	return false


func _snapshot_has_exit(snapshot: Dictionary, room_id: String) -> bool:
	var exits: Array = snapshot.get("available_exits", [])
	for exit_variant in exits:
		if not (exit_variant is Dictionary):
			continue
		if String((exit_variant as Dictionary).get("target_room_id", "")) == room_id:
			return true
	return false


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
		_fail("v2 branch expansion smoke could not load DataRegistry")
		return
	_profile_store().call("load_profile", _registry().call("get_default_character_id"), _registry().call("get_default_map_id"))


func _find_player(run_node: Node) -> Node:
	if run_node == null or not is_instance_valid(run_node):
		return null
	for node in run_node.find_children("*", "Node", true, false):
		if String(node.name) == "Player" and node.has_method("get_hud_data"):
			return node
	return null


func _registry() -> Node:
	return root.get_node_or_null("DataRegistry")


func _profile_store() -> Node:
	return root.get_node_or_null("ProfileStore")


func _localization() -> Node:
	return root.get_node_or_null("Localization")


func _wait_frames(count: int) -> void:
	for _index in range(maxi(1, count)):
		await process_frame


func _wait_for_room_id(run_node: Node, expected_room_id: String, max_frames: int = 720) -> void:
	for _index in range(maxi(1, max_frames)):
		var snapshot_variant: Variant = run_node.call("debug_get_snapshot")
		if snapshot_variant is Dictionary:
			var snapshot: Dictionary = snapshot_variant
			if String(snapshot.get("room_id", "")) == expected_room_id and String(snapshot.get("state", "")) != "transiting":
				return
		await process_frame


func _wait_for_reward_panel(run_node: Node, max_frames: int = 180) -> Dictionary:
	for _index in range(maxi(1, max_frames)):
		var snapshot_variant: Variant = run_node.call("debug_get_snapshot")
		if snapshot_variant is Dictionary:
			var snapshot: Dictionary = snapshot_variant
			if snapshot.get("reward_panel_visible", false) == true:
				return snapshot
		await process_frame
	return {}


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
	if _finish_requested:
		return
	_finish_requested = true
	var localization := _localization()
	if localization != null and localization.has_method("set_language_code"):
		localization.call("set_language_code", _original_language_code)
	print("Night V2 branch expansion smoke finished. failed=%d" % failed)
	call_deferred("_quit_after_cleanup", failed)


func _quit_after_cleanup(exit_code: int) -> void:
	await process_frame
	quit(exit_code)
