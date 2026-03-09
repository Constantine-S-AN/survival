extends RefCounted
class_name StardewLikeAssetLibrary

const SUNNYSIDE_SPRITE_ROOT := "res://assets/external/stardew_like_candidates/unpacked/Sunnyside-World-ASSET-PACK-V2-1/Sunnyside_World_ASSET_PACK_V2.1/Sunnyside_World_Gamemaker/sprites"

static var _texture_cache: Dictionary = {}
static var _image_cache: Dictionary = {}
static var _sprite_info_cache: Dictionary = {}
static var _sprite_frames_cache: Dictionary = {}


static func get_texture(path: String) -> Texture2D:
	if _texture_cache.has(path):
		var cached: Variant = _texture_cache[path]
		if cached is Texture2D:
			return cached
	var texture := load(path) as Texture2D
	if texture != null:
		_texture_cache[path] = texture
	return texture


static func get_image(path: String) -> Image:
	if _image_cache.has(path):
		var cached: Variant = _image_cache[path]
		if cached is Image:
			return (cached as Image).duplicate()
	var image := Image.new()
	var resolved_path := ProjectSettings.globalize_path(path) if path.begins_with("res://") else path
	if image.load(resolved_path) != OK:
		return null
	_image_cache[path] = image.duplicate()
	return image


static func get_gm_sprite_info(sprite_name: String) -> Dictionary:
	if _sprite_info_cache.has(sprite_name):
		return (_sprite_info_cache[sprite_name] as Dictionary).duplicate(true)
	var yy_path := "%s/%s/%s.yy" % [SUNNYSIDE_SPRITE_ROOT, sprite_name, sprite_name]
	if not FileAccess.file_exists(yy_path):
		return {}
	var file := FileAccess.open(yy_path, FileAccess.READ)
	if file == null:
		return {}
	var text := file.get_as_text()
	file.close()
	var frame_names: Array[String] = []
	for raw_line in text.split("\n"):
		var line := raw_line.strip_edges()
		if line.find("\"resourceType\":\"GMSpriteFrame\"") == -1:
			continue
		var marker := "\"name\":\""
		var marker_index := line.find(marker)
		if marker_index == -1:
			continue
		var name_start := marker_index + marker.length()
		var name_end := line.find("\"", name_start)
		if name_end == -1:
			continue
		var frame_name := line.substr(name_start, name_end - name_start)
		if frame_name.is_empty() or frame_names.has(frame_name):
			continue
		frame_names.append(frame_name)
	var info := {
		"width": _extract_int(text, "\"width\":", 16),
		"height": _extract_int(text, "\"height\":", 16),
		"xorigin": _extract_int(text, "\"xorigin\":", 0),
		"yorigin": _extract_int(text, "\"yorigin\":", 0),
		"frames": frame_names
	}
	_sprite_info_cache[sprite_name] = info.duplicate(true)
	return info


static func get_gm_sprite_frames(sprite_name: String) -> Array[Texture2D]:
	if _sprite_frames_cache.has(sprite_name):
		return (_sprite_frames_cache[sprite_name] as Array[Texture2D]).duplicate()
	var info := get_gm_sprite_info(sprite_name)
	var frames: Array[Texture2D] = []
	var frame_names_variant: Variant = info.get("frames", [])
	if frame_names_variant is Array:
		for frame_name_variant in frame_names_variant:
			var frame_name := String(frame_name_variant)
			if frame_name.is_empty():
				continue
			var texture := get_texture("%s/%s/%s.png" % [SUNNYSIDE_SPRITE_ROOT, sprite_name, frame_name])
			if texture != null:
				frames.append(texture)
	_sprite_frames_cache[sprite_name] = frames.duplicate()
	return frames


static func get_gm_sprite_texture(sprite_name: String, frame_index: int = 0) -> Texture2D:
	var frames := get_gm_sprite_frames(sprite_name)
	if frames.is_empty():
		return null
	return frames[posmod(frame_index, frames.size())]


static func get_gm_sprite_frames_resource(sprite_name: String, animation_name: String = "default") -> SpriteFrames:
	var sprite_frames := SpriteFrames.new()
	if not sprite_frames.has_animation(animation_name):
		sprite_frames.add_animation(animation_name)
	sprite_frames.set_animation_speed(animation_name, 6.0)
	sprite_frames.set_animation_loop(animation_name, true)
	for texture in get_gm_sprite_frames(sprite_name):
		sprite_frames.add_frame(animation_name, texture)
	return sprite_frames


