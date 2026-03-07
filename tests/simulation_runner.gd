extends Node
class_name SimulationRunner

const SUITE_ALL := "all"
const SUITE_LONG_BATTLE := "long_battle"
const SUITE_MAP_CONTRACT := "map_contract"

var failed: int = 0
var _profile_test_session_started: bool = false


func _ready() -> void:
	_setup_profile_isolation()
	_bootstrap_script_mode_singletons()
	var input_config_script: Script = load("res://scripts/core/input_config.gd")
	if input_config_script != null and input_config_script.has_method("ensure_default_actions"):
		input_config_script.ensure_default_actions()

	var suite := _resolve_suite_name()
	match suite:
		SUITE_LONG_BATTLE:
			print("SIMULATION SUITE: %s" % SUITE_LONG_BATTLE)
			await _run_long_battle_simulation_suite()
		SUITE_MAP_CONTRACT:
			print("SIMULATION SUITE: %s" % SUITE_MAP_CONTRACT)
			await _run_map_contract_simulation_suite()
		_:
			print("SIMULATION SUITE: %s" % SUITE_ALL)
			await _run_long_battle_simulation_suite()
			await _run_map_contract_simulation_suite()

	await get_tree().process_frame
	print("Tests finished. failed=%d" % failed)
	_cleanup_profile_isolation()
	get_tree().quit(failed)


func _resolve_suite_name() -> String:
	var env_suite := OS.get_environment("SIM_SUITE").strip_edges().to_lower()
	if env_suite == SUITE_LONG_BATTLE or env_suite == SUITE_MAP_CONTRACT:
		return env_suite
	var user_args: PackedStringArray = OS.get_cmdline_user_args()
	for arg in user_args:
		var token := String(arg).strip_edges().to_lower()
		if token.begins_with("--suite="):
			var value := token.trim_prefix("--suite=").strip_edges()
			if value == SUITE_LONG_BATTLE or value == SUITE_MAP_CONTRACT:
				return value
		elif token == SUITE_LONG_BATTLE or token == SUITE_MAP_CONTRACT:
			return token
	return SUITE_ALL


func _bootstrap_script_mode_singletons() -> void:
	var tree_root: Node = get_tree().root
	if tree_root.get_node_or_null("DataRegistry") == null:
		var registry_script: Script = load("res://scripts/core/data_registry.gd")
		var registry_instance: Node = registry_script.new()
		registry_instance.name = "DataRegistry"
		tree_root.add_child(registry_instance)
	if tree_root.get_node_or_null("FeedbackBus") == null:
		var feedback_script: Script = load("res://scripts/core/feedback_bus.gd")
		var feedback_instance: Node = feedback_script.new()
		feedback_instance.name = "FeedbackBus"
		tree_root.add_child(feedback_instance)
	if tree_root.get_node_or_null("TelegraphBus") == null:
		var telegraph_script: Script = load("res://scripts/core/telegraph_bus.gd")
		var telegraph_instance: Node = telegraph_script.new()
		telegraph_instance.name = "TelegraphBus"
		tree_root.add_child(telegraph_instance)


func _run_long_battle_simulation_suite() -> void:
	await _run_sustained_combat_attrition_simulation_tests()
	await _run_pickup_levelup_simulation_tests()
	await _run_live_boss_pressure_simulation_tests()


func _run_map_contract_simulation_suite() -> void:
	await _run_live_map_event_contract_combo_simulation_tests()
	await _run_contract_pressure_simulation_tests()


