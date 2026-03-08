extends Node

signal state_changed
signal reward_claimed(order_id: int, reward: Dictionary)

const ORDER_RESOURCE_PATHS: Array[String] = [
	"res://data/quests/daily_orders/field_stew_order.tres",
	"res://data/quests/daily_orders/herb_tea_order.tres",
	"res://data/quests/daily_orders/kelpfire_noodles_order.tres",
	"res://data/quests/daily_orders/kelpberry_tart_order.tres",
	"res://data/quests/daily_orders/emberleaf_flatbread_order.tres",
	"res://data/quests/daily_orders/wheat_stock_order.tres",
	"res://data/quests/daily_orders/herb_bundle_order.tres",
	"res://data/quests/daily_orders/kelpberry_crate_order.tres",
	"res://data/quests/daily_orders/emberleaf_bundle_order.tres",
	"res://data/quests/daily_orders/reef_salt_order.tres",
	"res://data/quests/daily_orders/glow_kelp_order.tres",
	"res://data/quests/daily_orders/abyssfin_order.tres"
]
const SYNC_INTERVAL_SECONDS := 0.25

var _loaded: bool = false
var _sync_accumulator: float = 0.0
var _current_day: int = 0
var _tracked_dish_sales: Dictionary = {}
var _tracked_materials: Dictionary = {}
var _quests_by_id: Dictionary = {}
var _profile_path: String = ""


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_process(true)
	_try_initialize()


func _process(delta: float) -> void:
	if not _try_initialize():
		return
	_sync_accumulator += delta
	if _sync_accumulator < SYNC_INTERVAL_SECONDS:
		return
	_sync_accumulator = 0.0
	_sync_progress()


func get_order_cards() -> Array[Dictionary]:
	if not _try_initialize():
		return []
	var cards: Array[Dictionary] = []
	for quest_id in _get_sorted_quest_ids():
		var quest := _get_daily_order(quest_id)
		if quest == null:
			continue
		var completed := QuestSystem.is_quest_completed(quest)
		var ready_to_claim := QuestSystem.is_quest_active(quest) and quest.objective_completed
		cards.append({
			"id": quest.id,
			"pillar": quest.pillar,
			"pillar_title": quest.get_pillar_title(),
			"name": quest.quest_name,
			"description": quest.quest_description,
			"objective": quest.quest_objective,
			"progress_text": quest.get_progress_text(),
			"reward_text": describe_reward(_get_reward_config(quest)),
			"completed": completed,
			"can_claim": ready_to_claim,
			"status_text": _build_status_text(completed, ready_to_claim)
		})
	return cards


func get_ready_to_claim_count() -> int:
	if not _try_initialize():
		return 0
	var count := 0
	for quest_id in _get_sorted_quest_ids():
		var quest := _get_daily_order(quest_id)
		if quest == null:
			continue
		if QuestSystem.is_quest_active(quest) and quest.objective_completed:
			count += 1
	return count


func describe_reward(reward: Dictionary) -> String:
	var parts := _build_reward_parts(reward)
	if parts.is_empty():
		return "No reward"
	return " · ".join(parts)


func claim_order(order_id: int) -> Dictionary:
	if not _try_initialize():
		return {"ok": false, "error": "daily_orders_not_ready"}
	var quest := _get_daily_order(order_id)
	if quest == null:
		return {"ok": false, "error": "order_not_found"}
	if QuestSystem.is_quest_completed(quest):
		return {"ok": false, "error": "order_already_completed"}
	if not QuestSystem.is_quest_active(quest) or not quest.objective_completed:
		return {"ok": false, "error": "order_not_ready"}
	var reward := _grant_reward(quest)
	_persist_state()
	state_changed.emit()
	reward_claimed.emit(order_id, reward)
	return {
		"ok": true,
		"reward": reward
	}


func _try_initialize() -> bool:
	if ProfileStore == null or QuestSystem == null:
		return false
	var profile_path := _get_profile_path()
	if _loaded and profile_path == _profile_path:
		return true
	if _loaded and profile_path != _profile_path:
		_reset_runtime_state()
	var current_day := _get_current_day()
	if current_day <= 0:
		return false
	var saved_state := ProfileStore.get_daily_orders_state()
	var saved_day := int(saved_state.get("current_day", 0))
	if saved_day > 0 and saved_day != current_day:
		_rollover_to_new_day(current_day, saved_state)
	elif not _state_matches_catalog(saved_state):
		_initialize_for_day(current_day)
	else:
		_restore_state(saved_state)
	_loaded = true
	_profile_path = profile_path
	return _loaded


