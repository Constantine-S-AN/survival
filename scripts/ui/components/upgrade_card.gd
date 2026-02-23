extends PanelContainer
class_name UpgradeCard

signal card_selected(upgrade_id: String, card_index: int)

const UIMotionClass := preload("res://scripts/ui/ui_motion.gd")

const RARITY_STYLE := {
	"common": {"color": Color(0.56, 0.72, 0.84, 1.0), "width": 1},
	"uncommon": {"color": Color(0.42, 0.90, 0.72, 1.0), "width": 2},
	"rare": {"color": Color(0.36, 0.72, 1.0, 1.0), "width": 2},
	"epic": {"color": Color(0.78, 0.62, 1.0, 1.0), "width": 3},
	"legendary": {"color": Color(1.0, 0.78, 0.42, 1.0), "width": 3}
}

@export var enable_motion: bool = true

@onready var rarity_label: Label = $Margin/VBox/TopRow/Rarity
@onready var icon_glyph: Label = $Margin/VBox/IconWrap/IconGlyph
@onready var title_label: Label = $Margin/VBox/Title
@onready var desc_label: Label = $Margin/VBox/Desc
@onready var stats_label: Label = $Margin/VBox/KeyStats
@onready var tag_labels: Array[Label] = [
	$Margin/VBox/TagsRow/Tag1,
	$Margin/VBox/TagsRow/Tag2,
	$Margin/VBox/TagsRow/Tag3,
	$Margin/VBox/TagsRow/Tag4
]
@onready var hitbox: Button = $Hitbox
@onready var focus_ring: PanelContainer = $FocusRing

var _upgrade_id: String = ""
var _card_index: int = -1
var _pending_option: Dictionary = {}
var _pending_tag_display_names: Dictionary = {}


func _ready() -> void:
	focus_ring.visible = false
	hitbox.pressed.connect(_on_pressed)
	hitbox.mouse_entered.connect(_on_hover_enter)
	hitbox.mouse_exited.connect(_on_hover_exit)
	hitbox.focus_entered.connect(_on_focus_enter)
	hitbox.focus_exited.connect(_on_focus_exit)
	if not _pending_option.is_empty():
		_apply_upgrade_data(_pending_option, _pending_tag_display_names)
		_pending_option.clear()
		_pending_tag_display_names.clear()


func set_card_index(value: int) -> void:
	_card_index = maxi(0, value)


func set_upgrade_data(option: Dictionary, tag_display_names: Dictionary = {}) -> void:
	_pending_option = option.duplicate(true)
	_pending_tag_display_names = tag_display_names.duplicate(true)
	if rarity_label == null:
		return
	_apply_upgrade_data(option, tag_display_names)


func _apply_upgrade_data(option: Dictionary, tag_display_names: Dictionary) -> void:
	_upgrade_id = String(option.get("id", "")).strip_edges()
	var rarity := String(option.get("rarity", "common")).strip_edges().to_lower()
	if rarity.is_empty():
		rarity = "common"
	rarity_label.text = rarity.capitalize()
	title_label.text = String(option.get("name", "Unknown Upgrade"))
	desc_label.text = _extract_short_description(option)
	icon_glyph.text = _resolve_icon_glyph(option)
	stats_label.text = _build_key_stats_text(option)
	_populate_tags(option.get("tags", []), tag_display_names)
	_apply_rarity_style(rarity)


func grab_card_focus() -> void:
	hitbox.grab_focus()


func is_card_focused() -> bool:
	return hitbox.has_focus()


func select_card() -> void:
	_on_pressed()


func get_upgrade_id() -> String:
	return _upgrade_id


func _on_pressed() -> void:
	if _upgrade_id.is_empty():
		return
	if enable_motion:
		UIMotionClass.press_bounce(self, 0.10)
	card_selected.emit(_upgrade_id, _card_index)


func _on_hover_enter() -> void:
	if enable_motion:
		UIMotionClass.hover_scale(self, 1.015, 0.08)


func _on_hover_exit() -> void:
	if not enable_motion:
		return
	var tween := create_tween()
	tween.tween_property(self, "scale", Vector2.ONE, 0.08)


func _on_focus_enter() -> void:
	focus_ring.visible = true
	if enable_motion:
		UIMotionClass.focus_ring(self)


func _on_focus_exit() -> void:
	focus_ring.visible = false


