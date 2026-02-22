extends Area2D
class_name XPPickup

var xp_amount: int = 1
var seek_speed: float = 320.0
var magnet_radius: float = 170.0
var source: String = "pickup"
var player: Node2D = null

@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var body_visual: Polygon2D = $Body


func _ready() -> void:
	add_to_group("pickup")
	body_entered.connect(_on_body_entered)


func setup(amount: int, player_ref: Node2D) -> void:
	xp_amount = max(1, amount)
	player = player_ref
	var radius := 6.0 + minf(7.0, float(xp_amount) * 0.25)
	var shape := collision_shape.shape
	if shape is CircleShape2D:
		shape.radius = radius
	body_visual.scale = Vector2.ONE * (radius / 7.0)


func _physics_process(delta: float) -> void:
	if player == null or not is_instance_valid(player):
		return
	var distance := global_position.distance_to(player.global_position)
	if distance <= magnet_radius:
		global_position = global_position.move_toward(player.global_position, seek_speed * delta)


func _on_body_entered(body: Node) -> void:
	if player == null or not is_instance_valid(player):
		return
	if body != player:
		return
	if player.has_method("gain_xp"):
		player.gain_xp(xp_amount)
	FeedbackBus.emit_sonar_pulse(global_position, {
		"source": source
	})
	queue_free()