func _run_sustained_combat_attrition_simulation_tests() -> void:
	var game := await _create_game_root_for_test("diver", "map_trench_lab", [], 2026030706)
	_assert_true(game != null, "sim-long battle game root instantiates")
	if game == null:
		return
	var world: Variant = game.get_node_or_null("World")
	var player: Variant = game.get_node_or_null("World/Player")
	var enemy_manager: Variant = game.get_node_or_null("World/EnemyManager")
	_assert_true(world != null and player != null and enemy_manager != null, "sim-long battle world nodes exist")
	if world == null or player == null or enemy_manager == null:
		await _cleanup_game_root_for_test(game)
		return

	var max_projectiles := 0
	var max_pickups := 0
	var max_alive_enemies := 0
	for frame_idx in range(360):
		if frame_idx % 45 == 0:
			_spawn_test_enemies_around_player(enemy_manager, player.global_position, "drifter", 4, 112.0, 1.0)
		if player.has_method("_attempt_fire"):
			player.call("_attempt_fire")
		if frame_idx % 12 == 0:
			_collect_pickups_for_player(world, player)
		_auto_resolve_pending_levelup(game)
		await _await_stable_physics_frames(1)
		var entity_counts: Dictionary = world.get_runtime_entity_counts() if world.has_method("get_runtime_entity_counts") else {}
		max_projectiles = maxi(max_projectiles, int(entity_counts.get("projectiles", 0)))
		max_pickups = maxi(max_pickups, int(entity_counts.get("pickups", 0)))
		max_alive_enemies = maxi(max_alive_enemies, int(entity_counts.get("enemies", 0)))

	_collect_pickups_for_player(world, player)
	_auto_resolve_pending_levelup(game)
	await _await_stable_physics_frames(2)

	_assert_true(int(game.get("kills")) >= 12, "sim-long battle reaches 12 kills under sustained combat")
	_assert_true(int(_get_object_property(game.get("run_stats"), "pickups_collected", 0)) >= 3, "sim-long battle collects multiple pickups")
	_assert_true(int(player.get("level")) >= 2, "sim-long battle levels player through combat loop")
	_assert_true(max_projectiles > 0, "sim-long battle produces projectile traffic")
	_assert_true(max_pickups > 0, "sim-long battle spawns pickup traffic")
	_assert_true(max_alive_enemies >= 4, "sim-long battle maintains enemy pressure")
	_assert_true(String(game.get("run_state")) == String(game.get("STATE_PLAYING")), "sim-long battle remains in playing state")
	var pool_stats: Dictionary = world.get_pool_stats() if world.has_method("get_pool_stats") else {}
	_assert_true(int(pool_stats.get("total", 0)) > 0, "sim-long battle exercises shared runtime pools")
	await _cleanup_game_root_for_test(game)


func _run_pickup_levelup_simulation_tests() -> void:
	var game := await _create_game_root_for_test("diver", "map_trench_lab", [], 2026030707)
	_assert_true(game != null, "sim-long pickup game root instantiates")
	if game == null:
		return
	var world: Variant = game.get_node_or_null("World")
	var player: Variant = game.get_node_or_null("World/Player")
	_assert_true(world != null and player != null, "sim-long pickup world nodes exist")
	if world == null or player == null:
		await _cleanup_game_root_for_test(game)
		return
	var level_before := int(player.get("level"))
	var xp_amount := int(ceil(float(player.get("xp_to_next"))))
	world.spawn_xp_pickup(player.global_position + Vector2(12.0, 0.0), xp_amount)
	var reached_level_up := await _wait_until(func() -> bool:
		_collect_pickups_for_player(world, player)
		return String(game.get("run_state")) == String(game.get("STATE_LEVEL_UP"))
	, 120)
	_assert_true(reached_level_up, "sim-long pickup reaches level-up state from live pickup")
	_assert_true(get_tree().paused, "sim-long pickup pauses tree on level-up")
	_assert_true(int(_get_object_property(game.get("run_stats"), "pickups_collected", 0)) >= 1, "sim-long pickup counts collected pickup")
	_assert_equal(int(player.get("level")), level_before + 1, "sim-long pickup increments player level")
	var option_ids_variant: Variant = game.get("_level_up_option_ids")
	var option_ids: Dictionary = option_ids_variant if option_ids_variant is Dictionary else {}
	_assert_true(not option_ids.is_empty(), "sim-long pickup exposes upgrade options")
	if not option_ids.is_empty():
		game.call("_on_upgrade_selected", String(option_ids.keys()[0]))
	var resumed := await _wait_until(func() -> bool:
		return String(game.get("run_state")) == String(game.get("STATE_PLAYING"))
	, 60)
	_assert_true(resumed, "sim-long pickup resumes gameplay after selecting upgrade")
	game.call("_refresh_hud")
	await _await_stable_physics_frames(1)
	var hud_snapshot := _get_game_hud_snapshot(game)
	_assert_equal(int(hud_snapshot.get("level", 0)), level_before + 1, "sim-long pickup syncs HUD level after selection")
	await _cleanup_game_root_for_test(game)


