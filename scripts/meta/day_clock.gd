extends RefCounted
class_name DayClock

const PHASE_MORNING := "morning"
const PHASE_NOON := "noon"
const PHASE_AFTERNOON := "afternoon"
const PHASE_EVENING := "evening"
const PHASE_NIGHT := "night"

const DEFAULT_MAX_ACTION_BUDGET := 5
const EVENING_ACTION_THRESHOLD := 3


static func normalize_phase(value: String) -> String:
	var normalized := value.strip_edges().to_lower()
	match normalized:
		PHASE_MORNING, PHASE_NOON, PHASE_AFTERNOON, PHASE_EVENING, PHASE_NIGHT:
			return normalized
		"day":
			return PHASE_MORNING
		_:
			return PHASE_MORNING


static func phase_from_action_budget(action_budget: int, max_action_budget: int = DEFAULT_MAX_ACTION_BUDGET) -> String:
	var clamped_max := maxi(1, max_action_budget)
	var remaining := clampi(action_budget, 0, clamped_max)
	var spent := clamped_max - remaining
	if spent >= EVENING_ACTION_THRESHOLD:
		return PHASE_EVENING
	if spent >= 2:
		return PHASE_AFTERNOON
	if spent >= 1:
		return PHASE_NOON
	return PHASE_MORNING


static func default_action_budget_for_phase(phase: String, max_action_budget: int = DEFAULT_MAX_ACTION_BUDGET) -> int:
	var clamped_max := maxi(1, max_action_budget)
	match normalize_phase(phase):
		PHASE_NIGHT:
			return 0
		PHASE_EVENING:
			return maxi(0, clamped_max - EVENING_ACTION_THRESHOLD)
		PHASE_AFTERNOON:
			return maxi(0, clamped_max - 2)
		PHASE_NOON:
			return maxi(0, clamped_max - 1)
		_:
			return clamped_max


static func actions_until_evening(action_budget: int, max_action_budget: int = DEFAULT_MAX_ACTION_BUDGET) -> int:
	var clamped_max := maxi(1, max_action_budget)
	var remaining := clampi(action_budget, 0, clamped_max)
	var spent := clamped_max - remaining
	return maxi(0, EVENING_ACTION_THRESHOLD - spent)


static func can_launch_night(phase: String) -> bool:
	var normalized := normalize_phase(phase)
	return normalized == PHASE_EVENING or normalized == PHASE_NIGHT
