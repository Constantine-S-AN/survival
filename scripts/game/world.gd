extends Node2D
class_name World

@onready var projectile_manager = $ProjectileManager
@onready var enemy_manager = $EnemyManager
@onready var player = $Player
@onready var camera = $Player/Camera2D
@onready var fog_darkness: CanvasModulate = $FogDarkness
@onready var fog_light: PointLight2D = $Player/FogLight
@onready var hit_sfx = $HitSfx
@onready var shot_sfx = $ShotSfx

var sfx_rng := RandomNumberGenerator.new()
var fog_enabled: bool = true
var fog_config: Dictionary = {}


func _ready() -> void:
	sfx_rng.seed = int(Time.get_unix_time_from_system())
	_configure_synth_player(hit_sfx)
	_configure_synth_player(shot_sfx)
	apply_fog_config(DataRegistry.get_fog_config())
	set_fog_enabled(bool(fog_config.get("enabled", true)))
	FeedbackBus.hit_landed.connect(_on_hit_landed)
	FeedbackBus.shot_fired.connect(_on_shot_fired)
	queue_redraw()


func setup_run(run_rng: RandomNumberGenerator) -> void:
	player.setup(enemy_manager, projectile_manager, run_rng)
	enemy_manager.setup(player, run_rng)


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


func _on_hit_landed(world_position: Vector2, intensity: float, killed: bool) -> void:
	_spawn_hit_particles(world_position, intensity, killed)
	_play_hit_sfx(intensity, killed)


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
