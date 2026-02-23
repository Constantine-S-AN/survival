extends Panel
class_name UpgradeSelectView

signal upgrade_selected(upgrade_id: String)
signal cancel_requested

const UPGRADE_CARD_SCENE := preload("res://ui/components/UpgradeCard.tscn")
const UIMotionClass := preload("res://scripts/ui/ui_motion.gd")

const TAG_DISPLAY_NAMES: Dictionary = {
	"sonar": "Sonar",
	"silence": "Silence",
	"heat": "Heat",
	"crit": "Crit",
	"pierce": "Pierce",
	"chain": "Chain",
	"aoe": "AOE",
	"pickup": "Pickup",
	"shield": "Shield",
	"speed": "Speed",
	"trap": "Trap",
	"control": "Control",
	"summon": "Summon",
	"economy": "Economy",
	"damage": "Damage",
	"weapon": "Weapon",
	"tempo": "Tempo",
	"noise": "Noise",
	"mobility": "Mobility",
	"defense": "Defense",
	"hull": "Hull"
}

@export var allow_cancel: bool = false

@onready var backdrop_rect: ColorRect = $Backdrop
@onready var subtitle_label: Label = $Margin/Columns/Main/Subtitle
@onready var cards_row: HBoxContainer = $Margin/Columns/Main/CardsRow
@onready var input_hint_label: Label = $Margin/Columns/Main/InputHint
@onready var build_panel: PanelContainer = $Margin/Columns/BuildPanel

var _cards: Array[Node] = []
var _current_options: Array = []
var _focused_index: int = 0
var _latest_hud_data: Dictionary = {}
var _run_multipliers: Dictionary = {}
var _selection_in_progress: bool = false
var _backdrop_material: ShaderMaterial
var _backdrop_time: float = 0.0


func _ready() -> void:
	visible = false
	if backdrop_rect != null and backdrop_rect.material is ShaderMaterial:
		_backdrop_material = backdrop_rect.material
	input_hint_label.text = "←/→ focus  Enter select  ↑/↓ scroll build"
	set_process(true)


func _process(delta: float) -> void:
	if not visible:
		return
	if _backdrop_material == null:
		return
	_backdrop_time += delta
	_backdrop_material.set_shader_parameter("time_sec", _backdrop_time)


func show_options(options: Array, hud_data: Dictionary = {}, run_multipliers: Dictionary = {}) -> void:
	_current_options = options.duplicate(true)
	_latest_hud_data = hud_data.duplicate(true)
	_run_multipliers = run_multipliers.duplicate(true)
	visible = true
	_build_cards()
	_update_build_panel()
	UIMotionClass.panel_pop_in(self, 0.14, 8.0)
	if not _cards.is_empty():
		_focus_card(0)


func hide_panel() -> void:
	visible = false
	_current_options.clear()
	_cards.clear()
	_selection_in_progress = false


func update_build_context(hud_data: Dictionary, run_multipliers: Dictionary = {}) -> void:
	_latest_hud_data = hud_data.duplicate(true)
	if not run_multipliers.is_empty():
		_run_multipliers = run_multipliers.duplicate(true)
	_update_build_panel()


func debug_focus_index(index: int) -> void:
	_focus_card(index)


func debug_select_index(index: int) -> void:
	if index < 0 or index >= _cards.size():
		return
	var card := _cards[index]
	if card != null and card.has_method("select_card"):
		card.call("select_card")


