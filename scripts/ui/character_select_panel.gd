extends Panel
class_name CharacterSelectPanel

signal start_pressed(character_id: String)
signal back_pressed
signal random_pressed(character_id: String)
signal debug_unlock_all_pressed

@onready var title_label: Label = $Margin/VBox/Header/Title
@onready var character_list: ItemList = $Margin/VBox/Body/Left/CharacterList
@onready var detail_name: Label = $Margin/VBox/Body/Right/Name
@onready var detail_desc: Label = $Margin/VBox/Body/Right/Desc
@onready var detail_stats: RichTextLabel = $Margin/VBox/Body/Right/Stats
@onready var detail_unlock: Label = $Margin/VBox/Body/Right/Unlock
@onready var start_button: Button = $Margin/VBox/Footer/StartButton
@onready var random_button: Button = $Margin/VBox/Footer/RandomButton
@onready var back_button: Button = $Margin/VBox/Footer/BackButton
@onready var unlock_all_button: Button = $Margin/VBox/Footer/UnlockAllButton

var characters: Array = []
var character_ids_by_index: Array[String] = []
var unlocked_ids: Array[String] = []
var selected_character_id: String = ""


func _ready() -> void:
	if Localization != null and Localization.has_signal("language_changed"):
		Localization.language_changed.connect(_on_language_changed)
	_apply_static_texts()
	character_list.item_selected.connect(_on_item_selected)
	start_button.pressed.connect(_on_start_pressed)
	random_button.pressed.connect(_on_random_pressed)
	back_button.pressed.connect(func() -> void:
		back_pressed.emit()
	)
	unlock_all_button.pressed.connect(func() -> void:
		debug_unlock_all_pressed.emit()
	)
	unlock_all_button.visible = OS.is_debug_build()
	modulate.a = 0.0
	scale = Vector2(0.98, 0.98)
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.22)
	tween.parallel().tween_property(self, "scale", Vector2.ONE, 0.22).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


func set_character_data(character_rows: Array, unlocked_character_ids: Array[String], initial_selected_id: String) -> void:
	characters = _resolve_character_rows(character_rows)
	unlocked_ids = unlocked_character_ids.duplicate()
	character_ids_by_index.clear()
	character_list.clear()

	for character_variant in characters:
		if not (character_variant is Dictionary):
			continue
		var character: Dictionary = character_variant
		var character_id := String(character.get("id", ""))
		if character_id.is_empty():
			continue
		var display_name := String(character.get("display_name", character_id))
		var unlocked := unlocked_ids.has(character_id)
		var item_text := display_name if unlocked else _l("[LOCKED] %s", "[未解锁] %s") % display_name
		character_list.add_item(item_text)
		character_ids_by_index.append(character_id)

	if character_ids_by_index.is_empty():
		selected_character_id = ""
		_refresh_detail()
		return

	selected_character_id = initial_selected_id
	if selected_character_id.is_empty() or not character_ids_by_index.has(selected_character_id):
		selected_character_id = _pick_default_unlocked_character()
	if selected_character_id.is_empty():
		selected_character_id = character_ids_by_index[0]

	var selected_index := character_ids_by_index.find(selected_character_id)
	if selected_index >= 0:
		character_list.select(selected_index)
	_refresh_detail()


func get_selected_character_id() -> String:
	return selected_character_id


func refresh_unlocks(unlocked_character_ids: Array[String]) -> void:
	var current_selected := selected_character_id
	set_character_data(characters, unlocked_character_ids, current_selected)


func _on_item_selected(index: int) -> void:
	if index < 0 or index >= character_ids_by_index.size():
		return
	selected_character_id = character_ids_by_index[index]
	_refresh_detail()


func _on_start_pressed() -> void:
	if selected_character_id.is_empty():
		return
	if not unlocked_ids.has(selected_character_id):
		return
	start_pressed.emit(selected_character_id)


