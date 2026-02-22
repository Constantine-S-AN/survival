extends Node2D
class_name ProjectileManager

var projectile_scene := preload("res://scenes/projectile/Projectile.tscn")
var active_projectiles: int = 0


func spawn_projectile(origin: Vector2, fire_direction: Vector2, projectile_data: Dictionary, owner: Node = null) -> void:
	var projectile = projectile_scene.instantiate()
	add_child(projectile)
	projectile.configure(origin, fire_direction, projectile_data, owner)
	active_projectiles += 1
	projectile.tree_exited.connect(_on_projectile_removed)


func _on_projectile_removed() -> void:
	active_projectiles = max(0, active_projectiles - 1)
