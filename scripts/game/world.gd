extends Node2D
class_name World

signal map_event_triggered(event_id: String, event_name: String, message: String)
signal hazard_state_changed(active: bool, warning_text: String)

const MapRuntimeClass := preload("res://scripts/core/map_runtime.gd")
const BossTelegraphEffectClass := preload("res://scripts/effects/boss_telegraph_effect.gd")

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
var base_fog_config: Dictionary = {}
var effective_fog_config: Dictionary = {}
var base_sonar_config: Dictionary = {}
var map_runtime = MapRuntimeClass.new()
var current_map_snapshot: Dictionary = {}
var current_map_id: String = ""
var current_map_modifiers: Dictionary = {}
var contract_modifiers: Dictionary = {}
var active_contract_ids: Array[String] = []
var last_hazard_active: bool = false
var last_hazard_warning_active: bool = false
var boss_fx_layer: Node2D
const PROJECTILE_POOL_KEY := "projectile"
const PICKUP_POOL_KEY := "pickup"
const ENEMY_POOL_KEY := "enemy"
const PROJECTILE_POOL_PREWARM := 72
const PICKUP_POOL_PREWARM := 48
const ENEMY_POOL_PREWARM := 120


func _ready() -> void:
	sfx_rng.seed = int(Time.get_unix_time_from_system())
	boss_fx_layer = Node2D.new()
	boss_fx_layer.name = "BossFxLayer"
	add_child(boss_fx_layer)
	_configure_synth_player(hit_sfx)
	_configure_synth_player(shot_sfx)
	_setup_pools()
	apply_fog_config(DataRegistry.get_fog_config())
	set_fog_enabled(bool(fog_config.get("enabled", true)))
	apply_sonar_config(DataRegistry.get_sonar_config())
	current_map_id = DataRegistry.get_default_map_id()
	FeedbackBus.hit_landed.connect(_on_hit_landed)
	FeedbackBus.shot_fired.connect(_on_shot_fired)
	if enemy_manager != null:
		enemy_manager.boss_telegraph_requested.connect(_on_boss_telegraph_requested)
		enemy_manager.boss_echoes_spawned.connect(_on_boss_echoes_spawned)
		enemy_manager.boss_true_form_revealed.connect(_on_boss_true_form_revealed)
	queue_redraw()


func setup_run(
	run_rng: RandomNumberGenerator,
	character_def: Dictionary = {},
	map_id: String = "",
	run_seed: int = 0,
	contract_bundle: Dictionary = {},
	contract_ids: Array = []
) -> void:
	_clear_boss_fx()
	_setup_pools()
	if pool_manager != null and pool_manager.has_method("reset_stats"):
		pool_manager.reset_stats()
	player.setup(enemy_manager, projectile_manager, run_rng, character_def)
	enemy_manager.setup(player, run_rng)
	set_contract_modifiers(contract_bundle, contract_ids)
	apply_sonar_config(base_sonar_config if not base_sonar_config.is_empty() else DataRegistry.get_sonar_config())
	set_current_map(map_id, run_seed)


func apply_screen_shake(amount: float) -> void:
	if camera != null and camera.has_method("add_trauma"):
		camera.add_trauma(amount)


func apply_fog_config(config: Dictionary) -> void:
	base_fog_config = config.duplicate(true)
	fog_config = base_fog_config.duplicate(true)
	effective_fog_config = fog_config.duplicate(true)
	if effective_fog_config.is_empty():
		return

	var dark := Color.from_string(String(effective_fog_config.get("darkness_color", "#0a1422")), Color(0.039, 0.078, 0.133))
	fog_darkness.color = dark

	fog_light.texture = _build_fog_light_texture()
	var radius := float(effective_fog_config.get("vision_radius", 440.0))
	fog_light.texture_scale = maxf(0.2, radius / 256.0)
	fog_light.energy = float(effective_fog_config.get("vision_energy", 1.25))
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
	base_sonar_config = config.duplicate(true)
	if sonar_manager != null and sonar_manager.has_method("apply_config"):
		sonar_manager.apply_config(config)
	if sonar_manager != null and sonar_manager.has_method("set_runtime_modifiers"):
		sonar_manager.set_runtime_modifiers({
			"wave_speed_mult": 1.0,
			"max_radius_mult": 1.0,
			"reveal_duration_mult": 1.0
		})


