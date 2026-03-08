extends Node

const WorldHelperClass := preload("res://tests/smoke/world_save_load_smoke_helper.gd")
const PhaseHelperClass := preload("res://tests/smoke/day_world_phase_smoke_helper.gd")

var _helper = null
var _phase_helper = null


func _ready() -> void:
	_helper = WorldHelperClass.new(self)
	_phase_helper = PhaseHelperClass.new()
	if not await _helper.begin_session("day_world_phase_cues"):
		push_error("Failed to start DayWorld phase cue smoke")
		_cleanup(true)
		return

	if not _assert_phase_snapshot(_helper.snapshot(), "morning", "DayWorld phase cue smoke should start with morning cues and locked dock readiness"):
		return
	if not _require(not bool(_helper.meta_root.call("debug_day_world_attempt_interact", "night")), "Morning should reject dock departure interaction before night readiness"):
		return
	await _helper.await_frames(1)
	if not _require(not bool(_helper.snapshot().get("day_world_night_popup_open", false)), "Morning dock interaction should not leave a stale confirmation popup behind"):
		return

	if not await _advance_phase_with_farm_action("till", "", "noon", "DayWorld phase cue smoke should advance into noon after the first farm action"):
		return
	if not _require(not bool(_helper.meta_root.call("debug_day_world_attempt_interact", "night")), "Noon should still reject dock departure interaction"):
		return
	await _helper.await_frames(1)
	if not _require(not bool(_helper.snapshot().get("day_world_night_popup_open", false)), "Noon dock interaction should not open the night confirmation popup"):
		return

	if not await _advance_phase_with_farm_action("plant", "wheat_seed", "afternoon", "DayWorld phase cue smoke should advance into afternoon after planting"):
		return
	if not _require(not bool(_helper.meta_root.call("debug_day_world_attempt_interact", "night")), "Afternoon should still reject dock departure interaction"):
		return
	await _helper.await_frames(1)
	if not _require(not bool(_helper.snapshot().get("day_world_night_popup_open", false)), "Afternoon dock interaction should not open the night confirmation popup"):
		return

	if not await _advance_phase_with_farm_action("water", "", "evening", "DayWorld phase cue smoke should advance into evening after watering"):
		return
	if not _require(bool(_helper.meta_root.call("debug_day_world_attempt_interact", "night")), "Evening should allow dock departure interaction once readiness is reached"):
		return
	await _helper.await_frames(1)

	var popup_snapshot: Dictionary = _helper.snapshot()
	if not _require(bool(popup_snapshot.get("day_world_night_popup_open", false)), "Evening dock interaction should open the night confirmation popup"):
		return
	if not _require(String(popup_snapshot.get("day_world_prompt_text", "")) == String(popup_snapshot.get("day_world_hud_prompt_text", "")), "Night confirmation messaging should stay aligned between the world and HUD prompts"):
		return
	if not _require(bool(_helper.meta_root.call("debug_day_world_cancel_night_departure")), "Evening dock confirmation should cancel cleanly for cue regression coverage"):
		return
	await _helper.await_frames(1)

	var cancelled_snapshot: Dictionary = _helper.snapshot()
	if not _require(not bool(cancelled_snapshot.get("day_world_night_popup_open", false)), "Cancelling the evening dock confirmation should clear the popup state"):
		return
	if not _assert_phase_snapshot(cancelled_snapshot, "evening", "Evening cues should remain stable after cancelling dock confirmation"):
		return

	print("Day World phase cue smoke PASS")
	_cleanup(false)


func _advance_phase_with_farm_action(action_id: String, seed_id: String, expected_phase: String, failure_prefix: String) -> bool:
	if not _require(bool(_helper.meta_root.call("debug_day_world_select_farm_tool", action_id, seed_id)), "%s: missing tool selection" % failure_prefix):
		return false
	if not _require(bool(_helper.meta_root.call("debug_day_world_interact_farm_plot", 0)), "%s: farm interaction should succeed" % failure_prefix):
		return false
	await _helper.await_frames(1)
	return _assert_phase_snapshot(_helper.snapshot(), expected_phase, failure_prefix)


