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
		var craftable_servings := max_servings(recipe, materials)
		var ingredients_text := _build_material_bundle_text(recipe.get("ingredients", {}))
		var tag_text := _build_tag_text(recipe.get("category_tags", []))
		var synergy_text := _build_synergy_text(recipe)
		var label := "%s\n$%d · Prep %d · %s\n%s" % [
			String(recipe.get("name", recipe_id.capitalize())),
			int(recipe.get("base_price", 0)),
			int(recipe.get("prep_complexity", 1)),
			_build_servings_text(craftable_servings),
			ingredients_text
		]
		if not tag_text.is_empty():
			label += "\n%s" % tag_text
		if not synergy_text.is_empty():
			label += "\n%s" % synergy_text
		cards.append({
			"id": recipe_id,
			"label": label,
			"selected": selected_lookup.has(recipe_id),
			"enabled": unlocked_lookup.has(recipe_id),
			"craftable_servings": craftable_servings
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
