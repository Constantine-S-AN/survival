extends Quest
class_name DailyOrderQuest

const ORDER_TYPE_DISH_SALES := "dish_sales"
const ORDER_TYPE_MATERIAL_GAIN := "material_gain"
const PILLAR_FARM := "farm"
const PILLAR_RESTAURANT := "restaurant"
const PILLAR_NIGHT := "night"

@export_enum("dish_sales", "material_gain") var order_type: String = ORDER_TYPE_MATERIAL_GAIN
@export_enum("farm", "restaurant", "night") var pillar: String = PILLAR_FARM
@export var target_id: String = ""
@export var target_amount: int = 1
@export var reward_gold: int = 0
@export var reward_reputation: int = 0
@export var reward_material_id: String = ""
@export var reward_material_amount: int = 0
@export var reward_seed_id: String = ""
@export var featured_from_day: int = 0
@export var featured_to_day: int = 0
@export var featured_priority: int = 0

var current_amount: int = 0
var assigned_day: int = 0


func start(args: Dictionary = {}) -> void:
	assigned_day = maxi(0, int(args.get("assigned_day", assigned_day)))
	current_amount = clampi(int(args.get("current_amount", current_amount)), 0, _get_safe_target_amount())
	objective_completed = current_amount >= _get_safe_target_amount()
	super.start(args)


func update(args: Dictionary = {}) -> void:
	if args.has("current_amount"):
		current_amount = clampi(int(args.get("current_amount", current_amount)), 0, _get_safe_target_amount())
	else:
		current_amount = clampi(current_amount + maxi(0, int(args.get("delta", 0))), 0, _get_safe_target_amount())
	objective_completed = current_amount >= _get_safe_target_amount()
	super.update(args)


func get_progress_text() -> String:
	return "%d/%d" % [current_amount, _get_safe_target_amount()]


func get_safe_target_id() -> String:
	return target_id.strip_edges().to_lower()


func get_pillar_title() -> String:
	match pillar:
		PILLAR_FARM:
			return "Farm"
		PILLAR_RESTAURANT:
			return "Restaurant"
		PILLAR_NIGHT:
			return "Night Run"
	return "Orders"


func get_reward_config() -> Dictionary:
	var reward := {
		"gold": maxi(0, reward_gold),
		"reputation": maxi(0, reward_reputation),
		"materials": {},
		"seed_ids": []
	}
	var material_id := reward_material_id.strip_edges().to_lower()
	if not material_id.is_empty() and reward_material_amount > 0:
		reward["materials"] = {
			material_id: maxi(0, reward_material_amount)
		}
	var seed_id := reward_seed_id.strip_edges().to_lower()
	if not seed_id.is_empty():
		reward["seed_ids"] = [seed_id]
	return reward


func is_featured_on_day(day: int) -> bool:
	if featured_priority <= 0:
		return false
	var safe_day := maxi(1, day)
	if featured_from_day > 0 and safe_day < featured_from_day:
		return false
	if featured_to_day > 0 and safe_day > featured_to_day:
		return false
	return true


func get_featured_priority_for_day(day: int) -> int:
	return featured_priority if is_featured_on_day(day) else 0


func _get_safe_target_amount() -> int:
	return maxi(1, target_amount)
