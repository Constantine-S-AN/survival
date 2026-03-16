extends Node
class_name WorldSaveLoadSmokeHelper

const META_LOOP_SCENE := preload("res://scenes/meta/MetaLoopRoot.tscn")
const DEFAULT_CHARACTER_ID := "diver"
const DEFAULT_MAP_ID := "map_trench_lab"

var _host: Node = null
var meta_root: Node = null


func _init(host: Node) -> void:
	_host = host


func begin_session(prefix: String) -> bool:
	if _host == null or ProfileStore == null:
		return false
	if get_parent() == null and is_instance_valid(_host):
		_host.add_child(self)
	process_mode = Node.PROCESS_MODE_ALWAYS
	var session_id := "%s_%d" % [prefix, int(Time.get_ticks_usec() % 1000000)]
	ProfileStore.begin_test_session(session_id, true)
	ProfileStore.load_profile(DEFAULT_CHARACTER_ID, DEFAULT_MAP_ID)
	_reset_daily_orders_runtime()
	await await_frames(1)
	meta_root = await _spawn_meta_root()
	return meta_root != null


func reload_meta_root() -> Node:
	if meta_root != null:
		meta_root.queue_free()
		meta_root = null
		await await_frames(2)
	_reset_daily_orders_runtime()
	if ProfileStore != null and ProfileStore.has_method("load_profile"):
		ProfileStore.load_profile(DEFAULT_CHARACTER_ID, DEFAULT_MAP_ID)
	await await_frames(1)
	meta_root = await _spawn_meta_root()
	return meta_root


func save() -> void:
	if meta_root != null and meta_root.has_method("debug_save_meta_progress"):
		meta_root.call("debug_save_meta_progress")


func snapshot() -> Dictionary:
	if meta_root == null:
		return {}
	var snapshot_variant: Variant = meta_root.call("debug_get_snapshot")
	return snapshot_variant if snapshot_variant is Dictionary else {}


func sync_daily_orders_progress() -> void:
	if DailyOrders != null and DailyOrders.has_method("_sync_progress"):
		DailyOrders.call("_sync_progress")


func get_order_cards() -> Array:
	if DailyOrders == null or not DailyOrders.has_method("get_order_cards"):
		return []
	var cards_variant: Variant = DailyOrders.call("get_order_cards")
	return cards_variant as Array if cards_variant is Array else []


func find_order_card_by_title(title: String) -> Dictionary:
	var normalized_title := title.strip_edges().to_lower()
	for card_variant in get_order_cards():
		if not (card_variant is Dictionary):
			continue
		var card := card_variant as Dictionary
		if String(card.get("name", "")).strip_edges().to_lower() == normalized_title:
			return card.duplicate(true)
	return {}


func find_entry_by_id(items_variant: Variant, item_id: String) -> Dictionary:
	if not (items_variant is Array):
		return {}
	var normalized_id := item_id.strip_edges().to_lower()
	for item_variant in (items_variant as Array):
		if not (item_variant is Dictionary):
			continue
		var item := item_variant as Dictionary
		if String(item.get("seed_id", "")).strip_edges().to_lower() == normalized_id:
			return item.duplicate(true)
		if String(item.get("id", "")).strip_edges().to_lower() == normalized_id:
			return item.duplicate(true)
	return {}


func claim_order(order_id: int) -> Dictionary:
	if DailyOrders == null or not DailyOrders.has_method("claim_order"):
		return {"ok": false, "error": "daily_orders_unavailable"}
	var result_variant: Variant = DailyOrders.call("claim_order", order_id)
	return result_variant if result_variant is Dictionary else {"ok": false, "error": "invalid_claim_result"}


func claim_order_by_title(title: String) -> Dictionary:
	var card := find_order_card_by_title(title)
	var order_id := int(card.get("id", 0))
	if order_id <= 0:
		return {"ok": false, "error": "order_not_found"}
	return claim_order(order_id)


