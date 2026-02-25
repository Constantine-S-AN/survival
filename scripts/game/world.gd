extends Node2D
class_name World

signal map_event_triggered(event_id: String, event_name: String, message: String)
signal hazard_state_changed(active: bool, warning_text: String)

const MapRuntimeClass := preload("res://scripts/core/map_runtime.gd")
const BossTelegraphEffectClass := preload("res://scripts/effects/boss_telegraph_effect.gd")
const ForegroundOccluderClass := preload("res://scripts/game/foreground_occluder.gd")
const FLARE_EDGE_SHADER := preload("res://assets/shaders/flare_edge_flash.gdshader")
const BACKDROP_TEXTURE_PATH := ""
const MAP_FLOOR_TEXTURES := {
	"map_trench_lab": "res://assets/textures/pixel/maps/dungeon/trench_floor_dungeon.png",
	"map_black_tide": "res://assets/textures/pixel/maps/dungeon/black_tide_floor_dungeon.png"
}
const MAP_FLOOR_SCALE := {
	"map_trench_lab": Vector2(4.40, 4.40),
	"map_black_tide": Vector2(4.25, 4.25)
}
const MAP_FLOOR_MODULATE := {
	"map_trench_lab": Color(0.90, 0.86, 0.92, 1.0),
	"map_black_tide": Color(0.76, 0.90, 1.00, 1.0)
}
const MAP_OBSTACLE_MODULATE := {
	"map_trench_lab": Color(0.70, 0.72, 0.74, 1.0),
	"map_black_tide": Color(0.66, 0.68, 0.72, 1.0)
}
const OBSTACLE_TEXTURES := {
	"house": "res://assets/textures/pixel/maps/props/dungeon/house_dungeon.png",
	"tower": "res://assets/textures/pixel/maps/props/dungeon/tower_dungeon.png",
	"barracks": "res://assets/textures/pixel/maps/props/dungeon/barracks_dungeon.png",
	"crate": "res://assets/textures/pixel/maps/props/dungeon/crate_dungeon.png",
	"barrier": "res://assets/textures/pixel/maps/props/dungeon/chest_dungeon.png",
	"hedge_chunk": "res://assets/textures/pixel/maps/props/dungeon/house_dungeon.png",
	"hedge_corner": "res://assets/textures/pixel/maps/props/dungeon/tower_dungeon.png",
	"hedge_strip": "res://assets/textures/pixel/maps/props/dungeon/barracks_dungeon.png",
	"cliff_chunk": "res://assets/textures/pixel/maps/props/dungeon/tower_dungeon.png",
	"cliff_strip": "res://assets/textures/pixel/maps/props/dungeon/barracks_dungeon.png"
}
const TERRAIN_COLLISION_LAYER := 1 << 3
const PLAYFIELD_HALF_EXTENT := 1620.0
const BORDER_THICKNESS := 140.0
const FOREGROUND_TOP_RATIOS := {
	"house": 0.54,
	"tower": 0.62,
	"barracks": 0.50,
	"hedge_chunk": 0.44,
	"hedge_corner": 0.44,
	"hedge_strip": 0.34,
	"cliff_chunk": 0.46,
	"cliff_strip": 0.36
}
const FOREGROUND_OCCLUDER_TUNING := {
	"house": {"fade_alpha": 0.24, "trigger_width_mult": 0.64, "trigger_height_mult": 0.62, "trigger_bias_mult": 0.40},
	"tower": {"fade_alpha": 0.30, "trigger_width_mult": 0.70, "trigger_height_mult": 0.72, "trigger_bias_mult": 0.36},
	"barracks": {"fade_alpha": 0.24, "trigger_width_mult": 0.68, "trigger_height_mult": 0.62, "trigger_bias_mult": 0.40},
	"hedge_chunk": {"fade_alpha": 0.34, "trigger_width_mult": 0.74, "trigger_height_mult": 0.74, "trigger_bias_mult": 0.34},
	"hedge_corner": {"fade_alpha": 0.34, "trigger_width_mult": 0.74, "trigger_height_mult": 0.72, "trigger_bias_mult": 0.34},
	"hedge_strip": {"fade_alpha": 0.34, "trigger_width_mult": 0.84, "trigger_height_mult": 0.64, "trigger_bias_mult": 0.28},
	"cliff_chunk": {"fade_alpha": 0.34, "trigger_width_mult": 0.74, "trigger_height_mult": 0.74, "trigger_bias_mult": 0.34},
	"cliff_strip": {"fade_alpha": 0.34, "trigger_width_mult": 0.84, "trigger_height_mult": 0.64, "trigger_bias_mult": 0.28}
}
const FOREGROUND_FADE_ALPHA := 0.30
const FOREGROUND_FADE_DURATION := 0.10
const FOREGROUND_TRIGGER_WIDTH_MULT := 0.74
const FOREGROUND_TRIGGER_HEIGHT_MULT := 0.70
const FOREGROUND_TRIGGER_BIAS_MULT := 0.34
const CANDLE_TEXTURE_PATHS: Array[String] = [
	"res://assets/textures/pixel/maps/props/dungeon/candle_1.png",
	"res://assets/textures/pixel/maps/props/dungeon/candle_2.png",
	"res://assets/textures/pixel/maps/props/dungeon/candle_3.png",
	"res://assets/textures/pixel/maps/props/dungeon/candle_4.png"
]
const CANDLE_WORLD_SIZE_PX := 22.0
const CANDLE_LIGHT_SCALE := 0.38
const CANDLE_LIGHT_COLOR := Color(1.0, 0.72, 0.42, 1.0)
const CANDLE_BASE_LIGHT_ENERGY := 1.24
const CANDLE_LIGHT_ENERGY_MIN_MULT := 0.94
const CANDLE_LIGHT_ENERGY_MAX_MULT := 1.28
const CANDLE_FRAME_SEC := 0.12
const FLARE_BOOST_DURATION := 5.0
const FLARE_ENERGY_MULT := 2.05
const FLARE_RADIUS_MULT := 1.48
const FLARE_ENERGY_INTENSITY_BONUS := 0.95
const FLARE_RADIUS_INTENSITY_BONUS := 0.82
const FLARE_LIGHT_BASE_COLOR := Color(0.96, 0.84, 0.72, 1.0)
const FLARE_LIGHT_HOT_COLOR := Color(1.0, 0.92, 0.78, 1.0)
const FLARE_SCREEN_FLASH_PEAK_SEC := 0.16
const FLARE_SCREEN_FLASH_DECAY_SEC := 5.0
const FLARE_SCREEN_FLASH_PEAK_TARGET := Color(0.74, 0.72, 0.66, 1.0)
const FLARE_SCREEN_FLASH_DECAY_TARGET := Color(0.32, 0.30, 0.27, 1.0)
const FLARE_SCREEN_FLASH_PEAK_BLEND := 0.98
const FLARE_SCREEN_FLASH_DECAY_BLEND := 0.88
const FLARE_EDGE_FLASH_SEC := 0.08
const FLARE_EDGE_FLASH_MAX_STRENGTH := 1.18
const FLARE_WARM_TONE_SEC := 0.30
const FLARE_WARM_TONE_ALPHA := 0.20
const FLARE_WARM_TONE_COLOR := Color(1.0, 0.85, 0.66, 1.0)
const FOG_INTRO_DURATION := 5.0
const FOG_INTRO_START_COLOR := Color(1.0, 1.0, 1.0, 1.0)
const FOG_LIGHT_TEXTURE_SIZE := 1024
const MAP_ROOM_SYNTAX_KEYS := [
	"narrow_corridor",
	"open_hall",
	"dense_obstacles",
	"sparse_candle"
]

