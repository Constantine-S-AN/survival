extends Control
class_name MainMenuView

signal play_pressed
signal profile_pressed
signal settings_pressed
signal quit_pressed

const PLACEHOLDER_PROFILE := "Profile page is coming soon."
const PLACEHOLDER_SETTINGS := "Settings page is coming soon."

@onready var background_rect: ColorRect = $BackgroundLayer/Background
@onready var glow_overlay: ColorRect = $BackgroundLayer/GlowOverlay
@onready var title_label: Label = $ContentLayer/Stack/Title
@onready var subtitle_label: Label = $ContentLayer/Stack/Subtitle
@onready var buttons_box: VBoxContainer = $ContentLayer/Stack/Buttons
@onready var play_button: Button = $ContentLayer/Stack/Buttons/PlayButton
@onready var profile_button: Button = $ContentLayer/Stack/Buttons/ProfileButton
@onready var settings_button: Button = $ContentLayer/Stack/Buttons/SettingsButton
@onready var quit_button: Button = $ContentLayer/Stack/Buttons/QuitButton
@onready var version_label: Label = $VersionLabel
@onready var tooltip_bubble: PanelContainer = $PlaceholderTooltip

var _buttons: Array[Button] = []
var _focused_index: int = 0
var _bg_time: float = 0.0
var _background_material: ShaderMaterial


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	mouse_filter = Control.MOUSE_FILTER_STOP
	if background_rect.material is ShaderMaterial:
		_background_material = background_rect.material
	_buttons = [play_button, profile_button, settings_button, quit_button]
	_connect_signals()
	_setup_focus_loop()
	_update_version_text()
	_set_labels()
	tooltip_bubble.visible = false
	_focus_button(0)
	_set_motion_enabled(true)


func _process(delta: float) -> void:
	_bg_time += delta
	if _background_material != null:
		_background_material.set_shader_parameter("time_sec", _bg_time)
	glow_overlay.modulate.a = 0.08 + sin(_bg_time * 0.42) * 0.014


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
			_on_quit_pressed()
			accept_event()
		_:
			pass


func set_motion_enabled(enabled: bool) -> void:
	_set_motion_enabled(enabled)


func focus_button_by_id(button_id: String) -> void:
	var id := button_id.strip_edges().to_lower()
	match id:
		"play":
			_focus_button(0)
		"profile":
			_focus_button(1)
		"settings":
			_focus_button(2)
		"quit":
			_focus_button(3)
		_:
			_focus_button(0)


func _connect_signals() -> void:
	play_button.pressed.connect(_on_play_pressed)
	profile_button.pressed.connect(_on_profile_pressed)
	settings_button.pressed.connect(_on_settings_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
	for i in range(_buttons.size()):
		_buttons[i].focus_entered.connect(_on_button_focus_entered.bind(i))
		_buttons[i].mouse_entered.connect(_on_button_focus_entered.bind(i))


func _setup_focus_loop() -> void:
	for i in range(_buttons.size()):
		var prev := _buttons[(i - 1 + _buttons.size()) % _buttons.size()].get_path()
		var next := _buttons[(i + 1) % _buttons.size()].get_path()
		_buttons[i].focus_neighbor_top = prev
		_buttons[i].focus_neighbor_bottom = next


func _update_version_text() -> void:
	var project_version := String(ProjectSettings.get_setting("application/config/version", "dev")).strip_edges()
	if project_version.is_empty():
		project_version = "dev"
	var godot_version := String(Engine.get_version_info().get("string", "4.x"))
	version_label.text = "v%s  |  Godot %s" % [project_version, godot_version]


func _set_labels() -> void:
	title_label.text = "s u r v i v e"
	subtitle_label.text = "FOG / SONAR / NOISE"


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


func _on_play_pressed() -> void:
	if _is_transition_busy():
		return
	play_pressed.emit()


func _on_profile_pressed() -> void:
	profile_pressed.emit()
	_show_placeholder(PLACEHOLDER_PROFILE)


func _on_settings_pressed() -> void:
	settings_pressed.emit()
	_show_placeholder(PLACEHOLDER_SETTINGS)


func _on_quit_pressed() -> void:
	if _is_transition_busy():
		return
	quit_pressed.emit()


func _show_placeholder(message: String) -> void:
	if tooltip_bubble == null:
		return
	tooltip_bubble.position = Vector2(buttons_box.position.x + 6.0, buttons_box.position.y + buttons_box.size.y + 12.0)
	if tooltip_bubble.has_method("show_tooltip"):
		tooltip_bubble.call("show_tooltip", message, 1.8)


func _set_motion_enabled(enabled: bool) -> void:
	for button in _buttons:
		if button != null and button.has_method("set_motion_enabled"):
			button.call("set_motion_enabled", enabled)


func _is_transition_busy() -> bool:
	if SceneTransition == null:
		return false
	if not SceneTransition.has_method("is_transitioning"):
		return false
	return bool(SceneTransition.call("is_transitioning"))