func open_orders_board() -> bool:
	if meta_root == null:
		return false
	if bool(snapshot().get("day_world_orders_open", false)):
		return true
	if not bool(meta_root.call("debug_day_world_attempt_interact", "orders")):
		return false
	await await_frames(1)
	return bool(snapshot().get("day_world_orders_open", false))


func close_orders_board() -> bool:
	if meta_root == null:
		return false
	if not bool(snapshot().get("day_world_orders_open", false)):
		return true
	if not bool(meta_root.call("debug_day_world_close_orders_board")):
		return false
	await await_frames(1)
	return not bool(snapshot().get("day_world_orders_open", false))


func wait_until_evening_via_world() -> bool:
	if meta_root == null:
		return false
	if String(snapshot().get("phase", "")) == "evening":
		return true
	if not bool(meta_root.call("debug_day_world_attempt_interact", "wait")):
		return false
	await await_frames(1)
	return String(snapshot().get("phase", "")) == "evening"


func open_night_departure() -> bool:
	if meta_root == null:
		return false
	if bool(snapshot().get("day_world_night_popup_open", false)):
		return true
	if not bool(meta_root.call("debug_day_world_attempt_interact", "night")):
		return false
	await await_frames(1)
	return bool(snapshot().get("day_world_night_popup_open", false))


func confirm_night_departure(request_overrides: Dictionary = {}) -> bool:
	if meta_root == null:
		return false
	if not request_overrides.is_empty():
		if not bool(meta_root.call("debug_set_next_night_request_overrides", request_overrides)):
			return false
	if not bool(meta_root.call("debug_day_world_confirm_night_departure")):
		return false
	await _host.get_tree().create_timer(0.8).timeout
	return String(snapshot().get("current_screen", "")) == "night"


func complete_night(summary_override: Dictionary = {}) -> bool:
	if meta_root == null:
		return false
	meta_root.call("debug_complete_active_night", summary_override)
	await await_frames(2)
	return String(snapshot().get("current_screen", "")) == "return_summary"


func get_night_combat_root() -> Node:
	if meta_root == null:
		return null
	return meta_root.get_node_or_null("NightCombatRoot")


func get_night_run_snapshot() -> Dictionary:
	var night_root := get_night_combat_root()
	if night_root == null or not night_root.has_method("debug_get_run_snapshot"):
		return {}
	var snapshot_variant: Variant = night_root.call("debug_get_run_snapshot")
	return snapshot_variant if snapshot_variant is Dictionary else {}


func get_night_floor_template_id() -> String:
	return String(get_night_run_snapshot().get("floor_template_id", "")).strip_edges()


func get_night_available_exits() -> Array[Dictionary]:
	var exits: Array[Dictionary] = []
	var exits_variant: Variant = get_night_run_snapshot().get("available_exits", [])
	if not (exits_variant is Array):
		return exits
	for exit_variant in (exits_variant as Array):
		if not (exit_variant is Dictionary):
			continue
		exits.append((exit_variant as Dictionary).duplicate(true))
	return exits


func resolve_extraction_room_id(preferred_room_id: String = "reef_patrol") -> String:
	var preferred_candidates: Array[String] = []
	var normalized_preferred := preferred_room_id.strip_edges()
	if not normalized_preferred.is_empty():
		preferred_candidates.append(normalized_preferred)
	var template_id := get_night_floor_template_id()
	match template_id:
		"branching_intro_channels", "branching_intro_pillars", "harbor_rift_v2_route_a":
			preferred_candidates.append("reef_patrol")
		"sunken_exchange_v2_route_b":
			preferred_candidates.append("kelp_watch")
	for candidate in preferred_candidates:
		if _night_exit_available(candidate):
			return candidate
	for exit_snapshot in get_night_available_exits():
		if String(exit_snapshot.get("target_room_type_id", "")).strip_edges().to_lower() != "combat":
			continue
		var target_room_id := String(exit_snapshot.get("target_room_id", "")).strip_edges()
		if not target_room_id.is_empty():
			return target_room_id
	for exit_snapshot in get_night_available_exits():
		var target_room_id := String(exit_snapshot.get("target_room_id", "")).strip_edges()
		if not target_room_id.is_empty():
			return target_room_id
	return ""


