extends Node

const HelperClass := preload("res://tests/smoke/world_save_load_smoke_helper.gd")

var _helper = null


func _ready() -> void:
	_helper = HelperClass.new(self)
	if not await _helper.begin_session("day_world_transition_gating"):
		push_error("Failed to start DayWorld transition gating smoke")
		_cleanup(true)
		return

	if not _require(await _helper.reach_evening_via_farm_loop(), "DayWorld transition gating smoke should reach evening through the world farm loop"):
		return

	var evening_snapshot: Dictionary = _helper.snapshot()
	if not _require(bool(evening_snapshot.get("day_world_night_ready", false)), "DayWorld transition gating smoke should expose night departure once evening is reached"):
		return

	if not _require(bool(_helper.meta_root.call("debug_day_world_attempt_interact", "night")), "Dock interaction should open the night confirmation once"):
		return
	await _helper.await_frames(1)

	var popup_snapshot: Dictionary = _helper.snapshot()
	if not _require(bool(popup_snapshot.get("day_world_night_popup_open", false)), "Dock interaction should surface the confirmation popup"):
		return
	if not _require(not bool(_helper.meta_root.call("debug_day_world_attempt_interact", "night")), "Dock confirmation should block repeated open input while the popup is visible"):
		return
	if not _require(not bool(_helper.meta_root.call("debug_day_world_attempt_interact", "orders")), "Dock confirmation should block the orders board behind the popup"):
		return
	if not _require(not bool(_helper.meta_root.call("debug_day_world_attempt_interact", "shop")), "Dock confirmation should block town entrances behind the popup"):
		return

	if not _require(bool(_helper.meta_root.call("debug_day_world_cancel_night_departure")), "Dock confirmation should support cancelling cleanly"):
		return
	await _helper.await_frames(1)

	var cancelled_snapshot: Dictionary = _helper.snapshot()
	if not _require(not bool(cancelled_snapshot.get("day_world_night_popup_open", false)), "Cancelling dock confirmation should close the popup"):
		return
	if not _require(bool(_helper.meta_root.call("debug_day_world_attempt_interact", "orders")), "Closing dock confirmation should restore world input"):
		return
	await _helper.await_frames(1)
	if not _require(bool(_helper.meta_root.call("debug_day_world_close_orders_board")), "Orders board should close after verifying restored input"):
		return
	await _helper.await_frames(1)

	if not _require(bool(_helper.meta_root.call("debug_day_world_attempt_interact", "night")), "Dock confirmation should still open after cancelling once"):
		return
	await _helper.await_frames(1)
	if not _require(bool(_helper.meta_root.call("debug_day_world_confirm_night_departure")), "Dock confirmation should launch the night run once"):
		return
	if not _require(not bool(_helper.meta_root.call("debug_day_world_confirm_night_departure")), "Dock confirmation should not submit twice while the transition is already running"):
		return

	await _helper.await_frames(1)
	var transition_snapshot: Dictionary = _helper.snapshot()
	if not _require(bool(transition_snapshot.get("day_world_transition_active", false)), "Dock confirmation should enter the departure transition after the first confirm"):
		return
	if not _require(not bool(transition_snapshot.get("day_world_night_popup_open", false)), "Dock confirmation should close the popup once departure starts"):
		return

	await get_tree().create_timer(0.8).timeout
	var night_snapshot: Dictionary = _helper.snapshot()
	if not _require(String(night_snapshot.get("current_screen", "")) == "night", "Dock transition should enter the night run exactly once"):
		return

	_helper.meta_root.call("debug_complete_active_night", {
		"exit_reason": "completed",
		"time_survived_sec": 74.0,
		"kills": 12,
		"seed": 606060
	})
	await _helper.await_frames(2)

	var summary_snapshot: Dictionary = _helper.snapshot()
	var summary_day := int(summary_snapshot.get("current_day", 0))
	if not _require(String(summary_snapshot.get("current_screen", "")) == "return_summary", "Night completion should enter the return summary overlay"):
		return
	if not _require(bool(summary_snapshot.get("pending_summary", false)), "Night completion should leave the return summary pending until continued"):
		return
	if not _require(bool(summary_snapshot.get("day_world_overlay_blocked", false)), "Return summary should block the day world behind the overlay"):
		return
	if not _require(not bool(_helper.meta_root.call("debug_day_world_attempt_interact", "shop")), "Return summary should block underlying town interactions"):
		return
	if not _require(not bool(_helper.meta_root.call("debug_day_world_attempt_interact", "orders")), "Return summary should block the orders board behind the overlay"):
		return

	if not _require(bool(_helper.meta_root.call("debug_continue_summary")), "Return summary should settle once when continued"):
		return
	await _helper.await_frames(1)

	var after_continue_snapshot: Dictionary = _helper.snapshot()
	if not _require(String(after_continue_snapshot.get("current_screen", "")) == "day_hub", "Continuing the return summary should restore the day world"):
		return
	if not _require(int(after_continue_snapshot.get("current_day", 0)) == summary_day + 1, "Continuing the return summary should advance exactly one day"):
		return
	if not _require(not bool(after_continue_snapshot.get("pending_summary", false)), "Continuing the return summary should clear the pending summary state"):
		return
	if not _require(not bool(_helper.meta_root.call("debug_continue_summary")), "Return summary settlement should not run twice"):
		return
	await _helper.await_frames(1)

	var second_continue_snapshot: Dictionary = _helper.snapshot()
	if not _require(int(second_continue_snapshot.get("current_day", 0)) == int(after_continue_snapshot.get("current_day", 0)), "Duplicate summary input should not advance the day a second time"):
		return
	if not _require(bool(_helper.meta_root.call("debug_day_world_attempt_interact", "shop")), "Settling the return summary should restore world input afterwards"):
		return
	await _helper.await_frames(1)

	var shop_snapshot: Dictionary = _helper.snapshot()
	if not _require(String(shop_snapshot.get("current_screen", "")) == "shop", "Restored world input should allow town entrances after the summary closes"):
		return

	print("Day World transition gating smoke PASS")
	_cleanup(false)


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
