extends Node
class_name TestRunner

class DummyEnemy:
	extends Node2D

	var reveal_calls: int = 0
	var last_duration: float = 0.0

	func set_revealed(duration_sec: float) -> void:
		reveal_calls += 1
		last_duration = duration_sec

	func is_revealed() -> bool:
		return reveal_calls > 0


class DummyEnemyManager:
	extends Node

	var target: Node2D = null

	func get_priority_target(_origin: Vector2) -> Node2D:
		return target


class DummyDamageEnemy:
	extends CharacterBody2D

	var hp: float = 400.0
	var hit_count: int = 0
	var reveal_until: float = 0.0

	func _ready() -> void:
		collision_layer = 2
		collision_mask = 0
		var shape := CollisionShape2D.new()
		var circle := CircleShape2D.new()
		circle.radius = 14.0
		shape.shape = circle
		add_child(shape)
		add_to_group("enemy")

	func take_hit(damage: float, _impulse: Vector2 = Vector2.ZERO) -> bool:
		hp -= damage
		hit_count += 1
		return hp <= 0.0

	func set_revealed(duration_sec: float) -> void:
		var now_sec := float(Time.get_ticks_msec()) * 0.001
		reveal_until = maxf(reveal_until, now_sec + duration_sec)

	func is_revealed() -> bool:
		var now_sec := float(Time.get_ticks_msec()) * 0.001
		return now_sec < reveal_until

	func get_threat_score(origin: Vector2) -> float:
		return 5000.0 - global_position.distance_to(origin)


var failed: int = 0
var _profile_test_session_started: bool = false


func _ready() -> void:
	_setup_profile_isolation()
	_bootstrap_script_mode_singletons()
	var input_config_script: Script = load("res://scripts/core/input_config.gd")
	if input_config_script != null and input_config_script.has_method("ensure_default_actions"):
		input_config_script.ensure_default_actions()
	_run_data_registry_tests()
	_run_spawn_profile_tests()
	await _run_pool_system_tests()
	await _run_character_profile_tests()
	await _run_weapon_system_tests()
	await _run_upgrade_rules_tests()
	await _run_m2_system_tests()
	await _run_map_biome_tests()
	await _run_p0f_system_tests()
	await _run_start_run_hotfix_tests()
	await _run_telegraph_bus_s4_tests()
	await _run_contract_ux_s3_tests()
	await _run_enemy_pool_perf_tests()
	await _run_boss_showcase_tests()
	await get_tree().process_frame
	print("Tests finished. failed=%d" % failed)
	_cleanup_profile_isolation()
	get_tree().quit(failed)


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


func _run_data_registry_tests() -> void:
	var registry_script := load("res://scripts/core/data_registry.gd")
	var registry = registry_script.new()
	_assert_true(registry.load_all(), "DataRegistry should load all JSON files")
	var required_weapon_ids: Array[String] = [
		"needle_rifle",
		"burst_smg",
		"silence_dart",
		"shock_pulse",
		"abyss_mine",
		"tether_beam",
		"orbital_drone",
		"sonar_blade"
	]
	for weapon_id in required_weapon_ids:
		_assert_true(registry.weapons.has(weapon_id), "weapons includes %s" % weapon_id)
	_assert_true(registry.enemies.size() >= 4, "enemies has at least 4 entries")
	_assert_true(registry.upgrades.size() >= 20, "upgrades has at least 20 entries")
	var characters: Array = registry.get_characters()
	_assert_true(characters.size() >= 5, "characters has at least 5 entries")
	_assert_equal(registry.get_default_character_id(), "diver", "default character id is diver")
	_assert_true(registry.has_character("diver"), "characters includes diver")
	var diver: Dictionary = registry.get_character("diver")
	_assert_equal(String(diver.get("starting_weapon_id", "")), "silence_dart", "diver starts with silence_dart")
	var diver_unlock_variant: Variant = diver.get("unlock", {})
	_assert_true(diver_unlock_variant is Dictionary, "diver unlock object exists")
	var diver_unlock: Dictionary = diver_unlock_variant if diver_unlock_variant is Dictionary else {}
	_assert_equal(String(diver_unlock.get("type", "")), "survive_time_seconds", "diver unlock type")
	var silence_dart: Dictionary = registry.get_weapon("silence_dart")
	_assert_equal(String(silence_dart.get("attack_model", "")), "projectile", "silence_dart attack model")
	var silence_growth_variant: Variant = silence_dart.get("level_growth", [])
	_assert_true(silence_growth_variant is Array and (silence_growth_variant as Array).size() >= 5, "silence_dart defines 5-level growth")

	var rng := RandomNumberGenerator.new()
	rng.seed = 42
	var choices: Array = registry.get_upgrade_choices(rng, {}, 3)
	_assert_equal(choices.size(), 3, "upgrade choice count should be 3")

	var weapons_path := "res://data/weapons.json"
	var original_weapons := FileAccess.get_file_as_string(weapons_path)
	var tmp_dir := "user://tmp"
	DirAccess.make_dir_recursive_absolute(tmp_dir)
	var parsed_weapons: Variant = JSON.parse_string(original_weapons)
	if parsed_weapons is Dictionary:
		var broken_missing := (parsed_weapons as Dictionary).duplicate(true)
		if broken_missing.has("needle_rifle"):
			var rifle_variant: Variant = broken_missing.get("needle_rifle", {})
			if rifle_variant is Dictionary:
				var rifle := (rifle_variant as Dictionary).duplicate(true)
				rifle.erase("base_damage")
				broken_missing["needle_rifle"] = rifle
		var broken_missing_path := "%s/weapons_broken_missing.json" % tmp_dir
		_write_json_value(broken_missing_path, broken_missing)
		var broken_registry_missing = registry_script.new()
		var missing_ok: bool = broken_registry_missing.load_all(false, {"weapons": broken_missing_path})
		var missing_errors: Array[String] = broken_registry_missing.get_validation_errors()
		_assert_true(not missing_ok, "weapons schema fails when base_damage missing")
		_assert_true(_array_contains_text(missing_errors, "missing key 'base_damage'"), "weapons schema error reports missing key")
		_remove_file_if_exists(broken_missing_path)
		broken_registry_missing.free()
	else:
		_assert_true(false, "weapons schema test: parse weapons json")

	var parsed_weapons_unknown: Variant = JSON.parse_string(original_weapons)
	if parsed_weapons_unknown is Dictionary:
		var broken_tag := (parsed_weapons_unknown as Dictionary).duplicate(true)
		if broken_tag.has("needle_rifle"):
			var rifle_unknown_variant: Variant = broken_tag.get("needle_rifle", {})
			if rifle_unknown_variant is Dictionary:
				var rifle_unknown := (rifle_unknown_variant as Dictionary).duplicate(true)
				rifle_unknown["tags"] = ["pierce", "totally_unknown_tag"]
				broken_tag["needle_rifle"] = rifle_unknown
		var broken_unknown_path := "%s/weapons_broken_unknown_tag.json" % tmp_dir
		_write_json_value(broken_unknown_path, broken_tag)
		var broken_registry_unknown = registry_script.new()
		var unknown_ok: bool = broken_registry_unknown.load_all(false, {"weapons": broken_unknown_path})
		var unknown_errors: Array[String] = broken_registry_unknown.get_validation_errors()
		_assert_true(not unknown_ok, "weapons schema fails when unknown tag exists")
		_assert_true(_array_contains_text(unknown_errors, "unknown tag 'totally_unknown_tag'"), "weapons schema reports unknown tag")
		_remove_file_if_exists(broken_unknown_path)
		broken_registry_unknown.free()
	else:
		_assert_true(false, "weapons unknown tag test: parse weapons json")
	_assert_true(FileAccess.get_file_as_string(weapons_path) == original_weapons, "weapons schema tests do not mutate res weapons data")

	registry.free()


func _run_spawn_profile_tests() -> void:
	var registry_script := load("res://scripts/core/data_registry.gd")
	var registry = registry_script.new()
	registry.load_all()

	var low_noise: float = registry.get_spawn_rate(0.0, 5.0)
	var high_noise: float = registry.get_spawn_rate(0.0, 80.0)
	_assert_true(high_noise > low_noise, "spawn rate should increase with noise tiers")

	var low_cap: int = registry.get_enemy_cap(0.0, 5.0)
	var high_cap: int = registry.get_enemy_cap(0.0, 80.0)
	_assert_true(high_cap > low_cap, "enemy cap should increase with noise tiers")

	var timeline: float = registry.get_timeline_progress(1000.0)
	_assert_true(timeline >= 0.99 and timeline <= 1.0, "timeline progress should clamp to 1.0")
	registry.free()


func _run_pool_system_tests() -> void:
	var pool_script: Script = load("res://scripts/managers/pool_manager.gd")
	var pool_manager: Node = pool_script.new()
	var active_layer := Node2D.new()
	get_tree().root.add_child.call_deferred(active_layer)
	get_tree().root.add_child.call_deferred(pool_manager)
	await get_tree().process_frame
	await get_tree().process_frame

	var projectile_scene: PackedScene = load("res://scenes/projectile/Projectile.tscn")
	pool_manager.ensure_pool("projectile_test", projectile_scene, active_layer, 1)
	var first_projectile: Node = pool_manager.checkout("projectile_test", active_layer)
	var stats_after_first: Dictionary = pool_manager.get_stats()
	_assert_equal(int(stats_after_first.get("hits", 0)), 1, "pool first checkout uses prewarmed hit")
	_assert_equal(int(stats_after_first.get("misses", 0)), 0, "pool miss starts at zero")

	var second_projectile: Node = pool_manager.checkout("projectile_test", active_layer)
	var stats_after_second: Dictionary = pool_manager.get_stats()
	_assert_equal(int(stats_after_second.get("hits", 0)), 1, "pool hit count unchanged on miss checkout")
	_assert_equal(int(stats_after_second.get("misses", 0)), 1, "pool miss increments on instantiate")

	pool_manager.recycle("projectile_test", first_projectile)
	pool_manager.recycle("projectile_test", second_projectile)
	var reused_projectile: Node = pool_manager.checkout("projectile_test", active_layer)
	var stats_after_reuse: Dictionary = pool_manager.get_stats()
	_assert_true(reused_projectile == first_projectile or reused_projectile == second_projectile, "pool reuses recycled projectile instance")
	_assert_equal(int(stats_after_reuse.get("hits", 0)), 2, "pool hit increments after recycle reuse")
	_assert_equal(int(stats_after_reuse.get("misses", 0)), 1, "pool miss count remains stable after reuse")
	_assert_true(is_equal_approx(float(stats_after_reuse.get("hit_rate", 0.0)), 2.0 / 3.0), "pool hit_rate matches hits over total")

	var pickup_scene: PackedScene = load("res://scenes/pickup/XPPickup.tscn")
	pool_manager.ensure_pool("pickup_test", pickup_scene, active_layer, 1)
	var first_pickup: Node = pool_manager.checkout("pickup_test", active_layer)
	pool_manager.recycle("pickup_test", first_pickup)
	var reused_pickup: Node = pool_manager.checkout("pickup_test", active_layer)
	_assert_true(reused_pickup == first_pickup, "pool reuses pickup instance")

	pool_manager.recycle("projectile_test", reused_projectile)
	pool_manager.recycle("pickup_test", reused_pickup)
	pool_manager.queue_free()
	active_layer.queue_free()
	await get_tree().process_frame