func _run_live_boss_pressure_simulation_tests() -> void:
	var game := await _create_game_root_for_test("diver", "map_trench_lab", [], 2026030708)
	_assert_true(game != null, "sim-long boss game root instantiates")
	if game == null:
		return
	var world: Variant = game.get_node_or_null("World")
	var enemy_manager: Variant = game.get_node_or_null("World/EnemyManager")
	_assert_true(world != null and enemy_manager != null, "sim-long boss world nodes exist")
	if world == null or enemy_manager == null:
		await _cleanup_game_root_for_test(game)
		return
	var boss := await _force_spawn_boss_for_test(world)
	_assert_true(boss != null, "sim-long boss pressure spawns boss during live run")
	if boss == null:
		await _cleanup_game_root_for_test(game)
		return
	game.call("_refresh_hud")
	await _await_stable_physics_frames(1)
	var boss_hud_before := _get_game_hud_snapshot(game)
	_assert_true(bool(boss_hud_before.get("boss_active", false)), "sim-long boss marks HUD boss_active")
	_assert_true(int(world.get_active_boss_telegraph_count()) > 0, "sim-long boss creates boss telegraphs in live run")
	var phase_before := String(boss_hud_before.get("boss_phase_id", ""))
	boss.set("hp", float(boss.get("max_hp")) * 0.42)
	enemy_manager.call("_process", 0.5)
	await _await_stable_physics_frames(1)
	game.call("_refresh_hud")
	var boss_hud_after := _get_game_hud_snapshot(game)
	var phase_after := String(boss_hud_after.get("boss_phase_id", ""))
	_assert_true(not phase_after.is_empty(), "sim-long boss keeps boss phase id populated")
	_assert_true(phase_after != phase_before or phase_after.find("phase_2") >= 0, "sim-long boss advances boss phase under damage")
	_assert_true(String(game.get("run_state")) == String(game.get("STATE_PLAYING")), "sim-long boss keeps game in playing state")
	await _cleanup_game_root_for_test(game)


func _run_live_map_event_contract_combo_simulation_tests() -> void:
	var baseline_game := await _create_game_root_for_test("diver", "map_black_tide", [], 2026030709)
	_assert_true(baseline_game != null, "sim-map baseline game root instantiates")
	if baseline_game == null:
		return
	var baseline_trace := await _capture_live_map_progress(baseline_game, 120, 0.5)
	await _cleanup_game_root_for_test(baseline_game)

	var combo_contracts: Array[String] = ["contract_event_storm", "contract_black_tide_often"]
	var combo_game := await _create_game_root_for_test("diver", "map_black_tide", combo_contracts, 2026030709)
	_assert_true(combo_game != null, "sim-map combo game root instantiates")
	if combo_game == null:
		return
	var combo_trace := await _capture_live_map_progress(combo_game, 120, 0.5)
	await _cleanup_game_root_for_test(combo_game)

	_assert_true(float(baseline_trace.get("first_event_time", -1.0)) >= 0.0, "sim-map baseline triggers at least one live event")
	_assert_true(float(combo_trace.get("first_event_time", -1.0)) >= 0.0, "sim-map combo triggers at least one live event")
	_assert_true(
		int(combo_trace.get("event_trigger_count", 0)) >= int(baseline_trace.get("event_trigger_count", 0)),
		"sim-map combo preserves or increases live event trigger count (combo=%d baseline=%d)" % [
			int(combo_trace.get("event_trigger_count", 0)),
			int(baseline_trace.get("event_trigger_count", 0))
		]
	)
	_assert_true(float(combo_trace.get("first_hazard_warning_time", 999.0)) <= float(baseline_trace.get("first_hazard_warning_time", 999.0)), "sim-map combo advances first hazard warning timing")
	_assert_true(bool(combo_trace.get("hazard_active_seen", false)), "sim-map combo reaches live hazard-active state")
	_assert_true(float(combo_trace.get("contract_event_rate_mult", 1.0)) > 1.0, "sim-map combo exposes boosted contract event rate")
	var combo_active_contracts_variant: Variant = combo_trace.get("contracts_active", [])
	var combo_active_contracts: Array = combo_active_contracts_variant if combo_active_contracts_variant is Array else []
	_assert_true(combo_active_contracts.has("contract_event_storm"), "sim-map combo keeps contract_event_storm active in runtime snapshot")
	_assert_true(combo_active_contracts.has("contract_black_tide_often"), "sim-map combo keeps contract_black_tide_often active in runtime snapshot")
	_assert_equal(String(combo_trace.get("current_map_id", "")), "map_black_tide", "sim-map combo stays on requested map")


