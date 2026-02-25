extends SceneTree

const PixelStickerRegistry := preload("res://scripts/visual/pixel_sticker_registry.gd")

const CHAR_IDS := ["diver", "arc_tech", "lancer", "drone_handler", "scavenger"]
const ENEMY_IDS := ["drifter", "sprinter", "shooter", "shielded", "splitter", "bloater", "summoner", "lurker", "drone_scout", "ink_mite", "rusher_eel"]
const WEAPON_IDS := ["needle_rifle", "burst_smg", "silence_dart", "shock_pulse", "abyss_mine", "tether_beam", "orbital_drone", "sonar_blade"]

func _initialize() -> void:
	var rows := [CHAR_IDS, ENEMY_IDS, WEAPON_IDS]
	var tile := 48
	var gap := 10
	var section_gap := 26
	var cols := 0
	for ids in rows:
		cols = maxi(cols, (ids as Array).size())
	var width := 20 + cols * (tile * 2 + gap) + 20
	var height := 24
	for ids in rows:
		height += tile + section_gap
	var out := Image.create(width, height, false, Image.FORMAT_RGBA8)
	out.fill(Color(0.03, 0.06, 0.13, 1.0))

	var y := 20
	for row_idx in range(rows.size()):
		var ids: Array = rows[row_idx]
		var x := 20
		for id_variant in ids:
			var entry_id := String(id_variant)
			var frames: Array[Texture2D]
			if row_idx == 0:
				frames = PixelStickerRegistry.get_character_idle_frames(entry_id)
			elif row_idx == 1:
				frames = PixelStickerRegistry.get_enemy_idle_frames(entry_id)
			else:
				frames = PixelStickerRegistry.get_weapon_idle_frames(entry_id)
			if frames.is_empty():
				x += tile * 2 + gap
				continue
			var image0 := frames[0].get_image()
			if image0 != null:
				out.blit_rect(image0, Rect2i(Vector2i.ZERO, image0.get_size()), Vector2i(x, y))
			if frames.size() > 1:
				var image1 := frames[1].get_image()
				if image1 != null:
					out.blit_rect(image1, Rect2i(Vector2i.ZERO, image1.get_size()), Vector2i(x + tile, y))
			x += tile * 2 + gap
		y += tile + section_gap

	DirAccess.make_dir_recursive_absolute("user://")
	var out_path := "res://tmp/pixel_idle_frames_preview.png"
	out.save_png(ProjectSettings.globalize_path(out_path))
	print("Saved ", out_path)
	quit()