@onready var projectile_manager = $ProjectileManager
@onready var pool_manager = $PoolManager
@onready var enemy_manager = $EnemyManager
@onready var sonar_manager = $SonarManager
@onready var pickup_layer: Node2D = $PickupLayer
@onready var player = $Player
@onready var camera = $Player/Camera2D
@onready var fog_darkness: CanvasModulate = $FogDarkness
@onready var fog_light: PointLight2D = $Player/FogLight
@onready var backdrop_main: Sprite2D = $Backdrop/BackdropMain
@onready var backdrop_accent: Sprite2D = $Backdrop/BackdropAccent
@onready var terrain_floor: Sprite2D = $Terrain/Floor
@onready var obstacle_visuals: Node2D = $Terrain/ObstacleVisuals
@onready var obstacle_foreground_visuals: Node2D = $Terrain/ForegroundVisuals
@onready var candle_layer: Node2D = $Terrain/Candles
@onready var obstacle_bodies: Node2D = $Terrain/ObstacleBodies
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
var runtime_reward_multipliers: Dictionary = {
	"xp": 1.0,
	"rarity": 1.0,
	"drop": 1.0,
	"meta_currency": 1.0
}
var runtime_drop_multiplier: float = 1.0
var last_hazard_active: bool = false
var last_hazard_warning_active: bool = false
var boss_fx_layer: Node2D
var _fog_light_texture_cache: Texture2D = null
var _terrain_texture_cache: Dictionary = {}
var _candle_nodes: Array[Dictionary] = []
var _candle_frames_cache: Array[Texture2D] = []
var _flare_boost_remaining: float = 0.0
var _flare_boost_intensity: float = 1.0
var _flare_screen_flash_peak_remaining: float = 0.0
var _flare_screen_flash_decay_remaining: float = 0.0
var _flare_edge_flash_remaining: float = 0.0
var _flare_warm_tone_remaining: float = 0.0
var _fog_darkness_base_color: Color = Color(0.039, 0.078, 0.133, 1.0)
var _fog_intro_remaining: float = 0.0
var _flare_fx_layer: CanvasLayer
var _flare_edge_overlay: ColorRect
var _flare_edge_material: ShaderMaterial
var _flare_warm_overlay: ColorRect
var _layout_seed: int = 0
var _active_map_obstacles: Array = []
var _active_map_candles: Array[Vector2] = []
var _active_map_room_syntax: Array[String] = []
const PROJECTILE_POOL_KEY := "projectile"
const PICKUP_POOL_KEY := "pickup"
const ENEMY_POOL_KEY := "enemy"
const PROJECTILE_POOL_PREWARM := 72
const PICKUP_POOL_PREWARM := 48
const ENEMY_POOL_PREWARM := 120


func _ready() -> void:
	sfx_rng.seed = int(Time.get_unix_time_from_system())
	_create_flare_screen_fx_overlays()
	_apply_optional_backdrop_texture()
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
	_apply_map_visual_layout(current_map_id)
	FeedbackBus.hit_landed.connect(_on_hit_landed)
	FeedbackBus.shot_fired.connect(_on_shot_fired)
	if not FeedbackBus.sonar_pulse_requested.is_connected(_on_sonar_pulse_requested):
		FeedbackBus.sonar_pulse_requested.connect(_on_sonar_pulse_requested)
	if enemy_manager != null:
		enemy_manager.boss_telegraph_requested.connect(_on_boss_telegraph_requested)
		enemy_manager.boss_echoes_spawned.connect(_on_boss_echoes_spawned)
		enemy_manager.boss_true_form_revealed.connect(_on_boss_true_form_revealed)
	set_process(true)
	queue_redraw()


func _create_flare_screen_fx_overlays() -> void:
	if _flare_fx_layer != null:
		return
	_flare_fx_layer = CanvasLayer.new()
	_flare_fx_layer.name = "FlareScreenFxLayer"
	_flare_fx_layer.layer = 2
	add_child(_flare_fx_layer)

	_flare_warm_overlay = ColorRect.new()
	_flare_warm_overlay.name = "FlareWarmOverlay"
	_flare_warm_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_flare_warm_overlay.offset_left = 0.0
	_flare_warm_overlay.offset_top = 0.0
	_flare_warm_overlay.offset_right = 0.0
	_flare_warm_overlay.offset_bottom = 0.0
	_flare_warm_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_flare_warm_overlay.visible = false
	_flare_warm_overlay.color = Color(
		FLARE_WARM_TONE_COLOR.r,
		FLARE_WARM_TONE_COLOR.g,
		FLARE_WARM_TONE_COLOR.b,
		0.0
	)
	_flare_fx_layer.add_child(_flare_warm_overlay)

	_flare_edge_overlay = ColorRect.new()
	_flare_edge_overlay.name = "FlareEdgeOverlay"
	_flare_edge_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_flare_edge_overlay.offset_left = 0.0
	_flare_edge_overlay.offset_top = 0.0
	_flare_edge_overlay.offset_right = 0.0
	_flare_edge_overlay.offset_bottom = 0.0
	_flare_edge_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_flare_edge_overlay.visible = false
	_flare_edge_overlay.color = Color(1.0, 1.0, 1.0, 1.0)
	_flare_edge_material = ShaderMaterial.new()
	_flare_edge_material.shader = FLARE_EDGE_SHADER
	_flare_edge_material.set_shader_parameter("edge_strength", 0.0)
	_flare_edge_material.set_shader_parameter("edge_softness", 0.18)
	_flare_edge_material.set_shader_parameter("edge_color", Color(1.0, 1.0, 1.0, 1.0))
	_flare_edge_overlay.material = _flare_edge_material
	_flare_fx_layer.add_child(_flare_edge_overlay)


func _process(delta: float) -> void:
	_tick_candle_fx(delta)
	if _flare_boost_remaining > 0.0:
		_flare_boost_remaining = maxf(0.0, _flare_boost_remaining - delta)
	_flare_boost_intensity = maxf(1.0, _flare_boost_intensity - delta * 0.50)
	if _flare_screen_flash_peak_remaining > 0.0:
		_flare_screen_flash_peak_remaining = maxf(0.0, _flare_screen_flash_peak_remaining - delta)
	if _flare_screen_flash_decay_remaining > 0.0:
		_flare_screen_flash_decay_remaining = maxf(0.0, _flare_screen_flash_decay_remaining - delta)
	if _flare_edge_flash_remaining > 0.0:
		_flare_edge_flash_remaining = maxf(0.0, _flare_edge_flash_remaining - delta)
	if _flare_warm_tone_remaining > 0.0:
		_flare_warm_tone_remaining = maxf(0.0, _flare_warm_tone_remaining - delta)
	if _fog_intro_remaining > 0.0:
		_fog_intro_remaining = maxf(0.0, _fog_intro_remaining - delta)
	_update_player_fog_light()
	_update_fog_darkness_modulate()
	_update_flare_screen_fx_overlays()