func _extract_short_description(option: Dictionary) -> String:
	var text := String(option.get("description", "")).strip_edges()
	if text.is_empty():
		return "No description yet"
	if text.length() <= 80:
		return text
	return text.substr(0, 77) + "..."


func _resolve_icon_glyph(option: Dictionary) -> String:
	var icon_name := String(option.get("icon", "")).strip_edges()
	if not icon_name.is_empty():
		return icon_name.substr(0, 2).to_upper()
	var name := String(option.get("name", "U"))
	if name.is_empty():
		return "UP"
	var words := name.split(" ", false)
	if words.size() >= 2:
		return (String(words[0]).substr(0, 1) + String(words[1]).substr(0, 1)).to_upper()
	return name.substr(0, mini(2, name.length())).to_upper()


func _build_key_stats_text(option: Dictionary) -> String:
	var effects_variant: Variant = option.get("effects", [])
	if not (effects_variant is Array):
		return "No key stats"
	var effects: Array = effects_variant
	if effects.is_empty():
		return "No key stats"
	var lines: Array[String] = []
	for i in range(mini(2, effects.size())):
		var effect_variant: Variant = effects[i]
		if not (effect_variant is Dictionary):
			continue
		lines.append(_format_effect_line(effect_variant))
	if lines.is_empty():
		return "No key stats"
	return "\n".join(lines)


func _format_effect_line(effect: Dictionary) -> String:
	var stat := String(effect.get("stat", "")).strip_edges()
	if stat.is_empty():
		return "-"
	var add_value := float(effect.get("add", 0.0))
	var amount_text := _format_amount(stat, add_value)
	var stat_text := stat.replace("_", " ").capitalize()
	var target_suffix := ""
	var target_variant: Variant = effect.get("target", null)
	if target_variant is Dictionary:
		var target: Dictionary = target_variant
		var target_type := String(target.get("type", "")).strip_edges().to_lower()
		var target_value := String(target.get("value", "")).strip_edges()
		if not target_type.is_empty() and not target_value.is_empty():
			target_suffix = " (%s %s)" % [target_type, target_value]
	return "%s %s%s" % [amount_text, stat_text, target_suffix]


func _format_amount(stat: String, value: float) -> String:
	var signed := "+" if value >= 0.0 else ""
	if stat.ends_with("_mult") or stat.find("chance") >= 0 or absf(value) <= 2.0:
		return "%s%d%%" % [signed, int(round(value * 100.0))]
	if absf(value - round(value)) < 0.001:
		return "%s%d" % [signed, int(round(value))]
	return "%s%.2f" % [signed, value]


func _populate_tags(tags_variant: Variant, tag_display_names: Dictionary) -> void:
	var tags: Array[String] = []
	if tags_variant is Array:
		for tag_variant in (tags_variant as Array):
			var tag := String(tag_variant).strip_edges().to_lower()
			if tag.is_empty():
				continue
			tags.append(String(tag_display_names.get(tag, tag.capitalize())))
	for i in range(tag_labels.size()):
		var label := tag_labels[i]
		if i < tags.size():
			label.text = "[%s]" % tags[i]
			label.visible = true
		else:
			label.visible = false


func _apply_rarity_style(rarity: String) -> void:
	var style_variant: Variant = RARITY_STYLE.get(rarity, RARITY_STYLE["common"])
	var style: Dictionary = style_variant if style_variant is Dictionary else RARITY_STYLE["common"]
	var color: Color = style["color"]
	var width: int = int(style["width"])
	rarity_label.modulate = color
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.07, 0.11, 0.16, 0.95)
	panel_style.border_color = color
	panel_style.set_border_width_all(width)
	panel_style.corner_radius_top_left = 12
	panel_style.corner_radius_top_right = 12
	panel_style.corner_radius_bottom_left = 12
	panel_style.corner_radius_bottom_right = 12
	add_theme_stylebox_override("panel", panel_style)

	var focus_style := StyleBoxFlat.new()
	focus_style.bg_color = Color(0.0, 0.0, 0.0, 0.0)
	focus_style.border_color = color.lightened(0.2)
	focus_style.set_border_width_all(width + 1)
	focus_style.corner_radius_top_left = 12
	focus_style.corner_radius_top_right = 12
	focus_style.corner_radius_bottom_left = 12
	focus_style.corner_radius_bottom_right = 12
	focus_ring.add_theme_stylebox_override("panel", focus_style)
