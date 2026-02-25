extends Panel
class_name MapSelectPanel

signal start_pressed(map_id: String)
signal back_pressed

@onready var title_label: Label = $Margin/VBox/Header/Title
@onready var map_list: ItemList = $Margin/VBox/Body/Left/MapList
@onready var detail_name: Label = $Margin/VBox/Body/Right/Name
@onready var detail_desc: Label = $Margin/VBox/Body/Right/Desc
@onready var detail_hazard: Label = $Margin/VBox/Body/Right/Hazard
@onready var detail_events: Label = $Margin/VBox/Body/Right/Events
@onready var detail_bias: RichTextLabel = $Margin/VBox/Body/Right/Bias
@onready var start_button: Button = $Margin/VBox/Footer/StartButton
@onready var back_button: Button = $Margin/VBox/Footer/BackButton

var maps: Array = []
var map_ids_by_index: Array[String] = []
var selected_map_id: String = ""


func _ready() -> void:
	if Localization != null and Localization.has_signal("language_changed"):
		Localization.language_changed.connect(_on_language_changed)
	_apply_static_texts()
	map_list.item_selected.connect(_on_item_selected)
	start_button.pressed.connect(_on_start_pressed)
	back_button.pressed.connect(func() -> void:
		back_pressed.emit()
	)
	modulate.a = 0.0
	scale = Vector2(0.98, 0.98)
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.22)
	tween.parallel().tween_property(self, "scale", Vector2.ONE, 0.22).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


func set_map_data(map_rows: Array, initial_selected_id: String) -> void:
	maps = map_rows.duplicate(true)
	map_ids_by_index.clear()
	map_list.clear()
	for map_variant in maps:
		if not (map_variant is Dictionary):
			continue
		var map: Dictionary = map_variant
		var map_id := String(map.get("id", "")).strip_edges()
		if map_id.is_empty():
			continue
		map_ids_by_index.append(map_id)
		map_list.add_item(String(map.get("name", map_id)))

	if map_ids_by_index.is_empty():
		selected_map_id = ""
		_refresh_detail()
		return

	selected_map_id = initial_selected_id.strip_edges()
	if selected_map_id.is_empty() or not map_ids_by_index.has(selected_map_id):
		selected_map_id = map_ids_by_index[0]
	var selected_index := map_ids_by_index.find(selected_map_id)
	if selected_index >= 0:
		map_list.select(selected_index)
	_refresh_detail()


func get_selected_map_id() -> String:
	return selected_map_id


func _on_item_selected(index: int) -> void:
	if index < 0 or index >= map_ids_by_index.size():
		return
	selected_map_id = map_ids_by_index[index]
	_refresh_detail()


func _on_start_pressed() -> void:
	if selected_map_id.is_empty():
		return
	start_pressed.emit(selected_map_id)


func _refresh_detail() -> void:
	var map := DataRegistry.get_map(selected_map_id)
	if map.is_empty():
		detail_name.text = _l("No map selected", "未选择地图")
		detail_desc.text = ""
		detail_hazard.text = ""
		detail_events.text = ""
		detail_bias.text = ""
		start_button.disabled = true
		return

	detail_name.text = String(map.get("name", selected_map_id))
	detail_desc.text = String(map.get("description", ""))
	detail_hazard.text = _l("Hazard: %s", "灾害：%s") % String(map.get("hazard_summary", ""))
	detail_events.text = _l("Events: %s", "事件：%s") % String(map.get("event_summary", ""))
	detail_bias.text = _format_bias_text(map)
	start_button.disabled = false


func _format_bias_text(map: Dictionary) -> String:
	var modifiers_variant: Variant = map.get("modifiers", {})
	if not (modifiers_variant is Dictionary):
		return _l("Bias: default", "倾向：默认")
	var modifiers: Dictionary = modifiers_variant
	var fog_variant: Variant = modifiers.get("fog", {})
	var noise_variant: Variant = modifiers.get("noise", {})
	var spawner_variant: Variant = modifiers.get("spawner", {})
	var fog: Dictionary = fog_variant if fog_variant is Dictionary else {}
	var noise: Dictionary = noise_variant if noise_variant is Dictionary else {}
	var spawner: Dictionary = spawner_variant if spawner_variant is Dictionary else {}
	var lines: Array[String] = []
	lines.append(_l("Fog Radius x%.2f", "视野半径 x%.2f") % float(fog.get("vision_radius_mult", 1.0)))
	lines.append(_l("Noise Gain x%.2f / Decay x%.2f", "噪声获取 x%.2f / 衰减 x%.2f") % [float(noise.get("gain_mult", 1.0)), float(noise.get("decay_mult", 1.0))])
	lines.append(_l("Spawn Rate x%.2f / Pursuer +%.3f", "刷新速率 x%.2f / 追猎者 +%.3f") % [float(spawner.get("spawn_rate_mult", 1.0)), float(spawner.get("pursuer_chance_add", 0.0))])
	return "\n".join(lines)


func _on_language_changed(_language_code: String) -> void:
	_apply_static_texts()
	for i in range(map_ids_by_index.size()):
		var map_id := map_ids_by_index[i]
		var map_name := String(DataRegistry.get_map(map_id).get("name", map_id))
		if i >= 0 and i < map_list.item_count:
			map_list.set_item_text(i, map_name)
	_refresh_detail()


func _apply_static_texts() -> void:
	title_label.text = _l("Map Select", "地图选择")
	start_button.text = _l("Start", "开始")
	back_button.text = _l("Back", "返回")


func _is_zh() -> bool:
	if Localization == null or not Localization.has_method("is_chinese"):
		return false
	return bool(Localization.call("is_chinese"))


func _l(en: String, zh: String) -> String:
	return zh if _is_zh() else en