func _update_flare_screen_fx_overlays() -> void:
	if _flare_edge_overlay == null or _flare_warm_overlay == null:
		return
	var edge_ratio := clampf(_flare_edge_flash_remaining / FLARE_EDGE_FLASH_SEC, 0.0, 1.0)
	var edge_strength := pow(edge_ratio, 0.44) * FLARE_EDGE_FLASH_MAX_STRENGTH
	_flare_edge_overlay.visible = edge_strength > 0.001
	if _flare_edge_material != null:
		_flare_edge_material.set_shader_parameter("edge_strength", edge_strength)

	var warm_ratio := clampf(_flare_warm_tone_remaining / FLARE_WARM_TONE_SEC, 0.0, 1.0)
	var warm_alpha := pow(warm_ratio, 0.72) * FLARE_WARM_TONE_ALPHA
	var warm_color := _flare_warm_overlay.color
	warm_color.a = warm_alpha
	_flare_warm_overlay.color = warm_color
	_flare_warm_overlay.visible = warm_alpha > 0.002


func _apply_optional_backdrop_texture() -> void:
	if backdrop_main == null or backdrop_accent == null:
		return
	if BACKDROP_TEXTURE_PATH.is_empty():
		backdrop_main.visible = false
		backdrop_accent.visible = false
		return
	if not ResourceLoader.exists(BACKDROP_TEXTURE_PATH, "Texture2D"):
		backdrop_main.visible = false
		backdrop_accent.visible = false
		return
	var texture_variant := load(BACKDROP_TEXTURE_PATH)
	if not (texture_variant is Texture2D):
		backdrop_main.visible = false
		backdrop_accent.visible = false
		return
	var texture: Texture2D = texture_variant
	backdrop_main.texture = texture
	backdrop_accent.texture = texture
	backdrop_main.visible = true
	backdrop_accent.visible = true


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
	set_runtime_reward_multipliers({})
	set_contract_modifiers(contract_bundle, contract_ids)
	apply_sonar_config(base_sonar_config if not base_sonar_config.is_empty() else DataRegistry.get_sonar_config())
	_flare_boost_remaining = 0.0
	_flare_boost_intensity = 1.0
	_flare_screen_flash_peak_remaining = 0.0
	_flare_screen_flash_decay_remaining = 0.0
	_flare_edge_flash_remaining = 0.0
	_flare_warm_tone_remaining = 0.0
	_fog_intro_remaining = 0.0
	_update_flare_screen_fx_overlays()
	set_current_map(map_id, run_seed)


func begin_run() -> void:
	_fog_intro_remaining = FOG_INTRO_DURATION
	_update_fog_darkness_modulate()
	if enemy_manager != null and enemy_manager.has_method("begin_run"):
		enemy_manager.begin_run()


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
	_fog_darkness_base_color = dark

	_ensure_fog_light_texture()
	_update_player_fog_light()
	_update_fog_darkness_modulate()


func set_fog_enabled(enabled: bool) -> void:
	fog_enabled = enabled
	fog_darkness.visible = fog_enabled
	fog_light.enabled = fog_enabled


func is_fog_enabled() -> bool:
	return fog_enabled


func _build_fog_light_texture() -> Texture2D:
	var gradient := Gradient.new()
	gradient.offsets = PackedFloat32Array([0.0, 0.26, 0.56, 0.82, 1.0])
	gradient.colors = PackedColorArray([
		Color(1.0, 1.0, 1.0, 0.98),
		Color(1.0, 1.0, 1.0, 0.74),
		Color(1.0, 1.0, 1.0, 0.36),
		Color(1.0, 1.0, 1.0, 0.12),
		Color(1.0, 1.0, 1.0, 0.0)
	])
	var texture := GradientTexture2D.new()
	texture.width = FOG_LIGHT_TEXTURE_SIZE
	texture.height = FOG_LIGHT_TEXTURE_SIZE
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
		_layout_seed = 0
		_clear_map_visual_layout()
		_apply_fog_modifier_bundle({})
		if sonar_manager != null and sonar_manager.has_method("set_runtime_modifiers"):
			sonar_manager.set_runtime_modifiers({})
		if player != null and is_instance_valid(player) and player.has_method("apply_environment_modifiers"):
			player.apply_environment_modifiers({}, {}, {})
		if enemy_manager != null and enemy_manager.has_method("set_map_spawn_modifiers"):
			enemy_manager.set_map_spawn_modifiers({})
		return
	var seed := run_seed if run_seed != 0 else int(Time.get_unix_time_from_system())
	_layout_seed = seed
	current_map_id = resolved_map_id
	_apply_map_visual_layout(current_map_id)
	var map_def := DataRegistry.get_map(current_map_id)
	var hazard_def := DataRegistry.get_hazard(String(map_def.get("hazard_id", "")))
	var event_table := DataRegistry.get_event_table(String(map_def.get("event_table_id", "")))
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


func set_runtime_reward_multipliers(multipliers: Dictionary = {}) -> void:
	runtime_reward_multipliers = {
		"xp": maxf(0.0, float(multipliers.get("xp", multipliers.get("xp_mult", 1.0)))),
		"rarity": maxf(0.0, float(multipliers.get("rarity", multipliers.get("rarity_mult", 1.0)))),
		"drop": maxf(0.0, float(multipliers.get("drop", multipliers.get("drop_mult", 1.0)))),
		"meta_currency": maxf(0.0, float(multipliers.get("meta_currency", multipliers.get("meta_currency_mult", 1.0))))
	}
	runtime_drop_multiplier = maxf(0.0, float(runtime_reward_multipliers.get("drop", 1.0)))
	if player != null and is_instance_valid(player) and player.has_method("set_run_reward_multipliers"):
		player.set_run_reward_multipliers(runtime_reward_multipliers)


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
		"contract_event_rate_mult": float(events_mod.get("rate_mult", 1.0)),
		"terrain_room_syntax": _active_map_room_syntax.duplicate(),
		"terrain_obstacle_count": _active_map_obstacles.size(),
		"terrain_candle_count": _active_map_candles.size()
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
			"reveal_duration_mult": float(sonar_mods.get("reveal_duration_mult", 1.0)),
			"max_radius_mult": float(sonar_mods.get("max_radius_mult", 1.0))
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
	_fog_darkness_base_color = dark
	_ensure_fog_light_texture()
	_update_player_fog_light()
	_update_fog_darkness_modulate()


func _ensure_fog_light_texture() -> void:
	if fog_light == null:
		return
	if _fog_light_texture_cache == null:
		if fog_light.texture != null:
			_fog_light_texture_cache = fog_light.texture
		else:
			_fog_light_texture_cache = _build_fog_light_texture()
	if fog_light.texture == null and _fog_light_texture_cache != null:
		fog_light.texture = _fog_light_texture_cache


func _update_player_fog_light() -> void:
	if fog_light == null:
		return
	var base_radius := float(effective_fog_config.get("vision_radius", float(base_fog_config.get("vision_radius", 420.0))))
	var visibility_penalty_mult := 1.0
	if player != null and is_instance_valid(player) and player.has_method("get_visibility_penalty_multiplier"):
		visibility_penalty_mult = clampf(float(player.call("get_visibility_penalty_multiplier")), 0.30, 1.0)
	base_radius *= visibility_penalty_mult
	var base_scale := maxf(0.2, base_radius / 256.0)
	var base_energy := float(effective_fog_config.get("vision_energy", float(base_fog_config.get("vision_energy", 1.05))))
	base_energy *= lerpf(0.72, 1.0, visibility_penalty_mult)
	var boost_ratio := clampf(_flare_boost_remaining / FLARE_BOOST_DURATION, 0.0, 1.0)
	var eased := boost_ratio * boost_ratio
	var intensity_norm := clampf((_flare_boost_intensity - 0.8) / 1.6, 0.0, 1.0)
	var radius_mult := FLARE_RADIUS_MULT + (FLARE_RADIUS_INTENSITY_BONUS * intensity_norm)
	var energy_mult := FLARE_ENERGY_MULT + (FLARE_ENERGY_INTENSITY_BONUS * intensity_norm)
	fog_light.texture_scale = base_scale * lerpf(1.0, radius_mult, eased)
	fog_light.energy = base_energy * lerpf(1.0, energy_mult, eased)
	fog_light.color = FLARE_LIGHT_BASE_COLOR.lerp(FLARE_LIGHT_HOT_COLOR, eased)


