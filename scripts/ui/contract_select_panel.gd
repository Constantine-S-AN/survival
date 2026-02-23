extends Panel
class_name ContractSelectPanel

signal start_pressed(contract_ids: Array[String])
signal back_pressed

const CONTRACT_GROUP_DISPLAY_NAMES: Dictionary = {
	"fog": "Fog",
	"sonar": "Sonar",
	"noise": "Noise",
	"spawner": "Spawner",
	"events": "Events",
	"rewards": "Rewards",
	"player": "Player",
	"enemy": "Enemy"
}

const CONTRACT_STAT_DISPLAY_NAMES: Dictionary = {
	"vision_radius_mult": "Vision Radius",
	"reveal_duration_mult": "Reveal Duration",
	"max_radius_mult": "Sonar Radius",
	"wave_speed_mult": "Sonar Wave Speed",
	"gain_mult": "Noise Gain",
	"decay_mult": "Noise Decay",
	"spawn_rate_mult": "Spawn Rate",
	"spawn_cap_mult": "Spawn Cap",
	"pursuer_chance_add": "Pursuer Chance",
	"elite_chance_add": "Elite Chance",
	"rate_mult": "Event Rate",
	"hazard_cycle_mult": "Hazard Frequency",
	"xp_mult": "XP Reward",
	"rarity_mult": "Rarity Reward",
	"drop_mult": "Drop Reward",
	"meta_currency_mult": "Meta Reward",
	"max_hp_mult": "Max HP",
	"dash_disabled": "Dash",
	"low_noise_damage_mult": "Low-Noise Damage",
	"high_noise_damage_mult": "High-Noise Damage",
	"speed_mult": "Enemy Speed"
}

@onready var title_label: Label = $Margin/VBox/Header/Title
@onready var selected_label: Label = $Margin/VBox/Header/Selected
@onready var contract_list: ItemList = $Margin/VBox/Body/Left/ContractList
@onready var detail_name: Label = $Margin/VBox/Body/Right/Name
@onready var detail_desc: Label = $Margin/VBox/Body/Right/Desc
@onready var detail_effects: RichTextLabel = $Margin/VBox/Body/Right/Effects
@onready var preview_label: Label = $Margin/VBox/Body/Right/Preview
@onready var start_button: Button = $Margin/VBox/Footer/StartButton
@onready var back_button: Button = $Margin/VBox/Footer/BackButton
@onready var root_vbox: VBoxContainer = $Margin/VBox

var contracts: Array = []
var contract_ids_by_index: Array[String] = []
var selected_contract_ids: Array[String] = []
var max_select: int = 3
var selected_index: int = -1
var lock_reason_by_id: Dictionary = {}
var status_label: Label


func _ready() -> void:
	title_label.text = "Contracts"
	_create_status_hint_label()
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
	lock_reason_by_id.clear()
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
	var previous_contract_id := ""
	if selected_index >= 0 and selected_index < contract_ids_by_index.size():
		previous_contract_id = contract_ids_by_index[selected_index]
	contract_list.clear()
	contract_ids_by_index.clear()
	lock_reason_by_id.clear()
	var selected_by_group := _build_selected_group_map()
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
		var lock_reason := _compute_contract_lock_reason(contract_id, selected_by_group)
		lock_reason_by_id[contract_id] = lock_reason
		var locked := not selected and not lock_reason.is_empty()
		if locked:
			marker = "🔒"
		var reward_pct := float(contract.get("reward_pct", 0.0))
		var text := "%s %s  (+%.0f%%)" % [marker, String(contract.get("name", contract_id)), reward_pct]
		contract_list.add_item(text)
		var list_index := contract_list.item_count - 1
		if locked:
			contract_list.set_item_disabled(list_index, true)
			contract_list.set_item_custom_fg_color(list_index, Color(0.56, 0.60, 0.66, 0.92))
		elif selected:
			contract_list.set_item_custom_fg_color(list_index, Color(0.62, 0.94, 1.0, 1.0))
		else:
			contract_list.set_item_custom_fg_color(list_index, Color(0.84, 0.90, 0.98, 1.0))
	var preview := DataRegistry.get_contract_reward_preview(selected_contract_ids)
	selected_label.text = "Selected %d / %d   Reward +%.0f%%" % [
		selected_contract_ids.size(),
		max_select,
		float(preview.get("reward_pct_sum", 0.0))
	]
	start_button.text = "Start Run (%d)" % selected_contract_ids.size()
	start_button.disabled = false
	selected_index = _get_contract_index(previous_contract_id)
	if selected_index < 0 and not contract_ids_by_index.is_empty():
		selected_index = 0
	if selected_index >= 0 and selected_index < contract_ids_by_index.size():
		contract_list.select(selected_index)


