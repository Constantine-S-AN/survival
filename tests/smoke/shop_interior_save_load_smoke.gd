extends Node

const HelperClass := preload("res://tests/smoke/world_save_load_smoke_helper.gd")

var _helper = null


func _ready() -> void:
	_helper = HelperClass.new(self)
	if not await _helper.begin_session("shop_interior_save_load"):
		push_error("Failed to start shop interior save/load smoke")
		_cleanup(true)
		return

	if not _require(bool(_helper.meta_root.call("debug_day_world_interact", "shop")), "Shop save/load should open the worldified shop interior"):
		return
	await _helper.await_frames(1)
	if not _require(bool(_helper.meta_root.call("debug_shop_interact", "shopkeeper")), "Shop save/load should open the merchant popup from the interior flow"):
		return
	await _helper.await_frames(1)
	if not _require(bool(_helper.meta_root.call("debug_shop_popup_sell_material", "wheat")), "Shop save/load should allow a merchant sale before saving"):
		return
	await _helper.await_frames(1)
	if not _require(bool(_helper.meta_root.call("debug_shop_popup_buy_seed", "kelpberry_seed")), "Shop save/load should allow a merchant seed purchase before saving"):
		return
	await _helper.await_frames(1)
	if not _require(bool(_helper.meta_root.call("debug_shop_interact", "regular")), "Shop save/load should open the customer popup from the interior flow"):
		return
	await _helper.await_frames(1)

	var snapshot_before: Dictionary = _helper.snapshot()
	if not _require(String(snapshot_before.get("current_screen", "")) == "shop", "Shop save/load should save from inside the shop interior"):
		return
	if not _require(String(snapshot_before.get("shop_world_popup", "")) == "customer", "Shop save/load should capture the active customer popup state"):
		return
	if not _require((snapshot_before.get("unlocked_seed_ids", []) as Array).has("kelpberry_seed"), "Shop save/load should capture the purchased kelpberry seed unlock"):
		return
	if not _require(not String(snapshot_before.get("shop_request_title", "")).strip_edges().is_empty(), "Shop save/load should capture the active customer request state"):
		return

	var inventory_before: Dictionary = (snapshot_before.get("inventory_materials", {}) as Dictionary).duplicate(true)
	var gold_before := int(snapshot_before.get("gold", 0))
	var phase_before := String(snapshot_before.get("phase", ""))
	var unlocked_seed_ids_before: Array = (snapshot_before.get("unlocked_seed_ids", []) as Array).duplicate(true)
	var request_title_before := String(snapshot_before.get("shop_request_title", ""))

	_helper.save()
	if await _helper.reload_meta_root() == null:
		push_error("Failed to reload shop interior save/load smoke")
		_cleanup(true)
		return

	var snapshot_after: Dictionary = _helper.snapshot()
	if not _require(String(snapshot_after.get("current_screen", "")) == "shop", "Shop save/load should restore the shop interior context"):
		return
	if not _require(String(snapshot_after.get("shop_world_popup", "")) == "customer", "Shop save/load should restore the active customer popup safely"):
		return
	if not _require(String(snapshot_after.get("phase", "")) == phase_before, "Shop save/load should preserve the current phase while in the shop"):
		return
	if not _require(int(snapshot_after.get("gold", 0)) == gold_before, "Shop save/load should not duplicate merchant gold changes after reload"):
		return
	if not _require(snapshot_after.get("inventory_materials", {}) == inventory_before, "Shop save/load should not duplicate merchant inventory changes after reload"):
		return
	if not _require(snapshot_after.get("unlocked_seed_ids", []) == unlocked_seed_ids_before, "Shop save/load should preserve purchased seed unlocks without duplicating them"):
		return
	if not _require(String(snapshot_after.get("shop_request_title", "")) == request_title_before, "Shop save/load should preserve the active customer request text safely"):
		return

	if not _require(bool(_helper.meta_root.call("debug_shop_interact", "shopkeeper")), "Shop save/load should allow returning to the merchant popup after reload"):
		return
	await _helper.await_frames(1)
	var merchant_snapshot: Dictionary = _helper.snapshot()
	var kelpberry_offer: Dictionary = _helper.find_entry_by_id(merchant_snapshot.get("shop_seed_offers", []), "kelpberry_seed")
	if not _require(String(merchant_snapshot.get("shop_world_popup", "")) == "merchant", "Shop save/load should reopen the merchant popup safely after reload"):
		return
	if not _require(not bool(kelpberry_offer.get("enabled", true)), "Shop save/load should keep the purchased seed offer disabled after reload"):
		return
	if not _require(not bool(_helper.meta_root.call("debug_shop_popup_buy_seed", "kelpberry_seed")), "Shop save/load should not allow duplicate merchant purchases after reload"):
		return

	print("Shop interior save/load smoke PASS")
	_cleanup(false)


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
