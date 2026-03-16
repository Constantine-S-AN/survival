extends Node

const WorldHelperClass := preload("res://tests/smoke/world_save_load_smoke_helper.gd")
const PhaseHelperClass := preload("res://tests/smoke/day_world_phase_smoke_helper.gd")

var _helper = null
var _phase_helper = null


func _ready() -> void:
	_helper = WorldHelperClass.new(self)
	_phase_helper = PhaseHelperClass.new()
	if not await _helper.begin_session("day_world_phase_save_load"):
		push_error("Failed to start DayWorld phase save/load smoke")
		_cleanup(true)
		return

	if not await _reach_phase("afternoon"):
		return

	var afternoon_before: Dictionary = _helper.snapshot()
	var afternoon_gold := int(afternoon_before.get("gold", 0))
	var afternoon_stamina := int(afternoon_before.get("stamina", 0))
	var afternoon_day := int(afternoon_before.get("current_day", 0))
	var afternoon_inventory: Dictionary = (afternoon_before.get("inventory_materials", {}) as Dictionary).duplicate(true)
	var afternoon_action_budget := int(afternoon_before.get("action_budget", 0))
	if not _assert_phase_snapshot(afternoon_before, "afternoon", "Phase save/load should capture afternoon cues before reload"):
		return

	_helper.save()
	if await _helper.reload_meta_root() == null:
		push_error("Failed to reload DayWorld phase save/load smoke in afternoon")
		_cleanup(true)
		return

	var afternoon_after: Dictionary = _helper.snapshot()
	if not _assert_phase_snapshot(afternoon_after, "afternoon", "Phase save/load should restore afternoon cues after reload"):
		return
	if not _require(int(afternoon_after.get("current_day", 0)) == afternoon_day, "Phase save/load should preserve the current day through afternoon reload"):
		return
	if not _require(int(afternoon_after.get("gold", 0)) == afternoon_gold, "Phase save/load should preserve gold through afternoon reload"):
		return
	if not _require(int(afternoon_after.get("stamina", 0)) == afternoon_stamina, "Phase save/load should preserve stamina through afternoon reload"):
		return
	if not _require(int(afternoon_after.get("action_budget", 0)) == afternoon_action_budget, "Phase save/load should preserve remaining actions through afternoon reload"):
		return
	if not _require(afternoon_after.get("inventory_materials", {}) == afternoon_inventory, "Phase save/load should preserve inventory through afternoon reload"):
		return
	if not _require(not bool(_helper.meta_root.call("debug_day_world_attempt_interact", "night")), "Phase save/load should keep dock departure locked after restoring afternoon state"):
		return
	await _helper.await_frames(1)
	if not _require(not bool(_helper.snapshot().get("day_world_night_popup_open", false)), "Restored afternoon state should not reopen the dock confirmation popup"):
		return

	if not await _advance_phase_with_farm_action("water", "", "evening", "Phase save/load should reach evening before the ready-state reload check"):
		return

	var evening_before: Dictionary = _helper.snapshot()
	var evening_gold := int(evening_before.get("gold", 0))
	var evening_stamina := int(evening_before.get("stamina", 0))
	var evening_day := int(evening_before.get("current_day", 0))
	var evening_inventory: Dictionary = (evening_before.get("inventory_materials", {}) as Dictionary).duplicate(true)
	var evening_action_budget := int(evening_before.get("action_budget", 0))
	if not _assert_phase_snapshot(evening_before, "evening", "Phase save/load should capture evening cues before reload"):
		return

	_helper.save()
	if await _helper.reload_meta_root() == null:
		push_error("Failed to reload DayWorld phase save/load smoke in evening")
		_cleanup(true)
		return

	var evening_after: Dictionary = _helper.snapshot()
	if not _assert_phase_snapshot(evening_after, "evening", "Phase save/load should restore evening cues after reload"):
		return
	if not _require(int(evening_after.get("current_day", 0)) == evening_day, "Phase save/load should preserve the current day through evening reload"):
		return
	if not _require(int(evening_after.get("gold", 0)) == evening_gold, "Phase save/load should preserve gold through evening reload"):
		return
	if not _require(int(evening_after.get("stamina", 0)) == evening_stamina, "Phase save/load should preserve stamina through evening reload"):
		return
	if not _require(int(evening_after.get("action_budget", 0)) == evening_action_budget, "Phase save/load should preserve remaining actions through evening reload"):
		return
	if not _require(evening_after.get("inventory_materials", {}) == evening_inventory, "Phase save/load should preserve inventory through evening reload"):
		return
	if not _require(not bool(evening_after.get("day_world_night_popup_open", false)), "Restored evening state should not carry a stale dock popup unless it was explicitly saved open"):
		return
	if not _require(bool(_helper.meta_root.call("debug_day_world_attempt_interact", "night")), "Restored evening state should still allow dock departure interaction"):
		return
	await _helper.await_frames(1)
	if not _require(bool(_helper.snapshot().get("day_world_night_popup_open", false)), "Restored evening state should open the dock confirmation exactly when the interaction is retried"):
		return
	if not _require(bool(_helper.meta_root.call("debug_day_world_cancel_night_departure")), "Restored evening state should cancel dock confirmation cleanly"):
		return
	await _helper.await_frames(1)
	if not _require(not bool(_helper.snapshot().get("day_world_night_popup_open", false)), "Cancelling the restored evening dock confirmation should clear the popup state again"):
		return

	print("Day World phase save/load smoke PASS")
	_cleanup(false)


