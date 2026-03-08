extends RefCounted
class_name DayState

const DayClockClass := preload("res://scripts/meta/day_clock.gd")

const PHASE_MORNING := DayClockClass.PHASE_MORNING
const PHASE_NOON := DayClockClass.PHASE_NOON
const PHASE_AFTERNOON := DayClockClass.PHASE_AFTERNOON
const PHASE_EVENING := DayClockClass.PHASE_EVENING
const PHASE_NIGHT := DayClockClass.PHASE_NIGHT

var current_day: int = 1
var current_phase: String = PHASE_MORNING
var stamina: int = 6
var max_stamina: int = 6
var action_budget: int = DayClockClass.DEFAULT_MAX_ACTION_BUDGET
var max_action_budget: int = DayClockClass.DEFAULT_MAX_ACTION_BUDGET
var pending_night_gold_bonus: int = 0
var pending_night_material_bonus: int = 0
var pending_next_day_stamina_penalty: int = 0


static func from_dict(source: Dictionary):
	var state = load("res://scripts/meta/day_state.gd").new()
	state.current_day = maxi(1, int(source.get("current_day", 1)))
	state.current_phase = _normalize_phase(String(source.get("current_phase", PHASE_MORNING)))
	state.max_stamina = maxi(1, int(source.get("max_stamina", 6)))
	state.stamina = clampi(int(source.get("stamina", state.max_stamina)), 0, state.max_stamina)
	state.max_action_budget = maxi(1, int(source.get("max_action_budget", DayClockClass.DEFAULT_MAX_ACTION_BUDGET)))
	var default_action_budget := DayClockClass.default_action_budget_for_phase(state.current_phase, state.max_action_budget)
	state.action_budget = clampi(int(source.get("action_budget", default_action_budget)), 0, state.max_action_budget)
	if state.current_phase != PHASE_NIGHT:
		state._refresh_day_phase()
	state.pending_night_gold_bonus = maxi(0, int(source.get("pending_night_gold_bonus", 0)))
	state.pending_night_material_bonus = maxi(0, int(source.get("pending_night_material_bonus", 0)))
	state.pending_next_day_stamina_penalty = maxi(0, int(source.get("pending_next_day_stamina_penalty", 0)))
	return state


func to_dict() -> Dictionary:
	return {
		"current_day": current_day,
		"current_phase": _normalize_phase(current_phase),
		"stamina": clampi(stamina, 0, max_stamina),
		"max_stamina": max_stamina,
		"action_budget": clampi(action_budget, 0, max_action_budget),
		"max_action_budget": max_action_budget,
		"pending_night_gold_bonus": maxi(0, pending_night_gold_bonus),
		"pending_night_material_bonus": maxi(0, pending_night_material_bonus),
		"pending_next_day_stamina_penalty": maxi(0, pending_next_day_stamina_penalty)
	}


func can_spend_stamina(cost: int = 1) -> bool:
	return cost >= 0 and stamina >= cost


func spend_stamina(cost: int = 1) -> bool:
	if not can_spend_stamina(cost):
		return false
	stamina -= cost
	return true


func can_spend_action_budget(cost: int = 1) -> bool:
	return current_phase != PHASE_NIGHT and cost >= 0 and action_budget >= cost


func spend_action_budget(cost: int = 1) -> bool:
	if not can_spend_action_budget(cost):
		return false
	action_budget -= cost
	_refresh_day_phase()
	return true


func can_take_daytime_action(stamina_cost: int = 0, action_cost: int = 1) -> bool:
	return can_spend_action_budget(action_cost) and can_spend_stamina(stamina_cost)


func spend_daytime_action(stamina_cost: int = 0, action_cost: int = 1) -> bool:
	if not can_take_daytime_action(stamina_cost, action_cost):
		return false
	if stamina_cost > 0:
		stamina -= stamina_cost
	if action_cost > 0:
		action_budget -= action_cost
	_refresh_day_phase()
	return true


func actions_until_evening() -> int:
	if current_phase == PHASE_NIGHT:
		return 0
	return DayClockClass.actions_until_evening(action_budget, max_action_budget)


func can_launch_night() -> bool:
	return DayClockClass.can_launch_night(current_phase)


func rest_until_evening() -> int:
	if current_phase == PHASE_NIGHT:
		return 0
	var cost := actions_until_evening()
	if cost <= 0:
		return 0
	action_budget = maxi(0, action_budget - cost)
	_refresh_day_phase()
	return cost


func add_night_gold_bonus(amount: int) -> void:
	pending_night_gold_bonus = maxi(0, pending_night_gold_bonus + amount)


func add_night_material_bonus(amount: int) -> void:
	pending_night_material_bonus = maxi(0, pending_night_material_bonus + amount)


func set_pending_next_day_stamina_penalty(amount: int) -> void:
	pending_next_day_stamina_penalty = clampi(amount, 0, max_stamina)


func preview_next_day_stamina() -> int:
	return clampi(max_stamina - pending_next_day_stamina_penalty, 0, max_stamina)


func begin_night() -> void:
	current_phase = PHASE_NIGHT


func begin_next_day() -> void:
	current_day += 1
	current_phase = PHASE_MORNING
	stamina = preview_next_day_stamina()
	action_budget = max_action_budget
	pending_night_gold_bonus = 0
	pending_night_material_bonus = 0
	pending_next_day_stamina_penalty = 0


func reset_daytime() -> void:
	action_budget = max_action_budget
	current_phase = PHASE_MORNING
	_refresh_day_phase()


static func _normalize_phase(value: String) -> String:
	return DayClockClass.normalize_phase(value)


func _refresh_day_phase() -> void:
	if current_phase == PHASE_NIGHT:
		return
	current_phase = DayClockClass.phase_from_action_budget(action_budget, max_action_budget)