func get_effective_fog_config() -> Dictionary:
	if effective_fog_config.is_empty():
		return {}
	return effective_fog_config.duplicate(true)


func get_current_map_id() -> String:
	return current_map_id


func get_current_map_snapshot() -> Dictionary:
	return current_map_snapshot.duplicate(true)


func get_active_contract_ids() -> Array[String]:
	return active_contract_ids.duplicate()


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


func get_enemy_pool_stats() -> Dictionary:
	if enemy_manager != null and enemy_manager.has_method("get_enemy_pool_stats"):
		return enemy_manager.get_enemy_pool_stats()
	return {
		"key": ENEMY_POOL_KEY,
		"hits": 0,
		"misses": 0,
		"total": 0,
		"hit_rate": -1.0
	}


func get_active_boss_telegraph_count() -> int:
	if boss_fx_layer == null:
		return 0
	return boss_fx_layer.get_child_count()


func spawn_boss_telegraph(telegraph_type: String, payload: Dictionary = {}) -> void:
	if BossTelegraphEffectClass == null:
		return
	if boss_fx_layer == null:
		return
	var telegraph := BossTelegraphEffectClass.new()
	if telegraph == null:
		return
	boss_fx_layer.add_child(telegraph)
	telegraph.configure(telegraph_type, payload)


func _clear_boss_fx() -> void:
	if boss_fx_layer == null:
		return
	for child in boss_fx_layer.get_children():
		if child == null or not is_instance_valid(child):
			continue
		child.queue_free()


func set_current_map(map_id: String, run_seed: int = 0) -> void:
	var resolved_map_id := map_id.strip_edges()
	if resolved_map_id.is_empty() or not DataRegistry.has_map(resolved_map_id):
		resolved_map_id = DataRegistry.get_default_map_id()
	if resolved_map_id.is_empty() or not DataRegistry.has_map(resolved_map_id):
		current_map_id = ""
		current_map_snapshot = {}
		current_map_modifiers = {}
		last_hazard_active = false
		last_hazard_warning_active = false
		_apply_fog_modifier_bundle({})
		if sonar_manager != null and sonar_manager.has_method("set_runtime_modifiers"):
			sonar_manager.set_runtime_modifiers({})
		if player != null and is_instance_valid(player) and player.has_method("apply_environment_modifiers"):
			player.apply_environment_modifiers({}, {}, {})
		if enemy_manager != null and enemy_manager.has_method("set_map_spawn_modifiers"):
			enemy_manager.set_map_spawn_modifiers({})
		return
	current_map_id = resolved_map_id
	var map_def := DataRegistry.get_map(current_map_id)
	var hazard_def := DataRegistry.get_hazard(String(map_def.get("hazard_id", "")))
	var event_table := DataRegistry.get_event_table(String(map_def.get("event_table_id", "")))
	var seed := run_seed if run_seed != 0 else int(Time.get_unix_time_from_system())
	map_runtime.setup(map_def, hazard_def, event_table, seed)
	map_runtime.set_external_modifiers(contract_modifiers)
	current_map_snapshot = map_runtime.get_snapshot()
	last_hazard_active = bool(current_map_snapshot.get("hazard_active", false))
	last_hazard_warning_active = bool(current_map_snapshot.get("hazard_warning_active", false))
	_apply_map_snapshot(current_map_snapshot)


func update_map_runtime(delta: float) -> Dictionary:
	if current_map_id.is_empty():
		return {}
	current_map_snapshot = map_runtime.update(delta)
	_apply_map_snapshot(current_map_snapshot)
	_handle_map_notifications(current_map_snapshot)
	return current_map_snapshot.duplicate(true)


