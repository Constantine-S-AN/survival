extends CanvasLayer
class_name SceneFader

@export var default_color: Color = Color(0.0, 0.0, 0.0, 1.0)

@onready var _overlay: ColorRect = $Overlay


func _ready() -> void:
	_overlay.color = default_color
	_overlay.visible = false
	_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE


func fade_in(duration_sec: float = 0.25) -> Tween:
	_overlay.visible = true
	_overlay.modulate.a = 1.0
	var tween := create_tween()
	tween.tween_property(_overlay, "modulate:a", 0.0, duration_sec)
	tween.finished.connect(func() -> void:
		_overlay.visible = false
	)
	return tween


func fade_out(duration_sec: float = 0.25) -> Tween:
	_overlay.visible = true
	_overlay.modulate.a = 0.0
	var tween := create_tween()
	tween.tween_property(_overlay, "modulate:a", 1.0, duration_sec)
	return tween
