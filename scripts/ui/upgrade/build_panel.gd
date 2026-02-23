extends PanelContainer
class_name UpgradeBuildPanel

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

@onready var body_scroll: ScrollContainer = $Margin/BodyScroll
@onready var weapon_label: Label = $Margin/BodyScroll/Body/WeaponLabel
@onready var top_tags_value: Label = $Margin/BodyScroll/Body/TopTagsValue
@onready var key_passives_value: Label = $Margin/BodyScroll/Body/KeyPassivesValue
@onready var modifiers_value: Label = $Margin/BodyScroll/Body/ModifiersValue

var _last_snapshot: Dictionary = {}


func set_build_data(hud_data: Dictionary, run_multipliers: Dictionary = {}) -> void:
	var weapon_name := String(hud_data.get("active_weapon_name", hud_data.get("weapon_name", "--")))
	weapon_label.text = "Current Weapon: %s" % weapon_name

	var top_tags := _derive_top_tags(hud_data)
	top_tags_value.text = " ".join(top_tags) if not top_tags.is_empty() else "-"

	var key_passives := _derive_key_passives(hud_data)
	key_passives_value.text = "\n".join(key_passives) if not key_passives.is_empty() else "-"

	modifiers_value.text = _format_modifiers(hud_data, run_multipliers)

	_last_snapshot = {
		"weapon": weapon_name,
		"top_tags": top_tags_value.text,
		"key_passives": key_passives_value.text,
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
		return int(a.get("value", 0)) > int(b.get("value", 0))
	)
	var out: Array[String] = []
	for i in range(mini(5, pairs.size())):
		var pair: Dictionary = pairs[i]
		var tag := String(pair.get("tag", ""))
		out.append("[%s]" % String(TAG_DISPLAY_NAMES.get(tag, tag.capitalize())))
	return out


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
		output.append("• %s x%d" % [String(row.get("name", "Unknown")), int(row.get("count", 1))])
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
	return "XP x%.2f | Rarity x%.2f\nDrop x%.2f | Meta x%.2f" % [xp, rarity, drop, meta]


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
