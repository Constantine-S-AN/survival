extends PanelContainer
class_name StatBadge

@export var label_text: String = "Label"
@export var value_text: String = "x1.00"

@onready var _label: Label = $Margin/Row/Label
@onready var _value: Label = $Margin/Row/Value


func _ready() -> void:
	theme_type_variation = &"BadgePanel"
	_apply_text()


func set_badge(label: String, value: String) -> void:
	label_text = label
	value_text = value
	_apply_text()


func _apply_text() -> void:
	if _label == null or _value == null:
		return
	_label.text = label_text
	_value.text = value_text
