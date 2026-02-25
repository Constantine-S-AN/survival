extends RefCounted
class_name RunSummaryState

static func from_dict(source: Dictionary) -> Dictionary:
	var multipliers_variant: Variant = source.get("multipliers", {})
	var multipliers: Dictionary = multipliers_variant if multipliers_variant is Dictionary else {}
	return {
		"time_survived_sec": maxf(0.0, float(source.get("time_survived_sec", source.get("time", 0.0)))),
		"kills": maxi(0, int(source.get("kills", 0))),
		"level": maxi(1, int(source.get("level", 1))),
		"noise_peak_tier": String(source.get("noise_peak_tier", "-")),
		"enemies_seen": maxi(0, int(source.get("enemies_seen", source.get("enemy_count", 0)))),
		"revealed_count": maxi(0, int(source.get("revealed_count", 0))),
		"boss_progress": String(source.get("boss_progress", "")),
		"weapon_id": String(source.get("weapon_id", "")),
		"weapon_name": String(source.get("weapon_name", "--")),
		"top_tags": _normalize_top_tags(source.get("top_tags", [])),
		"chosen_upgrades": _normalize_upgrades(source.get("chosen_upgrades", [])),
		"map_id": String(source.get("map_id", "")),
		"map_name": String(source.get("map_name", source.get("map_id", "-"))),
		"contract_ids": _normalize_string_array(source.get("contract_ids", [])),
		"contract_names": _normalize_string_array(source.get("contract_names", [])),
		"drop_pickups_spawned": maxi(0, int(source.get("drop_pickups_spawned", 0))),
		"multipliers": {
			"xp": float(multipliers.get("xp", multipliers.get("xp_mult", 1.0))),
			"rarity": float(multipliers.get("rarity", multipliers.get("rarity_mult", 1.0))),
			"drop": float(multipliers.get("drop", multipliers.get("drop_mult", 1.0))),
			"meta_currency": float(multipliers.get("meta_currency", multipliers.get("meta_currency_mult", 1.0)))
		},
		"meta_currency_earned": _normalize_meta_currency(source.get("meta_currency_earned", null)),
		"unlock_progress": _normalize_unlock_progress(source.get("unlock_progress", [])),
		"newly_unlocked_names": _normalize_string_array(source.get("newly_unlocked_names", [])),
		"seed": int(source.get("seed", 0))
	}


static func format_time(total_seconds: float) -> String:
	var total := maxi(0, int(floor(total_seconds)))
	var minutes := total / 60
	var seconds := total % 60
	return "%02d:%02d" % [minutes, seconds]


static func _normalize_top_tags(value: Variant) -> Array[Dictionary]:
	var output: Array[Dictionary] = []
	if not (value is Array):
		return output
	for entry_variant in (value as Array):
		if entry_variant is Dictionary:
			var row: Dictionary = entry_variant
			var tag := String(row.get("tag", "")).strip_edges().to_lower()
			if tag.is_empty():
				continue
			output.append({
				"tag": tag,
				"label": _tag_name(tag),
				"weight": maxi(0, int(row.get("weight", 0)))
			})
		else:
			var text := String(entry_variant).strip_edges().to_lower()
			if text.is_empty():
				continue
			output.append({
				"tag": text,
				"label": _tag_name(text),
				"weight": 1
			})
	return output


static func _normalize_upgrades(value: Variant) -> Array[Dictionary]:
	var output: Array[Dictionary] = []
	if not (value is Array):
		return output
	for row_variant in (value as Array):
		if not (row_variant is Dictionary):
			continue
		var row: Dictionary = row_variant
		output.append({
			"id": String(row.get("id", "")),
			"name": String(row.get("name", _unknown_upgrade_name())),
			"rarity": String(row.get("rarity", "common")),
			"count": maxi(1, int(row.get("count", 1))),
			"tags": _normalize_string_array(row.get("tags", []))
		})
	return output


static func _normalize_unlock_progress(value: Variant) -> Array[Dictionary]:
	var output: Array[Dictionary] = []
	if not (value is Array):
		return output
	for row_variant in (value as Array):
		if not (row_variant is Dictionary):
			continue
		var row: Dictionary = row_variant
		output.append({
			"name": String(row.get("name", "Unknown")),
			"display": String(row.get("display", "")),
			"ratio": clampf(float(row.get("ratio", 0.0)), 0.0, 1.0),
			"text": String(row.get("text", "")),
			"met": bool(row.get("met", false))
		})
	return output


static func _normalize_string_array(value: Variant) -> Array[String]:
	var output: Array[String] = []
	if not (value is Array):
		return output
	for item in (value as Array):
		var text := String(item).strip_edges()
		if text.is_empty():
			continue
		output.append(text)
	return output


static func _normalize_meta_currency(value: Variant) -> Variant:
	if value == null:
		return null
	if value is Dictionary:
		var payload: Dictionary = value
		return {
			"base": maxi(0, int(payload.get("base", payload.get("total", 0)))),
			"multiplier": maxf(0.0, float(payload.get("multiplier", 1.0))),
			"total": maxi(0, int(payload.get("total", payload.get("base", 0))))
		}
	return maxi(0, int(value))


static func _tag_name(tag: String) -> String:
	if Localization == null or not Localization.has_method("tag_name"):
		return tag.capitalize()
	return String(Localization.call("tag_name", tag))


static func _unknown_upgrade_name() -> String:
	if Localization == null or not Localization.has_method("t"):
		return "Unknown Upgrade"
	return String(Localization.call("t", "upgrade.unknown"))