func set_contract_modifiers(modifiers: Dictionary, contract_ids: Array = []) -> void:
	contract_modifiers = modifiers.duplicate(true)
	active_contract_ids = []
	for contract_id_variant in contract_ids:
		var contract_id := String(contract_id_variant).strip_edges()
		if contract_id.is_empty():
			continue
		if active_contract_ids.has(contract_id):
			continue
		active_contract_ids.append(contract_id)
	map_runtime.set_external_modifiers(contract_modifiers)

	var player_mods_variant: Variant = contract_modifiers.get("player", {})
	var player_mods: Dictionary = player_mods_variant if player_mods_variant is Dictionary else {}
	if player != null and is_instance_valid(player) and player.has_method("apply_contract_modifiers"):
		player.apply_contract_modifiers(player_mods)

	var spawner_mods_variant: Variant = contract_modifiers.get("spawner", {})
	var spawner_mods: Dictionary = spawner_mods_variant if spawner_mods_variant is Dictionary else {}
	var enemy_mods_variant: Variant = contract_modifiers.get("enemy", {})
	var enemy_mods: Dictionary = enemy_mods_variant if enemy_mods_variant is Dictionary else {}
	spawner_mods["enemy_speed_mult"] = float(enemy_mods.get("speed_mult", 1.0))
	if enemy_manager != null and enemy_manager.has_method("set_contract_spawn_modifiers"):
		enemy_manager.set_contract_spawn_modifiers(spawner_mods)


func get_map_debug_snapshot() -> Dictionary:
	var snapshot := current_map_snapshot
	var modifiers_variant: Variant = snapshot.get("modifiers", {})
	var modifiers: Dictionary = modifiers_variant if modifiers_variant is Dictionary else {}
	var fog_mod_variant: Variant = modifiers.get("fog", {})
	var fog_mod: Dictionary = fog_mod_variant if fog_mod_variant is Dictionary else {}
	var noise_mod_variant: Variant = modifiers.get("noise", {})
	var noise_mod: Dictionary = noise_mod_variant if noise_mod_variant is Dictionary else {}
	var spawner_mod_variant: Variant = modifiers.get("spawner", {})
	var spawner_mod: Dictionary = spawner_mod_variant if spawner_mod_variant is Dictionary else {}
	var events_mod_variant: Variant = contract_modifiers.get("events", {})
	var events_mod: Dictionary = events_mod_variant if events_mod_variant is Dictionary else {}
	return {
		"current_map_id": current_map_id,
		"hazard_active": bool(snapshot.get("hazard_active", false)),
		"hazard_timer": float(snapshot.get("hazard_timer", 0.0)),
		"last_event_triggered": String(snapshot.get("last_event_triggered", "")),
		"map_spawn_multiplier": float(spawner_mod.get("spawn_rate_mult", 1.0)),
		"fog_radius_multiplier": float(fog_mod.get("vision_radius_mult", 1.0)),
		"fog_radius": float(effective_fog_config.get("vision_radius", float(base_fog_config.get("vision_radius", 440.0)))),
		"noise_gain_multiplier": float(noise_mod.get("gain_mult", 1.0)),
		"contracts_active": active_contract_ids.duplicate(),
		"contract_event_rate_mult": float(events_mod.get("rate_mult", 1.0))
	}


