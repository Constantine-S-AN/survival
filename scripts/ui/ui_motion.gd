extends RefCounted
class_name UIMotion

static var _motion_enabled: bool = true


static func set_motion_enabled(enabled: bool) -> void:
	# TODO(settings): bind this to a future reduce_motion toggle in Settings.
	_motion_enabled = enabled


static func is_motion_enabled() -> bool:
	return _motion_enabled


static func hover_scale(control: Control, scale: float = 1.02, duration: float = 0.08) -> void:
	if control == null:
		return
	var base_scale := _get_base_scale(control)
	if not _motion_enabled:
		control.scale = base_scale
		return
	_kill_tween(control, "ui_motion_hover_tween")
	var target := base_scale * scale
	var tween := control.create_tween()
	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(control, "scale", target, maxf(0.01, duration))
	control.set_meta("ui_motion_hover_tween", tween)


static func press_bounce(control: Control, duration: float = 0.10) -> void:
	if control == null:
		return
	var base_scale := _get_base_scale(control)
	if not _motion_enabled:
		control.scale = base_scale
		return
	_kill_tween(control, "ui_motion_press_tween")
	var down_duration := maxf(0.01, duration * 0.45)
	var up_duration := maxf(0.01, duration * 0.55)
	var tween := control.create_tween()
	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(control, "scale", base_scale * 0.97, down_duration)
	tween.tween_property(control, "scale", base_scale, up_duration)
	control.set_meta("ui_motion_press_tween", tween)


static func focus_ring(control: Control) -> void:
	if control == null:
		return
	if not _motion_enabled:
		control.self_modulate = Color(1.0, 1.0, 1.0, 1.0)
		return
	_kill_tween(control, "ui_motion_focus_tween")
	var tween := control.create_tween()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(control, "self_modulate", Color(1.05, 1.08, 1.12, 1.0), 0.07)
	tween.tween_property(control, "self_modulate", Color(1.0, 1.0, 1.0, 1.0), 0.15)
	control.set_meta("ui_motion_focus_tween", tween)


static func panel_pop_in(control: Control, duration: float = 0.16, y_offset: float = 10.0) -> void:
	if control == null:
		return
	_kill_tween(control, "ui_motion_panel_tween")
	var container_managed := _is_container_managed(control)
	if not _motion_enabled:
		control.modulate.a = 1.0
		if container_managed:
			control.scale = _get_base_scale(control)
		else:
			control.position.y = _get_base_position(control).y
		return
	var base_scale := _get_base_scale(control)
	var base_position := _get_base_position(control)
	if container_managed:
		control.scale = base_scale * 0.985
	else:
		control.position = Vector2(base_position.x, base_position.y + y_offset)
	control.modulate.a = 0.0
	var tween := control.create_tween()
	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_OUT)
	if container_managed:
		tween.tween_property(control, "scale", base_scale, maxf(0.01, duration))
	else:
		tween.tween_property(control, "position", base_position, maxf(0.01, duration))
	tween.parallel().tween_property(control, "modulate:a", 1.0, maxf(0.01, duration))
	control.set_meta("ui_motion_panel_tween", tween)


static func _get_base_scale(control: Control) -> Vector2:
	if control.has_meta("ui_motion_base_scale"):
		var stored: Variant = control.get_meta("ui_motion_base_scale")
		if stored is Vector2:
			return stored
	control.set_meta("ui_motion_base_scale", control.scale)
	return control.scale


static func _get_base_position(control: Control) -> Vector2:
	if control.has_meta("ui_motion_base_position"):
		var stored: Variant = control.get_meta("ui_motion_base_position")
		if stored is Vector2:
			return stored
	control.set_meta("ui_motion_base_position", control.position)
	return control.position


static func _kill_tween(control: Control, key: String) -> void:
	if not control.has_meta(key):
		return
	var tween_variant: Variant = control.get_meta(key)
	if tween_variant is Tween:
		var tween: Tween = tween_variant
		if is_instance_valid(tween):
			tween.kill()
	control.remove_meta(key)


static func _is_container_managed(control: Control) -> bool:
	return control.get_parent() is Container
