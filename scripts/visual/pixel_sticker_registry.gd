extends RefCounted
class_name PixelStickerRegistry

const CHARACTER_DIR := "res://assets/textures/pixel/characters/"
const ENEMY_DIR := "res://assets/textures/pixel/enemies/"
const WEAPON_DIR := "res://assets/textures/pixel/weapons/"
const CHARACTER_IDLE_FRAME_COUNT := 4
const ENEMY_IDLE_FRAME_COUNT := 4
const WEAPON_IDLE_FRAME_COUNT := 3

static var _texture_cache: Dictionary = {}
static var _idle_frame_cache: Dictionary = {}


static func get_character_sticker(character_id: String) -> Texture2D:
	var frames := get_character_idle_frames(character_id)
	return frames[0] if not frames.is_empty() else _load_sticker(CHARACTER_DIR, character_id, "diver")


static func get_enemy_sticker(enemy_id: String) -> Texture2D:
	var frames := get_enemy_idle_frames(enemy_id)
	return frames[0] if not frames.is_empty() else _load_sticker(ENEMY_DIR, enemy_id, "drifter")


static func get_weapon_sticker(weapon_id: String) -> Texture2D:
	var frames := get_weapon_idle_frames(weapon_id)
	return frames[0] if not frames.is_empty() else _load_sticker(WEAPON_DIR, weapon_id, "needle_rifle")


static func get_character_idle_frames(character_id: String) -> Array[Texture2D]:
	return _get_idle_frames(CHARACTER_DIR, character_id, "diver", "character")


static func get_enemy_idle_frames(enemy_id: String) -> Array[Texture2D]:
	return _get_idle_frames(ENEMY_DIR, enemy_id, "drifter", "enemy")


static func get_weapon_idle_frames(weapon_id: String) -> Array[Texture2D]:
	return _get_idle_frames(WEAPON_DIR, weapon_id, "needle_rifle", "weapon")


static func _load_sticker(base_dir: String, entry_id: String, fallback_id: String) -> Texture2D:
	var key := entry_id.strip_edges().to_lower()
	var path := "%s%s.png" % [base_dir, key]
	if ResourceLoader.exists(path, "Texture2D"):
		return _load_texture(path)
	var fallback_path := "%s%s.png" % [base_dir, fallback_id]
	if ResourceLoader.exists(fallback_path, "Texture2D"):
		return _load_texture(fallback_path)
	return _build_fallback_sticker(base_dir + ":" + key)


static func _load_texture(path: String) -> Texture2D:
	if _texture_cache.has(path):
		var cached: Variant = _texture_cache[path]
		if cached is Texture2D:
			return cached
	var loaded := load(path)
	if loaded is Texture2D:
		_texture_cache[path] = loaded
		return loaded
	return _build_fallback_sticker(path)


static func _get_idle_frames(base_dir: String, entry_id: String, fallback_id: String, profile: String) -> Array[Texture2D]:
	var key := entry_id.strip_edges().to_lower()
	if key.is_empty():
		key = fallback_id
	var cache_key := "%s|%s|%s" % [base_dir, key, profile]
	if _idle_frame_cache.has(cache_key):
		var cached_variant: Variant = _idle_frame_cache[cache_key]
		if cached_variant is Array:
			var cached_frames: Array[Texture2D] = []
			for frame_variant in cached_variant:
				if frame_variant is Texture2D:
					cached_frames.append(frame_variant)
			if not cached_frames.is_empty():
				return cached_frames

	var base_texture := _load_sticker(base_dir, key, fallback_id)
	var base_image := _texture_to_image(base_texture)
	if base_image == null:
		return []

	var frames: Array[Texture2D] = []
	var frame0 := ImageTexture.create_from_image(base_image)
	if frame0 != null:
		frames.append(frame0)

	var frame_count := _frame_count_for_profile(profile)
	if frame_count > 1:
		for frame_idx in range(1, frame_count):
			var idle_variant := _build_idle_variant(base_image, profile, key, frame_idx, frame_count)
			var idle_frame := ImageTexture.create_from_image(idle_variant)
			if idle_frame != null:
				frames.append(idle_frame)
	if frames.is_empty():
		frames.append(base_texture)
	_idle_frame_cache[cache_key] = frames
	return frames


static func _frame_count_for_profile(profile: String) -> int:
	match profile:
		"character":
			return CHARACTER_IDLE_FRAME_COUNT
		"enemy":
			return ENEMY_IDLE_FRAME_COUNT
		"weapon":
			return WEAPON_IDLE_FRAME_COUNT
		_:
			return 2


