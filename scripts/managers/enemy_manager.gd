extends Node2D
class_name EnemyManager

signal enemy_killed(enemy_id: String, xp_reward: int, world_position: Vector2, meta: Dictionary)
signal pursuer_spawned(enemy_id: String, world_position: Vector2, spawned_total: int, next_eta: float)
signal boss_spawned(boss_id: String, phase_id: String, telegraph_text: String)
signal boss_phase_changed(boss_id: String, phase_id: String, telegraph_text: String)
signal boss_defeated(boss_id: String)
signal boss_telegraph_requested(telegraph_type: String, payload: Dictionary)
signal boss_echoes_spawned(boss_id: String, count: int, world_position: Vector2)
signal boss_true_form_revealed(boss_id: String, world_position: Vector2)

var enemy_scene := preload("res://scenes/enemy/Enemy.tscn")

var player: Node2D
var rng: RandomNumberGenerator
var elapsed_time := 0.0
var spawn_timer := 0.0
var noise_factor := 0.0
var active_enemies: Array = []
var pursuer_cooldown_remaining := 0.0
var current_spawn_rate_multiplier := 1.0
var current_spawn_cap_multiplier := 1.0
var current_pursuer_chance := 0.0
var noise_spawn_rate_multiplier := 1.0
var noise_spawn_cap_multiplier := 1.0
var noise_pursuer_chance := 0.0
var map_spawn_rate_multiplier := 1.0
var map_spawn_cap_multiplier := 1.0
var map_pursuer_chance_add := 0.0
var map_elite_chance_add := 0.0
var map_enemy_speed_multiplier := 1.0
var contract_spawn_rate_multiplier := 1.0
var contract_spawn_cap_multiplier := 1.0
var contract_pursuer_chance_add := 0.0
var contract_elite_chance_add := 0.0
var contract_enemy_speed_multiplier := 1.0
var current_elite_chance := 0.0
var current_enemy_speed_multiplier := 1.0
var active_elite_count := 0
var active_pursuer_count := 0
var pursuer_spawned_total := 0
var next_pursuer_eta := -1.0
var elite_pursuer_bonus_runtime := 0.0
var elite_jam_multiplier_runtime := 1.0
var boss_spawn_rate_multiplier := 1.0
var boss_state: String = "idle"
var boss_definition: Dictionary = {}
var boss_id: String = ""
var boss_node: Node = null
var boss_phase_index: int = -1
var boss_summon_timer: float = 0.0
var pool_manager: Node = null
var enemy_pool_key: String = "enemy"
var enemy_pool_enabled: bool = false


func setup_pool(pool_manager_ref: Node, key: String = "enemy", prewarm_size: int = 72) -> void:
	pool_manager = pool_manager_ref
	enemy_pool_key = key
	enemy_pool_enabled = (
		pool_manager != null
		and pool_manager.has_method("ensure_pool")
		and pool_manager.has_method("checkout")
		and pool_manager.has_method("recycle")
	)
	if enemy_pool_enabled:
		pool_manager.ensure_pool(enemy_pool_key, enemy_scene, self, maxi(0, prewarm_size))


