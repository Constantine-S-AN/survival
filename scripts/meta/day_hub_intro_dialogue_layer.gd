extends CanvasLayer

const DAY_HUB_INTRO_DIALOGUE_ID := "day_hub_intro"
const DAY_HUB_INTRO_DIALOGUE_TITLE := "intro"
const DAY_HUB_DAY2_DIALOGUE_ID := "day_hub_day2_morning"
const DAY_HUB_DAY2_DIALOGUE_TITLE := "day2_morning"
const DAY_HUB_DAY3_DIALOGUE_ID := "day_hub_day3_morning"
const DAY_HUB_DAY3_DIALOGUE_TITLE := "day3_morning"
const DAY_HUB_INTRO_DIALOGUE_PATH := "res://data/dialogue/day_hub_intro.dialogue"
const RETURN_SUMMARY_DIALOGUE_PATH := "res://data/dialogue/return_summary_events.dialogue"
const RESTAURANT_DIALOGUE_PATH := "res://data/dialogue/restaurant_special_customer.dialogue"
const RETURN_SUMMARY_FIRST_DIALOGUE_ID := "return_summary_first_return"
const RETURN_SUMMARY_FIRST_DIALOGUE_TITLE := "first_return"
const RETURN_SUMMARY_RARE_DIALOGUE_ID := "return_summary_rare_loot"
const RETURN_SUMMARY_RARE_DIALOGUE_TITLE := "rare_loot"
const RETURN_SUMMARY_POOR_DIALOGUE_ID := "return_summary_poor_run"
const RETURN_SUMMARY_POOR_DIALOGUE_TITLE := "poor_run"
const RESTAURANT_FIELD_STEW_DIALOGUE_ID := "restaurant_special_customer_field_stew"
const RESTAURANT_FIELD_STEW_DIALOGUE_TITLE := "field_stew_special"
const MORNING_PHASE := "morning"
const FIELD_STEW_RECIPE_ID := "field_stew"
const RARE_LOOT_IDS := [
	"abyssfin",
	"glow_kelp",
	"moon_spore",
	"kitchen_blueprint_fragment"
]

var _dialogue_blocking_active: bool = false
var _active_dialogue_resource_path: String = ""
var _input_blocker: Control = null


func _ready() -> void:
	layer = 90
	process_mode = Node.PROCESS_MODE_ALWAYS
	_ensure_input_blocker()
	_connect_daytime_hub_signals()
	_connect_restaurant_signals()
	_connect_return_summary_signals()
	_connect_dialogue_manager_signals()
	if _is_any_daytime_hub_visible():
		_maybe_show_day_hub_intro_dialogue.call_deferred()
	var restaurant := _get_restaurant()
	if restaurant != null and restaurant.visible:
		_maybe_show_restaurant_dialogue.call_deferred()
	var return_summary := _get_return_summary()
	if return_summary != null and return_summary.visible:
		_maybe_show_return_summary_dialogue.call_deferred()


func _ensure_input_blocker() -> void:
	if _input_blocker != null:
		return
	_input_blocker = Control.new()
	_input_blocker.name = "InputBlocker"
	_input_blocker.visible = false
	_input_blocker.mouse_filter = Control.MOUSE_FILTER_STOP
	_input_blocker.focus_mode = Control.FOCUS_NONE
	_input_blocker.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_input_blocker)


func _connect_daytime_hub_signals() -> void:
	var visibility_callable := Callable(self, "_on_day_hub_visibility_changed")
	for day_hub in _get_daytime_hubs():
		if day_hub.is_connected("visibility_changed", visibility_callable):
			continue
		day_hub.connect("visibility_changed", visibility_callable)


func _connect_restaurant_signals() -> void:
	var restaurant := _get_restaurant()
	if restaurant == null:
		return
	var visibility_callable := Callable(self, "_on_restaurant_visibility_changed")
	if restaurant.is_connected("visibility_changed", visibility_callable):
		return
	restaurant.connect("visibility_changed", visibility_callable)


func _connect_return_summary_signals() -> void:
	var return_summary := _get_return_summary()
	if return_summary == null:
		return
	var visibility_callable := Callable(self, "_on_return_summary_visibility_changed")
	if return_summary.is_connected("visibility_changed", visibility_callable):
		return
	return_summary.connect("visibility_changed", visibility_callable)


