extends Panel
class_name RunSetupView

signal run_submitted(run_config: Dictionary)
signal back_requested

const NEON_CARD_SCENE := preload("res://ui/components/NeonCard.tscn")
const NEON_BUTTON_SCRIPT := preload("res://scripts/ui/components/neon_button.gd")
const UIMotionClass := preload("res://scripts/ui/ui_motion.gd")
const PixelStickerRegistry := preload("res://scripts/visual/pixel_sticker_registry.gd")
const CARD_ICON_ANIM_SEC := 0.34

const STEP_CHARACTER := 0
const STEP_MAP := 1
const STEP_CONTRACTS := 2

@onready var backdrop_rect: ColorRect = $Backdrop
@onready var step_character_btn: Button = $Margin/Columns/Stepper/StepCharacter
@onready var step_map_btn: Button = $Margin/Columns/Stepper/StepMap
@onready var step_contracts_btn: Button = $Margin/Columns/Stepper/StepContracts
@onready var step_status_label: Label = $Margin/Columns/Stepper/StepStatus
@onready var stepper_title_label: Label = $Margin/Columns/Stepper/StepperTitle
@onready var stepper_hint_label: Label = $Margin/Columns/Stepper/StepperHint

@onready var content_title: Label = $Margin/Columns/Content/ContentHeader/Title
@onready var content_subtitle: Label = $Margin/Columns/Content/ContentHeader/Subtitle
@onready var cards_scroll: ScrollContainer = $Margin/Columns/Content/CardsScroll
@onready var cards_box: VBoxContainer = $Margin/Columns/Content/CardsScroll/Cards
@onready var nav_back_btn: Button = $Margin/Columns/Content/Nav/BackButton
@onready var nav_next_btn: Button = $Margin/Columns/Content/Nav/NextButton

@onready var selected_character_label: Label = $Margin/Columns/Summary/SummaryBody/BodyMargin/BodyContent/SelectedCharacter
@onready var selected_map_label: Label = $Margin/Columns/Summary/SummaryBody/BodyMargin/BodyContent/SelectedMap
@onready var selected_contracts_label: Label = $Margin/Columns/Summary/SummaryBody/BodyMargin/BodyContent/SelectedContracts
@onready var mult_xp_label: Label = $Margin/Columns/Summary/SummaryBody/BodyMargin/BodyContent/Multipliers/XPValue
@onready var mult_rarity_label: Label = $Margin/Columns/Summary/SummaryBody/BodyMargin/BodyContent/Multipliers/RarityValue
@onready var mult_drop_label: Label = $Margin/Columns/Summary/SummaryBody/BodyMargin/BodyContent/Multipliers/DropValue
@onready var mult_meta_label: Label = $Margin/Columns/Summary/SummaryBody/BodyMargin/BodyContent/Multipliers/MetaValue
@onready var summary_title_label: Label = $Margin/Columns/Summary/SummaryTitle
@onready var mult_title_label: Label = $Margin/Columns/Summary/SummaryBody/BodyMargin/BodyContent/MultTitle
@onready var mult_xp_title_label: Label = $Margin/Columns/Summary/SummaryBody/BodyMargin/BodyContent/Multipliers/XPLabel
@onready var mult_rarity_title_label: Label = $Margin/Columns/Summary/SummaryBody/BodyMargin/BodyContent/Multipliers/RarityLabel
@onready var mult_drop_title_label: Label = $Margin/Columns/Summary/SummaryBody/BodyMargin/BodyContent/Multipliers/DropLabel
@onready var mult_meta_title_label: Label = $Margin/Columns/Summary/SummaryBody/BodyMargin/BodyContent/Multipliers/MetaLabel
@onready var tag_weights_title_label: Label = $Margin/Columns/Summary/SummaryBody/BodyMargin/BodyContent/TagWeights/TagWeightsTitle
@onready var multiplier_badges: HFlowContainer = $Margin/Columns/Summary/SummaryBody/BodyMargin/BodyContent/MultiplierBadges
@onready var tag_weights_box: VBoxContainer = $Margin/Columns/Summary/SummaryBody/BodyMargin/BodyContent/TagWeights/Rows
@onready var start_run_btn: Button = $Margin/Columns/Summary/StartRunButton
@onready var hover_tooltip: PanelContainer = $HoverTooltip

var current_step: int = STEP_CHARACTER

var characters: Array = []
var maps: Array = []
var contracts: Array = []
var unlocked_character_ids: Array[String] = []
var max_contract_select: int = 3

var selected_character_id: String = ""
var selected_map_id: String = ""
var selected_contract_ids: Array[String] = []

var _card_buttons: Array[Button] = []
var _selected_index_by_step: Dictionary = {
	STEP_CHARACTER: 0,
	STEP_MAP: 0,
	STEP_CONTRACTS: 0
}
var _backdrop_material: ShaderMaterial
var _backdrop_time: float = 0.0
var _animated_card_icons: Array[Dictionary] = []
var _card_icon_timer: float = 0.0
var _card_icon_frame_idx: int = 0


