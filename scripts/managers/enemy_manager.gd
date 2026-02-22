extends Node2D
class_name EnemyManager

signal enemy_killed(enemy_id: String, xp_reward: int, world_position: Vector2)

var enemy_scene := preload("res://scenes/enemy/Enemy.tscn")

var player: Node2D
var rng: RandomNumberGenerator
var elapsed_time := 0.0
var spawn_timer := 0.0
var noise_factor := 0.0
var active_enemies: Array = []


func setup(player_ref: Node2D, run_rng: RandomNumberGenerator) -> void:
	player = player_ref
	rng = run_rng
	elapsed_time = 0.0
	spawn_timer = 0.0
	noise_factor = 0.0
	active_enemies.clear()


func update_difficulty(elapsed: float, noise: float) -> void:
	elapsed_time = elapsed
	noise_factor = noise


func _process(delta: float) -> void:
	if player == null or not is_instance_valid(player) or rng == null:
		return

	spawn_timer -= delta
	var spawn_rate: float = DataRegistry.get_spawn_rate(elapsed_time, noise_factor)
	var spawn_interval: float = 1.0 / maxf(0.05, spawn_rate)

	while spawn_timer <= 0.0:
		spawn_timer += spawn_interval
		if _get_alive_enemy_count() >= DataRegistry.get_enemy_cap(elapsed_time, noise_factor):
			break
		_spawn_enemy()


func get_priority_target(origin: Vector2) -> Node2D:
	var best: Node2D = null
	var best_score: float = -INF
	for enemy in active_enemies:
		if enemy == null or not is_instance_valid(enemy):
			continue
		var score: float = enemy.get_threat_score(origin)
		if score > best_score:
			best_score = score
			best = enemy
	return best


func get_alive_enemy_count() -> int:
	return _get_alive_enemy_count()


func _spawn_enemy() -> void:
	var enemy_id := DataRegistry.pick_enemy_id(rng, elapsed_time, noise_factor)
	if enemy_id.is_empty():
		return
	var definition: Dictionary = DataRegistry.get_enemy(enemy_id)
	if definition.is_empty():
		return

	var enemy = enemy_scene.instantiate()
	add_child(enemy)
	enemy.global_position = _pick_spawn_position()
	enemy.setup(enemy_id, definition, player)
	enemy.died.connect(_on_enemy_died.bind(enemy))
	active_enemies.append(enemy)


func _pick_spawn_position() -> Vector2:
	var angle := rng.randf_range(0.0, TAU)
	var radius := rng.randf_range(520.0, 760.0)
	return player.global_position + Vector2.RIGHT.rotated(angle) * radius


func _on_enemy_died(enemy_id: String, xp_reward: int, enemy: Node) -> void:
	var position: Vector2 = Vector2.ZERO
	if enemy != null and is_instance_valid(enemy):
		position = enemy.global_position
	active_enemies.erase(enemy)
	enemy_killed.emit(enemy_id, xp_reward, position)


func _get_alive_enemy_count() -> int:
	var alive := 0
	for enemy in active_enemies:
		if enemy != null and is_instance_valid(enemy):
			alive += 1
	return alive