func _connect_dialogue_manager_signals() -> void:
	var dialogue_manager := _get_dialogue_manager()
	if dialogue_manager == null or not dialogue_manager.has_signal("dialogue_ended"):
		return
	var ended_callable := Callable(self, "_on_dialogue_ended")
	if dialogue_manager.is_connected("dialogue_ended", ended_callable):
		return
	dialogue_manager.connect("dialogue_ended", ended_callable)


func _get_day_hub() -> CanvasItem:
	for day_hub in _get_daytime_hubs():
		if day_hub != null and day_hub.visible:
			return day_hub
	var hubs := _get_daytime_hubs()
	return hubs[0] if not hubs.is_empty() else null


func _get_daytime_hubs() -> Array[CanvasItem]:
	var parent := get_parent()
	if parent == null:
		return []
	var hubs: Array[CanvasItem] = []
	for node_name in ["DayHub", "DayWorld"]:
		var hub: Node = parent.get_node_or_null(node_name)
		if hub is CanvasItem:
			hubs.append(hub as CanvasItem)
	return hubs


func _is_any_daytime_hub_visible() -> bool:
	for day_hub in _get_daytime_hubs():
		if day_hub != null and day_hub.visible:
			return true
	return false


func _get_restaurant() -> Control:
	var parent := get_parent()
	if parent == null:
		return null
	var restaurant: Node = parent.get_node_or_null("Restaurant")
	return restaurant as Control


func _get_return_summary() -> Control:
	var parent := get_parent()
	if parent == null:
		return null
	var return_summary: Node = parent.get_node_or_null("ReturnSummary")
	return return_summary as Control


func _get_dialogue_manager() -> Node:
	return get_node_or_null("/root/DialogueManager")


func _on_day_hub_visibility_changed() -> void:
	if not _is_any_daytime_hub_visible():
		return
	_maybe_show_day_hub_intro_dialogue.call_deferred()


func _on_restaurant_visibility_changed() -> void:
	var restaurant := _get_restaurant()
	if restaurant == null or not restaurant.visible:
		return
	_maybe_show_restaurant_dialogue.call_deferred()


func _on_return_summary_visibility_changed() -> void:
	var return_summary := _get_return_summary()
	if return_summary == null or not return_summary.visible:
		return
	_maybe_show_return_summary_dialogue.call_deferred()


func _process(_delta: float) -> void:
	_maybe_show_restaurant_dialogue()


func _maybe_show_day_hub_intro_dialogue() -> void:
	if not _should_show_day_hub_intro_dialogue():
		return
	var meta_progress := ProfileStore.get_meta_progress_state() if ProfileStore != null and bool(ProfileStore.loaded) else {}
	var candidate := _select_day_hub_morning_dialogue(meta_progress, _get_seen_dialogue_ids())
	if candidate.is_empty():
		return
	_show_dialogue(
		DAY_HUB_INTRO_DIALOGUE_PATH,
		String(candidate.get("title", "")),
		String(candidate.get("id", ""))
	)


func _maybe_show_restaurant_dialogue() -> void:
	if not _should_show_restaurant_dialogue():
		return
	var service_snapshot := _get_restaurant_service_snapshot()
	var dialogue_id := _select_restaurant_dialogue_id(
		service_snapshot.get("summary", {}),
		int(service_snapshot.get("current_day", 0)),
		int(service_snapshot.get("last_service_day", 0)),
		_get_seen_dialogue_ids()
	)
	if dialogue_id.is_empty():
		return
	var dialogue_title := _get_restaurant_dialogue_title(dialogue_id)
	if dialogue_title.is_empty():
		return
	_show_dialogue(RESTAURANT_DIALOGUE_PATH, dialogue_title, dialogue_id)


func _maybe_show_return_summary_dialogue() -> void:
	if not _should_show_return_summary_dialogue():
		return
	var summary := _get_pending_return_summary()
	var seen_dialogue_ids := _get_seen_dialogue_ids()
	var dialogue_id := _select_return_summary_dialogue_id(summary, seen_dialogue_ids)
	if dialogue_id.is_empty():
		return
	var dialogue_title := _get_return_summary_dialogue_title(dialogue_id)
	if dialogue_title.is_empty():
		return
	_show_dialogue(RETURN_SUMMARY_DIALOGUE_PATH, dialogue_title, dialogue_id)


