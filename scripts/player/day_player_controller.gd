extends CharacterBody2D
class_name DayPlayerController

signal focus_changed(zone_id: String)
signal interaction_requested(zone_id: String)

const InputConfigClass := preload("res://scripts/core/input_config.gd")

@export var move_speed: float = 220.0
@export var world_bounds := Rect2(Vector2(48.0, 72.0), Vector2(1504.0, 812.0))

@onready var sprite: Sprite2D = $Sprite2D
@onready var interaction_sensor: Area2D = $InteractionSensor
@onready var camera: Camera2D = $Camera2D

var _controls_enabled: bool = true
var _last_facing := Vector2.RIGHT
var _focused_zone: Area2D = null
var _overlapping_zones: Array[Area2D] = []
var _sprite_base_position: Vector2 = Vector2.ZERO
var _sprite_base_scale: Vector2 = Vector2.ONE
var _move_visual_time: float = 0.0


func _ready() -> void:
	InputConfigClass.ensure_default_actions()
	interaction_sensor.area_entered.connect(_on_sensor_area_entered)
	interaction_sensor.area_exited.connect(_on_sensor_area_exited)
	if sprite != null:
		_sprite_base_position = sprite.position
		_sprite_base_scale = sprite.scale
	_update_sprite_facing()
	_refresh_focus_zone()


func _physics_process(delta: float) -> void:
	if not _controls_enabled or not is_visible_in_tree():
		velocity = Vector2.ZERO
		_update_move_feedback(false, delta)
		return
	var input_vector := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if input_vector.length_squared() > 0.0:
		_last_facing = input_vector.normalized()
	_update_sprite_facing()
	velocity = input_vector.normalized() * move_speed if input_vector.length_squared() > 0.0 else Vector2.ZERO
	move_and_slide()
	global_position = _clamp_to_world(global_position)
	_update_move_feedback(input_vector.length_squared() > 0.0, delta)
	_refresh_focus_zone()


func _unhandled_input(event: InputEvent) -> void:
	if not _controls_enabled or not is_visible_in_tree():
		return
	if not event.is_action_pressed("day_interact"):
		return
	if _focused_zone == null:
		return
	interaction_requested.emit(_zone_id_from_area(_focused_zone))
	get_viewport().set_input_as_handled()


func set_controls_enabled(enabled: bool) -> void:
	_controls_enabled = enabled
	if not _controls_enabled:
		velocity = Vector2.ZERO


func set_camera_active(active: bool) -> void:
	camera.enabled = active
	if active:
		camera.make_current()


func set_world_bounds(bounds: Rect2) -> void:
	world_bounds = bounds
	_update_camera_limits()
	global_position = _clamp_to_world(global_position)


func reset_to_position(spawn_position: Vector2) -> void:
	global_position = _clamp_to_world(spawn_position)
	refresh_interaction_focus()


func get_focused_zone_id() -> String:
	return _zone_id_from_area(_focused_zone)


func refresh_interaction_focus() -> void:
	if interaction_sensor == null:
		return
	var overlapping: Array[Area2D] = []
	for area_variant in interaction_sensor.get_overlapping_areas():
		if not (area_variant is Area2D):
			continue
		var area := area_variant as Area2D
		if not area.is_in_group("day_interaction_zone"):
			continue
		overlapping.append(area)
	_overlapping_zones = overlapping
	_refresh_focus_zone()


func _update_camera_limits() -> void:
	camera.limit_left = int(world_bounds.position.x)
	camera.limit_top = int(world_bounds.position.y)
	camera.limit_right = int(world_bounds.position.x + world_bounds.size.x)
	camera.limit_bottom = int(world_bounds.position.y + world_bounds.size.y)


func _clamp_to_world(source: Vector2) -> Vector2:
	var half_extents := Vector2(18.0, 18.0)
	var min_position := world_bounds.position + half_extents
	var max_position := world_bounds.position + world_bounds.size - half_extents
	return Vector2(
		clampf(source.x, min_position.x, maxf(min_position.x, max_position.x)),
		clampf(source.y, min_position.y, maxf(min_position.y, max_position.y))
	)


func _update_sprite_facing() -> void:
	if sprite == null:
		return
	if absf(_last_facing.x) > 0.01:
		sprite.flip_h = _last_facing.x < 0.0


func _update_move_feedback(is_moving: bool, delta: float) -> void:
	if sprite == null:
		return
	if is_moving:
		_move_visual_time += delta * 10.5
		var bob := sin(_move_visual_time) * 1.6
		var squash := 1.0 + (0.02 * absf(cos(_move_visual_time)))
		sprite.position = _sprite_base_position + Vector2(0.0, bob)
		sprite.scale = Vector2(
			_sprite_base_scale.x * squash,
			_sprite_base_scale.y * (2.0 - squash)
		)
		return
	sprite.position = sprite.position.lerp(_sprite_base_position, clampf(delta * 12.0, 0.0, 1.0))
	sprite.scale = sprite.scale.lerp(_sprite_base_scale, clampf(delta * 12.0, 0.0, 1.0))


func _on_sensor_area_entered(area: Area2D) -> void:
	if area == null or not area.is_in_group("day_interaction_zone"):
		return
	if _overlapping_zones.has(area):
		return
	_overlapping_zones.append(area)
	_refresh_focus_zone()


func _on_sensor_area_exited(area: Area2D) -> void:
	_overlapping_zones.erase(area)
	_refresh_focus_zone()


func _refresh_focus_zone() -> void:
	var next_focus: Area2D = null
	var best_distance := INF
	var player_position := global_position
	var filtered: Array[Area2D] = []
	for area in _overlapping_zones:
		if area == null or not is_instance_valid(area):
			continue
		filtered.append(area)
		var distance := player_position.distance_to(area.global_position)
		if distance < best_distance:
			best_distance = distance
			next_focus = area
	_overlapping_zones = filtered
	if _focused_zone == next_focus:
		return
	_focused_zone = next_focus
	focus_changed.emit(_zone_id_from_area(_focused_zone))


func _zone_id_from_area(area: Area2D) -> String:
	if area == null or not is_instance_valid(area):
		return ""
	if area.has_meta("interaction_id"):
		return String(area.get_meta("interaction_id", "")).strip_edges().to_lower()
	var zone_name := area.name.strip_edges()
	if zone_name.ends_with("Zone"):
		zone_name = zone_name.substr(0, zone_name.length() - 4)
	return zone_name.to_lower()
