extends RefCounted
class_name EconomyState

var gold: int = 0


static func from_dict(source: Dictionary) -> EconomyState:
	var economy := EconomyState.new()
	economy.gold = maxi(0, int(source.get("gold", 0)))
	return economy


func to_dict() -> Dictionary:
	return {
		"gold": maxi(0, gold)
	}


func add_gold(amount: int) -> void:
	gold = maxi(0, gold + amount)


func spend_gold(amount: int) -> bool:
	if amount < 0 or gold < amount:
		return false
	gold -= amount
	return true
