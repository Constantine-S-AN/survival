extends VBoxContainer
class_name NoiseMeter

@export var meter_name: String = "Noise"

@onready var _title: Label = $Title
@onready var _bar: ProgressBar = $Bar
@onready var _tier: Label = $Tier


func _ready() -> void:
	_title.text = meter_name
	_bar.show_percentage = false


func update_meter(value: float, min_value: float, max_value: float, tier_name: String, tier_color: Color) -> void:
	_bar.min_value = min_value
	_bar.max_value = max_value
	_bar.value = value
	_tier.text = "档位：%s" % tier_name if _is_zh() else "Tier: %s" % tier_name
	_tier.modulate = tier_color
	_bar.modulate = tier_color


func _is_zh() -> bool:
	if Localization == null or not Localization.has_method("is_chinese"):
		return false
	return bool(Localization.call("is_chinese"))
