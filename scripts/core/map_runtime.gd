extends RefCounted
class_name MapRuntime

const DEFAULT_MODIFIERS: Dictionary = {
	"fog": {
		"vision_radius_mult": 1.0,
		"noise_strength_add": 0.0,
		"scanline_strength_add": 0.0
	},
	"sonar": {
		"wave_speed_mult": 1.0,
		"max_radius_mult": 1.0,
		"reveal_duration_mult": 1.0
	},
	"noise": {
		"gain_mult": 1.0,
		"decay_mult": 1.0
	},
	"spawner": {
		"spawn_rate_mult": 1.0,
		"spawn_cap_mult": 1.0,
		"pursuer_chance_add": 0.0
	},
	"rewards": {
		"xp_mult": 1.0
	}
}

var map_def: Dictionary = {}
var hazard_def: Dictionary = {}
var event_table: Dictionary = {}
var rng := RandomNumberGenerator.new()

var elapsed_time: float = 0.0
var hazard_active: bool = false
var hazard_warning_active: bool = false
var hazard_cycle_remaining: float = 0.0
var hazard_active_remaining: float = 0.0
var event_roll_remaining: float = 0.0
var event_cooldowns: Dictionary = {}
var active_event_effects: Array[Dictionary] = []
var last_event_triggered: String = ""
var last_snapshot: Dictionary = {}


func setup(new_map_def: Dictionary, new_hazard_def: Dictionary, new_event_table: Dictionary, seed: int) -> void:
	map_def = new_map_def.duplicate(true)
	hazard_def = new_hazard_def.duplicate(true)
	event_table = new_event_table.duplicate(true)
	elapsed_time = 0.0
	hazard_active = false
	hazard_warning_active = false
	hazard_cycle_remaining = maxf(0.1, float(hazard_def.get("cycle_seconds", 30.0)))
	hazard_active_remaining = 0.0
	event_roll_remaining = maxf(0.25, float(event_table.get("roll_interval_seconds", 9.0)))
	event_cooldowns.clear()
	active_event_effects.clear()
	last_event_triggered = ""
	var map_hash := String(map_def.get("id", "map")).hash()
	rng.seed = int(seed) ^ int(map_hash)
	last_snapshot = _build_snapshot([])


func update(delta: float) -> Dictionary:
	elapsed_time += maxf(0.0, delta)
	_update_hazard(delta)
	_update_event_cooldowns(delta)
	_update_active_event_effects(delta)
	var triggered_events := _roll_events(delta)
	last_snapshot = _build_snapshot(triggered_events)
	return last_snapshot.duplicate(true)


func get_snapshot() -> Dictionary:
	return last_snapshot.duplicate(true)


func _update_hazard(delta: float) -> void:
	if hazard_def.is_empty():
		hazard_active = false
		hazard_warning_active = false
		hazard_cycle_remaining = 0.0
		hazard_active_remaining = 0.0
		return
	if hazard_active:
		hazard_active_remaining = maxf(0.0, hazard_active_remaining - delta)
		if hazard_active_remaining <= 0.0:
			hazard_active = false
			hazard_warning_active = false
			hazard_cycle_remaining = maxf(0.1, float(hazard_def.get("cycle_seconds", 30.0)))
			hazard_active_remaining = 0.0
		return
	
	hazard_cycle_remaining = maxf(0.0, hazard_cycle_remaining - delta)
	var telegraph_seconds := maxf(0.0, float(hazard_def.get("telegraph_seconds", 0.0)))
	if telegraph_seconds > 0.0:
		hazard_warning_active = hazard_cycle_remaining > 0.0 and hazard_cycle_remaining <= telegraph_seconds
	else:
		hazard_warning_active = false
	if hazard_cycle_remaining <= 0.0:
		hazard_active = true
		hazard_warning_active = false
		hazard_active_remaining = maxf(0.1, float(hazard_def.get("active_seconds", 6.0)))
		hazard_cycle_remaining = 0.0


func _update_event_cooldowns(delta: float) -> void:
	for event_id_variant in event_cooldowns.keys():
		var event_id := String(event_id_variant)
		var remaining := maxf(0.0, float(event_cooldowns.get(event_id_variant, 0.0)) - delta)
		event_cooldowns[event_id] = remaining


func _update_active_event_effects(delta: float) -> void:
	if active_event_effects.is_empty():
		return
	var remaining_effects: Array[Dictionary] = []
	for effect_entry in active_event_effects:
		if effect_entry.is_empty():
			continue
		var next_remaining := maxf(0.0, float(effect_entry.get("remaining", 0.0)) - delta)
		if next_remaining <= 0.0:
			continue
		var normalized := effect_entry.duplicate(true)
		normalized["remaining"] = next_remaining
		remaining_effects.append(normalized)
	active_event_effects = remaining_effects


