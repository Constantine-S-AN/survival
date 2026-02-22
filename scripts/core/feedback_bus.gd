extends Node

signal hit_landed(world_position: Vector2, intensity: float, killed: bool)
signal shot_fired(world_position: Vector2, intensity: float)


func emit_hit(world_position: Vector2, intensity: float = 0.12, killed: bool = false) -> void:
	hit_landed.emit(world_position, clampf(intensity, 0.02, 1.0), killed)


func emit_shot(world_position: Vector2, intensity: float = 0.08) -> void:
	shot_fired.emit(world_position, clampf(intensity, 0.02, 1.0))
