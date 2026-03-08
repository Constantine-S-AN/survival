extends Node

const HelperClass := preload("res://tests/smoke/world_save_load_smoke_helper.gd")

var _helper = null


func _ready() -> void:
	_helper = HelperClass.new(self)
	if not await _helper.begin_session("shop_world_gating"):
		push_error("Failed to start shop world gating smoke")
		_cleanup(true)
		return

	if not _require(bool(_helper.meta_root.call("debug_day_world_attempt_interact", "shop")), "Shop entrance should open once from the day world"):
		return
	if not _require(not bool(_helper.meta_root.call("debug_day_world_attempt_interact", "shop")), "Repeated world input should not retrigger the shop entrance after the transition starts"):
		return
	await _helper.await_frames(1)

	var shop_snapshot: Dictionary = _helper.snapshot()
	if not _require(String(shop_snapshot.get("current_screen", "")) == "shop", "Shop entrance should land inside the worldified shop interior"):
		return

	if not _require(bool(_helper.meta_root.call("debug_shop_attempt_interact", "shopkeeper")), "Merchant counter should open once from the shop interior"):
		return
	await _helper.await_frames(1)

	var merchant_snapshot: Dictionary = _helper.snapshot()
	var gold_before_purchase := int(merchant_snapshot.get("gold", 0))
	if not _require(String(merchant_snapshot.get("shop_world_popup", "")) == "merchant", "Shopkeeper interaction should open the merchant popup"):
		return
	if not _require(not bool(_helper.meta_root.call("debug_shop_attempt_interact", "shopkeeper")), "Merchant popup should block repeated interaction spam while it is open"):
		return
	if not _require(not bool(_helper.meta_root.call("debug_shop_attempt_interact", "regular")), "Merchant popup should block the customer interaction behind the overlay"):
		return
	if not _require(not bool(_helper.meta_root.call("debug_shop_attempt_interact", "door")), "Merchant popup should block the exit door behind the overlay"):
		return
	if not _require(bool(_helper.meta_root.call("debug_shop_popup_buy_seed", "kelpberry_seed")), "Merchant popup should allow buying kelpberry seed once"):
		return
	await _helper.await_frames(1)

	var purchased_snapshot: Dictionary = _helper.snapshot()
	if not _require((purchased_snapshot.get("unlocked_seed_ids", []) as Array).has("kelpberry_seed"), "Merchant popup should unlock kelpberry seed after the first purchase"):
		return
	if not _require(int(purchased_snapshot.get("gold", 0)) < gold_before_purchase, "Merchant popup should spend gold exactly once for the first seed purchase"):
		return
	if not _require(not bool(_helper.meta_root.call("debug_shop_popup_buy_seed", "kelpberry_seed")), "Merchant popup should not duplicate a one-shot seed purchase from repeated input"):
		return
	await _helper.await_frames(1)

	var duplicate_purchase_snapshot: Dictionary = _helper.snapshot()
	if not _require(int(duplicate_purchase_snapshot.get("gold", 0)) == int(purchased_snapshot.get("gold", 0)), "Repeated one-shot seed input should not spend extra gold"):
		return
	if not _require(bool(_helper.meta_root.call("debug_shop_close_popup")), "Merchant popup should support closing cleanly"):
		return
	await _helper.await_frames(1)

	if not _require(bool(_helper.meta_root.call("debug_shop_attempt_interact", "shopkeeper")), "Closing the merchant popup should restore shopkeeper input"):
		return
	await _helper.await_frames(1)
	if not _require(not bool(_helper.meta_root.call("debug_shop_popup_buy_seed", "kelpberry_seed")), "Reopening the merchant popup should still keep the one-shot seed purchase disabled"):
		return
	if not _require(bool(_helper.meta_root.call("debug_shop_close_popup")), "Reopened merchant popup should still close cleanly"):
		return
	await _helper.await_frames(1)

	if not _require(bool(_helper.meta_root.call("debug_shop_attempt_interact", "regular")), "Customer interaction should open once after the merchant popup closes"):
		return
	await _helper.await_frames(1)

	var customer_snapshot: Dictionary = _helper.snapshot()
	if not _require(String(customer_snapshot.get("shop_world_popup", "")) == "customer", "Customer interaction should open the request popup"):
		return
	if not _require(not bool(_helper.meta_root.call("debug_shop_attempt_interact", "shopkeeper")), "Customer popup should block the merchant counter behind the overlay"):
		return
	if not _require(not bool(_helper.meta_root.call("debug_shop_attempt_interact", "door")), "Customer popup should block the exit door behind the overlay"):
		return
	if not _require(bool(_helper.meta_root.call("debug_shop_close_popup")), "Customer popup should support closing cleanly"):
		return
	await _helper.await_frames(1)

	if not _require(bool(_helper.meta_root.call("debug_shop_attempt_interact", "door")), "Closing shop overlays should restore the exit input"):
		return
	await _helper.await_frames(1)

	var exit_snapshot: Dictionary = _helper.snapshot()
	if not _require(String(exit_snapshot.get("current_screen", "")) == "day_hub", "Shop exit should return to the day world after overlays close"):
		return

	print("Shop world gating smoke PASS")
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
