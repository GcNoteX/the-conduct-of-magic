extends Node
## Settings: owns the player's preferences (volume per audio bus, text size and fullscreen),
## applies them to the engine and keeps them in user://settings.cfg. They are not part of a run's
## save data, so they carry across every run.

signal changed

const SAVE_PATH := "user://settings.cfg"
const BUS_MASTER := &"Master"
const BUS_MUSIC := &"Music"
const BUS_SFX := &"SFX"
const BUSES: Array[StringName] = [BUS_MASTER, BUS_MUSIC, BUS_SFX]
const DEFAULT_VOLUME := 0.8
## The text sizes the menu offers, as a multiple of each theme's own font sizes
const TEXT_SCALES: Array[float] = [0.85, 1.0, 1.15, 1.3]
const DEFAULT_TEXT_SCALE := 1.0
const MENU_SCENE_PATH := "res://settings/settings_menu.tscn"
const MENU_LAYER := 100
const ACTION_TOGGLE_MENU := &"toggle_settings"
const SECTION_AUDIO := "audio"
const SECTION_DISPLAY := "display"
const KEY_TEXT_SCALE := "text_scale"
const KEY_FULLSCREEN := "fullscreen"
const DEFAULT_SIZE_KEY := &""

var save_path: String = SAVE_PATH

var _volumes: Dictionary[StringName, float] = {}
var _text_scale: float = DEFAULT_TEXT_SCALE
var _fullscreen: bool = false
## Each scaled theme's own font sizes, keyed by "type/name" (DEFAULT_SIZE_KEY for its default)
var _base_sizes: Dictionary[Theme, Dictionary] = {}
var _base_fallback_size: int = 0
var _menu_layer: CanvasLayer = null
var _was_paused: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_base_fallback_size = ThemeDB.fallback_font_size
	register_theme(ThemeDB.get_default_theme())
	register_theme(ThemeDB.get_project_theme())
	load_settings()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(ACTION_TOGGLE_MENU):
		get_viewport().set_input_as_handled()
		if is_menu_open():
			close_menu()
		else:
			open_menu()


func get_volume(bus: StringName) -> float:
	return _volumes.get(bus, DEFAULT_VOLUME)


## Sets a bus's volume from 0 (silent) to 1 (full) and saves it
func set_volume(bus: StringName, volume: float) -> void:
	_volumes[bus] = clampf(volume, 0.0, 1.0)
	_apply_volume(bus)
	_save_and_notify()


func get_text_scale() -> float:
	return _text_scale


## Scales the text in every registered theme and saves it
func set_text_scale(text_scale: float) -> void:
	_text_scale = clampf(text_scale, TEXT_SCALES.front(), TEXT_SCALES.back())
	_apply_text_scale()
	_save_and_notify()


func is_fullscreen() -> bool:
	return _fullscreen


func set_fullscreen(fullscreen: bool) -> void:
	_fullscreen = fullscreen
	_apply_fullscreen()
	_save_and_notify()


## Lets the text size setting scale a theme that isn't the project theme, such as a scene's own.
## The theme's font sizes as they are now are taken as its normal size.
func register_theme(theme: Theme) -> void:
	if theme == null or theme in _base_sizes:
		return
	var sizes: Dictionary[StringName, int] = {}
	if theme.has_default_font_size():
		sizes[DEFAULT_SIZE_KEY] = theme.default_font_size
	for type in theme.get_font_size_type_list():
		for size_name in theme.get_font_size_list(type):
			sizes[_size_key(type, size_name)] = theme.get_font_size(size_name, type)
	_base_sizes[theme] = sizes
	_scale_theme(theme)


## Shows the settings menu over everything else, pausing the game until it closes. Menus that
## open it themselves can instead add settings_menu.tscn to their own tree and listen for its
## closed signal.
func open_menu() -> void:
	if is_menu_open():
		return
	_menu_layer = CanvasLayer.new()
	_menu_layer.layer = MENU_LAYER
	_menu_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	var menu: SettingsMenu = load(MENU_SCENE_PATH).instantiate()
	menu.closed.connect(close_menu)
	_menu_layer.add_child(menu)
	add_child(_menu_layer)
	_was_paused = get_tree().paused
	get_tree().paused = true


func close_menu() -> void:
	if not is_menu_open():
		return
	_menu_layer.queue_free()
	_menu_layer = null
	get_tree().paused = _was_paused


func is_menu_open() -> bool:
	return _menu_layer != null


## Reads the settings file and applies it. Missing values keep their defaults.
func load_settings() -> void:
	var config := ConfigFile.new()
	config.load(save_path)
	for bus in BUSES:
		_volumes[bus] = clampf(
			float(config.get_value(SECTION_AUDIO, bus, DEFAULT_VOLUME)), 0.0, 1.0
		)
	_text_scale = clampf(
		float(config.get_value(SECTION_DISPLAY, KEY_TEXT_SCALE, DEFAULT_TEXT_SCALE)),
		TEXT_SCALES.front(),
		TEXT_SCALES.back()
	)
	_fullscreen = bool(config.get_value(SECTION_DISPLAY, KEY_FULLSCREEN, false))
	for bus in BUSES:
		_apply_volume(bus)
	_apply_text_scale()
	_apply_fullscreen()
	changed.emit()


func save_settings() -> void:
	var config := ConfigFile.new()
	for bus in BUSES:
		config.set_value(SECTION_AUDIO, bus, get_volume(bus))
	config.set_value(SECTION_DISPLAY, KEY_TEXT_SCALE, _text_scale)
	config.set_value(SECTION_DISPLAY, KEY_FULLSCREEN, _fullscreen)
	var err := config.save(save_path)
	if err != OK:
		push_warning("Couldn't save settings to %s: %s" % [save_path, error_string(err)])


func _save_and_notify() -> void:
	save_settings()
	changed.emit()


func _apply_volume(bus: StringName) -> void:
	var index := AudioServer.get_bus_index(bus)
	if index < 0:
		push_warning("No audio bus named %s" % bus)
		return
	var volume := get_volume(bus)
	AudioServer.set_bus_mute(index, is_zero_approx(volume))
	AudioServer.set_bus_volume_db(index, linear_to_db(maxf(volume, 0.0001)))


func _apply_text_scale() -> void:
	ThemeDB.fallback_font_size = _scaled(_base_fallback_size)
	for theme in _base_sizes:
		_scale_theme(theme)


func _apply_fullscreen() -> void:
	if DisplayServer.get_name() == "headless":
		return
	var mode := (
		DisplayServer.WINDOW_MODE_FULLSCREEN if _fullscreen else DisplayServer.WINDOW_MODE_WINDOWED
	)
	if DisplayServer.window_get_mode() != mode:
		DisplayServer.window_set_mode(mode)


func _scale_theme(theme: Theme) -> void:
	var sizes: Dictionary = _base_sizes[theme]
	for key: StringName in sizes:
		var size := _scaled(sizes[key])
		if key == DEFAULT_SIZE_KEY:
			theme.default_font_size = size
		else:
			var parts := String(key).split("/")
			theme.set_font_size(parts[1], parts[0], size)


func _scaled(size: int) -> int:
	return maxi(1, roundi(size * _text_scale))


func _size_key(type: StringName, size_name: StringName) -> StringName:
	return StringName("%s/%s" % [type, size_name])
