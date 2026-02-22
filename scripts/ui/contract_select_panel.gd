extends Panel
class_name ContractSelectPanel

signal start_pressed(contract_ids: Array[String])
signal back_pressed

@onready var title_label: Label = $Margin/VBox/Header/Title
@onready var selected_label: Label = $Margin/VBox/Header/Selected
@onready var contract_list: ItemList = $Margin/VBox/Body/Left/ContractList
@onready var detail_name: Label = $Margin/VBox/Body/Right/Name
@onready var detail_desc: Label = $Margin/VBox/Body/Right/Desc
@onready var detail_effects: RichTextLabel = $Margin/VBox/Body/Right/Effects
@onready var preview_label: Label = $Margin/VBox/Body/Right/Preview
@onready var start_button: Button = $Margin/VBox/Footer/StartButton
@onready var back_button: Button = $Margin/VBox/Footer/BackButton

var contracts: Array = []
var contract_ids_by_index: Array[String] = []
var selected_contract_ids: Array[String] = []
var max_select: int = 3
var selected_index: int = -1


func _ready() -> void:
	title_label.text = "Contracts"
	contract_list.item_selected.connect(_on_item_selected)
	contract_list.item_activated.connect(_on_item_activated)
	start_button.pressed.connect(_on_start_pressed)
	back_button.pressed.connect(func() -> void:
		back_pressed.emit()
	)
	modulate.a = 0.0
	scale = Vector2(0.98, 0.98)
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.22)
	tween.parallel().tween_property(self, "scale", Vector2.ONE, 0.22).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


func set_contract_data(contract_rows: Array, initial_selected_ids: Array[String], max_select_count: int) -> void:
	contracts = contract_rows.duplicate(true)
	max_select = clampi(max_select_count, 0, 3)
	contract_ids_by_index.clear()
	selected_contract_ids = DataRegistry.normalize_contract_selection(initial_selected_ids)
	selected_index = -1
	_refresh_list()
	if contract_ids_by_index.is_empty():
		_refresh_detail(-1)
		return
	selected_index = 0
	contract_list.select(0)
	_refresh_detail(0)


func get_selected_contract_ids() -> Array[String]:
	return selected_contract_ids.duplicate()


func _refresh_list() -> void:
	contract_list.clear()
	contract_ids_by_index.clear()
	for contract_variant in contracts:
		if not (contract_variant is Dictionary):
			continue
		var contract: Dictionary = contract_variant
		var contract_id := String(contract.get("id", "")).strip_edges()
		if contract_id.is_empty():
			continue
		contract_ids_by_index.append(contract_id)
		var selected := selected_contract_ids.has(contract_id)
		var marker := "[x]" if selected else "[ ]"
		var reward_pct := float(contract.get("reward_pct", 0.0))
		var text := "%s %s  (+%.0f%%)" % [marker, String(contract.get("name", contract_id)), reward_pct]
		contract_list.add_item(text)
	var preview := DataRegistry.get_contract_reward_preview(selected_contract_ids)
	selected_label.text = "Selected %d / %d   Reward +%.0f%%" % [
		selected_contract_ids.size(),
		max_select,
		float(preview.get("reward_pct_sum", 0.0))
	]
	start_button.text = "Start Run (%d)" % selected_contract_ids.size()


func _on_item_selected(index: int) -> void:
	selected_index = index
	_refresh_detail(index)


func _on_item_activated(index: int) -> void:
	if index < 0 or index >= contract_ids_by_index.size():
		return
	var contract_id := contract_ids_by_index[index]
	if selected_contract_ids.has(contract_id):
		selected_contract_ids.erase(contract_id)
		_refresh_list()
		_refresh_detail(index)
		return
	if max_select > 0 and selected_contract_ids.size() >= max_select:
		return
	var contract := DataRegistry.get_contract(contract_id)
	if contract.is_empty():
		return
	var exclusive_group := String(contract.get("exclusive_group", "")).strip_edges()
	if not exclusive_group.is_empty():
		var filtered: Array[String] = []
		for selected_id in selected_contract_ids:
			var selected_contract := DataRegistry.get_contract(selected_id)
			if selected_contract.is_empty():
				continue
			if String(selected_contract.get("exclusive_group", "")).strip_edges() == exclusive_group:
				continue
			filtered.append(selected_id)
		selected_contract_ids = filtered
	selected_contract_ids.append(contract_id)
	selected_contract_ids = DataRegistry.normalize_contract_selection(selected_contract_ids)
	_refresh_list()
	_refresh_detail(index)


func _on_start_pressed() -> void:
	start_pressed.emit(selected_contract_ids.duplicate())


func _refresh_detail(index: int) -> void:
	if index < 0 or index >= contract_ids_by_index.size():
		detail_name.text = "No contract selected"
		detail_desc.text = ""
		detail_effects.text = ""
		preview_label.text = ""
		return
	var contract_id := contract_ids_by_index[index]
	var contract := DataRegistry.get_contract(contract_id)
	if contract.is_empty():
		detail_name.text = "No contract selected"
		detail_desc.text = ""
		detail_effects.text = ""
		preview_label.text = ""
		return
	detail_name.text = String(contract.get("name", contract_id))
	detail_desc.text = "%s\nCategory: %s" % [
		String(contract.get("description", "")),
		String(contract.get("category", "misc"))
	]
	detail_effects.text = _format_contract_effects(contract)
	var preview := DataRegistry.get_contract_reward_preview(selected_contract_ids)
	preview_label.text = "XP x%.2f  Rarity x%.2f  Drop x%.2f\nReward Multiplier x%.2f" % [
		float(preview.get("xp_mult", 1.0)),
		float(preview.get("rarity_mult", 1.0)),
		float(preview.get("drop_mult", 1.0)),
		float(preview.get("reward_multiplier", 1.0))
	]


func _format_contract_effects(contract: Dictionary) -> String:
	var effects_variant: Variant = contract.get("effects", {})
	if not (effects_variant is Dictionary):
		return "Effects: -"
	var effects: Dictionary = effects_variant
	var lines: Array[String] = []
	for group_key_variant in effects.keys():
		var group_key := String(group_key_variant).strip_edges()
		var group_variant: Variant = effects.get(group_key_variant, {})
		if not (group_variant is Dictionary):
			continue
		var group: Dictionary = group_variant
		var group_parts: Array[String] = []
		for key_variant in group.keys():
			var key := String(key_variant)
			var value := float(group.get(key_variant, 0.0))
			if key.ends_with("_mult"):
				group_parts.append("%s x%.2f" % [key, value])
			else:
				group_parts.append("%s %+0.3f" % [key, value])
		lines.append("%s: %s" % [group_key, ", ".join(group_parts)])
	if lines.is_empty():
		return "Effects: -"
	return "Effects:\n%s" % "\n".join(lines)
