extends Node2D
class_name SonarManager

var config: Dictionary = {}
var waves: Array = []
var visual_enabled: bool = true
var enemy_manager: Node = null
var runtime_modifiers: Dictionary = {
	"wave_speed_mult": 1.0,
	"max_radius_mult": 1.0,
	"reveal_duration_mult": 1.0
}


func _ready() -> void:
	FeedbackBus.sonar_pulse_requested.connect(_on_sonar_pulse_requested)
	var parent := get_parent()
	if parent != null:
		enemy_manager = parent.get_node_or_null("EnemyManager")


func apply_config(new_config: Dictionary) -> void:
	config = new_config.duplicate(true)
	visual_enabled = bool(config.get("enabled", true))
	queue_redraw()


func set_runtime_modifiers(modifiers: Dictionary) -> void:
	runtime_modifiers["wave_speed_mult"] = maxf(0.05, float(modifiers.get("wave_speed_mult", 1.0)))
	runtime_modifiers["max_radius_mult"] = maxf(0.05, float(modifiers.get("max_radius_mult", 1.0)))
	runtime_modifiers["reveal_duration_mult"] = maxf(0.05, float(modifiers.get("reveal_duration_mult", 1.0)))


func set_visual_enabled(enabled: bool) -> void:
	visual_enabled = enabled
	queue_redraw()


func is_visual_enabled() -> bool:
	return visual_enabled


func get_revealed_enemy_count() -> int:
	var count := 0
	for enemy in _get_enemy_iterable():
		if enemy != null and is_instance_valid(enemy) and enemy.has_method("is_revealed"):
			if bool(enemy.is_revealed()):
				count += 1
	return count


func _process(delta: float) -> void:
	if waves.is_empty():
		return

	var active: Array = []
	for wave_variant in waves:
		if not (wave_variant is Dictionary):
			continue
		var wave: Dictionary = wave_variant
		var prev_radius := float(wave.get("radius", 0.0))
		var radius := prev_radius + float(wave.get("speed", 900.0)) * delta
		wave["prev_radius"] = prev_radius
		wave["radius"] = radius
		_reveal_enemies_for_wave(wave)
		if radius <= float(wave.get("max_radius", 700.0)):
			active.append(wave)
	waves = active
	queue_redraw()


func _draw() -> void:
	if not visual_enabled:
		return
	var base_color := Color.from_string(String(config.get("color", "#63e8ff")), Color(0.39, 0.91, 1.0, 1.0))
	var glow := float(config.get("glow_intensity", 1.0))
	for wave_variant in waves:
		if not (wave_variant is Dictionary):
			continue
		var wave: Dictionary = wave_variant
		var origin := Vector2(wave.get("origin", Vector2.ZERO))
		var radius := float(wave.get("radius", 0.0))
		var thickness := float(wave.get("line_width", 4.0))
		var strength := float(wave.get("strength", 0.6))
		var alpha := clampf(1.0 - (radius / maxf(1.0, float(wave.get("max_radius", 700.0)))), 0.0, 1.0)
		var color := base_color * (0.5 + strength * glow)
		color.a = 0.14 + alpha * 0.56
		draw_arc(origin, radius, 0.0, TAU, 96, color, thickness, true)


func _on_sonar_pulse_requested(world_position: Vector2, payload: Dictionary) -> void:
	if config.is_empty():
		return
	if not bool(config.get("enabled", true)):
		return

	var source := String(payload.get("source", "skill"))
	var source_strength_key := "%s_strength" % source
	var source_radius_key := "%s_radius_scale" % source

	var strength := float(payload.get("strength", float(config.get(source_strength_key, 0.7))))
	var max_radius := float(config.get("max_radius", 720.0))
	max_radius *= float(payload.get("radius_scale", float(config.get(source_radius_key, 1.0))))
	max_radius *= float(runtime_modifiers.get("max_radius_mult", 1.0))
	var speed := float(payload.get("speed", float(config.get("wave_speed", 980.0))))
	speed *= float(runtime_modifiers.get("wave_speed_mult", 1.0))
	var reveal_duration := float(payload.get("reveal_duration", float(config.get("reveal_duration", 1.8))))
	reveal_duration *= maxf(0.2, float(payload.get("reveal_duration_multiplier", 1.0)))
	reveal_duration *= float(runtime_modifiers.get("reveal_duration_mult", 1.0))
	var thickness := float(payload.get("line_width", float(config.get("line_width", 5.5))))

	waves.append({
		"origin": world_position,
		"radius": 0.0,
		"prev_radius": 0.0,
		"max_radius": max_radius,
		"speed": speed,
		"line_width": thickness,
		"reveal_duration": reveal_duration,
		"strength": strength,
		"revealed_ids": {}
	})
	queue_redraw()


func _reveal_enemies_for_wave(wave: Dictionary) -> void:
	var origin := Vector2(wave.get("origin", Vector2.ZERO))
	var prev_radius := float(wave.get("prev_radius", 0.0))
	var radius := float(wave.get("radius", 0.0))
	var reveal_duration := float(wave.get("reveal_duration", 1.8))
	var revealed_ids_variant: Variant = wave.get("revealed_ids", {})
	var revealed_ids: Dictionary = revealed_ids_variant if revealed_ids_variant is Dictionary else {}

	for enemy in _get_enemy_iterable():
		if enemy == null or not is_instance_valid(enemy):
			continue
		if not enemy.has_method("set_revealed"):
			continue
		var instance_key := str(enemy.get_instance_id())
		if bool(revealed_ids.get(instance_key, false)):
			continue
		var distance: float = enemy.global_position.distance_to(origin)
		if distance >= prev_radius and distance <= radius:
			enemy.set_revealed(reveal_duration)
			revealed_ids[instance_key] = true

	wave["revealed_ids"] = revealed_ids


func _get_enemy_iterable() -> Array:
	if enemy_manager != null and enemy_manager.has_method("get_active_enemies"):
		var active_variant: Variant = enemy_manager.get_active_enemies()
		if active_variant is Array:
			return active_variant
	return get_tree().get_nodes_in_group("enemy")
