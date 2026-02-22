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


var failed: int = 0


func _ready() -> void:
	_bootstrap_script_mode_singletons()
	_run_data_registry_tests()
	_run_spawn_profile_tests()
	await _run_pool_system_tests()
	await _run_m2_system_tests()
	await get_tree().process_frame
	print("Tests finished. failed=%d" % failed)
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


func _run_data_registry_tests() -> void:
	var registry_script := load("res://scripts/core/data_registry.gd")
	var registry = registry_script.new()
	_assert_true(registry.load_all(), "DataRegistry should load all JSON files")
	_assert_true(registry.weapons.has("pulse_emitter"), "weapons includes pulse_emitter")
	_assert_true(registry.enemies.size() >= 4, "enemies has at least 4 entries")
	_assert_true(registry.upgrades.size() >= 12, "upgrades has at least 12 entries")
	var characters: Array = registry.get_characters()
	_assert_true(characters.size() >= 5, "characters has at least 5 entries")
	_assert_equal(registry.get_default_character_id(), "diver", "default character id is diver")
	_assert_true(registry.has_character("diver"), "characters includes diver")
	var diver: Dictionary = registry.get_character("diver")
	_assert_equal(String(diver.get("starting_weapon_id", "")), "pulse_emitter", "diver starts with pulse_emitter")
	var diver_unlock_variant: Variant = diver.get("unlock", {})
	_assert_true(diver_unlock_variant is Dictionary, "diver unlock object exists")
	var diver_unlock: Dictionary = diver_unlock_variant if diver_unlock_variant is Dictionary else {}
	_assert_equal(String(diver_unlock.get("type", "")), "survive_time_seconds", "diver unlock type")

	var rng := RandomNumberGenerator.new()
	rng.seed = 42
	var choices: Array = registry.get_upgrade_choices(rng, {}, 3)
	_assert_equal(choices.size(), 3, "upgrade choice count should be 3")
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
	var fog_json: Variant = JSON.parse_string(fog_original)
	if fog_json is Dictionary:
		var broken := (fog_json as Dictionary).duplicate(true)
		broken.erase("vision_radius")
		var f := FileAccess.open(fog_path, FileAccess.WRITE)
		f.store_string(JSON.stringify(broken, "\t"))
		f.flush()
		f = null
		var broken_registry = registry_script.new()
		var broken_ok: bool = broken_registry.load_all(false)
		var broken_errors: Array[String] = broken_registry.get_validation_errors()
		var restore_f := FileAccess.open(fog_path, FileAccess.WRITE)
		restore_f.store_string(fog_original)
		restore_f.flush()
		restore_f = null
		_assert_true(not broken_ok, "schema validation fails when fog field missing")
		_assert_true(_array_contains_text(broken_errors, "missing key 'vision_radius'"), "schema error reports exact missing field")
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
		var fw := FileAccess.open(fog_path, FileAccess.WRITE)
		fw.store_string(JSON.stringify(updated, "\t"))
		fw.flush()
		fw = null
		var hot_registry = registry_script.new()
		hot_registry.load_all()
		var loaded_radius := float(hot_registry.get_fog_config().get("vision_radius", 0.0))
		var restore_fw := FileAccess.open(fog_path, FileAccess.WRITE)
		restore_fw.store_string(hotreload_original)
		restore_fw.flush()
		restore_fw = null
		_assert_true(is_equal_approx(loaded_radius, new_radius), "hot reload applies updated fog radius")
		hot_registry.free()
	else:
		_assert_true(false, "fog json parse for hot reload test")

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