func _apply_map_snapshot(snapshot: Dictionary) -> void:
	if snapshot.is_empty():
		return
	var modifiers_variant: Variant = snapshot.get("modifiers", {})
	if not (modifiers_variant is Dictionary):
		return
	var modifiers: Dictionary = modifiers_variant
	current_map_modifiers = modifiers.duplicate(true)

	var fog_mod_variant: Variant = modifiers.get("fog", {})
	var fog_mods: Dictionary = fog_mod_variant if fog_mod_variant is Dictionary else {}
	var sonar_mod_variant: Variant = modifiers.get("sonar", {})
	var sonar_mods: Dictionary = sonar_mod_variant if sonar_mod_variant is Dictionary else {}
	var noise_mod_variant: Variant = modifiers.get("noise", {})
	var noise_mods: Dictionary = noise_mod_variant if noise_mod_variant is Dictionary else {}
	var rewards_mod_variant: Variant = modifiers.get("rewards", {})
	var rewards_mods: Dictionary = rewards_mod_variant if rewards_mod_variant is Dictionary else {}
	var spawner_mod_variant: Variant = modifiers.get("spawner", {})
	var spawner_mods: Dictionary = spawner_mod_variant if spawner_mod_variant is Dictionary else {}

	_apply_fog_modifier_bundle(fog_mods)
	if sonar_manager != null and sonar_manager.has_method("set_runtime_modifiers"):
		var sonar_runtime := {
			"wave_speed_mult": float(sonar_mods.get("wave_speed_mult", 1.0)),
			"max_radius_mult": float(sonar_mods.get("max_radius_mult", 1.0)),
			"reveal_duration_mult": 1.0
		}
		sonar_manager.set_runtime_modifiers(sonar_runtime)
	if player != null and is_instance_valid(player) and player.has_method("apply_environment_modifiers"):
		var player_sonar_mod := {
			"reveal_duration_mult": float(sonar_mods.get("reveal_duration_mult", 1.0))
		}
		player.apply_environment_modifiers(noise_mods, player_sonar_mod, rewards_mods)
	if enemy_manager != null and enemy_manager.has_method("set_map_spawn_modifiers"):
		enemy_manager.set_map_spawn_modifiers(spawner_mods)


func _apply_fog_modifier_bundle(fog_modifiers: Dictionary) -> void:
	var base_config := base_fog_config if not base_fog_config.is_empty() else DataRegistry.get_fog_config()
	if base_config.is_empty():
		return
	var updated := base_config.duplicate(true)
	var base_radius := float(base_config.get("vision_radius", 440.0))
	var radius_mult := maxf(0.1, float(fog_modifiers.get("vision_radius_mult", 1.0)))
	updated["vision_radius"] = base_radius * radius_mult
	updated["noise_strength"] = float(base_config.get("noise_strength", 0.05)) + float(fog_modifiers.get("noise_strength_add", 0.0))
	updated["scanline_strength"] = float(base_config.get("scanline_strength", 0.08)) + float(fog_modifiers.get("scanline_strength_add", 0.0))
	effective_fog_config = updated
	fog_config = updated.duplicate(true)
	var dark := Color.from_string(String(updated.get("darkness_color", "#0a1422")), Color(0.039, 0.078, 0.133))
	fog_darkness.color = dark
	fog_light.texture = _build_fog_light_texture()
	fog_light.texture_scale = maxf(0.2, float(updated.get("vision_radius", 440.0)) / 256.0)
	fog_light.energy = float(updated.get("vision_energy", 1.25))


func _handle_map_notifications(snapshot: Dictionary) -> void:
	var warning_active_now := bool(snapshot.get("hazard_warning_active", false))
	if warning_active_now != last_hazard_warning_active:
		last_hazard_warning_active = warning_active_now
		if warning_active_now:
			hazard_state_changed.emit(false, String(snapshot.get("hazard_warning", "")))

	var hazard_active_now := bool(snapshot.get("hazard_active", false))
	if hazard_active_now != last_hazard_active:
		last_hazard_active = hazard_active_now
		hazard_state_changed.emit(hazard_active_now, String(snapshot.get("hazard_warning", "")))

	var triggered_variant: Variant = snapshot.get("triggered_events", [])
	if not (triggered_variant is Array):
		return
	var triggered_events: Array = triggered_variant
	for event_variant in triggered_events:
		if not (event_variant is Dictionary):
			continue
		var event: Dictionary = event_variant
		_apply_event_immediate(event)
		var immediate_variant: Variant = event.get("immediate", {})
		var immediate: Dictionary = immediate_variant if immediate_variant is Dictionary else {}
		map_event_triggered.emit(
			String(event.get("id", "")),
			String(event.get("name", "")),
			String(immediate.get("message", ""))
		)


