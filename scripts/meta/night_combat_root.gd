extends Node
class_name NightCombatRoot

signal session_completed(summary: Dictionary)
signal session_bootstrap_completed(success: bool)

const NIGHT_RUN_SCENE := preload("res://scenes/night/NightRun.tscn")
const GAME_ROOT_SCENE := preload("res://scenes/game/GameRoot.tscn")

@onready var session_mount: Node = $SessionMount

var _active_request: Dictionary = {}
var _game_root: Node = null
var _last_generated_seed: int = 0


func start_session(request: Dictionary) -> void:
	_teardown_session()
	_active_request = request.duplicate(true)
	_game_root = NIGHT_RUN_SCENE.instantiate()
	if _game_root == null:
		_game_root = GAME_ROOT_SCENE.instantiate()
	if _game_root != null and _game_root.has_signal("session_completed"):
		_game_root.connect("session_completed", Callable(self, "_on_session_finished"))
	if _game_root != null and _game_root.has_signal("session_bootstrapped"):
		_game_root.connect("session_bootstrapped", Callable(self, "_on_session_bootstrapped"))
	elif _game_root != null and _game_root.has_signal("embedded_session_finished"):
		_game_root.connect("embedded_session_finished", Callable(self, "_on_session_finished"))
	if _game_root == null:
		session_bootstrap_completed.emit(false)
		return
	if _game_root.has_method("start_session"):
		session_mount.add_child(_game_root)
		_game_root.call("start_session", _active_request)
		return
	if _game_root.has_method("set_embedded_session_request"):
		_game_root.call("set_embedded_session_request", _active_request)
	session_mount.add_child(_game_root)


func is_session_active() -> bool:
	return _game_root != null and is_instance_valid(_game_root)


func debug_get_snapshot() -> Dictionary:
	var snapshot := {
		"active": is_session_active(),
		"day": int(_active_request.get("day", 0)),
		"session_duration_sec": float(_active_request.get("session_duration_sec", 0.0)),
		"day_feedback": _active_request.get("day_feedback", {}).duplicate(true) if _active_request.get("day_feedback", {}) is Dictionary else {}
	}
	if _game_root != null and is_instance_valid(_game_root) and _game_root.has_method("debug_get_snapshot"):
		snapshot["night_run"] = _game_root.call("debug_get_snapshot")
	return snapshot


func debug_get_run_snapshot() -> Dictionary:
	if _game_root != null and is_instance_valid(_game_root) and _game_root.has_method("debug_get_snapshot"):
		var snapshot_variant: Variant = _game_root.call("debug_get_snapshot")
		return snapshot_variant if snapshot_variant is Dictionary else {}
	return {}


func debug_use_exit(target_room_id: String) -> bool:
	if _game_root != null and is_instance_valid(_game_root) and _game_root.has_method("debug_use_exit"):
		_game_root.call("debug_use_exit", target_room_id)
		return true
	return false


func debug_force_clear_room() -> bool:
	if _game_root != null and is_instance_valid(_game_root) and _game_root.has_method("debug_force_clear_room"):
		_game_root.call("debug_force_clear_room")
		return true
	return false


func debug_select_room_reward(option_index: int) -> bool:
	if _game_root != null and is_instance_valid(_game_root) and _game_root.has_method("debug_select_room_reward"):
		return bool(_game_root.call("debug_select_room_reward", option_index))
	return false


func debug_interact_room_feature(interaction_id: String = "") -> bool:
	if _game_root != null and is_instance_valid(_game_root) and _game_root.has_method("debug_interact_room_feature"):
		return bool(_game_root.call("debug_interact_room_feature", interaction_id))
	return false


func debug_request_extract() -> bool:
	if _game_root != null and is_instance_valid(_game_root) and _game_root.has_method("debug_request_extract"):
		return bool(_game_root.call("debug_request_extract"))
	return false


func stop_session() -> void:
	if _game_root != null and is_instance_valid(_game_root) and _game_root.has_method("stop_session"):
		_game_root.call("stop_session")
	_teardown_session()
	get_tree().paused = false


func _next_runtime_seed() -> int:
	var wall_usec: int = int(floor(Time.get_unix_time_from_system() * 1000000.0))
	var tick_usec: int = int(Time.get_ticks_usec())
	var seed: int = abs(wall_usec ^ (tick_usec << 11) ^ (tick_usec >> 3))
	if seed == 0:
		seed = 1
	if seed <= _last_generated_seed:
		seed = _last_generated_seed + 1
	_last_generated_seed = seed
	return seed


func debug_complete_session(summary_override: Dictionary = {}) -> void:
	if not is_session_active():
		return
	var request := _active_request.duplicate(true)
	var exit_reason := String(summary_override.get("exit_reason", "completed")).strip_edges().to_lower()
	if exit_reason != "abandoned" and exit_reason != "extracted":
		exit_reason = "completed"
	var payload := {
		"time_survived_sec": maxf(0.0, float(summary_override.get("time_survived_sec", 90.0))),
		"kills": maxi(0, int(summary_override.get("kills", 18))),
		"level": maxi(1, int(summary_override.get("level", 3))),
		"map_id": String(request.get("map_id", DataRegistry.get_default_map_id())),
		"map_name": String(DataRegistry.get_map(String(request.get("map_id", DataRegistry.get_default_map_id()))).get("name", request.get("map_id", DataRegistry.get_default_map_id()))),
		"contract_ids": request.get("contract_ids", []),
		"contract_names": _resolve_contract_names(request.get("contract_ids", [])),
		"drop_pickups_spawned": maxi(0, int(summary_override.get("drop_pickups_spawned", 4))),
		"multipliers": {
			"xp": 1.0,
			"rarity": 1.0,
			"drop": 1.0,
			"meta_currency": 1.0
		},
		"meta_currency_earned": {
			"base": maxi(0, int(summary_override.get("meta_currency_base", 4))),
			"multiplier": 1.0,
			"total": maxi(0, int(summary_override.get("meta_currency_total", 4)))
		},
		"weapon_name": String(summary_override.get("weapon_name", "Silent Dart")),
		"weapon_id": String(summary_override.get("weapon_id", "silence_dart")),
		"noise_peak_tier": String(summary_override.get("noise_peak_tier", "Alert")),
		"seed": int(summary_override.get("seed", request.get("seed", _next_runtime_seed()))),
		"exit_reason": exit_reason,
		"abandoned": exit_reason == "abandoned"
	}
	for key_variant in summary_override.keys():
		var key := String(key_variant)
		if payload.has(key):
			continue
		payload[key] = summary_override[key_variant]
	_emit_session_completed(payload)


func _on_session_finished(summary: Dictionary) -> void:
	_emit_session_completed(summary)


func _on_session_bootstrapped(success: bool) -> void:
	session_bootstrap_completed.emit(success)


func _emit_session_completed(summary: Dictionary) -> void:
	var payload := summary.duplicate(true)
	_teardown_session()
	get_tree().paused = false
	session_completed.emit(payload)


func _teardown_session() -> void:
	if _game_root != null and is_instance_valid(_game_root):
		_game_root.queue_free()
	_game_root = null
	_active_request.clear()


func _resolve_contract_names(contract_ids_variant: Variant) -> Array[String]:
	var names: Array[String] = []
	if not (contract_ids_variant is Array):
		return names
	for contract_id_variant in (contract_ids_variant as Array):
		var contract_id := String(contract_id_variant).strip_edges()
		if contract_id.is_empty():
			continue
		var contract := DataRegistry.get_contract(contract_id)
		names.append(String(contract.get("name", contract_id)))
	return names