func _run_contract_pressure_simulation_tests() -> void:
	var base_game := await _create_game_root_for_test("diver", "map_trench_lab", [], 2026030710)
	_assert_true(base_game != null, "sim-contract baseline game root instantiates")
	if base_game == null:
		return
	var base_player: Variant = base_game.get_node_or_null("World/Player")
	var base_max_hp := float(base_player.get("max_hp")) if base_player != null else 0.0
	await _cleanup_game_root_for_test(base_game)

	var contracts: Array[String] = ["contract_no_dash", "contract_fragile_player"]
	var game := await _create_game_root_for_test("diver", "map_trench_lab", contracts, 2026030711)
	_assert_true(game != null, "sim-contract game root instantiates")
	if game == null:
		return
	var world: Variant = game.get_node_or_null("World")
	var player: Variant = game.get_node_or_null("World/Player")
	var enemy_manager: Variant = game.get_node_or_null("World/EnemyManager")
	_assert_true(world != null and player != null and enemy_manager != null, "sim-contract world nodes exist")
	if world == null or player == null or enemy_manager == null:
		await _cleanup_game_root_for_test(game)
		return
	_assert_true(float(player.get("max_hp")) < base_max_hp, "sim-contract run reduces player max hp")
	game.call("_refresh_hud")
	await _await_stable_physics_frames(1)
	var hud_snapshot := _get_game_hud_snapshot(game)
	_assert_true(bool(hud_snapshot.get("contract_dash_disabled", false)), "sim-contract run reports dash disabled in HUD")
	var reward_mults_variant: Variant = game.get("run_reward_multipliers")
	var reward_mults: Dictionary = reward_mults_variant if reward_mults_variant is Dictionary else {}
	_assert_true(float(reward_mults.get("xp", 1.0)) > 1.0, "sim-contract run applies reward multiplier preview")
	_spawn_test_enemies_around_player(enemy_manager, player.global_position, "drifter", 4, 96.0, 1.0)
	var earned_kill := await _wait_until(func() -> bool:
		if player != null and player.has_method("_attempt_fire"):
			player.call("_attempt_fire")
		_collect_pickups_for_player(world, player)
		_auto_resolve_pending_levelup(game)
		return int(game.get("kills")) >= 1
	, 180)
	_assert_true(earned_kill, "sim-contract run still allows combat kills under constraints")
	_assert_true(String(game.get("run_state")) == String(game.get("STATE_PLAYING")), "sim-contract run remains in playing state")
	await _cleanup_game_root_for_test(game)


func _create_game_root_for_test(
	character_id: String = "diver",
	map_id: String = "map_trench_lab",
	contract_ids: Array = [],
	seed: int = 1
) -> Node:
	var game_scene: PackedScene = load("res://scenes/game/GameRoot.tscn")
	var game_variant: Variant = game_scene.instantiate()
	if not (game_variant is Node):
		return null
	var game: Node = game_variant
	get_tree().root.add_child.call_deferred(game)
	await _await_stable_physics_frames(2)
	game.call("_start_run", character_id, map_id, contract_ids, true, seed)
	await _await_stable_physics_frames(3)
	return game


