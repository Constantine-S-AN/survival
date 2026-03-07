extends RefCounted
class_name CropInstance

var crop_id: String = ""
var seed_id: String = ""
var planted_day: int = 1
var growth_days: int = 1
var growth_progress_days: int = 0
var watered_day: int = 0


static func from_dict(source: Dictionary) -> CropInstance:
	var instance := CropInstance.new()
	instance.crop_id = String(source.get("crop_id", "")).strip_edges().to_lower()
	instance.seed_id = String(source.get("seed_id", "")).strip_edges().to_lower()
	instance.planted_day = maxi(1, int(source.get("planted_day", 1)))
	instance.growth_days = maxi(1, int(source.get("growth_days", 1)))
	instance.growth_progress_days = maxi(0, int(source.get("growth_progress_days", 0)))
	instance.watered_day = maxi(0, int(source.get("watered_day", 0)))
	if instance.crop_id.is_empty() or instance.seed_id.is_empty():
		return CropInstance.new()
	return instance


static func planted(seed_id: String, crop_id: String, growth_days: int, current_day: int) -> CropInstance:
	var instance := CropInstance.new()
	instance.seed_id = seed_id.strip_edges().to_lower()
	instance.crop_id = crop_id.strip_edges().to_lower()
	instance.growth_days = maxi(1, growth_days)
	instance.planted_day = maxi(1, current_day)
	instance.growth_progress_days = 0
	instance.watered_day = 0
	return instance


func is_empty() -> bool:
	return crop_id.is_empty() or seed_id.is_empty()


func to_dict() -> Dictionary:
	if is_empty():
		return {}
	return {
		"crop_id": crop_id,
		"seed_id": seed_id,
		"planted_day": planted_day,
		"growth_days": growth_days,
		"growth_progress_days": growth_progress_days,
		"watered_day": watered_day
	}


func is_watered_on_day(current_day: int) -> bool:
	return watered_day == maxi(0, current_day)


func can_water(current_day: int) -> bool:
	return not is_empty() and not is_harvestable() and watered_day != maxi(0, current_day)


func mark_watered(current_day: int) -> void:
	if is_empty():
		return
	watered_day = maxi(0, current_day)


func advance_day(previous_day: int) -> void:
	if is_empty() or is_harvestable():
		return
	if watered_day == maxi(0, previous_day):
		growth_progress_days = mini(growth_days, growth_progress_days + 1)


func is_harvestable() -> bool:
	return not is_empty() and growth_progress_days >= growth_days


func get_progress_text() -> String:
	if is_empty():
		return ""
	return "%d/%d days" % [mini(growth_progress_days, growth_days), growth_days]