func _ready() -> void:
	visible = false
	if backdrop_rect != null and backdrop_rect.material is ShaderMaterial:
		_backdrop_material = backdrop_rect.material
	if Localization != null and Localization.has_signal("language_changed"):
		Localization.language_changed.connect(_on_language_changed)
	_connect_signals()
	_set_step(STEP_CHARACTER)
	_refresh_all()
	visibility_changed.connect(_on_visibility_changed)
	set_process(true)


func _process(delta: float) -> void:
	if not visible:
		return
	if _backdrop_material == null:
		_tick_card_icons(delta)
		return
	_backdrop_time += delta
	_backdrop_material.set_shader_parameter("time_sec", _backdrop_time)
	_tick_card_icons(delta)


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if not (event is InputEventKey):
		return
	if not event.pressed or event.echo:
		return

	match event.keycode:
		KEY_TAB:
			if event.shift_pressed:
				_focus_prev_area()
			else:
				_focus_next_area()
			accept_event()
		KEY_UP:
			if _is_focus_in_cards():
				_move_card_focus(-1)
				accept_event()
		KEY_DOWN:
			if _is_focus_in_cards():
				_move_card_focus(1)
				accept_event()
		KEY_LEFT:
			if _is_focus_in_cards():
				_move_card_focus(-1)
				accept_event()
		KEY_RIGHT:
			if _is_focus_in_cards():
				_move_card_focus(1)
				accept_event()
		KEY_ENTER, KEY_KP_ENTER:
			_activate_focused_control()
			accept_event()
		_:
			pass


func set_character_data(character_rows: Array, unlocked_ids: Array[String], initial_selected_id: String) -> void:
	characters = character_rows.duplicate(true)
	unlocked_character_ids = unlocked_ids.duplicate()
	selected_character_id = initial_selected_id.strip_edges()
	if selected_character_id.is_empty() or not _has_character(selected_character_id) or not unlocked_character_ids.has(selected_character_id):
		selected_character_id = _pick_first_unlocked_character()
	_refresh_all()


func set_map_data(map_rows: Array, initial_selected_id: String) -> void:
	maps = map_rows.duplicate(true)
	selected_map_id = initial_selected_id.strip_edges()
	if selected_map_id.is_empty() or not _has_map(selected_map_id):
		selected_map_id = _pick_first_map()
	_refresh_all()


func set_contract_data(contract_rows: Array, initial_selected_ids: Array[String], max_select_count: int) -> void:
	contracts = contract_rows.duplicate(true)
	max_contract_select = clampi(max_select_count, 0, 3)
	selected_contract_ids = DataRegistry.normalize_contract_selection(initial_selected_ids)
	_refresh_all()


func set_step_by_state(state: String) -> void:
	match state:
		"character_select":
			_set_step(STEP_CHARACTER)
		"map_select":
			_set_step(STEP_MAP)
		"contract_select":
			_set_step(STEP_CONTRACTS)
		_:
			pass


func get_selected_character_id() -> String:
	return selected_character_id


func get_selected_map_id() -> String:
	return selected_map_id


func get_selected_contract_ids() -> Array[String]:
	return selected_contract_ids.duplicate()


func refresh_unlocks(unlocked_ids: Array[String]) -> void:
	unlocked_character_ids = unlocked_ids.duplicate()
	if not selected_character_id.is_empty() and not unlocked_character_ids.has(selected_character_id):
		selected_character_id = _pick_first_unlocked_character()
	_refresh_all()


func debug_select_character(character_id: String) -> void:
	if _select_character(character_id):
		_set_step(STEP_MAP)


func debug_select_map(map_id: String) -> void:
	if _select_map(map_id):
		_set_step(STEP_CONTRACTS)


func debug_toggle_contract(contract_id: String) -> void:
	_toggle_contract(contract_id)


func debug_submit() -> void:
	_submit_run()


func _connect_signals() -> void:
	step_character_btn.pressed.connect(func() -> void:
		_set_step(STEP_CHARACTER)
	)
	step_map_btn.pressed.connect(func() -> void:
		if _can_enter_step(STEP_MAP):
			_set_step(STEP_MAP)
	)
	step_contracts_btn.pressed.connect(func() -> void:
		if _can_enter_step(STEP_CONTRACTS):
			_set_step(STEP_CONTRACTS)
	)

	nav_back_btn.pressed.connect(_on_back_pressed)
	nav_next_btn.pressed.connect(_on_next_pressed)
	start_run_btn.pressed.connect(_submit_run)


func _on_back_pressed() -> void:
	if current_step == STEP_CHARACTER:
		back_requested.emit()
		return
	_set_step(current_step - 1)


func _on_next_pressed() -> void:
	if current_step == STEP_CHARACTER:
		if selected_character_id.is_empty():
			return
		_set_step(STEP_MAP)
		return
	if current_step == STEP_MAP:
		if selected_map_id.is_empty():
			return
		_set_step(STEP_CONTRACTS)
		return


