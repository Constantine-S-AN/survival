extends PanelContainer
class_name UpgradeBuildPanel

const IconRegistry := preload("res://scripts/ui/icon_registry.gd")
const WEAPON_ICON_ANIM_SEC := 0.20
const TAG_ICON_CODES: Dictionary = {
	"sonar": "SO",
	"silence": "SI",
	"heat": "HT",
	"crit": "CR",
	"pierce": "PI",
	"chain": "CH",
	"aoe": "AO",
	"pickup": "PK",
	"shield": "SH",
	"speed": "SP",
	"trap": "TR",
	"control": "CT",
	"summon": "SM",
	"economy": "EC",
	"damage": "DM",
	"weapon": "WP",
	"tempo": "TP",
	"starter": "ST",
	"kinetic": "KN",
	"noise": "NS",
	"mobility": "MB",
	"defense": "DF",
	"hull": "HL"
}

@onready var body_scroll: ScrollContainer = $Margin/BodyScroll
@onready var title_label: Label = $Margin/BodyScroll/Body/Title
@onready var weapon_icon: TextureRect = $Margin/BodyScroll/Body/WeaponRow/WeaponIcon
@onready var weapon_label: Label = $Margin/BodyScroll/Body/WeaponRow/WeaponLabel
@onready var top_tags_title_label: Label = $Margin/BodyScroll/Body/TopTagsTitle
@onready var top_tags_flow: HFlowContainer = $Margin/BodyScroll/Body/TopTagsFlow
@onready var key_passives_title_label: Label = $Margin/BodyScroll/Body/KeyPassivesTitle
@onready var key_passives_list: VBoxContainer = $Margin/BodyScroll/Body/KeyPassivesList
@onready var modifiers_title_label: Label = $Margin/BodyScroll/Body/ModifiersTitle
@onready var modifiers_value: Label = $Margin/BodyScroll/Body/ModifiersValue

var _last_snapshot: Dictionary = {}
var _last_hud_data: Dictionary = {}
var _last_run_multipliers: Dictionary = {}
var _weapon_icon_frames: Array[Texture2D] = []
var _weapon_icon_timer: float = 0.0
var _weapon_icon_frame_idx: int = 0


func _ready() -> void:
	if Localization != null and Localization.has_signal("language_changed"):
		Localization.language_changed.connect(_on_language_changed)
	_apply_static_texts()
	set_process(true)


func _process(delta: float) -> void:
	_tick_weapon_icon(delta)


func set_build_data(hud_data: Dictionary, run_multipliers: Dictionary = {}) -> void:
	_last_hud_data = hud_data.duplicate(true)
	_last_run_multipliers = run_multipliers.duplicate(true)
	var weapon_id := String(hud_data.get("active_weapon_id", hud_data.get("weapon_id", "")))
	var weapon_name := String(hud_data.get("active_weapon_name", hud_data.get("weapon_name", "--")))
	weapon_label.text = _t("build.current_weapon", {"value": weapon_name})
	if weapon_icon != null:
		_set_weapon_icon_frames(IconRegistry.get_weapon_icon_frames(weapon_id))

	var top_tags := _derive_top_tags(hud_data)
	_render_top_tags(top_tags)

	var key_passives := _derive_key_passives(hud_data)
	_render_key_passives(key_passives)

	modifiers_value.text = _format_modifiers(hud_data, run_multipliers)

	_last_snapshot = {
		"weapon": weapon_name,
		"top_tags": top_tags,
		"key_passives": key_passives,
		"modifiers": modifiers_value.text
	}


func scroll_by(step: int) -> void:
	if body_scroll == null:
		return
	var next_scroll := body_scroll.scroll_vertical + step * 32
	body_scroll.scroll_vertical = maxi(0, next_scroll)


func get_snapshot() -> Dictionary:
	return _last_snapshot.duplicate(true)


func _derive_top_tags(hud_data: Dictionary) -> Array[String]:
	var counts: Dictionary = {}
	var acquired_variant: Variant = hud_data.get("acquired_tags", {})
	if acquired_variant is Dictionary:
		counts = (acquired_variant as Dictionary).duplicate(true)
	if counts.is_empty():
		var build_tags_variant: Variant = hud_data.get("build_tags", [])
		if build_tags_variant is Array:
			for tag_variant in (build_tags_variant as Array):
				var tag := String(tag_variant).strip_edges().to_lower()
				if tag.is_empty():
					continue
				counts[tag] = int(counts.get(tag, 0)) + 1
	var pairs: Array = []
	for key_variant in counts.keys():
		var key := String(key_variant).strip_edges().to_lower()
		var value := int(counts.get(key_variant, 0))
		if key.is_empty() or value <= 0:
			continue
		pairs.append({"tag": key, "value": value})
	pairs.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var av := int(a.get("value", 0))
		var bv := int(b.get("value", 0))
		if av == bv:
			return String(a.get("tag", "")) < String(b.get("tag", ""))
		return av > bv
	)
	var out: Array[String] = []
	for i in range(mini(5, pairs.size())):
		var pair: Dictionary = pairs[i]
		var tag := String(pair.get("tag", ""))
		var label := _tag_name(tag)
		var icon_code := String(TAG_ICON_CODES.get(tag, "TG"))
		out.append("[%s %s]" % [icon_code, label])
	return out


func _render_top_tags(tags: Array[String]) -> void:
	if top_tags_flow == null:
		return
	for child in top_tags_flow.get_children():
		child.queue_free()
	if tags.is_empty():
		_add_badge(top_tags_flow, _t("build.none"))
		return
	for tag in tags:
		_add_badge(top_tags_flow, tag)