func _update_fog_darkness_modulate() -> void:
	if fog_darkness == null:
		return
	var base_color := _get_fog_darkness_baseline_color()
	if not fog_enabled:
		fog_darkness.color = base_color
		return
	if _flare_screen_flash_peak_remaining > 0.0:
		var peak_ratio := clampf(_flare_screen_flash_peak_remaining / FLARE_SCREEN_FLASH_PEAK_SEC, 0.0, 1.0)
		var peak_eased := pow(peak_ratio, 0.45)
		var peak_target := base_color.lerp(FLARE_SCREEN_FLASH_PEAK_TARGET, FLARE_SCREEN_FLASH_PEAK_BLEND)
		fog_darkness.color = base_color.lerp(peak_target, peak_eased)
		return
	if _flare_screen_flash_decay_remaining > 0.0:
		var decay_ratio := clampf(_flare_screen_flash_decay_remaining / FLARE_SCREEN_FLASH_DECAY_SEC, 0.0, 1.0)
		var decay_eased := pow(decay_ratio, 0.70)
		var decay_target := base_color.lerp(FLARE_SCREEN_FLASH_DECAY_TARGET, FLARE_SCREEN_FLASH_DECAY_BLEND)
		fog_darkness.color = base_color.lerp(decay_target, decay_eased)
		return
	fog_darkness.color = base_color


func _get_fog_darkness_baseline_color() -> Color:
	if _fog_intro_remaining <= 0.0 or FOG_INTRO_DURATION <= 0.0:
		return _fog_darkness_base_color
	var intro_ratio := clampf(1.0 - (_fog_intro_remaining / FOG_INTRO_DURATION), 0.0, 1.0)
	var intro_eased := intro_ratio * intro_ratio * (3.0 - 2.0 * intro_ratio)
	return FOG_INTRO_START_COLOR.lerp(_fog_darkness_base_color, intro_eased)


func _trigger_flare_screen_flash(strength: float) -> void:
	var normalized := clampf(strength, 0.05, 2.0)
	var peak_dur := FLARE_SCREEN_FLASH_PEAK_SEC * lerpf(0.92, 1.35, normalized * 0.5)
	var decay_dur := FLARE_SCREEN_FLASH_DECAY_SEC
	var edge_dur := FLARE_EDGE_FLASH_SEC * lerpf(0.94, 1.18, normalized * 0.5)
	var warm_dur := FLARE_WARM_TONE_SEC * lerpf(0.84, 1.28, normalized * 0.5)
	_flare_screen_flash_peak_remaining = maxf(_flare_screen_flash_peak_remaining, peak_dur)
	_flare_screen_flash_decay_remaining = maxf(_flare_screen_flash_decay_remaining, decay_dur)
	_flare_edge_flash_remaining = maxf(_flare_edge_flash_remaining, edge_dur)
	_flare_warm_tone_remaining = maxf(_flare_warm_tone_remaining, warm_dur)
	_update_fog_darkness_modulate()
	_update_flare_screen_fx_overlays()


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
	var scaled_total := float(clamped_count) * runtime_drop_multiplier
	var scaled_count := int(floor(scaled_total))
	if sfx_rng.randf() < (scaled_total - float(scaled_count)):
		scaled_count += 1
	clamped_count = clampi(scaled_count, 0, 24)
	if clamped_count <= 0:
		return
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
		"strength": intensity,
		"reveal_duration_multiplier": _get_player_sonar_reveal_multiplier()
	})


func _on_shot_fired(_world_position: Vector2, intensity: float) -> void:
	_play_shot_sfx(intensity)


func _on_sonar_pulse_requested(world_position: Vector2, payload: Dictionary) -> void:
	var source := String(payload.get("source", "")).strip_edges().to_lower()
	if source != "skill" and source != "flare":
		return
	var screen_flash_strength := clampf(float(payload.get("screen_flash", 0.0)), 0.0, 2.0)
	if screen_flash_strength <= 0.0 and (source == "skill" or bool(payload.get("player_skill", false))):
		screen_flash_strength = 1.0
	if screen_flash_strength > 0.0:
		_trigger_flare_screen_flash(screen_flash_strength)
	var strength := clampf(float(payload.get("strength", 1.0)), 0.2, 2.4)
	var ping_count := int(payload.get("ping_count", -1))
	_play_flare_skill_sfx(strength, ping_count)
	var flare_duration_mult := clampf(float(payload.get("flare_duration_mult", 1.0)), 0.5, 1.8)
	_flare_boost_remaining = maxf(_flare_boost_remaining, FLARE_BOOST_DURATION * flare_duration_mult)
	_flare_boost_intensity = maxf(_flare_boost_intensity, strength)
	apply_screen_shake(0.12 + strength * 0.09)
	spawn_boss_telegraph("ring", {
		"origin": world_position,
		"radius": 120.0 + strength * 138.0,
		"duration": 0.22,
		"line_width": 8.8,
		"color": "#fff0c9"
	})
	var tree := get_tree()
	if tree == null:
		return
	tree.create_timer(0.09).timeout.connect(func() -> void:
		if not is_inside_tree():
			return
		spawn_boss_telegraph("ring", {
			"origin": world_position,
			"radius": 226.0 + strength * 154.0,
			"duration": 0.24,
			"line_width": 6.0,
			"color": "#ffd79b"
		})
	)
	tree.create_timer(0.18).timeout.connect(func() -> void:
		if not is_inside_tree():
			return
		spawn_boss_telegraph("ring", {
			"origin": world_position,
			"radius": 322.0 + strength * 180.0,
			"duration": 0.24,
			"line_width": 3.6,
			"color": "#ffe9c7"
		})
	)


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
		"source": "flare",
		"strength": 0.95,
		"radius_scale": 1.2,
		"reveal_duration_multiplier": _get_player_sonar_reveal_multiplier()
	})


func _get_player_sonar_reveal_multiplier() -> float:
	if player == null or not is_instance_valid(player):
		return 1.0
	if not player.has_method("get_sonar_reveal_duration_multiplier"):
		return 1.0
	return maxf(0.05, float(player.call("get_sonar_reveal_duration_multiplier")))


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


