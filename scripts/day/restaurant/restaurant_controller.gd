extends Control
class_name RestaurantController

signal back_requested
signal recipe_toggled(recipe_id: String)
signal clear_menu_requested
signal service_requested

@onready var content_vbox: VBoxContainer = $ContentPanel/Margin/VBox
@onready var panels_row: HBoxContainer = $ContentPanel/Margin/VBox/Panels
@onready var ingredients_panel: Panel = $ContentPanel/Margin/VBox/Panels/IngredientsPanel
@onready var recipes_panel: Panel = $ContentPanel/Margin/VBox/Panels/RecipesPanel
@onready var menu_panel: Panel = $ContentPanel/Margin/VBox/Panels/MenuPanel
@onready var title_label: Label = $ContentPanel/Margin/VBox/Title
@onready var subtitle_label: Label = $ContentPanel/Margin/VBox/Subtitle
@onready var stats_label: Label = $ContentPanel/Margin/VBox/StatsLabel
@onready var bridge_label: Label = $ContentPanel/Margin/VBox/BridgeLabel
@onready var ingredients_title_label: Label = $ContentPanel/Margin/VBox/Panels/IngredientsPanel/Margin/VBox/Title
@onready var pantry_label: Label = $ContentPanel/Margin/VBox/Panels/IngredientsPanel/Margin/VBox/Value
@onready var recipes_title_label: Label = $ContentPanel/Margin/VBox/Panels/RecipesPanel/Margin/VBox/Title
@onready var recipes_scroll: ScrollContainer = $ContentPanel/Margin/VBox/Panels/RecipesPanel/Margin/VBox/Scroll
@onready var recipes_list: VBoxContainer = $ContentPanel/Margin/VBox/Panels/RecipesPanel/Margin/VBox/Scroll/RecipesList
@onready var menu_title_label: Label = $ContentPanel/Margin/VBox/Panels/MenuPanel/Margin/VBox/Title
@onready var menu_scroll: ScrollContainer = $ContentPanel/Margin/VBox/Panels/MenuPanel/Margin/VBox/Scroll
@onready var menu_list: VBoxContainer = $ContentPanel/Margin/VBox/Panels/MenuPanel/Margin/VBox/Scroll/MenuList
@onready var menu_hint_label: Label = $ContentPanel/Margin/VBox/Panels/MenuPanel/Margin/VBox/MenuHint
@onready var status_label: Label = $ContentPanel/Margin/VBox/StatusLabel
@onready var actions_row: HBoxContainer = $ContentPanel/Margin/VBox/Actions
@onready var service_button: Button = $ContentPanel/Margin/VBox/Actions/ServiceButton
@onready var clear_button: Button = $ContentPanel/Margin/VBox/Actions/ClearButton
@onready var back_button: Button = $ContentPanel/Margin/VBox/Actions/BackButton
@onready var result_panel: Panel = $ContentPanel/Margin/VBox/ResultPanel
@onready var result_title_label: Label = $ContentPanel/Margin/VBox/ResultPanel/Margin/VBox/Title
@onready var result_summary_label: Label = $ContentPanel/Margin/VBox/ResultPanel/Margin/VBox/Summary
@onready var result_feedback_label: Label = $ContentPanel/Margin/VBox/ResultPanel/Margin/VBox/Feedback
@onready var sold_stats_label: Label = $ContentPanel/Margin/VBox/ResultPanel/Margin/VBox/SoldStats

var _view_model: Dictionary = {}


func _ready() -> void:
	visible = false
	service_button.pressed.connect(func() -> void:
		service_requested.emit()
	)
	clear_button.pressed.connect(func() -> void:
		clear_menu_requested.emit()
	)
	back_button.pressed.connect(func() -> void:
		back_requested.emit()
	)
	if Localization != null and Localization.has_signal("language_changed"):
		Localization.language_changed.connect(_on_language_changed)
	resized.connect(_sync_layout)
	content_vbox.resized.connect(_sync_layout)
	recipes_scroll.resized.connect(_sync_scroll_content_widths)
	menu_scroll.resized.connect(_sync_scroll_content_widths)
	_apply_view_model()
	_sync_layout.call_deferred()
	_sync_scroll_content_widths.call_deferred()


