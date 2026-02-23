extends PanelContainer
class_name TooltipBubble

@onready var _text_label: Label = $Margin/Text
@onready var _hide_timer: Timer = $HideTimer


func _ready() -> void:
	theme_type_variation = &"TooltipPanel"
	visible = false
	_hide_timer.timeout.connect(func() -> void:
		visible = false
	)


func show_tooltip(text: String, duration_sec: float = 0.0) -> void:
	_text_label.text = text
	visible = true
	if duration_sec > 0.0:
		_hide_timer.start(duration_sec)
	else:
		_hide_timer.stop()


func hide_tooltip() -> void:
	visible = false
	_hide_timer.stop()
