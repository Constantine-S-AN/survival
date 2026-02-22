extends SceneTree

class DummyEnemy:
	extends Node2D

	var reveal_calls: int = 0
	var last_duration: float = 0.0

	func set_revealed(duration_sec: float) -> void:
		reveal_calls += 1
		last_duration = duration_sec

	func is_revealed() -> bool:
		return reveal_calls > 0


var failed := 0


func _init() -> void:
	_run_data_registry_tests()
	_run_spawn_profile_tests()
	_run_m2_system_tests()
	print("Tests finished. failed=%d" % failed)
	quit(failed)


func _run_data_registry_tests() -> void:
	var registry_script := load("res://scripts/core/data_registry.gd")
	var registry = registry_script.new()
	_assert_true(registry.load_all(), "DataRegistry should load all JSON files")
	_assert_true(registry.weapons.has("pulse_emitter"), "weapons includes pulse_emitter")
	_assert_true(registry.enemies.size() >= 4, "enemies has at least 4 entries")
	_assert_true(registry.upgrades.size() >= 12, "upgrades has at least 12 entries")

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

	registry.free()


func _assert_true(condition: bool, label: String) -> void:
	if condition:
		print("PASS: %s" % label)
		return
	failed += 1
	push_error("FAIL: %s" % label)


func _assert_equal(actual: Variant, expected: Variant, label: String) -> void:
	_assert_true(actual == expected, "%s (actual=%s expected=%s)" % [label, actual, expected])