func set_view_model(model: Dictionary) -> void:
	_view_model = model.duplicate(true)
	_apply_view_model()


func _apply_view_model() -> void:
	title_label.text = _t("meta.restaurant.title")
	subtitle_label.text = _t("meta.restaurant.subtitle")
	ingredients_title_label.text = _t("meta.restaurant.ingredients_title")
	recipes_title_label.text = _t("meta.restaurant.recipes_title")
	menu_title_label.text = _t("meta.restaurant.menu_title")
	stats_label.text = _t("meta.restaurant.stats", {
		"day": int(_view_model.get("current_day", 1)),
		"phase": _t("meta.phase.%s" % String(_view_model.get("phase", "morning"))),
		"gold": int(_view_model.get("gold", 0)),
		"reputation": int(_view_model.get("reputation", 0)),
		"actions": int(_view_model.get("action_budget", 0)),
		"action_max": int(_view_model.get("max_action_budget", 0))
	})
	bridge_label.text = _t("meta.restaurant.bridge", {"value": String(_view_model.get("bridge_summary", _t("meta.bridge.summary_none")))})
	bridge_label.tooltip_text = String(_view_model.get("bridge_tooltip", ""))
	pantry_label.text = String(_view_model.get("ingredient_summary", _t("meta.common.none")))
	pantry_label.tooltip_text = String(_view_model.get("ingredient_tooltip", ""))
	status_label.text = String(_view_model.get("status_text", ""))
	service_button.text = String(_view_model.get("service_button_text", _t("meta.restaurant.open_service")))
	service_button.tooltip_text = String(_view_model.get("service_button_tooltip", ""))
	service_button.disabled = not bool(_view_model.get("service_button_enabled", false))
	clear_button.text = _t("meta.restaurant.clear_menu")
	clear_button.disabled = not bool(_view_model.get("clear_button_enabled", false))
	back_button.text = _t("meta.common.back")
	menu_hint_label.text = String(_view_model.get("menu_hint_text", ""))
	menu_hint_label.tooltip_text = String(_view_model.get("menu_hint_tooltip", ""))
	result_title_label.text = String(_view_model.get("result_title", _t("meta.restaurant.summary_idle_title")))
	result_summary_label.text = String(_view_model.get("result_summary", _t("meta.restaurant.summary_idle")))
	result_feedback_label.text = String(_view_model.get("result_feedback", _t("meta.common.none")))
	sold_stats_label.text = String(_view_model.get("sold_stats_text", ""))
	_rebuild_recipe_buttons()
	_rebuild_selected_menu()
	_sync_layout.call_deferred()
	_sync_scroll_content_widths.call_deferred()


func _rebuild_recipe_buttons() -> void:
	for child in recipes_list.get_children():
		child.free()
	var recipe_cards_variant: Variant = _view_model.get("recipe_cards", [])
	var recipe_cards: Array = recipe_cards_variant if recipe_cards_variant is Array else []
	for recipe_variant in recipe_cards:
		if not (recipe_variant is Dictionary):
			continue
		var recipe: Dictionary = recipe_variant
		var button := Button.new()
		button.custom_minimum_size = Vector2(0.0, 112.0)
		button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.toggle_mode = true
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.button_pressed = bool(recipe.get("selected", false))
		button.disabled = not bool(recipe.get("enabled", false))
		button.theme_type_variation = &"SecondaryButton"
		button.text = String(recipe.get("label", ""))
		button.tooltip_text = String(recipe.get("tooltip", ""))
		button.pressed.connect(_on_recipe_button_pressed.bind(String(recipe.get("id", ""))))
		recipes_list.add_child(button)
	_sync_scroll_content_widths.call_deferred()


