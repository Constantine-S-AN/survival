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


func debug_get_snapshot() -> Dictionary:
	var cards := _get_cards()
	var ordered_titles: Array[String] = []
	var ready_count := 0
	var featured_count := 0
	for card in cards:
		ordered_titles.append(String(card.get("name", "")).strip_edges())
		if bool(card.get("can_claim", false)):
			ready_count += 1
		if bool(card.get("featured", false)):
			featured_count += 1
	return {
		"visible": visible,
		"title_text": title_label.text if title_label != null else "",
		"subtitle_text": subtitle_label.text if subtitle_label != null else "",
		"summary_text": summary_label.text if summary_label != null else "",
		"status_text": status_label.text if status_label != null else "",
		"featured_titles": _get_featured_titles(2),
		"ordered_titles": ordered_titles,
		"ready_count": ready_count,
		"featured_count": featured_count
	}


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
	title_label.text = _t("meta.orders.title")
	subtitle_label.text = _build_subtitle_text()
	for child in orders_list.get_children():
		orders_list.remove_child(child)
		child.queue_free()
	var cards: Array[Dictionary] = []
	if DailyOrders != null and DailyOrders.has_method("get_order_cards"):
		cards = DailyOrders.get_order_cards()
	if cards.is_empty():
		var empty_label := Label.new()
		empty_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		empty_label.text = _t("meta.orders.empty")
		orders_list.add_child(empty_label)
		summary_label.text = ""
		status_label.text = _status_text
		return
	var ready_count := 0
	var featured_count := 0
	for card in cards:
		if bool(card.get("can_claim", false)):
			ready_count += 1
		if bool(card.get("featured", false)):
			featured_count += 1
	for pillar in [DailyOrderQuest.PILLAR_FARM, DailyOrderQuest.PILLAR_RESTAURANT, DailyOrderQuest.PILLAR_NIGHT]:
		_append_pillar_section(cards, pillar)
	summary_label.text = _build_summary_text(cards.size(), ready_count, featured_count)
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

	if bool(card.get("featured", false)):
		var featured_label := Label.new()
		featured_label.text = _t("meta.orders.badge_featured")
		featured_label.theme_type_variation = &"BodyMutedLabel"
		content.add_child(featured_label)

	var pillar_label := Label.new()
	pillar_label.text = String(card.get("pillar_title", "Orders"))
	pillar_label.theme_type_variation = &"BodyMutedLabel"
	content.add_child(pillar_label)

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
	reward_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	reward_label.theme_type_variation = &"BodyMutedLabel"
	footer.add_child(reward_label)

	var status_label := Label.new()
	status_label.text = String(card.get("status_text", ""))
	footer.add_child(status_label)

	if bool(card.get("can_claim", false)):
		var claim_button := Button.new()
		var order_id := int(card.get("id", 0))
		var order_name := String(card.get("name", "Order"))
		claim_button.text = _t("meta.orders.claim")
		claim_button.pressed.connect(func() -> void:
			var result: Dictionary = DailyOrders.claim_order(order_id) if DailyOrders != null and DailyOrders.has_method("claim_order") else {"ok": false}
			if not bool(result.get("ok", false)):
				_status_text = _t("meta.orders.claim_failed", {"value": order_name})
			else:
				var reward_variant: Variant = result.get("reward", {})
				var reward: Dictionary = reward_variant if reward_variant is Dictionary else {}
				var reward_text := DailyOrders.describe_reward(reward) if DailyOrders != null and DailyOrders.has_method("describe_reward") else ""
				_status_text = (
					_t("meta.orders.claimed_with_reward", {"name": order_name, "reward": reward_text})
					if not reward_text.is_empty()
					else _t("meta.orders.claimed", {"value": order_name})
				)
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


func _append_pillar_section(cards: Array[Dictionary], pillar: String) -> void:
	var section_cards: Array[Dictionary] = []
	for card in cards:
		if String(card.get("pillar", "")) != pillar:
			continue
		section_cards.append(card)
	if section_cards.is_empty():
		return
	var heading := Label.new()
	heading.text = String(section_cards[0].get("pillar_title", "Orders"))
	heading.theme_type_variation = &"HeadingLabel"
	orders_list.add_child(heading)
	for card in section_cards:
		orders_list.add_child(_build_order_card(card))


func _build_subtitle_text() -> String:
	var featured_names := _get_featured_titles(2)
	if not featured_names.is_empty():
		return _t("meta.orders.subtitle_featured", {"value": ", ".join(featured_names)})
	return _t("meta.orders.subtitle")


func _build_summary_text(active_count: int, ready_count: int, featured_count: int) -> String:
	if featured_count > 0:
		return _t("meta.orders.summary_featured", {
			"active": active_count,
			"ready": ready_count,
			"featured": featured_count
		})
	return _t("meta.orders.summary", {
		"active": active_count,
		"ready": ready_count
	})


func _get_cards() -> Array[Dictionary]:
	var cards: Array[Dictionary] = []
	if DailyOrders != null and DailyOrders.has_method("get_order_cards"):
		cards = DailyOrders.get_order_cards()
	return cards


func _get_featured_titles(limit: int) -> Array[String]:
	var titles: Array[String] = []
	if DailyOrders == null or not DailyOrders.has_method("get_featured_order_cards"):
		return titles
	var cards_variant: Variant = DailyOrders.call("get_featured_order_cards", limit)
	if not (cards_variant is Array):
		return titles
	for card_variant in cards_variant:
		if not (card_variant is Dictionary):
			continue
		var title := String((card_variant as Dictionary).get("name", "")).strip_edges()
		if title.is_empty():
			continue
		titles.append(title)
	return titles


func _t(key: String, args: Dictionary = {}) -> String:
	if Localization == null or not Localization.has_method("t"):
		return key
	return String(Localization.call("t", key, args))