func _set_step(step_value: int) -> void:
	current_step = clampi(step_value, STEP_CHARACTER, STEP_CONTRACTS)
	_refresh_stepper()
	_refresh_content()
	_refresh_nav_buttons()
	if visible:
		UIMotionClass.panel_pop_in(cards_scroll, 0.14, 8.0)


func _refresh_all() -> void:
	_refresh_stepper()
	_refresh_content()
	_refresh_summary()
	_refresh_nav_buttons()


func _refresh_stepper() -> void:
	step_character_btn.text = _build_step_text(_t("run_setup.step.character"), STEP_CHARACTER)
	step_map_btn.text = _build_step_text(_t("run_setup.step.map"), STEP_MAP)
	step_contracts_btn.text = _build_step_text(_t("run_setup.step.contracts"), STEP_CONTRACTS)
	step_status_label.text = _t("run_setup.step.status", {
		"current": current_step + 1,
		"name": _step_name(current_step)
	})
	step_character_btn.disabled = false
	step_map_btn.disabled = not _can_enter_step(STEP_MAP)
	step_contracts_btn.disabled = not _can_enter_step(STEP_CONTRACTS)
	step_character_btn.theme_type_variation = "PrimaryButton" if current_step == STEP_CHARACTER else "SecondaryButton"
	step_map_btn.theme_type_variation = "PrimaryButton" if current_step == STEP_MAP else "SecondaryButton"
	step_contracts_btn.theme_type_variation = "PrimaryButton" if current_step == STEP_CONTRACTS else "SecondaryButton"


func _build_step_text(name: String, step_index: int) -> String:
	var marker := ""
	if _is_step_completed(step_index):
		marker = "[x] "
	elif current_step == step_index:
		marker = "[>] "
	return "%s%s" % [marker, name]


func _refresh_content() -> void:
	for child in cards_box.get_children():
		child.queue_free()
	_card_buttons.clear()
	_animated_card_icons.clear()
	_card_icon_timer = 0.0
	_card_icon_frame_idx = 0

	match current_step:
		STEP_CHARACTER:
			content_title.text = _t("run_setup.content.character.title")
			content_subtitle.text = _t("run_setup.content.character.subtitle")
			_build_character_cards()
		STEP_MAP:
			content_title.text = _t("run_setup.content.map.title")
			content_subtitle.text = _t("run_setup.content.map.subtitle")
			_build_map_cards()
		STEP_CONTRACTS:
			content_title.text = _t("run_setup.content.contract.title")
			content_subtitle.text = _t("run_setup.content.contract.subtitle", {"max": max_contract_select})
			_build_contract_cards()

	await get_tree().process_frame
	if not _card_buttons.is_empty():
		var target_index := clampi(int(_selected_index_by_step.get(current_step, 0)), 0, _card_buttons.size() - 1)
		_card_buttons[target_index].grab_focus()


func _build_character_cards() -> void:
	for index in range(characters.size()):
		var row_variant: Variant = characters[index]
		if not (row_variant is Dictionary):
			continue
		var row: Dictionary = row_variant
		var character_id := String(row.get("id", "")).strip_edges()
		if character_id.is_empty():
			continue
		var display_row := _resolve_character_row(row, character_id)
		var unlocked := unlocked_character_ids.has(character_id)
		var is_selected := character_id == selected_character_id
		var title := String(display_row.get("display_name", character_id))
		var desc := String(display_row.get("short_desc", ""))
		if not unlocked:
			desc = _t("run_setup.locked", {"value": String(display_row.get("unlock", {}).get("display", ""))})
		var action_text := _t("run_setup.action.selected") if is_selected else _t("run_setup.action.select")
		var action_disabled := (not unlocked) or is_selected
		var tooltip_text := _build_character_tooltip(display_row, unlocked)
		var icon_frames := PixelStickerRegistry.get_character_idle_frames(character_id)
		var card_btn := _add_card_item(title, desc, action_text, action_disabled, tooltip_text, icon_frames)
		_card_buttons.append(card_btn)
		card_btn.pressed.connect(_on_character_card_pressed.bind(character_id, index))


func _build_map_cards() -> void:
	for index in range(maps.size()):
		var row_variant: Variant = maps[index]
		if not (row_variant is Dictionary):
			continue
		var row: Dictionary = row_variant
		var map_id := String(row.get("id", "")).strip_edges()
		if map_id.is_empty():
			continue
		var display_row := _resolve_map_row(row, map_id)
		var is_selected := map_id == selected_map_id
		var title := String(display_row.get("name", map_id))
		var desc := "%s\n%s" % [String(display_row.get("description", "")), String(display_row.get("hazard_summary", ""))]
		var action_text := _t("run_setup.action.selected") if is_selected else _t("run_setup.action.select")
		var tooltip_text := _build_map_tooltip(display_row)
		var card_btn := _add_card_item(title, desc, action_text, is_selected, tooltip_text)
		_card_buttons.append(card_btn)
		card_btn.pressed.connect(_on_map_card_pressed.bind(map_id, index))