static func configure_sprite(node: Sprite2D, sprite_name: String, frame_index: int = 0) -> Dictionary:
	var info := get_gm_sprite_info(sprite_name)
	var texture := get_gm_sprite_texture(sprite_name, frame_index)
	if texture == null:
		return {}
	node.texture = texture
	node.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	node.offset = Vector2(
		(float(info.get("width", 0)) * 0.5) - float(info.get("xorigin", 0)),
		(float(info.get("height", 0)) * 0.5) - float(info.get("yorigin", 0))
	)
	return info


static func configure_animated_sprite(
	node: AnimatedSprite2D,
	sprite_name: String,
	fps: float,
	animation_name: String = "default"
) -> Dictionary:
	var info := get_gm_sprite_info(sprite_name)
	var frames := get_gm_sprite_frames_resource(sprite_name, animation_name)
	if frames.get_frame_count(animation_name) <= 0:
		return {}
	frames.set_animation_speed(animation_name, fps)
	node.sprite_frames = frames
	node.animation = animation_name
	node.play(animation_name)
	node.centered = true
	node.offset = Vector2(
		(float(info.get("width", 0)) * 0.5) - float(info.get("xorigin", 0)),
		(float(info.get("height", 0)) * 0.5) - float(info.get("yorigin", 0))
	)
	return info


static func make_region_texture(texture_path: String, region: Rect2i) -> AtlasTexture:
	var texture := get_texture(texture_path)
	if texture == null:
		return null
	var atlas := AtlasTexture.new()
	atlas.atlas = texture
	atlas.region = Rect2(region.position, region.size)
	return atlas


static func build_tileset(tile_specs: Array, tile_size: int) -> TileSet:
	var atlas_image := Image.create(tile_size * maxi(1, tile_specs.size()), tile_size, false, Image.FORMAT_RGBA8)
	atlas_image.fill(Color(0.0, 0.0, 0.0, 0.0))
	for tile_index in range(tile_specs.size()):
		var spec_variant: Variant = tile_specs[tile_index]
		if not (spec_variant is Dictionary):
			continue
		var spec := spec_variant as Dictionary
		var tile_image := _build_tile_image(spec, tile_size)
		if tile_image == null:
			continue
		atlas_image.blit_rect(tile_image, Rect2i(Vector2i.ZERO, tile_image.get_size()), Vector2i(tile_index * tile_size, 0))
	var atlas_texture := ImageTexture.create_from_image(atlas_image)
	var tile_set := TileSet.new()
	tile_set.tile_size = Vector2i(tile_size, tile_size)
	var source := TileSetAtlasSource.new()
	source.texture = atlas_texture
	source.texture_region_size = Vector2i(tile_size, tile_size)
	for tile_index in range(maxi(1, tile_specs.size())):
		source.create_tile(Vector2i(tile_index, 0))
	tile_set.add_source(source, 0)
	return tile_set


static func _build_tile_image(spec: Dictionary, tile_size: int) -> Image:
	var source_image: Image = null
	if spec.has("sprite_name"):
		var sprite_texture := get_gm_sprite_texture(String(spec.get("sprite_name", "")), int(spec.get("frame_index", 0)))
		if sprite_texture != null:
			source_image = sprite_texture.get_image()
	elif spec.has("path"):
		source_image = get_image(String(spec.get("path", "")))
	if source_image == null:
		return null
	var region := Rect2i(Vector2i.ZERO, source_image.get_size())
	if spec.has("region"):
		var region_variant: Variant = spec.get("region", Rect2i())
		if region_variant is Rect2i:
			region = region_variant
	elif spec.has("cell"):
		var cell_variant: Variant = spec.get("cell", Vector2i.ZERO)
		var cell_size := int(spec.get("cell_size", 16))
		if cell_variant is Vector2i:
			var cell := cell_variant as Vector2i
			var span_variant: Variant = spec.get("span", Vector2i.ONE)
			var span: Vector2i = span_variant if span_variant is Vector2i else Vector2i.ONE
			region = Rect2i(cell * cell_size, span * cell_size)
	var cropped := Image.create(region.size.x, region.size.y, false, Image.FORMAT_RGBA8)
	cropped.blit_rect(source_image, region, Vector2i.ZERO)
	if cropped.get_width() != tile_size or cropped.get_height() != tile_size:
		cropped.resize(tile_size, tile_size, Image.INTERPOLATE_NEAREST)
	return cropped


static func _extract_int(text: String, key: String, default_value: int) -> int:
	var key_index := text.find(key)
	if key_index == -1:
		return default_value
	var value_start := key_index + key.length()
	while value_start < text.length() and text[value_start] in [" ", "\t"]:
		value_start += 1
	var value_end := value_start
	while value_end < text.length() and text[value_end] >= "0" and text[value_end] <= "9":
		value_end += 1
	if value_end <= value_start:
		return default_value
	return int(text.substr(value_start, value_end - value_start))
