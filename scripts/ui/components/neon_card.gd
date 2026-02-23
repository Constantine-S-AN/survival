extends PanelContainer
class_name NeonCard

const UIMotion := preload("res://scripts/ui/ui_motion.gd")

@export var hover_lift_px: float = 3.0
@export var hover_tint: Color = Color(1.06, 1.06, 1.08, 1.0)
@export var enable_breathing_motion: bool = true
@export var breathing_speed: float = 0.46
@export var breathing_alpha_amp: float = 0.04
@export var play_intro_on_show: bool = true

var _base_position: Vector2
var _base_scale: Vector2 = Vector2.ONE
var _base_modulate: Color = Color(1, 1, 1, 1)
var _time_accum: float = 0.0


func _ready() -> void:
	theme_type_variation = &"CardPanel"
	_base_position = position
	_base_scale = scale
	_base_modulate = modulate
	mouse_filter = Control.MOUSE_FILTER_STOP
	mouse_entered.connect(_on_hover_entered)
	mouse_exited.connect(_on_hover_exited)
	visibility_changed.connect(_on_visibility_changed)
	set_process(enable_breathing_motion)
	if play_intro_on_show and visible:
		UIMotion.panel_pop_in(self, 0.14, 8.0)


func _process(delta: float) -> void:
	if not enable_breathing_motion:
		return
	if not UIMotion.is_motion_enabled():
		modulate = _base_modulate
		return
	_time_accum += delta
	var breathe := sin(_time_accum * TAU * breathing_speed) * breathing_alpha_amp
	modulate = Color(_base_modulate.r, _base_modulate.g, _base_modulate.b, clampf(1.0 + breathe, 0.9, 1.08))


func _on_hover_entered() -> void:
	if not UIMotion.is_motion_enabled():
		return
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_OUT)
	if _is_container_managed():
		tween.tween_property(self, "scale", _base_scale * 1.01, 0.12)
	else:
		tween.tween_property(self, "position:y", _base_position.y - hover_lift_px, 0.12)
	tween.parallel().tween_property(self, "modulate", hover_tint, 0.12)


func _on_hover_exited() -> void:
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_OUT)
	if _is_container_managed():
		tween.tween_property(self, "scale", _base_scale, 0.15)
	else:
		tween.tween_property(self, "position:y", _base_position.y, 0.15)
	tween.parallel().tween_property(self, "modulate", _base_modulate, 0.15)


func _on_visibility_changed() -> void:
	if not visible:
		return
	_base_position = position
	_base_scale = scale
	_base_modulate = modulate
	if play_intro_on_show:
		UIMotion.panel_pop_in(self, 0.14, 8.0)


func _is_container_managed() -> bool:
	return get_parent() is Container