func wait_for_night_room(target_room_id: String = "", frame_budget: int = 180) -> Dictionary:
	var normalized_target := target_room_id.strip_edges()
	for _frame in range(maxi(1, frame_budget)):
		var run_snapshot := get_night_run_snapshot()
		var active_room_id := String(run_snapshot.get("room_id", "")).strip_edges()
		if normalized_target.is_empty():
			if not active_room_id.is_empty():
				return run_snapshot
		elif active_room_id == normalized_target:
			return run_snapshot
		await await_frames(1)
	return {}


func wait_for_night_reward_panel(frame_budget: int = 90) -> Dictionary:
	for _frame in range(maxi(1, frame_budget)):
		var run_snapshot := get_night_run_snapshot()
		if bool(run_snapshot.get("reward_panel_visible", false)):
			return run_snapshot
		await await_frames(1)
	return {}


func finish_night_run_via_extraction(route_room_id: String = "reef_patrol", reward_index: int = 0) -> bool:
	var night_root := get_night_combat_root()
	if night_root == null:
		return false
	var start_snapshot := await wait_for_night_room("camp")
	if start_snapshot.is_empty():
		return false
	var resolved_route_room_id := resolve_extraction_room_id(route_room_id)
	if resolved_route_room_id.is_empty():
		return false
	if not bool(night_root.call("debug_use_exit", resolved_route_room_id)):
		return false
	var room_snapshot := await wait_for_night_room(resolved_route_room_id)
	if room_snapshot.is_empty():
		return false
	if not bool(night_root.call("debug_force_clear_room")):
		return false
	var reward_snapshot := await wait_for_night_reward_panel()
	if reward_snapshot.is_empty():
		return false
	if not await _select_preferred_night_reward(night_root, reward_index):
		return false
	await await_frames(2)
	if not bool(night_root.call("debug_request_extract")):
		return false
	for _frame in range(90):
		if String(snapshot().get("current_screen", "")) == "return_summary":
			return true
		await await_frames(1)
	return false


func finish_night_run_via_completion(route_reward_indices: Array = [2, 0]) -> bool:
	var night_root := get_night_combat_root()
	if night_root == null:
		return false
	var start_snapshot := await wait_for_night_room("camp")
	if start_snapshot.is_empty():
		return false
	var route: Array[String] = _resolve_completion_route()
	if route.is_empty():
		return false
	var regular_reward_index: int = int(route_reward_indices[0] if not route_reward_indices.is_empty() else 0)
	var boss_reward_index: int = int(route_reward_indices[1] if route_reward_indices.size() > 1 else 0)
	for room_id in route:
		if not bool(night_root.call("debug_use_exit", room_id)):
			return false
		var room_snapshot := await wait_for_night_room(room_id)
		if room_snapshot.is_empty():
			return false
		var room_type_id := _get_floor_room_type_id(room_id)
		if room_type_id != "combat" and room_type_id != "boss":
			continue
		if not bool(night_root.call("debug_force_clear_room")):
			return false
		var reward_snapshot := await wait_for_night_reward_panel()
		if reward_snapshot.is_empty():
			return false
		var reward_index: int = boss_reward_index if room_type_id == "boss" else regular_reward_index
		if not await _select_preferred_night_reward(night_root, reward_index):
			return false
		if room_type_id != "boss":
			await await_frames(2)
	for _frame in range(120):
		if String(snapshot().get("current_screen", "")) == "return_summary":
			return true
		await await_frames(1)
	return false


func continue_summary() -> bool:
	if meta_root == null:
		return false
	if not bool(meta_root.call("debug_continue_summary")):
		return false
	await await_frames(1)
	return String(snapshot().get("current_screen", "")) == "day_hub"


