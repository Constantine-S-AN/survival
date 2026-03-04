extends Node

signal hit_landed(world_position: Vector2, intensity: float, killed: bool)
signal hit_landed_detailed(world_position: Vector2, intensity: float, killed: bool, payload: Dictionary)
signal shot_fired(world_position: Vector2, intensity: float)
signal sonar_pulse_requested(world_position: Vector2, payload: Dictionary)
signal pickup_collected(world_position: Vector2, amount: int)


func emit_hit(world_position: Vector2, intensity: float = 0.12, killed: bool = false, payload: Dictionary = {}) -> void:
	var clamped_intensity := clampf(intensity, 0.02, 1.0)
	var safe_payload := payload.duplicate(true)
	if not safe_payload.has("is_crit") and safe_payload.has("crit"):
		safe_payload["is_crit"] = bool(safe_payload.get("crit", false))
	hit_landed.emit(world_position, clamped_intensity, killed)
	hit_landed_detailed.emit(world_position, clamped_intensity, killed, safe_payload)


func emit_shot(world_position: Vector2, intensity: float = 0.08) -> void:
	shot_fired.emit(world_position, clampf(intensity, 0.02, 1.0))


func emit_sonar_pulse(world_position: Vector2, payload: Dictionary = {}) -> void:
	sonar_pulse_requested.emit(world_position, payload)


func emit_pickup_collected(world_position: Vector2, amount: int) -> void:
	pickup_collected.emit(world_position, maxi(1, amount))