func setup(player_ref: Node2D, run_rng: RandomNumberGenerator) -> void:
	_clear_all_active_enemies()
	player = player_ref
	rng = run_rng
	elapsed_time = 0.0
	spawn_timer = 0.0
	noise_factor = 0.0
	pursuer_cooldown_remaining = 0.0
	current_spawn_rate_multiplier = 1.0
	current_spawn_cap_multiplier = 1.0
	current_pursuer_chance = 0.0
	noise_spawn_rate_multiplier = 1.0
	noise_spawn_cap_multiplier = 1.0
	noise_pursuer_chance = 0.0
	map_spawn_rate_multiplier = 1.0
	map_spawn_cap_multiplier = 1.0
	map_pursuer_chance_add = 0.0
	map_elite_chance_add = 0.0
	map_enemy_speed_multiplier = 1.0
	contract_spawn_rate_multiplier = 1.0
	contract_spawn_cap_multiplier = 1.0
	contract_pursuer_chance_add = 0.0
	contract_elite_chance_add = 0.0
	contract_enemy_speed_multiplier = 1.0
	current_elite_chance = DataRegistry.get_default_elite_chance()
	current_enemy_speed_multiplier = 1.0
	active_elite_count = 0
	active_pursuer_count = 0
	pursuer_spawned_total = 0
	next_pursuer_eta = -1.0
	elite_pursuer_bonus_runtime = 0.0
	elite_jam_multiplier_runtime = 1.0
	boss_spawn_rate_multiplier = 1.0
	boss_state = "idle"
	boss_id = ""
	boss_definition.clear()
	boss_node = null
	boss_phase_index = -1
	boss_summon_timer = 0.0
	active_enemies.clear()
	var bosses: Array = DataRegistry.get_bosses()
	if not bosses.is_empty() and bosses[0] is Dictionary:
		boss_definition = (bosses[0] as Dictionary).duplicate(true)
		boss_id = String(boss_definition.get("id", "")).strip_edges()


func update_difficulty(elapsed: float, noise: float) -> void:
	elapsed_time = elapsed
	noise_factor = noise


func _process(delta: float) -> void:
	if player == null or not is_instance_valid(player) or rng == null:
		return

	pursuer_cooldown_remaining = maxf(0.0, pursuer_cooldown_remaining - delta)
	_refresh_live_enemy_counters()
	var noise_modifiers := DataRegistry.get_noise_spawn_modifiers(noise_factor)
	noise_spawn_rate_multiplier = float(noise_modifiers.get("spawn_rate_multiplier", 1.0))
	noise_spawn_cap_multiplier = float(noise_modifiers.get("spawn_cap_multiplier", 1.0))
	noise_pursuer_chance = float(noise_modifiers.get("pursuer_chance", 0.0))
	current_spawn_rate_multiplier = noise_spawn_rate_multiplier * map_spawn_rate_multiplier * contract_spawn_rate_multiplier * boss_spawn_rate_multiplier
	current_spawn_cap_multiplier = noise_spawn_cap_multiplier * map_spawn_cap_multiplier * contract_spawn_cap_multiplier
	current_elite_chance = clampf(
		DataRegistry.get_default_elite_chance() + map_elite_chance_add + contract_elite_chance_add,
		0.0,
		0.95
	)
	current_enemy_speed_multiplier = maxf(0.05, map_enemy_speed_multiplier * contract_enemy_speed_multiplier)
	current_pursuer_chance = clampf(
		noise_pursuer_chance + map_pursuer_chance_add + contract_pursuer_chance_add + elite_pursuer_bonus_runtime,
		0.0,
		1.0
	)
	_update_next_pursuer_eta()

	spawn_timer -= delta
	var spawn_rate: float = DataRegistry.get_spawn_rate(elapsed_time, 0.0) * current_spawn_rate_multiplier
	var spawn_interval: float = 1.0 / maxf(0.05, spawn_rate)
	var enemy_cap := int(round(DataRegistry.get_enemy_cap(elapsed_time, 0.0) * current_spawn_cap_multiplier))

	while spawn_timer <= 0.0:
		spawn_timer += spawn_interval
		if _get_alive_enemy_count() >= enemy_cap:
			break
		_spawn_enemy()

	_try_spawn_pursuer(delta)
	_try_spawn_boss(delta)
	_update_boss_phase(delta)


func get_priority_target(origin: Vector2) -> Node2D:
	var best: Node2D = null
	var best_score: float = -INF
	for enemy in active_enemies:
		if enemy == null or not is_instance_valid(enemy):
			continue
		var score: float = enemy.get_threat_score(origin)
		if enemy.has_method("get_elite_jam_multiplier"):
			score *= float(enemy.get_elite_jam_multiplier(origin))
		if score > best_score:
			best_score = score
			best = enemy
	return best


