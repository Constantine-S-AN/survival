extends RefCounted
class_name MenuPlanner

const MAX_MENU_SIZE := 3


static func toggle_recipe(selected_menu_ids: Array, recipe_id: String, max_menu_size: int = MAX_MENU_SIZE) -> Dictionary:
	var normalized_recipe_id := recipe_id.strip_edges().to_lower()
	var menu_ids := _normalize_string_array(selected_menu_ids)
	if normalized_recipe_id.is_empty():
		return {
			"ok": false,
			"selected_menu_ids": menu_ids,
			"status": "invalid"
		}
	if menu_ids.has(normalized_recipe_id):
		menu_ids.erase(normalized_recipe_id)
		return {
			"ok": true,
			"selected_menu_ids": menu_ids,
			"status": "removed"
		}
	if menu_ids.size() >= maxi(1, max_menu_size):
		return {
			"ok": false,
			"selected_menu_ids": menu_ids,
			"status": "full"
		}
	menu_ids.append(normalized_recipe_id)
	return {
		"ok": true,
		"selected_menu_ids": menu_ids,
		"status": "added"
	}


static func build_recipe_cards(recipe_defs: Array, materials: Dictionary, unlocked_recipe_ids: Array, selected_menu_ids: Array) -> Array[Dictionary]:
	var cards: Array[Dictionary] = []
	var unlocked_lookup: Dictionary = {}
	for recipe_id in _normalize_string_array(unlocked_recipe_ids):
		unlocked_lookup[recipe_id] = true
	var selected_lookup: Dictionary = {}
	for recipe_id in _normalize_string_array(selected_menu_ids):
		selected_lookup[recipe_id] = true
	for recipe_variant in recipe_defs:
		if not (recipe_variant is Dictionary):
			continue
		var recipe: Dictionary = recipe_variant
		var recipe_id := String(recipe.get("id", "")).strip_edges().to_lower()
		if recipe_id.is_empty():
			continue
		var unlocked := unlocked_lookup.has(recipe_id)
		var craftable_servings := max_servings(recipe, materials)
		var ingredients_text := _build_material_bundle_text(recipe.get("ingredients", {}))
		var tag_text := _build_tag_text(recipe.get("category_tags", []))
		var synergy_text := _build_synergy_text(recipe)
		var night_material_text := _build_night_material_text(recipe)
		var label := "%s\n$%d · Prep %d · %s\n%s" % [
			String(recipe.get("name", recipe_id.capitalize())),
			int(recipe.get("base_price", 0)),
			int(recipe.get("prep_complexity", 1)),
			_build_servings_text(craftable_servings),
			ingredients_text
		]
		if not night_material_text.is_empty():
			label += "\n%s" % _t("meta.restaurant.recipe_card_night", {"value": night_material_text})
		if not tag_text.is_empty():
			label += "\n%s" % tag_text
		if not synergy_text.is_empty():
			label += "\n%s" % synergy_text
		cards.append({
			"id": recipe_id,
			"label": label,
			"selected": selected_lookup.has(recipe_id),
			"enabled": unlocked,
			"craftable_servings": craftable_servings,
			"tooltip": _build_recipe_tooltip(recipe, craftable_servings, unlocked, ingredients_text, night_material_text, synergy_text)
		})
	return cards


static func build_selected_menu_entries(selected_menu_ids: Array, recipe_lookup: Dictionary, materials: Dictionary) -> Array[Dictionary]:
	var entries: Array[Dictionary] = []
	for recipe_id in _normalize_string_array(selected_menu_ids):
		var recipe_variant: Variant = recipe_lookup.get(recipe_id, {})
		if not (recipe_variant is Dictionary):
			continue
		var recipe: Dictionary = recipe_variant
		var craftable_servings := max_servings(recipe, materials)
		var entry_label := "%s\n%s · %s" % [
			String(recipe.get("name", recipe_id.capitalize())),
			_build_servings_text(craftable_servings),
			_build_material_bundle_text(recipe.get("ingredients", {}))
		]
		entries.append({
			"id": recipe_id,
			"label": entry_label,
			"craftable_servings": craftable_servings
		})
	return entries


