extends Area2D
class_name XPPickup

var xp_amount: int = 1
var seek_speed: float = 320.0
var magnet_radius: float = 170.0
var source: String = "pickup"
var player: Node2D = null
var recycle_handler: Callable = Callable()
var active: bool = false

@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var body_visual: Polygon2D = $Body


func _ready() -> void:
	add_to_group("pickup")
	body_entered.connect(_on_body_entered)
	on_pool_recycle()


func set_recycle_handler(handler: Callable) -> void:
	recycle_handler = handler


func setup(amount: int, player_ref: Node2D) -> void:
	xp_amount = max(1, amount)
	player = player_ref
	var radius := 6.0 + minf(7.0, float(xp_amount) * 0.25)
	var shape := collision_shape.shape
	if shape is CircleShape2D:
		shape.radius = radius
	body_visual.scale = Vector2.ONE * (radius / 7.0)
	on_pool_spawned()


func _physics_process(delta: float) -> void:
	if not active:
		return
	if player == null or not is_instance_valid(player):
		return
	var distance := global_position.distance_to(player.global_position)
	if distance <= magnet_radius:
		global_position = global_position.move_toward(player.global_position, seek_speed * delta)


func _on_body_entered(body: Node) -> void:
	if not active:
		return
	if player == null or not is_instance_valid(player):
		return
	if body != player:
		return
	if player.has_method("gain_xp"):
		player.gain_xp(xp_amount)
	FeedbackBus.emit_sonar_pulse(global_position, {
		"source": source
	})
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
	player = null
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