func _build_contract_cards() -> void:
	for index in range(contracts.size()):
		var row_variant: Variant = contracts[index]
		if not (row_variant is Dictionary):
			continue
		var row: Dictionary = row_variant
		var contract_id := String(row.get("id", "")).strip_edges()
		if contract_id.is_empty():
			continue
		var display_row := _resolve_contract_row(row, contract_id)
		var selected := selected_contract_ids.has(contract_id)
		var title := "%s (+%.0f%%)" % [String(display_row.get("name", contract_id)), float(display_row.get("reward_pct", 0.0))]
		var desc := String(display_row.get("description", ""))
		var impact_line := _format_contract_impact_line(display_row)
		if not impact_line.is_empty():
			desc = impact_line if desc.is_empty() else "%s\n%s" % [desc, impact_line]
		var action_text := _t("run_setup.action.remove") if selected else _t("run_setup.action.add")
		var disabled := false
		if not selected:
			disabled = _is_contract_locked(contract_id)
		var tooltip_text := _build_contract_tooltip(display_row, selected)
		var card_btn := _add_card_item(title, desc, action_text, false if selected else disabled, tooltip_text)
		_card_buttons.append(card_btn)
		card_btn.pressed.connect(_on_contract_card_pressed.bind(contract_id, index))


func _add_card_item(
	title: String,
	desc: String,
	button_text: String,
	disabled: bool,
	tooltip_text: String = "",
	icon_frames: Array[Texture2D] = []
) -> Button:
	var card: PanelContainer = NEON_CARD_SCENE.instantiate()
	card.custom_minimum_size = Vector2(0.0, 148.0)
	cards_box.add_child(card)

	var content := card.get_node_or_null("Margin/Content") as VBoxContainer
	if content != null and not icon_frames.is_empty():
		var icon_row := HBoxContainer.new()
		icon_row.alignment = BoxContainer.ALIGNMENT_CENTER
		icon_row.custom_minimum_size = Vector2(0.0, 54.0)
		var icon_rect := TextureRect.new()
		icon_rect.custom_minimum_size = Vector2(44.0, 44.0)
		icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon_rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		icon_rect.texture = icon_frames[0]
		icon_row.add_child(icon_rect)
		content.add_child(icon_row)
		content.move_child(icon_row, 0)
		_register_card_icon(icon_rect, icon_frames)

	var title_label := card.get_node_or_null("Margin/Content/Title") as Label
	var body_label := card.get_node_or_null("Margin/Content/Body") as Label
	if title_label != null:
		title_label.text = title
	if body_label != null:
		body_label.text = desc
		body_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

	var button := NEON_BUTTON_SCRIPT.new()
	button.text = button_text
	button.custom_minimum_size = Vector2(0.0, 38.0)
	button.disabled = disabled
	button.set("use_primary_style", true)
	button.set("enable_motion", true)
	if content != null:
		content.add_child(button)
	if not tooltip_text.strip_edges().is_empty():
		card.mouse_entered.connect(_show_card_tooltip.bind(card, tooltip_text))
		card.mouse_exited.connect(_hide_card_tooltip)
		button.mouse_entered.connect(_show_card_tooltip.bind(card, tooltip_text))
		button.mouse_exited.connect(_hide_card_tooltip)
	return button


func _register_card_icon(icon_node: TextureRect, frames: Array[Texture2D]) -> void:
	if icon_node == null or frames.is_empty():
		return
	_animated_card_icons.append({
		"node": icon_node,
		"frames": frames
	})


func _tick_card_icons(delta: float) -> void:
	if _animated_card_icons.is_empty():
		return
	_card_icon_timer += delta
	if _card_icon_timer < CARD_ICON_ANIM_SEC:
		return
	_card_icon_timer = 0.0
	_card_icon_frame_idx += 1
	for row_variant in _animated_card_icons:
		if not (row_variant is Dictionary):
			continue
		var row: Dictionary = row_variant
		var node: Variant = row.get("node", null)
		var frames_variant: Variant = row.get("frames", [])
		if not (node is TextureRect):
			continue
		if not (frames_variant is Array):
			continue
		var frames: Array = frames_variant
		if frames.is_empty():
			continue
		var frame_index := _card_icon_frame_idx % frames.size()
		var frame_variant: Variant = frames[frame_index]
		if frame_variant is Texture2D:
			(node as TextureRect).texture = frame_variant


func _on_character_card_pressed(character_id: String, index: int) -> void:
	if _select_character(character_id):
		_selected_index_by_step[STEP_CHARACTER] = index


func _on_map_card_pressed(map_id: String, index: int) -> void:
	if _select_map(map_id):
		_selected_index_by_step[STEP_MAP] = index


func _on_contract_card_pressed(contract_id: String, index: int) -> void:
	_toggle_contract(contract_id)
	_selected_index_by_step[STEP_CONTRACTS] = index


func _select_character(character_id: String) -> bool:
	if character_id.is_empty() or not _has_character(character_id):
		return false
	if not unlocked_character_ids.has(character_id):
		return false
	selected_character_id = character_id
	_refresh_summary()
	_refresh_content()
	_refresh_nav_buttons()
	return true


