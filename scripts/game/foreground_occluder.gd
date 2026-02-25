extends Area2D
class_name ForegroundOccluder

@export var fade_alpha: float = 0.36
@export var fade_duration: float = 0.12

var _target: CanvasItem
var _default_modulate: Color = Color(1.0, 1.0, 1.0, 1.0)
var _occupants: Dictionary = {}
var _fade_tween: Tween


func configure(target: CanvasItem, trigger_size: Vector2, trigger_offset: Vector2 = Vector2.ZERO) -> void:
	_target = target
	position = trigger_offset
	if _target != null and is_instance_valid(_target):
		_default_modulate = _target.modulate
	else:
		_default_modulate = Color(1.0, 1.0, 1.0, 1.0)

	var collider := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(maxf(8.0, trigger_size.x), maxf(8.0, trigger_size.y))
	collider.shape = shape
	add_child(collider)

	collision_layer = 0
	collision_mask = 1
	monitoring = true
	monitorable = false
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _on_body_entered(body: Node) -> void:
	if body == null or not is_instance_valid(body) or not body.is_in_group("player"):
		return
	_occupants[int(body.get_instance_id())] = true
	_apply_fade_state()


func _on_body_exited(body: Node) -> void:
	if body == null or not is_instance_valid(body):
		return
	_occupants.erase(int(body.get_instance_id()))
	_apply_fade_state()


func _apply_fade_state() -> void:
	if _target == null or not is_instance_valid(_target):
		return
	if _fade_tween != null and is_instance_valid(_fade_tween):
		_fade_tween.kill()
	var target_color := _default_modulate
	target_color.a = fade_alpha if not _occupants.is_empty() else _default_modulate.a
	_fade_tween = create_tween()
	_fade_tween.set_trans(Tween.TRANS_SINE)
	_fade_tween.set_ease(Tween.EASE_OUT)
	_fade_tween.tween_property(_target, "modulate", target_color, maxf(0.01, fade_duration))
