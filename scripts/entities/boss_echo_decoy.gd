extends CharacterBody2D
class_name BossEchoDecoy

signal faded(world_position: Vector2)

var life_time: float = 8.0
var fading: bool = false

@onready var outline_visual: Polygon2D = $Outline
@onready var body_visual: Polygon2D = $Body
@onready var collision_shape: CollisionShape2D = $CollisionShape2D


func _ready() -> void:
	add_to_group("enemy")
	add_to_group("boss_echo")


func configure(origin: Vector2, base_color: Color, radius: float, ttl: float = 8.0) -> void:
	global_position = origin
	life_time = maxf(0.2, ttl)
	fading = false
	visible = true
	collision_layer = 2
	collision_mask = 0
	var body_color := base_color
	body_color.a = 0.26
	var outline_color := base_color.lightened(0.18)
	outline_color.a = 0.78
	body_visual.color = body_color
	outline_visual.color = outline_color
	var shape := collision_shape.shape
	if shape is CircleShape2D:
		(shape as CircleShape2D).radius = maxf(6.0, radius * 0.88)
	var scale_mult := maxf(0.5, radius / 15.0)
	body_visual.scale = Vector2.ONE * scale_mult
	outline_visual.scale = Vector2.ONE * (scale_mult * 1.18)
	set_physics_process(true)


func _physics_process(delta: float) -> void:
	if fading:
		return
	life_time -= delta
	if life_time <= 0.0:
		_force_fade(false)


func take_hit(_damage: float, _impulse: Vector2 = Vector2.ZERO) -> bool:
	if fading:
		return false
	_flash_hit()
	_force_fade(true)
	return false


func set_revealed(_duration_sec: float) -> void:
	return


func is_revealed() -> bool:
	return false


func force_dissipate() -> void:
	_force_fade(false)


func _flash_hit() -> void:
	body_visual.modulate = Color(1.8, 1.8, 1.8, 1.0)
	outline_visual.modulate = Color(1.35, 1.35, 1.35, 1.0)
	var tween := create_tween()
	tween.tween_property(body_visual, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.09)
	tween.parallel().tween_property(outline_visual, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.11)


func _force_fade(from_hit: bool) -> void:
	if fading:
		return
	fading = true
	collision_layer = 0
	remove_from_group("enemy")
	remove_from_group("boss_echo")
	set_physics_process(false)
	var tween := create_tween()
	var fade_duration := 0.12 if from_hit else 0.2
	tween.tween_property(self, "modulate:a", 0.0, fade_duration)
	tween.finished.connect(func() -> void:
		faded.emit(global_position)
		queue_free()
	)
