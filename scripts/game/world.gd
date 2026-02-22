extends Node2D
class_name World

@onready var projectile_manager = $ProjectileManager
@onready var pool_manager = $PoolManager
@onready var enemy_manager = $EnemyManager
@onready var sonar_manager = $SonarManager
@onready var pickup_layer: Node2D = $PickupLayer
@onready var player = $Player
@onready var camera = $Player/Camera2D
@onready var fog_darkness: CanvasModulate = $FogDarkness
@onready var fog_light: PointLight2D = $Player/FogLight
@onready var hit_sfx = $HitSfx
@onready var shot_sfx = $ShotSfx

var xp_pickup_scene := preload("res://scenes/pickup/XPPickup.tscn")
var sfx_rng := RandomNumberGenerator.new()
var fog_enabled: bool = true
var fog_config: Dictionary = {}
const PROJECTILE_POOL_KEY := "projectile"
const PICKUP_POOL_KEY := "pickup"
const PROJECTILE_POOL_PREWARM := 72
const PICKUP_POOL_PREWARM := 48


func _ready() -> void:
	sfx_rng.seed = int(Time.get_unix_time_from_system())
	_configure_synth_player(hit_sfx)
	_configure_synth_player(shot_sfx)
	_setup_pools()
	apply_fog_config(DataRegistry.get_fog_config())
	set_fog_enabled(bool(fog_config.get("enabled", true)))
	apply_sonar_config(DataRegistry.get_sonar_config())
	FeedbackBus.hit_landed.connect(_on_hit_landed)
	FeedbackBus.shot_fired.connect(_on_shot_fired)
	queue_redraw()


func setup_run(run_rng: RandomNumberGenerator) -> void:
	_setup_pools()
	if pool_manager != null and pool_manager.has_method("reset_stats"):
		pool_manager.reset_stats()
	player.setup(enemy_manager, projectile_manager, run_rng)
	enemy_manager.setup(player, run_rng)
	apply_sonar_config(DataRegistry.get_sonar_config())


func apply_screen_shake(amount: float) -> void:
	if camera != null and camera.has_method("add_trauma"):
		camera.add_trauma(amount)


func apply_fog_config(config: Dictionary) -> void:
	fog_config = config.duplicate(true)
	if fog_config.is_empty():
		return

	var dark := Color.from_string(String(fog_config.get("darkness_color", "#0a1422")), Color(0.039, 0.078, 0.133))
	fog_darkness.color = dark

	fog_light.texture = _build_fog_light_texture()
	var radius := float(fog_config.get("vision_radius", 440.0))
	fog_light.texture_scale = maxf(0.2, radius / 256.0)
	fog_light.energy = float(fog_config.get("vision_energy", 1.25))
	fog_light.color = Color(0.70, 0.88, 1.0, 1.0)


func set_fog_enabled(enabled: bool) -> void:
	fog_enabled = enabled
	fog_darkness.visible = fog_enabled
	fog_light.enabled = fog_enabled


func is_fog_enabled() -> bool:
	return fog_enabled


func _build_fog_light_texture() -> Texture2D:
	var gradient := Gradient.new()
	gradient.offsets = PackedFloat32Array([0.0, 0.4, 0.78, 1.0])
	gradient.colors = PackedColorArray([
		Color(1.0, 1.0, 1.0, 0.95),
		Color(1.0, 1.0, 1.0, 0.60),
		Color(1.0, 1.0, 1.0, 0.20),
		Color(1.0, 1.0, 1.0, 0.0)
	])
	var texture := GradientTexture2D.new()
	texture.width = 512
	texture.height = 512
	texture.fill = GradientTexture2D.FILL_RADIAL
	texture.gradient = gradient
	return texture


func apply_sonar_config(config: Dictionary) -> void:
	if sonar_manager != null and sonar_manager.has_method("apply_config"):
		sonar_manager.apply_config(config)


func set_sonar_visual_enabled(enabled: bool) -> void:
	if sonar_manager != null and sonar_manager.has_method("set_visual_enabled"):
		sonar_manager.set_visual_enabled(enabled)


func is_sonar_visual_enabled() -> bool:
	if sonar_manager == null or not sonar_manager.has_method("is_visual_enabled"):
		return false
	return bool(sonar_manager.is_visual_enabled())


func get_revealed_enemy_count() -> int:
	if sonar_manager == null or not sonar_manager.has_method("get_revealed_enemy_count"):
		return 0
	return int(sonar_manager.get_revealed_enemy_count())


func get_runtime_entity_counts() -> Dictionary:
	var pickups := 0
	if pickup_layer != null:
		pickups = pickup_layer.get_child_count()
	return {
		"enemies": enemy_manager.get_alive_enemy_count(),
		"projectiles": int(projectile_manager.active_projectiles),
		"pickups": pickups,
		"revealed": get_revealed_enemy_count()
	}


func get_pool_stats() -> Dictionary:
	if pool_manager != null and pool_manager.has_method("get_stats"):
		return pool_manager.get_stats()
	return {
		"hits": 0,
		"misses": 0,
		"total": 0,
		"hit_rate": -1.0
	}


