extends Node

const WORLD_SCENE := preload("res://scenes/world/World.tscn")
const BENCH_CHARACTER_ID := "diver"
const BENCH_MAP_ID := "map_trench_lab"
const BENCH_SEED := 13371337
const BATCHES := 12
const HITS_PER_BATCH := 24
const RECYCLE_FRAMES := 24

var _baseline_node_ids: Dictionary = {}
var _seen_new_node_ids: Dictionary = {}


func _ready() -> void:
	await _run_benchmark()


func _run_benchmark() -> void:
	_bootstrap_script_mode_singletons()
	var world := WORLD_SCENE.instantiate()
	add_child(world)
	await _await_frames(2)

	var run_rng := RandomNumberGenerator.new()
	run_rng.seed = BENCH_SEED
	world.setup_run(run_rng, DataRegistry.get_character(BENCH_CHARACTER_ID), BENCH_MAP_ID, BENCH_SEED)
	await _await_frames(3)
	if world.player != null:
		world.player.set_process(false)
		world.player.set_physics_process(false)
	if world.enemy_manager != null:
		world.enemy_manager.set_process(false)
		world.enemy_manager.set_physics_process(false)
	if world.sonar_manager != null:
		world.sonar_manager.set_process(false)
		world.sonar_manager.set_physics_process(false)

	_collect_node_ids(world, _baseline_node_ids, true)
	var start_usec := Time.get_ticks_usec()
	var emit_usec_total := 0
	for batch_idx in range(BATCHES):
		var emit_start_usec := Time.get_ticks_usec()
		for hit_idx in range(HITS_PER_BATCH):
			var intensity := 0.35 + float(hit_idx % 7) * 0.12
			var killed := hit_idx % 3 == 0
			var payload := {
				"is_crit": hit_idx % 2 == 0,
				"weapon_id": "silence_dart"
			}
			var angle := (TAU / float(maxi(1, HITS_PER_BATCH))) * float(hit_idx)
			var position: Vector2 = world.player.global_position + Vector2.RIGHT.rotated(angle) * (52.0 + float(batch_idx % 3) * 10.0)
			world._on_hit_landed(position, intensity, killed, payload)
		emit_usec_total += Time.get_ticks_usec() - emit_start_usec
		await _await_frames(RECYCLE_FRAMES)
		_collect_node_ids(world, _seen_new_node_ids, false)
		print(
			"hit_fx_bench batch=%d total_hits=%d unique_new_nodes=%d subtree_nodes=%d emit_ms=%.2f"
			% [
				batch_idx + 1,
				(batch_idx + 1) * HITS_PER_BATCH,
				_seen_new_node_ids.size(),
				_count_subtree_nodes(world),
				float(emit_usec_total) / 1000.0
			]
		)

	var elapsed_ms := float(Time.get_ticks_usec() - start_usec) / 1000.0
	print(
		"HIT_FX_BENCH elapsed_ms=%.2f emit_ms=%.2f batches=%d hits=%d unique_new_nodes=%d"
		% [elapsed_ms, float(emit_usec_total) / 1000.0, BATCHES, BATCHES * HITS_PER_BATCH, _seen_new_node_ids.size()]
	)
	world.queue_free()
	await _await_frames(2)
	_cleanup_script_mode_singletons()
	await _await_frames(1)
	get_tree().quit()


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
	var input_config_script: Script = load("res://scripts/core/input_config.gd")
	if input_config_script != null and input_config_script.has_method("ensure_default_actions"):
		input_config_script.ensure_default_actions()


func _collect_node_ids(root: Node, target: Dictionary, include_all: bool) -> void:
	if root == null:
		return
	var stack: Array[Node] = [root]
	while not stack.is_empty():
		var node: Node = stack.pop_back()
		var instance_id := int(node.get_instance_id())
		if include_all or not _baseline_node_ids.has(instance_id):
			target[instance_id] = true
		for child in node.get_children():
			if child is Node:
				stack.append(child as Node)


func _count_subtree_nodes(root: Node) -> int:
	if root == null:
		return 0
	var count := 0
	var stack: Array[Node] = [root]
	while not stack.is_empty():
		var node: Node = stack.pop_back()
		count += 1
		for child in node.get_children():
			if child is Node:
				stack.append(child as Node)
	return count


func _cleanup_script_mode_singletons() -> void:
	var tree_root: Node = get_tree().root
	for node_name in ["TelegraphBus", "FeedbackBus", "DataRegistry"]:
		var singleton := tree_root.get_node_or_null(node_name)
		if singleton != null:
			singleton.queue_free()


func _await_frames(count: int) -> void:
	for _i in range(maxi(1, count)):
		await get_tree().process_frame
