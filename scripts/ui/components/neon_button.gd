extends Button
class_name NeonButton

const UIMotion := preload("res://scripts/ui/ui_motion.gd")
const UISfx := preload("res://scripts/ui/ui_sfx.gd")

enum ButtonRole {
	PRIMARY,
	SECONDARY,
	DANGER
}

@export var use_primary_style: bool = true
@export var button_role: ButtonRole = ButtonRole.PRIMARY
@export var enable_motion: bool = true
@export var hover_scale: float = 1.02
@export var hover_duration: float = 0.08
@export var press_duration: float = 0.10


func _ready() -> void:
	if not use_primary_style and button_role == ButtonRole.PRIMARY:
		button_role = ButtonRole.SECONDARY
	_apply_button_role()
	focus_mode = Control.FOCUS_ALL
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	mouse_entered.connect(_on_hover_entered)
	mouse_exited.connect(_on_hover_exited)
	focus_entered.connect(_on_focus_entered)
	focus_exited.connect(_on_hover_exited)
	button_down.connect(_on_button_down)
	button_up.connect(_on_hover_entered)
	pressed.connect(_on_pressed)


func _on_hover_entered() -> void:
	if disabled or not enable_motion:
		return
	var target_scale := hover_scale
	if button_role == ButtonRole.SECONDARY:
		target_scale = minf(hover_scale, 1.015)
	elif button_role == ButtonRole.DANGER:
		target_scale = maxf(hover_scale, 1.04)
	UIMotion.hover_scale(self, target_scale, hover_duration)
	UISfx.play_hover()


func _on_hover_exited() -> void:
	if not enable_motion:
		return
	UIMotion.hover_scale(self, 1.0, hover_duration)


func _on_button_down() -> void:
	if disabled or not enable_motion:
		return
	UIMotion.press_bounce(self, press_duration)
	UISfx.play_click()


func _on_focus_entered() -> void:
	if not enable_motion:
		return
	UIMotion.focus_ring(self)


func set_motion_enabled(enabled: bool) -> void:
	enable_motion = enabled
	if not enable_motion:
		scale = Vector2.ONE


func set_button_role(role: ButtonRole) -> void:
	button_role = role
	_apply_button_role()


func _on_pressed() -> void:
	if disabled:
		return
	if button_role == ButtonRole.PRIMARY:
		UISfx.play_confirm()


func _apply_button_role() -> void:
	match button_role:
		ButtonRole.PRIMARY:
			theme_type_variation = &"PrimaryButton"
		ButtonRole.SECONDARY:
			theme_type_variation = &"SecondaryButton"
		ButtonRole.DANGER:
			theme_type_variation = &"DangerButton"
		_:
			theme_type_variation = &"Button"
