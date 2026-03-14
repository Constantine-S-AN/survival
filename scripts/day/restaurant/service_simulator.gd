extends RefCounted
class_name ServiceSimulator

const DEFAULT_UPGRADE_BONUSES := {
	"demand_bonus": 0.0,
	"capacity_bonus": 0,
	"satisfaction_bonus": 0.0,
	"special_slots": 0
}
const MenuPlannerClass := preload("res://scripts/day/restaurant/menu_planner.gd")


static func simulate_service(context: Dictionary) -> Dictionary:
	var menu_variant: Variant = context.get("menu_recipes", [])
	var menu_recipes: Array = menu_variant if menu_variant is Array else []
	if menu_recipes.is_empty():
		return {
			"ok": false,
			"error": "no_menu"
		}

	var materials_variant: Variant = context.get("inventory_materials", {})
	var materials: Dictionary = (materials_variant as Dictionary).duplicate(true) if materials_variant is Dictionary else {}
	var upgrade_bonuses := _sum_upgrade_bonuses(context.get("upgrades", []))
	var prepared_entries: Array[Dictionary] = []
	var category_lookup: Dictionary = {}
	var total_price := 0.0
	var total_complexity := 0.0
	var total_desirability := 0.0

	for recipe_variant in menu_recipes:
		if not (recipe_variant is Dictionary):
			continue
		var recipe: Dictionary = recipe_variant
		var craftable_servings: int = MenuPlannerClass.max_servings(recipe, materials)
		if craftable_servings <= 0:
			continue
		var desirability := _recipe_desirability(recipe, materials)
		var entry := {
			"recipe": recipe,
			"max_servings": craftable_servings,
			"desirability": desirability
		}
		prepared_entries.append(entry)
		total_price += float(recipe.get("base_price", 0))
		total_complexity += float(recipe.get("prep_complexity", 1))
		total_desirability += desirability
		var tags_variant: Variant = recipe.get("category_tags", [])
		if tags_variant is Array:
			for tag_variant in tags_variant:
				var tag := String(tag_variant).strip_edges().to_lower()
				if tag.is_empty():
					continue
				category_lookup[tag] = true

	if prepared_entries.is_empty():
		return {
			"ok": false,
			"error": "insufficient_ingredients"
		}

	var day := maxi(1, int(context.get("day", 1)))
	var reputation := clampi(int(context.get("reputation", 1)), 0, 20)
	var menu_size := prepared_entries.size()
	var special_recipe_count := _count_special_menu_entries(prepared_entries)
	var special_slots := maxi(0, int(upgrade_bonuses.get("special_slots", 0)))
	var active_special_slots := mini(special_slots, special_recipe_count)
	var average_price := total_price / float(menu_size)
	var average_complexity := total_complexity / float(menu_size)
	var average_desirability := total_desirability / float(menu_size)
	var variety_bonus := clampf(maxf(0.0, float(category_lookup.size() - 1)) * 0.07, 0.0, 0.21)
	var reputation_factor := 0.92 + float(reputation) * 0.035
	var price_target := 10.0 + float(reputation) * 0.8
	var price_factor := clampf(1.08 - maxf(0.0, average_price - price_target) * 0.035, 0.72, 1.12)
	var menu_attractiveness := clampf(
		average_desirability
		+ variety_bonus
		+ float(upgrade_bonuses.get("demand_bonus", 0.0))
		+ float(active_special_slots) * 0.12,
		0.75,
		1.95
	)
	var expected_customers := maxi(
		4,
		int(round((6.0 + float(day) + float(reputation) * 1.2 + float(menu_size)) * menu_attractiveness * price_factor * reputation_factor))
	)
	var service_capacity := maxi(
		3,
		int(round(8.0 + float(reputation) * 1.4 + float(menu_size) * 3.0 - average_complexity * 2.0 + int(upgrade_bonuses.get("capacity_bonus", 0))))
	)
	var served_customers_target := mini(expected_customers, service_capacity)
	var allocation := _allocate_orders(prepared_entries, served_customers_target, materials)
	var sold_dishes_variant: Variant = allocation.get("sold_dishes", {})
	var sold_dishes: Dictionary = sold_dishes_variant if sold_dishes_variant is Dictionary else {}
	var ingredients_consumed_variant: Variant = allocation.get("ingredients_consumed", {})
	var ingredients_consumed: Dictionary = ingredients_consumed_variant if ingredients_consumed_variant is Dictionary else {}
	var served_customers := _count_total_dishes_sold(sold_dishes)
	var synergy_consumed: Dictionary = {}
	var synergy_feedback: Array[String] = []
	var revenue := 0
	var synergy_revenue_bonus := 0
	var synergy_satisfaction_bonus := 0.0

	for entry in prepared_entries:
		var recipe: Dictionary = entry.get("recipe", {})
		var recipe_id := String(recipe.get("id", "")).strip_edges().to_lower()
		var sold_count := maxi(0, int(sold_dishes.get(recipe_id, 0)))
		if sold_count <= 0:
			continue
		revenue += sold_count * int(recipe.get("base_price", 0))

		var synergy_variant: Variant = recipe.get("night_material_synergy", {})
		if not (synergy_variant is Dictionary):
			continue
		var synergy: Dictionary = synergy_variant
		if synergy.is_empty():
			continue
		var synergy_material_id := String(synergy.get("material_id", "")).strip_edges().to_lower()
		if synergy_material_id.is_empty():
			continue
		var committed_amount := maxi(0, int(ingredients_consumed.get(synergy_material_id, 0))) + maxi(0, int(synergy_consumed.get(synergy_material_id, 0)))
		var available_synergy_amount := maxi(0, int(materials.get(synergy_material_id, 0))) - committed_amount
		if available_synergy_amount <= 0:
			continue
		var synergy_servings := mini(available_synergy_amount, sold_count)
		synergy_servings = mini(synergy_servings, maxi(0, int(synergy.get("max_bonus_servings", sold_count))))
		if synergy_servings <= 0:
			continue
		synergy_consumed[synergy_material_id] = maxi(0, int(synergy_consumed.get(synergy_material_id, 0))) + synergy_servings
		synergy_revenue_bonus += synergy_servings * maxi(0, int(synergy.get("extra_price", 0)))
		synergy_satisfaction_bonus += float(synergy.get("satisfaction_bonus", 0.0))
		var synergy_feedback_text := String(synergy.get("feedback", "")).strip_edges()
		if not synergy_feedback_text.is_empty() and not synergy_feedback.has(synergy_feedback_text):
			synergy_feedback.append(synergy_feedback_text)

	revenue += synergy_revenue_bonus
	var capacity_pressure := 0.0
	if expected_customers > service_capacity:
		capacity_pressure = float(expected_customers - service_capacity) / float(maxi(1, expected_customers))
	var prep_pressure := average_complexity * float(served_customers) / maxf(1.0, float(service_capacity * 2))
	var satisfaction := clampf(
		0.60 +
			variety_bonus * 0.40 +
			(menu_attractiveness - 1.0) * 0.25 +
			float(reputation) * 0.02 +
			float(upgrade_bonuses.get("satisfaction_bonus", 0.0)) +
			float(active_special_slots) * 0.035 +
			synergy_satisfaction_bonus -
			capacity_pressure * 0.18 -
			maxf(0.0, prep_pressure - 1.0) * 0.16 -
			maxf(0.0, 1.0 - price_factor) * 0.14,
		0.45,
		0.98
	)
	var tips := int(round(maxf(0.0, satisfaction - 0.72) * float(revenue) * 0.10))
	revenue += tips
	var reputation_delta := _reputation_delta(satisfaction, served_customers, expected_customers)
	var feedback_tags := _build_feedback_tags(
		variety_bonus,
		price_factor,
		capacity_pressure,
		satisfaction,
		synergy_feedback,
		active_special_slots
	)

	for material_id_variant in synergy_consumed.keys():
		ingredients_consumed[String(material_id_variant)] = maxi(0, int(ingredients_consumed.get(material_id_variant, 0))) + int(synergy_consumed.get(material_id_variant, 0))
	var headline_key := _build_headline_key(revenue, satisfaction, capacity_pressure)

	return {
		"ok": true,
		"served_day": day,
		"menu_size": menu_size,
		"menu_attractiveness": menu_attractiveness,
		"price_factor": price_factor,
		"expected_customers": expected_customers,
		"served_customers": served_customers,
		"service_capacity": service_capacity,
		"revenue": revenue,
		"tips": tips,
		"reputation_delta": reputation_delta,
		"satisfaction_pct": int(round(satisfaction * 100.0)),
		"sold_dishes": sold_dishes,
		"ingredients_consumed": ingredients_consumed,
		"feedback_tags": feedback_tags,
		"synergy_feedback": synergy_feedback,
		"specials_featured": active_special_slots,
		"headline": headline_key,
		"headline_key": headline_key,
		"price_target": price_target
	}