func _apply_event_immediate(event: Dictionary) -> void:
	var immediate_variant: Variant = event.get("immediate", {})
	if not (immediate_variant is Dictionary):
		return
	var immediate: Dictionary = immediate_variant
	var spawn_pickups := int(immediate.get("spawn_pickups", 0))
	if spawn_pickups > 0:
		_spawn_event_pickups(spawn_pickups, int(immediate.get("pickup_xp", 8)))
	var noise_delta := float(immediate.get("noise_delta", 0.0))
	if absf(noise_delta) > 0.001 and player != null and is_instance_valid(player) and player.has_method("add_noise_delta"):
		player.add_noise_delta(noise_delta)


func _spawn_event_pickups(count: int, xp_amount: int) -> void:
	if player == null or not is_instance_valid(player):
		return
	var clamped_count := clampi(count, 1, 12)
	var amount := maxi(1, xp_amount)
	for i in range(clamped_count):
		var angle := sfx_rng.randf_range(0.0, TAU)
		var radius := sfx_rng.randf_range(32.0, 120.0)
		var world_pos: Vector2 = player.global_position + Vector2.RIGHT.rotated(angle) * radius
		spawn_xp_pickup(world_pos, amount)


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


func _on_boss_telegraph_requested(telegraph_type: String, payload: Dictionary) -> void:
	spawn_boss_telegraph(telegraph_type, payload)


func _on_boss_echoes_spawned(_boss_id: String, count: int, world_position: Vector2) -> void:
	spawn_boss_telegraph("ring", {
		"origin": world_position,
		"radius": 92.0 + float(count) * 22.0,
		"duration": 0.62,
		"line_width": 4.5,
		"color": "#7ee8ff"
	})


func _on_boss_true_form_revealed(_boss_id: String, world_position: Vector2) -> void:
	spawn_boss_telegraph("cone", {
		"origin": world_position,
		"radius": 220.0,
		"duration": 0.55,
		"line_width": 4.0,
		"cone_angle_deg": 90.0,
		"direction": Vector2.RIGHT.rotated(float(Time.get_ticks_msec() % 3600) * 0.0018),
		"color": "#a8f7ff"
	})
	FeedbackBus.emit_sonar_pulse(world_position, {
		"source": "skill",
		"strength": 0.95,
		"radius_scale": 1.2
	})


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


func play_pursuer_warning_sfx() -> void:
	shot_sfx.play()
	var playback = shot_sfx.get_stream_playback()
	if playback is AudioStreamGeneratorPlayback:
		var generator: AudioStreamGeneratorPlayback = playback
		var sample_rate := 44100.0
		var length := 0.16
		for i in range(int(sample_rate * length)):
			var t := float(i) / sample_rate
			var env := exp(-t * 11.0)
			var sweep := 560.0 + 320.0 * sin(t * TAU * 4.0)
			var sample := sin(TAU * sweep * t) * env * 0.20
			generator.push_frame(Vector2(sample, sample))


func play_telegraph_sfx(bucket: String, severity: float = 1.0, text_key: String = "") -> void:
	var normalized_bucket := bucket.strip_edges().to_lower()
	var normalized_key := text_key.strip_edges().to_lower()
	match normalized_bucket:
		"boss":
			match normalized_key:
				"boss_phase_shift":
					if severity >= 2.3:
						play_boss_phase2_sfx()
					else:
						play_boss_warning_sfx()
				"boss_echoes":
					play_boss_echo_spawn_sfx()
				"boss_true_form_revealed":
					play_boss_true_reveal_sfx()
				_:
					play_boss_warning_sfx()
		"alert":
			play_pursuer_warning_sfx()
		_:
			play_warning_ping_sfx(severity)


