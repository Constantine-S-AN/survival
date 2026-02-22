extends CharacterBody2D
class_name Enemy

signal died(enemy_id: String, xp_reward: int)

var enemy_id := "drone_scout"
var max_hp := 20.0
var hp := 20.0
var speed := 100.0
var contact_damage := 8.0
var contact_cooldown := 0.7
var threat := 1.0
var xp_reward := 5
var body_radius := 14.0
var knockback_velocity := Vector2.ZERO
var contact_timer := 0.0
var target: Node2D

@onready var body_visual: Polygon2D = $Body
@onready var collision_shape: CollisionShape2D = $CollisionShape2D


func setup(new_enemy_id: String, definition: Dictionary, player_target: Node2D) -> void:
	enemy_id = new_enemy_id
	target = player_target
	max_hp = float(definition.get("max_hp", max_hp))
	hp = max_hp
	speed = float(definition.get("speed", speed))
	contact_damage = float(definition.get("damage", contact_damage))
	contact_cooldown = float(definition.get("contact_cooldown", contact_cooldown))
	threat = float(definition.get("threat", threat))
	xp_reward = int(definition.get("xp_reward", xp_reward))
	body_radius = float(definition.get("size", body_radius))
	var color_text := String(definition.get("color", "#38e7ff"))
	body_visual.color = Color.from_string(color_text, Color(0.22, 0.9, 1.0, 1.0))

	var shape := collision_shape.shape
	if shape is CircleShape2D:
		shape.radius = body_radius
	body_visual.scale = Vector2.ONE * (body_radius / 15.0)

	add_to_group("enemy")


func _physics_process(delta: float) -> void:
	if target == null or not is_instance_valid(target):
		return

	contact_timer = max(0.0, contact_timer - delta)

	var to_target := target.global_position - global_position
	var dir := to_target.normalized() if to_target.length() > 0.01 else Vector2.ZERO
	velocity = (dir * speed) + knockback_velocity
	knockback_velocity = knockback_velocity.move_toward(Vector2.ZERO, 640.0 * delta)
	move_and_slide()

	if to_target.length() <= body_radius + 13.0 and contact_timer <= 0.0:
		if target.has_method("take_damage"):
			target.take_damage(contact_damage)
		contact_timer = contact_cooldown


func get_threat_score(reference_position: Vector2) -> float:
	var distance: float = maxf(32.0, global_position.distance_to(reference_position))
	return threat + (160.0 / distance)


func take_hit(damage: float, impulse: Vector2 = Vector2.ZERO) -> bool:
	hp -= damage
	knockback_velocity += impulse
	_flash_hit()
	if hp <= 0.0:
		died.emit(enemy_id, xp_reward)
		queue_free()
		return true
	return false


func _flash_hit() -> void:
	body_visual.modulate = Color(1.6, 1.6, 1.6, 1.0)
	var tween := create_tween()
	tween.tween_property(body_visual, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.08)
