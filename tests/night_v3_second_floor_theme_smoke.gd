extends SceneTree

const SECOND_THEME_TEMPLATE_ID := "sunken_exchange_v2_route_b"
const SECOND_THEME_MUTATORS := [
	"mutator_salt_thickening",
	"mutator_relay_static",
	"mutator_contraband_current"
]

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
	await _run_seed_selected_theme_flow()
	await _run_forced_template_override_flow()
	_finish()


func _run_seed_selected_theme_flow() -> void:
	var run_node := await _start_run(9003)
	if run_node == null:
		return
	var snapshot: Dictionary = run_node.call("debug_get_snapshot")
	_assert_equal(String(snapshot.get("floor_template_id", "")), SECOND_THEME_TEMPLATE_ID, "seed 9003 selects the second floor theme")
	var minimap: Dictionary = snapshot.get("minimap", {})
	_assert_equal(String(minimap.get("template_id", "")), SECOND_THEME_TEMPLATE_ID, "minimap reports the second floor theme template id")
	var floor_mutator: Dictionary = snapshot.get("floor_mutator", {})
	var mutator_id := String(floor_mutator.get("mutator_id", floor_mutator.get("id", "")))
	_assert_true(SECOND_THEME_MUTATORS.has(mutator_id), "second floor theme draws a mutator from its dedicated pool")
	_assert_true(_snapshot_has_room(snapshot, "kelp_watch"), "second floor theme exposes the kelp_watch starter room")
	_assert_true(_snapshot_has_room(snapshot, "salt_vault"), "second floor theme exposes the salt_vault starter room")
	_assert_true(not _snapshot_has_room(snapshot, "reef_patrol"), "second floor theme does not reuse the original reef_patrol room id")
	var kelp_watch := _find_room_snapshot(snapshot, "kelp_watch")
	_assert_equal(String((kelp_watch.get("metadata", {}) as Dictionary).get("theme_id", "")), "sunken_exchange", "second floor rooms advertise the new theme id in metadata")
	_assert_equal(String(kelp_watch.get("spawn_set_id", "")), "kelp_watch_volley", "second floor starter room uses its theme-specific spawn set")
	_assert_equal(String((kelp_watch.get("metadata", {}) as Dictionary).get("preview_reward_material", "")), "reef_salt", "second floor starter room previews its theme material")
	_assert_true(_snapshot_has_exit(snapshot, "kelp_watch"), "second floor start room can route into kelp_watch")
	_assert_true(_snapshot_has_exit(snapshot, "salt_vault"), "second floor start room can route into salt_vault")

	await _clear_and_claim_combat_room(run_node, "kelp_watch", 0)
	run_node.call("debug_use_exit", "signal_jetty")
	await _wait_for_room_id(run_node, "signal_jetty")
	snapshot = run_node.call("debug_get_snapshot")
	_assert_equal(String(snapshot.get("spawn_set_id", "")), "signal_jetty_wave_1", "second floor objective room uses its theme-specific opening spawn set")
	var objective: Dictionary = snapshot.get("objective", {})
	_assert_equal(String(objective.get("objective_id", "")), "hold_zone", "objective room snapshot exposes the normalized objective id")
	_assert_true(objective.get("active", false) == true, "objective runtime marks hold-zone objectives as active on room entry")
	_assert_true(objective.get("blocks_clear", false) == true, "objective runtime blocks room clear until the objective resolves")
	_assert_equal(int(objective.get("required_count", 0)), 1, "objective runtime snapshot records the required hold-zone target count")
	_assert_true(float(objective.get("elapsed_sec", -1.0)) >= 0.0, "objective runtime snapshot exposes elapsed objective time")
	await _clear_and_claim_combat_room(run_node, "signal_jetty", 1)

	run_node.call("debug_use_exit", "hushed_aisle")
	await _wait_for_room_id(run_node, "hushed_aisle")
	snapshot = run_node.call("debug_get_snapshot")
	_assert_equal(String(snapshot.get("room_type_id", "")), "rest", "second floor route includes a dedicated rest room")
	_assert_true(snapshot.get("room_reward_claimed", false) == true, "second floor rest room auto-claims on entry")

	run_node.call("debug_use_exit", "customs_gate")
	await _wait_for_room_id(run_node, "customs_gate")
	await _clear_and_claim_combat_room(run_node, "customs_gate", 0)

	run_node.call("debug_use_exit", "apex_guardian")
	await _wait_for_room_id(run_node, "apex_guardian")
	snapshot = run_node.call("debug_get_snapshot")
	_assert_equal(String(snapshot.get("room_type_id", "")), "boss", "second floor route can advance to the boss room")
	_assert_equal(String(snapshot.get("room_id", "")), "apex_guardian", "second floor route reaches the stable boss-room endpoint")
	await _dispose_run_node(run_node)


func _run_forced_template_override_flow() -> void:
	var run_node := await _start_run(9000, {
		"floor_template_overrides": {
			"floor_1": SECOND_THEME_TEMPLATE_ID
		}
	})
	if run_node == null:
		return
	var snapshot: Dictionary = run_node.call("debug_get_snapshot")
	_assert_equal(String(snapshot.get("floor_template_id", "")), SECOND_THEME_TEMPLATE_ID, "explicit template override forces the second floor theme")
	_assert_true(_snapshot_has_exit(snapshot, "kelp_watch"), "template override keeps the second theme route exits available")
	_assert_true(_snapshot_has_exit(snapshot, "salt_vault"), "template override keeps the second theme lower branch available")
	_assert_true(not _snapshot_has_exit(snapshot, "reef_patrol"), "template override removes the original starter branch from this run")
	await _dispose_run_node(run_node)


func _start_run(seed_value: int, extra_request: Dictionary = {}) -> Node:
	var run_scene: PackedScene = load("res://scenes/night/NightRun.tscn")
	if run_scene == null:
		_fail("v3 second floor theme smoke could not load NightRun.tscn")
		return null
	var run_node: Node = run_scene.instantiate()
	root.add_child(run_node)
	var request := {
		"day": 1,
		"character_id": _registry().call("get_default_character_id"),
		"map_id": _registry().call("get_default_map_id"),
		"contract_ids": [],
		"seed": seed_value,
		"session_duration_sec": 60.0
	}
	for key_variant in extra_request.keys():
		request[key_variant] = extra_request[key_variant]
	run_node.call("start_session", request)
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
	_assert_true(reward_snapshot.get("reward_panel_visible", false) == true, "room %s opens a reward panel in the second floor theme" % target_room_id)
	_assert_true(run_node.call("debug_select_room_reward", reward_index) == true, "room %s reward can be claimed before advancing on the second floor theme" % target_room_id)
	await _wait_frames(2)


func _snapshot_has_room(snapshot: Dictionary, room_id: String) -> bool:
	return not _find_room_snapshot(snapshot, room_id).is_empty()


func _find_room_snapshot(snapshot: Dictionary, room_id: String) -> Dictionary:
	var rooms: Array = snapshot.get("floor_rooms", [])
	for room_variant in rooms:
		if not (room_variant is Dictionary):
			continue
		var room: Dictionary = room_variant
		if String(room.get("id", "")) == room_id:
			return room
	return {}


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
		_fail("v3 second floor theme smoke could not load DataRegistry")
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
	print("Night V3 second floor theme smoke finished. failed=%d" % failed)
	call_deferred("_quit_after_cleanup", failed)


func _quit_after_cleanup(exit_code: int) -> void:
	await process_frame
	quit(exit_code)