static func _recipe_desirability(recipe: Dictionary, materials: Dictionary) -> float:
	var desirability := 0.88 + float(recipe.get("base_price", 0)) * 0.035 - float(recipe.get("prep_complexity", 1)) * 0.08
	var tags_variant: Variant = recipe.get("category_tags", [])
	if tags_variant is Array:
		desirability += clampf(float((tags_variant as Array).size()) * 0.03, 0.0, 0.12)
	var synergy_variant: Variant = recipe.get("night_material_synergy", {})
	if synergy_variant is Dictionary:
		var synergy: Dictionary = synergy_variant
		var material_id := String(synergy.get("material_id", "")).strip_edges().to_lower()
		if not material_id.is_empty() and int(materials.get(material_id, 0)) > 0:
			desirability += float(synergy.get("demand_bonus", 0.0))
	return clampf(desirability, 0.65, 1.75)


static func _allocate_orders(entries: Array[Dictionary], served_customers: int, materials: Dictionary) -> Dictionary:
	var sold_dishes: Dictionary = {}
	var ingredients_consumed: Dictionary = {}
	var available_materials: Dictionary = materials.duplicate(true)
	for entry in entries:
		var recipe: Dictionary = entry.get("recipe", {})
		var recipe_id := String(recipe.get("id", "")).strip_edges().to_lower()
		if recipe_id.is_empty():
			continue
		sold_dishes[recipe_id] = 0
	var remaining_customers := maxi(0, served_customers)
	while remaining_customers > 0:
		var best_index := -1
		var best_score := -1000000.0
		for entry_index in range(entries.size()):
			var entry: Dictionary = entries[entry_index]
			var recipe: Dictionary = entry.get("recipe", {})
			var recipe_id := String(recipe.get("id", "")).strip_edges().to_lower()
			if recipe_id.is_empty() or not _bundle_fits_inventory(recipe.get("ingredients", {}), available_materials):
				continue
			var remaining_servings := MenuPlannerClass.max_servings(recipe, available_materials)
			if remaining_servings <= 0:
				continue
			var score := float(entry.get("desirability", 1.0)) - float(int(sold_dishes.get(recipe_id, 0))) * 0.08 + float(remaining_servings) * 0.015
			if score > best_score:
				best_score = score
				best_index = entry_index
		if best_index < 0:
			break
		var best_entry: Dictionary = entries[best_index]
		var best_recipe: Dictionary = best_entry.get("recipe", {})
		var best_recipe_id := String(best_recipe.get("id", "")).strip_edges().to_lower()
		_remove_bundle_from_inventory(available_materials, best_recipe.get("ingredients", {}))
		_consume_bundle(ingredients_consumed, best_recipe.get("ingredients", {}), 1)
		sold_dishes[best_recipe_id] = maxi(0, int(sold_dishes.get(best_recipe_id, 0))) + 1
		remaining_customers -= 1
	return {
		"sold_dishes": sold_dishes,
		"ingredients_consumed": ingredients_consumed
	}