func _select_map(map_id: String) -> bool:
	if map_id.is_empty() or not _has_map(map_id):
		return false
	selected_map_id = map_id
	_refresh_summary()
	_refresh_content()
	_refresh_nav_buttons()
	return true


func _toggle_contract(contract_id: String) -> void:
	if contract_id.is_empty() or not _has_contract(contract_id):
		return
	if selected_contract_ids.has(contract_id):
		selected_contract_ids.erase(contract_id)
	else:
		if _is_contract_locked(contract_id):
			return
		selected_contract_ids.append(contract_id)
	selected_contract_ids = DataRegistry.normalize_contract_selection(selected_contract_ids)
	_refresh_summary()
	_refresh_content()
	_refresh_nav_buttons()


func _is_contract_locked(contract_id: String) -> bool:
	if contract_id.is_empty():
		return true
	if max_contract_select > 0 and selected_contract_ids.size() >= max_contract_select:
		return true
	var contract := DataRegistry.get_contract(contract_id)
	if contract.is_empty():
		return true
	var group := String(contract.get("exclusive_group", "")).strip_edges()
	if group.is_empty():
		return false
	for selected_id in selected_contract_ids:
		if selected_id == contract_id:
			continue
		var selected_contract := DataRegistry.get_contract(selected_id)
		if String(selected_contract.get("exclusive_group", "")).strip_edges() == group:
			return true
	return false


func _refresh_summary() -> void:
	selected_character_label.text = _t("run_setup.summary.character", {"value": _resolve_character_name(selected_character_id)})
	selected_map_label.text = _t("run_setup.summary.map", {"value": _resolve_map_name(selected_map_id)})
	selected_contracts_label.text = _t("run_setup.summary.contracts", {"value": _resolve_contract_names(selected_contract_ids)})

	var preview := DataRegistry.get_contract_reward_preview(selected_contract_ids)
	mult_xp_label.text = _format_multiplier_display(float(preview.get("xp_mult", 1.0)))
	mult_rarity_label.text = _format_multiplier_display(float(preview.get("rarity_mult", 1.0)))
	mult_drop_label.text = _format_multiplier_display(float(preview.get("drop_mult", 1.0)))
	mult_meta_label.text = _format_multiplier_display(float(preview.get("meta_currency_mult", 1.0)))
	_refresh_multiplier_badges(preview)

	_refresh_tag_weight_rows(selected_character_id)


func _refresh_tag_weight_rows(character_id: String) -> void:
	for child in tag_weights_box.get_children():
		child.queue_free()
	if character_id.is_empty():
		return
	var character := DataRegistry.get_character(character_id)
	var weights_variant: Variant = character.get("tag_weights", {})
	if not (weights_variant is Dictionary):
		return
	var weights: Dictionary = weights_variant
	if weights.is_empty():
		return

	var pairs: Array = []
	for key_variant in weights.keys():
		var key := String(key_variant)
		pairs.append({"tag": key, "value": float(weights.get(key_variant, 0.0))})
	pairs.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return float(a.get("value", 0.0)) > float(b.get("value", 0.0))
	)
	var top_count := mini(5, pairs.size())
	var max_value := 0.0
	for i in range(top_count):
		max_value = maxf(max_value, float((pairs[i] as Dictionary).get("value", 0.0)))
	if max_value <= 0.0:
		max_value = 1.0
	for i in range(top_count):
		var pair: Dictionary = pairs[i]
		var row := HBoxContainer.new()
		row.custom_minimum_size = Vector2(0.0, 24.0)
		row.add_theme_constant_override("separation", 8)

		var tag_label := Label.new()
		tag_label.custom_minimum_size = Vector2(86, 0)
		tag_label.theme_type_variation = &"BodyMutedLabel"
		tag_label.text = _tag_name(String(pair.get("tag", "")))
		row.add_child(tag_label)

		var bar_bg := ColorRect.new()
		bar_bg.custom_minimum_size = Vector2(120, 10)
		bar_bg.color = Color(0.10, 0.18, 0.26, 0.9)
		row.add_child(bar_bg)

		var bar_fill := ColorRect.new()
		bar_fill.anchor_right = clampf(float(pair.get("value", 0.0)) / max_value, 0.0, 1.0)
		bar_fill.anchor_bottom = 1.0
		bar_fill.grow_horizontal = Control.GROW_DIRECTION_END
		bar_fill.grow_vertical = Control.GROW_DIRECTION_BOTH
		bar_fill.color = Color(0.36, 0.86, 1.0, 0.95)
		bar_bg.add_child(bar_fill)

		var value_label := Label.new()
		value_label.custom_minimum_size = Vector2(46, 0)
		value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		value_label.text = "%.2f" % float(pair.get("value", 0.0))
		row.add_child(value_label)

		tag_weights_box.add_child(row)


