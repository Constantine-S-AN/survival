extends PanelContainer
class_name NeonCard

@export var hover_lift_px: float = 3.0
@export var hover_tint: Color = Color(1.06, 1.06, 1.08, 1.0)

var _base_position: Vector2


func _ready() -> void:
	theme_type_variation = &"CardPanel"
	_base_position = position
	mouse_filter = Control.MOUSE_FILTER_STOP
	mouse_entered.connect(_on_hover_entered)
	mouse_exited.connect(_on_hover_exited)


func _on_hover_entered() -> void:
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "position:y", _base_position.y - hover_lift_px, 0.12)
	tween.parallel().tween_property(self, "modulate", hover_tint, 0.12)


func _on_hover_exited() -> void:
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "position:y", _base_position.y, 0.15)
	tween.parallel().tween_property(self, "modulate", Color(1, 1, 1, 1), 0.15)