func _cleanup_game_root_for_test(game: Node) -> void:
	if game != null and is_instance_valid(game):
		game.queue_free()
	await _await_stable_physics_frames(2)
	get_tree().paused = false
	Engine.time_scale = 1.0


func _spawn_test_enemies_around_player(
	enemy_manager: Node,
	center: Vector2,
	enemy_id: String,
	count: int,
	radius: float,
	hp_override: float = -1.0
) -> Array[Node]:
	var spawned: Array[Node] = []
	if enemy_manager == null or not enemy_manager.has_method("_spawn_enemy_near"):
		return spawned
	var safe_count := maxi(1, count)
	for idx in range(safe_count):
		var angle := TAU * float(idx) / float(safe_count)
		var world_position := center + Vector2.RIGHT.rotated(angle) * radius
		var enemy_variant: Variant = enemy_manager.call("_spawn_enemy_near", enemy_id, world_position)
		if not (enemy_variant is Node):
			continue
		var enemy: Node = enemy_variant
		if enemy is Node2D:
			(enemy as Node2D).global_position = world_position
		if hp_override > 0.0:
			enemy.set("hp", hp_override)
		spawned.append(enemy)
	return spawned


func _collect_pickups_for_player(world: Node, player: Node) -> int:
	if world == null or player == null:
		return 0
	var pickup_layer := world.get_node_or_null("PickupLayer")
	if pickup_layer == null:
		return 0
	var collected := 0
	for pickup in pickup_layer.get_children():
		if pickup == null or not is_instance_valid(pickup):
			continue
		if pickup.has_method("_on_body_entered"):
			pickup.call("_on_body_entered", player)
			collected += 1
	return collected


func _auto_resolve_pending_levelup(game: Node) -> void:
	if game == null:
		return
	if String(game.get("run_state")) != String(game.get("STATE_LEVEL_UP")):
		return
	var option_ids_variant: Variant = game.get("_level_up_option_ids")
	var option_ids: Dictionary = option_ids_variant if option_ids_variant is Dictionary else {}
	if option_ids.is_empty():
		return
	game.call("_on_upgrade_selected", String(option_ids.keys()[0]))


func _capture_live_map_progress(game: Node, max_steps: int, delta: float) -> Dictionary:
	var world := game.get_node_or_null("World")
	var trace := {
		"current_map_id": "",
		"contracts_active": [],
		"contract_event_rate_mult": 1.0,
		"event_trigger_count": 0,
		"first_event_time": -1.0,
		"first_hazard_warning_time": -1.0,
		"first_hazard_active_time": -1.0,
		"hazard_active_seen": false
	}
	if world == null:
		return trace
	for _i in range(maxi(1, max_steps)):
		game.call("_process", delta)
		_auto_resolve_pending_levelup(game)
		var map_debug: Dictionary = world.get_map_debug_snapshot() if world.has_method("get_map_debug_snapshot") else {}
		var snapshot_variant: Variant = world.get("current_map_snapshot")
		var current_snapshot: Dictionary = snapshot_variant if snapshot_variant is Dictionary else {}
		trace["current_map_id"] = String(map_debug.get("current_map_id", trace.get("current_map_id", "")))
		trace["contracts_active"] = map_debug.get("contracts_active", trace.get("contracts_active", []))
		trace["contract_event_rate_mult"] = float(map_debug.get("contract_event_rate_mult", trace.get("contract_event_rate_mult", 1.0)))
		var triggered_variant: Variant = current_snapshot.get("triggered_events", [])
		if triggered_variant is Array:
			var triggered_events: Array = triggered_variant
			if not triggered_events.is_empty():
				trace["event_trigger_count"] = int(trace.get("event_trigger_count", 0)) + triggered_events.size()
				if float(trace.get("first_event_time", -1.0)) < 0.0:
					trace["first_event_time"] = float(game.get("elapsed_time"))
		var warning_active := bool(current_snapshot.get("hazard_warning_active", false))
		if warning_active and float(trace.get("first_hazard_warning_time", -1.0)) < 0.0:
			trace["first_hazard_warning_time"] = float(game.get("elapsed_time"))
		var hazard_active := bool(map_debug.get("hazard_active", false))
		if hazard_active:
			trace["hazard_active_seen"] = true
			if float(trace.get("first_hazard_active_time", -1.0)) < 0.0:
				trace["first_hazard_active_time"] = float(game.get("elapsed_time"))
		await get_tree().process_frame
	return trace