func _should_show_day_hub_intro_dialogue() -> bool:
	if not _is_any_daytime_hub_visible():
		return false
	if _dialogue_blocking_active:
		return false
	if DisplayServer.get_name() == "headless":
		return false
	if ProfileStore == null or not bool(ProfileStore.loaded):
		return false
	var meta_progress := ProfileStore.get_meta_progress_state()
	return not _select_day_hub_morning_dialogue(meta_progress, _get_seen_dialogue_ids()).is_empty()


func _should_show_restaurant_dialogue() -> bool:
	var restaurant := _get_restaurant()
	if restaurant == null or not restaurant.visible:
		return false
	if _dialogue_blocking_active:
		return false
	if DisplayServer.get_name() == "headless":
		return false
	if ProfileStore == null or not bool(ProfileStore.loaded):
		return false
	var service_snapshot := _get_restaurant_service_snapshot()
	if int(service_snapshot.get("current_day", 0)) != int(service_snapshot.get("last_service_day", -1)):
		return false
	var summary_variant: Variant = service_snapshot.get("summary", {})
	return summary_variant is Dictionary and not (summary_variant as Dictionary).is_empty()


func _should_show_return_summary_dialogue() -> bool:
	var return_summary := _get_return_summary()
	if return_summary == null or not return_summary.visible:
		return false
	if _dialogue_blocking_active:
		return false
	if DisplayServer.get_name() == "headless":
		return false
	if ProfileStore == null or not bool(ProfileStore.loaded):
		return false
	return not _get_pending_return_summary().is_empty()


func _show_dialogue(resource_path: String, dialogue_title: String, dialogue_id: String) -> void:
	var dialogue_manager := _get_dialogue_manager()
	if dialogue_manager == null or not dialogue_manager.has_method("show_dialogue_balloon"):
		return
	if not ResourceLoader.exists(resource_path):
		push_warning("Missing dialogue resource: %s" % resource_path)
		return
	var resource: Resource = load(resource_path)
	if resource == null:
		push_warning("Failed to load dialogue resource: %s" % resource_path)
		return
	var balloon: Variant = dialogue_manager.call("show_dialogue_balloon", resource, dialogue_title)
	if balloon == null:
		return
	_active_dialogue_resource_path = resource.resource_path
	_set_dialogue_blocking(true)
	_mark_dialogue_seen(dialogue_id)


func debug_mark_dialogue_seen(dialogue_id: String) -> void:
	_mark_dialogue_seen(dialogue_id)


func debug_get_snapshot() -> Dictionary:
	var seen_dialogue_ids := _get_seen_dialogue_ids()
	var pending_summary := _get_pending_return_summary()
	var meta_progress := ProfileStore.get_meta_progress_state() if ProfileStore != null and bool(ProfileStore.loaded) else {}
	var service_snapshot := _get_restaurant_service_snapshot()
	var morning_candidate := _select_day_hub_morning_dialogue(meta_progress, seen_dialogue_ids)
	return {
		"seen_dialogue_ids": seen_dialogue_ids,
		"dialogue_blocking_active": _dialogue_blocking_active,
		"active_dialogue_resource_path": _active_dialogue_resource_path,
		"day_hub_intro_candidate_id": (
			DAY_HUB_INTRO_DIALOGUE_ID
			if _should_show_day_hub_intro_for_state(meta_progress, seen_dialogue_ids)
			else ""
		),
		"day_hub_morning_candidate_id": String(morning_candidate.get("id", "")),
		"restaurant_candidate_id": _select_restaurant_dialogue_id(
			service_snapshot.get("summary", {}),
			int(service_snapshot.get("current_day", 0)),
			int(service_snapshot.get("last_service_day", 0)),
			seen_dialogue_ids
		),
		"return_summary_candidate_id": _select_return_summary_dialogue_id(pending_summary, seen_dialogue_ids),
		"pending_return_summary": pending_summary.duplicate(true),
		"restaurant_service_snapshot": service_snapshot.duplicate(true)
	}


func _has_seen_dialogue(dialogue_id: String) -> bool:
	return _get_seen_dialogue_ids().has(dialogue_id.strip_edges().to_lower())