func _play_flare_skill_sfx(intensity: float, ping_count: int = -1) -> void:
	shot_sfx.play()
	var playback = shot_sfx.get_stream_playback()
	if not (playback is AudioStreamGeneratorPlayback):
		return
	var generator: AudioStreamGeneratorPlayback = playback
	var sample_rate := 44100.0
	var length := 0.24
	var count_boost := 1.0 + clampf(float(maxi(0, ping_count)) * 0.03, 0.0, 0.24)
	for i in range(int(sample_rate * length)):
		var t := float(i) / sample_rate
		var env := exp(-t * 8.6)
		var chirp := sin(TAU * (330.0 + 760.0 * t) * t)
		var tail := sin(TAU * (180.0 + 30.0 * sin(t * 19.0)) * t)
		var sample := (chirp * 0.58 + tail * 0.42) * env * (0.14 + intensity * 0.08) * count_boost
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
	draw_rect(Rect2(Vector2(-4200.0, -4200.0), Vector2(8400.0, 8400.0)), Color(0.022, 0.016, 0.012, 1.0), true)
	if terrain_floor != null and terrain_floor.visible:
		return
	for i in range(-30, 31):
		var x := float(i) * 240.0
		draw_line(Vector2(x, -4200.0), Vector2(x, 4200.0), Color(0.38, 0.29, 0.18, 0.10), 1.0)
		var y := float(i) * 240.0
		draw_line(Vector2(-4200.0, y), Vector2(4200.0, y), Color(0.38, 0.29, 0.18, 0.10), 1.0)


func _apply_map_visual_layout(map_id: String) -> void:
	_cache_tactical_layout(map_id)
	_apply_map_floor_texture(map_id)
	_rebuild_map_obstacles(map_id)
	queue_redraw()


func _clear_map_visual_layout() -> void:
	if terrain_floor != null:
		terrain_floor.visible = false
		terrain_floor.texture = null
	_clear_obstacle_nodes()
	_active_map_obstacles.clear()
	_active_map_candles.clear()
	_active_map_room_syntax.clear()
	_flare_boost_remaining = 0.0
	_flare_boost_intensity = 1.0
	_flare_screen_flash_peak_remaining = 0.0
	_flare_screen_flash_decay_remaining = 0.0
	_flare_edge_flash_remaining = 0.0
	_flare_warm_tone_remaining = 0.0
	_fog_intro_remaining = 0.0
	_update_fog_darkness_modulate()
	_update_flare_screen_fx_overlays()


func _apply_map_floor_texture(map_id: String) -> void:
	if terrain_floor == null:
		return
	var path := String(MAP_FLOOR_TEXTURES.get(map_id, ""))
	if path.is_empty() or not ResourceLoader.exists(path, "Texture2D"):
		terrain_floor.visible = false
		terrain_floor.texture = null
		return
	var texture := _load_cached_texture(path)
	if texture == null:
		terrain_floor.visible = false
		terrain_floor.texture = null
		return
	terrain_floor.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	terrain_floor.texture = texture
	terrain_floor.centered = true
	terrain_floor.position = Vector2.ZERO
	terrain_floor.scale = _get_map_floor_scale(map_id)
	terrain_floor.modulate = _get_map_floor_modulate(map_id)
	terrain_floor.visible = true


func _rebuild_map_obstacles(map_id: String) -> void:
	_clear_obstacle_nodes()
	var layout := _get_map_obstacle_layout(map_id)
	for row_variant in layout:
		if not (row_variant is Dictionary):
			continue
		_spawn_obstacle_row(row_variant)
	_spawn_world_borders()
	_spawn_map_candles(map_id)


func _clear_obstacle_nodes() -> void:
	if obstacle_visuals != null:
		for child in obstacle_visuals.get_children():
			child.queue_free()
	if obstacle_foreground_visuals != null:
		for child in obstacle_foreground_visuals.get_children():
			child.queue_free()
	if obstacle_bodies != null:
		for child in obstacle_bodies.get_children():
			child.queue_free()
	if candle_layer != null:
		for child in candle_layer.get_children():
			child.queue_free()
	_candle_nodes.clear()


func _get_candle_frames() -> Array[Texture2D]:
	if not _candle_frames_cache.is_empty():
		return _candle_frames_cache
	var frames: Array[Texture2D] = []
	for path in CANDLE_TEXTURE_PATHS:
		var texture := _load_cached_texture(path)
		if texture == null:
			continue
		frames.append(texture)
	_candle_frames_cache = frames
	return _candle_frames_cache


func _spawn_map_candles(_map_id: String) -> void:
	if candle_layer == null:
		return
	_ensure_fog_light_texture()
	var candle_frames := _get_candle_frames()
	if candle_frames.is_empty():
		return
	for pos in _get_map_candle_positions(_map_id):
		var anchor := Node2D.new()
		anchor.position = pos
		anchor.z_index = 4
		candle_layer.add_child(anchor)

		var sprite := Sprite2D.new()
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		sprite.centered = true
		sprite.texture = candle_frames[0]
		var max_dim := maxf(float(candle_frames[0].get_width()), float(candle_frames[0].get_height()))
		sprite.scale = Vector2.ONE * (CANDLE_WORLD_SIZE_PX / maxf(1.0, max_dim))
		sprite.position = Vector2(0.0, -6.0)
		anchor.add_child(sprite)

		var light := PointLight2D.new()
		if _fog_light_texture_cache != null:
			light.texture = _fog_light_texture_cache
		light.enabled = true
		light.texture_scale = CANDLE_LIGHT_SCALE
		light.energy = CANDLE_BASE_LIGHT_ENERGY * sfx_rng.randf_range(0.96, 1.08)
		light.color = CANDLE_LIGHT_COLOR
		light.position = Vector2(0.0, -10.0)
		anchor.add_child(light)

		_candle_nodes.append({
			"sprite": sprite,
			"light": light,
			"frame": sfx_rng.randi_range(0, candle_frames.size() - 1),
			"timer": sfx_rng.randf_range(0.0, CANDLE_FRAME_SEC),
			"phase": sfx_rng.randf_range(0.0, TAU),
			"base_energy": light.energy
		})


func _tick_candle_fx(delta: float) -> void:
	var candle_frames := _get_candle_frames()
	if candle_frames.is_empty() or _candle_nodes.is_empty():
		return
	for i in range(_candle_nodes.size()):
		var row_variant: Variant = _candle_nodes[i]
		if not (row_variant is Dictionary):
			continue
		var row: Dictionary = row_variant
		var sprite_variant: Variant = row.get("sprite", null)
		var light_variant: Variant = row.get("light", null)
		if not (sprite_variant is Sprite2D) or not (light_variant is PointLight2D):
			continue
		var sprite: Sprite2D = sprite_variant
		var light: PointLight2D = light_variant
		var timer := float(row.get("timer", 0.0)) + delta
		var frame := int(row.get("frame", 0))
		if timer >= CANDLE_FRAME_SEC:
			timer = 0.0
			frame = (frame + 1) % candle_frames.size()
		sprite.texture = candle_frames[frame]
		var phase := float(row.get("phase", 0.0)) + delta * 4.3
		var base_energy := float(row.get("base_energy", CANDLE_BASE_LIGHT_ENERGY))
		var flicker := 0.90 + 0.14 * sin(phase) + 0.06 * sin(phase * 2.8)
		light.enabled = true
		light.energy = base_energy * clampf(flicker, CANDLE_LIGHT_ENERGY_MIN_MULT, CANDLE_LIGHT_ENERGY_MAX_MULT)
		row["timer"] = timer
		row["frame"] = frame
		row["phase"] = phase
		_candle_nodes[i] = row


func _get_map_candle_positions(map_id: String) -> Array[Vector2]:
	if _active_map_candles.is_empty():
		_cache_tactical_layout(map_id)
	return _active_map_candles.duplicate()


