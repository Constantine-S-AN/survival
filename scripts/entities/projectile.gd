extends Area2D
class_name Projectile

var direction := Vector2.RIGHT
var speed := 520.0
var damage := 10.0
var remaining_range := 600.0
var radius := 6.0
var pierce := 0
var hit_count := 0
var source_owner: Node = null
var recycle_handler: Callable = Callable()
var active: bool = false

@onready var body_visual: Polygon2D = $Body
@onready var collision_shape: CollisionShape2D = $CollisionShape2D


func _ready() -> void:
	on_pool_recycle()


func set_recycle_handler(handler: Callable) -> void:
	recycle_handler = handler


func configure(origin: Vector2, fire_direction: Vector2, projectile_data: Dictionary, owner_ref: Node) -> void:
	global_position = origin
	hit_count = 0
	direction = fire_direction.normalized() if fire_direction.length() > 0.01 else Vector2.RIGHT
	speed = float(projectile_data.get("speed", speed))
	damage = float(projectile_data.get("damage", damage))
	remaining_range = float(projectile_data.get("range", remaining_range))
	pierce = int(projectile_data.get("pierce", pierce))
	radius = float(projectile_data.get("radius", radius))
	source_owner = owner_ref

	var shape := collision_shape.shape
	if shape is CircleShape2D:
		shape.radius = radius
	body_visual.scale = Vector2.ONE * (radius / 6.0)

	rotation = direction.angle()
	on_pool_spawned()


func _physics_process(delta: float) -> void:
	if not active:
		return
	var motion := direction * speed * delta
	global_position += motion
	remaining_range -= motion.length()
	if remaining_range <= 0.0:
		_request_recycle()


func _on_body_entered(body: Node) -> void:
	if not active:
		return
	if body == source_owner:
		return
	if body.is_in_group("enemy") and body.has_method("take_hit"):
		var killed := bool(body.take_hit(damage, direction * 180.0))
		var intensity := clampf((damage / 34.0) + (0.07 if killed else 0.0), 0.08, 0.34)
		FeedbackBus.emit_hit(global_position, intensity, killed)
		hit_count += 1
		if hit_count > pierce:
			_request_recycle()


func on_pool_spawned() -> void:
	active = true
	set_deferred("monitoring", true)
	set_deferred("monitorable", true)
	set_physics_process(true)
	visible = true


func on_pool_recycle() -> void:
	active = false
	set_deferred("monitoring", false)
	set_deferred("monitorable", false)
	set_physics_process(false)
	source_owner = null
	visible = false


func _request_recycle() -> void:
	if not active:
		return
	active = false
	set_physics_process(false)
	set_deferred("monitoring", false)
	set_deferred("monitorable", false)
	call_deferred("_dispatch_recycle_request")


func _dispatch_recycle_request() -> void:
	if recycle_handler.is_valid():
		recycle_handler.call(self)
		return
	queue_free()