func _refresh_nav_buttons() -> void:
	stepper_title_label.text = _t("run_setup.title")
	stepper_hint_label.text = _t("run_setup.hint")
	summary_title_label.text = _t("run_setup.summary_title")
	mult_title_label.text = _t("run_setup.mult_title")
	mult_xp_title_label.text = _t("run_setup.mult.xp")
	mult_rarity_title_label.text = _t("run_setup.mult.rarity")
	mult_drop_title_label.text = _t("run_setup.mult.drop")
	mult_meta_title_label.text = _t("run_setup.mult.meta")
	tag_weights_title_label.text = _t("run_setup.tag_weights_title")
	nav_back_btn.text = _t("run_setup.nav.back")
	nav_next_btn.text = _t("run_setup.nav.next")
	nav_next_btn.visible = current_step != STEP_CONTRACTS
	nav_next_btn.disabled = (current_step == STEP_CHARACTER and selected_character_id.is_empty()) or (current_step == STEP_MAP and selected_map_id.is_empty())
	start_run_btn.text = _t("run_setup.start")
	start_run_btn.disabled = selected_character_id.is_empty() or selected_map_id.is_empty()


func _submit_run() -> void:
	if selected_character_id.is_empty() or selected_map_id.is_empty():
		return
	selected_contract_ids = DataRegistry.normalize_contract_selection(selected_contract_ids)
	var preview := DataRegistry.get_contract_reward_preview(selected_contract_ids)
	var run_config := {
		"character_id": selected_character_id,
		"map_id": selected_map_id,
		"contract_ids": selected_contract_ids.duplicate(),
		"multipliers": {
			"xp": float(preview.get("xp_mult", 1.0)),
			"rarity": float(preview.get("rarity_mult", 1.0)),
			"drop": float(preview.get("drop_mult", 1.0)),
			"meta_currency": float(preview.get("meta_currency_mult", 1.0))
		}
	}
	run_submitted.emit(run_config)


func _focus_next_area() -> void:
	match _get_focus_area():
		"stepper":
			_focus_cards_or_start()
		"cards":
			_focus_nav_or_start()
		"nav":
			start_run_btn.grab_focus()
		"start":
			step_character_btn.grab_focus()
		_:
			step_character_btn.grab_focus()


func _focus_prev_area() -> void:
	match _get_focus_area():
		"stepper":
			start_run_btn.grab_focus()
		"cards":
			step_character_btn.grab_focus()
		"nav":
			_focus_cards_or_start()
		"start":
			_focus_nav_or_cards()
		_:
			start_run_btn.grab_focus()


func _move_card_focus(delta: int) -> void:
	if _card_buttons.is_empty():
		return
	var focus_idx := -1
	for i in range(_card_buttons.size()):
		if _card_buttons[i].has_focus():
			focus_idx = i
			break
	if focus_idx < 0:
		focus_idx = clampi(int(_selected_index_by_step.get(current_step, 0)), 0, _card_buttons.size() - 1)
	focus_idx = wrapi(focus_idx + delta, 0, _card_buttons.size())
	_card_buttons[focus_idx].grab_focus()
	_selected_index_by_step[current_step] = focus_idx


func _activate_focused_control() -> void:
	var focus_owner := get_viewport().gui_get_focus_owner()
	if focus_owner is Button:
		(focus_owner as Button).pressed.emit()


func _get_focus_area() -> String:
	var focus_owner := get_viewport().gui_get_focus_owner()
	if focus_owner == null:
		return "none"
	if focus_owner == step_character_btn or focus_owner == step_map_btn or focus_owner == step_contracts_btn:
		return "stepper"
	if focus_owner == nav_back_btn or focus_owner == nav_next_btn:
		return "nav"
	if focus_owner == start_run_btn:
		return "start"
	for button in _card_buttons:
		if focus_owner == button:
			return "cards"
	return "none"


func _focus_cards_or_start() -> void:
	if not _card_buttons.is_empty():
		var idx := clampi(int(_selected_index_by_step.get(current_step, 0)), 0, _card_buttons.size() - 1)
		_card_buttons[idx].grab_focus()
	else:
		start_run_btn.grab_focus()


func _focus_nav_or_start() -> void:
	if _is_nav_focus_available():
		if nav_next_btn.visible and not nav_next_btn.disabled:
			nav_next_btn.grab_focus()
		else:
			nav_back_btn.grab_focus()
		return
	start_run_btn.grab_focus()


func _focus_nav_or_cards() -> void:
	if _is_nav_focus_available():
		if nav_next_btn.visible and not nav_next_btn.disabled:
			nav_next_btn.grab_focus()
		else:
			nav_back_btn.grab_focus()
		return
	_focus_cards_or_start()


func _is_nav_focus_available() -> bool:
	if nav_back_btn.visible and not nav_back_btn.disabled:
		return true
	if nav_next_btn.visible and not nav_next_btn.disabled:
		return true
	return false


func _is_focus_in_cards() -> bool:
	return _get_focus_area() == "cards"


func _is_step_completed(step_index: int) -> bool:
	match step_index:
		STEP_CHARACTER:
			return not selected_character_id.is_empty()
		STEP_MAP:
			return not selected_map_id.is_empty()
		STEP_CONTRACTS:
			return true
		_:
			return false