func _spawn_obstacle_row(definition: Dictionary) -> void:
	if obstacle_bodies == null:
		return
	var pos_variant: Variant = definition.get("pos", Vector2.ZERO)
	var pos := pos_variant as Vector2 if pos_variant is Vector2 else Vector2.ZERO
	var size_variant: Variant = definition.get("size", Vector2(80.0, 44.0))
	var size := size_variant as Vector2 if size_variant is Vector2 else Vector2(80.0, 44.0)
	var texture_key := String(definition.get("texture", ""))
	var texture_path := String(OBSTACLE_TEXTURES.get(texture_key, ""))
	var texture := _load_cached_texture(texture_path)
	var visual_scale := Vector2.ONE
	var visual_scale_variant: Variant = definition.get("scale", Vector2.ONE)
	if visual_scale_variant is Vector2:
		visual_scale = visual_scale_variant

	var body := StaticBody2D.new()
	body.collision_layer = TERRAIN_COLLISION_LAYER
	body.collision_mask = 0
	body.position = pos
	var shape := RectangleShape2D.new()
	shape.size = size
	var collider := CollisionShape2D.new()
	collider.shape = shape
	body.add_child(collider)
	obstacle_bodies.add_child(body)

	if obstacle_visuals != null and texture != null:
		var sprite := Sprite2D.new()
		sprite.texture = texture
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		sprite.centered = true
		sprite.position = pos
		sprite.scale = visual_scale
		var y_offset := float(definition.get("y_offset", 0.0))
		sprite.position.y += y_offset
		var tint_variant: Variant = definition.get("modulate", null)
		if tint_variant is Color:
			sprite.modulate = tint_variant
		else:
			sprite.modulate = _get_map_obstacle_modulate(current_map_id)
		obstacle_visuals.add_child(sprite)
		if _should_use_foreground_occluder(definition, texture_key):
			_spawn_foreground_occluder(definition, texture_key, texture, sprite.position, visual_scale, size, tint_variant)


func _should_use_foreground_occluder(definition: Dictionary, texture_key: String) -> bool:
	if definition.has("foreground_enabled"):
		return bool(definition.get("foreground_enabled", false))
	return FOREGROUND_TOP_RATIOS.has(texture_key)


func _spawn_foreground_occluder(
	definition: Dictionary,
	texture_key: String,
	texture: Texture2D,
	visual_position: Vector2,
	visual_scale: Vector2,
	collider_size: Vector2,
	tint_variant: Variant
) -> void:
	if obstacle_foreground_visuals == null or texture == null:
		return
	var tuning := _get_foreground_tuning(texture_key)
	var default_top_ratio := float(FOREGROUND_TOP_RATIOS.get(texture_key, -1.0))
	var top_ratio := clampf(float(definition.get("foreground_top_ratio", float(tuning.get("top_ratio", default_top_ratio)))), 0.0, 0.95)
	if top_ratio <= 0.0:
		return
	var tex_w := float(texture.get_width())
	var tex_h := float(texture.get_height())
	if tex_w < 1.0 or tex_h < 1.0:
		return
	var region_h := maxi(1, int(round(tex_h * top_ratio)))

	var slice := Sprite2D.new()
	slice.texture = texture
	slice.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	slice.centered = true
	slice.region_enabled = true
	slice.region_rect = Rect2(0.0, 0.0, tex_w, float(region_h))
	slice.scale = visual_scale
	var region_shift := (tex_h - float(region_h)) * 0.5 * visual_scale.y
	slice.position = visual_position - Vector2(0.0, region_shift)
	if tint_variant is Color:
		slice.modulate = tint_variant
	else:
		slice.modulate = _get_map_obstacle_modulate(current_map_id)
	obstacle_foreground_visuals.add_child(slice)

	var visual_w := tex_w * absf(visual_scale.x)
	var visual_h := tex_h * absf(visual_scale.y)
	var top_h := float(region_h) * absf(visual_scale.y)
	var trigger_width_mult := float(definition.get("foreground_trigger_width_mult", float(tuning.get("trigger_width_mult", FOREGROUND_TRIGGER_WIDTH_MULT))))
	var trigger_height_mult := float(definition.get("foreground_trigger_height_mult", float(tuning.get("trigger_height_mult", FOREGROUND_TRIGGER_HEIGHT_MULT))))
	var trigger_w := maxf(
		collider_size.x * trigger_width_mult,
		visual_w * 0.55
	)
	trigger_w = clampf(trigger_w, 12.0, visual_w * 0.96)
	var trigger_h := maxf(
		top_h * trigger_height_mult,
		collider_size.y * 0.58
	)
	trigger_h = clampf(trigger_h, 12.0, visual_h * 0.92)
	var trigger_bias_mult := float(definition.get("foreground_trigger_bias_mult", float(tuning.get("trigger_bias_mult", FOREGROUND_TRIGGER_BIAS_MULT))))
	var trigger_bias := float(definition.get("foreground_trigger_y_bias", top_h * trigger_bias_mult))
	var trigger_offset := Vector2(0.0, -visual_h * 0.5 + trigger_h * 0.5 + trigger_bias)

	var occluder := ForegroundOccluderClass.new()
	occluder.fade_alpha = clampf(float(definition.get("foreground_fade_alpha", float(tuning.get("fade_alpha", FOREGROUND_FADE_ALPHA)))), 0.12, 0.95)
	occluder.fade_duration = maxf(0.01, float(definition.get("foreground_fade_duration", FOREGROUND_FADE_DURATION)))
	obstacle_foreground_visuals.add_child(occluder)
	occluder.configure(slice, Vector2(trigger_w, trigger_h), slice.position + trigger_offset)


func _get_foreground_tuning(texture_key: String) -> Dictionary:
	var row_variant: Variant = FOREGROUND_OCCLUDER_TUNING.get(texture_key, {})
	if row_variant is Dictionary:
		return (row_variant as Dictionary).duplicate(true)
	return {}


func _spawn_world_borders() -> void:
	if obstacle_bodies == null:
		return
	_spawn_border_rect(Vector2(0.0, -PLAYFIELD_HALF_EXTENT - BORDER_THICKNESS * 0.5), Vector2(PLAYFIELD_HALF_EXTENT * 2.0 + BORDER_THICKNESS * 2.0, BORDER_THICKNESS))
	_spawn_border_rect(Vector2(0.0, PLAYFIELD_HALF_EXTENT + BORDER_THICKNESS * 0.5), Vector2(PLAYFIELD_HALF_EXTENT * 2.0 + BORDER_THICKNESS * 2.0, BORDER_THICKNESS))
	_spawn_border_rect(Vector2(-PLAYFIELD_HALF_EXTENT - BORDER_THICKNESS * 0.5, 0.0), Vector2(BORDER_THICKNESS, PLAYFIELD_HALF_EXTENT * 2.0))
	_spawn_border_rect(Vector2(PLAYFIELD_HALF_EXTENT + BORDER_THICKNESS * 0.5, 0.0), Vector2(BORDER_THICKNESS, PLAYFIELD_HALF_EXTENT * 2.0))


func _spawn_border_rect(pos: Vector2, size: Vector2) -> void:
	var body := StaticBody2D.new()
	body.collision_layer = TERRAIN_COLLISION_LAYER
	body.collision_mask = 0
	body.position = pos
	var shape := RectangleShape2D.new()
	shape.size = size
	var collider := CollisionShape2D.new()
	collider.shape = shape
	body.add_child(collider)
	obstacle_bodies.add_child(body)


