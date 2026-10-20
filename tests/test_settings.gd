extends Node

"""
Headless checks for the Settings autoload: volume, text size, saving and the menu.
Run: godot --headless --path . res://tests/test_settings.tscn
Exits with code 1 if any check fails.
"""

const SETTINGS := preload("res://globals/settings.gd")
const MENU_SCENE := preload("res://settings/settings_menu.tscn")
const TEST_PATH := "user://test_settings.cfg"

var _failures := 0
var _checks := 0


func _ready() -> void:
	DirAccess.remove_absolute(TEST_PATH)
	test_buses()
	test_volume()
	test_text_scale()
	test_save_and_load()
	test_menu()
	test_open_menu_pauses()
	DirAccess.remove_absolute(TEST_PATH)
	print("%d checks, %d failed" % [_checks, _failures])
	get_tree().quit(1 if _failures > 0 else 0)


func check(cond: bool, what: String) -> void:
	_checks += 1
	if not cond:
		_failures += 1
		printerr("FAIL: ", what)


func new_settings() -> Node:
	var settings: Node = SETTINGS.new()
	settings.save_path = TEST_PATH
	add_child(settings)
	return settings


func test_buses() -> void:
	for bus in SETTINGS.BUSES:
		check(AudioServer.get_bus_index(bus) >= 0, "the %s bus exists" % bus)
	var bank := SoundBank.new()
	bank.sounds = {&"beep": AudioStreamWAV.new()}
	add_child(bank)
	check(bank.get_child(0).bus == SETTINGS.BUS_SFX, "sound effects play on the SFX bus")
	bank.free()


func test_volume() -> void:
	var settings := new_settings()
	var music := AudioServer.get_bus_index(SETTINGS.BUS_MUSIC)
	settings.set_volume(SETTINGS.BUS_MUSIC, 0.5)
	check(is_equal_approx(settings.get_volume(SETTINGS.BUS_MUSIC), 0.5), "volume is kept")
	check(
		is_equal_approx(AudioServer.get_bus_volume_db(music), linear_to_db(0.5)),
		"half volume sets the Music bus to about -6 dB"
	)
	check(not AudioServer.is_bus_mute(music), "half volume isn't muted")
	settings.set_volume(SETTINGS.BUS_MUSIC, 0.0)
	check(AudioServer.is_bus_mute(music), "zero volume mutes the bus")
	settings.set_volume(SETTINGS.BUS_MUSIC, 3.0)
	check(is_equal_approx(settings.get_volume(SETTINGS.BUS_MUSIC), 1.0), "volume stops at 1")
	settings.free()


func test_text_scale() -> void:
	var settings := new_settings()
	var theme := Theme.new()
	theme.default_font_size = 20
	theme.set_font_size(&"font_size", &"Label", 40)
	settings.register_theme(theme)
	var fallback := ThemeDB.fallback_font_size
	settings.set_text_scale(1.3)
	check(theme.default_font_size == 26, "larger text scales the default size, 20 to 26")
	check(theme.get_font_size(&"font_size", &"Label") == 52, "larger text scales Label, 40 to 52")
	check(ThemeDB.fallback_font_size == roundi(fallback * 1.3), "the fallback size scales too")
	settings.set_text_scale(0.85)
	check(theme.default_font_size == 17, "small text scales from the original, 20 to 17")
	settings.set_text_scale(1.0)
	check(theme.default_font_size == 20, "normal text restores the original size")
	check(theme.get_font_size(&"font_size", &"Label") == 40, "normal text restores Label")
	check(ThemeDB.fallback_font_size == fallback, "normal text restores the fallback size")
	settings.set_text_scale(5.0)
	check(is_equal_approx(settings.get_text_scale(), 1.3), "text scale stops at the largest")
	settings.set_text_scale(1.0)
	var late := Theme.new()
	late.default_font_size = 30
	settings.set_text_scale(1.15)
	settings.register_theme(late)
	check(late.default_font_size == 35, "a theme registered later picks up the current scale")
	settings.set_text_scale(1.0)
	settings.free()