func _initialize_for_day(day: int) -> void:
	QuestSystem.reset_pool()
	_quests_by_id.clear()
	for quest in _load_order_instances():
		_quests_by_id[quest.id] = quest
		QuestSystem.mark_quest_as_available(quest)
		QuestSystem.start_quest(quest, {"assigned_day": day})
	_current_day = maxi(1, day)
	var meta_progress := ProfileStore.get_meta_progress_state()
	_tracked_dish_sales = _snapshot_dish_sales(meta_progress)
	_tracked_materials = _snapshot_materials(meta_progress)
	_loaded = true
	_persist_state()
	state_changed.emit()


func _restore_state(state: Dictionary) -> void:
	QuestSystem.reset_pool()
	_quests_by_id.clear()
	var quests := _load_order_instances()
	var serialized_quests: Dictionary = state.get("serialized_quests", {})
	for quest in quests:
		var quest_state_variant: Variant = serialized_quests.get(str(quest.id), {})
		if quest_state_variant is Dictionary:
			quest.deserialize(quest_state_variant)
		_quests_by_id[quest.id] = quest
	var remaining_quests: Array[Quest] = []
	remaining_quests.append_array(quests)
	QuestSystem.restore_pool_state_from_dict(state.get("pool_state", {}), remaining_quests)
	for leftover_quest in remaining_quests:
		QuestSystem.mark_quest_as_available(leftover_quest)
		QuestSystem.start_quest(leftover_quest, {"assigned_day": int(state.get("current_day", 0))})
	_current_day = maxi(1, int(state.get("current_day", _get_current_day())))
	_tracked_dish_sales = _normalize_snapshot(state.get("tracked_dish_sales", {}))
	_tracked_materials = _normalize_snapshot(state.get("tracked_materials", {}))


func _rollover_to_new_day(new_day: int, previous_state: Dictionary) -> void:
	var previous_day := int(previous_state.get("current_day", 0))
	if previous_day > 0:
		_restore_state(previous_state)
		_loaded = true
		_profile_path = _get_profile_path()
		if _auto_claim_ready_orders() > 0:
			_persist_state()
	_initialize_for_day(new_day)


func _sync_progress() -> void:
	var current_day := _get_current_day()
	if current_day <= 0:
		return
	if current_day != _current_day:
		var saved_state := ProfileStore.get_daily_orders_state()
		_rollover_to_new_day(current_day, saved_state)
		return
	var meta_progress := ProfileStore.get_meta_progress_state()
	var dish_sales_snapshot := _snapshot_dish_sales(meta_progress)
	var materials_snapshot := _snapshot_materials(meta_progress)
	var order_changed := false
	for quest_id in _get_sorted_quest_ids():
		var quest := _get_daily_order(quest_id)
		if quest == null or not QuestSystem.is_quest_active(quest):
			continue
		var delta := 0
		match quest.order_type:
			DailyOrderQuest.ORDER_TYPE_DISH_SALES:
				delta = _positive_delta(dish_sales_snapshot, _tracked_dish_sales, quest.get_safe_target_id())
			DailyOrderQuest.ORDER_TYPE_MATERIAL_GAIN:
				delta = _positive_delta(materials_snapshot, _tracked_materials, quest.get_safe_target_id())
		if delta <= 0:
			continue
		QuestSystem.update_quest(quest, {"delta": delta})
		order_changed = true
	var tracked_changed := dish_sales_snapshot != _tracked_dish_sales or materials_snapshot != _tracked_materials
	_tracked_dish_sales = dish_sales_snapshot
	_tracked_materials = materials_snapshot
	if order_changed or tracked_changed:
		_persist_state()
		state_changed.emit()


func _persist_state() -> void:
	if not _loaded:
		return
	ProfileStore.set_daily_orders_state({
		"current_day": _current_day,
		"pool_state": QuestSystem.pool_state_as_dict(),
		"serialized_quests": QuestSystem.serialize_quests(),
		"tracked_dish_sales": _tracked_dish_sales.duplicate(true),
		"tracked_materials": _tracked_materials.duplicate(true)
	})


func _grant_reward(quest: DailyOrderQuest) -> Dictionary:
	var reward := _get_reward_config(quest)
	var current_scene := get_tree().current_scene
	var economy_target: Variant = current_scene.get("_economy") if current_scene != null else null
	var inventory_target: Variant = current_scene.get("_inventory") if current_scene != null else null
	var applied_reward := (
		_apply_reward_to_runtime(reward, economy_target, inventory_target)
		if economy_target != null or inventory_target != null
		else _apply_reward_to_profile(reward)
	)
	if current_scene != null and _reward_has_content(reward):
		if current_scene.has_method("_save_meta_progress"):
			current_scene.call("_save_meta_progress")
		if current_scene.has_method("_refresh_views"):
			current_scene.call("_refresh_views")
	QuestSystem.complete_quest(quest)
	return applied_reward


