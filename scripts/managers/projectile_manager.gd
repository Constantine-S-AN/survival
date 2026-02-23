extends Node2D
class_name ProjectileManager

var projectile_scene := preload("res://scenes/projectile/Projectile.tscn")
var active_projectiles: int = 0
var pool_manager: Node = null
var pool_key: String = "projectile"


func spawn_projectile(origin: Vector2, fire_direction: Vector2, projectile_data: Dictionary, owner: Node = null) -> void:
	var projectile: Node = null
	if pool_manager != null and pool_manager.has_method("checkout"):
		projectile = pool_manager.checkout(pool_key, self)
	if projectile == null:
		projectile = projectile_scene.instantiate()
		add_child(projectile)
	if projectile.has_method("set_recycle_handler"):
		projectile.set_recycle_handler(Callable(self, "_on_projectile_recycle_requested"))
	projectile.configure(origin, fire_direction, projectile_data, owner)
	active_projectiles += 1


func setup_pool(pool_manager_ref: Node, key: String = "projectile", prewarm_size: int = 64) -> void:
	pool_manager = pool_manager_ref
	pool_key = key
	if pool_manager != null and pool_manager.has_method("ensure_pool"):
		pool_manager.ensure_pool(pool_key, projectile_scene, self, prewarm_size)


func _on_projectile_recycle_requested(projectile: Node) -> void:
	active_projectiles = max(0, active_projectiles - 1)
	if projectile == null:
		return
	if pool_manager != null and pool_manager.has_method("recycle"):
		pool_manager.recycle(pool_key, projectile)
	else:
		projectile.queue_free()
