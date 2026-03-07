extends Button
class_name FarmPlot

signal plot_pressed(plot_index: int)

const STATE_COLORS := {
	"empty": Color("4f4a3f"),
	"tilled": Color("6f4e2f"),
	"planted": Color("2f6a3e"),
	"watered": Color("235d8f"),
	"harvestable": Color("a17a22")
}

var plot_index: int = -1
var _state_id: String = "empty"


func _ready() -> void:
	custom_minimum_size = Vector2(0.0, 96.0)
	autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	clip_text = true
	pressed.connect(_on_pressed)
	_apply_style()


func set_plot_model(model: Dictionary) -> void:
	plot_index = int(model.get("index", -1))
	disabled = not bool(model.get("enabled", true))
	var title := String(model.get("title", "")).strip_edges()
	var subtitle := String(model.get("subtitle", "")).strip_edges()
	text = title if subtitle.is_empty() else "%s\n%s" % [title, subtitle]
	tooltip_text = String(model.get("tooltip", text))
	_state_id = String(model.get("state_id", "empty")).strip_edges().to_lower()
	if not STATE_COLORS.has(_state_id):
		_state_id = "empty"
	_apply_style()


func _on_pressed() -> void:
	if plot_index < 0:
		return
	plot_pressed.emit(plot_index)


func _apply_style() -> void:
	var base_color: Color = STATE_COLORS.get(_state_id, STATE_COLORS["empty"])
	add_theme_stylebox_override("normal", _build_stylebox(base_color))
	add_theme_stylebox_override("hover", _build_stylebox(base_color.lightened(0.08)))
	add_theme_stylebox_override("pressed", _build_stylebox(base_color.darkened(0.12)))
	add_theme_stylebox_override("disabled", _build_stylebox(base_color.darkened(0.25)))


func _build_stylebox(fill_color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill_color
	style.border_color = fill_color.lightened(0.22)
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.corner_radius_top_left = 12
	style.corner_radius_top_right = 12
	style.corner_radius_bottom_right = 12
	style.corner_radius_bottom_left = 12
	return style
