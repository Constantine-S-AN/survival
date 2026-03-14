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
	_assert_equal(String(snapshot.get("room_id", "")), "camp", "night run starts in the deterministic rest room")
	_assert_equal(String(snapshot.get("room_type_id", "")), "rest", "night run opens on a rest node")
	_assert_equal(String(snapshot.get("room_status", "")), "cleared", "rest room resolves immediately after entry")
	_assert_true(bool(snapshot.get("room_reward_claimed", false)), "rest room auto-claims its room reward")
	_assert_equal(int((snapshot.get("available_exits", []) as Array).size()), 2, "entry room exposes two route choices")
	_assert_true(_minimap_has_room_type(snapshot, "boss"), "minimap snapshot includes the boss room type")
	_assert_true(_minimap_has_room_type(snapshot, "treasure"), "minimap snapshot includes the treasure room type")
	_assert_true(_minimap_has_room_type(snapshot, "event"), "minimap snapshot includes the event room type")
	var reef_patrol_room := _find_room_snapshot(snapshot, "reef_patrol")
	var swarm_nest_room := _find_room_snapshot(snapshot, "swarm_nest")
	var apex_guardian_room := _find_room_snapshot(snapshot, "apex_guardian")
	_assert_equal(String(reef_patrol_room.get("encounter_category", "")), "standard", "reef patrol is marked as a standard encounter")
	_assert_equal(String(swarm_nest_room.get("encounter_category", "")), "elite", "swarm nest is marked as an elite encounter")
	_assert_equal(String(apex_guardian_room.get("encounter_category", "")), "boss", "apex guardian is marked as a boss encounter")
	_assert_true(String(reef_patrol_room.get("scene_path", "")).find("CombatRoom.tscn") < 0, "reef patrol now uses an authored combat room scene")
	_assert_true(String(apex_guardian_room.get("scene_path", "")).find("CombatRoom.tscn") < 0, "boss room now uses an authored boss-room scene")
	var first_reef_scene_path := String(reef_patrol_room.get("scene_path", ""))

	run_node.call("debug_use_exit", "swarm_nest")
	await _wait_frames(6)
	snapshot = run_node.call("debug_get_snapshot")
	_assert_equal(String(snapshot.get("room_id", "")), "swarm_nest", "selecting an exit advances into the chosen combat room")
	_assert_equal(String(snapshot.get("room_type_id", "")), "combat", "swarm nest room is treated as a combat room")
	_assert_equal(String(snapshot.get("encounter_category", "")), "elite", "combat room exposes its elite encounter category")
	_assert_equal(String(snapshot.get("room_status", "")), "active", "combat room becomes active on entry")
	_assert_true(not bool(snapshot.get("room_cleared", true)), "combat room remains uncleared until the encounter is resolved")
	_assert_true(_snapshot_has_locked_exit(snapshot), "combat room keeps its exit locked while enemies are alive")
	var elite_room_content: Dictionary = snapshot.get("room_content", {})
	_assert_true(int(elite_room_content.get("cover_count", 0)) >= 3, "elite room exposes authored cover geometry")
	_assert_true(int(elite_room_content.get("hazard_count", 0)) >= 1, "elite room exposes authored hazard setpieces")
	_assert_true(int(elite_room_content.get("explosive_count", 0)) >= 1, "elite room exposes authored explosive props")
	var base_weapon_dps := float((snapshot.get("player_hud", {}) as Dictionary).get("weapon_dps_estimate", 0.0))

	run_node.call("debug_force_clear_room")
	await _wait_frames(2)
	snapshot = run_node.call("debug_get_snapshot")
	_assert_true(bool(snapshot.get("room_cleared", false)), "forcing the encounter clear marks the room as cleared")
	_assert_true(not _snapshot_has_locked_exit(snapshot), "clearing the room unlocks its exit")
	_assert_true(bool(snapshot.get("reward_panel_visible", false)), "combat clear opens a room-end reward panel")
	_assert_true(not bool(snapshot.get("room_reward_claimed", true)), "combat room reward remains unclaimed until the player picks one")
	_assert_equal(int((snapshot.get("reward_choices", []) as Array).size()), 3, "combat clear presents three compact reward choices")
	_assert_true(_reward_choice_has_kind(snapshot, "currency"), "reward panel includes a currency or materials option")
	_assert_true(_reward_choice_has_kind(snapshot, "weapon"), "reward panel includes a weapon-focused run modifier")

	_assert_true(bool(run_node.call("debug_select_room_reward", 2)), "weapon reward option can be claimed from the room-end reward panel")
	await _wait_frames(2)
	snapshot = run_node.call("debug_get_snapshot")
	_assert_true(bool(snapshot.get("room_reward_claimed", false)), "claiming a room-end reward marks the room reward as claimed")
	_assert_true(not bool(snapshot.get("reward_panel_visible", true)), "reward panel closes after a reward is chosen")
	var run_modifier_state: Dictionary = snapshot.get("run_modifier_state", {})
	var applied_modifiers: Array = run_modifier_state.get("applied_modifiers", [])
	_assert_equal(int(applied_modifiers.size()), 1, "claiming a weapon reward records one applied run modifier")
	if not applied_modifiers.is_empty() and applied_modifiers[0] is Dictionary:
		_assert_equal(String((applied_modifiers[0] as Dictionary).get("reward_kind", "")), "weapon", "chosen reward is tracked as a weapon modifier")
	var upgraded_weapon_dps := float((snapshot.get("player_hud", {}) as Dictionary).get("weapon_dps_estimate", 0.0))
	_assert_true(upgraded_weapon_dps > base_weapon_dps, "claiming a weapon reward makes the player stronger within the same run")

	run_node.call("debug_use_exit", "quiet_niche")
	await _wait_frames(6)
	snapshot = run_node.call("debug_get_snapshot")
	_assert_equal(String(snapshot.get("room_id", "")), "quiet_niche", "elite branch advances into its linked rest room")
	_assert_equal(String(snapshot.get("room_type_id", "")), "rest", "quiet niche is marked as a rest room")
	_assert_true(bool(snapshot.get("room_reward_claimed", false)), "rest room claims its reward on entry")
	_assert_equal(String(snapshot.get("room_status", "")), "cleared", "rest room resolves immediately after its reward")

	run_node.call("debug_use_exit", "omen_shrine")
	await _wait_frames(6)
	snapshot = run_node.call("debug_get_snapshot")
	_assert_equal(String(snapshot.get("room_type_id", "")), "event", "elite branch feeds into an event room")
	_assert_true(bool(snapshot.get("room_reward_claimed", false)), "event room marks its reward as claimed")

	run_node.call("debug_use_exit", "apex_guardian")
	await _wait_frames(6)
	snapshot = run_node.call("debug_get_snapshot")
	_assert_equal(String(snapshot.get("room_type_id", "")), "boss", "final room is marked as a boss room")
	_assert_equal(String(snapshot.get("encounter_category", "")), "boss", "boss room exposes boss encounter metadata")
	var boss_climax: Dictionary = snapshot.get("boss_climax", {})
	_assert_true(bool(boss_climax.get("active", false)), "boss room activates the floor-climax panel")
	_assert_equal(String(boss_climax.get("title", "")), "Floor Climax", "boss panel shows the climax title")
	_assert_true(_snapshot_has_locked_exit(snapshot) == false, "boss room with no onward exits does not expose unlocked navigation")
	run_node.call("debug_force_clear_room")
	await _wait_frames(2)
	snapshot = run_node.call("debug_get_snapshot")
	_assert_true(bool(snapshot.get("reward_panel_visible", false)), "boss clear also triggers a final reward choice")
	_assert_true(bool(run_node.call("debug_select_room_reward", 0)), "final room reward can be claimed before extraction")
	await _wait_frames(8)

	_assert_true(_completed, "clearing the boss room completes the night run")
	_assert_equal(String(_summary.get("exit_reason", "")), "completed", "goal-room completion preserves the normal completed return flow")
	_assert_true(int(_summary.get("dungeon_rooms_cleared", 0)) >= 5, "summary tracks cleared rooms across the dungeon route")
	var room_path: Array = _summary.get("dungeon_room_path", [])
	_assert_true(room_path.has("camp"), "summary records the rest room in the dungeon path")
	_assert_true(room_path.has("swarm_nest"), "summary records the chosen elite branch room in the dungeon path")
	_assert_true(room_path.has("quiet_niche"), "summary records the linked rest room in the dungeon path")
	_assert_true(room_path.has("omen_shrine"), "summary records the event room in the dungeon path")
	_assert_true(room_path.has("apex_guardian"), "summary records the boss room in the dungeon path")
	_assert_equal(String(_summary.get("dungeon_last_room_type_id", "")), "boss", "summary records the final boss-room type")
	_assert_true((_summary.get("dungeon_run_rewards", []) as Array).size() >= 2, "summary records claimed room-end rewards across the run")
	_assert_true((_summary.get("dungeon_run_modifiers", []) as Array).size() >= 1, "summary records applied temporary run modifiers")
	_assert_true(bool(_summary.get("dungeon_boss_cleared", false)), "summary records the boss-floor clear")
	var boss_bonus_materials: Dictionary = _summary.get("dungeon_boss_bonus_materials", {})
	_assert_true(int(boss_bonus_materials.get("kitchen_blueprint_fragment", 0)) >= 1, "boss completion contributes explicit carryover materials")

	if run_node != null and is_instance_valid(run_node):
		run_node.queue_free()
	await process_frame

	_completed = false
	_summary.clear()
	run_node = run_scene.instantiate()
	root.add_child(run_node)
	if run_node.has_signal("session_completed"):
		run_node.connect("session_completed", Callable(self, "_on_session_completed"))
	run_node.call("start_session", {
		"day": 1,
		"character_id": _registry().call("get_default_character_id"),
		"map_id": _registry().call("get_default_map_id"),
		"contract_ids": [],
		"seed": 9002,
		"session_duration_sec": 60.0
	})

	await _wait_frames(10)
	snapshot = run_node.call("debug_get_snapshot")
	var second_reef_scene_path := String(_find_room_snapshot(snapshot, "reef_patrol").get("scene_path", ""))
	_assert_true(
		not second_reef_scene_path.is_empty() and second_reef_scene_path != first_reef_scene_path,
		"different deterministic seeds pick different authored combat-room scenes"
	)
	run_node.call("debug_use_exit", "reef_patrol")
	await _wait_frames(6)
	snapshot = run_node.call("debug_get_snapshot")
	var standard_room_content: Dictionary = snapshot.get("room_content", {})
	_assert_true(int(standard_room_content.get("cover_count", 0)) >= 3, "standard room exposes authored cover geometry")
	_assert_true(int(standard_room_content.get("hazard_count", 0)) >= 1, "standard room exposes authored hazards")
	_assert_true(int(standard_room_content.get("explosive_count", 0)) >= 1, "standard room exposes authored explosive props")
	run_node.call("debug_force_clear_room")
	await _wait_frames(2)
	_assert_true(bool(run_node.call("debug_select_room_reward", 0)), "extraction test can still claim a room reward before leaving")
	await _wait_frames(2)
	snapshot = run_node.call("debug_get_snapshot")
	var extraction_snapshot: Dictionary = snapshot.get("extraction", {})
	_assert_true(bool(extraction_snapshot.get("available", false)), "early extraction becomes available after securing a combat room")
	_assert_true(bool(run_node.call("debug_request_extract")), "night run accepts an early extraction request from a secured room")
	await _wait_frames(8)
	_assert_true(_completed, "early extraction also completes the night run flow")
	_assert_equal(String(_summary.get("exit_reason", "")), "extracted", "early extract produces the extracted return reason")
	_assert_true(bool(_summary.get("dungeon_extracted_early", false)), "summary records that the run ended via early extraction")
	_assert_equal(String(_summary.get("dungeon_extraction_room_id", "")), "reef_patrol", "summary records which room the player extracted from")
	var carryover_materials: Dictionary = _summary.get("dungeon_carryover_materials", {})
	_assert_true(int(carryover_materials.get("scrap", 0)) >= 1, "extraction secures room-clear carryover materials")
	var carryover_rows: Array = _summary.get("dungeon_carryover_rows", [])
	_assert_true(int(carryover_rows.size()) >= 2, "summary includes a carryover breakdown for return presentation")
	_assert_true((_summary.get("dungeon_boss_bonus_materials", {}) as Dictionary).is_empty(), "early extraction leaves boss-only carryover behind")

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


func _minimap_has_room_type(snapshot: Dictionary, room_type_id: String) -> bool:
	var minimap_snapshot: Dictionary = snapshot.get("minimap", {})
	var rooms: Array = minimap_snapshot.get("rooms", [])
	for room_variant in rooms:
		if not (room_variant is Dictionary):
			continue
		if String((room_variant as Dictionary).get("room_type_id", "")) == room_type_id:
			return true
	return false


func _find_room_snapshot(snapshot: Dictionary, room_id: String) -> Dictionary:
	var rooms: Array = snapshot.get("floor_rooms", [])
	for room_variant in rooms:
		if not (room_variant is Dictionary):
			continue
		var room: Dictionary = room_variant
		if String(room.get("id", "")) == room_id:
			return room
	return {}


func _reward_choice_has_kind(snapshot: Dictionary, reward_kind: String) -> bool:
	var rewards: Array = snapshot.get("reward_choices", [])
	for reward_variant in rewards:
		if not (reward_variant is Dictionary):
			continue
		if String((reward_variant as Dictionary).get("reward_kind", "")) == reward_kind:
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