func _on_item_selected(index: int) -> void:
	selected_index = index
	_refresh_detail(index)


func _on_item_activated(index: int) -> void:
	if index < 0 or index >= contract_ids_by_index.size():
		return
	var contract_id := contract_ids_by_index[index]
	if selected_contract_ids.has(contract_id):
		selected_contract_ids.erase(contract_id)
		_show_status_hint("Removed %s" % String(DataRegistry.get_contract(contract_id).get("name", contract_id)), false)
		_refresh_list()
		_refresh_detail(index)
		return
	var lock_reason := String(lock_reason_by_id.get(contract_id, ""))
	if not lock_reason.is_empty():
		_show_status_hint(lock_reason, true)
		return
	if max_select > 0 and selected_contract_ids.size() >= max_select:
		_show_status_hint("Selection limit reached (%d/%d)." % [selected_contract_ids.size(), max_select], true)
		return
	var contract := DataRegistry.get_contract(contract_id)
	if contract.is_empty():
		return
	selected_contract_ids.append(contract_id)
	selected_contract_ids = DataRegistry.normalize_contract_selection(selected_contract_ids)
	var conflict_names := _get_contract_conflict_names(contract_id)
	if not conflict_names.is_empty():
		_show_status_hint("与 %s 互斥" % " / ".join(conflict_names), true)
	else:
		_show_status_hint("Selected %s" % String(contract.get("name", contract_id)), false)
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
	var lock_reason := String(lock_reason_by_id.get(contract_id, ""))
	var status_line := "Status: Selected" if selected_contract_ids.has(contract_id) else "Status: Available"
	if not lock_reason.is_empty():
		status_line = "Status: 🔒 %s" % lock_reason
	detail_desc.text = "%s\nCategory: %s\n%s" % [
		String(contract.get("description", "")),
		String(contract.get("category", "misc")),
		status_line
	]
	detail_effects.text = _format_contract_effects(contract)
	var preview := DataRegistry.get_contract_reward_preview(selected_contract_ids)
	preview_label.text = "Reward Preview (Selected)\nXP x%.2f\nRarity x%.2f\nDrop x%.2f\nMeta x%.2f\nTotal +%.0f%% (x%.2f)" % [
		float(preview.get("xp_mult", 1.0)),
		float(preview.get("rarity_mult", 1.0)),
		float(preview.get("drop_mult", 1.0)),
		float(preview.get("meta_currency_mult", 1.0)),
		float(preview.get("reward_pct_sum", 0.0)),
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
		var group_lines: Array[String] = []
		for key_variant in group.keys():
			var key := String(key_variant)
			var value := float(group.get(key_variant, 0.0))
			var label := String(CONTRACT_STAT_DISPLAY_NAMES.get(key, key))
			group_lines.append("- %s: %s" % [label, _format_contract_effect_value(key, value)])
		var group_name := String(CONTRACT_GROUP_DISPLAY_NAMES.get(group_key, group_key.capitalize()))
		lines.append("%s\n%s" % [group_name, "\n".join(group_lines)])
	if lines.is_empty():
		return "Effects: -"
	return "Effects:\n%s" % "\n\n".join(lines)


func _build_selected_group_map() -> Dictionary:
	var selected_by_group: Dictionary = {}
	for contract_id in selected_contract_ids:
		var contract := DataRegistry.get_contract(contract_id)
		if contract.is_empty():
			continue
		var group := String(contract.get("exclusive_group", "")).strip_edges()
		if group.is_empty():
			continue
		selected_by_group[group] = contract_id
	return selected_by_group


func _compute_contract_lock_reason(contract_id: String, selected_by_group: Dictionary = {}) -> String:
	var contract := DataRegistry.get_contract(contract_id)
	if contract.is_empty():
		return ""
	if max_select > 0 and selected_contract_ids.size() >= max_select and not selected_contract_ids.has(contract_id):
		return "Selection limit reached (%d/%d)." % [selected_contract_ids.size(), max_select]
	var group := String(contract.get("exclusive_group", "")).strip_edges()
	if group.is_empty():
		return ""
	var owner_id := String(selected_by_group.get(group, "")).strip_edges()
	if owner_id.is_empty() or owner_id == contract_id:
		return ""
	var owner_name := String(DataRegistry.get_contract(owner_id).get("name", owner_id))
	return "与 %s 互斥" % owner_name


func _get_contract_conflict_names(contract_id: String) -> Array[String]:
	var contract := DataRegistry.get_contract(contract_id)
	if contract.is_empty():
		return []
	var group := String(contract.get("exclusive_group", "")).strip_edges()
	if group.is_empty():
		return []
	var names: Array[String] = []
	for contract_variant in contracts:
		if not (contract_variant is Dictionary):
			continue
		var row: Dictionary = contract_variant
		var row_id := String(row.get("id", "")).strip_edges()
		if row_id.is_empty() or row_id == contract_id:
			continue
		if String(row.get("exclusive_group", "")).strip_edges() != group:
			continue
		names.append(String(row.get("name", row_id)))
	return names


func _format_contract_effect_value(key: String, value: float) -> String:
	if key == "dash_disabled":
		return "Disabled" if value >= 0.5 else "Enabled"
	if key.ends_with("_mult"):
		var delta_pct := (value - 1.0) * 100.0
		var sign := "+" if delta_pct >= 0.0 else ""
		return "%s%d%%" % [sign, int(round(delta_pct))]
	if key.ends_with("_add"):
		var add_pct := value * 100.0
		var sign := "+" if add_pct >= 0.0 else ""
		return "%s%d%%" % [sign, int(round(add_pct))]
	if absf(value) >= 1.0:
		var sign_int := "+" if value >= 0.0 else ""
		return "%s%d" % [sign_int, int(round(value))]
	var sign_float := "+" if value >= 0.0 else ""
	return "%s%.2f" % [sign_float, value]


func _create_status_hint_label() -> void:
	status_label = Label.new()
	status_label.name = "StatusHint"
	status_label.visible = false
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status_label.modulate = Color(0.80, 0.94, 1.0, 0.95)
	root_vbox.add_child(status_label)
	root_vbox.move_child(status_label, 1)


func _show_status_hint(message: String, is_error: bool) -> void:
	if status_label == null:
		return
	status_label.text = message
	status_label.visible = not message.strip_edges().is_empty()
	status_label.modulate = Color(1.0, 0.72, 0.72, 1.0) if is_error else Color(0.72, 0.96, 1.0, 1.0)


func _get_contract_index(contract_id: String) -> int:
	if contract_id.strip_edges().is_empty():
		return -1
	return contract_ids_by_index.find(contract_id)


func get_contract_index(contract_id: String) -> int:
	return _get_contract_index(contract_id)


func is_contract_locked(contract_id: String) -> bool:
	return not String(lock_reason_by_id.get(contract_id, "")).strip_edges().is_empty()


func get_contract_row_text(contract_id: String) -> String:
	var index := _get_contract_index(contract_id)
	if index < 0:
		return ""
	return contract_list.get_item_text(index)


func get_status_hint_text() -> String:
	if status_label == null:
		return ""
	return status_label.text


func get_preview_text() -> String:
	if preview_label == null:
		return ""
	return preview_label.text