func _assert_phase_snapshot(snapshot: Dictionary, phase: String, failure_prefix: String) -> bool:
	var expected: Dictionary = _phase_helper.expected_phase_snapshot(phase)
	if not _require(String(snapshot.get("current_screen", "")) == "day_hub", "%s: current screen should remain in the day world shell" % failure_prefix):
		return false
	if not _require(String(snapshot.get("phase", "")) == String(expected.get("phase", "")), "%s: underlying phase should match" % failure_prefix):
		return false
	if not _require(String(snapshot.get("day_world_phase_visual_id", "")) == String(expected.get("phase_visual_id", "")), "%s: world phase visual id should match the day phase" % failure_prefix):
		return false
	if not _require(String(snapshot.get("day_world_hud_phase", "")) == String(expected.get("hud_phase", "")), "%s: HUD phase label should match the day phase" % failure_prefix):
		return false
	if not _require(int(snapshot.get("day_world_hud_phase_track_active_index", -1)) == int(expected.get("hud_phase_track_active_index", -1)), "%s: HUD phase track should highlight the active phase correctly" % failure_prefix):
		return false
	if not _require(int(snapshot.get("day_world_hud_actions_until_evening", -1)) == int(expected.get("hud_actions_until_evening", -1)), "%s: HUD remaining-actions cue should match the phase" % failure_prefix):
		return false
	if not _require(bool(snapshot.get("day_world_night_ready", false)) == bool(expected.get("night_ready", false)), "%s: night readiness should match the phase" % failure_prefix):
		return false
	if not _require(bool(snapshot.get("day_world_night_enabled", false)) == bool(expected.get("night_enabled", false)), "%s: dock eligibility should match readiness" % failure_prefix):
		return false
	if not _require(bool(snapshot.get("day_world_wait_enabled", false)) == bool(expected.get("wait_enabled", false)), "%s: wait bench eligibility should match the phase" % failure_prefix):
		return false
	if not _require(bool(snapshot.get("day_world_dock_gate_open", false)) == bool(expected.get("dock_gate_open", false)), "%s: dock gate presentation should match readiness" % failure_prefix):
		return false
	if not _require(int(snapshot.get("day_world_visible_town_npc_count", -1)) == int(expected.get("visible_town_npc_count", -1)), "%s: visible town NPC cues should match the phase presentation" % failure_prefix):
		return false
	if not _require(String(snapshot.get("day_world_phase_idle_cue", "")) == String(expected.get("phase_idle_cue", "")), "%s: idle world cue should match the active phase" % failure_prefix):
		return false
	if not _require(String(snapshot.get("day_world_restaurant_cue", "")) == String(expected.get("restaurant_cue", "")), "%s: restaurant cue should match the active phase" % failure_prefix):
		return false
	if not _require(String(snapshot.get("day_world_shop_cue", "")) == String(expected.get("shop_cue", "")), "%s: shop cue should match the active phase" % failure_prefix):
		return false
	if not _require(String(snapshot.get("day_world_wait_cue", "")) == String(expected.get("wait_cue", "")), "%s: wait cue should match actual wait availability" % failure_prefix):
		return false
	if not _require(String(snapshot.get("day_world_night_cue", "")) == String(expected.get("night_cue", "")), "%s: dock cue should match actual departure eligibility" % failure_prefix):
		return false
	if not _require(String(snapshot.get("day_world_hud_clock_status_text", "")) == String(expected.get("hud_clock_status_text", "")), "%s: HUD clock status should stay aligned with the phase" % failure_prefix):
		return false
	if not _require(String(snapshot.get("day_world_hud_departure_text", "")) == String(expected.get("hud_departure_text", "")), "%s: HUD departure status should stay aligned with dock readiness" % failure_prefix):
		return false
	if not _require(String(snapshot.get("day_world_prompt_text", "")) == String(snapshot.get("day_world_hud_prompt_text", "")), "%s: world and HUD prompt text should stay aligned" % failure_prefix):
		return false
	if not _require(not bool(snapshot.get("day_world_orders_open", false)), "%s: orders overlay should stay closed during phase cue checks" % failure_prefix):
		return false
	if not _require(not bool(snapshot.get("day_world_night_popup_open", false)), "%s: dock popup should stay closed outside the explicit evening confirmation check" % failure_prefix):
		return false
	return _require(not bool(snapshot.get("day_world_transition_active", false)), "%s: departure transition should not already be running" % failure_prefix)


func _require(condition: bool, message: String) -> bool:
	if condition:
		return true
	push_error(message)
	_cleanup(true)
	return false


func _cleanup(failed: bool = true) -> void:
	if _helper != null:
		_helper.cleanup()
	get_tree().quit(1 if failed else 0)
