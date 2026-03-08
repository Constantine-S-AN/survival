extends CanvasLayer

const DAY_HUB_INTRO_DIALOGUE_ID := "day_hub_intro"
const DAY_HUB_INTRO_DIALOGUE_TITLE := "intro"
const DAY_HUB_INTRO_DIALOGUE_PATH := "res://data/dialogue/day_hub_intro.dialogue"
const MORNING_PHASE := "morning"

var _dialogue_blocking_active: bool = false
var _active_dialogue_resource_path: String = ""
var _input_blocker: Control = null


func _ready() -> void:
	layer = 90
	process_mode = Node.PROCESS_MODE_ALWAYS
	_ensure_input_blocker()
	_connect_day_hub_signals()
	_connect_dialogue_manager_signals()
	var day_hub := _get_day_hub()
	if day_hub != null and day_hub.visible:
		_maybe_show_day_hub_intro_dialogue.call_deferred()


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


func _connect_day_hub_signals() -> void:
	var day_hub := _get_day_hub()
	if day_hub == null:
		return
	var visibility_callable := Callable(self, "_on_day_hub_visibility_changed")
	if day_hub.is_connected("visibility_changed", visibility_callable):
		return
	day_hub.connect("visibility_changed", visibility_callable)


func _connect_dialogue_manager_signals() -> void:
	var dialogue_manager := _get_dialogue_manager()
	if dialogue_manager == null or not dialogue_manager.has_signal("dialogue_ended"):
		return
	var ended_callable := Callable(self, "_on_dialogue_ended")
	if dialogue_manager.is_connected("dialogue_ended", ended_callable):
		return
	dialogue_manager.connect("dialogue_ended", ended_callable)


func _get_day_hub() -> Control:
	var parent := get_parent()
	if parent == null:
		return null
	var day_hub: Node = parent.get_node_or_null("DayHub")
	return day_hub as Control


func _get_dialogue_manager() -> Node:
	return get_node_or_null("/root/DialogueManager")


func _on_day_hub_visibility_changed() -> void:
	var day_hub := _get_day_hub()
	if day_hub == null or not day_hub.visible:
		return
	_maybe_show_day_hub_intro_dialogue.call_deferred()


func _maybe_show_day_hub_intro_dialogue() -> void:
	if not _should_show_day_hub_intro_dialogue():
		return
	var dialogue_manager := _get_dialogue_manager()
	if dialogue_manager == null or not dialogue_manager.has_method("show_dialogue_balloon"):
		return
	if not ResourceLoader.exists(DAY_HUB_INTRO_DIALOGUE_PATH):
		push_warning("Missing day hub intro dialogue resource: %s" % DAY_HUB_INTRO_DIALOGUE_PATH)
		return
	var resource: Resource = load(DAY_HUB_INTRO_DIALOGUE_PATH)
	if resource == null:
		push_warning("Failed to load day hub intro dialogue resource: %s" % DAY_HUB_INTRO_DIALOGUE_PATH)
		return
	var balloon: Variant = dialogue_manager.call("show_dialogue_balloon", resource, DAY_HUB_INTRO_DIALOGUE_TITLE)
	if balloon == null:
		return
	_active_dialogue_resource_path = resource.resource_path
	_set_dialogue_blocking(true)
	_mark_dialogue_seen(DAY_HUB_INTRO_DIALOGUE_ID)


func _should_show_day_hub_intro_dialogue() -> bool:
	var day_hub := _get_day_hub()
	if day_hub == null or not day_hub.visible:
		return false
	if _dialogue_blocking_active:
		return false
	if DisplayServer.get_name() == "headless":
		return false
	if ProfileStore == null or not bool(ProfileStore.loaded):
		return false
	var meta_progress := ProfileStore.get_meta_progress_state()
	var day_state_variant: Variant = meta_progress.get("day_state", {})
	if not (day_state_variant is Dictionary):
		return false
	var day_state: Dictionary = day_state_variant
	if int(day_state.get("current_day", 1)) != 1:
		return false
	if String(day_state.get("current_phase", "")).strip_edges().to_lower() != MORNING_PHASE:
		return false
	var pending_summary_variant: Variant = meta_progress.get("pending_return_summary", {})
	if pending_summary_variant is Dictionary and not (pending_summary_variant as Dictionary).is_empty():
		return false
	return not _has_seen_dialogue(DAY_HUB_INTRO_DIALOGUE_ID)


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