func _rebuild_selected_menu() -> void:
	for child in menu_list.get_children():
		child.free()
	var selected_menu_variant: Variant = _view_model.get("selected_menu_entries", [])
	var selected_menu_entries: Array = selected_menu_variant if selected_menu_variant is Array else []
	if selected_menu_entries.is_empty():
		var empty_label := Label.new()
		empty_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		empty_label.text = _t("meta.restaurant.menu_empty")
		menu_list.add_child(empty_label)
		return
	for entry_variant in selected_menu_entries:
		if not (entry_variant is Dictionary):
			continue
		var entry_label := Label.new()
		entry_label.custom_minimum_size = Vector2(0.0, 60.0)
		entry_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		entry_label.max_lines_visible = 2
		entry_label.clip_text = true
		entry_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		entry_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		entry_label.text = String((entry_variant as Dictionary).get("label", ""))
		menu_list.add_child(entry_label)
	_sync_scroll_content_widths.call_deferred()


func _sync_scroll_content_widths() -> void:
	_sync_scroll_content_width(recipes_scroll, recipes_list)
	_sync_scroll_content_width(menu_scroll, menu_list)


func _sync_layout() -> void:
	var content_width := maxf(0.0, content_vbox.size.x)
	if content_width <= 0.0:
		return
	panels_row.custom_minimum_size = Vector2(content_width, maxf(320.0, panels_row.custom_minimum_size.y))
	actions_row.custom_minimum_size = Vector2(content_width, maxf(56.0, actions_row.custom_minimum_size.y))
	result_panel.custom_minimum_size = Vector2(content_width, maxf(190.0, result_panel.custom_minimum_size.y))
	var available_width := maxf(0.0, content_width - 28.0)
	var ingredients_width := maxf(260.0, floor(available_width * 0.24))
	var recipes_width := maxf(360.0, floor(available_width * 0.38))
	var menu_width := maxf(300.0, floor(available_width * 0.30))
	ingredients_panel.custom_minimum_size = Vector2(ingredients_width, 320.0)
	recipes_panel.custom_minimum_size = Vector2(recipes_width, 320.0)
	menu_panel.custom_minimum_size = Vector2(menu_width, 320.0)
	pantry_label.custom_minimum_size = Vector2(maxf(0.0, ingredients_width - 28.0), pantry_label.custom_minimum_size.y)
	recipes_scroll.custom_minimum_size = Vector2(maxf(0.0, recipes_width - 28.0), maxf(280.0, recipes_scroll.custom_minimum_size.y))
	menu_scroll.custom_minimum_size = Vector2(maxf(0.0, menu_width - 28.0), maxf(280.0, menu_scroll.custom_minimum_size.y))
	_sync_scroll_content_widths()


func _sync_scroll_content_width(scroll: ScrollContainer, container: VBoxContainer) -> void:
	var target_width := maxf(0.0, scroll.size.x - 8.0)
	container.custom_minimum_size = Vector2(target_width, container.custom_minimum_size.y)
	for child in container.get_children():
		if child is Control:
			var child_control := child as Control
			child_control.custom_minimum_size = Vector2(target_width, child_control.custom_minimum_size.y)
			var target_height := child_control.custom_minimum_size.y
			if target_height <= 0.0:
				target_height = child_control.get_combined_minimum_size().y
			child_control.size = Vector2(target_width, target_height)


func _on_recipe_button_pressed(recipe_id: String) -> void:
	var normalized_id := recipe_id.strip_edges()
	if normalized_id.is_empty():
		return
	recipe_toggled.emit(normalized_id)


func _on_language_changed(_language_code: String) -> void:
	_apply_view_model()


func _t(key: String, args: Dictionary = {}) -> String:
	if Localization == null or not Localization.has_method("t"):
		return key
	return String(Localization.call("t", key, args))
