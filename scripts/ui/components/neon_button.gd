extends Button
class_name NeonButton

@export var use_primary_style: bool = true
@export var hover_scale: Vector2 = Vector2(1.015, 1.015)

var _base_scale: Vector2 = Vector2.ONE


func _ready() -> void:
	if use_primary_style:
		theme_type_variation = &"PrimaryButton"
	_base_scale = scale
	focus_mode = Control.FOCUS_ALL
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	mouse_entered.connect(_on_hover_entered)
	mouse_exited.connect(_on_hover_exited)
	focus_entered.connect(_on_hover_entered)
	focus_exited.connect(_on_hover_exited)
	button_down.connect(_on_button_down)
	button_up.connect(_on_hover_entered)


func _on_hover_entered() -> void:
	if disabled:
		return
	_create_scale_tween(hover_scale, 0.09)


func _on_hover_exited() -> void:
	_create_scale_tween(_base_scale, 0.12)


func _on_button_down() -> void:
	if disabled:
		return
	_create_scale_tween(Vector2(0.99, 0.99), 0.06)


func _create_scale_tween(target: Vector2, duration: float) -> void:
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", target, duration)
