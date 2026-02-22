extends Node2D
class_name World

@onready var projectile_manager = $ProjectileManager
@onready var enemy_manager = $EnemyManager
@onready var player = $Player


func _ready() -> void:
	queue_redraw()


func setup_run(run_rng: RandomNumberGenerator) -> void:
	player.setup(enemy_manager, projectile_manager, run_rng)
	enemy_manager.setup(player, run_rng)


func _draw() -> void:
	draw_rect(Rect2(Vector2(-4200.0, -4200.0), Vector2(8400.0, 8400.0)), Color(0.015, 0.03, 0.055, 1.0), true)
	for i in range(-30, 31):
		var x := float(i) * 240.0
		draw_line(Vector2(x, -4200.0), Vector2(x, 4200.0), Color(0.12, 0.55, 0.78, 0.12), 1.0)
		var y := float(i) * 240.0
		draw_line(Vector2(-4200.0, y), Vector2(4200.0, y), Color(0.12, 0.55, 0.78, 0.12), 1.0)
