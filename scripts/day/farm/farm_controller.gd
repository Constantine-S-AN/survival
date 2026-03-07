extends Control
class_name FarmController

signal back_requested
signal plot_action_requested(plot_index: int, action_id: String, seed_id: String)

const FarmPlotClass := preload("res://scripts/day/farm/farm_plot.gd")

@onready var title_label: Label = $ContentPanel/Margin/VBox/Title
@onready var subtitle_label: Label = $ContentPanel/Margin/VBox/Subtitle
@onready var stats_label: Label = $ContentPanel/Margin/VBox/StatsLabel
@onready var inventory_label: Label = $ContentPanel/Margin/VBox/InventoryLabel
@onready var status_label: Label = $ContentPanel/Margin/VBox/StatusLabel
@onready var tool_label: Label = $ContentPanel/Margin/VBox/ToolLabel
@onready var tool_buttons: FlowContainer = $ContentPanel/Margin/VBox/ToolButtons
@onready var plot_grid: GridContainer = $ContentPanel/Margin/VBox/PlotGrid
@onready var back_button: Button = $ContentPanel/Margin/VBox/BackButton

var _view_model: Dictionary = {}
var _selected_action_id: String = "till"
var _selected_seed_id: String = ""


func _ready() -> void:
	visible = false
	back_button.pressed.connect(func() -> void:
		back_requested.emit()
	)
	if Localization != null and Localization.has_signal("language_changed"):
		Localization.language_changed.connect(_on_language_changed)
	_apply_view_model()


func set_view_model(model: Dictionary) -> void:
	_view_model = model.duplicate(true)
	_sync_selected_tool()
	_apply_view_model()


func _apply_view_model() -> void:
	title_label.text = _t("meta.farm.title")
	subtitle_label.text = _t("meta.farm.subtitle")
	stats_label.text = _t("meta.farm.stats", {
		"day": int(_view_model.get("current_day", 1)),
		"stamina": int(_view_model.get("stamina", 0)),
		"max": int(_view_model.get("max_stamina", 0))
	})
	inventory_label.text = _t("meta.farm.inventory", {"value": String(_view_model.get("inventory_summary", "-"))})
	status_label.text = String(_view_model.get("status_text", ""))
	tool_label.text = _t("meta.farm.tool_selected", {"value": _get_selected_tool_label()})
	back_button.text = _t("meta.common.back")
	_rebuild_tool_buttons()
	_rebuild_plot_nodes()


func _sync_selected_tool() -> void:
	var tools_variant: Variant = _view_model.get("tools", [])
	var tools: Array = tools_variant if tools_variant is Array else []
	if tools.is_empty():
		_selected_action_id = ""
		_selected_seed_id = ""
		return
	for tool_variant in tools:
		if not (tool_variant is Dictionary):
			continue
		var tool: Dictionary = tool_variant
		if String(tool.get("id", "")) == _selected_action_id and String(tool.get("seed_id", "")) == _selected_seed_id:
			return
	var fallback: Dictionary = tools[0] if tools[0] is Dictionary else {}
	_selected_action_id = String(fallback.get("id", ""))
	_selected_seed_id = String(fallback.get("seed_id", ""))


func _rebuild_tool_buttons() -> void:
	for child in tool_buttons.get_children():
		child.free()
	var tools_variant: Variant = _view_model.get("tools", [])
	var tools: Array = tools_variant if tools_variant is Array else []
	for tool_variant in tools:
		if not (tool_variant is Dictionary):
			continue
		var tool: Dictionary = tool_variant
		var button := Button.new()
		button.custom_minimum_size = Vector2(132.0, 44.0)
		button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		button.toggle_mode = true
		button.button_pressed = _is_selected_tool(tool)
		button.disabled = not bool(tool.get("enabled", true))
		button.text = String(tool.get("label", ""))
		button.pressed.connect(_on_tool_button_pressed.bind(String(tool.get("id", "")), String(tool.get("seed_id", ""))))
		tool_buttons.add_child(button)


func _rebuild_plot_nodes() -> void:
	for child in plot_grid.get_children():
		child.free()
	var columns := maxi(1, int(_view_model.get("columns", 3)))
	plot_grid.columns = columns
	var plots_variant: Variant = _view_model.get("plots", [])
	var plots: Array = plots_variant if plots_variant is Array else []
	for plot_variant in plots:
		if not (plot_variant is Dictionary):
			continue
		var plot = FarmPlotClass.new()
		plot.set_plot_model(plot_variant as Dictionary)
		plot.plot_pressed.connect(_on_plot_pressed)
		plot_grid.add_child(plot)


func _on_tool_button_pressed(action_id: String, seed_id: String) -> void:
	_selected_action_id = action_id
	_selected_seed_id = seed_id
	_apply_view_model()


func _on_plot_pressed(plot_index: int) -> void:
	if _selected_action_id.is_empty():
		return
	plot_action_requested.emit(plot_index, _selected_action_id, _selected_seed_id)


func _is_selected_tool(tool: Dictionary) -> bool:
	return String(tool.get("id", "")) == _selected_action_id and String(tool.get("seed_id", "")) == _selected_seed_id


func _get_selected_tool_label() -> String:
	var tools_variant: Variant = _view_model.get("tools", [])
	var tools: Array = tools_variant if tools_variant is Array else []
	for tool_variant in tools:
		if not (tool_variant is Dictionary):
			continue
		var tool: Dictionary = tool_variant
		if _is_selected_tool(tool):
			return String(tool.get("label", _t("meta.farm.tool_none")))
	return _t("meta.farm.tool_none")


func _on_language_changed(_language_code: String) -> void:
	_apply_view_model()


func _t(key: String, args: Dictionary = {}) -> String:
	if Localization == null or not Localization.has_method("t"):
		return key
	return String(Localization.call("t", key, args))