func _roll_events(delta: float) -> Array[Dictionary]:
	var triggered: Array[Dictionary] = []
	if event_table.is_empty():
		return triggered
	event_roll_remaining -= delta
	var roll_interval := maxf(0.25, float(event_table.get("roll_interval_seconds", 9.0)))
	while event_roll_remaining <= 0.0:
		event_roll_remaining += roll_interval
		var event_choice := _pick_event_candidate()
		if event_choice.is_empty():
			continue
		_trigger_event(event_choice)
		triggered.append(event_choice.duplicate(true))
	return triggered


func _pick_event_candidate() -> Dictionary:
	var events_variant: Variant = event_table.get("events", [])
	if not (events_variant is Array):
		return {}
	var events: Array = events_variant
	var candidates: Array[Dictionary] = []
	for event_variant in events:
		if not (event_variant is Dictionary):
			continue
		var event: Dictionary = event_variant
		var event_id := String(event.get("id", "")).strip_edges()
		if event_id.is_empty():
			continue
		var min_time := float(event.get("min_time", 0.0))
		var max_time := float(event.get("max_time", 999999.0))
		if elapsed_time < min_time or elapsed_time > max_time:
			continue
		if float(event_cooldowns.get(event_id, 0.0)) > 0.0:
			continue
		if float(event.get("weight", 0.0)) <= 0.0:
			continue
		candidates.append(event)
	if candidates.is_empty():
		return {}

	var total_weight := 0.0
	for candidate in candidates:
		total_weight += maxf(0.0, float(candidate.get("weight", 0.0)))
	if total_weight <= 0.0:
		return {}

	var roll := rng.randf_range(0.0, total_weight)
	var running := 0.0
	for candidate in candidates:
		running += maxf(0.0, float(candidate.get("weight", 0.0)))
		if roll <= running:
			return candidate
	return candidates.back()


func _trigger_event(event: Dictionary) -> void:
	var event_id := String(event.get("id", "")).strip_edges()
	if event_id.is_empty():
		return
	last_event_triggered = event_id
	event_cooldowns[event_id] = maxf(0.0, float(event.get("cooldown_seconds", 0.0)))
	var duration := maxf(0.0, float(event.get("duration_seconds", 0.0)))
	if duration <= 0.0:
		return
	var effects_variant: Variant = event.get("effects", {})
	if not (effects_variant is Dictionary):
		return
	var effects: Dictionary = effects_variant
	if effects.is_empty():
		return
	active_event_effects.append({
		"remaining": duration,
		"effects": effects.duplicate(true),
		"event_id": event_id
	})


func _build_snapshot(triggered_events: Array[Dictionary]) -> Dictionary:
	var modifiers := _compose_current_modifiers()
	return {
		"map_id": String(map_def.get("id", "")),
		"map_name": String(map_def.get("name", "")),
		"hazard_id": String(hazard_def.get("id", "")),
		"hazard_name": String(hazard_def.get("name", "")),
		"hazard_warning": String(hazard_def.get("warning_text", "")),
		"hazard_warning_active": hazard_warning_active,
		"hazard_active": hazard_active,
		"hazard_timer": hazard_active_remaining if hazard_active else hazard_cycle_remaining,
		"last_event_triggered": last_event_triggered,
		"triggered_events": triggered_events,
		"modifiers": modifiers,
		"elapsed_time": elapsed_time
	}


func _compose_current_modifiers() -> Dictionary:
	var output := _clone_default_modifiers()
	_apply_modifier_bundle(output, map_def.get("modifiers", {}))
	if hazard_active:
		_apply_modifier_bundle(output, hazard_def.get("effects", {}))
	for entry in active_event_effects:
		if entry.is_empty():
			continue
		_apply_modifier_bundle(output, entry.get("effects", {}))
	return output


func _clone_default_modifiers() -> Dictionary:
	return DEFAULT_MODIFIERS.duplicate(true)


func _apply_modifier_bundle(output: Dictionary, bundle_variant: Variant) -> void:
	if not (bundle_variant is Dictionary):
		return
	var bundle: Dictionary = bundle_variant
	for group_key_variant in bundle.keys():
		var group_key := String(group_key_variant).strip_edges().to_lower()
		if group_key.is_empty() or not output.has(group_key):
			continue
		var group_variant: Variant = bundle.get(group_key_variant, {})
		if not (group_variant is Dictionary):
			continue
		var group: Dictionary = group_variant
		var destination_variant: Variant = output.get(group_key, {})
		if not (destination_variant is Dictionary):
			continue
		var destination: Dictionary = destination_variant
		for modifier_key_variant in group.keys():
			var modifier_key := String(modifier_key_variant).strip_edges()
			if modifier_key.is_empty():
				continue
			var value := float(group.get(modifier_key_variant, 0.0))
			if modifier_key.ends_with("_mult"):
				destination[modifier_key] = maxf(0.05, float(destination.get(modifier_key, 1.0)) * value)
			else:
				destination[modifier_key] = float(destination.get(modifier_key, 0.0)) + value
		output[group_key] = destination
