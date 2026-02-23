extends Control
class_name MainMenuView

signal play_pressed
signal profile_pressed
signal settings_pressed
signal quit_pressed

const UIMotionClass := preload("res://scripts/ui/ui_motion.gd")
const MENU_BACKDROP_TEXTURE_PATH := "res://assets/textures/commercial/neon_grid_bg.png"
const DEFAULT_LANGUAGE_CODE := "en"
const SUPPORTED_LANGUAGE_CODES: Array[String] = ["en", "zh_CN"]
const LANGUAGE_LABELS := {
	"en": "English",
	"zh_CN": "中文"
}
const MENU_TEXT := {
	"en": {
		"subtitle": "FOG / SONAR / NOISE",
		"play": "Play",
		"profile": "Profile",
		"settings": "Settings",
		"quit": "Quit",
		"language": "Language",
		"placeholder_profile": "Profile page is coming soon.",
		"placeholder_settings": "Settings page is coming soon."
	},
	"zh_CN": {
		"subtitle": "迷雾 / 声呐 / 噪声",
		"play": "开始游戏",
		"profile": "档案",
		"settings": "设置",
		"quit": "退出游戏",
		"language": "语言",
		"placeholder_profile": "档案页面即将推出。",
		"placeholder_settings": "设置页面即将推出。"
	}
}

@onready var background_rect: ColorRect = $BackgroundLayer/Background
@onready var backdrop_texture: TextureRect = $BackgroundLayer/BackdropTexture
@onready var glow_overlay: ColorRect = $BackgroundLayer/GlowOverlay
@onready var title_label: Label = $ContentLayer/Stack/Title
@onready var subtitle_label: Label = $ContentLayer/Stack/Subtitle
@onready var language_label: Label = $ContentLayer/Stack/LanguageRow/LanguageLabel
@onready var language_select: OptionButton = $ContentLayer/Stack/LanguageRow/LanguageSelect
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
var _current_language_code: String = DEFAULT_LANGUAGE_CODE


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	mouse_filter = Control.MOUSE_FILTER_STOP
	if background_rect.material is ShaderMaterial:
		_background_material = background_rect.material
	_buttons = [play_button, profile_button, settings_button, quit_button]
	_connect_signals()
	_setup_focus_loop()
	_apply_optional_backdrop_texture()
	_setup_language_selector()
	_update_version_text()
	_set_labels()
	tooltip_bubble.visible = false
	_focus_button(0)
	_set_motion_enabled(true)
	UIMotionClass.panel_pop_in($ContentLayer/Stack, 0.18, 10.0)


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
	language_select.item_selected.connect(_on_language_selected)
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
	subtitle_label.text = _localized_text("subtitle")
	play_button.text = _localized_text("play")
	profile_button.text = _localized_text("profile")
	settings_button.text = _localized_text("settings")
	quit_button.text = _localized_text("quit")
	language_label.text = _localized_text("language")


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
	_show_placeholder(_localized_text("placeholder_profile"))


func _on_settings_pressed() -> void:
	settings_pressed.emit()
	_show_placeholder(_localized_text("placeholder_settings"))


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


func _apply_optional_backdrop_texture() -> void:
	if backdrop_texture == null:
		return
	if not ResourceLoader.exists(MENU_BACKDROP_TEXTURE_PATH, "Texture2D"):
		backdrop_texture.visible = false
		return
	var texture_variant := load(MENU_BACKDROP_TEXTURE_PATH)
	if texture_variant is Texture2D:
		backdrop_texture.texture = texture_variant
		backdrop_texture.visible = true
	else:
		backdrop_texture.visible = false


func _set_motion_enabled(enabled: bool) -> void:
	for button in _buttons:
		if button != null and button.has_method("set_motion_enabled"):
			button.call("set_motion_enabled", enabled)


func _setup_language_selector() -> void:
	if language_select == null:
		return
	language_select.clear()
	for language_code in SUPPORTED_LANGUAGE_CODES:
		var label := String(LANGUAGE_LABELS.get(language_code, language_code))
		language_select.add_item(label)
	var stored_language := _load_language_code()
	_current_language_code = _normalize_language_code(stored_language)
	var selected_index := SUPPORTED_LANGUAGE_CODES.find(_current_language_code)
	if selected_index < 0:
		selected_index = 0
		_current_language_code = DEFAULT_LANGUAGE_CODE
	language_select.select(selected_index)
	_save_language_code(_current_language_code)


func _on_language_selected(index: int) -> void:
	if index < 0 or index >= SUPPORTED_LANGUAGE_CODES.size():
		return
	var selected := _normalize_language_code(SUPPORTED_LANGUAGE_CODES[index])
	if selected == _current_language_code:
		return
	_current_language_code = selected
	_save_language_code(_current_language_code)
	_set_labels()


func _localized_text(key: String) -> String:
	var locale_pack: Dictionary = MENU_TEXT.get(_current_language_code, MENU_TEXT[DEFAULT_LANGUAGE_CODE])
	return String(locale_pack.get(key, String(MENU_TEXT[DEFAULT_LANGUAGE_CODE].get(key, key))))


func _load_language_code() -> String:
	if ProfileStore == null:
		return DEFAULT_LANGUAGE_CODE
	if not ProfileStore.has_method("get_language_code"):
		return DEFAULT_LANGUAGE_CODE
	return String(ProfileStore.call("get_language_code"))


func _save_language_code(language_code: String) -> void:
	if ProfileStore == null:
		return
	if ProfileStore.has_method("set_language_code"):
		ProfileStore.call("set_language_code", language_code)


func _normalize_language_code(language_code: String) -> String:
	var code := language_code.strip_edges()
	if code.is_empty():
		return DEFAULT_LANGUAGE_CODE
	if code == "zh" or code == "zh_CN" or code == "zh-Hans":
		return "zh_CN"
	return DEFAULT_LANGUAGE_CODE


func _is_transition_busy() -> bool:
	if SceneTransition == null:
		return false
	if not SceneTransition.has_method("is_transitioning"):
		return false
	return bool(SceneTransition.call("is_transitioning"))