func get_alive_enemy_count() -> int:
	return _get_alive_enemy_count()


func get_noise_debug_snapshot() -> Dictionary:
	var enemy_pool_stats := get_enemy_pool_stats()
	return {
		"spawn_rate_multiplier": current_spawn_rate_multiplier,
		"spawn_cap_multiplier": current_spawn_cap_multiplier,
		"pursuer_chance": current_pursuer_chance,
		"noise_spawn_rate_multiplier": noise_spawn_rate_multiplier,
		"noise_spawn_cap_multiplier": noise_spawn_cap_multiplier,
		"noise_pursuer_chance": noise_pursuer_chance,
		"map_spawn_rate_multiplier": map_spawn_rate_multiplier,
		"map_spawn_cap_multiplier": map_spawn_cap_multiplier,
		"map_pursuer_chance_add": map_pursuer_chance_add,
		"map_elite_chance_add": map_elite_chance_add,
		"contract_spawn_rate_multiplier": contract_spawn_rate_multiplier,
		"contract_spawn_cap_multiplier": contract_spawn_cap_multiplier,
		"contract_pursuer_chance_add": contract_pursuer_chance_add,
		"contract_elite_chance_add": contract_elite_chance_add,
		"elite_chance": current_elite_chance,
		"elite_count": active_elite_count,
		"pursuer_count": active_pursuer_count,
		"pursuer_spawned_total": pursuer_spawned_total,
		"next_pursuer_eta": next_pursuer_eta,
		"boss_state": boss_state,
		"boss_id": boss_id,
		"boss_decoy_count": get_boss_decoy_count(),
		"boss_true_form_revealed": is_boss_true_form_revealed(),
		"boss_spawn_rate_multiplier": boss_spawn_rate_multiplier,
		"elite_jam_multiplier": elite_jam_multiplier_runtime,
		"enemy_pool_hit_rate": float(enemy_pool_stats.get("hit_rate", -1.0)),
		"enemy_pool_hits": int(enemy_pool_stats.get("hits", 0)),
		"enemy_pool_misses": int(enemy_pool_stats.get("misses", 0))
	}


func get_enemy_pool_stats() -> Dictionary:
	if pool_manager != null and pool_manager.has_method("get_stats_for_key"):
		return pool_manager.get_stats_for_key(enemy_pool_key)
	return {
		"key": enemy_pool_key,
		"hits": 0,
		"misses": 0,
		"total": 0,
		"hit_rate": -1.0
	}


func get_boss_decoy_count() -> int:
	if boss_node == null or not is_instance_valid(boss_node):
		return 0
	if boss_node.has_method("get_boss_decoy_count"):
		return int(boss_node.get_boss_decoy_count())
	return 0


func is_boss_true_form_revealed() -> bool:
	if boss_node == null or not is_instance_valid(boss_node):
		return false
	if boss_node.has_method("is_boss_true_form_revealed"):
		return bool(boss_node.is_boss_true_form_revealed())
	return false


func set_map_spawn_modifiers(modifiers: Dictionary) -> void:
	map_spawn_rate_multiplier = maxf(0.05, float(modifiers.get("spawn_rate_mult", 1.0)))
	map_spawn_cap_multiplier = maxf(0.05, float(modifiers.get("spawn_cap_mult", 1.0)))
	map_pursuer_chance_add = float(modifiers.get("pursuer_chance_add", 0.0))
	map_elite_chance_add = float(modifiers.get("elite_chance_add", 0.0))
	map_enemy_speed_multiplier = maxf(0.05, float(modifiers.get("enemy_speed_mult", 1.0)))