func _mark_dialogue_seen(dialogue_id: String) -> void:
	if ProfileStore == null or not ProfileStore.has_method("get_dialogue_state") or not ProfileStore.has_method("set_dialogue_state"):
		return
	var normalized_dialogue_id := dialogue_id.strip_edges().to_lower()
	if normalized_dialogue_id.is_empty():
		return
	var dialogue_state := ProfileStore.get_dialogue_state()
	var seen_dialogue_ids := _normalize_string_id_array(dialogue_state.get("seen_dialogue_ids", []))
	if seen_dialogue_ids.has(normalized_dialogue_id):
		return
	seen_dialogue_ids.append(normalized_dialogue_id)
	dialogue_state["seen_dialogue_ids"] = seen_dialogue_ids
	ProfileStore.set_dialogue_state(dialogue_state)


func _get_seen_dialogue_ids() -> Array[String]:
	if ProfileStore == null or not ProfileStore.has_method("get_dialogue_state"):
		return []
	var dialogue_state := ProfileStore.get_dialogue_state()
	return _normalize_string_id_array(dialogue_state.get("seen_dialogue_ids", []))


func _set_dialogue_blocking(enabled: bool) -> void:
	_dialogue_blocking_active = enabled
	if _input_blocker != null:
		_input_blocker.visible = enabled


func _on_dialogue_ended(resource: Resource) -> void:
	if _active_dialogue_resource_path.is_empty():
		return
	if resource == null or resource.resource_path != _active_dialogue_resource_path:
		return
	_active_dialogue_resource_path = ""
	_set_dialogue_blocking(false)


func _get_pending_return_summary() -> Dictionary:
	if ProfileStore == null or not bool(ProfileStore.loaded):
		return {}
	var meta_progress := ProfileStore.get_meta_progress_state()
	var pending_summary_variant: Variant = meta_progress.get("pending_return_summary", {})
	if pending_summary_variant is Dictionary:
		return (pending_summary_variant as Dictionary).duplicate(true)
	return {}


func _should_show_day_hub_intro_for_state(meta_progress_variant: Variant, seen_dialogue_ids: Array) -> bool:
	var candidate := _select_day_hub_morning_dialogue(meta_progress_variant, seen_dialogue_ids)
	return String(candidate.get("id", "")) == DAY_HUB_INTRO_DIALOGUE_ID


func _select_day_hub_morning_dialogue(meta_progress_variant: Variant, seen_dialogue_ids: Array) -> Dictionary:
	if not (meta_progress_variant is Dictionary):
		return {}
	var meta_progress: Dictionary = meta_progress_variant
	var day_state_variant: Variant = meta_progress.get("day_state", {})
	if not (day_state_variant is Dictionary):
		return {}
	var day_state: Dictionary = day_state_variant
	if String(day_state.get("current_phase", "")).strip_edges().to_lower() != MORNING_PHASE:
		return {}
	var pending_summary_variant: Variant = meta_progress.get("pending_return_summary", {})
	if pending_summary_variant is Dictionary and not (pending_summary_variant as Dictionary).is_empty():
		return {}
	var normalized_seen_ids := _normalize_string_id_array(seen_dialogue_ids)
	match int(day_state.get("current_day", 1)):
		1:
			if normalized_seen_ids.has(DAY_HUB_INTRO_DIALOGUE_ID):
				return {}
			return {
				"id": DAY_HUB_INTRO_DIALOGUE_ID,
				"title": DAY_HUB_INTRO_DIALOGUE_TITLE
			}
		2:
			if normalized_seen_ids.has(DAY_HUB_DAY2_DIALOGUE_ID):
				return {}
			return {
				"id": DAY_HUB_DAY2_DIALOGUE_ID,
				"title": DAY_HUB_DAY2_DIALOGUE_TITLE
			}
		3:
			if normalized_seen_ids.has(DAY_HUB_DAY3_DIALOGUE_ID):
				return {}
			return {
				"id": DAY_HUB_DAY3_DIALOGUE_ID,
				"title": DAY_HUB_DAY3_DIALOGUE_TITLE
			}
	return {}


func _get_restaurant_service_snapshot() -> Dictionary:
	if ProfileStore == null or not bool(ProfileStore.loaded):
		return {}
	var meta_progress := ProfileStore.get_meta_progress_state()
	var day_state_variant: Variant = meta_progress.get("day_state", {})
	var day_state: Dictionary = day_state_variant if day_state_variant is Dictionary else {}
	var restaurant_state_variant: Variant = meta_progress.get("restaurant_state", {})
	var restaurant_state: Dictionary = restaurant_state_variant if restaurant_state_variant is Dictionary else {}
	var summary_variant: Variant = restaurant_state.get("last_service_summary", {})
	var summary: Dictionary = summary_variant if summary_variant is Dictionary else {}
	return {
		"current_day": int(day_state.get("current_day", 0)),
		"last_service_day": int(restaurant_state.get("last_service_day", 0)),
		"summary": summary.duplicate(true)
	}


