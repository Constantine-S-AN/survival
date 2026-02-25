extends RefCounted
class_name WeaponPartsRegistry

const PARTS_DIR := "res://assets/textures/pixel/weapons/parts/"
const FALLBACK_ID := "needle_rifle"
const PART_KEYS: Array[String] = ["base", "muzzle", "core"]

static var _parts_cache: Dictionary = {}


static func get_weapon_parts(weapon_id: String) -> Dictionary:
	var key := weapon_id.strip_edges().to_lower()
	if key.is_empty():
		return {}
	if _parts_cache.has(key):
		var cached_variant: Variant = _parts_cache[key]
		if cached_variant is Dictionary:
			return (cached_variant as Dictionary).duplicate(true)

	var resolved := _load_parts_for_id(key)
	if resolved.is_empty() and key != FALLBACK_ID:
		resolved = _load_parts_for_id(FALLBACK_ID)
	_parts_cache[key] = resolved.duplicate(true)
	return resolved.duplicate(true)


static func _load_parts_for_id(weapon_id: String) -> Dictionary:
	var out: Dictionary = {}
	for part_key in PART_KEYS:
		var path := "%s%s_%s.png" % [PARTS_DIR, weapon_id, part_key]
		if not ResourceLoader.exists(path, "Texture2D"):
			continue
		var resource := load(path)
		if resource is Texture2D:
			out[part_key] = resource
	return out