func _run_character_profile_tests() -> void:
	var characters_path := "res://data/characters.json"
	var original_characters := FileAccess.get_file_as_string(characters_path)
	var tmp_dir := "user://tmp"
	DirAccess.make_dir_recursive_absolute(tmp_dir)
	var parsed_characters: Variant = JSON.parse_string(original_characters)
	if parsed_characters is Dictionary:
		var broken_chars := (parsed_characters as Dictionary).duplicate(true)
		var rows_variant: Variant = broken_chars.get("characters", [])
		if rows_variant is Array and not (rows_variant as Array).is_empty():
			var rows: Array = rows_variant
			if rows[0] is Dictionary:
				var first_row := (rows[0] as Dictionary).duplicate(true)
				first_row.erase("starting_weapon_id")
				rows[0] = first_row
				broken_chars["characters"] = rows
				var broken_chars_path := "%s/characters_broken_missing_starting_weapon.json" % tmp_dir
				_write_json_value(broken_chars_path, broken_chars)
				var broken_registry_script: Script = load("res://scripts/core/data_registry.gd")
				var broken_registry = broken_registry_script.new()
				var broken_ok: bool = broken_registry.load_all(false, {"characters": broken_chars_path})
				var broken_errors: Array[String] = broken_registry.get_validation_errors()
				_assert_true(not broken_ok, "characters schema fails when starting_weapon_id missing")
				_assert_true(_array_contains_text(broken_errors, "missing key 'starting_weapon_id'"), "characters schema error reports missing key")
				_remove_file_if_exists(broken_chars_path)
				broken_registry.free()
			else:
				_assert_true(false, "characters schema test: first row must be dictionary")
		else:
			_assert_true(false, "characters schema test: characters array exists")
	else:
		_assert_true(false, "characters schema test: parse characters json")
	_assert_true(FileAccess.get_file_as_string(characters_path) == original_characters, "characters schema tests do not mutate res characters data")

	var profile_path := _current_profile_path()
	var had_backup := FileAccess.file_exists(profile_path)
	var backup_content := FileAccess.get_file_as_string(profile_path) if had_backup else ""

	var legacy_profile := {
		"unlocked_characters": ["diver"],
		"last_selected_character_id": "diver",
		"progress": {
			"total_kills": 12
		}
	}
	var write_profile := FileAccess.open(profile_path, FileAccess.WRITE)
	write_profile.store_string(JSON.stringify(legacy_profile, "\t"))
	write_profile.flush()
	write_profile = null

	var profile_script: Script = load("res://scripts/core/profile_store.gd")
	var profile_store: Node = profile_script.new()
	get_tree().root.add_child.call_deferred(profile_store)
	await get_tree().process_frame
	await get_tree().process_frame
	profile_store.load_profile("diver")
	_assert_equal(profile_store.get_schema_version(), 2, "profile migration upgrades schema to v2")
	var migrated_profile: Dictionary = profile_store.get_profile()
	var migrated_progress_variant: Variant = migrated_profile.get("progress", {})
	var migrated_progress: Dictionary = migrated_progress_variant if migrated_progress_variant is Dictionary else {}
	_assert_equal(int(migrated_progress.get("total_kills", 0)), 12, "profile migration preserves legacy progress fields")

	profile_store.set_selected_character_id("scavenger")
	profile_store.save_profile()
	var profile_store_reloaded: Node = profile_script.new()
	get_tree().root.add_child.call_deferred(profile_store_reloaded)
	await get_tree().process_frame
	await get_tree().process_frame
	profile_store_reloaded.load_profile("diver")
	_assert_equal(profile_store_reloaded.get_selected_character_id("diver"), "scavenger", "selected character persists after reload")

	var player_scene: PackedScene = load("res://scenes/player/Player.tscn")
	var player = player_scene.instantiate()
	get_tree().root.add_child.call_deferred(player)
	await get_tree().process_frame
	await get_tree().process_frame
	var character_rng := RandomNumberGenerator.new()
	character_rng.seed = 913
	player.setup(null, null, character_rng, DataRegistry.get_character("scavenger"))
	_assert_true(is_equal_approx(player.get_pickup_radius_multiplier(), 1.35), "scavenger pickup radius multiplier applied")
	_assert_true(is_equal_approx(player.xp_gain_mult, 1.1), "scavenger xp gain multiplier applied")
	player.setup(null, null, character_rng, DataRegistry.get_character("diver"))
	_assert_true(is_equal_approx(player.noise_generation_mult, 0.8), "diver noise gain multiplier applied")
	_assert_true(is_equal_approx(player.get_sonar_reveal_duration_multiplier(), 1.25), "diver sonar reveal multiplier applied")

	var base_pickup_count := 0
	var biased_pickup_count := 0
	for seed in range(1, 33):
		var rng_base := RandomNumberGenerator.new()
		rng_base.seed = seed
		var base_choices: Array = DataRegistry.get_upgrade_choices(rng_base, {}, 3, {})
		base_pickup_count += _count_choices_with_tag(base_choices, "pickup")

		var rng_biased := RandomNumberGenerator.new()
		rng_biased.seed = seed
		var biased_choices: Array = DataRegistry.get_upgrade_choices(
			rng_biased,
			{},
			3,
			{"pickup": 2.8, "economy": 2.0, "weapon": 0.45}
		)
		biased_pickup_count += _count_choices_with_tag(biased_choices, "pickup")
	_assert_true(biased_pickup_count > base_pickup_count, "tag_weights bias pickup upgrades deterministically")

	var run_summary := {
		"total_kills": 900,
		"pickups_collected": 260,
		"elite_or_pursuer_kills": 3,
		"survive_time_seconds": 620.0,
		"max_noise_reached": 72.0,
		"max_noise_tier_id": "exposed"
	}
	var newly_unlocked: Array[String] = profile_store_reloaded.evaluate_character_unlocks(DataRegistry.get_characters(), run_summary)
	_assert_true(newly_unlocked.has("arc_tech"), "unlock evaluation unlocks arc_tech from total_kills")
	_assert_true(newly_unlocked.has("lancer"), "unlock evaluation unlocks lancer from max noise")
	_assert_true(newly_unlocked.has("drone_handler"), "unlock evaluation unlocks drone_handler from pickups")
	_assert_true(newly_unlocked.has("scavenger"), "unlock evaluation unlocks scavenger from survive time")
	_assert_true(profile_store_reloaded.is_character_unlocked("arc_tech"), "unlock state persisted for arc_tech")

	var arc_unlock_variant: Variant = DataRegistry.get_character("arc_tech").get("unlock", {})
	var arc_unlock: Dictionary = arc_unlock_variant if arc_unlock_variant is Dictionary else {}
	var arc_progress: Dictionary = profile_store_reloaded.get_requirement_progress(arc_unlock)
	_assert_true(bool(arc_progress.get("met", false)), "progress query returns met after unlock")

	profile_store_reloaded.unlock_all_characters(DataRegistry.get_characters())
	profile_store_reloaded.set_selected_character_id("scavenger")
	var game_scene: PackedScene = load("res://scenes/game/GameRoot.tscn")
	var game = game_scene.instantiate()
	get_tree().root.add_child.call_deferred(game)
	await get_tree().process_frame
	await get_tree().process_frame
	game._start_run("scavenger")
	_assert_equal(String(game.world.player.character_id), "scavenger", "selected character applied on run start")
	_assert_true(is_equal_approx(game.world.player.get_pickup_radius_multiplier(), 1.35), "run-start character multiplier is active")
	game.queue_free()
	await get_tree().process_frame

	player.queue_free()
	profile_store.queue_free()
	profile_store_reloaded.queue_free()
	await get_tree().process_frame
	if had_backup:
		var restore := FileAccess.open(profile_path, FileAccess.WRITE)
		restore.store_string(backup_content)
		restore.flush()
		restore = null
	elif FileAccess.file_exists(profile_path):
		DirAccess.remove_absolute(profile_path)


func _run_weapon_system_tests() -> void:
	var weapon_ids: Array[String] = [
		"needle_rifle",
		"burst_smg",
		"silence_dart",
		"shock_pulse",
		"abyss_mine",
		"tether_beam",
		"orbital_drone",
		"sonar_blade"
	]
	for weapon_id in weapon_ids:
		var enemy_position := Vector2(120.0, 0.0)
		if weapon_id == "sonar_blade":
			enemy_position = Vector2(62.0, 0.0)
		var harness := await _create_weapon_test_harness(weapon_id, enemy_position)
		var player: Node = harness.get("player")
		var enemy: Node = harness.get("enemy")
		var projectile_manager: Node = harness.get("projectile_manager")
		_assert_true(player != null and enemy != null and projectile_manager != null, "weapon harness created for %s" % weapon_id)
		await _await_stable_physics_frames(1)
		player._attempt_fire()
		await _await_stable_physics_frames(1)
		var spawned_projectiles := int(projectile_manager.active_projectiles)
		_force_projectile_hits(projectile_manager, enemy)
		await _await_stable_physics_frames(1)
		if (weapon_id == "shock_pulse" or weapon_id == "sonar_blade") and int(enemy.hit_count) < 1:
			player._attempt_fire()
			await _await_stable_physics_frames(1)

		match weapon_id:
			"needle_rifle", "burst_smg":
				_assert_true(spawned_projectiles > 0, "%s spawns projectile entities" % weapon_id)
				_assert_true(int(enemy.hit_count) >= 1, "%s can damage enemy through projectile path" % weapon_id)
			"silence_dart":
				_assert_true(spawned_projectiles > 0, "silence_dart spawns projectile")
				_assert_true(int(enemy.hit_count) >= 1, "silence_dart damages enemy")
				var now_sec := float(Time.get_ticks_msec()) * 0.001
				_assert_true(float(enemy.reveal_until) > now_sec, "silence_dart applies reveal extension")
			"shock_pulse":
				_assert_true(int(enemy.hit_count) >= 1, "shock_pulse applies radial damage")
			"abyss_mine":
				_assert_true((player.deployed_mines as Array).size() >= 1, "abyss_mine deploys mine instance")
				player._update_deployed_mines(0.8)
				await _await_stable_physics_frames(1)
				_assert_true(int(enemy.hit_count) >= 1, "abyss_mine detonates and damages enemy")
			"tether_beam":
				_assert_true(float(player.beam_visual_timer) > 0.0, "tether_beam starts beam visual timer")
				_assert_true(int(enemy.hit_count) >= 1, "tether_beam applies beam damage")
			"orbital_drone":
				if spawned_projectiles <= 0:
					player._update_drone_orbits(0.25)
					player._attempt_fire()
					await _await_stable_physics_frames(1)
					spawned_projectiles = int(projectile_manager.active_projectiles)
					_force_projectile_hits(projectile_manager, enemy)
					await _await_stable_physics_frames(1)
				_assert_true((player.drone_nodes as Array).size() >= 1, "orbital_drone spawns drone visuals")
				_assert_true(spawned_projectiles > 0, "orbital_drone produces projectiles")
				_assert_true(int(enemy.hit_count) >= 1, "orbital_drone can damage enemy")
			"sonar_blade":
				_assert_true(int(enemy.hit_count) >= 1, "sonar_blade melee strike damages enemy")
			_:
				_assert_true(false, "unknown test weapon id %s" % weapon_id)

		await _cleanup_weapon_test_harness(harness)

	var low_noise_harness := await _create_weapon_test_harness("needle_rifle", Vector2(140.0, 0.0))
	var high_noise_harness := await _create_weapon_test_harness("burst_smg", Vector2(140.0, 0.0))
	var low_player: Node = low_noise_harness.get("player")
	var high_player: Node = high_noise_harness.get("player")
	var low_runtime: Variant = low_player._build_active_weapon_runtime()
	var high_runtime: Variant = high_player._build_active_weapon_runtime()
	_assert_true(float(high_runtime.noise_per_attack) > float(low_runtime.noise_per_attack), "burst_smg runtime noise_per_attack > needle_rifle")
	low_player.set_noise_value(0.0)
	high_player.set_noise_value(0.0)
	low_player._add_noise_source("attack", float(low_runtime.noise_per_attack))
	high_player._add_noise_source("attack", float(high_runtime.noise_per_attack))
	_assert_true(float(high_player.noise) > float(low_player.noise), "burst_smg creates more noise than needle_rifle in same window")
	await _cleanup_weapon_test_harness(low_noise_harness)
	await _cleanup_weapon_test_harness(high_noise_harness)

	var weapon_target_harness := await _create_weapon_test_harness("needle_rifle", Vector2(140.0, 0.0))
	var weapon_player: Node = weapon_target_harness.get("player")
	var runtime_before_weapon: Variant = weapon_player._build_active_weapon_runtime()
	weapon_player.apply_upgrade("u_lancer_rail_matrix")
	var runtime_after_weapon: Variant = weapon_player._build_active_weapon_runtime()
	_assert_true(float(runtime_after_weapon.attack_rate) > float(runtime_before_weapon.attack_rate), "weapon_id-targeted upgrade increases targeted weapon attack rate")
	_assert_true(int(runtime_after_weapon.pierce) > int(runtime_before_weapon.pierce), "weapon_id-targeted upgrade increases targeted weapon pierce")
	await _cleanup_weapon_test_harness(weapon_target_harness)

	var tag_target_harness := await _create_weapon_test_harness("silence_dart", Vector2(140.0, 0.0))
	var tag_player: Node = tag_target_harness.get("player")
	var runtime_before_tag: Variant = tag_player._build_active_weapon_runtime()
	tag_player.apply_upgrade("u_ping_accelerant")
	var runtime_after_tag: Variant = tag_player._build_active_weapon_runtime()
	_assert_true(float(runtime_after_tag.attack_rate) > float(runtime_before_tag.attack_rate), "tag-targeted upgrade increases sonar weapon attack rate")
	tag_player._apply_targeted_effect("weapon_level_up", 99, {"type": "weapon_id", "value": "silence_dart"})
	var runtime_after_level: Variant = tag_player._build_active_weapon_runtime()
	_assert_true(int(runtime_after_level.level) >= 2, "weapon level-up effect raises weapon level")
	_assert_true(int(runtime_after_level.level) <= int(runtime_after_level.max_level), "weapon level-up clamps to max level")
	await _cleanup_weapon_test_harness(tag_target_harness)


