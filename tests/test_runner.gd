extends SceneTree

var failed := 0


func _init() -> void:
	_run_data_registry_tests()
	_run_spawn_profile_tests()
	print("Tests finished. failed=%d" % failed)
	quit(failed)


func _run_data_registry_tests() -> void:
	var registry_script := load("res://scripts/core/data_registry.gd")
	var registry = registry_script.new()
	_assert_true(registry.load_all(), "DataRegistry should load all JSON files")
	_assert_true(registry.weapons.has("pulse_emitter"), "weapons includes pulse_emitter")
	_assert_true(registry.enemies.size() >= 3, "enemies has at least 3 entries")
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

	var low_noise: float = registry.get_spawn_rate(0.0, 0.0)
	var high_noise: float = registry.get_spawn_rate(0.0, 80.0)
	_assert_true(high_noise > low_noise, "spawn rate should increase with noise")

	var low_cap: int = registry.get_enemy_cap(0.0, 0.0)
	var high_cap: int = registry.get_enemy_cap(0.0, 80.0)
	_assert_true(high_cap > low_cap, "enemy cap should increase with noise")
	registry.free()


func _assert_true(condition: bool, label: String) -> void:
	if condition:
		print("PASS: %s" % label)
		return
	failed += 1
	push_error("FAIL: %s" % label)


func _assert_equal(actual: Variant, expected: Variant, label: String) -> void:
	_assert_true(actual == expected, "%s (actual=%s expected=%s)" % [label, actual, expected])
