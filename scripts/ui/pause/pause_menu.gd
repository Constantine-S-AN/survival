extends Control
class_name PauseMenuView

signal resume_pressed
signal settings_pressed
signal main_menu_pressed
signal quit_pressed

@onready var title_label: Label = $Backdrop/Panel/Margin/VBox/Title
@onready var hint_label: Label = $Backdrop/Panel/Margin/VBox/Hint
@onready var resume_button: Button = $Backdrop/Panel/Margin/VBox/ResumeButton
@onready var settings_button: Button = $Backdrop/Panel/Margin/VBox/SettingsButton
@onready var menu_button: Button = $Backdrop/Panel/Margin/VBox/MainMenuButton
@onready var quit_button: Button = $Backdrop/Panel/Margin/VBox/QuitButton

var _buttons: Array[Button] = []
var _focused_index: int = 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	mouse_filter = Control.MOUSE_FILTER_STOP
	_buttons = [resume_button, settings_button, menu_button, quit_button]
	_connect_signals()
	_setup_focus_loop()
	if Localization != null and Localization.has_signal("language_changed"):
		Localization.language_changed.connect(_on_language_changed)
	_set_labels()
	_focus_button(0)


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if not (event is InputEventKey):
		return
	if not event.pressed or event.echo:
		return

	match event.keycode:
		KEY_UP:
			_move_focus(-1)
			accept_event()
		KEY_DOWN:
			_move_focus(1)
			accept_event()
		KEY_ENTER, KEY_KP_ENTER, KEY_SPACE:
			_activate_focused_button()
			accept_event()
		KEY_ESCAPE:
			resume_pressed.emit()
			accept_event()
		_:
			pass


func _connect_signals() -> void:
	resume_button.pressed.connect(func() -> void:
		resume_pressed.emit()
	)
	settings_button.pressed.connect(func() -> void:
		settings_pressed.emit()
	)
	menu_button.pressed.connect(func() -> void:
		main_menu_pressed.emit()
	)
	quit_button.pressed.connect(func() -> void:
		quit_pressed.emit()
	)
	for i in range(_buttons.size()):
		_buttons[i].focus_entered.connect(_on_button_focus_entered.bind(i))
		_buttons[i].mouse_entered.connect(_on_button_focus_entered.bind(i))


func _setup_focus_loop() -> void:
	for i in range(_buttons.size()):
		var prev := _buttons[(i - 1 + _buttons.size()) % _buttons.size()].get_path()
		var next := _buttons[(i + 1) % _buttons.size()].get_path()
		_buttons[i].focus_neighbor_top = prev
		_buttons[i].focus_neighbor_bottom = next


func _focus_button(index: int) -> void:
	if _buttons.is_empty():
		return
	_focused_index = wrapi(index, 0, _buttons.size())
	var target := _buttons[_focused_index]
	if target == null:
		return
	target.grab_focus()


func _move_focus(step: int) -> void:
	if _buttons.is_empty():
		return
	_focus_button(_focused_index + step)


func _activate_focused_button() -> void:
	if _focused_index < 0 or _focused_index >= _buttons.size():
		return
	var target := _buttons[_focused_index]
	if target == null or target.disabled:
		return
	target.pressed.emit()


func _on_button_focus_entered(index: int) -> void:
	_focused_index = clampi(index, 0, _buttons.size() - 1)


func _on_language_changed(_language_code: String) -> void:
	_set_labels()


func _set_labels() -> void:
	title_label.text = _t("pause.title")
	hint_label.text = _t("pause.hint")
	resume_button.text = _t("pause.resume")
	settings_button.text = _t("pause.settings")
	menu_button.text = _t("pause.main_menu")
	quit_button.text = _t("pause.quit")


func _t(key: String, args: Dictionary = {}) -> String:
	if Localization == null or not Localization.has_method("t"):
		return key
	return String(Localization.call("t", key, args))
