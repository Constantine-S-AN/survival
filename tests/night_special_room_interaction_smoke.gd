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
	await _run_shop_flow()
	await _run_shrine_flow()
	_finish()


func _run_shop_flow() -> void:
	var run_node := await _start_run(9000)
	if run_node == null:
		return
	await _clear_and_claim_combat_room(run_node, "reef_patrol", 0)
	run_node.call("debug_use_exit", "salvage_market")
	await _wait_for_room_id(run_node, "salvage_market")
	var snapshot: Dictionary = run_node.call("debug_get_snapshot")
	_assert_equal(String(snapshot.get("room_id", "")), "salvage_market", "shop path enters the salvage market room")
	_assert_equal(int((snapshot.get("interactions", []) as Array).size()), 1, "shop room spawns one runtime interaction node")
	var player := _find_player(run_node)
	if player != null and is_instance_valid(player):
		player.set("xp", 96.0)
		if player.has_method("emit_stats_changed"):
			player.call("emit_stats_changed")
	await _wait_frames(2)
	snapshot = run_node.call("debug_get_snapshot")
	var xp_before := float((snapshot.get("player_hud", {}) as Dictionary).get("xp", 0.0))
	_assert_true(run_node.call("debug_interact_room_feature") == true, "shop interaction opens from the runtime node")
	var reward_snapshot := await _wait_for_reward_panel(run_node)
	_assert_true(reward_snapshot.get("reward_panel_visible", false) == true, "shop interaction opens the shared reward panel")
	var reward_choices: Array = reward_snapshot.get("reward_choices", [])
	_assert_equal(int(reward_choices.size()), 3, "shop presents three purchasable offers")
	if not reward_choices.is_empty() and reward_choices[0] is Dictionary:
		_assert_equal(String((reward_choices[0] as Dictionary).get("cost_type", "")), "xp", "shop offers are priced in XP")
	_assert_true(run_node.call("debug_select_room_reward", 0) == true, "shop purchase succeeds through the reward panel")
	await _wait_frames(2)
	snapshot = run_node.call("debug_get_snapshot")
	var xp_after := float((snapshot.get("player_hud", {}) as Dictionary).get("xp", 0.0))
	_assert_true(xp_after < xp_before, "shop purchase deducts XP immediately")
	_assert_true(snapshot.get("room_reward_claimed", false) == true, "shop purchase marks the room reward as claimed")
	_assert_equal(int((snapshot.get("interactions", []) as Array).size()), 0, "shop interaction node is removed after purchase")
	await _dispose_run_node(run_node)


func _run_shrine_flow() -> void:
	var run_node := await _start_run(9000)
	if run_node == null:
		return
	await _clear_and_claim_combat_room(run_node, "reef_patrol", 1)
	await _clear_and_claim_combat_room(run_node, "relay_beacon", 1)
	run_node.call("debug_use_exit", "tide_statue")
	await _wait_for_room_id(run_node, "tide_statue")
	var snapshot: Dictionary = run_node.call("debug_get_snapshot")
	_assert_equal(String(snapshot.get("room_id", "")), "tide_statue", "shrine path enters the tide statue room")
	_assert_equal(int((snapshot.get("interactions", []) as Array).size()), 1, "shrine room spawns one runtime interaction node")
	var player := _find_player(run_node)
	if player != null and is_instance_valid(player):
		player.set("hp", 18.0)
		player.set("noise", 12.0)
		if player.has_method("emit_stats_changed"):
			player.call("emit_stats_changed")
	await _wait_frames(2)
	snapshot = run_node.call("debug_get_snapshot")
	var hud_before: Dictionary = snapshot.get("player_hud", {})
	var noise_before := float(hud_before.get("noise", 0.0))
	_assert_true(run_node.call("debug_interact_room_feature") == true, "shrine interaction opens from the runtime node")
	var reward_snapshot := await _wait_for_reward_panel(run_node)
	_assert_true(reward_snapshot.get("reward_panel_visible", false) == true, "shrine interaction opens the blessing panel")
	var reward_choices: Array = reward_snapshot.get("reward_choices", [])
	_assert_equal(int(reward_choices.size()), 3, "shrine presents three blessing offers")
	if not reward_choices.is_empty() and reward_choices[0] is Dictionary:
		_assert_equal(String((reward_choices[0] as Dictionary).get("reward_kind", "")), "blessing", "shrine offers blessings instead of generic upgrades")
	_assert_true(run_node.call("debug_select_room_reward", 0) == true, "shrine blessing can be claimed from the runtime interaction")
	await _wait_frames(2)
	snapshot = run_node.call("debug_get_snapshot")
	var noise_after := float((snapshot.get("player_hud", {}) as Dictionary).get("noise", 0.0))
	_assert_true(noise_after > noise_before, "low-hp shrine interaction pays with noise when HP is unsafe")
	_assert_true(snapshot.get("room_reward_claimed", false) == true, "shrine claim marks the room reward as claimed")
	_assert_equal(int((snapshot.get("interactions", []) as Array).size()), 0, "shrine interaction node is removed after blessing choice")
	await _dispose_run_node(run_node)


func _start_run(seed_value: int) -> Node:
	var run_scene: PackedScene = load("res://scenes/night/NightRun.tscn")
	if run_scene == null:
		_fail("special room smoke could not load NightRun.tscn")
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
	run_node.call("debug_use_exit", target_room_id)
	await _wait_for_room_id(run_node, target_room_id)
	run_node.call("debug_force_clear_room")
	var reward_snapshot := await _wait_for_reward_panel(run_node)
	_assert_true(reward_snapshot.get("reward_panel_visible", false) == true, "combat room %s still opens a reward panel" % target_room_id)
	_assert_true(run_node.call("debug_select_room_reward", reward_index) == true, "combat room %s reward can be claimed before moving on" % target_room_id)
	await _wait_frames(2)


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
		_fail("special room smoke could not load DataRegistry")
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
	print("Night special room interaction smoke finished. failed=%d" % failed)
	call_deferred("_quit_after_cleanup", failed)


func _quit_after_cleanup(exit_code: int) -> void:
	await process_frame
	quit(exit_code)