func _can_enter_step(step_index: int) -> bool:
	if step_index == STEP_CHARACTER:
		return true
	if step_index == STEP_MAP:
		return not selected_character_id.is_empty()
	if step_index == STEP_CONTRACTS:
		return not selected_character_id.is_empty() and not selected_map_id.is_empty()
	return false


func _has_character(character_id: String) -> bool:
	for row_variant in characters:
		if row_variant is Dictionary and String((row_variant as Dictionary).get("id", "")).strip_edges() == character_id:
			return true
	return false


func _has_map(map_id: String) -> bool:
	for row_variant in maps:
		if row_variant is Dictionary and String((row_variant as Dictionary).get("id", "")).strip_edges() == map_id:
			return true
	return false


func _has_contract(contract_id: String) -> bool:
	for row_variant in contracts:
		if row_variant is Dictionary and String((row_variant as Dictionary).get("id", "")).strip_edges() == contract_id:
			return true
	return false


func _resolve_character_row(row: Dictionary, character_id: String) -> Dictionary:
	var localized := DataRegistry.get_character(character_id)
	return localized if not localized.is_empty() else row


func _resolve_map_row(row: Dictionary, map_id: String) -> Dictionary:
	var localized := DataRegistry.get_map(map_id)
	return localized if not localized.is_empty() else row


func _resolve_contract_row(row: Dictionary, contract_id: String) -> Dictionary:
	var localized := DataRegistry.get_contract(contract_id)
	return localized if not localized.is_empty() else row


func _pick_first_unlocked_character() -> String:
	for row_variant in characters:
		if not (row_variant is Dictionary):
			continue
		var row: Dictionary = row_variant
		var character_id := String(row.get("id", "")).strip_edges()
		if not character_id.is_empty() and unlocked_character_ids.has(character_id):
			return character_id
	return ""


func _pick_first_map() -> String:
	for row_variant in maps:
		if not (row_variant is Dictionary):
			continue
		var row: Dictionary = row_variant
		var map_id := String(row.get("id", "")).strip_edges()
		if not map_id.is_empty():
			return map_id
	return ""


func _resolve_character_name(character_id: String) -> String:
	if character_id.is_empty():
		return "--"
	return String(DataRegistry.get_character(character_id).get("display_name", character_id))


func _resolve_map_name(map_id: String) -> String:
	if map_id.is_empty():
		return "--"
	return String(DataRegistry.get_map(map_id).get("name", map_id))


func _resolve_contract_names(contract_ids: Array[String]) -> String:
	if contract_ids.is_empty():
		return _t("run_setup.none")
	var names: Array[String] = []
	for contract_id in contract_ids:
		names.append(String(DataRegistry.get_contract(contract_id).get("name", contract_id)))
	return ", ".join(names)


func _format_multiplier_display(value: float) -> String:
	var delta_pct := (value - 1.0) * 100.0
	if absf(delta_pct) < 0.05:
		return "x%.2f" % value
	return "x%.2f (%+d%%)" % [value, int(round(delta_pct))]


func _format_contract_impact_line(contract: Dictionary) -> String:
	var rewards_variant: Variant = contract.get("rewards", {})
	if not (rewards_variant is Dictionary):
		return ""
	var rewards: Dictionary = rewards_variant
	var parts: Array[String] = []
	var xp_mult := float(rewards.get("xp_mult", 1.0))
	var rarity_mult := float(rewards.get("rarity_mult", 1.0))
	var drop_mult := float(rewards.get("drop_mult", 1.0))
	var meta_mult := float(rewards.get("meta_currency_mult", 1.0))
	if not is_equal_approx(xp_mult, 1.0):
		parts.append("%s %s" % [_t("run_setup.mult.xp"), _format_multiplier_display(xp_mult)])
	if not is_equal_approx(rarity_mult, 1.0):
		parts.append("%s %s" % [_t("run_setup.mult.rarity"), _format_multiplier_display(rarity_mult)])
	if not is_equal_approx(drop_mult, 1.0):
		parts.append("%s %s" % [_t("run_setup.mult.drop"), _format_multiplier_display(drop_mult)])
	if not is_equal_approx(meta_mult, 1.0):
		parts.append("%s %s" % [_t("run_setup.mult.meta"), _format_multiplier_display(meta_mult)])
	if parts.is_empty():
		return ""
	return _t("run_setup.affects", {"value": ", ".join(parts)})


func _refresh_multiplier_badges(preview: Dictionary) -> void:
	if multiplier_badges == null:
		return
	for child in multiplier_badges.get_children():
		child.queue_free()
	_append_multiplier_badge(_t("run_setup.mult.xp"), float(preview.get("xp_mult", 1.0)))
	_append_multiplier_badge(_t("run_setup.mult.rarity"), float(preview.get("rarity_mult", 1.0)))
	_append_multiplier_badge(_t("run_setup.mult.drop"), float(preview.get("drop_mult", 1.0)))
	_append_multiplier_badge(_t("run_setup.mult.meta"), float(preview.get("meta_currency_mult", 1.0)))