func _get_reward_config(quest: DailyOrderQuest) -> Dictionary:
	if quest == null:
		return _build_empty_reward()
	if quest.has_method("get_reward_config"):
		var reward_variant: Variant = quest.call("get_reward_config")
		if reward_variant is Dictionary:
			return _normalize_reward_dictionary(reward_variant)
	return _normalize_reward_dictionary({"gold": maxi(0, quest.reward_gold)})


func _apply_reward_to_runtime(reward: Dictionary, economy_target: Variant, inventory_target: Variant) -> Dictionary:
	var applied := _build_empty_reward()
	var gold_amount := maxi(0, int(reward.get("gold", 0)))
	if gold_amount > 0 and economy_target != null and economy_target.has_method("add_gold"):
		var gold_before := maxi(0, int(economy_target.get("gold")))
		economy_target.call("add_gold", gold_amount)
		applied["gold"] = maxi(0, int(economy_target.get("gold")) - gold_before)
	var reputation_amount := maxi(0, int(reward.get("reputation", 0)))
	if reputation_amount > 0 and economy_target != null and economy_target.has_method("add_reputation"):
		var reputation_before := clampi(int(economy_target.get("restaurant_reputation")), 0, 20)
		economy_target.call("add_reputation", reputation_amount)
		applied["reputation"] = maxi(0, int(economy_target.get("restaurant_reputation")) - reputation_before)
	var materials_variant: Variant = reward.get("materials", {})
	var materials: Dictionary = materials_variant if materials_variant is Dictionary else {}
	var applied_materials: Dictionary = {}
	if inventory_target != null and inventory_target.has_method("add_material") and inventory_target.has_method("get_material_amount"):
		for material_id_variant in materials.keys():
			var material_id := String(material_id_variant).strip_edges().to_lower()
			var amount := maxi(0, int(materials.get(material_id_variant, 0)))
			if material_id.is_empty() or amount <= 0:
				continue
			var before := maxi(0, int(inventory_target.call("get_material_amount", material_id)))
			inventory_target.call("add_material", material_id, amount)
			var after := maxi(0, int(inventory_target.call("get_material_amount", material_id)))
			var applied_amount := maxi(0, after - before)
			if applied_amount > 0:
				applied_materials[material_id] = applied_amount
	if not applied_materials.is_empty():
		applied["materials"] = applied_materials
	var seed_ids := _normalize_string_id_array(reward.get("seed_ids", []))
	var applied_seed_ids: Array[String] = []
	if inventory_target != null and inventory_target.has_method("unlock_seed"):
		for seed_id in seed_ids:
			if bool(inventory_target.call("unlock_seed", seed_id)):
				applied_seed_ids.append(seed_id)
	if not applied_seed_ids.is_empty():
		applied["seed_ids"] = applied_seed_ids
	return applied


func _apply_reward_to_profile(reward: Dictionary) -> Dictionary:
	var applied := _build_empty_reward()
	var meta_progress := ProfileStore.get_meta_progress_state()
	var economy_variant: Variant = meta_progress.get("economy", {})
	var economy: Dictionary = economy_variant if economy_variant is Dictionary else {}
	var inventory_variant: Variant = meta_progress.get("inventory", {})
	var inventory: Dictionary = inventory_variant if inventory_variant is Dictionary else {}
	var gold_before := maxi(0, int(economy.get("gold", 0)))
	var gold_amount := maxi(0, int(reward.get("gold", 0)))
	economy["gold"] = gold_before + gold_amount
	applied["gold"] = maxi(0, int(economy.get("gold", 0)) - gold_before)
	var reputation_before := clampi(int(economy.get("restaurant_reputation", 1)), 0, 20)
	var reputation_amount := maxi(0, int(reward.get("reputation", 0)))
	economy["restaurant_reputation"] = clampi(reputation_before + reputation_amount, 0, 20)
	applied["reputation"] = maxi(0, int(economy.get("restaurant_reputation", 1)) - reputation_before)
	var materials_variant: Variant = inventory.get("materials", {})
	var materials: Dictionary = materials_variant if materials_variant is Dictionary else {}
	var reward_materials_variant: Variant = reward.get("materials", {})
	var reward_materials: Dictionary = reward_materials_variant if reward_materials_variant is Dictionary else {}
	var applied_materials: Dictionary = {}
	for material_id_variant in reward_materials.keys():
		var material_id := String(material_id_variant).strip_edges().to_lower()
		var amount := maxi(0, int(reward_materials.get(material_id_variant, 0)))
		if material_id.is_empty() or amount <= 0:
			continue
		var before := maxi(0, int(materials.get(material_id, 0)))
		materials[material_id] = before + amount
		applied_materials[material_id] = maxi(0, int(materials.get(material_id, 0)) - before)
	if not applied_materials.is_empty():
		applied["materials"] = applied_materials
	inventory["materials"] = materials
	var unlocked_seed_ids := _normalize_string_id_array(inventory.get("unlocked_seeds", []))
	var applied_seed_ids: Array[String] = []
	for seed_id in _normalize_string_id_array(reward.get("seed_ids", [])):
		if unlocked_seed_ids.has(seed_id):
			continue
		unlocked_seed_ids.append(seed_id)
		applied_seed_ids.append(seed_id)
	if not applied_seed_ids.is_empty():
		applied["seed_ids"] = applied_seed_ids
	inventory["unlocked_seeds"] = unlocked_seed_ids
	meta_progress["economy"] = economy
	meta_progress["inventory"] = inventory
	ProfileStore.set_meta_progress_state(meta_progress)
	return applied


