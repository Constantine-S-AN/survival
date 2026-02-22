extends RefCounted
class_name RunStats

var total_kills: int = 0
var pickups_collected: int = 0
var elite_or_pursuer_kills: int = 0
var survive_time_seconds: float = 0.0
var max_noise_reached: float = 0.0
var max_noise_tier_id: String = "silent"
var run_seed: int = 0


func reset(seed: int) -> void:
	total_kills = 0
	pickups_collected = 0
	elite_or_pursuer_kills = 0
	survive_time_seconds = 0.0
	max_noise_reached = 0.0
	max_noise_tier_id = "silent"
	run_seed = seed


func to_dict() -> Dictionary:
	return {
		"total_kills": total_kills,
		"pickups_collected": pickups_collected,
		"elite_or_pursuer_kills": elite_or_pursuer_kills,
		"survive_time_seconds": survive_time_seconds,
		"max_noise_reached": max_noise_reached,
		"max_noise_tier_id": max_noise_tier_id,
		"run_seed": run_seed
	}