func spawn_xp_pickup(world_position: Vector2, xp_amount: int) -> void:
	if xp_pickup_scene == null:
		player.gain_xp(xp_amount)
		return
	var pickup: Node = null
	if pool_manager != null and pool_manager.has_method("checkout"):
		pickup = pool_manager.checkout(PICKUP_POOL_KEY, pickup_layer)
	if pickup == null:
		pickup = xp_pickup_scene.instantiate()
		pickup_layer.add_child(pickup)
	if pickup.has_method("set_recycle_handler"):
		pickup.set_recycle_handler(Callable(self, "_on_pickup_recycle_requested"))
	pickup.global_position = world_position
	pickup.setup(xp_amount, player)


func _on_hit_landed(world_position: Vector2, intensity: float, killed: bool) -> void:
	_spawn_hit_particles(world_position, intensity, killed)
	_play_hit_sfx(intensity, killed)
	FeedbackBus.emit_sonar_pulse(world_position, {
		"source": "hit",
		"strength": intensity
	})


func _on_shot_fired(_world_position: Vector2, intensity: float) -> void:
	_play_shot_sfx(intensity)


func _spawn_hit_particles(world_position: Vector2, intensity: float, killed: bool) -> void:
	var p := CPUParticles2D.new()
	add_child(p)
	p.global_position = world_position
	p.one_shot = true
	p.emitting = true
	p.amount = 10 + int(round(intensity * 16.0)) + (8 if killed else 0)
	p.lifetime = 0.18 + intensity * 0.08
	p.explosiveness = 0.95
	p.spread = 180.0
	p.gravity = Vector2.ZERO
	p.direction = Vector2.RIGHT
	p.initial_velocity_min = 70.0
	p.initial_velocity_max = 220.0 + intensity * 130.0
	p.scale_amount_min = 1.6
	p.scale_amount_max = 3.6 + intensity * 1.8
	p.color = Color(0.72, 0.98, 1.0, 0.95) if not killed else Color(1.0, 0.98, 0.75, 1.0)
	p.finished.connect(p.queue_free)


func _configure_synth_player(player_ref: AudioStreamPlayer) -> void:
	var stream := AudioStreamGenerator.new()
	stream.mix_rate = 44100.0
	stream.buffer_length = 0.12
	player_ref.stream = stream


func _play_shot_sfx(intensity: float) -> void:
	shot_sfx.play()
	var playback = shot_sfx.get_stream_playback()
	if playback is AudioStreamGeneratorPlayback:
		var generator: AudioStreamGeneratorPlayback = playback
		var sample_rate := 44100.0
		var length := 0.055
		var freq_base := sfx_rng.randf_range(620.0, 780.0)
		for i in range(int(sample_rate * length)):
			var t := float(i) / sample_rate
			var env := exp(-t * 42.0)
			var wave := sin(TAU * (freq_base - 260.0 * t) * t)
			var sample := wave * env * (0.09 + intensity * 0.18)
			generator.push_frame(Vector2(sample, sample))


func _play_hit_sfx(intensity: float, killed: bool) -> void:
	hit_sfx.play()
	var playback = hit_sfx.get_stream_playback()
	if playback is AudioStreamGeneratorPlayback:
		var generator: AudioStreamGeneratorPlayback = playback
		var sample_rate := 44100.0
		var length := 0.08 + (0.03 if killed else 0.0)
		var freq_base := sfx_rng.randf_range(740.0, 980.0)
		for i in range(int(sample_rate * length)):
			var t := float(i) / sample_rate
			var env := exp(-t * 32.0)
			var wave := sin(TAU * (freq_base - 420.0 * t) * t)
			var noise := sfx_rng.randf_range(-1.0, 1.0)
			var sample := (wave * 0.72 + noise * 0.28) * env * (0.12 + intensity * 0.26)
			generator.push_frame(Vector2(sample, sample))


func _draw() -> void:
	draw_rect(Rect2(Vector2(-4200.0, -4200.0), Vector2(8400.0, 8400.0)), Color(0.015, 0.03, 0.055, 1.0), true)
	for i in range(-30, 31):
		var x := float(i) * 240.0
		draw_line(Vector2(x, -4200.0), Vector2(x, 4200.0), Color(0.12, 0.55, 0.78, 0.12), 1.0)
		var y := float(i) * 240.0
		draw_line(Vector2(-4200.0, y), Vector2(4200.0, y), Color(0.12, 0.55, 0.78, 0.12), 1.0)


func _setup_pools() -> void:
	if pool_manager == null:
		return
	if projectile_manager != null and projectile_manager.has_method("setup_pool"):
		projectile_manager.setup_pool(pool_manager, PROJECTILE_POOL_KEY, PROJECTILE_POOL_PREWARM)
	if xp_pickup_scene != null and pool_manager.has_method("ensure_pool"):
		pool_manager.ensure_pool(PICKUP_POOL_KEY, xp_pickup_scene, pickup_layer, PICKUP_POOL_PREWARM)


func _on_pickup_recycle_requested(pickup: Node) -> void:
	if pickup == null:
		return
	if pool_manager != null and pool_manager.has_method("recycle"):
		pool_manager.recycle(PICKUP_POOL_KEY, pickup)
	else:
		pickup.queue_free()