func _on_random_pressed() -> void:
	var unlocked_pool: Array[String] = []
	for character_id in character_ids_by_index:
		if unlocked_ids.has(character_id):
			unlocked_pool.append(character_id)
	if unlocked_pool.is_empty():
		return
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var picked := unlocked_pool[rng.randi_range(0, unlocked_pool.size() - 1)]
	selected_character_id = picked
	var idx := character_ids_by_index.find(picked)
	if idx >= 0:
		character_list.select(idx)
	_refresh_detail()
	random_pressed.emit(picked)


func _refresh_detail() -> void:
	var character := DataRegistry.get_character(selected_character_id)
	if character.is_empty():
		detail_name.text = _l("No character selected", "未选择角色")
		detail_desc.text = ""
		detail_stats.text = ""
		detail_unlock.text = ""
		start_button.disabled = true
		return

	var unlocked := unlocked_ids.has(selected_character_id)
	detail_name.text = String(character.get("display_name", selected_character_id))
	detail_desc.text = "%s\n%s" % [
		String(character.get("short_desc", "")),
		String(character.get("passive_summary", ""))
	]

	var mods_variant: Variant = character.get("stat_modifiers", {})
	var mods: Dictionary = mods_variant if mods_variant is Dictionary else {}
	var weapon_id := String(character.get("starting_weapon_id", "needle_rifle"))
	var weapon_name := String(DataRegistry.get_weapon(weapon_id).get("name", weapon_id))
	detail_stats.text = "\n".join([
		_l("Start Weapon: %s", "起始武器：%s") % weapon_name,
		_l("HP Mult: %.2f", "生命倍率：%.2f") % float(mods.get("max_hp_multiplier", 1.0)),
		_l("Move Mult: %.2f", "移速倍率：%.2f") % float(mods.get("move_speed_multiplier", 1.0)),
		_l("Dash CD Mult: %.2f", "冲刺冷却倍率：%.2f") % float(mods.get("dash_cooldown_multiplier", 1.0)),
		_l("Noise Mult: %.2f", "噪声倍率：%.2f") % float(mods.get("noise_gain_multiplier", 1.0)),
		_l("Flare Reveal Mult: %.2f", "照明弹显形倍率：%.2f") % float(mods.get("sonar_reveal_duration_multiplier", 1.0)),
		_l("Pickup Radius Mult: %.2f", "拾取半径倍率：%.2f") % float(mods.get("pickup_radius_multiplier", 1.0))
	])

	var unlock_variant: Variant = character.get("unlock", {})
	var unlock: Dictionary = unlock_variant if unlock_variant is Dictionary else {}
	var display := String(unlock.get("display", ""))
	var progress := ProfileStore.get_requirement_progress(unlock)
	if unlocked:
		detail_unlock.text = _l("Status: UNLOCKED", "状态：已解锁")
	else:
		detail_unlock.text = _l("Unlock: %s\nProgress: %s", "解锁条件：%s\n进度：%s") % [display, String(progress.get("text", "0 / 0"))]

	start_button.disabled = not unlocked


func _pick_default_unlocked_character() -> String:
	for character_id in character_ids_by_index:
		if unlocked_ids.has(character_id):
			return character_id
	return ""


func _on_language_changed(_language_code: String) -> void:
	_apply_static_texts()
	set_character_data(characters, unlocked_ids, selected_character_id)


func _apply_static_texts() -> void:
	title_label.text = _l("Character Select", "角色选择")
	start_button.text = _l("Start", "开始")
	random_button.text = _l("Random", "随机")
	back_button.text = _l("Back", "返回")
	unlock_all_button.text = _l("Unlock All", "全部解锁")


func _is_zh() -> bool:
	if Localization == null or not Localization.has_method("is_chinese"):
		return false
	return bool(Localization.call("is_chinese"))


func _l(en: String, zh: String) -> String:
	return zh if _is_zh() else en


func _resolve_character_rows(source_rows: Array) -> Array:
	var rows: Array = []
	for row_variant in source_rows:
		if not (row_variant is Dictionary):
			continue
		var row: Dictionary = row_variant
		var character_id := String(row.get("id", "")).strip_edges()
		if character_id.is_empty():
			continue
		var localized := DataRegistry.get_character(character_id)
		rows.append(localized if not localized.is_empty() else row)
	return rows