static func max_servings(recipe: Dictionary, materials_variant: Variant) -> int:
	var ingredients_variant: Variant = recipe.get("ingredients", {})
	if not (ingredients_variant is Dictionary):
		return 0
	var ingredients: Dictionary = ingredients_variant
	if ingredients.is_empty():
		return 0
	var materials: Dictionary = materials_variant if materials_variant is Dictionary else {}
	var servings := 999999
	for material_id_variant in ingredients.keys():
		var material_id := String(material_id_variant).strip_edges().to_lower()
		if material_id.is_empty():
			continue
		var required_amount := maxi(1, int(ingredients.get(material_id_variant, 0)))
		var available_amount := maxi(0, int(materials.get(material_id, 0)))
		servings = mini(servings, available_amount / required_amount)
	return maxi(0, servings if servings != 999999 else 0)


static func build_ingredient_summary(materials_variant: Variant) -> String:
	var materials: Dictionary = materials_variant if materials_variant is Dictionary else {}
	if materials.is_empty():
		return "-"
	var ordered_ids: Array[String] = []
	for material_id_variant in materials.keys():
		var material_id := String(material_id_variant).strip_edges().to_lower()
		if material_id.is_empty():
			continue
		ordered_ids.append(material_id)
	ordered_ids.sort()
	var parts: Array[String] = []
	for material_id in ordered_ids:
		var amount := maxi(0, int(materials.get(material_id, 0)))
		parts.append("%s x%d" % [_material_name(material_id), amount])
	return ", ".join(parts)


static func build_menu_ids_string(selected_menu_ids: Array) -> String:
	return ", ".join(_normalize_string_array(selected_menu_ids))


static func _build_material_bundle_text(bundle_variant: Variant) -> String:
	if not (bundle_variant is Dictionary):
		return ""
	var bundle: Dictionary = bundle_variant
	var parts: Array[String] = []
	for material_id_variant in bundle.keys():
		var material_id := String(material_id_variant).strip_edges().to_lower()
		if material_id.is_empty():
			continue
		parts.append("%s x%d" % [_material_name(material_id), int(bundle.get(material_id_variant, 0))])
	return ", ".join(parts)


static func _build_tag_text(tags_variant: Variant) -> String:
	if not (tags_variant is Array):
		return ""
	var parts: Array[String] = []
	for tag_variant in tags_variant:
		var tag := String(tag_variant).strip_edges()
		if tag.is_empty():
			continue
		parts.append(tag)
	return "Tags: %s" % ", ".join(parts) if not parts.is_empty() else ""


static func _build_synergy_text(recipe: Dictionary) -> String:
	var synergy_variant: Variant = recipe.get("night_material_synergy", {})
	if not (synergy_variant is Dictionary):
		return ""
	var synergy: Dictionary = synergy_variant
	if synergy.is_empty():
		return ""
	var material_id := String(synergy.get("material_id", "")).strip_edges().to_lower()
	if material_id.is_empty():
		return ""
	return "Night synergy: %s" % _material_name(material_id)


static func _build_recipe_tooltip(
	recipe: Dictionary,
	craftable_servings: int,
	unlocked: bool,
	ingredients_text: String,
	night_material_text: String,
	synergy_text: String
) -> String:
	var lines: Array[String] = []
	var description := String(recipe.get("description", "")).strip_edges()
	if not description.is_empty():
		lines.append(description)
	lines.append(_t("meta.restaurant.recipe_tooltip.stats", {
		"price": int(recipe.get("base_price", 0)),
		"prep": int(recipe.get("prep_complexity", 1)),
		"servings": maxi(0, craftable_servings)
	}))
	if not ingredients_text.is_empty():
		lines.append(_t("meta.restaurant.recipe_tooltip.ingredients", {"value": ingredients_text}))
	if not night_material_text.is_empty():
		lines.append(_t("meta.restaurant.recipe_tooltip.night", {"value": night_material_text}))
	if not synergy_text.is_empty():
		lines.append(synergy_text)
	if not unlocked:
		var unlock_text := _build_unlock_requirement_text("recipe", String(recipe.get("id", "")))
		if not unlock_text.is_empty():
			lines.append(_t("meta.restaurant.recipe_tooltip.unlock", {"value": unlock_text}))
	return "\n".join(lines)