func reach_evening_via_farm_loop(plot_index: int = 0, seed_id: String = "wheat_seed") -> bool:
	if meta_root == null:
		return false
	if not bool(meta_root.call("debug_day_world_select_farm_tool", "till")):
		return false
	if not bool(meta_root.call("debug_day_world_interact_farm_plot", plot_index)):
		return false
	await await_frames(1)
	if not bool(meta_root.call("debug_day_world_select_farm_tool", "plant", seed_id)):
		return false
	if not bool(meta_root.call("debug_day_world_interact_farm_plot", plot_index)):
		return false
	await await_frames(1)
	if not bool(meta_root.call("debug_day_world_select_farm_tool", "water")):
		return false
	if not bool(meta_root.call("debug_day_world_interact_farm_plot", plot_index)):
		return false
	await await_frames(1)
	return String(snapshot().get("phase", "")) == "evening"


func cleanup() -> void:
	var root_to_cleanup := meta_root
	meta_root = null
	if root_to_cleanup != null and is_instance_valid(root_to_cleanup):
		var night_root := root_to_cleanup.get_node_or_null("NightCombatRoot")
		if night_root != null and night_root.has_method("stop_session"):
			night_root.call("stop_session")
		root_to_cleanup.queue_free()
	_reset_daily_orders_runtime()
	if ProfileStore != null and ProfileStore.has_method("end_test_session"):
		ProfileStore.end_test_session(true)


func cleanup_and_quit(exit_code: int) -> void:
	if _host == null:
		return
	var tree := _host.get_tree()
	tree.paused = false
	var root_to_cleanup := meta_root
	meta_root = null
	if root_to_cleanup != null and is_instance_valid(root_to_cleanup):
		var night_root := root_to_cleanup.get_node_or_null("NightCombatRoot")
		if night_root != null and night_root.has_method("stop_session"):
			night_root.call("stop_session")
	tree.process_frame.connect(func() -> void:
		if root_to_cleanup != null and is_instance_valid(root_to_cleanup):
			root_to_cleanup.queue_free()
		tree.process_frame.connect(func() -> void:
			_reset_daily_orders_runtime()
			if ProfileStore != null and ProfileStore.has_method("end_test_session"):
				ProfileStore.end_test_session(true)
			tree.process_frame.connect(func() -> void:
				if _host == null or not is_instance_valid(_host):
					return
				_host.get_tree().quit(exit_code)
			, CONNECT_ONE_SHOT)
		, CONNECT_ONE_SHOT)
	, CONNECT_ONE_SHOT)


func await_frames(frame_count: int) -> void:
	if _host == null:
		return
	for _i in range(frame_count):
		await _host.get_tree().process_frame


func _spawn_meta_root() -> Node:
	if _host == null or META_LOOP_SCENE == null:
		return null
	var next_meta_root: Node = META_LOOP_SCENE.instantiate()
	_host.get_tree().root.add_child.call_deferred(next_meta_root)
	await await_frames(2)
	next_meta_root.call("debug_press_play")
	await await_frames(1)
	return next_meta_root


func _reset_daily_orders_runtime() -> void:
	if DailyOrders != null and DailyOrders.has_method("_reset_runtime_state"):
		DailyOrders.call("_reset_runtime_state")


func _night_exit_available(target_room_id: String) -> bool:
	var normalized_target := target_room_id.strip_edges()
	if normalized_target.is_empty():
		return false
	for exit_snapshot in get_night_available_exits():
		if String(exit_snapshot.get("target_room_id", "")).strip_edges() == normalized_target:
			return true
	return false


