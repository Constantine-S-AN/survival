extends Camera2D
class_name CameraShake

@export var decay: float = 3.2
@export var max_offset: Vector2 = Vector2(16.0, 11.0)
@export var max_rotation: float = 0.04
@export var pixel_snap_step: float = 0.25

var trauma: float = 0.0
var tick: float = 0.0
var noise := FastNoiseLite.new()


func _ready() -> void:
	noise.seed = int(Time.get_ticks_usec() % 100000)
	noise.frequency = 0.12


func add_trauma(amount: float) -> void:
	trauma = clampf(trauma + amount, 0.0, 1.0)


func _process(delta: float) -> void:
	tick += delta * 60.0
	if trauma <= 0.0:
		offset = _snap_offset(offset.lerp(Vector2.ZERO, minf(1.0, delta * 15.0)))
		rotation = lerpf(rotation, 0.0, minf(1.0, delta * 15.0))
		return

	trauma = maxf(0.0, trauma - decay * delta)
	var shake: float = trauma * trauma
	var target_offset := Vector2(
		noise.get_noise_2d(0.0, tick),
		noise.get_noise_2d(73.0, tick)
	) * max_offset * shake
	var blend := minf(1.0, delta * (18.0 + 30.0 * shake))
	offset = _snap_offset(offset.lerp(target_offset, blend))
	var target_rotation := noise.get_noise_2d(141.0, tick) * max_rotation * shake
	rotation = lerpf(rotation, target_rotation, blend)


func _snap_offset(value: Vector2) -> Vector2:
	if pixel_snap_step <= 0.0:
		return value
	return Vector2(
		round(value.x / pixel_snap_step) * pixel_snap_step,
		round(value.y / pixel_snap_step) * pixel_snap_step
	)