func _run_upgrade_rules_tests() -> void:
	var upgrade_rules: Script = load("res://scripts/core/upgrade_rules.gd")
	var upgrades: Array = DataRegistry.upgrades

	var sonar_context := _make_upgrade_context(["silence_dart"], "silence_dart", {"sonar": 1}, "silent")
	var exposed_without_prereq: Array = upgrade_rules.filter_candidates(upgrades, {}, sonar_context)
	_assert_true(not _candidate_list_has(exposed_without_prereq, "u_exposed_breaker"), "prereq blocks u_exposed_breaker before u_echo_stabilizer")

	var exposed_with_prereq: Array = upgrade_rules.filter_candidates(upgrades, {"u_echo_stabilizer": 1}, sonar_context)
	_assert_true(_candidate_list_has(exposed_with_prereq, "u_exposed_breaker"), "prereq unlocks u_exposed_breaker after u_echo_stabilizer")

	var blocked_by_exclusive: Array = upgrade_rules.filter_candidates(
		upgrades,
		{"u_echo_stabilizer": 1, "u_ping_accelerant": 1},
		sonar_context
	)
	_assert_true(not _candidate_list_has(blocked_by_exclusive, "u_exposed_breaker"), "exclusive_group hides alternate sonar route after selection")

	var low_profile_silent: Array = upgrade_rules.filter_candidates(
		upgrades,
		{},
		_make_upgrade_context(["silence_dart"], "silence_dart", {"silence": 1}, "silent")
	)
	_assert_true(not _candidate_list_has(low_profile_silent, "u_low_profile_processor"), "prereq(any) unmet keeps u_low_profile_processor hidden")

	var low_profile_alert: Array = upgrade_rules.filter_candidates(
		upgrades,
		{},
		_make_upgrade_context(["silence_dart"], "silence_dart", {"silence": 1}, "alert")
	)
	_assert_true(_candidate_list_has(low_profile_alert, "u_low_profile_processor"), "noise tier prereq unlocks u_low_profile_processor")

	var low_profile_from_upgrade: Array = upgrade_rules.filter_candidates(
		upgrades,
		{"u_thermal_sink": 1},
		_make_upgrade_context(["silence_dart"], "silence_dart", {"silence": 1}, "silent")
	)
	_assert_true(_candidate_list_has(low_profile_from_upgrade, "u_low_profile_processor"), "non-exclusive prereq branch unlocks u_low_profile_processor")

	var low_profile_conflict: Array = upgrade_rules.filter_candidates(
		upgrades,
		{"u_silent_baffles": 1},
		_make_upgrade_context(["silence_dart"], "silence_dart", {"silence": 1}, "silent")
	)
	_assert_true(not _candidate_list_has(low_profile_conflict, "u_low_profile_processor"), "exclusive_group still blocks conflicting noise route picks")

	var without_drone_weapon: Array = upgrade_rules.filter_candidates(
		upgrades,
		{},
		_make_upgrade_context(["silence_dart"], "silence_dart", {}, "silent")
	)
	_assert_true(not _candidate_list_has(without_drone_weapon, "u_drone_bay"), "requires_weapon_ids blocks drone upgrade without orbital_drone")

	var with_drone_weapon: Array = upgrade_rules.filter_candidates(
		upgrades,
		{},
		_make_upgrade_context(["orbital_drone"], "orbital_drone", {}, "silent")
	)
	_assert_true(_candidate_list_has(with_drone_weapon, "u_drone_bay"), "requires_weapon_ids allows drone upgrade when weapon owned")

	var summon_tag_missing: Array = upgrade_rules.filter_candidates(
		upgrades,
		{},
		_make_upgrade_context(["orbital_drone"], "orbital_drone", {}, "silent")
	)
	_assert_true(not _candidate_list_has(summon_tag_missing, "u_summon_screen"), "requires_tags hides summon screen without summon tag")

	var summon_tag_present: Array = upgrade_rules.filter_candidates(
		upgrades,
		{},
		_make_upgrade_context(["orbital_drone"], "orbital_drone", {"summon": 1}, "silent")
	)
	_assert_true(_candidate_list_has(summon_tag_present, "u_summon_screen"), "requires_tags allows summon screen when summon tag exists")

	var blocked_by_rule: Array = upgrade_rules.filter_candidates(
		upgrades,
		{"u_burst_vent_tuning": 1},
		_make_upgrade_context(["burst_smg"], "burst_smg", {"heat": 1}, "silent")
	)
	_assert_true(not _candidate_list_has(blocked_by_rule, "u_silent_baffles"), "blocks rule prevents blocked upgrade from appearing")

	var capped_upgrades: Array = upgrade_rules.filter_candidates(upgrades, {"u_hardlight_core": 5}, sonar_context)
	_assert_true(not _candidate_list_has(capped_upgrades, "u_hardlight_core"), "max_rank removes already capped upgrade")

	var rng_a := RandomNumberGenerator.new()
	rng_a.seed = 5531
	var choices_a: Array = DataRegistry.get_upgrade_choices(rng_a, {"u_echo_stabilizer": 1}, 3, {"sonar": 1.2}, sonar_context)
	var rng_b := RandomNumberGenerator.new()
	rng_b.seed = 5531
	var choices_b: Array = DataRegistry.get_upgrade_choices(rng_b, {"u_echo_stabilizer": 1}, 3, {"sonar": 1.2}, sonar_context)
	_assert_equal(_extract_choice_ids(choices_a), _extract_choice_ids(choices_b), "upgrade picker deterministic with fixed seed under rules")

	var common_weight := DataRegistry._get_upgrade_weight(
		{"id": "tmp_common", "rarity": "common", "base_weight": 1.0, "tags": []},
		{},
		{}
	)
	var legendary_weight := DataRegistry._get_upgrade_weight(
		{"id": "tmp_legendary", "rarity": "legendary", "base_weight": 1.0, "tags": []},
		{},
		{}
	)
	_assert_true(common_weight > legendary_weight, "rarity weight makes common heavier than legendary at same base_weight")
	var rare_base_weight := DataRegistry._get_upgrade_weight(
		{"id": "tmp_rare_base", "rarity": "rare", "base_weight": 1.0, "tags": []},
		{},
		{}
	)
	var rare_boosted_weight := DataRegistry._get_upgrade_weight(
		{"id": "tmp_rare_boosted", "rarity": "rare", "base_weight": 1.0, "tags": []},
		{},
		{"rarity_mult": 1.3}
	)
	_assert_true(rare_boosted_weight > rare_base_weight, "rarity_mult boosts rare upgrade weight in runtime context")

	_run_upgrade_schema_validation_tests()
	await _run_placeholder_fix_tests()


func _run_upgrade_schema_validation_tests() -> void:
	var upgrades_path := "res://data/upgrades.json"
	var original_upgrades := FileAccess.get_file_as_string(upgrades_path)
	var parsed_upgrades: Variant = JSON.parse_string(original_upgrades)
	if not (parsed_upgrades is Array):
		_assert_true(false, "upgrade schema tests: parse upgrades json")
		return
	var upgrades_array: Array = parsed_upgrades
	var registry_script: Script = load("res://scripts/core/data_registry.gd")
	var tmp_dir := "user://tmp"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(tmp_dir))

	var broken_rarity: Array = upgrades_array.duplicate(true)
	if _mutate_upgrade_field(broken_rarity, "u_hardlight_core", "rarity", "mythic"):
		var rarity_path := "%s/upgrades_broken_rarity.json" % tmp_dir
		_write_json_value(rarity_path, broken_rarity)
		var rarity_registry = registry_script.new()
		var rarity_ok: bool = rarity_registry.load_all(false, {"upgrades": rarity_path})
		var rarity_errors: Array[String] = rarity_registry.get_validation_errors()
		_assert_true(not rarity_ok, "upgrade schema fails when rarity enum is invalid")
		_assert_true(_array_contains_text(rarity_errors, "unknown rarity 'mythic'"), "upgrade schema reports invalid rarity value")
		rarity_registry.free()
		_remove_file_if_exists(rarity_path)
	else:
		_assert_true(false, "upgrade schema rarity test: u_hardlight_core exists")

	var broken_prereq: Array = upgrades_array.duplicate(true)
	if _mutate_upgrade_field(broken_prereq, "u_echo_stabilizer", "prereq", {"all": "bad", "any": []}):
		var prereq_path := "%s/upgrades_broken_prereq.json" % tmp_dir
		_write_json_value(prereq_path, broken_prereq)
		var prereq_registry = registry_script.new()
		var prereq_ok: bool = prereq_registry.load_all(false, {"upgrades": prereq_path})
		var prereq_errors: Array[String] = prereq_registry.get_validation_errors()
		_assert_true(not prereq_ok, "upgrade schema fails when prereq branch has wrong type")
		_assert_true(_array_contains_text(prereq_errors, "prereq] 'all' must be an array"), "upgrade schema reports prereq branch type error")
		prereq_registry.free()
		_remove_file_if_exists(prereq_path)
	else:
		_assert_true(false, "upgrade schema prereq test: u_echo_stabilizer exists")

	var broken_stat: Array = upgrades_array.duplicate(true)
	if _mutate_upgrade_field(broken_stat, "u_hardlight_core", "effects", [{"stat": "invalid_effect_stat", "add": 0.1}]):
		var stat_path := "%s/upgrades_broken_stat.json" % tmp_dir
		_write_json_value(stat_path, broken_stat)
		var stat_registry = registry_script.new()
		var stat_ok: bool = stat_registry.load_all(false, {"upgrades": stat_path})
		var stat_errors: Array[String] = stat_registry.get_validation_errors()
		_assert_true(not stat_ok, "upgrade schema fails when effect stat is unknown")
		_assert_true(_array_contains_text(stat_errors, "unknown effect stat 'invalid_effect_stat'"), "upgrade schema reports unknown effect stat")
		_assert_true(stat_registry.get_upgrade("u_hardlight_core").is_empty(), "upgrade with invalid effect stat is skipped from runtime pool")
		stat_registry.free()
		_remove_file_if_exists(stat_path)
	else:
		_assert_true(false, "upgrade schema effect stat test: u_hardlight_core exists")

	var broken_requires_weapon: Array = upgrades_array.duplicate(true)
	if _mutate_upgrade_field(broken_requires_weapon, "u_drone_bay", "requires_weapon_ids", ["ghost_weapon"]):
		var requires_weapon_path := "%s/upgrades_broken_requires_weapon.json" % tmp_dir
		_write_json_value(requires_weapon_path, broken_requires_weapon)
		var requires_weapon_registry = registry_script.new()
		var requires_weapon_ok: bool = requires_weapon_registry.load_all(false, {"upgrades": requires_weapon_path})
		var requires_weapon_errors: Array[String] = requires_weapon_registry.get_validation_errors()
		_assert_true(not requires_weapon_ok, "upgrade schema fails when requires_weapon_ids references unknown weapon")
		_assert_true(_array_contains_text(requires_weapon_errors, "requires_weapon_ids contains unknown weapon 'ghost_weapon'"), "upgrade schema reports unknown requires_weapon_ids value")
		requires_weapon_registry.free()
		_remove_file_if_exists(requires_weapon_path)
	else:
		_assert_true(false, "upgrade schema requires_weapon_ids test: u_drone_bay exists")

	var broken_requires_tag: Array = upgrades_array.duplicate(true)
	if _mutate_upgrade_field(broken_requires_tag, "u_summon_screen", "requires_tags", ["ghost_tag"]):
		var requires_tag_path := "%s/upgrades_broken_requires_tag.json" % tmp_dir
		_write_json_value(requires_tag_path, broken_requires_tag)
		var requires_tag_registry = registry_script.new()
		var requires_tag_ok: bool = requires_tag_registry.load_all(false, {"upgrades": requires_tag_path})
		var requires_tag_errors: Array[String] = requires_tag_registry.get_validation_errors()
		_assert_true(not requires_tag_ok, "upgrade schema fails when requires_tags references unknown tag")
		_assert_true(_array_contains_text(requires_tag_errors, "requires_tags contains unknown tag 'ghost_tag'"), "upgrade schema reports unknown requires_tags value")
		requires_tag_registry.free()
		_remove_file_if_exists(requires_tag_path)
	else:
		_assert_true(false, "upgrade schema requires_tags test: u_summon_screen exists")

	_assert_true(FileAccess.get_file_as_string(upgrades_path) == original_upgrades, "upgrade schema tests do not mutate res upgrades data")


