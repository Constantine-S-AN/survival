extends Node

signal warning_emitted(payload: Dictionary)

var _sequence: int = 0


func emit_warning(
	warning_type: String,
	severity: float = 1.0,
	duration: float = 2.0,
	text_key: String = "",
	context: Dictionary = {}
) -> Dictionary:
	_sequence += 1
	var payload := {
		"id": _sequence,
		"warning_type": warning_type.strip_edges().to_lower(),
		"severity": clampf(severity, 0.1, 3.0),
		"duration": maxf(0.05, duration),
		"text_key": text_key.strip_edges().to_lower(),
		"context": context.duplicate(true),
		"timestamp_usec": Time.get_ticks_usec()
	}
	payload["sfx_bucket"] = _resolve_sfx_bucket(payload)
	payload["message"] = resolve_text(payload)
	warning_emitted.emit(payload)
	return payload


func resolve_text(payload: Dictionary) -> String:
	var text_key := String(payload.get("text_key", "")).strip_edges().to_lower()
	var context_variant: Variant = payload.get("context", {})
	var context: Dictionary = context_variant if context_variant is Dictionary else {}
	if context.has("text_override"):
		return String(context.get("text_override", ""))
	match text_key:
		"pursuer_inbound":
			return "Pursuer inbound! (%d) next ETA %.1fs" % [
				int(context.get("spawned_total", 1)),
				float(context.get("next_eta", -1.0))
			]
		"hazard_warning":
			var warning_text := String(context.get("warning_text", "")).strip_edges()
			return warning_text if not warning_text.is_empty() else "Hazard shift incoming."
		"hazard_active":
			var hazard_text := String(context.get("warning_text", "")).strip_edges()
			if hazard_text.is_empty():
				hazard_text = "Hazard shift"
			return "%s (ACTIVE)" % hazard_text
		"boss_spawn":
			var boss_spawn_text := String(context.get("telegraph_text", "")).strip_edges()
			return boss_spawn_text if not boss_spawn_text.is_empty() else "Boss detected."
		"boss_phase_shift":
			var phase_text := String(context.get("telegraph_text", "")).strip_edges()
			return phase_text if not phase_text.is_empty() else "Boss phase shift."
		"boss_attack_warning":
			return "High-energy attack telegraphed."
		"boss_echoes":
			return "False echoes deployed: %d" % int(context.get("count", 0))
		"boss_true_form_revealed":
			return "True core exposed. Push damage now."
		_:
			return String(context.get("fallback_text", "")).strip_edges()


func _resolve_sfx_bucket(payload: Dictionary) -> String:
	var warning_type := String(payload.get("warning_type", "")).strip_edges().to_lower()
	var text_key := String(payload.get("text_key", "")).strip_edges().to_lower()
	if warning_type.find("boss") >= 0 or text_key.begins_with("boss_"):
		return "boss"
	if warning_type.find("pursuer") >= 0:
		return "alert"
	var severity := float(payload.get("severity", 1.0))
	if severity >= 1.55:
		return "alert"
	return "warning"