static func _texture_to_image(texture: Texture2D) -> Image:
	if texture == null:
		return null
	var image := texture.get_image()
	if image == null:
		return null
	if image.get_format() != Image.FORMAT_RGBA8:
		image.convert(Image.FORMAT_RGBA8)
	return image


static func _build_idle_variant(base_image: Image, profile: String, seed_text: String, frame_idx: int, frame_count: int) -> Image:
	var width := base_image.get_width()
	var height := base_image.get_height()
	var out := Image.create(width, height, false, Image.FORMAT_RGBA8)
	out.fill(Color(0.0, 0.0, 0.0, 0.0))

	var seed: int = abs(int(seed_text.hash()))
	var shimmer_color := Color.from_hsv(float(seed % 360) / 360.0, 0.26, 0.96, 1.0)
	var upper_cutoff := maxi(2, height - 7)
	var phase := float(frame_idx) / maxf(1.0, float(frame_count))
	var bob_wave := sin((phase + float(seed % 7) * 0.03) * TAU)
	var bob_offset := int(round(bob_wave))
	var frame_jitter := ((seed + frame_idx * 11) % 5) - 2
	var glow_strength := 0.06 + 0.05 * maxf(0.0, bob_wave)
	var shadow_strength := 0.10 + 0.04 * maxf(0.0, -bob_wave)

	for y in range(height):
		for x in range(width):
			var color := base_image.get_pixel(x, y)
			if color.a <= 0.01:
				continue
			var luminance := (color.r + color.g + color.b) / 3.0
			var dst_x := x
			var dst_y := y

			if profile == "weapon":
				if luminance > 0.55 and y < height - 4:
					color = color.lightened(0.08 + glow_strength)
				elif luminance < 0.20:
					color = color.darkened(0.08 + shadow_strength * 0.4)
				if x > int(float(width) * 0.48) and ((x + y + seed + frame_idx) % 4) == 0:
					color = color.lerp(shimmer_color, 0.10 + 0.06 * maxf(0.0, bob_wave))
				if frame_idx == frame_count - 1 and ((x + y + frame_jitter) % 7) == 0:
					color = color.lightened(0.08)
			else:
				if y < upper_cutoff and luminance > 0.08:
					dst_y = clampi(y + bob_offset, 0, height - 1)
				if y < int(float(height) * 0.40) and luminance > 0.45:
					color = color.lightened(glow_strength)
				elif y >= upper_cutoff and luminance < 0.17:
					color = color.darkened(shadow_strength)
				if ((x + y + frame_jitter) % 9) == 0 and luminance > 0.25:
					color = color.lightened(0.04)

			var previous := out.get_pixel(dst_x, dst_y)
			if color.a >= previous.a:
				out.set_pixel(dst_x, dst_y, color)

	if profile == "weapon":
		var streak_y := clampi(int(float(height) * (0.42 + 0.04 * bob_wave)), 0, height - 1)
		for x in range(int(float(width) * 0.24), int(float(width) * 0.86)):
			var source := out.get_pixel(x, streak_y)
			if source.a <= 0.01:
				continue
			out.set_pixel(x, streak_y, source.lightened(0.10 + glow_strength))
	return out


static func _build_fallback_sticker(seed_text: String) -> Texture2D:
	var cache_key := "fallback:%s" % seed_text
	if _texture_cache.has(cache_key):
		var cached: Variant = _texture_cache[cache_key]
		if cached is Texture2D:
			return cached
	var hue: float = float(abs(seed_text.hash()) % 360) / 360.0
	var bg := Color.from_hsv(hue, 0.5, 0.28, 1.0)
	var accent := Color.from_hsv(hue, 0.65, 0.94, 1.0)
	var hi := Color.from_hsv(hue, 0.35, 1.0, 1.0)
	var img := Image.create(24, 24, false, Image.FORMAT_RGBA8)
	img.fill(Color(0.0, 0.0, 0.0, 0.0))
	for x in range(2, 22):
		for y in range(2, 22):
			img.set_pixel(x, y, bg)
	for i in range(5, 19):
		img.set_pixel(i, 12, accent)
		img.set_pixel(12, i, accent)
	for x in range(8, 16):
		for y in range(8, 16):
			if (x + y) % 2 == 0:
				img.set_pixel(x, y, hi)
	var texture := ImageTexture.create_from_image(img)
	_texture_cache[cache_key] = texture
	return texture