func set_contract_spawn_modifiers(modifiers: Dictionary) -> void:
	contract_spawn_rate_multiplier = maxf(0.05, float(modifiers.get("spawn_rate_mult", 1.0)))
	contract_spawn_cap_multiplier = maxf(0.05, float(modifiers.get("spawn_cap_mult", 1.0)))
	contract_pursuer_chance_add = float(modifiers.get("pursuer_chance_add", 0.0))
	contract_elite_chance_add = float(modifiers.get("elite_chance_add", 0.0))
	contract_enemy_speed_multiplier = maxf(0.05, float(modifiers.get("enemy_speed_mult", 1.0)))


func _spawn_enemy() -> void:
	var enemy_id := DataRegistry.pick_enemy_id(rng, elapsed_time, noise_factor)
	if enemy_id.is_empty():
		return
	var definition: Dictionary = DataRegistry.get_enemy(enemy_id)
	if definition.is_empty():
		return

	_spawn_enemy_node(enemy_id, definition, _pick_spawn_position(), true)


func _spawn_specific_enemy(enemy_id: String) -> void:
	var definition: Dictionary = DataRegistry.get_enemy(enemy_id)
	if definition.is_empty():
		return
	var spawned := _spawn_enemy_node(enemy_id, definition, _pick_spawn_position(), false)
	if spawned == null:
		return
	var spawn_group := String(definition.get("spawn_group", "normal")).strip_edges().to_lower()
	if spawn_group == "pursuer":
		pursuer_spawned_total += 1
		var noise_cfg := DataRegistry.get_noise_config()
		var pursuer_variant: Variant = noise_cfg.get("pursuer", {})
		var cooldown := 12.0
		if pursuer_variant is Dictionary:
			cooldown = maxf(0.2, float((pursuer_variant as Dictionary).get("spawn_cooldown", 12.0)))
		pursuer_cooldown_remaining = cooldown
		next_pursuer_eta = cooldown
		pursuer_spawned.emit(enemy_id, spawned.global_position, pursuer_spawned_total, next_pursuer_eta)


func _spawn_enemy_near(enemy_id: String, world_position: Vector2) -> void:
	var definition: Dictionary = DataRegistry.get_enemy(enemy_id)
	if definition.is_empty():
		return
	_spawn_enemy_node(enemy_id, definition, world_position, false)


func _try_spawn_pursuer(delta: float) -> void:
	var noise_cfg := DataRegistry.get_noise_config()
	var pursuer_variant: Variant = noise_cfg.get("pursuer", {})
	if not (pursuer_variant is Dictionary):
		return
	var pursuer: Dictionary = pursuer_variant
	var min_noise := float(pursuer.get("min_noise", 60.0))
	if noise_factor < min_noise:
		return
	if pursuer_cooldown_remaining > 0.0:
		return
	var chance := current_pursuer_chance
	if chance <= 0.0:
		return
	if rng.randf() <= chance * delta:
		var pursuer_id := String(pursuer.get("enemy_id", ""))
		if pursuer_id.is_empty():
			return
		_spawn_specific_enemy(pursuer_id)


func _pick_spawn_position() -> Vector2:
	var angle := rng.randf_range(0.0, TAU)
	var radius := rng.randf_range(520.0, 760.0)
	return player.global_position + Vector2.RIGHT.rotated(angle) * radius


