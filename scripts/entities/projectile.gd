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

@onready var body_visual: Polygon2D = $Body
@onready var collision_shape: CollisionShape2D = $CollisionShape2D


func configure(origin: Vector2, fire_direction: Vector2, projectile_data: Dictionary, owner_ref: Node) -> void:
	global_position = origin
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


func _physics_process(delta: float) -> void:
	var motion := direction * speed * delta
	global_position += motion
	remaining_range -= motion.length()
	if remaining_range <= 0.0:
		queue_free()


func _on_body_entered(body: Node) -> void:
	if body == source_owner:
		return
	if body.is_in_group("enemy") and body.has_method("take_hit"):
		var killed := bool(body.take_hit(damage, direction * 180.0))
		var intensity := clampf((damage / 34.0) + (0.07 if killed else 0.0), 0.08, 0.34)
		FeedbackBus.emit_hit(global_position, intensity, killed)
		hit_count += 1
		if hit_count > pierce:
			queue_free()