func _render_key_passives(rows: Array[String]) -> void:
	if key_passives_list == null:
		return
	for child in key_passives_list.get_children():
		child.queue_free()
	if rows.is_empty():
		var placeholder := Label.new()
		placeholder.text = _t("build.none")
		placeholder.theme_type_variation = &"BodyMutedLabel"
		key_passives_list.add_child(placeholder)
		return
	for row in rows:
		var label := Label.new()
		label.text = row
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		label.theme_type_variation = &"BodyMutedLabel"
		key_passives_list.add_child(label)


func _add_badge(parent: Control, text: String) -> void:
	var badge := PanelContainer.new()
	badge.theme_type_variation = &"BadgePanel"
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 8)
	margin.add_theme_constant_override("margin_top", 3)
	margin.add_theme_constant_override("margin_right", 8)
	margin.add_theme_constant_override("margin_bottom", 3)
	var label := Label.new()
	label.text = text
	label.theme_type_variation = &"BodyMutedLabel"
	margin.add_child(label)
	badge.add_child(margin)
	parent.add_child(badge)


func _set_weapon_icon_frames(frames: Array[Texture2D]) -> void:
	if weapon_icon == null:
		return
	if frames.is_empty():
		_weapon_icon_frames.clear()
		weapon_icon.texture = null
		return
	var changed := _weapon_icon_frames.size() != frames.size()
	if not changed:
		for i in range(frames.size()):
			if _weapon_icon_frames[i] != frames[i]:
				changed = true
				break
	if changed:
		_weapon_icon_frames = frames
		_weapon_icon_timer = 0.0
		_weapon_icon_frame_idx = 0
		weapon_icon.texture = _weapon_icon_frames[0]


func _tick_weapon_icon(delta: float) -> void:
	if weapon_icon == null or _weapon_icon_frames.size() <= 1:
		return
	_weapon_icon_timer += delta
	if _weapon_icon_timer < WEAPON_ICON_ANIM_SEC:
		return
	_weapon_icon_timer = 0.0
	_weapon_icon_frame_idx = (_weapon_icon_frame_idx + 1) % _weapon_icon_frames.size()
	weapon_icon.texture = _weapon_icon_frames[_weapon_icon_frame_idx]


func _derive_key_passives(hud_data: Dictionary) -> Array[String]:
	var stacks_variant: Variant = hud_data.get("upgrade_stacks", {})
	if not (stacks_variant is Dictionary):
		return _derive_top_tags(hud_data)
	var stacks: Dictionary = stacks_variant
	if stacks.is_empty():
		return _derive_top_tags(hud_data)
	var ranked: Array = []
	for key_variant in stacks.keys():
		var upgrade_id := String(key_variant).strip_edges()
		var count := int(stacks.get(key_variant, 0))
		if upgrade_id.is_empty() or count <= 0:
			continue
		var upgrade := DataRegistry.get_upgrade(upgrade_id)
		var rarity := String(upgrade.get("rarity", "common")).to_lower()
		var rarity_score := _rarity_score(rarity)
		ranked.append({
			"id": upgrade_id,
			"count": count,
			"rarity_score": rarity_score,
			"name": String(upgrade.get("name", upgrade_id))
		})
	ranked.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		if int(a.get("count", 0)) == int(b.get("count", 0)):
			return int(a.get("rarity_score", 0)) > int(b.get("rarity_score", 0))
		return int(a.get("count", 0)) > int(b.get("count", 0))
	)
	var output: Array[String] = []
	for i in range(mini(3, ranked.size())):
		var row: Dictionary = ranked[i]
		output.append("• %s x%d" % [String(row.get("name", _t("upgrade.unknown"))), int(row.get("count", 1))])
	return output


func _format_modifiers(hud_data: Dictionary, run_multipliers: Dictionary) -> String:
	var source := run_multipliers
	if source.is_empty():
		source = {
			"xp": float(hud_data.get("env_xp_gain_multiplier", 1.0))
		}
	var xp := float(source.get("xp", source.get("xp_mult", 1.0)))
	var rarity := float(source.get("rarity", source.get("rarity_mult", 1.0)))
	var drop := float(source.get("drop", source.get("drop_mult", 1.0)))
	var meta := float(source.get("meta_currency", source.get("meta_currency_mult", 1.0)))
	return _t("build.modifiers", {
		"xp": "%.2f" % xp,
		"rarity": "%.2f" % rarity,
		"drop": "%.2f" % drop,
		"meta": "%.2f" % meta
	})


func _rarity_score(rarity: String) -> int:
	match rarity:
		"legendary":
			return 5
		"epic":
			return 4
		"rare":
			return 3
		"uncommon":
			return 2
		_:
			return 1


func _on_language_changed(_language_code: String) -> void:
	_apply_static_texts()
	if not _last_hud_data.is_empty():
		set_build_data(_last_hud_data, _last_run_multipliers)


func _apply_static_texts() -> void:
	title_label.text = _t("build.title")
	top_tags_title_label.text = _t("build.top_tags")
	key_passives_title_label.text = _t("build.key_passives")
	modifiers_title_label.text = _t("build.run_modifiers")


func _t(key: String, args: Dictionary = {}) -> String:
	if Localization == null or not Localization.has_method("t"):
		return key
	return String(Localization.call("t", key, args))


func _tag_name(tag: String) -> String:
	if Localization == null or not Localization.has_method("tag_name"):
		return tag.capitalize()
	return String(Localization.call("tag_name", tag))
