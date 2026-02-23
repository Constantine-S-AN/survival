extends RefCounted
class_name UISfx

const STREAM_HOVER := preload("res://assets/audio/shot.wav")
const STREAM_CLICK := preload("res://assets/audio/hit.wav")
const STREAM_CONFIRM := preload("res://assets/audio/shot.wav")
const STREAM_TIER_UP := preload("res://assets/audio/hit.wav")
const STREAM_REWARD := preload("res://assets/audio/shot.wav")

const EVENT_GAP_MSEC: Dictionary = {
	"hover": 50,
	"click": 20,
	"confirm": 25,
	"tier_up": 80,
	"reward": 120
}

static var _enabled: bool = true
static var _last_play_msec: Dictionary = {}
static var _players: Dictionary = {}


static func set_enabled(enabled: bool) -> void:
	# TODO(settings): bind this to a future UI SFX toggle in Settings.
	_enabled = enabled


static func is_enabled() -> bool:
	return _enabled


static func play_hover() -> void:
	_play("hover", STREAM_HOVER, -30.0, 1.42)


static func play_click() -> void:
	_play("click", STREAM_CLICK, -27.0, 1.12)


static func play_confirm() -> void:
	_play("confirm", STREAM_CONFIRM, -24.0, 1.0)


static func play_tier_up() -> void:
	_play("tier_up", STREAM_TIER_UP, -20.0, 0.86)


static func play_reward() -> void:
	_play("reward", STREAM_REWARD, -19.0, 0.94)


static func _play(event_key: String, stream: AudioStream, volume_db: float, pitch_scale: float) -> void:
	if not _enabled:
		return
	if stream == null:
		return
	if DisplayServer.get_name() == "headless":
		return
	var now := Time.get_ticks_msec()
	var min_gap := int(EVENT_GAP_MSEC.get(event_key, 0))
	var last_time := int(_last_play_msec.get(event_key, -1000000))
	if now - last_time < min_gap:
		return
	_last_play_msec[event_key] = now
	var player := _ensure_player(event_key, stream)
	if player == null:
		return
	player.stream = stream
	player.volume_db = volume_db
	player.pitch_scale = pitch_scale
	player.play()


static func _ensure_player(event_key: String, stream: AudioStream) -> AudioStreamPlayer:
	var cached_variant: Variant = _players.get(event_key, null)
	if cached_variant is AudioStreamPlayer:
		var cached: AudioStreamPlayer = cached_variant
		if is_instance_valid(cached):
			return cached
	var main_loop := Engine.get_main_loop()
	if not (main_loop is SceneTree):
		return null
	var root := (main_loop as SceneTree).root
	if root == null:
		return null
	var node_name := "__ui_sfx_%s" % event_key
	var existing := root.get_node_or_null(node_name)
	if existing is AudioStreamPlayer:
		var existing_player: AudioStreamPlayer = existing
		_players[event_key] = existing_player
		return existing_player
	var player := AudioStreamPlayer.new()
	player.name = node_name
	player.bus = "Master"
	player.stream = stream
	player.max_polyphony = 1
	root.add_child(player)
	_players[event_key] = player
	return player