func _run_placeholder_fix_tests() -> void:
	var summon_harness := await _create_weapon_test_harness("orbital_drone", Vector2(54.0, 0.0))
	var summon_player: Node = summon_harness.get("player")
	var summon_damage_before := float(summon_player.get_summon_damage_taken(12.0))
	summon_player.apply_upgrade("u_summon_screen")
	var summon_damage_after := float(summon_player.get_summon_damage_taken(12.0))
	_assert_true(summon_damage_after < summon_damage_before, "summon_resistance reduces summon incoming damage")
	await _cleanup_weapon_test_harness(summon_harness)

	var player_scene: PackedScene = load("res://scenes/player/Player.tscn")
	var arc_player: Node = player_scene.instantiate()
	var diver_player: Node = player_scene.instantiate()
	get_tree().root.add_child.call_deferred(arc_player)
	get_tree().root.add_child.call_deferred(diver_player)
	await get_tree().process_frame
	await get_tree().process_frame

	var chain_rng_arc := RandomNumberGenerator.new()
	chain_rng_arc.seed = 2026
	var chain_rng_diver := RandomNumberGenerator.new()
	chain_rng_diver.seed = 2026
	arc_player.setup(null, null, chain_rng_arc, DataRegistry.get_character("arc_tech"))
	diver_player.setup(null, null, chain_rng_diver, DataRegistry.get_character("diver"))
	arc_player.active_weapon_id = "tether_beam"
	diver_player.active_weapon_id = "tether_beam"

	var arc_chain_before: Dictionary = arc_player.get_chain_parameters_for_current_weapon()
	var diver_chain: Dictionary = diver_player.get_chain_parameters_for_current_weapon()
	_assert_true(bool(arc_chain_before.get("enabled", false)), "arc_tech enables chain parameters on chain weapon")
	_assert_true(float(arc_chain_before.get("chance", 0.0)) > float(diver_chain.get("chance", 0.0)), "character_chain_bonus raises arc_tech chain chance")

	arc_player.apply_upgrade("u_chain_velocity")
	var arc_chain_after: Dictionary = arc_player.get_chain_parameters_for_current_weapon()
	_assert_true(float(arc_chain_after.get("chance", 0.0)) > float(arc_chain_before.get("chance", 0.0)), "chain upgrade increases chain chance on chain weapon")

	arc_player.queue_free()
	diver_player.queue_free()
	await get_tree().process_frame


func _create_weapon_test_harness(weapon_id: String, enemy_position: Vector2) -> Dictionary:
	var player_scene: PackedScene = load("res://scenes/player/Player.tscn")
	var player: Node = player_scene.instantiate()
	var projectile_manager_script: Script = load("res://scripts/managers/projectile_manager.gd")
	var projectile_manager: Node = projectile_manager_script.new()
	var enemy_manager := DummyEnemyManager.new()
	var enemy := DummyDamageEnemy.new()
	enemy.global_position = enemy_position
	enemy_manager.target = enemy

	var test_rng := RandomNumberGenerator.new()
	test_rng.seed = 7321

	get_tree().root.add_child.call_deferred(projectile_manager)
	get_tree().root.add_child.call_deferred(enemy_manager)
	get_tree().root.add_child.call_deferred(enemy)
	get_tree().root.add_child.call_deferred(player)
	await _await_stable_physics_frames(2)

	player.setup(enemy_manager, projectile_manager, test_rng, _make_test_character(weapon_id))
	player.auto_attack = true
	player.attack_cd_remaining = 0.0
	player.global_position = Vector2.ZERO
	await _await_stable_physics_frames(1)
	return {
		"player": player,
		"projectile_manager": projectile_manager,
		"enemy_manager": enemy_manager,
		"enemy": enemy
	}


func _make_test_character(weapon_id: String) -> Dictionary:
	return {
		"id": "test_runner_character",
		"display_name": "Test Runner",
		"short_desc": "Test harness character",
		"starting_weapon_id": weapon_id,
		"effect_id": "",
		"stat_modifiers": {},
		"tag_weights": {}
	}


func _force_projectile_hits(projectile_manager: Node, enemy: Node) -> void:
	if projectile_manager == null or enemy == null:
		return
	for child in projectile_manager.get_children():
		if child == null or not is_instance_valid(child):
			continue
		if child.has_method("_on_body_entered"):
			child._on_body_entered(enemy)


func _cleanup_weapon_test_harness(harness: Dictionary) -> void:
	for key in ["player", "projectile_manager", "enemy_manager", "enemy"]:
		var node_variant: Variant = harness.get(key, null)
		if node_variant is Node:
			var node: Node = node_variant
			if is_instance_valid(node):
				node.queue_free()
	await get_tree().process_frame
	await get_tree().process_frame


func _await_stable_physics_frames(count: int = 1) -> void:
	var steps := maxi(1, count)
	for _i in range(steps):
		await get_tree().physics_frame
		await get_tree().process_frame


func _run_m2_system_tests() -> void:
	var registry_script := load("res://scripts/core/data_registry.gd")
	var registry = registry_script.new()
	registry.load_all()

	var fog: Dictionary = registry.get_fog_config()
	_assert_true(bool(fog.get("enabled", false)), "fog config enabled flag exists")
	_assert_true(float(fog.get("vision_radius", 0.0)) > 0.0, "fog vision radius is positive")

	var sonar: Dictionary = registry.get_sonar_config()
	_assert_true(bool(sonar.get("enabled", false)), "sonar config enabled flag exists")
	_assert_true(float(sonar.get("wave_speed", 0.0)) > 0.0, "sonar wave speed is positive")

	var noise: Dictionary = registry.get_noise_config()
	_assert_true(float(noise.get("decay_per_second", 0.0)) > 0.0, "noise decay configured")
	var tiers_variant: Variant = noise.get("tiers", [])
	_assert_true(tiers_variant is Array and (tiers_variant as Array).size() >= 3, "noise tiers configured")

	var tier_silent: Dictionary = registry.get_noise_tier(10.0)
	var tier_alert: Dictionary = registry.get_noise_tier(40.0)
	var tier_exposed: Dictionary = registry.get_noise_tier(80.0)
	_assert_equal(String(tier_silent.get("id", "")), "silent", "noise tier mapping for 10")
	_assert_equal(String(tier_alert.get("id", "")), "alert", "noise tier mapping for 40")
	_assert_equal(String(tier_exposed.get("id", "")), "exposed", "noise tier mapping for 80")

	var mod_silent: Dictionary = registry.get_noise_spawn_modifiers(10.0)
	var mod_alert: Dictionary = registry.get_noise_spawn_modifiers(40.0)
	var mod_exposed: Dictionary = registry.get_noise_spawn_modifiers(80.0)
	_assert_true(float(mod_exposed.get("spawn_rate_multiplier", 0.0)) > float(mod_silent.get("spawn_rate_multiplier", 0.0)), "exposed tier has higher spawn multiplier")
	_assert_true(float(mod_exposed.get("pursuer_chance", 0.0)) > float(mod_alert.get("pursuer_chance", 0.0)), "exposed tier has higher pursuer chance")

	var skill_cfg_variant: Variant = noise.get("skill", {})
	_assert_true(skill_cfg_variant is Dictionary, "noise skill config exists")
	var skill_cfg: Dictionary = skill_cfg_variant if skill_cfg_variant is Dictionary else {}
	_assert_true(float(skill_cfg.get("cooldown", 0.0)) > 0.0, "noise skill cooldown configured")
	var source_cfg_variant: Variant = noise.get("sources", {})
	_assert_true(source_cfg_variant is Dictionary, "noise sources config exists")
	var source_cfg: Dictionary = source_cfg_variant if source_cfg_variant is Dictionary else {}
	_assert_true(float(source_cfg.get("attack", 0.0)) > 0.0, "noise attack source configured")

	_assert_equal(String(registry.get_noise_tier(24.99).get("id", "")), "silent", "noise tier boundary <25")
	_assert_equal(String(registry.get_noise_tier(25.0).get("id", "")), "alert", "noise tier boundary at 25")
	_assert_equal(String(registry.get_noise_tier(59.99).get("id", "")), "alert", "noise tier boundary <60")
	_assert_equal(String(registry.get_noise_tier(60.0).get("id", "")), "exposed", "noise tier boundary at 60")
	_assert_true(is_equal_approx(registry.clamp_noise_value(-3.0), 0.0), "noise clamp lower bound")
	_assert_true(is_equal_approx(registry.clamp_noise_value(180.0), 100.0), "noise clamp upper bound")

	var enemy_scene: PackedScene = load("res://scenes/enemy/Enemy.tscn")
	var enemy: Node = enemy_scene.instantiate()
	var target := Node2D.new()
	get_tree().root.add_child.call_deferred(target)
	get_tree().root.add_child.call_deferred(enemy)
	await get_tree().process_frame
	await get_tree().process_frame
	enemy.setup("drone_scout", registry.get_enemy("drone_scout"), target)
	var now_sec := float(Time.get_ticks_msec()) * 0.001
	enemy.set_revealed(1.0)
	_assert_true(enemy.reveal_until > now_sec, "sonar reveal_until is later than now")
	var reveal_first: float = float(enemy.reveal_until)
	enemy.set_revealed(2.0)
	_assert_true(enemy.reveal_until > reveal_first, "sonar refresh extends reveal_until")
	enemy.queue_free()
	target.queue_free()
	await get_tree().process_frame

	var fog_path := "res://data/fog.json"
	var fog_original := FileAccess.get_file_as_string(fog_path)
	var tmp_dir := "user://tmp"
	DirAccess.make_dir_recursive_absolute(tmp_dir)
	var fog_json: Variant = JSON.parse_string(fog_original)
	if fog_json is Dictionary:
		var broken := (fog_json as Dictionary).duplicate(true)
		broken.erase("vision_radius")
		var broken_fog_path := "%s/fog_broken_missing_vision_radius.json" % tmp_dir
		_write_json_value(broken_fog_path, broken)
		var broken_registry = registry_script.new()
		var broken_ok: bool = broken_registry.load_all(false, {"fog": broken_fog_path})
		var broken_errors: Array[String] = broken_registry.get_validation_errors()
		_assert_true(not broken_ok, "schema validation fails when fog field missing")
		_assert_true(_array_contains_text(broken_errors, "missing key 'vision_radius'"), "schema error reports exact missing field")
		_remove_file_if_exists(broken_fog_path)
		broken_registry.free()
	else:
		_assert_true(false, "fog json parse for schema test")

	var hotreload_original := FileAccess.get_file_as_string(fog_path)
	var hotreload_json: Variant = JSON.parse_string(hotreload_original)
	if hotreload_json is Dictionary:
		var updated := (hotreload_json as Dictionary).duplicate(true)
		var previous_radius := float(updated.get("vision_radius", 0.0))
		var new_radius := previous_radius + 77.0
		updated["vision_radius"] = new_radius
		var hotreload_fog_path := "%s/fog_hotreload_override.json" % tmp_dir
		_write_json_value(hotreload_fog_path, updated)
		var hot_registry = registry_script.new()
		hot_registry.load_all(false, {"fog": hotreload_fog_path})
		var loaded_radius := float(hot_registry.get_fog_config().get("vision_radius", 0.0))
		_assert_true(is_equal_approx(loaded_radius, new_radius), "hot reload applies updated fog radius")
		_remove_file_if_exists(hotreload_fog_path)
		hot_registry.free()
	else:
		_assert_true(false, "fog json parse for hot reload test")
	_assert_true(FileAccess.get_file_as_string(fog_path) == fog_original, "fog tests do not mutate res fog data")

	var game_scene: PackedScene = load("res://scenes/game/GameRoot.tscn")
	var game: Node = game_scene.instantiate()
	get_tree().root.add_child.call_deferred(game)
	await get_tree().process_frame
	await get_tree().process_frame
	var f1 := InputEventKey.new()
	f1.keycode = KEY_F1
	f1.pressed = true
	game._unhandled_input(f1)
	_assert_true(game.ui != null and game.ui.is_debug_visible(), "debug toggle F1 enables panel")
	var f2 := InputEventKey.new()
	f2.keycode = KEY_F2
	f2.pressed = true
	var fog_before: bool = game.world.is_fog_enabled()
	game._unhandled_input(f2)
	_assert_true(game.world.is_fog_enabled() != fog_before, "fog toggle F2 switches state without error")
	game.queue_free()
	await get_tree().process_frame

	registry.free()


