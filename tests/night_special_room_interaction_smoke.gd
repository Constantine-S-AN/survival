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
	var shop_state: Dictionary = {}
	var player := _find_player(run_node)
	if player != null and is_instance_valid(player):
		player.set("xp", 144.0)
		if player.has_method("emit_stats_changed"):
			player.call("emit_stats_changed")
	await _wait_frames(2)
	snapshot = run_node.call("debug_get_snapshot")
	var xp_before := float((snapshot.get("player_hud", {}) as Dictionary).get("xp", 0.0))
	_assert_true(run_node.call("debug_interact_room_feature") == true, "shop interaction opens from the runtime node")
	var reward_snapshot := await _wait_for_reward_panel(run_node)
	_assert_true(reward_snapshot.get("reward_panel_visible", false) == true, "shop interaction opens the shared reward panel")
	shop_state = reward_snapshot.get("shop_state", {})
	_assert_equal(String(shop_state.get("theme_id", "")), "harbor_rift", "harbor route shop snapshot records the harbor theme")
	var reward_choices: Array = reward_snapshot.get("reward_choices", [])
	_assert_equal(int(reward_choices.size()), 3, "shop presents three purchasable offers")
	if not reward_choices.is_empty() and reward_choices[0] is Dictionary:
		_assert_equal(String((reward_choices[0] as Dictionary).get("cost_type", "")), "xp", "shop offers are priced in XP")
	var initial_offer_ids := _shop_offer_ids(reward_choices)
	_assert_true(run_node.call("debug_toggle_shop_lock", 0) == true, "shop slot locking succeeds from the runtime session")
	await _wait_frames(1)
	snapshot = run_node.call("debug_get_snapshot")
	shop_state = snapshot.get("shop_state", {})
	_assert_true(_shop_slot_locked(shop_state, 0), "shop snapshot records the locked slot state")
	_assert_true(run_node.call("debug_refresh_shop") == true, "shop refresh succeeds through the runtime session")
	await _wait_frames(2)
	snapshot = run_node.call("debug_get_snapshot")
	var xp_after_refresh := float((snapshot.get("player_hud", {}) as Dictionary).get("xp", 0.0))
	shop_state = snapshot.get("shop_state", {})
	var refreshed_offer_ids := _shop_offer_ids_from_state(shop_state)
	_assert_true(xp_after_refresh < xp_before, "shop refresh deducts XP immediately")
	_assert_equal(int(shop_state.get("refresh_count", 0)), 1, "shop snapshot records refresh count after reroll")
	_assert_equal(refreshed_offer_ids[0] if not refreshed_offer_ids.is_empty() else "", initial_offer_ids[0] if not initial_offer_ids.is_empty() else "", "locked slot preserves its offer across refresh")
	_assert_true(initial_offer_ids != refreshed_offer_ids, "shop refresh rerolls at least one unlocked offer")
	_assert_true(int((shop_state.get("actions", []) as Array).size()) >= 2, "shop snapshot records lock and refresh actions")
	_assert_true(bool(snapshot.get("reward_panel_visible", false)), "shop refresh keeps the panel open for follow-up decisions")
	reward_choices = snapshot.get("reward_choices", [])
	_assert_true(run_node.call("debug_select_room_reward", 1) == true, "shop purchase succeeds through the refreshed reward panel")
	await _wait_frames(2)
	snapshot = run_node.call("debug_get_snapshot")
	var xp_after_purchase := float((snapshot.get("player_hud", {}) as Dictionary).get("xp", 0.0))
	shop_state = snapshot.get("shop_state", {})
	_assert_true(xp_after_purchase < xp_after_refresh, "shop purchase deducts XP after the refresh step")
	_assert_true(not bool(snapshot.get("room_reward_claimed", false)), "shop session no longer converts the room into a one-shot claimed reward")
	_assert_equal(int((snapshot.get("interactions", []) as Array).size()), 1, "shop interaction node stays active after purchase for follow-up decisions")
	_assert_true(int((shop_state.get("actions", []) as Array).size()) >= 3, "shop snapshot records purchase actions alongside lock and refresh")
	await _dispose_run_node(run_node)

	var second_run := await _start_run(9003)
	if second_run == null:
		return
	await _clear_and_claim_combat_room(second_run, "salt_vault", 0)
	second_run.call("debug_use_exit", "rust_market")
	await _wait_for_room_id(second_run, "rust_market")
	snapshot = second_run.call("debug_get_snapshot")
	_assert_equal(String(snapshot.get("room_id", "")), "rust_market", "second floor theme shop path reaches the rust market room")
	_assert_true(second_run.call("debug_interact_room_feature") == true, "second floor theme shop opens from the runtime node")
	reward_snapshot = await _wait_for_reward_panel(second_run)
	shop_state = reward_snapshot.get("shop_state", {})
	_assert_equal(String(shop_state.get("theme_id", "")), "sunken_exchange", "second floor theme shop snapshot records the sunken-exchange theme")
	_assert_true(_shop_state_has_rare_slot(shop_state), "tier-2 shop snapshot exposes a rare slot")
	_assert_true(_shop_offer_ids_from_state(shop_state) != refreshed_offer_ids, "different floor themes roll different shop pools")
	await _dispose_run_node(second_run)


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
		player.set("hp", 28.0)
		player.set("noise", 4.0)
		if player.has_method("emit_stats_changed"):
			player.call("emit_stats_changed")
	await _wait_frames(2)
	_assert_true(run_node.call("debug_interact_room_feature") == true, "shrine interaction opens from the runtime node")
	var reward_snapshot := await _wait_for_reward_panel(run_node)
	_assert_true(reward_snapshot.get("reward_panel_visible", false) == true, "shrine interaction opens the blessing panel")
	var reward_choices: Array = reward_snapshot.get("reward_choices", [])
	_assert_equal(int(reward_choices.size()), 3, "shrine presents three blessing offers")
	_assert_equal(int(_shrine_direction_ids(reward_choices).size()), 3, "shrine offers one directed blessing per build lane")
	var cost_types := _shrine_cost_types(reward_choices)
	_assert_true(cost_types.has("hp"), "shrine offer set includes an HP cost lane")
	_assert_true(cost_types.has("noise"), "shrine offer set includes a noise cost lane")
	_assert_true(cost_types.has("curse"), "shrine offer set includes a curse cost lane")
	var shrine_state: Dictionary = reward_snapshot.get("shrine_state", {})
	_assert_equal(String(shrine_state.get("pool_id", "")), "tide_statue_pool", "shrine snapshot records the tide-statue pool id")
	for reward_variant in reward_choices:
		if not (reward_variant is Dictionary):
			continue
		_assert_equal(String((reward_variant as Dictionary).get("reward_kind", "")), "blessing", "shrine offers blessings instead of generic upgrades")
		_assert_true(not String((reward_variant as Dictionary).get("shrine_direction_label", "")).strip_edges().is_empty(), "shrine offer exposes a localized direction label")
	_assert_true(run_node.call("debug_reject_room_interaction") == true, "shrine panel supports rejecting the current offer set")
	await _wait_frames(1)
	snapshot = run_node.call("debug_get_snapshot")
	_assert_true(not bool(snapshot.get("reward_panel_visible", false)), "rejecting the shrine hides the shared reward panel")
	_assert_true(not bool(snapshot.get("room_reward_claimed", false)), "rejecting the shrine keeps the room reusable")
	_assert_equal(int((snapshot.get("interactions", []) as Array).size()), 1, "rejecting the shrine keeps the interaction node active")
	shrine_state = snapshot.get("shrine_state", {})
	_assert_true(int((shrine_state.get("actions", []) as Array).size()) >= 1, "shrine snapshot records the reject action")
	_assert_true(run_node.call("debug_interact_room_feature") == true, "rejected shrine can be reopened from the same runtime interaction")
	reward_snapshot = await _wait_for_reward_panel(run_node)
	reward_choices = reward_snapshot.get("reward_choices", [])
	var selected_index := _find_offer_index_by_cost_type(reward_choices, "hp")
	if selected_index < 0:
		selected_index = _find_offer_index_by_cost_type(reward_choices, "noise")
	_assert_true(selected_index >= 0, "shrine keeps at least one payable blessing after reopening")
	snapshot = run_node.call("debug_get_snapshot")
	var hud_before: Dictionary = snapshot.get("player_hud", {})
	var hp_before := float(hud_before.get("hp", 0.0))
	var noise_before := float(hud_before.get("noise", 0.0))
	var selected_offer: Dictionary = reward_choices[selected_index] if reward_choices[selected_index] is Dictionary else {}
	var selected_cost_type := String(selected_offer.get("cost_type", "")).strip_edges().to_lower()
	var selected_cost_value := int(selected_offer.get("cost_value", 0))
	var selected_direction_id := String(selected_offer.get("shrine_direction_id", "")).strip_edges().to_lower()
	_assert_true(run_node.call("debug_select_room_reward", selected_index) == true, "shrine blessing can be claimed from the runtime interaction")
	await _wait_frames(2)
	snapshot = run_node.call("debug_get_snapshot")
	var hud_after: Dictionary = snapshot.get("player_hud", {})
	var noise_after := float((snapshot.get("player_hud", {}) as Dictionary).get("noise", 0.0))
	var hp_after := float(hud_after.get("hp", 0.0))
	match selected_cost_type:
		"noise":
			_assert_true(noise_after >= noise_before + float(selected_cost_value), "shrine noise lane applies its noise cost on accept")
		"hp":
			_assert_true(hp_after <= hp_before - float(selected_cost_value), "shrine HP lane applies its HP cost on accept")
		_:
			_fail("special-room shrine smoke selected an unexpected cost lane: %s" % selected_cost_type)
	_assert_true(snapshot.get("room_reward_claimed", false) == true, "shrine claim marks the room reward as claimed")
	_assert_equal(int((snapshot.get("interactions", []) as Array).size()), 0, "shrine interaction node is removed after blessing choice")
	shrine_state = snapshot.get("shrine_state", {})
	_assert_equal(String(shrine_state.get("accepted_direction_id", "")), selected_direction_id, "shrine snapshot records the accepted build direction")
	_assert_true(int((shrine_state.get("actions", []) as Array).size()) >= 2, "shrine snapshot records both reject and accept actions")
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