func test_save_and_load() -> void:
	DirAccess.remove_absolute(TEST_PATH)
	var settings := new_settings()
	settings.set_volume(SETTINGS.BUS_MASTER, 0.4)
	settings.set_volume(SETTINGS.BUS_SFX, 0.25)
	settings.set_text_scale(1.15)
	settings.set_fullscreen(true)
	settings.free()
	check(FileAccess.file_exists(TEST_PATH), "changing a setting saves the file")

	var loaded := new_settings()
	check(is_equal_approx(loaded.get_volume(SETTINGS.BUS_MASTER), 0.4), "master volume reloads")
	check(is_equal_approx(loaded.get_volume(SETTINGS.BUS_SFX), 0.25), "SFX volume reloads")
	check(
		is_equal_approx(loaded.get_volume(SETTINGS.BUS_MUSIC), SETTINGS.DEFAULT_VOLUME),
		"an unchanged volume reloads as the default"
	)
	check(is_equal_approx(loaded.get_text_scale(), 1.15), "text size reloads")
	check(loaded.is_fullscreen(), "fullscreen reloads")
	loaded.set_text_scale(1.0)
	loaded.set_volume(SETTINGS.BUS_MASTER, SETTINGS.DEFAULT_VOLUME)
	loaded.free()

	DirAccess.remove_absolute(TEST_PATH)
	var fresh := new_settings()
	check(
		is_equal_approx(fresh.get_volume(SETTINGS.BUS_MASTER), SETTINGS.DEFAULT_VOLUME),
		"with no file, volume starts at the default"
	)
	check(is_equal_approx(fresh.get_text_scale(), 1.0), "with no file, text starts normal")
	check(not fresh.is_fullscreen(), "with no file, the game starts windowed")
	fresh.free()


func test_menu() -> void:
	var old_path: String = Settings.save_path
	Settings.save_path = TEST_PATH
	var menu: SettingsMenu = MENU_SCENE.instantiate()
	add_child(menu)
	var sliders := menu.find_children("*", "HSlider", true, false)
	check(sliders.size() == SETTINGS.BUSES.size(), "the menu has a slider per bus")
	var music_slider: HSlider = menu._sliders[SETTINGS.BUS_MUSIC]
	music_slider.value = 0.3
	check(is_equal_approx(Settings.get_volume(SETTINGS.BUS_MUSIC), 0.3), "the slider sets volume")
	menu._text_size.select(2)
	menu._text_size.item_selected.emit(2)
	check(is_equal_approx(Settings.get_text_scale(), 1.15), "choosing Large sets the text size")
	check(menu._nearest_text_scale_index(1.0) == 1, "normal text shows as Normal")
	check(menu._nearest_text_scale_index(1.2) == 2, "an in-between size shows the nearest")
	var was_closed := [false]
	menu.closed.connect(func() -> void: was_closed[0] = true)
	menu._close_button.pressed.emit()
	check(was_closed[0], "Close emits closed")
	menu.free()
	Settings.set_text_scale(1.0)
	Settings.set_volume(SETTINGS.BUS_MUSIC, SETTINGS.DEFAULT_VOLUME)
	Settings.save_path = old_path


func test_open_menu_pauses() -> void:
	check(not Settings.is_menu_open(), "the menu starts closed")
	Settings.open_menu()
	check(Settings.is_menu_open(), "open_menu opens it")
	check(get_tree().paused, "the game pauses while it's open")
	Settings.close_menu()
	check(not Settings.is_menu_open(), "close_menu closes it")
	check(not get_tree().paused, "closing unpauses a game that wasn't paused before")
	get_tree().paused = true
	Settings.open_menu()
	Settings.close_menu()
	check(get_tree().paused, "closing leaves a game paused if it was paused before")
	get_tree().paused = false