func _append_multiplier_badge(label: String, value: float) -> void:
	var badge := PanelContainer.new()
	badge.theme_type_variation = &"BadgePanel"
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 8)
	margin.add_theme_constant_override("margin_right", 8)
	margin.add_theme_constant_override("margin_top", 4)
	margin.add_theme_constant_override("margin_bottom", 4)
	var text := Label.new()
	text.theme_type_variation = &"BodyMutedLabel"
	text.text = "%s %s" % [label, _format_multiplier_display(value)]
	if value > 1.0001:
		text.modulate = Color(0.66, 0.96, 1.0, 1.0)
	elif value < 0.9999:
		text.modulate = Color(1.0, 0.78, 0.78, 1.0)
	margin.add_child(text)
	badge.add_child(margin)
	multiplier_badges.add_child(badge)


func _build_character_tooltip(character: Dictionary, unlocked: bool) -> String:
	var name := String(character.get("display_name", character.get("id", "Character")))
	var desc := String(character.get("short_desc", "")).strip_edges()
	var details: Array[String] = []
	var modifiers_variant: Variant = character.get("stat_modifiers", {})
	if modifiers_variant is Dictionary:
		var modifiers: Dictionary = modifiers_variant
		if modifiers.has("move_speed_multiplier"):
			details.append("%s x%.2f" % [_t("run_setup.stat.move"), float(modifiers.get("move_speed_multiplier", 1.0))])
		if modifiers.has("noise_gain_multiplier"):
			details.append("%s x%.2f" % [_t("run_setup.stat.noise"), float(modifiers.get("noise_gain_multiplier", 1.0))])
		if modifiers.has("damage_multiplier"):
			details.append("%s x%.2f" % [_t("run_setup.stat.damage"), float(modifiers.get("damage_multiplier", 1.0))])
	var unlock_line := ""
	if not unlocked:
		unlock_line = _t("run_setup.tooltip.unlock", {"value": String(character.get("unlock", {}).get("display", _t("run_setup.unknown_requirement")))})
	var lines: Array[String] = ["%s" % name]
	if not desc.is_empty():
		lines.append(desc)
	if not details.is_empty():
		lines.append(_t("run_setup.tooltip.stats", {"value": ", ".join(details)}))
	if not unlock_line.is_empty():
		lines.append(unlock_line)
	return "\n".join(lines)


func _build_map_tooltip(map_row: Dictionary) -> String:
	var name := String(map_row.get("name", map_row.get("id", "Map")))
	var desc := String(map_row.get("description", "")).strip_edges()
	var hazard := String(map_row.get("hazard_summary", "")).strip_edges()
	var lines: Array[String] = [name]
	if not desc.is_empty():
		lines.append(desc)
	if not hazard.is_empty():
		lines.append(_t("run_setup.tooltip.hazard", {"value": hazard}))
	return "\n".join(lines)


func _build_contract_tooltip(contract: Dictionary, selected: bool) -> String:
	var name := String(contract.get("name", contract.get("id", "Contract")))
	var desc := String(contract.get("description", "")).strip_edges()
	var impact := _format_contract_impact_line(contract)
	var lines: Array[String] = [name]
	if not desc.is_empty():
		lines.append(desc)
	if not impact.is_empty():
		lines.append(impact)
	lines.append(_t("run_setup.tooltip.status", {
		"value": _t("run_setup.tooltip.status_selected") if selected else _t("run_setup.tooltip.status_optional")
	}))
	return "\n".join(lines)


func _show_card_tooltip(card: Control, text: String) -> void:
	if hover_tooltip == null or not hover_tooltip.has_method("show_tooltip"):
		return
	var global_pos := card.get_global_position()
	hover_tooltip.global_position = Vector2(global_pos.x + card.size.x + 12.0, global_pos.y + 6.0)
	hover_tooltip.call("show_tooltip", text, 0.0)


func _hide_card_tooltip() -> void:
	if hover_tooltip != null and hover_tooltip.has_method("hide_tooltip"):
		hover_tooltip.call("hide_tooltip")


func _step_name(step_index: int) -> String:
	match step_index:
		STEP_CHARACTER:
			return _t("run_setup.step.character")
		STEP_MAP:
			return _t("run_setup.step.map")
		STEP_CONTRACTS:
			return _t("run_setup.step.contracts")
		_:
			return _t("run_setup.step.character")


func _on_visibility_changed() -> void:
	if not visible:
		_hide_card_tooltip()
		return
	UIMotionClass.panel_pop_in(self, 0.16, 10.0)


func _on_language_changed(_language_code: String) -> void:
	_refresh_all()


func _t(key: String, args: Dictionary = {}) -> String:
	if Localization == null or not Localization.has_method("t"):
		return key
	return String(Localization.call("t", key, args))


func _tag_name(tag: String) -> String:
	if Localization == null or not Localization.has_method("tag_name"):
		return tag
	return String(Localization.call("tag_name", tag))