func _wait_until(predicate: Callable, max_frames: int = 120) -> bool:
	var safe_frames := maxi(1, max_frames)
	for _i in range(safe_frames):
		if predicate.call():
			return true
		await _await_stable_physics_frames(1)
	return predicate.call()


func _get_game_hud_snapshot(game: Node) -> Dictionary:
	if game == null:
		return {}
	var ui := game.get_node_or_null("UI")
	if ui == null:
		return {}
	var hud_variant: Variant = ui.get("latest_hud_data")
	return hud_variant if hud_variant is Dictionary else {}


func _get_object_property(target: Variant, property_name: String, default_value: Variant = null) -> Variant:
	if target is Object:
		return (target as Object).get(property_name)
	if target is Dictionary:
		return (target as Dictionary).get(property_name, default_value)
	return default_value


func _create_boss_test_world(seed: int) -> Node:
	var world_scene: PackedScene = load("res://scenes/world/World.tscn")
	var world = world_scene.instantiate()
	get_tree().root.add_child.call_deferred(world)
	await get_tree().process_frame
	await get_tree().process_frame
	var run_rng := RandomNumberGenerator.new()
	run_rng.seed = seed
	world.setup_run(run_rng, DataRegistry.get_character("diver"), "map_trench_lab", seed)
	await get_tree().process_frame
	await get_tree().process_frame
	return world


func _force_spawn_boss_for_test(world: Node) -> Node:
	if world == null:
		return null
	var manager: Node = world.enemy_manager
	var player: Node = world.player
	if manager == null or player == null:
		return null
	player.set_noise_value(80.0)
	manager.update_difficulty(620.0, player.noise)
	for _i in range(5):
		manager._process(0.35)
		await _await_stable_physics_frames(1)
		var boss := _find_active_boss_node(manager)
		if boss != null:
			return boss
	return _find_active_boss_node(manager)


func _find_active_boss_node(enemy_manager: Node) -> Node:
	if enemy_manager == null:
		return null
	for enemy in enemy_manager.get_children():
		if enemy == null or not is_instance_valid(enemy):
			continue
		if enemy.is_in_group("boss"):
			return enemy
	return null


func _await_stable_physics_frames(count: int = 1) -> void:
	var steps := maxi(1, count)
	for _i in range(steps):
		await get_tree().physics_frame
		await get_tree().process_frame


func _assert_true(condition: bool, label: String) -> void:
	if condition:
		print("PASS: %s" % label)
		return
	failed += 1
	push_error("FAIL: %s" % label)


func _assert_equal(actual: Variant, expected: Variant, label: String) -> void:
	_assert_true(actual == expected, "%s (actual=%s expected=%s)" % [label, actual, expected])


func _setup_profile_isolation() -> void:
	if ProfileStore == null:
		return
	if not ProfileStore.has_method("begin_test_session"):
		return
	var session_id := "simulation_runner_%d_%d" % [int(Time.get_unix_time_from_system()), int(Time.get_ticks_usec() % 1000000)]
	ProfileStore.begin_test_session(session_id, true)
	_profile_test_session_started = true
	if ProfileStore.has_method("load_profile"):
		ProfileStore.load_profile("diver", "map_trench_lab")


func _cleanup_profile_isolation() -> void:
	if not _profile_test_session_started:
		return
	if ProfileStore != null and ProfileStore.has_method("end_test_session"):
		ProfileStore.end_test_session(true)
	_profile_test_session_started = false