func _on_enemy_died(enemy_id: String, xp_reward: int, enemy: Node) -> void:
	var position: Vector2 = Vector2.ZERO
	var meta := {
		"is_elite": false,
		"is_pursuer": false,
		"is_boss": false,
		"spawn_group": "normal",
		"affix_id": ""
	}
	if enemy != null and is_instance_valid(enemy):
		position = enemy.global_position
		meta["is_elite"] = bool(enemy.get("is_elite"))
		var spawn_group_variant: Variant = enemy.get("spawn_group")
		meta["spawn_group"] = String(spawn_group_variant) if spawn_group_variant != null else "normal"
		meta["is_pursuer"] = bool(enemy.is_in_group("pursuer")) or String(meta["spawn_group"]) == "pursuer"
		var behavior_variant: Variant = enemy.get("behavior")
		meta["is_boss"] = bool(enemy.is_in_group("boss")) or String(behavior_variant) == "boss"
		var affix_variant: Variant = enemy.get("elite_affix_id")
		meta["affix_id"] = String(affix_variant) if affix_variant != null else ""
		if bool(meta["is_elite"]):
			xp_reward = int(round(float(xp_reward) * 1.12))
		if bool(meta["is_boss"]):
			boss_state = "defeated"
			boss_defeated.emit(enemy_id)
			boss_node = null
			boss_phase_index = -1
			boss_spawn_rate_multiplier = 1.0
	active_enemies.erase(enemy)
	enemy_killed.emit(enemy_id, xp_reward, position, meta)


func _get_alive_enemy_count() -> int:
	var alive := 0
	for enemy in active_enemies:
		if enemy != null and is_instance_valid(enemy):
			alive += 1
	return alive


func _bind_enemy_signals(enemy: Node) -> void:
	if enemy == null:
		return
	var died_callable := Callable(self, "_on_enemy_died").bind(enemy)
	if enemy.has_signal("died") and not enemy.is_connected("died", died_callable):
		enemy.connect("died", died_callable)
	if enemy.has_signal("summon_requested"):
		var summon_callable := Callable(self, "_on_enemy_summon_requested")
		if not enemy.is_connected("summon_requested", summon_callable):
			enemy.connect("summon_requested", summon_callable)
	if enemy.has_signal("explosion_requested"):
		var explosion_callable := Callable(self, "_on_enemy_explosion_requested")
		if not enemy.is_connected("explosion_requested", explosion_callable):
			enemy.connect("explosion_requested", explosion_callable)
	if enemy.has_signal("boss_telegraph_requested"):
		var telegraph_callable := Callable(self, "_on_boss_telegraph_requested")
		if not enemy.is_connected("boss_telegraph_requested", telegraph_callable):
			enemy.connect("boss_telegraph_requested", telegraph_callable)
	if enemy.has_signal("boss_echoes_spawned"):
		var echo_callable := Callable(self, "_on_boss_echoes_spawned")
		if not enemy.is_connected("boss_echoes_spawned", echo_callable):
			enemy.connect("boss_echoes_spawned", echo_callable)
	if enemy.has_signal("boss_true_form_revealed"):
		var reveal_callable := Callable(self, "_on_boss_true_form_revealed")
		if not enemy.is_connected("boss_true_form_revealed", reveal_callable):
			enemy.connect("boss_true_form_revealed", reveal_callable)


func _on_enemy_summon_requested(enemy_type_id: String, count: int, world_position: Vector2) -> void:
	if enemy_type_id.is_empty() or count <= 0:
		return
	var spawn_count := clampi(count, 1, 4)
	for i in range(spawn_count):
		var angle := rng.randf_range(0.0, TAU)
		var radius := rng.randf_range(26.0, 64.0)
		var pos := world_position + Vector2.RIGHT.rotated(angle) * radius
		_spawn_enemy_near(enemy_type_id, pos)


func _on_enemy_explosion_requested(world_position: Vector2, radius: float, damage: float, _source_enemy_id: String) -> void:
	if player == null or not is_instance_valid(player):
		return
	if not player.has_method("take_damage"):
		return
	if player.global_position.distance_to(world_position) <= radius:
		player.take_damage(damage)


func _on_boss_telegraph_requested(telegraph_type: String, payload: Dictionary) -> void:
	boss_telegraph_requested.emit(telegraph_type, payload.duplicate(true))


func _on_boss_echoes_spawned(count: int, world_position: Vector2) -> void:
	if boss_id.is_empty():
		return
	boss_echoes_spawned.emit(boss_id, maxi(0, count), world_position)


