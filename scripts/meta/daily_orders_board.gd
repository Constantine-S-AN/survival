extends Control
class_name DailyOrdersBoardView

signal closed

@onready var title_label: Label = $Panel/Margin/VBox/Header/Title
@onready var subtitle_label: Label = $Panel/Margin/VBox/Subtitle
@onready var summary_label: Label = $Panel/Margin/VBox/Summary
@onready var orders_list: VBoxContainer = $Panel/Margin/VBox/Scroll/OrdersList
@onready var status_label: Label = $Panel/Margin/VBox/Status
@onready var close_button: Button = $Panel/Margin/VBox/Header/CloseButton

var _status_text: String = ""


func _ready() -> void:
	visible = false
	close_button.pressed.connect(close_board)
	if DailyOrders != null and DailyOrders.has_signal("state_changed"):
		DailyOrders.state_changed.connect(_on_orders_changed)
	if DailyOrders != null and DailyOrders.has_signal("reward_claimed"):
		DailyOrders.reward_claimed.connect(_on_reward_claimed)
	_refresh()


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if not (event is InputEventKey):
		return
	if not event.pressed or event.echo:
		return
	if event.keycode != KEY_ESCAPE:
		return
	close_board()
	get_viewport().set_input_as_handled()


func open_board() -> void:
	_status_text = ""
	visible = true
	_refresh()


func close_board() -> void:
	if not visible:
		return
	visible = false
	closed.emit()


func _refresh() -> void:
	title_label.text = "Daily Orders"
	subtitle_label.text = "Three small contracts refresh at the start of each new day."
	for child in orders_list.get_children():
		orders_list.remove_child(child)
		child.queue_free()
	var cards: Array[Dictionary] = []
	if DailyOrders != null and DailyOrders.has_method("get_order_cards"):
		cards = DailyOrders.get_order_cards()
	if cards.is_empty():
		var empty_label := Label.new()
		empty_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		empty_label.text = "No orders are loaded yet."
		orders_list.add_child(empty_label)
		summary_label.text = ""
		status_label.text = _status_text
		return
	var ready_count := 0
	for card in cards:
		if bool(card.get("can_claim", false)):
			ready_count += 1
		orders_list.add_child(_build_order_card(card))
	summary_label.text = "%d ready to claim" % ready_count if ready_count > 0 else "No rewards ready yet."
	status_label.text = _status_text


func _build_order_card(card: Dictionary) -> Control:
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 14)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_right", 14)
	margin.add_theme_constant_override("margin_bottom", 12)
	panel.add_child(margin)

	var content := VBoxContainer.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 6)
	margin.add_child(content)

	var name_label := Label.new()
	name_label.text = String(card.get("name", "Order"))
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(name_label)

	var description_label := Label.new()
	description_label.text = String(card.get("description", ""))
	description_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	description_label.theme_type_variation = &"BodyMutedLabel"
	content.add_child(description_label)

	var objective_label := Label.new()
	objective_label.text = "%s  %s" % [String(card.get("objective", "")), String(card.get("progress_text", "0/0"))]
	objective_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(objective_label)

	var footer := HBoxContainer.new()
	footer.add_theme_constant_override("separation", 12)
	content.add_child(footer)

	var reward_label := Label.new()
	reward_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	reward_label.text = String(card.get("reward_text", ""))
	reward_label.theme_type_variation = &"BodyMutedLabel"
	footer.add_child(reward_label)

	var status_label := Label.new()
	status_label.text = String(card.get("status_text", ""))
	footer.add_child(status_label)

	if bool(card.get("can_claim", false)):
		var claim_button := Button.new()
		var order_id := int(card.get("id", 0))
		var order_name := String(card.get("name", "Order"))
		claim_button.text = "Claim"
		claim_button.pressed.connect(func() -> void:
			var result: Dictionary = DailyOrders.claim_order(order_id) if DailyOrders != null and DailyOrders.has_method("claim_order") else {"ok": false}
			if not bool(result.get("ok", false)):
				_status_text = "Unable to claim %s right now." % order_name
			else:
				var reward_variant: Variant = result.get("reward", {})
				var reward: Dictionary = reward_variant if reward_variant is Dictionary else {}
				_status_text = "Claimed %s for +%d gold." % [order_name, int(reward.get("gold", 0))]
			_refresh()
		)
		footer.add_child(claim_button)

	return panel


func _on_orders_changed() -> void:
	if visible:
		_refresh()


func _on_reward_claimed(_order_id: int, _reward: Dictionary) -> void:
	if visible:
		_refresh()
