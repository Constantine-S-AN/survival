extends Node

signal hit_landed(world_position: Vector2, intensity: float, killed: bool)
signal shot_fired(world_position: Vector2, intensity: float)
signal sonar_pulse_requested(world_position: Vector2, payload: Dictionary)
signal pickup_collected(world_position: Vector2, amount: int)


func emit_hit(world_position: Vector2, intensity: float = 0.12, killed: bool = false) -> void:
	hit_landed.emit(world_position, clampf(intensity, 0.02, 1.0), killed)


func emit_shot(world_position: Vector2, intensity: float = 0.08) -> void:
	shot_fired.emit(world_position, clampf(intensity, 0.02, 1.0))


func emit_sonar_pulse(world_position: Vector2, payload: Dictionary = {}) -> void:
	sonar_pulse_requested.emit(world_position, payload)


func emit_pickup_collected(world_position: Vector2, amount: int) -> void:
	pickup_collected.emit(world_position, maxi(1, amount))