func _load_cached_texture(path: String) -> Texture2D:
	if path.is_empty():
		return null
	if _terrain_texture_cache.has(path):
		var cached: Variant = _terrain_texture_cache[path]
		if cached is Texture2D:
			return cached
	if not ResourceLoader.exists(path, "Texture2D"):
		return null
	var loaded := load(path)
	if loaded is Texture2D:
		_terrain_texture_cache[path] = loaded
		return loaded
	return null


func _get_map_floor_modulate(map_id: String) -> Color:
	var tone_variant: Variant = MAP_FLOOR_MODULATE.get(map_id, Color(0.56, 0.58, 0.62, 1.0))
	return tone_variant if tone_variant is Color else Color(0.56, 0.58, 0.62, 1.0)


func _get_map_floor_scale(map_id: String) -> Vector2:
	var scale_variant: Variant = MAP_FLOOR_SCALE.get(map_id, Vector2(4.3, 4.3))
	return scale_variant if scale_variant is Vector2 else Vector2(4.3, 4.3)


func _get_map_obstacle_modulate(map_id: String) -> Color:
	var tone_variant: Variant = MAP_OBSTACLE_MODULATE.get(map_id, Color(0.66, 0.68, 0.72, 1.0))
	return tone_variant if tone_variant is Color else Color(0.66, 0.68, 0.72, 1.0)


func _get_map_obstacle_layout(map_id: String) -> Array:
	if _active_map_obstacles.is_empty():
		_cache_tactical_layout(map_id)
	return _active_map_obstacles.duplicate(true)


func _cache_tactical_layout(map_id: String) -> void:
	if map_id.is_empty():
		_active_map_obstacles.clear()
		_active_map_candles.clear()
		_active_map_room_syntax.clear()
		return
	var layout := _build_tactical_layout(map_id, _layout_seed)
	var obstacle_variant: Variant = layout.get("obstacles", [])
	if obstacle_variant is Array:
		_active_map_obstacles = (obstacle_variant as Array).duplicate(true)
	else:
		_active_map_obstacles = []
	var candle_variant: Variant = layout.get("candles", [])
	if candle_variant is Array:
		_active_map_candles = _normalize_vector2_array(candle_variant as Array)
	else:
		_active_map_candles = []
	var room_variant: Variant = layout.get("room_syntax", MAP_ROOM_SYNTAX_KEYS)
	if room_variant is Array:
		_active_map_room_syntax = _normalize_string_array(room_variant as Array)
	else:
		_active_map_room_syntax = _normalize_string_array(MAP_ROOM_SYNTAX_KEYS)


func _normalize_vector2_array(source: Array) -> Array[Vector2]:
	var out: Array[Vector2] = []
	for point_variant in source:
		if point_variant is Vector2:
			out.append(point_variant)
	return out


func _normalize_string_array(source: Array) -> Array[String]:
	var out: Array[String] = []
	for row_variant in source:
		var value := String(row_variant).strip_edges()
		if value.is_empty():
			continue
		if out.has(value):
			continue
		out.append(value)
	return out


func _build_tactical_layout(map_id: String, seed: int) -> Dictionary:
	match map_id:
		"map_black_tide":
			return _build_black_tide_tactical_layout(seed)
		_:
			return _build_trench_lab_tactical_layout(seed)


func _build_trench_lab_tactical_layout(seed: int) -> Dictionary:
	var rows: Array = []
	var candles: Array[Vector2] = []
	var mirror_dense := (absi(seed) % 2) == 1
	var dense_sign := -1.0 if mirror_dense else 1.0
	var dense_center_x := 860.0 * dense_sign
	var sparse_center_x := -dense_center_x

	# Room syntax A: narrow corridor
	for x in [-1110.0, -760.0, -410.0, -60.0, 290.0, 640.0, 990.0]:
		_append_obstacle(rows, "hedge_strip", Vector2(x, -980.0), Vector2(250.0, 70.0), Vector2(0.70, 0.70), -14.0)
	for x in [-940.0, -540.0, -140.0, 260.0, 660.0, 1060.0]:
		_append_obstacle(rows, "cliff_strip", Vector2(x, -620.0), Vector2(250.0, 70.0), Vector2(0.70, 0.70), -14.0)
	for x in [-650.0, -260.0, 130.0, 520.0, 890.0]:
		_append_obstacle(rows, "barrier", Vector2(x, -810.0), Vector2(118.0, 42.0), Vector2(2.30, 2.30), -12.0)
	for x in [-820.0, -430.0, -40.0, 350.0, 740.0]:
		_append_obstacle(rows, "crate", Vector2(x, -730.0), Vector2(62.0, 42.0), Vector2(2.28, 2.28), -12.0)

	# Room syntax B: open hall
	for point in [Vector2(-320.0, -180.0), Vector2(320.0, -180.0), Vector2(-320.0, 180.0), Vector2(320.0, 180.0)]:
		_append_obstacle(rows, "tower", point, Vector2(110.0, 68.0), Vector2(0.64, 0.64), -56.0)
	_append_obstacle(rows, "barrier", Vector2(0.0, -330.0), Vector2(122.0, 42.0), Vector2(2.24, 2.24), -12.0)
	_append_obstacle(rows, "barrier", Vector2(0.0, 330.0), Vector2(122.0, 42.0), Vector2(2.24, 2.24), -12.0)

	# Room syntax C: dense obstacle block
	_append_obstacle(rows, "barracks", Vector2(dense_center_x + 340.0, 560.0), Vector2(138.0, 62.0), Vector2(0.60, 0.60), -44.0)
	_append_obstacle(rows, "house", Vector2(dense_center_x - 330.0, 940.0), Vector2(100.0, 58.0), Vector2(0.64, 0.64), -52.0)
	var dense_x_offsets := [-250.0, -70.0, 110.0, 290.0]
	var dense_y_rows := [420.0, 620.0, 820.0, 1020.0]
	for row_idx in range(dense_y_rows.size()):
		var y := float(dense_y_rows[row_idx])
		for col_idx in range(dense_x_offsets.size()):
			if (row_idx == 1 and col_idx == 1) or (row_idx == 2 and col_idx == 2):
				continue
			var x := dense_center_x + float(dense_x_offsets[col_idx])
			var is_crate := ((row_idx + col_idx) % 2) == 0
			var tex := "crate" if is_crate else "barrier"
			var col_size := Vector2(62.0, 42.0) if is_crate else Vector2(110.0, 42.0)
			var col_scale := Vector2(2.34, 2.34) if is_crate else Vector2(2.18, 2.18)
			_append_obstacle(rows, tex, Vector2(x, y), col_size, col_scale, -12.0)

	# Room syntax D: sparse-candle zone
	_append_obstacle(rows, "house", Vector2(sparse_center_x - 180.0, 660.0), Vector2(100.0, 58.0), Vector2(0.64, 0.64), -52.0)
	_append_obstacle(rows, "tower", Vector2(sparse_center_x + 180.0, 920.0), Vector2(112.0, 68.0), Vector2(0.68, 0.68), -58.0)
	_append_obstacle(rows, "barracks", Vector2(sparse_center_x, 1110.0), Vector2(136.0, 62.0), Vector2(0.60, 0.60), -44.0)
	_append_obstacle(rows, "hedge_strip", Vector2(sparse_center_x, 780.0), Vector2(246.0, 68.0), Vector2(0.70, 0.70), -14.0)

	_append_candle_line(candles, Vector2(-1080.0, -1030.0), Vector2(360.0, 0.0), 7)
	_append_candle_line(candles, Vector2(-900.0, -590.0), Vector2(360.0, 0.0), 6)
	_append_candle_ring(candles, Vector2(0.0, 0.0), Vector2(460.0, 340.0), 8)
	for point in [
		Vector2(dense_center_x - 360.0, 380.0),
		Vector2(dense_center_x - 360.0, 1120.0),
		Vector2(dense_center_x + 360.0, 380.0),
		Vector2(dense_center_x + 360.0, 1120.0),
		Vector2(dense_center_x + 40.0, 760.0)
	]:
		candles.append(point)
	candles.append(Vector2(sparse_center_x - 120.0, 540.0))
	candles.append(Vector2(sparse_center_x + 160.0, 980.0))

	var syntax: Array[String] = _normalize_string_array(MAP_ROOM_SYNTAX_KEYS)
	return {
		"room_syntax": syntax,
		"obstacles": rows,
		"candles": _dedupe_candle_positions(candles)
	}