func debug_get_snapshot() -> Dictionary:
	var build_snapshot := {}
	if build_panel != null:
		build_snapshot = build_panel.get_snapshot()
	return {
		"visible": visible,
		"card_count": _cards.size(),
		"focused_index": _focused_index,
		"build": build_snapshot
	}


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if not (event is InputEventKey):
		return
	if not event.pressed or event.echo:
		return

	match event.keycode:
		KEY_LEFT:
			_focus_card(_focused_index - 1)
			accept_event()
		KEY_RIGHT:
			_focus_card(_focused_index + 1)
			accept_event()
		KEY_UP:
			if build_panel != null:
				build_panel.scroll_by(-1)
			accept_event()
		KEY_DOWN:
			if build_panel != null:
				build_panel.scroll_by(1)
			accept_event()
		KEY_ENTER, KEY_KP_ENTER:
			_select_focused_card()
			accept_event()
		KEY_ESCAPE:
			if allow_cancel:
				cancel_requested.emit()
			accept_event()
		_:
			pass


func _build_cards() -> void:
	for child in cards_row.get_children():
		child.queue_free()
	_cards.clear()
	for i in range(_current_options.size()):
		var option_variant: Variant = _current_options[i]
		if not (option_variant is Dictionary):
			continue
		var option: Dictionary = option_variant
		var card_variant := UPGRADE_CARD_SCENE.instantiate()
		if not (card_variant is Node):
			continue
		var card: Node = card_variant
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		cards_row.add_child(card)
		if card.has_method("set_card_index"):
			card.call("set_card_index", i)
		if card.has_method("set_upgrade_data"):
			card.call("set_upgrade_data", option, TAG_DISPLAY_NAMES)
		if card.has_signal("card_selected"):
			card.connect("card_selected", Callable(self, "_on_card_selected"))
		_cards.append(card)
	subtitle_label.text = "Pick one. Build direction updates on the right."


func _update_build_panel() -> void:
	if build_panel == null:
		return
	build_panel.set_build_data(_latest_hud_data, _run_multipliers)


func _focus_card(index: int) -> void:
	if _cards.is_empty():
		return
	_focused_index = wrapi(index, 0, _cards.size())
	var card := _cards[_focused_index]
	if card != null and card.has_method("grab_card_focus"):
		card.call("grab_card_focus")


func _select_focused_card() -> void:
	if _cards.is_empty():
		return
	var card := _cards[_focused_index]
	if card != null and card.has_method("select_card"):
		card.call("select_card")


func _on_card_selected(upgrade_id: String, card_index: int) -> void:
	if _selection_in_progress:
		return
	_selection_in_progress = true
	_focused_index = clampi(card_index, 0, maxi(0, _cards.size() - 1))
	var preview_hud := _build_preview_hud_data(upgrade_id)
	if build_panel != null and build_panel.has_method("set_build_data"):
		build_panel.call("set_build_data", preview_hud, _run_multipliers)
	if build_panel != null and UIMotionClass.is_motion_enabled():
		UIMotionClass.panel_pop_in(build_panel, 0.10, 4.0)
		await get_tree().create_timer(0.08).timeout
	upgrade_selected.emit(upgrade_id)
	_selection_in_progress = false


func _build_preview_hud_data(upgrade_id: String) -> Dictionary:
	var preview: Dictionary = _latest_hud_data.duplicate(true)
	var acquired_variant: Variant = preview.get("acquired_tags", {})
	var acquired_tags: Dictionary = acquired_variant.duplicate(true) if acquired_variant is Dictionary else {}
	var stacks_variant: Variant = preview.get("upgrade_stacks", {})
	var stacks: Dictionary = stacks_variant.duplicate(true) if stacks_variant is Dictionary else {}
	var upgrade := DataRegistry.get_upgrade(upgrade_id)
	stacks[upgrade_id] = int(stacks.get(upgrade_id, 0)) + 1
	var tags_variant: Variant = upgrade.get("tags", [])
	if tags_variant is Array:
		for tag_variant in (tags_variant as Array):
			var tag := String(tag_variant).strip_edges().to_lower()
			if tag.is_empty():
				continue
			acquired_tags[tag] = int(acquired_tags.get(tag, 0)) + 1
	preview["acquired_tags"] = acquired_tags
	preview["upgrade_stacks"] = stacks
	return preview
