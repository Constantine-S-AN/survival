extends RefCounted
class_name InventoryState

var materials: Dictionary = {}
var unlocked_seeds: Array[String] = []
var unlocked_recipes: Array[String] = []


static func from_dict(source: Dictionary) -> InventoryState:
	var inventory := InventoryState.new()
	var materials_variant: Variant = source.get("materials", {})
	if materials_variant is Dictionary:
		for material_key_variant in (materials_variant as Dictionary).keys():
			var material_id := String(material_key_variant).strip_edges().to_lower()
			if material_id.is_empty():
				continue
			inventory.materials[material_id] = maxi(0, int((materials_variant as Dictionary).get(material_key_variant, 0)))
	inventory.unlocked_seeds = _normalize_string_array(source.get("unlocked_seeds", []))
	inventory.unlocked_recipes = _normalize_string_array(source.get("unlocked_recipes", []))
	return inventory


func to_dict() -> Dictionary:
	return {
		"materials": materials.duplicate(true),
		"unlocked_seeds": unlocked_seeds.duplicate(),
		"unlocked_recipes": unlocked_recipes.duplicate()
	}


func get_material_amount(material_id: String) -> int:
	var key := material_id.strip_edges().to_lower()
	if key.is_empty():
		return 0
	return maxi(0, int(materials.get(key, 0)))


func add_material(material_id: String, amount: int) -> void:
	var key := material_id.strip_edges().to_lower()
	if key.is_empty() or amount <= 0:
		return
	materials[key] = get_material_amount(key) + amount


func remove_material(material_id: String, amount: int) -> bool:
	var key := material_id.strip_edges().to_lower()
	if key.is_empty() or amount < 0:
		return false
	if get_material_amount(key) < amount:
		return false
	materials[key] = get_material_amount(key) - amount
	return true


func has_seed(seed_id: String) -> bool:
	return unlocked_seeds.has(seed_id.strip_edges().to_lower())


func unlock_seed(seed_id: String) -> bool:
	var key := seed_id.strip_edges().to_lower()
	if key.is_empty() or unlocked_seeds.has(key):
		return false
	unlocked_seeds.append(key)
	return true


func has_recipe(recipe_id: String) -> bool:
	return unlocked_recipes.has(recipe_id.strip_edges().to_lower())


func unlock_recipe(recipe_id: String) -> bool:
	var key := recipe_id.strip_edges().to_lower()
	if key.is_empty() or unlocked_recipes.has(key):
		return false
	unlocked_recipes.append(key)
	return true


func build_material_summary() -> String:
	if materials.is_empty():
		return "-"
	var keys: Array[String] = []
	for key_variant in materials.keys():
		keys.append(String(key_variant))
	keys.sort()
	var parts: Array[String] = []
	for key in keys:
		parts.append("%s x%d" % [key.capitalize(), get_material_amount(key)])
	return ", ".join(parts)


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