static func _bundle_fits_inventory(bundle_variant: Variant, materials: Dictionary, multiplier: int = 1) -> bool:
	if not (bundle_variant is Dictionary) or multiplier <= 0:
		return false
	var bundle: Dictionary = bundle_variant
	for material_id_variant in bundle.keys():
		var material_id := String(material_id_variant).strip_edges().to_lower()
		if material_id.is_empty():
			continue
		var required_amount := maxi(0, int(bundle.get(material_id_variant, 0))) * multiplier
		if required_amount <= 0:
			continue
		if maxi(0, int(materials.get(material_id, 0))) < required_amount:
			return false
	return true


static func _remove_bundle_from_inventory(materials: Dictionary, bundle_variant: Variant, multiplier: int = 1) -> void:
	if not (bundle_variant is Dictionary) or multiplier <= 0:
		return
	var bundle: Dictionary = bundle_variant
	for material_id_variant in bundle.keys():
		var material_id := String(material_id_variant).strip_edges().to_lower()
		if material_id.is_empty():
			continue
		var required_amount := maxi(0, int(bundle.get(material_id_variant, 0))) * multiplier
		if required_amount <= 0:
			continue
		materials[material_id] = maxi(0, int(materials.get(material_id, 0))) - required_amount


static func _count_total_dishes_sold(sold_dishes: Dictionary) -> int:
	var total := 0
	for recipe_id_variant in sold_dishes.keys():
		total += maxi(0, int(sold_dishes.get(recipe_id_variant, 0)))
	return total


