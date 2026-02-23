extends Button
class_name NeonButton

const UIMotion := preload("res://scripts/ui/ui_motion.gd")

@export var use_primary_style: bool = true
@export var enable_motion: bool = true
@export var hover_scale: float = 1.02
@export var hover_duration: float = 0.08
@export var press_duration: float = 0.10


func _ready() -> void:
	if use_primary_style:
		theme_type_variation = &"PrimaryButton"
	focus_mode = Control.FOCUS_ALL
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	mouse_entered.connect(_on_hover_entered)
	mouse_exited.connect(_on_hover_exited)
	focus_entered.connect(_on_focus_entered)
	focus_exited.connect(_on_hover_exited)
	button_down.connect(_on_button_down)
	button_up.connect(_on_hover_entered)


func _on_hover_entered() -> void:
	if disabled or not enable_motion:
		return
	UIMotion.hover_scale(self, hover_scale, hover_duration)


func _on_hover_exited() -> void:
	if not enable_motion:
		return
	UIMotion.hover_scale(self, 1.0, hover_duration)


func _on_button_down() -> void:
	if disabled or not enable_motion:
		return
	UIMotion.press_bounce(self, press_duration)


func _on_focus_entered() -> void:
	if not enable_motion:
		return
	UIMotion.focus_ring(self)


func set_motion_enabled(enabled: bool) -> void:
	enable_motion = enabled
	if not enable_motion:
		scale = Vector2.ONE