func _resolve_completion_route() -> Array[String]:
	var run_snapshot := get_night_run_snapshot()
	var current_room_id := String(run_snapshot.get("room_id", "")).strip_edges()
	var floor_rooms_variant: Variant = run_snapshot.get("floor_rooms", [])
	if not current_room_id.is_empty() and floor_rooms_variant is Array:
		var graph: Dictionary = {}
		var goal_room_id := ""
		for room_variant in (floor_rooms_variant as Array):
			if not (room_variant is Dictionary):
				continue
			var room: Dictionary = room_variant
			var room_id := String(room.get("id", "")).strip_edges()
			if room_id.is_empty():
				continue
			graph[room_id] = _normalize_string_id_array(room.get("connections", []))
			if String(room.get("room_type_id", "")).strip_edges().to_lower() == "boss" and goal_room_id.is_empty():
				goal_room_id = room_id
		if graph.has(current_room_id) and graph.has(goal_room_id):
			var discovered: Dictionary = {current_room_id: true}
			var previous: Dictionary = {}
			var queue: Array[String] = [current_room_id]
			var cursor := 0
			while cursor < queue.size():
				var room_id := queue[cursor]
				cursor += 1
				if room_id == goal_room_id:
					break
				for next_room_id in graph.get(room_id, []):
					if discovered.has(next_room_id):
						continue
					discovered[next_room_id] = true
					previous[next_room_id] = room_id
					queue.append(next_room_id)
			if discovered.has(goal_room_id):
				var reverse_path: Array[String] = [goal_room_id]
				while reverse_path.back() != current_room_id:
					var previous_room_id := String(previous.get(reverse_path.back(), "")).strip_edges()
					if previous_room_id.is_empty():
						reverse_path.clear()
						break
					reverse_path.append(previous_room_id)
				if not reverse_path.is_empty():
					reverse_path.reverse()
					if reverse_path.front() == current_room_id:
						reverse_path.remove_at(0)
					return reverse_path
	var template_id := get_night_floor_template_id()
	match template_id:
		"branching_intro_channels", "branching_intro_pillars":
			return ["swarm_nest", "quiet_niche", "omen_shrine", "apex_guardian"]
		"harbor_rift_v2_route_a":
			return ["reef_patrol", "relay_beacon", "pressure_lock", "apex_guardian"]
		"sunken_exchange_v2_route_b":
			return ["kelp_watch", "signal_jetty", "customs_gate", "apex_guardian"]
	return []


func _get_floor_room_type_id(room_id: String) -> String:
	var normalized_room_id := room_id.strip_edges()
	if normalized_room_id.is_empty():
		return ""
	var floor_rooms_variant: Variant = get_night_run_snapshot().get("floor_rooms", [])
	if not (floor_rooms_variant is Array):
		return ""
	for room_variant in (floor_rooms_variant as Array):
		if not (room_variant is Dictionary):
			continue
		var room := room_variant as Dictionary
		if String(room.get("id", "")).strip_edges() != normalized_room_id:
			continue
		return String(room.get("room_type_id", "")).strip_edges().to_lower()
	return ""


func _select_preferred_night_reward(night_root: Node, preferred_index: int = 0) -> bool:
	if night_root == null:
		return false
	var reward_choices_variant: Variant = get_night_run_snapshot().get("reward_choices", [])
	var reward_choices: Array = reward_choices_variant if reward_choices_variant is Array else []
	var candidate_indices: Array[int] = []
	if preferred_index >= 0:
		candidate_indices.append(preferred_index)
	for choice_index in range(reward_choices.size()):
		if candidate_indices.has(choice_index):
			continue
		candidate_indices.append(choice_index)
	if candidate_indices.is_empty():
		candidate_indices.append(maxi(0, preferred_index))
	for choice_index in candidate_indices:
		if bool(night_root.call("debug_select_room_reward", choice_index)):
			await await_frames(1)
			return true
	return false


func _normalize_string_id_array(value: Variant) -> Array[String]:
	var output: Array[String] = []
	if not (value is Array):
		return output
	for item_variant in (value as Array):
		var item := String(item_variant).strip_edges()
		if item.is_empty() or output.has(item):
			continue
		output.append(item)
	return output