static func _consume_bundle(target_bundle: Dictionary, bundle_variant: Variant, multiplier: int = 1) -> void:
	if not (bundle_variant is Dictionary) or multiplier <= 0:
		return
	var bundle: Dictionary = bundle_variant
	for material_id_variant in bundle.keys():
		var material_id := String(material_id_variant).strip_edges().to_lower()
		if material_id.is_empty():
			continue
		target_bundle[material_id] = maxi(0, int(target_bundle.get(material_id, 0))) + maxi(0, int(bundle.get(material_id_variant, 0))) * multiplier


static func _count_special_menu_entries(entries: Array[Dictionary]) -> int:
	var count := 0
	for entry in entries:
		var recipe: Dictionary = entry.get("recipe", {})
		if _recipe_uses_night_specials(recipe):
			count += 1
	return count


static func _recipe_uses_night_specials(recipe: Dictionary) -> bool:
	var ingredients_variant: Variant = recipe.get("ingredients", {})
	if ingredients_variant is Dictionary:
		for material_id_variant in (ingredients_variant as Dictionary).keys():
			var material_id := String(material_id_variant).strip_edges().to_lower()
			if material_id.is_empty():
				continue
			if MenuPlannerClass._material_is_night_only(material_id):
				return true
	var synergy_variant: Variant = recipe.get("night_material_synergy", {})
	if synergy_variant is Dictionary:
		var synergy_material_id := String((synergy_variant as Dictionary).get("material_id", "")).strip_edges().to_lower()
		if not synergy_material_id.is_empty() and MenuPlannerClass._material_is_night_only(synergy_material_id):
			return true
	return false


static func _reputation_delta(satisfaction: float, served_customers: int, expected_customers: int) -> int:
	var delta := 0
	if satisfaction >= 0.84:
		delta += 2
	elif satisfaction >= 0.72:
		delta += 1
	elif satisfaction < 0.56:
		delta -= 1
	if served_customers < int(round(float(expected_customers) * 0.5)):
		delta -= 1
	return clampi(delta, -2, 3)


static func _build_feedback_tags(
	variety_bonus: float,
	price_factor: float,
	capacity_pressure: float,
	satisfaction: float,
	synergy_feedback: Array[String],
	specials_featured: int = 0
) -> Array[String]:
	var tags: Array[String] = []
	if variety_bonus >= 0.10:
		tags.append("variety_good")
	if price_factor >= 1.0:
		tags.append("price_good")
	elif price_factor < 0.88:
		tags.append("price_high")
	if capacity_pressure >= 0.18:
		tags.append("capacity_strained")
	else:
		tags.append("capacity_steady")
	if satisfaction >= 0.82:
		tags.append("satisfaction_high")
	elif satisfaction < 0.60:
		tags.append("satisfaction_low")
	if not synergy_feedback.is_empty():
		tags.append("synergy_used")
	if specials_featured > 0:
		tags.append("specials_featured")
	return tags


static func _build_headline_key(revenue: int, satisfaction: float, capacity_pressure: float) -> String:
	if revenue >= 40 and satisfaction >= 0.82:
		return "meta.restaurant.headline_packed"
	if revenue >= 24 and capacity_pressure < 0.18:
		return "meta.restaurant.headline_steady"
	return "meta.restaurant.headline_quiet"


static func _sum_upgrade_bonuses(upgrades_variant: Variant) -> Dictionary:
	var bonuses := DEFAULT_UPGRADE_BONUSES.duplicate(true)
	if not (upgrades_variant is Array):
		return bonuses
	for upgrade_variant in (upgrades_variant as Array):
		if not (upgrade_variant is Dictionary):
			continue
		var upgrade: Dictionary = upgrade_variant
		var effects_variant: Variant = upgrade.get("effects", {})
		if not (effects_variant is Dictionary):
			continue
		var effects: Dictionary = effects_variant
		bonuses["demand_bonus"] = float(bonuses.get("demand_bonus", 0.0)) + float(effects.get("demand_bonus", 0.0))
		bonuses["capacity_bonus"] = int(bonuses.get("capacity_bonus", 0)) + int(effects.get("capacity_bonus", 0))
		bonuses["satisfaction_bonus"] = float(bonuses.get("satisfaction_bonus", 0.0)) + float(effects.get("satisfaction_bonus", 0.0))
		bonuses["special_slots"] = int(bonuses.get("special_slots", 0)) + int(effects.get("special_slots", 0))
	return bonuses