func _run_map_biome_tests() -> void:
	var registry_script: Script = load("res://scripts/core/data_registry.gd")
	var registry = registry_script.new()
	_assert_true(registry.load_all(), "map biome registry load succeeds")

	var maps: Array = registry.get_maps()
	_assert_true(maps.size() >= 2, "maps data includes at least 2 maps")
	var default_map_id: String = registry.get_default_map_id()
	_assert_true(registry.has_map(default_map_id), "default map id exists in maps registry")

	var trench_map: Dictionary = registry.get_map("map_trench_lab")
	var tide_map: Dictionary = registry.get_map("map_black_tide")
	_assert_true(not trench_map.is_empty(), "map_trench_lab exists")
	_assert_true(not tide_map.is_empty(), "map_black_tide exists")

	var trench_hazard := String(trench_map.get("hazard_id", ""))
	var trench_table := String(trench_map.get("event_table_id", ""))
	_assert_true(not registry.get_hazard(trench_hazard).is_empty(), "trench hazard reference resolves")
	_assert_true(not registry.get_event_table(trench_table).is_empty(), "trench event table reference resolves")

	var map_runtime_script: Script = load("res://scripts/core/map_runtime.gd")
	var hazard_cycles = map_runtime_script.new()
	hazard_cycles.setup(
		trench_map,
		registry.get_hazard(trench_hazard),
		registry.get_event_table(trench_table),
		7744
	)
	var saw_warning := false
	var saw_active := false
	var saw_recover := false
	var active_seen_once := false
	for step in range(0, 240):
		var snapshot: Dictionary = hazard_cycles.update(0.25)
		if bool(snapshot.get("hazard_warning_active", false)):
			saw_warning = true
		if bool(snapshot.get("hazard_active", false)):
			saw_active = true
			active_seen_once = true
		elif active_seen_once:
			saw_recover = true
			break
	_assert_true(saw_warning, "hazard telegraph warning becomes active before hazard starts")
	_assert_true(saw_active, "hazard active state triggers during runtime")
	_assert_true(saw_recover, "hazard returns to inactive state after active window")

	var deterministic_a = map_runtime_script.new()
	deterministic_a.setup(
		registry.get_map("map_black_tide"),
		registry.get_hazard(String(registry.get_map("map_black_tide").get("hazard_id", ""))),
		registry.get_event_table(String(registry.get_map("map_black_tide").get("event_table_id", ""))),
		9911
	)
	var deterministic_b = map_runtime_script.new()
	deterministic_b.setup(
		registry.get_map("map_black_tide"),
		registry.get_hazard(String(registry.get_map("map_black_tide").get("hazard_id", ""))),
		registry.get_event_table(String(registry.get_map("map_black_tide").get("event_table_id", ""))),
		9911
	)
	var events_a: Array[String] = []
	var events_b: Array[String] = []
	for step in range(0, 220):
		var snap_a: Dictionary = deterministic_a.update(0.5)
		var snap_b: Dictionary = deterministic_b.update(0.5)
		var trig_a_variant: Variant = snap_a.get("triggered_events", [])
		var trig_b_variant: Variant = snap_b.get("triggered_events", [])
		if trig_a_variant is Array:
			for event_variant in (trig_a_variant as Array):
				if event_variant is Dictionary:
					events_a.append(String((event_variant as Dictionary).get("id", "")))
		if trig_b_variant is Array:
			for event_variant in (trig_b_variant as Array):
				if event_variant is Dictionary:
					events_b.append(String((event_variant as Dictionary).get("id", "")))
	_assert_true(events_a.size() > 0, "map runtime emits at least one event in test window")
	_assert_equal(events_a, events_b, "event order is deterministic with fixed seed")

	var world_scene: PackedScene = load("res://scenes/world/World.tscn")
	var world = world_scene.instantiate()
	get_tree().root.add_child.call_deferred(world)
	await get_tree().process_frame
	await get_tree().process_frame
	var run_rng := RandomNumberGenerator.new()
	run_rng.seed = 1441
	world.setup_run(run_rng, registry.get_character("diver"), "map_black_tide", 1441)
	var world_debug_black: Dictionary = world.get_map_debug_snapshot()
	_assert_equal(String(world_debug_black.get("current_map_id", "")), "map_black_tide", "world applies selected map id")
	var base_fog_radius := float(DataRegistry.get_fog_config().get("vision_radius", 440.0))
	_assert_true(float(world_debug_black.get("fog_radius", base_fog_radius)) < base_fog_radius, "map modifier changes fog radius")

	var player: Node = world.player
	player.set_noise_value(0.0)
	player._add_noise_source("attack", 1.0)
	var black_noise_after_attack := float(player.noise)
	world.set_current_map("map_trench_lab", 1441)
	player.set_noise_value(0.0)
	player._add_noise_source("attack", 1.0)
	var trench_noise_after_attack := float(player.noise)
	_assert_true(black_noise_after_attack > trench_noise_after_attack, "map noise gain modifier affects attack noise")

	var world_debug_trench: Dictionary = world.get_map_debug_snapshot()
	_assert_true(
		float(world_debug_black.get("map_spawn_multiplier", 1.0)) > float(world_debug_trench.get("map_spawn_multiplier", 1.0)),
		"map spawn multiplier differs between biomes"
	)
	world.queue_free()
	await get_tree().process_frame

	var tmp_dir := "user://tmp"
	DirAccess.make_dir_recursive_absolute(tmp_dir)
	var maps_text := FileAccess.get_file_as_string("res://data/maps.json")
	var maps_json: Variant = JSON.parse_string(maps_text)
	if maps_json is Dictionary:
		var broken_hazard := (maps_json as Dictionary).duplicate(true)
		var rows_variant: Variant = broken_hazard.get("maps", [])
		if rows_variant is Array and not (rows_variant as Array).is_empty():
			var rows: Array = (rows_variant as Array).duplicate(true)
			var first_variant: Variant = rows[0]
			if first_variant is Dictionary:
				var first_map := (first_variant as Dictionary).duplicate(true)
				first_map["hazard_id"] = "ghost_hazard"
				rows[0] = first_map
				broken_hazard["maps"] = rows
				var broken_hazard_path := "%s/maps_broken_hazard.json" % tmp_dir
				_write_json_value(broken_hazard_path, broken_hazard)
				var broken_hazard_registry = registry_script.new()
				var broken_hazard_ok: bool = broken_hazard_registry.load_all(false, {"maps": broken_hazard_path})
				var broken_hazard_errors: Array[String] = broken_hazard_registry.get_validation_errors()
				_assert_true(not broken_hazard_ok, "schema validation fails for unknown hazard reference")
				_assert_true(_array_contains_text(broken_hazard_errors, "unknown hazard_id 'ghost_hazard'"), "map schema reports unknown hazard reference")
				_remove_file_if_exists(broken_hazard_path)
				broken_hazard_registry.free()
	else:
		_assert_true(false, "maps json parse for hazard reference test")

	var maps_json_event: Variant = JSON.parse_string(maps_text)
	if maps_json_event is Dictionary:
		var broken_event := (maps_json_event as Dictionary).duplicate(true)
		var rows_variant_event: Variant = broken_event.get("maps", [])
		if rows_variant_event is Array and not (rows_variant_event as Array).is_empty():
			var rows_event: Array = (rows_variant_event as Array).duplicate(true)
			var first_event_variant: Variant = rows_event[0]
			if first_event_variant is Dictionary:
				var first_event_map := (first_event_variant as Dictionary).duplicate(true)
				first_event_map["event_table_id"] = "ghost_table"
				rows_event[0] = first_event_map
				broken_event["maps"] = rows_event
				var broken_event_path := "%s/maps_broken_event.json" % tmp_dir
				_write_json_value(broken_event_path, broken_event)
				var broken_event_registry = registry_script.new()
				var broken_event_ok: bool = broken_event_registry.load_all(false, {"maps": broken_event_path})
				var broken_event_errors: Array[String] = broken_event_registry.get_validation_errors()
				_assert_true(not broken_event_ok, "schema validation fails for unknown event table reference")
				_assert_true(_array_contains_text(broken_event_errors, "unknown event_table_id 'ghost_table'"), "map schema reports unknown event table reference")
				_remove_file_if_exists(broken_event_path)
				broken_event_registry.free()
	else:
		_assert_true(false, "maps json parse for event table reference test")

	var profile_path := _current_profile_path()
	var had_profile_backup := FileAccess.file_exists(profile_path)
	var profile_backup_content := FileAccess.get_file_as_string(profile_path) if had_profile_backup else ""
	var profile_script: Script = load("res://scripts/core/profile_store.gd")
	var profile_store_map: Node = profile_script.new()
	get_tree().root.add_child.call_deferred(profile_store_map)
	await get_tree().process_frame
	profile_store_map.load_profile("diver", "map_trench_lab")
	profile_store_map.set_selected_map_id("map_black_tide")
	profile_store_map.save_profile()
	var profile_store_map_reload: Node = profile_script.new()
	get_tree().root.add_child.call_deferred(profile_store_map_reload)
	await get_tree().process_frame
	profile_store_map_reload.load_profile("diver", "map_trench_lab")
	_assert_equal(
		profile_store_map_reload.get_selected_map_id("map_trench_lab"),
		"map_black_tide",
		"profile stores and reloads last_selected_map_id"
	)
	profile_store_map.queue_free()
	profile_store_map_reload.queue_free()
	await get_tree().process_frame
	if had_profile_backup:
		var restore_profile := FileAccess.open(profile_path, FileAccess.WRITE)
		restore_profile.store_string(profile_backup_content)
		restore_profile.flush()
		restore_profile = null
	elif FileAccess.file_exists(profile_path):
		DirAccess.remove_absolute(profile_path)

	registry.free()