func _build_empty_reward() -> Dictionary:
	return {
		"gold": 0,
		"reputation": 0,
		"materials": {},
		"seed_ids": []
	}


func _normalize_reward_dictionary(reward_variant: Variant) -> Dictionary:
	var reward: Dictionary = reward_variant if reward_variant is Dictionary else {}
	var normalized := _build_empty_reward()
	normalized["gold"] = maxi(0, int(reward.get("gold", 0)))
	normalized["reputation"] = maxi(0, int(reward.get("reputation", 0)))
	normalized["materials"] = _normalize_snapshot(reward.get("materials", {}))
	normalized["seed_ids"] = _normalize_string_id_array(reward.get("seed_ids", []))
	return normalized


func _build_reward_parts(reward: Dictionary) -> Array[String]:
	var normalized_reward := _normalize_reward_dictionary(reward)
	var parts: Array[String] = []
	var gold_amount := int(normalized_reward.get("gold", 0))
	if gold_amount > 0:
		parts.append("+%d gold" % gold_amount)
	var reputation_amount := int(normalized_reward.get("reputation", 0))
	if reputation_amount > 0:
		parts.append("+%d reputation" % reputation_amount)
	var materials_variant: Variant = normalized_reward.get("materials", {})
	var materials: Dictionary = materials_variant if materials_variant is Dictionary else {}
	var material_ids: Array[String] = []
	for material_id_variant in materials.keys():
		material_ids.append(String(material_id_variant))
	material_ids.sort()
	for material_id in material_ids:
		parts.append("+%d %s" % [int(materials.get(material_id, 0)), _get_material_display_name(material_id)])
	for seed_id in _normalize_string_id_array(normalized_reward.get("seed_ids", [])):
		parts.append("Unlock %s" % _get_seed_display_name(seed_id))
	return parts


func _get_material_display_name(material_id: String) -> String:
	var normalized_id := material_id.strip_edges().to_lower()
	if normalized_id.is_empty():
		return "Material"
	if DataRegistry != null and DataRegistry.has_method("get_material_display_name"):
		var display_name := String(DataRegistry.call("get_material_display_name", normalized_id)).strip_edges()
		if not display_name.is_empty():
			return display_name
	return normalized_id.capitalize()


func _get_seed_display_name(seed_id: String) -> String:
	var normalized_id := seed_id.strip_edges().to_lower()
	if normalized_id.is_empty():
		return "Seed Pack"
	if DataRegistry != null and DataRegistry.has_method("get_seed"):
		var seed_variant: Variant = DataRegistry.call("get_seed", normalized_id)
		if seed_variant is Dictionary:
			var seed: Dictionary = seed_variant
			var display_name := String(seed.get("name", "")).strip_edges()
			if not display_name.is_empty():
				return display_name
	return normalized_id.capitalize()


func _reward_has_content(reward: Dictionary) -> bool:
	var normalized_reward := _normalize_reward_dictionary(reward)
	if int(normalized_reward.get("gold", 0)) > 0:
		return true
	if int(normalized_reward.get("reputation", 0)) > 0:
		return true
	var materials_variant: Variant = normalized_reward.get("materials", {})
	if materials_variant is Dictionary and not (materials_variant as Dictionary).is_empty():
		return true
	return not _normalize_string_id_array(normalized_reward.get("seed_ids", [])).is_empty()