func _select_restaurant_dialogue_id(summary: Dictionary, current_day: int, last_service_day: int, seen_dialogue_ids: Array) -> String:
	var normalized_seen_ids := _normalize_string_id_array(seen_dialogue_ids)
	if summary.is_empty():
		return ""
	if current_day <= 0 or current_day != last_service_day:
		return ""
	var sold_dishes_variant: Variant = summary.get("sold_dishes", {})
	var sold_dishes: Dictionary = sold_dishes_variant if sold_dishes_variant is Dictionary else {}
	if int(sold_dishes.get(FIELD_STEW_RECIPE_ID, 0)) <= 0:
		return ""
	if normalized_seen_ids.has(RESTAURANT_FIELD_STEW_DIALOGUE_ID):
		return ""
	return RESTAURANT_FIELD_STEW_DIALOGUE_ID


func _get_restaurant_dialogue_title(dialogue_id: String) -> String:
	match dialogue_id.strip_edges().to_lower():
		RESTAURANT_FIELD_STEW_DIALOGUE_ID:
			return RESTAURANT_FIELD_STEW_DIALOGUE_TITLE
	return ""


func _select_return_summary_dialogue_id(summary: Dictionary, seen_dialogue_ids: Array) -> String:
	var normalized_seen_ids := _normalize_string_id_array(seen_dialogue_ids)
	if summary.is_empty():
		return ""
	if not normalized_seen_ids.has(RETURN_SUMMARY_FIRST_DIALOGUE_ID):
		return RETURN_SUMMARY_FIRST_DIALOGUE_ID
	if _summary_has_rare_loot(summary) and not normalized_seen_ids.has(RETURN_SUMMARY_RARE_DIALOGUE_ID):
		return RETURN_SUMMARY_RARE_DIALOGUE_ID
	if _summary_is_poor_run(summary) and not normalized_seen_ids.has(RETURN_SUMMARY_POOR_DIALOGUE_ID):
		return RETURN_SUMMARY_POOR_DIALOGUE_ID
	return ""


func _get_return_summary_dialogue_title(dialogue_id: String) -> String:
	match dialogue_id.strip_edges().to_lower():
		RETURN_SUMMARY_FIRST_DIALOGUE_ID:
			return RETURN_SUMMARY_FIRST_DIALOGUE_TITLE
		RETURN_SUMMARY_RARE_DIALOGUE_ID:
			return RETURN_SUMMARY_RARE_DIALOGUE_TITLE
		RETURN_SUMMARY_POOR_DIALOGUE_ID:
			return RETURN_SUMMARY_POOR_DIALOGUE_TITLE
	return ""


func _summary_has_rare_loot(summary: Dictionary) -> bool:
	var materials_reward_variant: Variant = summary.get("materials_reward", {})
	var materials_reward: Dictionary = materials_reward_variant if materials_reward_variant is Dictionary else {}
	for rare_loot_id in RARE_LOOT_IDS:
		if int(materials_reward.get(rare_loot_id, 0)) > 0:
			return true
	var unlock_names_variant: Variant = summary.get("unlock_names", [])
	return unlock_names_variant is Array and not (unlock_names_variant as Array).is_empty()


func _summary_is_poor_run(summary: Dictionary) -> bool:
	if String(summary.get("exit_reason", "completed")).strip_edges().to_lower() != "abandoned":
		return false
	if _summary_has_rare_loot(summary):
		return false
	var materials_reward_variant: Variant = summary.get("materials_reward", {})
	var materials_reward: Dictionary = materials_reward_variant if materials_reward_variant is Dictionary else {}
	return _count_material_reward_total(materials_reward) <= 2


func _count_material_reward_total(materials_reward: Dictionary) -> int:
	var total := 0
	for material_id_variant in materials_reward.keys():
		total += maxi(0, int(materials_reward.get(material_id_variant, 0)))
	return total


func _normalize_string_id_array(source: Variant) -> Array[String]:
	var output: Array[String] = []
	if not (source is Array):
		return output
	for item in source:
		var text := String(item).strip_edges().to_lower()
		if text.is_empty() or output.has(text):
			continue
		output.append(text)
	return output