func _on_boss_true_form_revealed(world_position: Vector2) -> void:
	if boss_id.is_empty():
		return
	boss_true_form_revealed.emit(boss_id, world_position)


func _spawn_enemy_node(enemy_id: String, definition: Dictionary, world_position: Vector2, allow_elite: bool) -> Node:
	var enemy: Node = null
	if enemy_pool_enabled and pool_manager != null and pool_manager.has_method("checkout"):
		enemy = pool_manager.checkout(enemy_pool_key, self)
	if enemy == null:
		enemy = enemy_scene.instantiate()
		add_child(enemy)
	if enemy.has_method("set_recycle_handler"):
		enemy.set_recycle_handler(Callable(self, "_on_enemy_recycle_requested"))
	enemy.global_position = world_position
	_bind_enemy_signals(enemy)
	var runtime_modifiers := {
		"speed_mult": current_enemy_speed_multiplier
	}
	enemy.setup(enemy_id, definition, player, runtime_modifiers)
	if allow_elite and _can_become_elite(definition):
		_try_apply_elite(enemy)
	active_enemies.append(enemy)
	return enemy


func _on_enemy_recycle_requested(enemy: Node) -> void:
	_recycle_enemy(enemy)


func _can_become_elite(definition: Dictionary) -> bool:
	var spawn_group := String(definition.get("spawn_group", "normal")).strip_edges().to_lower()
	if spawn_group != "normal":
		return false
	var behavior := String(definition.get("behavior", "drifter")).strip_edges().to_lower()
	if behavior == "boss" or behavior == "pursuer":
		return false
	return true


func _try_apply_elite(enemy: Node) -> void:
	if enemy == null or not is_instance_valid(enemy):
		return
	var max_active := DataRegistry.get_max_active_elites()
	if max_active > 0 and active_elite_count >= max_active:
		return
	if current_elite_chance <= 0.0:
		return
	if rng.randf() > current_elite_chance:
		return
	var affixes: Array = DataRegistry.get_elite_affixes()
	if affixes.is_empty():
		return
	var index := rng.randi_range(0, affixes.size() - 1)
	var affix_variant: Variant = affixes[index]
	if not (affix_variant is Dictionary):
		return
	if enemy.has_method("apply_elite_affix"):
		enemy.apply_elite_affix(affix_variant)


func _refresh_live_enemy_counters() -> void:
	active_elite_count = 0
	active_pursuer_count = 0
	elite_pursuer_bonus_runtime = 0.0
	elite_jam_multiplier_runtime = 1.0
	var player_pos := player.global_position if player != null and is_instance_valid(player) else Vector2.ZERO
	var compact: Array = []
	for enemy in active_enemies:
		if enemy == null or not is_instance_valid(enemy):
			continue
		compact.append(enemy)
		if bool(enemy.get("is_elite")):
			active_elite_count += 1
			if enemy.has_method("get_pursuer_bonus"):
				elite_pursuer_bonus_runtime += maxf(0.0, float(enemy.get_pursuer_bonus()))
			if enemy.has_method("get_elite_jam_multiplier"):
				elite_jam_multiplier_runtime *= clampf(float(enemy.get_elite_jam_multiplier(player_pos)), 0.25, 1.0)
		if enemy.is_in_group("pursuer"):
			active_pursuer_count += 1
	active_enemies = compact


func _update_next_pursuer_eta() -> void:
	if pursuer_cooldown_remaining > 0.0:
		next_pursuer_eta = pursuer_cooldown_remaining
		return
	if current_pursuer_chance <= 0.0001:
		next_pursuer_eta = -1.0
		return
	next_pursuer_eta = clampf(1.0 / maxf(current_pursuer_chance, 0.0001), 0.1, 60.0)


