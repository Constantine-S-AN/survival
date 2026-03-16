extends RefCounted
class_name EconomyState

var gold: int = 0
var restaurant_reputation: int = 1
var sold_dishes_stats: Dictionary = {}
var last_route_resource_flow: Dictionary = {}
var last_material_use_rows: Array[Dictionary] = []
var last_night_feedback_rows: Array[Dictionary] = []


static func from_dict(source: Dictionary):
	var economy = load("res://scripts/meta/economy_state.gd").new()
	economy.gold = maxi(0, int(source.get("gold", 0)))
	economy.restaurant_reputation = clampi(int(source.get("restaurant_reputation", 1)), 0, 20)
	var sold_dishes_variant: Variant = source.get("sold_dishes_stats", {})
	if sold_dishes_variant is Dictionary:
		for dish_id_variant in (sold_dishes_variant as Dictionary).keys():
			var dish_id := String(dish_id_variant).strip_edges().to_lower()
			if dish_id.is_empty():
				continue
			economy.sold_dishes_stats[dish_id] = maxi(0, int((sold_dishes_variant as Dictionary).get(dish_id_variant, 0)))
	var route_flow_variant: Variant = source.get("last_route_resource_flow", {})
	economy.last_route_resource_flow = route_flow_variant.duplicate(true) if route_flow_variant is Dictionary else {}
	economy.last_material_use_rows = _normalize_dictionary_array(source.get("last_material_use_rows", []))
	economy.last_night_feedback_rows = _normalize_dictionary_array(source.get("last_night_feedback_rows", []))
	return economy


func to_dict() -> Dictionary:
	return {
		"gold": maxi(0, gold),
		"restaurant_reputation": clampi(restaurant_reputation, 0, 20),
		"sold_dishes_stats": sold_dishes_stats.duplicate(true),
		"last_route_resource_flow": last_route_resource_flow.duplicate(true),
		"last_material_use_rows": last_material_use_rows.duplicate(true),
		"last_night_feedback_rows": last_night_feedback_rows.duplicate(true)
	}


func add_gold(amount: int) -> void:
	gold = maxi(0, gold + amount)


func spend_gold(amount: int) -> bool:
	if amount < 0 or gold < amount:
		return false
	gold -= amount
	return true


func add_reputation(delta: int) -> void:
	restaurant_reputation = clampi(restaurant_reputation + delta, 0, 20)


func record_dish_sales(dish_id: String, count: int) -> void:
	var normalized_id := dish_id.strip_edges().to_lower()
	if normalized_id.is_empty() or count <= 0:
		return
	sold_dishes_stats[normalized_id] = maxi(0, int(sold_dishes_stats.get(normalized_id, 0))) + count


func record_route_resource_flow(flow: Dictionary) -> void:
	last_route_resource_flow = flow.duplicate(true)


func record_material_use_rows(rows: Array) -> void:
	last_material_use_rows = _normalize_dictionary_array(rows)


func record_night_feedback_rows(rows: Array) -> void:
	last_night_feedback_rows = _normalize_dictionary_array(rows)


func get_dish_sales(dish_id: String) -> int:
	var normalized_id := dish_id.strip_edges().to_lower()
	if normalized_id.is_empty():
		return 0
	return maxi(0, int(sold_dishes_stats.get(normalized_id, 0)))


static func _normalize_dictionary_array(source: Variant) -> Array[Dictionary]:
	var output: Array[Dictionary] = []
	if not (source is Array):
		return output
	for row_variant in (source as Array):
		if not (row_variant is Dictionary):
			continue
		output.append((row_variant as Dictionary).duplicate(true))
	return output