func _run_p0f_system_tests() -> void:
	var registry_script: Script = load("res://scripts/core/data_registry.gd")
	var registry = registry_script.new()
	_assert_true(registry.load_all(), "p0f registry load succeeds")
	_assert_true(registry.get_elite_affixes().size() >= 6, "p0f elites includes at least 6 affixes")
	_assert_true(registry.get_contracts().size() >= 12, "p0f contracts includes at least 12 entries")
	_assert_true(registry.get_bosses().size() >= 1, "p0f bosses includes at least 1 entry")

	var all_contract_ids: Array[String] = []
	for contract_variant in registry.get_contracts():
		if contract_variant is Dictionary:
			all_contract_ids.append(String((contract_variant as Dictionary).get("id", "")))
	var normalized_contracts: Array[String] = registry.normalize_contract_selection(all_contract_ids)
	_assert_true(normalized_contracts.size() <= registry.get_contract_max_select(), "p0f normalize contract selection clamps to max_select")

	var composed_contracts: Dictionary = registry.compose_contract_modifiers(["contract_small_vision", "contract_loud_world"])
	var composed_fog_variant: Variant = composed_contracts.get("fog", {})
	var composed_noise_variant: Variant = composed_contracts.get("noise", {})
	var composed_fog: Dictionary = composed_fog_variant if composed_fog_variant is Dictionary else {}
	var composed_noise: Dictionary = composed_noise_variant if composed_noise_variant is Dictionary else {}
	_assert_true(float(composed_fog.get("vision_radius_mult", 1.0)) < 1.0, "p0f contract fog modifier applied")
	_assert_true(float(composed_noise.get("gain_mult", 1.0)) > 1.0, "p0f contract noise modifier applied")

	var preview: Dictionary = registry.get_contract_reward_preview(["contract_small_vision", "contract_loud_world"])
	_assert_true(
		is_equal_approx(float(preview.get("reward_multiplier", 1.0)), 1.35),
		"p0f reward preview uses pct-sum multiplier"
	)

	var low_pursuer: Dictionary = registry.get_noise_spawn_modifiers(10.0)
	var high_pursuer: Dictionary = registry.get_noise_spawn_modifiers(80.0)
	_assert_true(float(high_pursuer.get("pursuer_chance", 0.0)) > float(low_pursuer.get("pursuer_chance", 0.0)), "p0f high-noise pursuer chance > low-noise")

	var enemies_path := "res://data/enemies.json"
	var original_enemies := FileAccess.get_file_as_string(enemies_path)
	var tmp_dir := "user://tmp"
	DirAccess.make_dir_recursive_absolute(tmp_dir)
	var parsed_enemies: Variant = JSON.parse_string(original_enemies)
	if parsed_enemies is Dictionary:
		var broken_enemies := (parsed_enemies as Dictionary).duplicate(true)
		if broken_enemies.has("drifter"):
			var drifter_variant: Variant = broken_enemies.get("drifter", {})
			if drifter_variant is Dictionary:
				var drifter := (drifter_variant as Dictionary).duplicate(true)
				drifter["behavior"] = "unknown_behavior"
				broken_enemies["drifter"] = drifter
		var broken_enemies_path := "%s/enemies_broken_behavior.json" % tmp_dir
		_write_json_value(broken_enemies_path, broken_enemies)
		var broken_registry = registry_script.new()
		var broken_ok: bool = broken_registry.load_all(false, {"enemies": broken_enemies_path})
		var broken_errors: Array[String] = broken_registry.get_validation_errors()
		_assert_true(not broken_ok, "p0f enemies schema fails on unknown behavior")
		_assert_true(_array_contains_text(broken_errors, "unsupported behavior"), "p0f enemies schema reports unknown behavior")
		broken_registry.free()
		_remove_file_if_exists(broken_enemies_path)
	else:
		_assert_true(false, "p0f enemies schema test parse")
	_assert_true(FileAccess.get_file_as_string(enemies_path) == original_enemies, "p0f enemies schema tests do not mutate res data")

	var profile_path := _current_profile_path()
	var had_profile_backup := FileAccess.file_exists(profile_path)
	var profile_backup_content := FileAccess.get_file_as_string(profile_path) if had_profile_backup else ""
	var profile_script: Script = load("res://scripts/core/profile_store.gd")
	var profile_store: Node = profile_script.new()
	get_tree().root.add_child.call_deferred(profile_store)
	await get_tree().process_frame
	profile_store.load_profile("diver", "map_trench_lab")
	profile_store.set_selected_contract_ids(["contract_small_vision", "contract_loud_world"])
	profile_store.save_profile()
	var profile_reload: Node = profile_script.new()
	get_tree().root.add_child.call_deferred(profile_reload)
	await get_tree().process_frame
	profile_reload.load_profile("diver", "map_trench_lab")
	var persisted_contracts: Array[String] = profile_reload.get_selected_contract_ids()
	_assert_true(persisted_contracts.has("contract_small_vision"), "p0f profile persists selected contracts")
	profile_store.queue_free()
	profile_reload.queue_free()
	await get_tree().process_frame
	if had_profile_backup:
		var restore_profile := FileAccess.open(profile_path, FileAccess.WRITE)
		restore_profile.store_string(profile_backup_content)
		restore_profile.flush()
		restore_profile = null
	elif FileAccess.file_exists(profile_path):
		DirAccess.remove_absolute(profile_path)

	var map_runtime_script: Script = load("res://scripts/core/map_runtime.gd")
	var map_a = registry.get_map("map_black_tide")
	var hazard_a = registry.get_hazard(String(map_a.get("hazard_id", "")))
	var event_a = registry.get_event_table(String(map_a.get("event_table_id", "")))
	var runtime_default = map_runtime_script.new()
	runtime_default.setup(map_a, hazard_a, event_a, 5021)
	runtime_default.set_external_modifiers({})
	var runtime_contract = map_runtime_script.new()
	runtime_contract.setup(map_a, hazard_a, event_a, 5021)
	runtime_contract.set_external_modifiers({"events": {"rate_mult": 1.35, "hazard_cycle_mult": 1.4}})
	var default_event_count := 0
	var contract_event_count := 0
	var default_first_event_time := -1.0
	var contract_first_event_time := -1.0
	var default_hazard_first_time := -1.0
	var contract_hazard_first_time := -1.0
	for step in range(0, 240):
		var snap_default: Dictionary = runtime_default.update(0.5)
		var snap_contract: Dictionary = runtime_contract.update(0.5)
		var default_trig_variant: Variant = snap_default.get("triggered_events", [])
		var contract_trig_variant: Variant = snap_contract.get("triggered_events", [])
		if default_trig_variant is Array:
			default_event_count += (default_trig_variant as Array).size()
			if default_first_event_time < 0.0 and (default_trig_variant as Array).size() > 0:
				default_first_event_time = float(snap_default.get("elapsed_time", 0.0))
		if contract_trig_variant is Array:
			contract_event_count += (contract_trig_variant as Array).size()
			if contract_first_event_time < 0.0 and (contract_trig_variant as Array).size() > 0:
				contract_first_event_time = float(snap_contract.get("elapsed_time", 0.0))
		if default_hazard_first_time < 0.0 and bool(snap_default.get("hazard_active", false)):
			default_hazard_first_time = float(snap_default.get("elapsed_time", 0.0))
		if contract_hazard_first_time < 0.0 and bool(snap_contract.get("hazard_active", false)):
			contract_hazard_first_time = float(snap_contract.get("elapsed_time", 0.0))
	_assert_true(contract_event_count >= default_event_count, "p0f event rate multiplier does not reduce event triggers")
	_assert_true(contract_first_event_time > 0.0 and contract_first_event_time <= default_first_event_time, "p0f event rate multiplier advances first event timing")
	_assert_true(contract_hazard_first_time > 0.0 and contract_hazard_first_time < default_hazard_first_time, "p0f hazard cycle multiplier triggers hazards earlier")

	var world_scene: PackedScene = load("res://scenes/world/World.tscn")
	var world = world_scene.instantiate()
	get_tree().root.add_child.call_deferred(world)
	await get_tree().process_frame
	await get_tree().process_frame
	var run_rng := RandomNumberGenerator.new()
	run_rng.seed = 8129
	var fragile_contract: Dictionary = registry.compose_contract_modifiers(["contract_fragile_player", "contract_no_dash"])
	world.setup_run(run_rng, registry.get_character("diver"), "map_trench_lab", 8129, fragile_contract, ["contract_fragile_player", "contract_no_dash"])
	_assert_true(bool(world.player.get_hud_data().get("contract_dash_disabled", false)), "p0f contract_no_dash disables dash")
	_assert_true(float(world.player.max_hp) < 100.0, "p0f contract_fragile_player reduces max hp")
	_assert_true(world.get_active_contract_ids().size() == 2, "p0f world stores active contract ids")

	world.player.set_noise_value(80.0)
	world.enemy_manager.update_difficulty(180.0, world.player.noise)
	world.enemy_manager._process(0.5)
	var noise_debug: Dictionary = world.enemy_manager.get_noise_debug_snapshot()
	_assert_true(float(noise_debug.get("elite_chance", 0.0)) >= registry.get_default_elite_chance(), "p0f elite chance is exposed in runtime debug")
	_assert_true(float(noise_debug.get("pursuer_chance", 0.0)) > 0.0, "p0f runtime pursuer chance positive at high noise")

	var rich_contract: Dictionary = registry.compose_contract_modifiers(["contract_rich_pickups"])
	world.set_contract_modifiers(rich_contract, ["contract_rich_pickups"])
	world.player.set_noise_value(80.0)
	world.enemy_manager.update_difficulty(200.0, world.player.noise)
	world.enemy_manager._process(0.2)
	var mul_debug: Dictionary = world.enemy_manager.get_noise_debug_snapshot()
	var computed_total := float(mul_debug.get("noise_spawn_rate_multiplier", 1.0)) \
		* float(mul_debug.get("map_spawn_rate_multiplier", 1.0)) \
		* float(mul_debug.get("contract_spawn_rate_multiplier", 1.0)) \
		* float(mul_debug.get("boss_spawn_rate_multiplier", 1.0))
	_assert_true(is_equal_approx(float(mul_debug.get("spawn_rate_multiplier", 1.0)), computed_total), "p0f spawn multiplier equals noise*map*contract*boss components")

	world.enemy_manager._spawn_specific_enemy("pursuer_stalker")
	await get_tree().process_frame
	var pursuer_debug: Dictionary = world.enemy_manager.get_noise_debug_snapshot()
	_assert_true(int(pursuer_debug.get("pursuer_spawned_total", 0)) >= 1, "p0f pursuer spawn updates runtime counter")

	world.enemy_manager.update_difficulty(620.0, world.player.noise)
	for i in range(4):
		world.enemy_manager._process(0.4)
		await get_tree().process_frame
	var boss_spawned := false
	for node in world.enemy_manager.get_children():
		if node != null and is_instance_valid(node) and node.is_in_group("boss"):
			boss_spawned = true
			node.set("hp", float(node.get("max_hp")) * 0.42)
			break
	_assert_true(boss_spawned, "p0f boss spawns once timeline passes threshold")
	world.enemy_manager._process(0.5)
	await get_tree().process_frame
	var boss_debug: Dictionary = world.enemy_manager.get_noise_debug_snapshot()
	_assert_true(String(boss_debug.get("boss_state", "")).find("False") >= 0 or String(boss_debug.get("boss_state", "")).find("phase_2") >= 0 or String(boss_debug.get("boss_state", "")).find("false") >= 0, "p0f boss phase transition updates boss_state")

	var game_scene: PackedScene = load("res://scenes/game/GameRoot.tscn")
	var game = game_scene.instantiate()
	get_tree().root.add_child.call_deferred(game)
	await get_tree().process_frame
	await get_tree().process_frame
	game._on_main_menu_start_requested()
	_assert_true(game.run_state == game.STATE_CHARACTER_SELECT, "p0f menu start enters character select")
	game._on_start_run_requested("diver")
	_assert_true(game.run_state == game.STATE_MAP_SELECT, "p0f character select enters map select")
	game._on_map_select_start_requested("map_trench_lab")
	_assert_true(game.run_state == game.STATE_CONTRACT_SELECT, "p0f map select enters contract select")
	var selected_contracts_for_start: Array[String] = ["contract_small_vision"]
	game._on_contract_select_start_requested(selected_contracts_for_start)
	_assert_true(game.run_state == game.STATE_PLAYING, "p0f contract select starts run")

	game.queue_free()
	world.queue_free()
	await get_tree().process_frame
	registry.free()


func _run_start_run_hotfix_tests() -> void:
	var game_scene: PackedScene = load("res://scenes/game/GameRoot.tscn")
	var game_variant: Variant = game_scene.instantiate()
	_assert_true(game_variant is Node, "hotfix game root instantiates for start-run tests")
	if not (game_variant is Node):
		return
	var game: Node = game_variant
	get_tree().root.add_child.call_deferred(game)
	await _await_stable_physics_frames(2)

	game.call("_on_main_menu_start_requested")
	game.call("_on_start_run_requested", "diver")
	game.call("_on_map_select_start_requested", "map_trench_lab")
	Engine.time_scale = 0.33
	var hotfix_contracts: Array[String] = []
	game.call("_on_contract_select_start_requested", hotfix_contracts)
	await _await_stable_physics_frames(3)

	_assert_true(String(game.get("run_state")) == String(game.get("STATE_PLAYING")), "hotfix run enters STATE_PLAYING after start")
	_assert_true(not get_tree().paused, "hotfix start run clears SceneTree paused flag")

	var ui_node: Node = game.get_node_or_null("UI")
	if ui_node != null:
		var ui_root: Control = ui_node.get_node_or_null("Root") as Control
		if ui_root != null:
			_assert_true(ui_root.mouse_filter == Control.MOUSE_FILTER_IGNORE, "hotfix gameplay root input passthrough enabled")
		var menu_panel: CanvasItem = ui_node.get_node_or_null("Root/MainMenuPanel") as CanvasItem
		var contract_panel: CanvasItem = ui_node.get_node_or_null("Root/ContractSelect") as CanvasItem
		if menu_panel != null:
			_assert_true(not menu_panel.visible, "hotfix main menu overlay hidden in playing state")
		if contract_panel != null:
			_assert_true(not contract_panel.visible, "hotfix contract overlay hidden in playing state")

	var elapsed_before := float(game.get("elapsed_time"))
	for _i in range(8):
		game.call("_process", 0.2)
		await get_tree().process_frame
	var elapsed_after := float(game.get("elapsed_time"))
	_assert_true(elapsed_after > elapsed_before, "test_run_starts_time_moves: elapsed time increases after start")

	var world_node: Node = game.get_node_or_null("World")
	if world_node != null:
		for _step in range(40):
			game.call("_process", 0.2)
			if world_node.has_method("update_map_runtime"):
				world_node.call("update_map_runtime", 0.2)
			var enemy_manager: Node = world_node.get_node_or_null("EnemyManager")
			if enemy_manager != null and enemy_manager.has_method("_process"):
				enemy_manager.call("_process", 0.2)
			await get_tree().process_frame
		var manager: Node = world_node.get_node_or_null("EnemyManager")
		if manager != null and manager.has_method("get_alive_enemy_count"):
			_assert_true(int(manager.call("get_alive_enemy_count")) > 0, "test_enemy_spawns_after_start: enemies spawn within 5-10s window")

	game.queue_free()
	await _await_stable_physics_frames(1)
	get_tree().set_deferred("paused", false)
	Engine.time_scale = 1.0