func _reach_phase(target_phase: String) -> bool:
	match target_phase:
		"afternoon":
			if not await _advance_phase_with_farm_action("till", "", "noon", "Phase save/load should step from morning into noon"):
				return false
			return await _advance_phase_with_farm_action("plant", "wheat_seed", "afternoon", "Phase save/load should step from noon into afternoon")
		"evening":
			if not await _reach_phase("afternoon"):
				return false
			return await _advance_phase_with_farm_action("water", "", "evening", "Phase save/load should step from afternoon into evening")
	return false


func _advance_phase_with_farm_action(action_id: String, seed_id: String, expected_phase: String, failure_prefix: String) -> bool:
	if not _require(bool(_helper.meta_root.call("debug_day_world_select_farm_tool", action_id, seed_id)), "%s: missing tool selection" % failure_prefix):
		return false
	if not _require(bool(_helper.meta_root.call("debug_day_world_interact_farm_plot", 0)), "%s: farm interaction should succeed" % failure_prefix):
		return false
	await _helper.await_frames(1)
	return _assert_phase_snapshot(_helper.snapshot(), expected_phase, failure_prefix)


func _assert_phase_snapshot(snapshot: Dictionary, phase: String, failure_prefix: String) -> bool:
	var expected: Dictionary = _phase_helper.expected_phase_snapshot(phase)
	if not _require(String(snapshot.get("phase", "")) == String(expected.get("phase", "")), "%s: underlying phase should match" % failure_prefix):
		return false
	if not _require(String(snapshot.get("day_world_phase_visual_id", "")) == String(expected.get("phase_visual_id", "")), "%s: world phase visual should match" % failure_prefix):
		return false
	if not _require(String(snapshot.get("day_world_hud_phase", "")) == String(expected.get("hud_phase", "")), "%s: HUD phase should match" % failure_prefix):
		return false
	if not _require(int(snapshot.get("day_world_hud_actions_until_evening", -1)) == int(expected.get("hud_actions_until_evening", -1)), "%s: HUD action countdown should match" % failure_prefix):
		return false
	if not _require(int(snapshot.get("day_world_hud_phase_track_active_index", -1)) == int(expected.get("hud_phase_track_active_index", -1)), "%s: HUD phase track should match" % failure_prefix):
		return false
	if not _require(bool(snapshot.get("day_world_night_ready", false)) == bool(expected.get("night_ready", false)), "%s: night readiness should match" % failure_prefix):
		return false
	if not _require(bool(snapshot.get("day_world_night_enabled", false)) == bool(expected.get("night_enabled", false)), "%s: dock eligibility should match" % failure_prefix):
		return false
	if not _require(bool(snapshot.get("day_world_wait_enabled", false)) == bool(expected.get("wait_enabled", false)), "%s: wait availability should match" % failure_prefix):
		return false
	if not _require(bool(snapshot.get("day_world_dock_gate_open", false)) == bool(expected.get("dock_gate_open", false)), "%s: dock gate presentation should match" % failure_prefix):
		return false
	if not _require(int(snapshot.get("day_world_visible_town_npc_count", -1)) == int(expected.get("visible_town_npc_count", -1)), "%s: town NPC visibility cue should match" % failure_prefix):
		return false
	if not _require(String(snapshot.get("day_world_phase_idle_cue", "")) == String(expected.get("phase_idle_cue", "")), "%s: idle cue should match" % failure_prefix):
		return false
	if not _require(String(snapshot.get("day_world_restaurant_cue", "")) == String(expected.get("restaurant_cue", "")), "%s: restaurant cue should match" % failure_prefix):
		return false
	if not _require(String(snapshot.get("day_world_shop_cue", "")) == String(expected.get("shop_cue", "")), "%s: shop cue should match" % failure_prefix):
		return false
	if not _require(String(snapshot.get("day_world_wait_cue", "")) == String(expected.get("wait_cue", "")), "%s: wait cue should match" % failure_prefix):
		return false
	if not _require(String(snapshot.get("day_world_night_cue", "")) == String(expected.get("night_cue", "")), "%s: dock cue should match" % failure_prefix):
		return false
	if not _require(String(snapshot.get("day_world_hud_clock_status_text", "")) == String(expected.get("hud_clock_status_text", "")), "%s: HUD clock status should match" % failure_prefix):
		return false
	if not _require(String(snapshot.get("day_world_hud_departure_text", "")) == String(expected.get("hud_departure_text", "")), "%s: HUD departure status should match" % failure_prefix):
		return false
	if not _require(String(snapshot.get("day_world_prompt_text", "")) == String(snapshot.get("day_world_hud_prompt_text", "")), "%s: world and HUD prompt text should stay aligned" % failure_prefix):
		return false
	if not _require(not bool(snapshot.get("day_world_orders_open", false)), "%s: orders overlay should remain closed during phase save/load checks" % failure_prefix):
		return false
	if not _require(not bool(snapshot.get("day_world_transition_active", false)), "%s: departure transition should not already be running" % failure_prefix):
		return false
	return _require(not bool(snapshot.get("pending_summary", false)), "%s: return summary should not be pending during daytime phase checks" % failure_prefix)


func _require(condition: bool, message: String) -> bool:
	if condition:
		return true
	push_error(message)
	_cleanup(true)
	return false


func _cleanup(failed: bool = true) -> void:
	if _helper != null:
		_helper.cleanup_and_quit(1 if failed else 0)
		return
	get_tree().quit(1 if failed else 0)
