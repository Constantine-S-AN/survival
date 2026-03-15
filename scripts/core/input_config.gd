extends RefCounted
class_name InputConfig

static func ensure_default_actions() -> void:
	_ensure_action("move_up", [KEY_W, KEY_UP])
	_ensure_action("move_down", [KEY_S, KEY_DOWN])
	_ensure_action("move_left", [KEY_A, KEY_LEFT])
	_ensure_action("move_right", [KEY_D, KEY_RIGHT])
	_ensure_action("day_interact", [KEY_E, KEY_ENTER, KEY_KP_ENTER])
	_ensure_action("night_interact", [KEY_F, KEY_ENTER, KEY_KP_ENTER])
	_ensure_action("day_cycle_farm_tool_prev", [KEY_Q])
	_ensure_action("day_cycle_farm_tool_next", [KEY_TAB])
	_ensure_action("day_hotbar_slot_1", [KEY_1, KEY_KP_1])
	_ensure_action("day_hotbar_slot_2", [KEY_2, KEY_KP_2])
	_ensure_action("day_hotbar_slot_3", [KEY_3, KEY_KP_3])
	_ensure_action("day_hotbar_slot_4", [KEY_4, KEY_KP_4])
	_ensure_action("day_hotbar_slot_5", [KEY_5, KEY_KP_5])
	_ensure_action("day_hotbar_slot_6", [KEY_6, KEY_KP_6])
	_ensure_action("dash", [KEY_SPACE, KEY_SHIFT])
	_ensure_action("sonar_skill", [KEY_Q, KEY_E])
	_ensure_action("toggle_attack_mode", [KEY_TAB])
	_ensure_mouse_action("manual_fire", [MOUSE_BUTTON_LEFT])


static func _ensure_action(action: String, keycodes: Array[int]) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	var events := InputMap.action_get_events(action)
	for keycode in keycodes:
		if _has_key_event(events, keycode):
			continue
		var event := InputEventKey.new()
		event.physical_keycode = keycode
		event.keycode = keycode
		InputMap.action_add_event(action, event)


static func _ensure_mouse_action(action: String, buttons: Array[int]) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	var events := InputMap.action_get_events(action)
	for button in buttons:
		if _has_mouse_event(events, button):
			continue
		var event := InputEventMouseButton.new()
		event.button_index = button
		InputMap.action_add_event(action, event)


static func _has_key_event(events: Array, keycode: int) -> bool:
	for event in events:
		if event is InputEventKey and int(event.physical_keycode) == keycode:
			return true
	return false


static func _has_mouse_event(events: Array, button: int) -> bool:
	for event in events:
		if event is InputEventMouseButton and int(event.button_index) == button:
			return true
	return false
