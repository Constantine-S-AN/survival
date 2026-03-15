extends SceneTree

var failed: int = 0
var _completed: bool = false
var _summary: Dictionary = {}
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

	var run_scene: PackedScene = load("res://scenes/night/NightRun.tscn")
	if run_scene == null:
		_fail("v2 boss smoke could not load NightRun.tscn")
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
		"seed": 9000,
		"session_duration_sec": 60.0
	})

	await _wait_frames(10)
	await _clear_and_claim_combat_room(run_node, "reef_patrol", 0)
	run_node.call("debug_use_exit", "relay_beacon")
	await _wait_for_room_id(run_node, "relay_beacon")
	await _clear_and_claim_combat_room(run_node, "relay_beacon", 1)
	run_node.call("debug_use_exit", "pressure_lock")
	await _wait_for_room_id(run_node, "pressure_lock")
	await _clear_and_claim_combat_room(run_node, "pressure_lock", 0)
	run_node.call("debug_use_exit", "apex_guardian")
	await _wait_for_room_id(run_node, "apex_guardian")

	var snapshot: Dictionary = run_node.call("debug_get_snapshot")
	_assert_equal(String(snapshot.get("room_id", "")), "apex_guardian", "v2 boss route preserves the stable boss room id")
	_assert_equal(String(snapshot.get("room_label", "")), "顶潮海妖", "v2 boss route localizes the live boss room label")
	_assert_equal(String(snapshot.get("encounter_id", "")), "apex_siren_ritual", "live v2 route enters the new siren encounter")
	_assert_equal(String(snapshot.get("spawn_set_id", "")), "apex_siren_phase_1", "v2 boss route starts from the new siren phase 1 spawn set")
	var boss_climax: Dictionary = snapshot.get("boss_climax", {})
	_assert_true(boss_climax.get("active", false) == true, "v2 boss route activates the boss climax panel")
	_assert_equal(String(boss_climax.get("phase_label", "")), "静默戒律", "v2 boss route surfaces the new phase-one boss label in the climax panel")

	run_node.call("debug_force_clear_room")
	var reward_snapshot := await _wait_for_reward_panel(run_node)
	_assert_true(reward_snapshot.get("reward_panel_visible", false) == true, "v2 boss clear still presents the final reward panel")
	_assert_true(run_node.call("debug_select_room_reward", 0) == true, "v2 boss final reward can be claimed")
	await _wait_for_completion()

	_assert_true(_completed, "v2 boss route completes the run after the final reward")
	_assert_equal(String(_summary.get("dungeon_last_room_id", "")), "apex_guardian", "v2 boss summary keeps the stable room id")
	_assert_equal(String(_summary.get("dungeon_last_encounter_id", "")), "apex_siren_ritual", "v2 boss summary records the new encounter id")
	var boss_bonus_materials: Dictionary = _summary.get("dungeon_boss_bonus_materials", {})
	_assert_true(int(boss_bonus_materials.get("abyssfin", 0)) >= 2, "v2 boss summary awards the deeper abyssfin payout")
	_assert_true(int(boss_bonus_materials.get("kitchen_blueprint_fragment", 0)) >= 1, "v2 boss summary still awards the blueprint fragment")

	await _dispose_run_node(run_node)
	_finish()


func _clear_and_claim_combat_room(run_node: Node, target_room_id: String, reward_index: int) -> void:
	var snapshot_variant: Variant = run_node.call("debug_get_snapshot")
	if snapshot_variant is Dictionary:
		var snapshot: Dictionary = snapshot_variant
		if String(snapshot.get("room_id", "")) != target_room_id:
			run_node.call("debug_use_exit", target_room_id)
			await _wait_for_room_id(run_node, target_room_id)
	run_node.call("debug_force_clear_room")
	var reward_snapshot := await _wait_for_reward_panel(run_node)
	_assert_true(reward_snapshot.get("reward_panel_visible", false) == true, "room %s opens its reward panel in the v2 boss route" % target_room_id)
	_assert_true(run_node.call("debug_select_room_reward", reward_index) == true, "room %s reward can be claimed before advancing" % target_room_id)
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
		_fail("v2 boss smoke could not load DataRegistry")
		return
	_profile_store().call("load_profile", _registry().call("get_default_character_id"), _registry().call("get_default_map_id"))


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


func _wait_for_completion(max_frames: int = 720) -> void:
	for _index in range(maxi(1, max_frames)):
		if _completed:
			return
		await process_frame


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
	print("Night V2 boss smoke finished. failed=%d" % failed)
	call_deferred("_quit_after_cleanup", failed)


func _quit_after_cleanup(exit_code: int) -> void:
	await process_frame
	quit(exit_code)
