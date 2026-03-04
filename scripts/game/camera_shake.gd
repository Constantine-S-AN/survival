extends Camera2D
class_name CameraShake

@export var decay: float = 3.2
@export var max_offset: Vector2 = Vector2(16.0, 11.0)
@export var max_rotation: float = 0.04
@export var pixel_snap_step: float = 0.25

var trauma: float = 0.0
var tick: float = 0.0
var noise := FastNoiseLite.new()
var _freq_mult: float = 1.0
var _decay_mult: float = 1.0
var _response_mult: float = 1.0
var _rotation_mult: float = 1.0
var _axis_scale: Vector2 = Vector2.ONE
var _direction_bias: Vector2 = Vector2.ZERO
var _directional_impulse: float = 0.0
var _directional_decay: float = 9.0
var _afterimage_amount: float = 0.0
var _afterimage_energy: float = 0.0
var _afterimage_decay: float = 5.8
var _afterimage_curve: float = 1.45


func _ready() -> void:
	noise.seed = int(Time.get_ticks_usec() % 100000)
	noise.frequency = 0.12
	_reset_runtime_profile()


func add_trauma(amount: float) -> void:
	add_trauma_profile(amount, {})


func add_trauma_profile(amount: float, profile: Dictionary = {}) -> void:
	var clamped_amount := clampf(amount, 0.0, 1.0)
	if clamped_amount <= 0.0:
		return
	trauma = clampf(trauma + clamped_amount, 0.0, 1.0)
	var blend := clampf(0.34 + clamped_amount * 0.46, 0.0, 1.0)
	_freq_mult = lerpf(_freq_mult, clampf(float(profile.get("freq_mult", 1.0)), 0.45, 2.80), blend)
	_decay_mult = lerpf(_decay_mult, clampf(float(profile.get("decay_mult", 1.0)), 0.45, 2.20), blend)
	_response_mult = lerpf(_response_mult, clampf(float(profile.get("response_mult", 1.0)), 0.45, 2.10), blend)
	_rotation_mult = lerpf(_rotation_mult, clampf(float(profile.get("rotation_mult", 1.0)), 0.40, 2.20), blend)
	var axis_variant: Variant = profile.get("axis_scale", Vector2.ONE)
	var axis_scale: Vector2 = axis_variant if axis_variant is Vector2 else Vector2.ONE
	axis_scale.x = clampf(axis_scale.x, 0.4, 2.0)
	axis_scale.y = clampf(axis_scale.y, 0.4, 2.0)
	_axis_scale = _axis_scale.lerp(axis_scale, blend)
	var direction_variant: Variant = profile.get("direction", Vector2.ZERO)
	var direction: Vector2 = direction_variant if direction_variant is Vector2 else Vector2.ZERO
	if direction.length() > 0.01:
		_direction_bias = _direction_bias.lerp(direction.normalized(), blend)
	var directional_impulse := clampf(float(profile.get("directional_impulse", 0.0)), 0.0, 1.0)
	_directional_impulse = maxf(_directional_impulse, directional_impulse * (0.40 + clamped_amount * 0.92))
	_directional_decay = lerpf(_directional_decay, clampf(float(profile.get("directional_decay", 9.0)), 1.5, 22.0), blend)
	_afterimage_amount = lerpf(_afterimage_amount, clampf(float(profile.get("afterimage_strength", 0.0)), 0.0, 1.0), blend)
	_afterimage_energy = maxf(_afterimage_energy, _afterimage_amount * (0.36 + clamped_amount * 0.96))
	_afterimage_decay = lerpf(_afterimage_decay, clampf(float(profile.get("afterimage_decay", 5.8)), 1.5, 18.0), blend)
	_afterimage_curve = lerpf(_afterimage_curve, clampf(float(profile.get("afterimage_curve", 1.45)), 0.5, 3.0), blend)


func _process(delta: float) -> void:
	tick += delta * 60.0 * _freq_mult
	if _directional_impulse > 0.0:
		_directional_impulse = maxf(0.0, _directional_impulse - delta * _directional_decay)
	if _afterimage_energy > 0.0:
		_afterimage_energy = maxf(0.0, _afterimage_energy - delta * _afterimage_decay)
	if trauma <= 0.0 and _afterimage_energy <= 0.0 and _directional_impulse <= 0.0:
		offset = _snap_offset(offset.lerp(Vector2.ZERO, minf(1.0, delta * 15.0)))
		rotation = lerpf(rotation, 0.0, minf(1.0, delta * 15.0))
		_direction_bias = _direction_bias.lerp(Vector2.ZERO, minf(1.0, delta * 6.0))
		_reset_runtime_profile(false)
		return

	trauma = maxf(0.0, trauma - (decay * _decay_mult) * delta)
	var shake: float = trauma * trauma
	var target_offset := Vector2(
		noise.get_noise_2d(0.0, tick),
		noise.get_noise_2d(73.0, tick)
	)
	target_offset *= Vector2(max_offset.x * _axis_scale.x, max_offset.y * _axis_scale.y) * shake
	target_offset += _direction_bias * max_offset * (_directional_impulse + shake * 0.22)
	var afterimage_ratio := 0.0
	if _afterimage_energy > 0.0:
		afterimage_ratio = pow(clampf(_afterimage_energy, 0.0, 1.0), _afterimage_curve)
		var afterimage_phase := tick * (0.06 + _freq_mult * 0.03)
		var rotated_dir := _direction_bias.rotated(sin(afterimage_phase) * 0.22)
		target_offset += rotated_dir * max_offset * (_afterimage_amount * afterimage_ratio * 0.58)
	var blend := minf(1.0, delta * ((18.0 * _response_mult) + 30.0 * shake))
	offset = _snap_offset(offset.lerp(target_offset, blend))
	var target_rotation := noise.get_noise_2d(141.0, tick) * max_rotation * shake * _rotation_mult
	if afterimage_ratio > 0.0:
		target_rotation += sin(tick * 0.04) * max_rotation * (_afterimage_amount * afterimage_ratio * 0.30)
	rotation = lerpf(rotation, target_rotation, blend)
	_direction_bias = _direction_bias.lerp(Vector2.ZERO, minf(1.0, delta * (3.0 + _directional_decay * 0.06)))


func _snap_offset(value: Vector2) -> Vector2:
	if pixel_snap_step <= 0.0:
		return value
	return Vector2(
		round(value.x / pixel_snap_step) * pixel_snap_step,
		round(value.y / pixel_snap_step) * pixel_snap_step
	)


func _reset_runtime_profile(reset_energies: bool = true) -> void:
	_freq_mult = 1.0
	_decay_mult = 1.0
	_response_mult = 1.0
	_rotation_mult = 1.0
	_axis_scale = Vector2.ONE
	if reset_energies:
		_direction_bias = Vector2.ZERO
		_directional_impulse = 0.0
	_afterimage_amount = 0.0
	if reset_energies:
		_afterimage_energy = 0.0
	_directional_decay = 9.0
	_afterimage_decay = 5.8
	_afterimage_curve = 1.45
