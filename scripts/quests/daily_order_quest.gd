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


func _get_safe_target_amount() -> int:
	return maxi(1, target_amount)