func play_warning_ping_sfx(severity: float = 1.0) -> void:
	shot_sfx.play()
	var playback = shot_sfx.get_stream_playback()
	if playback is AudioStreamGeneratorPlayback:
		var generator: AudioStreamGeneratorPlayback = playback
		var sample_rate := 44100.0
		var length := 0.08 + clampf(severity, 0.1, 3.0) * 0.02
		var freq := 720.0 + 60.0 * clampf(severity, 0.1, 3.0)
		for i in range(int(sample_rate * length)):
			var t := float(i) / sample_rate
			var env := exp(-t * 21.0)
			var sample := sin(TAU * freq * t) * env * 0.12
			generator.push_frame(Vector2(sample, sample))


func play_boss_warning_sfx() -> void:
	hit_sfx.play()
	var playback = hit_sfx.get_stream_playback()
	if playback is AudioStreamGeneratorPlayback:
		var generator: AudioStreamGeneratorPlayback = playback
		var sample_rate := 44100.0
		var length := 0.28
		for i in range(int(sample_rate * length)):
			var t := float(i) / sample_rate
			var env := exp(-t * 7.6)
			var freq := 210.0 + 70.0 * sin(t * TAU * 2.0)
			var sample := sin(TAU * freq * t) * env * 0.27
			generator.push_frame(Vector2(sample, sample))


func play_boss_phase2_sfx() -> void:
	hit_sfx.play()
	var playback = hit_sfx.get_stream_playback()
	if playback is AudioStreamGeneratorPlayback:
		var generator: AudioStreamGeneratorPlayback = playback
		var sample_rate := 44100.0
		var length := 0.32
		for i in range(int(sample_rate * length)):
			var t := float(i) / sample_rate
			var env := exp(-t * 6.4)
			var freq := 140.0 + 110.0 * sin(t * TAU * 3.2)
			var sample := sin(TAU * freq * t) * env * 0.31
			generator.push_frame(Vector2(sample, sample))


func play_boss_echo_spawn_sfx() -> void:
	shot_sfx.play()
	var playback = shot_sfx.get_stream_playback()
	if playback is AudioStreamGeneratorPlayback:
		var generator: AudioStreamGeneratorPlayback = playback
		var sample_rate := 44100.0
		var length := 0.14
		for i in range(int(sample_rate * length)):
			var t := float(i) / sample_rate
			var env := exp(-t * 13.0)
			var freq := 460.0 + 220.0 * sin(t * TAU * 6.0)
			var sample := sin(TAU * freq * t) * env * 0.19
			generator.push_frame(Vector2(sample, sample))


func play_boss_true_reveal_sfx() -> void:
	hit_sfx.play()
	var playback = hit_sfx.get_stream_playback()
	if playback is AudioStreamGeneratorPlayback:
		var generator: AudioStreamGeneratorPlayback = playback
		var sample_rate := 44100.0
		var length := 0.18
		for i in range(int(sample_rate * length)):
			var t := float(i) / sample_rate
			var env := exp(-t * 10.0)
			var sweep := 280.0 + 640.0 * t
			var sample := sin(TAU * sweep * t) * env * 0.24
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
	if enemy_manager != null and enemy_manager.has_method("setup_pool"):
		enemy_manager.setup_pool(pool_manager, ENEMY_POOL_KEY, ENEMY_POOL_PREWARM)
	if xp_pickup_scene != null and pool_manager.has_method("ensure_pool"):
		pool_manager.ensure_pool(PICKUP_POOL_KEY, xp_pickup_scene, pickup_layer, PICKUP_POOL_PREWARM)


func _on_pickup_recycle_requested(pickup: Node) -> void:
	if pickup == null:
		return
	if pool_manager != null and pool_manager.has_method("recycle"):
		pool_manager.recycle(PICKUP_POOL_KEY, pickup)
	else:
		pickup.queue_free()
