extends RefCounted
class_name DayWorldPhaseSmokeHelper

const PHASE_ORDER := ["morning", "noon", "afternoon", "evening"]


func t(key: String, args: Dictionary = {}) -> String:
	if Localization == null or not Localization.has_method("t"):
		return key
	return String(Localization.call("t", key, args))


func expected_phase_snapshot(phase: String) -> Dictionary:
	var normalized := phase.strip_edges().to_lower()
	var actions_remaining := _actions_until_evening(normalized)
	var night_ready := normalized == "evening" or normalized == "night"
	var phase_label := t("meta.phase.%s" % normalized)
	var phase_cue := _phase_idle_cue(normalized)
	return {
		"phase": normalized,
		"phase_visual_id": normalized,
		"night_ready": night_ready,
		"night_enabled": night_ready,
		"wait_enabled": not night_ready,
		"dock_gate_open": night_ready,
		"visible_town_npc_count": _visible_town_npc_count(normalized),
		"hud_phase": normalized,
		"hud_actions_until_evening": actions_remaining,
		"hud_phase_track_active_index": _phase_track_index(normalized),
		"phase_idle_cue": phase_cue,
		"restaurant_cue": _restaurant_cue(normalized),
		"shop_cue": _shop_cue(normalized),
		"wait_cue": _wait_cue(actions_remaining, night_ready),
		"night_cue": _night_cue(actions_remaining, night_ready),
		"hud_clock_status_text": (
			t("meta.day_hud.clock_phase_ready", {"phase": phase_label})
			if night_ready
			else t("meta.day_hud.clock_phase_progress", {
				"phase": phase_label,
				"value": actions_remaining
			})
		),
		"hud_departure_text": (
			t("meta.day_hud.departure_ready")
			if night_ready
			else t("meta.day_hud.departure_locked", {"value": actions_remaining})
		)
	}


func _actions_until_evening(phase: String) -> int:
	match phase:
		"morning":
			return 3
		"noon":
			return 2
		"afternoon":
			return 1
		_:
			return 0


func _visible_town_npc_count(phase: String) -> int:
	match phase:
		"evening":
			return 1
		"night":
			return 0
		_:
			return 2


func _phase_track_index(phase: String) -> int:
	if phase == "night":
		return PHASE_ORDER.size() - 1
	var phase_index := PHASE_ORDER.find(phase)
	return phase_index if phase_index >= 0 else 0


func _phase_idle_cue(phase: String) -> String:
	return t("meta.world.phase_cue_%s" % phase)


func _restaurant_cue(phase: String) -> String:
	if phase == "night":
		return t("meta.world.restaurant_cue_night")
	if phase == "evening":
		return t("meta.world.restaurant_cue_evening")
	return t("meta.world.restaurant_cue_day")


func _shop_cue(phase: String) -> String:
	if phase == "night":
		return t("meta.world.shop_cue_night")
	if phase == "evening":
		return t("meta.world.shop_cue_evening")
	return t("meta.world.shop_cue_day")


func _wait_cue(actions_remaining: int, night_ready: bool) -> String:
	if night_ready:
		return t("meta.world.wait_cue_ready")
	return t("meta.world.wait_cue_progress", {"value": actions_remaining})


func _night_cue(actions_remaining: int, night_ready: bool) -> String:
	if night_ready:
		return t("meta.world.night_cue_ready")
	return t("meta.world.night_cue_locked", {"value": actions_remaining})
