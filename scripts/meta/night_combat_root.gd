extends Node
class_name NightCombatRoot

signal session_completed(summary: Dictionary)

const GAME_ROOT_SCENE := preload("res://scenes/game/GameRoot.tscn")

@onready var session_mount: Node = $SessionMount

var _active_request: Dictionary = {}
var _game_root: Node = null


func start_session(request: Dictionary) -> void:
	_teardown_session()
	_active_request = request.duplicate(true)
	_game_root = GAME_ROOT_SCENE.instantiate()
	if _game_root != null and _game_root.has_method("set_embedded_session_request"):
		_game_root.call("set_embedded_session_request", _active_request)
	if _game_root != null and _game_root.has_signal("embedded_session_finished"):
		_game_root.connect("embedded_session_finished", Callable(self, "_on_embedded_session_finished"))
	session_mount.add_child(_game_root)


func is_session_active() -> bool:
	return _game_root != null and is_instance_valid(_game_root)


func stop_session() -> void:
	_teardown_session()
	get_tree().paused = false


func debug_complete_session(summary_override: Dictionary = {}) -> void:
	if not is_session_active():
		return
	var request := _active_request.duplicate(true)
	var exit_reason := String(summary_override.get("exit_reason", "completed")).strip_edges().to_lower()
	if exit_reason != "abandoned":
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
		"seed": int(summary_override.get("seed", request.get("seed", int(Time.get_unix_time_from_system())))),
		"exit_reason": exit_reason,
		"abandoned": exit_reason == "abandoned"
	}
	_emit_session_completed(payload)


func _on_embedded_session_finished(summary: Dictionary) -> void:
	_emit_session_completed(summary)


func _emit_session_completed(summary: Dictionary) -> void:
	var payload := summary.duplicate(true)
	_teardown_session()
	get_tree().paused = false
	session_completed.emit(payload)


func _teardown_session() -> void:
	if _game_root != null and is_instance_valid(_game_root):
		_game_root.queue_free()
	_game_root = null


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
