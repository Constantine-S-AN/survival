extends RefCounted
class_name DayState

const PHASE_DAY := "day"
const PHASE_NIGHT := "night"

var current_day: int = 1
var current_phase: String = PHASE_DAY
var stamina: int = 3
var max_stamina: int = 3
var pending_night_gold_bonus: int = 0
var pending_night_material_bonus: int = 0


static func from_dict(source: Dictionary) -> DayState:
	var state := DayState.new()
	state.current_day = maxi(1, int(source.get("current_day", 1)))
	state.current_phase = _normalize_phase(String(source.get("current_phase", PHASE_DAY)))
	state.max_stamina = maxi(1, int(source.get("max_stamina", 3)))
	state.stamina = clampi(int(source.get("stamina", state.max_stamina)), 0, state.max_stamina)
	state.pending_night_gold_bonus = maxi(0, int(source.get("pending_night_gold_bonus", 0)))
	state.pending_night_material_bonus = maxi(0, int(source.get("pending_night_material_bonus", 0)))
	return state


func to_dict() -> Dictionary:
	return {
		"current_day": current_day,
		"current_phase": _normalize_phase(current_phase),
		"stamina": clampi(stamina, 0, max_stamina),
		"max_stamina": max_stamina,
		"pending_night_gold_bonus": maxi(0, pending_night_gold_bonus),
		"pending_night_material_bonus": maxi(0, pending_night_material_bonus)
	}


func can_spend_stamina(cost: int = 1) -> bool:
	return cost >= 0 and stamina >= cost


func spend_stamina(cost: int = 1) -> bool:
	if not can_spend_stamina(cost):
		return false
	stamina -= cost
	return true


func add_night_gold_bonus(amount: int) -> void:
	pending_night_gold_bonus = maxi(0, pending_night_gold_bonus + amount)


func add_night_material_bonus(amount: int) -> void:
	pending_night_material_bonus = maxi(0, pending_night_material_bonus + amount)


func begin_night() -> void:
	current_phase = PHASE_NIGHT


func begin_next_day() -> void:
	current_day += 1
	current_phase = PHASE_DAY
	stamina = max_stamina
	pending_night_gold_bonus = 0
	pending_night_material_bonus = 0


static func _normalize_phase(value: String) -> String:
	var normalized := value.strip_edges().to_lower()
	if normalized == PHASE_NIGHT:
		return PHASE_NIGHT
	return PHASE_DAY