func _shop_offer_ids(items_variant: Variant) -> Array[String]:
	var ids: Array[String] = []
	if not (items_variant is Array):
		return ids
	var items: Array = items_variant
	for item_variant in items:
		if not (item_variant is Dictionary):
			continue
		var item: Dictionary = item_variant
		var offer_id := String(
			item.get("offer_id", item.get("shop_entry_id", item.get("modifier_id", item.get("id", ""))))
		).strip_edges().to_lower()
		if offer_id.is_empty():
			continue
		ids.append(offer_id)
	return ids


func _shop_offer_ids_from_state(shop_state: Dictionary) -> Array[String]:
	return _shop_offer_ids(shop_state.get("slots", []))


func _shop_slot_locked(shop_state: Dictionary, index: int) -> bool:
	var slots_variant: Variant = shop_state.get("slots", [])
	if not (slots_variant is Array):
		return false
	var slots: Array = slots_variant
	if index < 0 or index >= slots.size():
		return false
	if not (slots[index] is Dictionary):
		return false
	return bool((slots[index] as Dictionary).get("locked", false))


func _shop_state_has_rare_slot(shop_state: Dictionary) -> bool:
	var slots_variant: Variant = shop_state.get("slots", [])
	if not (slots_variant is Array):
		return false
	var slots: Array = slots_variant
	for slot_variant in slots:
		if not (slot_variant is Dictionary):
			continue
		if bool((slot_variant as Dictionary).get("rare_slot", false)):
			return true
	return false