func _try_spawn_boss(_delta: float) -> void:
	if boss_definition.is_empty() or boss_id.is_empty():
		return
	if boss_node != null and is_instance_valid(boss_node):
		return
	var spawn_time := float(boss_definition.get("spawn_time_seconds", INF))
	if elapsed_time < spawn_time:
		return
	var enemy_def := _build_boss_enemy_definition()
	if enemy_def.is_empty():
		return
	var spawned := _spawn_enemy_node(boss_id, enemy_def, _pick_spawn_position(), false)
	if spawned == null:
		return
	boss_node = spawned
	boss_phase_index = 0
	boss_state = "phase_1"
	boss_spawn_rate_multiplier = maxf(0.05, float(enemy_def.get("spawn_rate_mult", 1.0)))
	var phase := _get_boss_phase(0)
	var telegraph := String(phase.get("telegraph_text", "Boss incoming")).strip_edges()
	boss_spawned.emit(boss_id, String(phase.get("id", "phase_1")), telegraph)


func _update_boss_phase(delta: float) -> void:
	if boss_node == null or not is_instance_valid(boss_node):
		return
	var hp_ratio := 1.0
	if boss_node.has_method("get_hp_ratio"):
		hp_ratio = float(boss_node.get_hp_ratio())
	var phases_variant: Variant = boss_definition.get("phases", [])
	if not (phases_variant is Array):
		return
	var phases: Array = phases_variant
	if phases.size() < 2:
		return
	for i in range(boss_phase_index + 1, phases.size()):
		var phase_variant: Variant = phases[i]
		if not (phase_variant is Dictionary):
			continue
		var phase: Dictionary = phase_variant
		var threshold := float(phase.get("start_hp_ratio", 0.0))
		if hp_ratio <= threshold:
			_apply_boss_phase(i, phase)
			break

	if boss_summon_timer > 0.0:
		boss_summon_timer = maxf(0.0, boss_summon_timer - delta)
	if boss_summon_timer <= 0.0:
		var current_phase := _get_boss_phase(boss_phase_index)
		boss_summon_timer = maxf(0.3, float(current_phase.get("summon_interval", 7.5)))
		_spawn_boss_adds(current_phase)


func _apply_boss_phase(next_index: int, phase: Dictionary) -> void:
	if boss_node == null or not is_instance_valid(boss_node):
		return
	var runtime_phase := phase.duplicate(true)
	if String(runtime_phase.get("id", "")).strip_edges() == "phase_2":
		var base_echoes := maxi(2, int(boss_definition.get("fake_echoes", 2)))
		runtime_phase["echo_count"] = clampi(base_echoes + rng.randi_range(0, 1), 2, 3)
	boss_phase_index = next_index
	boss_state = String(runtime_phase.get("label", "phase_%d" % (next_index + 1))).strip_edges()
	if boss_node.has_method("apply_boss_phase"):
		boss_node.apply_boss_phase(runtime_phase, boss_definition)
	boss_spawn_rate_multiplier = maxf(0.05, float(runtime_phase.get("spawn_rate_mult", 1.0)))
	boss_summon_timer = maxf(0.1, float(runtime_phase.get("summon_interval", 6.0)))
	var telegraph := String(runtime_phase.get("telegraph_text", "Boss phase shift")).strip_edges()
	boss_phase_changed.emit(boss_id, String(runtime_phase.get("id", "phase_%d" % (next_index + 1))), telegraph)
	var transition_noise := float(boss_definition.get("phase_transition_noise_delta", 0.0))
	if transition_noise > 0.0 and player != null and is_instance_valid(player) and player.has_method("add_noise_delta"):
		player.add_noise_delta(transition_noise)
	if String(runtime_phase.get("id", "")).strip_edges() == "phase_2":
		pursuer_cooldown_remaining = minf(pursuer_cooldown_remaining, 0.2)