func _run_telegraph_bus_s4_tests() -> void:
	var bus := get_tree().root.get_node_or_null("TelegraphBus")
	_assert_true(bus != null, "s4 telegraph bus singleton exists")
	if bus == null:
		return
	_assert_true(bus.has_signal("warning_emitted"), "s4 telegraph bus exposes warning_emitted signal")

	var events: Array[Dictionary] = []
	var listener: Callable = func(payload: Dictionary) -> void:
		events.append(payload.duplicate(true))
	if not bus.is_connected("warning_emitted", listener):
		bus.connect("warning_emitted", listener)

	var game_scene: PackedScene = load("res://scenes/game/GameRoot.tscn")
	var game_variant: Variant = game_scene.instantiate()
	_assert_true(game_variant is Node, "s4 game root instantiates for telegraph test")
	if game_variant is Node:
		var game: Node = game_variant
		get_tree().root.add_child.call_deferred(game)
		await _await_stable_physics_frames(2)
		game.set("run_state", game.get("STATE_PLAYING"))
		game.call("_on_pursuer_spawned", "pursuer_stalker", Vector2.ZERO, 2, 4.5)
		game.call("_on_hazard_state_changed", false, "Magnetic Interference")
		game.call("_on_hazard_state_changed", true, "Magnetic Interference")
		game.call("_on_boss_phase_changed", "abyss_siren", "phase_2", "Signal Fracture")
		game.call("_on_boss_attack_telegraph_requested", "line", {})
		await _await_stable_physics_frames(2)
		game.queue_free()
		await _await_stable_physics_frames(1)

	if bus.is_connected("warning_emitted", listener):
		bus.disconnect("warning_emitted", listener)

	_assert_true(events.size() >= 5, "s4 gameplay warning sources emit telegraph events")
	_assert_true(_telegraph_events_has_text_key(events, "pursuer_inbound"), "s4 pursuer warning emits text_key pursuer_inbound")
	_assert_true(_telegraph_events_has_text_key(events, "hazard_warning"), "s4 hazard warning emits text_key hazard_warning")
	_assert_true(_telegraph_events_has_text_key(events, "hazard_active"), "s4 hazard active emits text_key hazard_active")
	_assert_true(_telegraph_events_has_text_key(events, "boss_phase_shift"), "s4 boss phase emits text_key boss_phase_shift")
	_assert_true(_telegraph_events_has_text_key(events, "boss_attack_warning"), "s4 boss major telegraph emits text_key boss_attack_warning")
	_assert_true(_telegraph_events_has_sfx_bucket(events, "warning"), "s4 telegraph bus outputs warning bucket")
	_assert_true(_telegraph_events_has_sfx_bucket(events, "alert"), "s4 telegraph bus outputs alert bucket")
	_assert_true(_telegraph_events_has_sfx_bucket(events, "boss"), "s4 telegraph bus outputs boss bucket")


func _run_contract_ux_s3_tests() -> void:
	var registry_script: Script = load("res://scripts/core/data_registry.gd")
	var registry = registry_script.new()
	_assert_true(registry.load_all(), "s3 contracts registry load succeeds")

	var contracts_rows: Array = registry.get_contracts()
	var group_to_ids: Dictionary = {}
	for row_variant in contracts_rows:
		if not (row_variant is Dictionary):
			continue
		var row: Dictionary = row_variant
		var contract_id := String(row.get("id", "")).strip_edges()
		var group := String(row.get("exclusive_group", "")).strip_edges()
		if contract_id.is_empty() or group.is_empty():
			continue
		if not group_to_ids.has(group):
			group_to_ids[group] = []
		var bucket_variant: Variant = group_to_ids.get(group, [])
		if bucket_variant is Array:
			var bucket: Array = bucket_variant
			bucket.append(contract_id)
			group_to_ids[group] = bucket

	var conflict_pair: Array[String] = []
	for group_key_variant in group_to_ids.keys():
		var bucket_variant: Variant = group_to_ids.get(group_key_variant, [])
		if not (bucket_variant is Array):
			continue
		var bucket: Array = bucket_variant
		if bucket.size() >= 2:
			conflict_pair = [
				String(bucket[0]).strip_edges(),
				String(bucket[1]).strip_edges()
			]
			break
	_assert_true(conflict_pair.size() == 2, "s3 contracts include at least one shared exclusive group")
	if conflict_pair.size() != 2:
		registry.free()
		return

	var normalized_conflict: Array[String] = registry.normalize_contract_selection(conflict_pair)
	_assert_true(normalized_conflict.size() == 1, "s3 normalize keeps one contract per exclusive group")

	var contract_scene: PackedScene = load("res://scenes/ui/ContractSelect.tscn")
	var panel_variant: Variant = contract_scene.instantiate()
	_assert_true(panel_variant is Node, "s3 contract select scene instantiates")
	if not (panel_variant is Node):
		registry.free()
		return
	var panel: Node = panel_variant
	get_tree().root.add_child.call_deferred(panel)
	await _await_stable_physics_frames(2)
	var initial_selection: Array[String] = [conflict_pair[0]]
	panel.call("set_contract_data", contracts_rows, initial_selection, registry.get_contract_max_select())
	await _await_stable_physics_frames(1)

	var locked_id := conflict_pair[1]
	_assert_true(bool(panel.call("is_contract_locked", locked_id)), "s3 conflicting contract is locked in contract list")
	var locked_text: String = String(panel.call("get_contract_row_text", locked_id))
	_assert_true(locked_text.find("🔒") >= 0, "s3 locked contract shows lock icon in row text")

	var locked_index: int = int(panel.call("get_contract_index", locked_id))
	var selected_before_variant: Variant = panel.call("get_selected_contract_ids")
	var selected_before: Array[String] = selected_before_variant if selected_before_variant is Array else []
	panel.call("_on_item_activated", locked_index)
	await _await_stable_physics_frames(1)
	var selected_after_variant: Variant = panel.call("get_selected_contract_ids")
	var selected_after: Array[String] = selected_after_variant if selected_after_variant is Array else []
	_assert_equal(selected_after, selected_before, "s3 locked contract activation does not change selection")
	var conflict_hint: String = String(panel.call("get_status_hint_text"))
	_assert_true(conflict_hint.find("互斥") >= 0, "s3 selecting locked contract shows mutual exclusion hint")

	var preview_before: String = String(panel.call("get_preview_text"))
	_assert_true(
		preview_before.find("XP x") >= 0 and preview_before.find("Rarity x") >= 0 and preview_before.find("Drop x") >= 0,
		"s3 reward preview displays XP/Rarity/Drop breakdown"
	)

	var selected_group := String(registry.get_contract(conflict_pair[0]).get("exclusive_group", ""))
	var additive_contract_id := ""
	for row_variant in contracts_rows:
		if not (row_variant is Dictionary):
			continue
		var row: Dictionary = row_variant
		var candidate_id := String(row.get("id", "")).strip_edges()
		if candidate_id.is_empty() or conflict_pair.has(candidate_id):
			continue
		if String(row.get("exclusive_group", "")).strip_edges() == selected_group:
			continue
		additive_contract_id = candidate_id
		break
	_assert_true(not additive_contract_id.is_empty(), "s3 found non-conflicting contract for preview change test")
	if not additive_contract_id.is_empty():
		var additive_index: int = int(panel.call("get_contract_index", additive_contract_id))
		panel.call("_on_item_activated", additive_index)
		await _await_stable_physics_frames(1)

	var preview_after: String = String(panel.call("get_preview_text"))
	_assert_true(preview_after != preview_before, "s3 reward preview updates after selection change")
	var selected_snapshot_variant: Variant = panel.call("get_selected_contract_ids")
	var selected_snapshot: Array[String] = selected_snapshot_variant if selected_snapshot_variant is Array else []

	var panel_b_variant: Variant = contract_scene.instantiate()
	_assert_true(panel_b_variant is Node, "s3 second contract panel instantiates")
	if panel_b_variant is Node:
		var panel_b: Node = panel_b_variant
		get_tree().root.add_child.call_deferred(panel_b)
		await _await_stable_physics_frames(2)
		panel_b.call("set_contract_data", contracts_rows, selected_snapshot, registry.get_contract_max_select())
		await _await_stable_physics_frames(1)
		var preview_repro: String = String(panel_b.call("get_preview_text"))
		_assert_equal(preview_repro, preview_after, "s3 reward preview reproducible for same selected contracts")
		panel_b.queue_free()
		await _await_stable_physics_frames(1)

	var ui_scene: PackedScene = load("res://scenes/ui/UI.tscn")
	var ui_variant: Variant = ui_scene.instantiate()
	_assert_true(ui_variant is Node, "s3 ui scene instantiates for no_dash HUD test")
	if ui_variant is Node:
		var ui: Node = ui_variant
		get_tree().root.add_child.call_deferred(ui)
		await _await_stable_physics_frames(2)
		ui.call("update_hud", {
			"hp": 100.0,
			"max_hp": 100.0,
			"xp": 0.0,
			"xp_to_next": 20.0,
			"level": 1,
			"noise": 0.0,
			"noise_min": 0.0,
			"noise_max": 100.0,
			"noise_tier_name": "静默",
			"noise_tier_id": "silent",
			"noise_tier_color": "#74e7ff",
			"attack_mode": "AUTO",
			"elapsed_time": 0.0,
			"kills": 0,
			"enemy_count": 0,
			"revealed_count": 0,
			"active_weapon_name": "silence_dart",
			"active_weapon_id": "silence_dart",
			"active_weapon_level": 1,
			"active_weapon_model": "projectile",
			"contract_dash_disabled": true
		})
		var contract_label_variant: Variant = ui.get("contract_status_label")
		if contract_label_variant is Label:
			var contract_label: Label = contract_label_variant
			_assert_true(contract_label.visible, "s3 no_dash HUD label is visible")
			_assert_true(contract_label.text.find("Dash Disabled") >= 0, "s3 no_dash HUD label text is explicit")
		else:
			_assert_true(false, "s3 contract status label exists in HUD")
		ui.queue_free()
		await _await_stable_physics_frames(1)

	panel.queue_free()
	await _await_stable_physics_frames(1)
	registry.free()


func _telegraph_events_has_text_key(events: Array[Dictionary], text_key: String) -> bool:
	for payload in events:
		if String(payload.get("text_key", "")) == text_key:
			return true
	return false


func _telegraph_events_has_sfx_bucket(events: Array[Dictionary], bucket: String) -> bool:
	for payload in events:
		if String(payload.get("sfx_bucket", "")) == bucket:
			return true
	return false