func _build_black_tide_tactical_layout(seed: int) -> Dictionary:
	var rows: Array = []
	var candles: Array[Vector2] = []
	var dense_in_north := (absi(seed) % 3) != 0
	var dense_center := Vector2(-910.0, -780.0 if dense_in_north else 760.0)
	var sparse_center := Vector2(80.0, 860.0 if dense_in_north else -860.0)

	# Room syntax A: narrow corridor (vertical)
	for y in [-1100.0, -780.0, -460.0, -140.0, 180.0, 500.0, 820.0, 1140.0]:
		_append_obstacle(rows, "cliff_chunk", Vector2(700.0, y), Vector2(188.0, 122.0), Vector2(0.48, 0.48), -24.0)
	for y in [-940.0, -620.0, -300.0, 20.0, 340.0, 660.0, 980.0]:
		_append_obstacle(rows, "hedge_chunk", Vector2(1080.0, y), Vector2(188.0, 122.0), Vector2(0.48, 0.48), -24.0)
	for y in [-560.0, -180.0, 200.0, 580.0]:
		_append_obstacle(rows, "barrier", Vector2(890.0, y), Vector2(118.0, 42.0), Vector2(2.28, 2.28), -12.0)

	# Room syntax B: open hall
	var hall_center := Vector2(-360.0, -120.0)
	for point in [
		hall_center + Vector2(-280.0, -170.0),
		hall_center + Vector2(280.0, -170.0),
		hall_center + Vector2(-280.0, 170.0),
		hall_center + Vector2(280.0, 170.0)
	]:
		_append_obstacle(rows, "tower", point, Vector2(108.0, 68.0), Vector2(0.62, 0.62), -54.0)
	_append_obstacle(rows, "cliff_strip", hall_center + Vector2(0.0, -300.0), Vector2(236.0, 68.0), Vector2(0.68, 0.68), -14.0)
	_append_obstacle(rows, "cliff_strip", hall_center + Vector2(0.0, 300.0), Vector2(236.0, 68.0), Vector2(0.68, 0.68), -14.0)

	# Room syntax C: dense obstacle block
	var dense_x_offsets := [-250.0, -70.0, 110.0, 290.0]
	var dense_y_offsets := [-250.0, -70.0, 110.0, 290.0]
	for row_idx in range(dense_y_offsets.size()):
		for col_idx in range(dense_x_offsets.size()):
			if (row_idx == 1 and col_idx == 2) or (row_idx == 2 and col_idx == 1):
				continue
			var point := dense_center + Vector2(float(dense_x_offsets[col_idx]), float(dense_y_offsets[row_idx]))
			var is_crate := ((row_idx + col_idx + 1) % 2) == 0
			var tex := "crate" if is_crate else "barrier"
			var col_size := Vector2(62.0, 42.0) if is_crate else Vector2(112.0, 42.0)
			var col_scale := Vector2(2.30, 2.30) if is_crate else Vector2(2.16, 2.16)
			_append_obstacle(rows, tex, point, col_size, col_scale, -12.0)
	_append_obstacle(rows, "barracks", dense_center + Vector2(-360.0, -120.0), Vector2(136.0, 62.0), Vector2(0.58, 0.58), -44.0)
	_append_obstacle(rows, "house", dense_center + Vector2(340.0, 220.0), Vector2(100.0, 58.0), Vector2(0.62, 0.62), -52.0)

	# Room syntax D: sparse-candle zone
	_append_obstacle(rows, "house", sparse_center + Vector2(-220.0, -120.0), Vector2(100.0, 58.0), Vector2(0.64, 0.64), -52.0)
	_append_obstacle(rows, "tower", sparse_center + Vector2(210.0, 70.0), Vector2(110.0, 68.0), Vector2(0.66, 0.66), -56.0)
	_append_obstacle(rows, "cliff_strip", sparse_center + Vector2(0.0, -260.0), Vector2(242.0, 68.0), Vector2(0.68, 0.68), -14.0)

	_append_candle_line(candles, Vector2(780.0, -1000.0), Vector2(0.0, 360.0), 6)
	_append_candle_line(candles, Vector2(980.0, -820.0), Vector2(0.0, 360.0), 6)
	_append_candle_ring(candles, hall_center, Vector2(430.0, 310.0), 8)
	for point in [
		dense_center + Vector2(-380.0, -320.0),
		dense_center + Vector2(380.0, -320.0),
		dense_center + Vector2(-380.0, 320.0),
		dense_center + Vector2(380.0, 320.0),
		dense_center + Vector2(0.0, 0.0)
	]:
		candles.append(point)
	candles.append(sparse_center + Vector2(-130.0, -340.0))
	candles.append(sparse_center + Vector2(120.0, 250.0))

	var syntax: Array[String] = _normalize_string_array(MAP_ROOM_SYNTAX_KEYS)
	return {
		"room_syntax": syntax,
		"obstacles": rows,
		"candles": _dedupe_candle_positions(candles)
	}


func _append_obstacle(
	rows: Array,
	texture_key: String,
	pos: Vector2,
	size: Vector2,
	scale: Vector2 = Vector2.ONE,
	y_offset: float = 0.0,
	extra: Dictionary = {}
) -> void:
	var row := {
		"texture": texture_key,
		"pos": pos,
		"size": size,
		"scale": scale,
		"y_offset": y_offset
	}
	for key_variant in extra.keys():
		row[key_variant] = extra[key_variant]
	rows.append(row)


func _append_candle_line(candles: Array[Vector2], start: Vector2, step: Vector2, count: int) -> void:
	for i in range(maxi(0, count)):
		candles.append(start + step * float(i))


func _append_candle_ring(
	candles: Array[Vector2],
	center: Vector2,
	radius: Vector2,
	count: int,
	phase_offset: float = 0.0
) -> void:
	var safe_count := maxi(1, count)
	for i in range(safe_count):
		var t := (float(i) / float(safe_count)) * TAU + phase_offset
		candles.append(center + Vector2(cos(t) * radius.x, sin(t) * radius.y))


func _dedupe_candle_positions(candles: Array[Vector2]) -> Array[Vector2]:
	var out: Array[Vector2] = []
	var seen: Dictionary = {}
	for point in candles:
		var key := "%d:%d" % [int(round(point.x)), int(round(point.y))]
		if seen.has(key):
			continue
		seen[key] = true
		out.append(point)
	return out


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