func _auto_claim_ready_orders() -> int:
	var claimed_count := 0
	for quest_id in _get_sorted_quest_ids():
		var quest := _get_daily_order(quest_id)
		if quest == null:
			continue
		if not QuestSystem.is_quest_active(quest) or not quest.objective_completed:
			continue
		var reward := _grant_reward(quest)
		reward_claimed.emit(quest.id, reward)
		claimed_count += 1
	return claimed_count


func _reset_runtime_state() -> void:
	_loaded = false
	_sync_accumulator = 0.0
	_current_day = 0
	_tracked_dish_sales.clear()
	_tracked_materials.clear()
	_quests_by_id.clear()
	_profile_path = ""
	if QuestSystem != null:
		QuestSystem.reset_pool()


func _load_order_instances() -> Array[DailyOrderQuest]:
	var quests: Array[DailyOrderQuest] = []
	for resource_path in ORDER_RESOURCE_PATHS:
		var resource_variant: Variant = load(resource_path)
		if not (resource_variant is DailyOrderQuest):
			push_warning("Daily order resource is missing or invalid: %s" % resource_path)
			continue
		var runtime_quest_variant: Variant = (resource_variant as Resource).duplicate(true)
		if runtime_quest_variant is DailyOrderQuest:
			quests.append(runtime_quest_variant as DailyOrderQuest)
	return quests


func _state_matches_catalog(state: Dictionary) -> bool:
	var serialized_variant: Variant = state.get("serialized_quests", {})
	var serialized: Dictionary = serialized_variant if serialized_variant is Dictionary else {}
	if serialized.size() != ORDER_RESOURCE_PATHS.size():
		return false
	for quest in _load_order_instances():
		if not serialized.has(str(quest.id)):
			return false
	return true


func _get_current_day() -> int:
	var meta_progress := ProfileStore.get_meta_progress_state()
	var day_state_variant: Variant = meta_progress.get("day_state", {})
	var day_state: Dictionary = day_state_variant if day_state_variant is Dictionary else {}
	return maxi(1, int(day_state.get("current_day", 1)))


func _get_profile_path() -> String:
	if ProfileStore != null and ProfileStore.has_method("get_profile_path"):
		return String(ProfileStore.call("get_profile_path"))
	return ""


func _snapshot_dish_sales(meta_progress: Dictionary) -> Dictionary:
	var economy_variant: Variant = meta_progress.get("economy", {})
	var economy: Dictionary = economy_variant if economy_variant is Dictionary else {}
	return _normalize_snapshot(economy.get("sold_dishes_stats", {}))


func _snapshot_materials(meta_progress: Dictionary) -> Dictionary:
	var inventory_variant: Variant = meta_progress.get("inventory", {})
	var inventory: Dictionary = inventory_variant if inventory_variant is Dictionary else {}
	return _normalize_snapshot(inventory.get("materials", {}))


func _normalize_snapshot(source_variant: Variant) -> Dictionary:
	var source: Dictionary = source_variant if source_variant is Dictionary else {}
	var normalized: Dictionary = {}
	for key_variant in source.keys():
		var key := String(key_variant).strip_edges().to_lower()
		if key.is_empty():
			continue
		normalized[key] = maxi(0, int(source.get(key_variant, 0)))
	return normalized


func _normalize_string_id_array(source_variant: Variant) -> Array[String]:
	var output: Array[String] = []
	if not (source_variant is Array):
		return output
	for item in source_variant:
		var text := String(item).strip_edges().to_lower()
		if text.is_empty() or output.has(text):
			continue
		output.append(text)
	return output


func _positive_delta(current: Dictionary, previous: Dictionary, key: String) -> int:
	var normalized_key := key.strip_edges().to_lower()
	if normalized_key.is_empty():
		return 0
	var current_value := maxi(0, int(current.get(normalized_key, 0)))
	var previous_value := maxi(0, int(previous.get(normalized_key, 0)))
	return maxi(0, current_value - previous_value)


func _get_sorted_quest_ids() -> Array[int]:
	var ids: Array[int] = []
	for quest_id_variant in _quests_by_id.keys():
		ids.append(int(quest_id_variant))
	ids.sort()
	return ids


func _get_daily_order(quest_id: int) -> DailyOrderQuest:
	var quest_variant: Variant = _quests_by_id.get(quest_id, null)
	if quest_variant is DailyOrderQuest:
		return quest_variant as DailyOrderQuest
	return null


func _build_status_text(completed: bool, ready_to_claim: bool) -> String:
	if completed:
		return "Completed"
	if ready_to_claim:
		return "Ready to claim"
	return "In progress"