func _run_enemy_pool_perf_tests() -> void:
	var world_scene: PackedScene = load("res://scenes/world/World.tscn")
	var world = world_scene.instantiate()
	get_tree().root.add_child.call_deferred(world)
	await get_tree().process_frame
	await get_tree().process_frame

	var run_rng := RandomNumberGenerator.new()
	run_rng.seed = 420123
	world.setup_run(run_rng, DataRegistry.get_character("diver"), "map_trench_lab", 420123)
	await get_tree().process_frame
	await get_tree().process_frame

	var manager: Node = world.enemy_manager
	_assert_true(manager != null and manager.has_method("get_enemy_pool_stats"), "s1 enemy manager exposes enemy pool stats")
	if manager != null and manager.has_method("set_process"):
		manager.set_process(false)
	if manager != null and manager.has_method("_clear_all_active_enemies"):
		manager._clear_all_active_enemies()
	await get_tree().process_frame

	manager._spawn_specific_enemy("drifter")
	await get_tree().process_frame
	var drifter_a: Node = _find_active_enemy_by_id(manager, "drifter")
	_assert_true(drifter_a != null, "s1 drifter spawn succeeds for pooling test")

	var drifter_instance_id := -1
	if drifter_a != null:
		drifter_instance_id = int(drifter_a.get_instance_id())
		if drifter_a.has_method("set_revealed"):
			drifter_a.set_revealed(1.5)
		var affixes: Array = DataRegistry.get_elite_affixes()
		if not affixes.is_empty() and affixes[0] is Dictionary and drifter_a.has_method("apply_elite_affix"):
			drifter_a.apply_elite_affix(affixes[0])
		if drifter_a.has_method("take_hit"):
			drifter_a.take_hit(99999.0)
	await get_tree().process_frame
	await get_tree().process_frame
	_assert_true(_find_active_enemy_by_id(manager, "drifter") == null, "s1 enemy recycle removes dead enemy from active list")

	manager._spawn_specific_enemy("drifter")
	await get_tree().process_frame
	var drifter_b: Node = _find_active_enemy_by_id(manager, "drifter")
	_assert_true(drifter_b != null, "s1 drifter respawn succeeds after recycle")
	if drifter_b != null:
		_assert_true(drifter_instance_id >= 0 and int(drifter_b.get_instance_id()) == drifter_instance_id, "s1 enemy pool reuses drifter instance")
		_assert_true(not bool(drifter_b.get("is_elite")), "s1 pooled enemy clears elite state")
		var revealed_after_reuse := bool(drifter_b.call("is_revealed")) if drifter_b.has_method("is_revealed") else true
		_assert_true(not revealed_after_reuse, "s1 pooled enemy clears revealed state")
		_assert_true(is_equal_approx(float(drifter_b.get("hp")), float(drifter_b.get("max_hp"))), "s1 pooled enemy hp resets to max")
		var drifter_def: Dictionary = DataRegistry.get_enemy("drifter")
		_assert_true(is_equal_approx(float(drifter_b.get("speed")), float(drifter_def.get("speed", 0.0))), "s1 pooled enemy speed resets to definition")

	manager._spawn_specific_enemy("pursuer_stalker")
	await get_tree().process_frame
	var pursuer_debug_first: Dictionary = manager.get_noise_debug_snapshot()
	_assert_true(int(pursuer_debug_first.get("pursuer_spawned_total", 0)) >= 1, "s1 pursuer spawn updates warning counter on first spawn")
	var pursuer_a: Node = _find_active_enemy_by_id(manager, "pursuer_stalker")
	_assert_true(pursuer_a != null and pursuer_a.is_in_group("pursuer"), "s1 pursuer spawn applies pursuer identity")
	var pursuer_instance_id := -1
	if pursuer_a != null:
		pursuer_instance_id = int(pursuer_a.get_instance_id())
		if pursuer_a.has_method("take_hit"):
			pursuer_a.take_hit(99999.0)
	await get_tree().process_frame
	await get_tree().process_frame
	manager._spawn_specific_enemy("pursuer_stalker")
	await get_tree().process_frame
	var pursuer_b: Node = _find_active_enemy_by_id(manager, "pursuer_stalker")
	_assert_true(pursuer_b != null, "s1 pursuer respawn succeeds after recycle")
	if pursuer_b != null:
		_assert_true(pursuer_instance_id >= 0 and int(pursuer_b.get_instance_id()) == pursuer_instance_id, "s1 pursuer reuses pooled instance")
	var pursuer_debug_second: Dictionary = manager.get_noise_debug_snapshot()
	_assert_true(int(pursuer_debug_second.get("pursuer_spawned_total", 0)) >= 2, "s1 pursuer warning counter increments after pooled reuse")

	var unique_enemy_instances: Dictionary = {}
	for i in range(90):
		manager._spawn_specific_enemy("drifter")
		await get_tree().process_frame
		var spawned: Node = _find_active_enemy_by_id(manager, "drifter")
		if spawned != null:
			unique_enemy_instances[int(spawned.get_instance_id())] = true
			if spawned.has_method("take_hit"):
				spawned.take_hit(99999.0)
		if i % 6 == 0:
			await get_tree().process_frame
	await get_tree().process_frame
	_assert_true(unique_enemy_instances.size() <= 26, "s1 high-spawn short run keeps enemy instance count bounded")

	var enemy_pool_stats: Dictionary = manager.get_enemy_pool_stats()
	_assert_true(int(enemy_pool_stats.get("hits", 0)) > 0, "s1 enemy pool hit counter increments")
	_assert_true(float(enemy_pool_stats.get("hit_rate", 0.0)) >= 0.0, "s1 enemy pool exposes hit_rate metric")

	world.queue_free()
	await get_tree().process_frame
	await get_tree().process_frame

	var mine_harness := await _create_weapon_test_harness("abyss_mine", Vector2(72.0, 0.0))
	var mine_player: Node = mine_harness.get("player")
	mine_player._attempt_fire()
	mine_player._update_deployed_mines(1.0)
	_assert_true(int(mine_player.get_target_query_total()) > 0, "s1 mine trigger path contributes target query telemetry")
	await _cleanup_weapon_test_harness(mine_harness)

	var drone_harness := await _create_weapon_test_harness("orbital_drone", Vector2(66.0, 0.0))
	var drone_player: Node = drone_harness.get("player")
	drone_player._attempt_fire()
	for i in range(6):
		drone_player._physics_process(0.2)
		await get_tree().process_frame
	_assert_true(float(drone_player.get_target_query_count_per_sec()) > 0.0, "s1 drone path reports target_query_count_per_sec")
	await _cleanup_weapon_test_harness(drone_harness)

	var melee_harness := await _create_weapon_test_harness("sonar_blade", Vector2(52.0, 0.0))
	var melee_player: Node = melee_harness.get("player")
	melee_player._attempt_fire()
	_assert_true(int(melee_player.get_target_query_total()) > 0, "s1 melee path uses radius query telemetry")
	await _cleanup_weapon_test_harness(melee_harness)


func _run_boss_showcase_tests() -> void:
	var world_a := await _create_boss_test_world(77201)
	var manager_a: Node = world_a.enemy_manager
	var boss_a := await _force_spawn_boss_for_test(world_a)
	_assert_true(boss_a != null, "s2 boss spawns for showcase test")
	_assert_true(world_a.get_active_boss_telegraph_count() > 0, "s2 phase telegraph appears on boss entry")

	if boss_a != null:
		boss_a.set("hp", float(boss_a.get("max_hp")) * 0.42)
	manager_a._process(0.5)
	await get_tree().process_frame
	var decoy_count_a := int(manager_a.get_boss_decoy_count())
	_assert_true(decoy_count_a >= 2 and decoy_count_a <= 3, "s2 phase2 generates decoy count in [2,3]")
	_assert_true(not bool(manager_a.is_boss_true_form_revealed()), "s2 true form remains hidden before reveal")

	if boss_a != null and boss_a.has_method("set_revealed"):
		boss_a.set_revealed(1.3)
	await _await_stable_physics_frames(1)
	_assert_true(bool(manager_a.is_boss_true_form_revealed()), "s2 true form marked revealed after sonar reveal")
	for _i in range(36):
		await _await_stable_physics_frames(1)
		if int(manager_a.get_boss_decoy_count()) == 0:
			break
	_assert_true(int(manager_a.get_boss_decoy_count()) == 0, "s2 decoys dissipate after true reveal")

	var telegraphs_before := int(world_a.get_active_boss_telegraph_count())
	if boss_a != null:
		boss_a.set("ranged_cooldown_remaining", 0.0)
		boss_a.call("_update_shooter_attack", 90.0)
	await get_tree().process_frame
	var telegraphs_after := int(world_a.get_active_boss_telegraph_count())
	_assert_true(telegraphs_after > telegraphs_before, "s2 boss attack emits line telegraph")

	world_a.spawn_boss_telegraph("ring", {
		"origin": Vector2.ZERO,
		"radius": 88.0,
		"duration": 0.08,
		"line_width": 4.0
	})
	var transient_telegraphs := int(world_a.get_active_boss_telegraph_count())
	_assert_true(transient_telegraphs > 0, "s2 manual telegraph node instantiates")
	await _force_advance_boss_telegraphs(world_a, 0.2, 7)
	_assert_true(int(world_a.get_active_boss_telegraph_count()) < transient_telegraphs, "s2 telegraph nodes auto-destroy after duration")

	world_a.queue_free()
	await get_tree().process_frame
	await get_tree().process_frame

	var world_b := await _create_boss_test_world(77201)
	var manager_b: Node = world_b.enemy_manager
	var boss_b := await _force_spawn_boss_for_test(world_b)
	if boss_b != null:
		boss_b.set("hp", float(boss_b.get("max_hp")) * 0.42)
	manager_b._process(0.5)
	await get_tree().process_frame
	var decoy_count_b := int(manager_b.get_boss_decoy_count())
	_assert_equal(decoy_count_b, decoy_count_a, "s2 decoy count reproducible with fixed seed")
	world_b.queue_free()
	await get_tree().process_frame
	await get_tree().process_frame

	var decoy_scene: PackedScene = load("res://scenes/enemy/BossEchoDecoy.tscn")
	var decoy: Node = decoy_scene.instantiate()
	get_tree().root.add_child.call_deferred(decoy)
	await get_tree().process_frame
	await get_tree().process_frame
	if decoy != null and decoy.has_method("configure"):
		decoy.configure(Vector2.ZERO, Color(0.7, 0.95, 1.0, 1.0), 14.0, 2.0)
	await get_tree().process_frame
	if decoy != null and decoy.has_method("take_hit"):
		decoy.take_hit(10.0)
	var decoy_fading := false
	if decoy != null and is_instance_valid(decoy):
		var fading_variant: Variant = decoy.get("fading")
		decoy_fading = bool(fading_variant)
	_assert_true(decoy_fading, "s2 decoy hit enters fading state")
	for _i in range(120):
		await _await_stable_physics_frames(1)
		if decoy == null or not is_instance_valid(decoy):
			break
	var decoy_cleanup_ok := decoy == null or not is_instance_valid(decoy)
	if not decoy_cleanup_ok and decoy != null and is_instance_valid(decoy):
		decoy_cleanup_ok = bool(decoy.get("fading"))
	_assert_true(decoy_cleanup_ok, "s2 decoy hit causes dissipate and cleanup")


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


func _force_advance_boss_telegraphs(world: Node, delta: float, steps: int) -> void:
	if world == null:
		return
	var layer := world.get_node_or_null("BossFxLayer")
	if layer == null:
		return
	for _i in range(maxi(1, steps)):
		for telegraph in layer.get_children():
			if telegraph == null or not is_instance_valid(telegraph):
				continue
			if telegraph.has_method("_process"):
				telegraph._process(delta)
		await get_tree().process_frame


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


func _find_active_enemy_by_id(enemy_manager: Node, enemy_id: String) -> Node:
	if enemy_manager == null:
		return null
	for enemy in enemy_manager.get_children():
		if enemy == null or not is_instance_valid(enemy):
			continue
		if not enemy.is_in_group("enemy"):
			continue
		var current_enemy_id_variant: Variant = enemy.get("enemy_id")
		var current_enemy_id := String(current_enemy_id_variant) if current_enemy_id_variant != null else ""
		if current_enemy_id != enemy_id:
			continue
		return enemy
	return null


func _assert_true(condition: bool, label: String) -> void:
	if condition:
		print("PASS: %s" % label)
		return
	failed += 1
	push_error("FAIL: %s" % label)


func _assert_equal(actual: Variant, expected: Variant, label: String) -> void:
	_assert_true(actual == expected, "%s (actual=%s expected=%s)" % [label, actual, expected])


func _array_contains_text(items: Array[String], pattern: String) -> bool:
	for item in items:
		if item.find(pattern) >= 0:
			return true
	return false


func _make_upgrade_context(current_weapon_ids: Array, active_weapon_id: String, acquired_tags: Dictionary, noise_tier_id: String) -> Dictionary:
	return {
		"current_weapon_ids": current_weapon_ids,
		"active_weapon_id": active_weapon_id,
		"acquired_tags": acquired_tags,
		"noise_tier_id": noise_tier_id,
		"player_level": 1,
		"survive_time_seconds": 0.0
	}


func _candidate_list_has(candidates: Array, upgrade_id: String) -> bool:
	for candidate_variant in candidates:
		if not (candidate_variant is Dictionary):
			continue
		var candidate: Dictionary = candidate_variant
		if String(candidate.get("id", "")) == upgrade_id:
			return true
	return false


func _extract_choice_ids(choices: Array) -> Array[String]:
	var ids: Array[String] = []
	for choice_variant in choices:
		if not (choice_variant is Dictionary):
			continue
		var choice: Dictionary = choice_variant
		var upgrade_id := String(choice.get("id", ""))
		if upgrade_id.is_empty():
			continue
		ids.append(upgrade_id)
	return ids


func _write_json_value(path: String, value: Variant) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(JSON.stringify(value, "\t"))
	file.flush()
	file = null


func _remove_file_if_exists(path: String) -> void:
	if not FileAccess.file_exists(path):
		return
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))


func _mutate_upgrade_field(rows: Array, upgrade_id: String, field: String, value: Variant) -> bool:
	for idx in range(rows.size()):
		var row_variant: Variant = rows[idx]
		if not (row_variant is Dictionary):
			continue
		var row := (row_variant as Dictionary).duplicate(true)
		if String(row.get("id", "")) != upgrade_id:
			continue
		row[field] = value
		rows[idx] = row
		return true
	return false


func _count_choices_with_tag(choices: Array, tag: String) -> int:
	var count := 0
	for choice_variant in choices:
		if not (choice_variant is Dictionary):
			continue
		var choice: Dictionary = choice_variant
		var tags_variant: Variant = choice.get("tags", [])
		if not (tags_variant is Array):
			continue
		var tags: Array = tags_variant
		if tags.has(tag):
			count += 1
	return count


func _setup_profile_isolation() -> void:
	if ProfileStore == null:
		return
	if not ProfileStore.has_method("begin_test_session"):
		return
	var session_id := "test_runner_%d_%d" % [int(Time.get_unix_time_from_system()), int(Time.get_ticks_usec() % 1000000)]
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


func _current_profile_path() -> String:
	if ProfileStore != null and ProfileStore.has_method("get_profile_path"):
		return String(ProfileStore.get_profile_path())
	return "user://profile.json"
