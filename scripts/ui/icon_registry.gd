extends RefCounted
class_name IconRegistry

const _WEAPON_ICON_PATHS: Dictionary = {
	"needle_rifle": "res://assets/external/icons/tabler/target-arrow.svg",
	"burst_smg": "res://assets/external/icons/tabler/crosshair.svg",
	"silence_dart": "res://assets/external/icons/tabler/needle.svg",
	"shock_pulse": "res://assets/external/icons/tabler/wave-sine.svg",
	"abyss_mine": "res://assets/external/icons/tabler/bomb.svg",
	"tether_beam": "res://assets/external/icons/tabler/line-dashed.svg",
	"orbital_drone": "res://assets/external/icons/tabler/drone.svg",
	"sonar_blade": "res://assets/external/icons/tabler/sword.svg"
}

const _SKILL_ICON_PATHS: Dictionary = {
	"sonar": "res://assets/external/icons/tabler/radar-2.svg",
	"dash": "res://assets/external/icons/tabler/wind.svg"
}

const _TAG_ICON_PATHS: Dictionary = {
	"sonar": "res://assets/external/icons/tabler/radar-2.svg",
	"silence": "res://assets/external/icons/tabler/needle.svg",
	"speed": "res://assets/external/icons/tabler/wind.svg",
	"chain": "res://assets/external/icons/tabler/line-dashed.svg",
	"aoe": "res://assets/external/icons/tabler/wave-sine.svg",
	"control": "res://assets/external/icons/tabler/crosshair.svg",
	"summon": "res://assets/external/icons/tabler/drone.svg",
	"damage": "res://assets/external/icons/tabler/sword.svg",
	"pickup": "res://assets/external/icons/tabler/bomb.svg",
	"weapon": "res://assets/external/icons/tabler/target-arrow.svg",
	"crit": "res://assets/external/icons/tabler/crosshair.svg",
	"pierce": "res://assets/external/icons/tabler/needle.svg",
	"noise": "res://assets/external/icons/tabler/wave-sine.svg"
}

const _DEFAULT_ICON_PATH := "res://assets/external/icons/tabler/bolt.svg"

static var _texture_cache: Dictionary = {}


static func get_weapon_icon_path(weapon_id: String) -> String:
	var key := weapon_id.strip_edges().to_lower()
	return String(_WEAPON_ICON_PATHS.get(key, _DEFAULT_ICON_PATH))


static func get_skill_icon_path(skill_id: String) -> String:
	var key := skill_id.strip_edges().to_lower()
	return String(_SKILL_ICON_PATHS.get(key, _DEFAULT_ICON_PATH))


static func get_weapon_icon(weapon_id: String) -> Texture2D:
	return _load_texture(get_weapon_icon_path(weapon_id))


static func get_skill_icon(skill_id: String) -> Texture2D:
	return _load_texture(get_skill_icon_path(skill_id))


static func get_tag_icon_path(tag_id: String) -> String:
	var key := tag_id.strip_edges().to_lower()
	return String(_TAG_ICON_PATHS.get(key, _DEFAULT_ICON_PATH))


static func get_tag_icon(tag_id: String) -> Texture2D:
	return _load_texture(get_tag_icon_path(tag_id))


static func get_upgrade_icon(option: Dictionary) -> Texture2D:
	var icon_variant: Variant = option.get("icon_path", option.get("icon", ""))
	var explicit_path := String(icon_variant).strip_edges()
	if explicit_path.begins_with("res://"):
		var explicit_texture := _load_texture(explicit_path)
		if explicit_texture != null:
			return explicit_texture
	var tags_variant: Variant = option.get("tags", [])
	if tags_variant is Array:
		for tag_variant in (tags_variant as Array):
			var tag := String(tag_variant).strip_edges().to_lower()
			if tag.is_empty():
				continue
			return get_tag_icon(tag)
	return _load_texture(_DEFAULT_ICON_PATH)


static func _load_texture(path: String) -> Texture2D:
	if _texture_cache.has(path):
		var cached: Variant = _texture_cache[path]
		if cached is Texture2D:
			return cached
	if ResourceLoader.exists(path, "Texture2D"):
		var resource := load(path)
		if resource is Texture2D:
			_texture_cache[path] = resource
			return resource
	var generated := _build_fallback_texture(path)
	_texture_cache[path] = generated
	return generated


static func _build_fallback_texture(seed_text: String) -> Texture2D:
	var seed_hash: int = abs(seed_text.hash())
	var hue: float = float(seed_hash % 360) / 360.0
	var accent: Color = Color.from_hsv(hue, 0.65, 0.92, 1.0)
	var bg: Color = Color.from_hsv(hue, 0.42, 0.18, 1.0)
	var img := Image.create(48, 48, false, Image.FORMAT_RGBA8)
	img.fill(bg)
	for x in range(48):
		for y in range(48):
			if x <= 1 or y <= 1 or x >= 46 or y >= 46:
				img.set_pixel(x, y, accent)
	for i in range(8, 40):
		img.set_pixel(i, 24, accent)
		img.set_pixel(24, i, accent)
	return ImageTexture.create_from_image(img)
