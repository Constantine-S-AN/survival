extends Node

const GAME_ROOT_SCENE := preload("res://scenes/game/GameRoot.tscn")
const LOG_PATH := "res://tmp/logs/t10_modifiers_effect.log"
const SESSION_TAG := "t10_modifiers_runner"
const FIXED_RUN_SEED := 8102026
const ROUTE_CORE_UPGRADE_ID := "u_sonar_scope_matrix"
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
		await _fail(lines, "drop multiplier produced no gain")
		return
	if boosted_meta <= baseline_meta or boosted_meta_mult <= 1.0:
		await _fail(lines, "meta currency multiplier produced no gain")
		return
	if boosted_rarity <= baseline_rarity:
		await _fail(lines, "rarity multiplier produced no gain in sampled rolls")
		return
	if not await _validate_build_pack_market(lines):
		return

	lines.append("t10 modifiers effect: PASS")
	_write_log(lines)
	print("t10 modifiers effect: PASS")
	await _dispose_node(game)
	_cleanup_profile_isolation()
	await _wait_frames(2)
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
	player.call("apply_upgrade", ROUTE_CORE_UPGRADE_ID)
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
	var current_stacks_variant: Variant = player.get("upgrade_stacks")
	var current_stacks: Dictionary = current_stacks_variant if current_stacks_variant is Dictionary else {}
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
		var choices: Array = DataRegistry.get_upgrade_choices(rng, current_stacks, 3, {}, context)
		for row_variant in choices:
			if not (row_variant is Dictionary):
				continue
			var row: Dictionary = row_variant
			var rarity := String(row.get("rarity", "common")).strip_edges().to_lower()
			total_score += int(rarity_value.get(rarity, 1))
	return total_score


func _validate_build_pack_market(lines: Array[String]) -> bool:
	var modifier_state_script: Script = load("res://scripts/night/run_modifier_state.gd")
	var reward_picker_script: Script = load("res://scripts/night/room_reward_picker.gd")
	if modifier_state_script == null or reward_picker_script == null:
		lines.append("build_pack_market=missing_dependencies")
		await _fail(lines, "build pack market validation could not load scripts")
		return false
	var reward_picker = reward_picker_script.new()
	var preview_cases: Array[Dictionary] = [
		{
			"label": "silence_precision",
			"modifier_id": "blessing_choir_silence",
			"theme_id": "harbor_rift",
			"shop_seed": 9000,
			"expected_rare": "relic_hush_compass"
		},
		{
			"label": "pressure_overload",
			"modifier_id": "blessing_redline_howl",
			"theme_id": "harbor_rift",
			"shop_seed": 9000,
			"expected_rare": "relic_tide_lens"
		},
		{
			"label": "dash_mobility",
			"modifier_id": "blessing_riptide_step",
			"theme_id": "harbor_rift",
			"shop_seed": 9000,
			"expected_rare": "relic_riptide_gyro"
		},
		{
			"label": "summon_device",
			"modifier_id": "blessing_dockyard_creed",
			"theme_id": "sunken_exchange",
			"shop_seed": 9003,
			"expected_rare": "relic_ballast_array",
			"expected_synergy": "trait_relay_forge"
		}
	]
	for case_data in preview_cases:
		var state = modifier_state_script.new()
		state.reset()
		var modifier_id := String(case_data.get("modifier_id", "")).strip_edges().to_lower()
		var blessing_offer: Dictionary = state.build_modifier_offer(modifier_id)
		if blessing_offer.is_empty() or state.apply_offer(blessing_offer, {}).is_empty():
			lines.append("%s=blessing_failed" % String(case_data.get("label", "case")))
			await _fail(lines, "build pack market blessing chain failed to apply")
			return false
		var market_offers: Array = reward_picker.build_shop_inventory_offers(
			"night_market_tier_2",
			int(case_data.get("shop_seed", 9000)),
			{
				"theme_id": String(case_data.get("theme_id", "harbor_rift")).strip_edges().to_lower(),
				"room_tags": [],
				"build_tags": state.get_build_tags(),
				"refresh_count": 0
			},
			state
		)
		var rare_offer := _find_shop_offer_by_slot_id(market_offers, "rare_pick")
		var synergy_offer := _find_shop_offer_by_slot_id(market_offers, "synergy_pick")
		var case_label := String(case_data.get("label", "case"))
		lines.append(
			"%s={\"rare\":\"%s\",\"synergy\":\"%s\"}"
			% [case_label, String(rare_offer.get("modifier_id", "")), String(synergy_offer.get("modifier_id", ""))]
		)
		if String(rare_offer.get("modifier_id", "")) != String(case_data.get("expected_rare", "")):
			await _fail(lines, "%s rare lane drifted" % case_label)
			return false
		var expected_synergy := String(case_data.get("expected_synergy", "")).strip_edges()
		if not expected_synergy.is_empty() and String(synergy_offer.get("modifier_id", "")) != expected_synergy:
			await _fail(lines, "%s synergy lane drifted" % case_label)
			return false
	return true


func _fail(lines: Array[String], reason: String) -> void:
	lines.append("t10 modifiers effect: FAIL - %s" % reason)
	_write_log(lines)
	push_error(reason)
	await _dispose_children()
	_cleanup_profile_isolation()
	await _wait_frames(2)
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


func _dispose_children() -> void:
	for child in get_children():
		await _dispose_node(child)


func _dispose_node(node: Node) -> void:
	if node == null or not is_instance_valid(node):
		return
	if node.has_method("stop_session"):
		node.call("stop_session")
	await _wait_frames(2)
	node.queue_free()
	await _wait_frames(4)


func _find_shop_offer_by_slot_id(items_variant: Variant, slot_id: String) -> Dictionary:
	if not (items_variant is Array):
		return {}
	var normalized_slot_id := slot_id.strip_edges().to_lower()
	for item_variant in (items_variant as Array):
		if not (item_variant is Dictionary):
			continue
		var item: Dictionary = item_variant
		if String(item.get("shop_slot_id", "")).strip_edges().to_lower() == normalized_slot_id:
			return item.duplicate(true)
	return {}


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