static func _build_unlock_requirement_text(target_type: String, target_id: String) -> String:
	var normalized_target_type := target_type.strip_edges().to_lower()
	var normalized_target_id := target_id.strip_edges().to_lower()
	if normalized_target_type.is_empty() or normalized_target_id.is_empty() or DataRegistry == null:
		return ""
	for unlock_variant in DataRegistry.get_meta_unlocks():
		if not (unlock_variant is Dictionary):
			continue
		var unlock: Dictionary = unlock_variant
		if String(unlock.get("target_type", "")).strip_edges().to_lower() != normalized_target_type:
			continue
		if String(unlock.get("target_id", "")).strip_edges().to_lower() != normalized_target_id:
			continue
		var requirement_text := _build_material_bundle_text(unlock.get("requirements", {}))
		var unlock_name := String(unlock.get("name", "")).strip_edges()
		if unlock_name.is_empty():
			return requirement_text
		if requirement_text.is_empty():
			return unlock_name
		return "%s · %s" % [unlock_name, requirement_text]
	return ""


static func _build_night_material_text(recipe: Dictionary) -> String:
	var material_ids: Array[String] = []
	var ingredients_variant: Variant = recipe.get("ingredients", {})
	if ingredients_variant is Dictionary:
		for material_id_variant in (ingredients_variant as Dictionary).keys():
			var material_id := String(material_id_variant).strip_edges().to_lower()
			if material_id.is_empty() or material_ids.has(material_id) or not _material_is_night_only(material_id):
				continue
			material_ids.append(material_id)
	var synergy_variant: Variant = recipe.get("night_material_synergy", {})
	if synergy_variant is Dictionary:
		var synergy_material_id := String((synergy_variant as Dictionary).get("material_id", "")).strip_edges().to_lower()
		if not synergy_material_id.is_empty() and not material_ids.has(synergy_material_id) and _material_is_night_only(synergy_material_id):
			material_ids.append(synergy_material_id)
	var names: Array[String] = []
	for material_id in material_ids:
		names.append(_material_name(material_id))
	return ", ".join(names)


static func _material_is_night_only(material_id: String) -> bool:
	if DataRegistry == null or not DataRegistry.has_method("get_special_ingredient"):
		return false
	var ingredient := DataRegistry.get_special_ingredient(material_id)
	return not ingredient.is_empty() and bool(ingredient.get("night_only", false))


static func _build_servings_text(craftable_servings: int) -> String:
	return "Ready for %d servings" % maxi(0, craftable_servings)


static func _material_name(material_id: String) -> String:
	var normalized_id := material_id.strip_edges().to_lower()
	if normalized_id.is_empty():
		return ""
	if DataRegistry != null and DataRegistry.has_method("get_material_display_name"):
		var display_name := String(DataRegistry.call("get_material_display_name", normalized_id))
		if not display_name.is_empty():
			return display_name
	return normalized_id.capitalize()


static func _t(key: String, args: Dictionary = {}) -> String:
	if Localization == null or not Localization.has_method("t"):
		return key
	return String(Localization.call("t", key, args))


static func _normalize_string_array(source: Variant) -> Array[String]:
	var output: Array[String] = []
	if not (source is Array):
		return output
	for item in (source as Array):
		var text := String(item).strip_edges().to_lower()
		if text.is_empty() or output.has(text):
			continue
		output.append(text)
	return output
