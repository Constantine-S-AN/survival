extends Node

const GAME_ROOT_SCENE := preload("res://scenes/game/GameRoot.tscn")
const LOG_PATH := "res://tmp/logs/t10_modifiers_effect.log"
const SESSION_TAG := "t10_modifiers_runner"
const FIXED_RUN_SEED := 8102026
const BOOSTED_CONTRACTS := [
	"contract_rich_pickups",
	"contract_pursuer_hunt",
	"contract_no_dash"
]


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	_setup_profile_isolation(SESSION_TAG)
	var lines: Array[String] = []
	var game := GAME_ROOT_SCENE.instantiate()
	add_child(game)
	await _wait_frames(3)

	var baseline := await _simulate_case(game, [], FIXED_RUN_SEED)
	var boosted := await _simulate_case(game, BOOSTED_CONTRACTS, FIXED_RUN_SEED)
	lines.append("baseline=%s" % JSON.stringify(baseline))
	lines.append("boosted=%s" % JSON.stringify(boosted))

	var baseline_drop := int(baseline.get("drop_pickups", 0))
	var boosted_drop := int(boosted.get("drop_pickups", 0))
	var baseline_meta := int(baseline.get("meta_total", 0))
	var boosted_meta := int(boosted.get("meta_total", 0))
	var baseline_rarity := int(baseline.get("rarity_score", 0))
	var boosted_rarity := int(boosted.get("rarity_score", 0))
	var boosted_meta_mult := float(boosted.get("meta_multiplier", 1.0))

	if boosted_drop <= baseline_drop:
		_fail(lines, "drop multiplier produced no gain")
		return
	if boosted_meta <= baseline_meta or boosted_meta_mult <= 1.0:
		_fail(lines, "meta currency multiplier produced no gain")
		return
	if boosted_rarity <= baseline_rarity:
		_fail(lines, "rarity multiplier produced no gain in sampled rolls")
		return

	lines.append("t10 modifiers effect: PASS")
	_write_log(lines)
	print("t10 modifiers effect: PASS")
	game.queue_free()
	await _wait_frames(1)
	_cleanup_profile_isolation()
	get_tree().quit(0)


func _simulate_case(game: Node, contract_ids: Array, run_seed: int) -> Dictionary:
	game.call("_start_run", "diver", "map_trench_lab", contract_ids, true, run_seed)
	await _wait_frames(2)

	for i in range(22):
		game.call("_on_enemy_killed", "enemy_scout", 2, Vector2(180.0 + i, 140.0), {})

	var player := game.get_node_or_null("World/Player")
	if player == null:
		return {}
	player.set("level", 7)
	game.set("elapsed_time", 132.0)
	await _wait_frames(2)

	var rarity_score := _sample_rarity_score(player)
	var unlocked_ids: Array[String] = []
	var summary: Dictionary = game.call("_build_run_summary_state", unlocked_ids)
	var meta_variant: Variant = summary.get("meta_currency_earned", null)
	var meta_total := 0
	var meta_mult := 1.0
	if meta_variant is Dictionary:
		var meta: Dictionary = meta_variant
		meta_total = int(meta.get("total", 0))
		meta_mult = float(meta.get("multiplier", 1.0))
	elif meta_variant != null:
		meta_total = int(meta_variant)

	var metrics := {
		"contracts": contract_ids.duplicate(),
		"drop_pickups": int(game.get("runtime_drop_pickups_spawned")),
		"meta_total": meta_total,
		"meta_multiplier": meta_mult,
		"rarity_score": rarity_score
	}
	return metrics


func _sample_rarity_score(player: Node) -> int:
	var total_score := 0
	var rarity_value := {
		"common": 1,
		"uncommon": 2,
		"rare": 4,
		"epic": 7,
		"legendary": 11
	}
	for i in range(64):
		var rng := RandomNumberGenerator.new()
		rng.seed = 3000 + i
		var context: Dictionary = player.call("_build_upgrade_context")
		var choices: Array = DataRegistry.get_upgrade_choices(rng, {}, 3, {}, context)
		for row_variant in choices:
			if not (row_variant is Dictionary):
				continue
			var row: Dictionary = row_variant
			var rarity := String(row.get("rarity", "common")).strip_edges().to_lower()
			total_score += int(rarity_value.get(rarity, 1))
	return total_score


func _fail(lines: Array[String], reason: String) -> void:
	lines.append("t10 modifiers effect: FAIL - %s" % reason)
	_write_log(lines)
	push_error(reason)
	for child in get_children():
		child.queue_free()
	_cleanup_profile_isolation()
	get_tree().quit(1)


func _write_log(lines: Array[String]) -> void:
	var abs_path := ProjectSettings.globalize_path(LOG_PATH)
	DirAccess.make_dir_recursive_absolute(abs_path.get_base_dir())
	var file := FileAccess.open(abs_path, FileAccess.WRITE)
	if file == null:
		return
	for line in lines:
		file.store_line(line)


func _wait_frames(count: int) -> void:
	for _i in range(maxi(1, count)):
		await get_tree().process_frame


func _setup_profile_isolation(tag: String) -> void:
	if ProfileStore == null or not ProfileStore.has_method("begin_test_session"):
		return
	var session_id := "%s_%d_%d" % [tag, int(Time.get_unix_time_from_system()), int(Time.get_ticks_usec() % 1000000)]
	ProfileStore.begin_test_session(session_id, true)
	if ProfileStore.has_method("load_profile"):
		ProfileStore.load_profile("diver", "map_trench_lab")


func _cleanup_profile_isolation() -> void:
	if ProfileStore == null or not ProfileStore.has_method("end_test_session"):
		return
	ProfileStore.end_test_session(true)
