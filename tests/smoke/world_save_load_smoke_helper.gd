extends RefCounted
class_name WorldSaveLoadSmokeHelper

const META_LOOP_SCENE := preload("res://scenes/meta/MetaLoopRoot.tscn")
const DEFAULT_CHARACTER_ID := "diver"
const DEFAULT_MAP_ID := "map_trench_lab"

var _host: Node = null
var meta_root: Node = null


func _init(host: Node) -> void:
	_host = host


func begin_session(prefix: String) -> bool:
	if _host == null or ProfileStore == null:
		return false
	var session_id := "%s_%d" % [prefix, int(Time.get_ticks_usec() % 1000000)]
	ProfileStore.begin_test_session(session_id, true)
	ProfileStore.load_profile(DEFAULT_CHARACTER_ID, DEFAULT_MAP_ID)
	_reset_daily_orders_runtime()
	await await_frames(1)
	meta_root = await _spawn_meta_root()
	return meta_root != null


func reload_meta_root() -> Node:
	if meta_root != null:
		meta_root.free()
		meta_root = null
	_reset_daily_orders_runtime()
	if ProfileStore != null and ProfileStore.has_method("load_profile"):
		ProfileStore.load_profile(DEFAULT_CHARACTER_ID, DEFAULT_MAP_ID)
	await await_frames(1)
	meta_root = await _spawn_meta_root()
	return meta_root


func save() -> void:
	if meta_root != null and meta_root.has_method("debug_save_meta_progress"):
		meta_root.call("debug_save_meta_progress")


func snapshot() -> Dictionary:
	if meta_root == null:
		return {}
	var snapshot_variant: Variant = meta_root.call("debug_get_snapshot")
	return snapshot_variant if snapshot_variant is Dictionary else {}


func sync_daily_orders_progress() -> void:
	if DailyOrders != null and DailyOrders.has_method("_sync_progress"):
		DailyOrders.call("_sync_progress")


func get_order_cards() -> Array:
	if DailyOrders == null or not DailyOrders.has_method("get_order_cards"):
		return []
	var cards_variant: Variant = DailyOrders.call("get_order_cards")
	return cards_variant as Array if cards_variant is Array else []


func find_order_card_by_title(title: String) -> Dictionary:
	var normalized_title := title.strip_edges().to_lower()
	for card_variant in get_order_cards():
		if not (card_variant is Dictionary):
			continue
		var card := card_variant as Dictionary
		if String(card.get("name", "")).strip_edges().to_lower() == normalized_title:
			return card.duplicate(true)
	return {}


func find_entry_by_id(items_variant: Variant, item_id: String) -> Dictionary:
	if not (items_variant is Array):
		return {}
	var normalized_id := item_id.strip_edges().to_lower()
	for item_variant in (items_variant as Array):
		if not (item_variant is Dictionary):
			continue
		var item := item_variant as Dictionary
		if String(item.get("seed_id", "")).strip_edges().to_lower() == normalized_id:
			return item.duplicate(true)
		if String(item.get("id", "")).strip_edges().to_lower() == normalized_id:
			return item.duplicate(true)
	return {}


func cleanup() -> void:
	if meta_root != null:
		meta_root.free()
		meta_root = null
	_reset_daily_orders_runtime()
	if ProfileStore != null and ProfileStore.has_method("end_test_session"):
		ProfileStore.end_test_session(true)


func await_frames(frame_count: int) -> void:
	if _host == null:
		return
	for _i in range(frame_count):
		await _host.get_tree().process_frame


func _spawn_meta_root() -> Node:
	if _host == null or META_LOOP_SCENE == null:
		return null
	var next_meta_root: Node = META_LOOP_SCENE.instantiate()
	_host.get_tree().root.add_child.call_deferred(next_meta_root)
	await await_frames(2)
	next_meta_root.call("debug_press_play")
	await await_frames(1)
	return next_meta_root


func _reset_daily_orders_runtime() -> void:
	if DailyOrders != null and DailyOrders.has_method("_reset_runtime_state"):
		DailyOrders.call("_reset_runtime_state")