func _shrine_direction_ids(items_variant: Variant) -> Array[String]:
	var ids: Array[String] = []
	if not (items_variant is Array):
		return ids
	var items: Array = items_variant
	for item_variant in items:
		if not (item_variant is Dictionary):
			continue
		var direction_id := String((item_variant as Dictionary).get("shrine_direction_id", "")).strip_edges().to_lower()
		if direction_id.is_empty() or ids.has(direction_id):
			continue
		ids.append(direction_id)
	return ids


func _shrine_cost_types(items_variant: Variant) -> Array[String]:
	var cost_types: Array[String] = []
	if not (items_variant is Array):
		return cost_types
	var items: Array = items_variant
	for item_variant in items:
		if not (item_variant is Dictionary):
			continue
		var cost_type := String((item_variant as Dictionary).get("cost_type", "")).strip_edges().to_lower()
		if cost_type.is_empty() or cost_types.has(cost_type):
			continue
		cost_types.append(cost_type)
	return cost_types


func _find_offer_index_by_cost_type(items_variant: Variant, cost_type: String) -> int:
	if not (items_variant is Array):
		return -1
	var normalized_cost_type := cost_type.strip_edges().to_lower()
	var items: Array = items_variant
	for item_index in range(items.size()):
		if not (items[item_index] is Dictionary):
			continue
		if String((items[item_index] as Dictionary).get("cost_type", "")).strip_edges().to_lower() == normalized_cost_type:
			return item_index
	return -1


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