func _spawn_boss_adds(phase: Dictionary) -> void:
	if boss_node == null or not is_instance_valid(boss_node):
		return
	var summon_pool_variant: Variant = boss_definition.get("summon_pool", [])
	if not (summon_pool_variant is Array):
		return
	var summon_pool: Array = summon_pool_variant
	if summon_pool.is_empty():
		return
	var count := maxi(0, int(phase.get("summon_count", 0)))
	for i in range(count):
		var pick := rng.randi_range(0, summon_pool.size() - 1)
		var enemy_id := String(summon_pool[pick]).strip_edges()
		if enemy_id.is_empty():
			continue
		var angle := rng.randf_range(0.0, TAU)
		var radius := rng.randf_range(120.0, 210.0)
		var position: Vector2 = boss_node.global_position + Vector2.RIGHT.rotated(angle) * radius
		_spawn_enemy_near(enemy_id, position)


func _build_boss_enemy_definition() -> Dictionary:
	var phase := _get_boss_phase(0)
	if phase.is_empty():
		return {}
	return {
		"id": boss_id,
		"name": String(boss_definition.get("name", "Boss")),
		"behavior": "boss",
		"spawn_group": "boss",
		"max_hp": float(boss_definition.get("max_hp", 2000.0)),
		"speed": float(boss_definition.get("speed", 62.0)),
		"damage": float(boss_definition.get("damage", 22.0)),
		"xp_reward": int(boss_definition.get("xp_reward", 300)),
		"contact_cooldown": 0.6,
		"threat": 4.5,
		"size": float(boss_definition.get("size", 44.0)),
		"color": String(boss_definition.get("color", "#ff7fb9")),
		"tags": ["boss", "elite"],
		"noise_aggression_scale": 0.0,
		"reveal_reaction": "none",
		"reveal_reaction_duration": 0.0,
		"ranged_range": 460.0,
		"ranged_cooldown": float(phase.get("attack_interval", 2.2)),
		"ranged_damage": float(boss_definition.get("damage", 22.0)),
		"summon_interval": float(phase.get("summon_interval", 8.0)),
		"summon_count": int(phase.get("summon_count", 2)),
		"initial_phase": phase.duplicate(true),
		"fake_echoes": int(boss_definition.get("fake_echoes", 2)),
		"telegraph_color": String(boss_definition.get("telegraph_color", "#8be8ff")),
		"hidden_damage_multiplier": 0.35,
		"spawn_rate_mult": float(phase.get("spawn_rate_mult", 1.0))
	}


func _get_boss_phase(index: int) -> Dictionary:
	var phases_variant: Variant = boss_definition.get("phases", [])
	if not (phases_variant is Array):
		return {}
	var phases: Array = phases_variant
	if index < 0 or index >= phases.size():
		return {}
	var phase_variant: Variant = phases[index]
	if phase_variant is Dictionary:
		return (phase_variant as Dictionary).duplicate(true)
	return {}


func _clear_all_active_enemies() -> void:
	var seen: Dictionary = {}
	for enemy in active_enemies:
		if enemy == null or not is_instance_valid(enemy):
			continue
		seen[int(enemy.get_instance_id())] = true
		_recycle_enemy(enemy)
	for child in get_children():
		if child == null or not is_instance_valid(child):
			continue
		if not child.is_in_group("enemy"):
			continue
		if seen.has(int(child.get_instance_id())):
			continue
		_recycle_enemy(child)
	active_enemies.clear()
	active_elite_count = 0
	active_pursuer_count = 0
	elite_pursuer_bonus_runtime = 0.0
	elite_jam_multiplier_runtime = 1.0


func _recycle_enemy(enemy: Node) -> void:
	if enemy == null or not is_instance_valid(enemy):
		return
	active_enemies.erase(enemy)
	if enemy == boss_node:
		boss_node = null
		boss_phase_index = -1
		boss_state = "idle"
		boss_spawn_rate_multiplier = 1.0
	if enemy_pool_enabled and pool_manager != null and pool_manager.has_method("recycle"):
		pool_manager.recycle(enemy_pool_key, enemy)
	else:
		enemy.queue_free()
