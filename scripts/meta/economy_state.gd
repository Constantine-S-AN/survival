extends RefCounted
class_name EconomyState

var gold: int = 0
var restaurant_reputation: int = 1
var sold_dishes_stats: Dictionary = {}


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
	return economy


func to_dict() -> Dictionary:
	return {
		"gold": maxi(0, gold),
		"restaurant_reputation": clampi(restaurant_reputation, 0, 20),
		"sold_dishes_stats": sold_dishes_stats.duplicate(true)
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


func get_dish_sales(dish_id: String) -> int:
	var normalized_id := dish_id.strip_edges().to_lower()
	if normalized_id.is_empty():
		return 0
	return maxi(0, int(sold_dishes_stats.get(normalized_id, 0)))
