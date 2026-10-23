extends Node
## SaveManager: owns the save file and moving between the main menu and a run. There is one save
## slot. A run started or continued from the main menu autosaves at the start and end of each
## day; a day scene run on its own (F6, tests) only saves when asked.

const SAVE_PATH := "user://saves/run.tres"
const MAIN_MENU_SCENE := "res://menus/main_menu.tscn"
const DAY_SCENE := "res://day/day.tscn"
## A save is plain data: it may only point at the game's own files, never carry its own code
const UNSAFE_SAVE_MARKERS: Array[String] = ['type="GDScript"', 'path="user://', 'path="/']

var _autosave_enabled := false
var _pending_load: SaveGame = null


func has_save(path: String = SAVE_PATH) -> bool:
	return FileAccess.file_exists(path)


## Reads a save, or returns null if there is none or it can't be used
func read_save(path: String = SAVE_PATH) -> SaveGame:
	if not has_save(path):
		return null
	var text := FileAccess.get_file_as_string(path)
	for marker in UNSAFE_SAVE_MARKERS:
		if text.contains(marker):
			push_warning("Refusing to load %s: it isn't a plain save file." % path)
			return null
	var game := ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_IGNORE) as SaveGame
	if game == null:
		push_warning("Couldn't read the save at %s." % path)
		return null
	if game.format_version != SaveGame.FORMAT_VERSION or game.player == null:
		push_warning(
			(
				"The save at %s is from another version (%d, not %d)."
				% [path, game.format_version, SaveGame.FORMAT_VERSION]
			)
		)
		return null
	return game


func write_save(game: SaveGame, path: String = SAVE_PATH) -> Error:
	game.format_version = SaveGame.FORMAT_VERSION
	game.saved_at = Time.get_datetime_string_from_system()
	var err := DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	if err != OK:
		return err
	err = ResourceSaver.save(game, path)
	if err != OK:
		push_warning("Couldn't save to %s (error %d)." % [path, err])
	return err


func delete_save(path: String = SAVE_PATH) -> void:
	if has_save(path):
		DirAccess.remove_absolute(path)


## Saves only during a run started from the main menu
func autosave(game: SaveGame) -> void:
	if _autosave_enabled:
		write_save(game)


func start_new_game() -> void:
	_pending_load = null
	_autosave_enabled = true
	get_tree().paused = false
	get_tree().change_scene_to_file(DAY_SCENE)


## Opens the saved run; returns false, staying put, if there is no usable save
func continue_game() -> bool:
	var game := read_save()
	if game == null:
		return false
	_pending_load = game
	_autosave_enabled = true
	get_tree().paused = false
	get_tree().change_scene_to_file(DAY_SCENE)
	return true


## The save the day scene should open with, if any. Taking it clears it.
func take_pending_load() -> SaveGame:
	var game := _pending_load
	_pending_load = null
	return game


## Leaves any run without saving it (the caller saves first) and shows the main menu
func open_main_menu() -> void:
	_autosave_enabled = false
	get_tree().paused = false
	get_tree().change_scene_to_file(MAIN_MENU_SCENE)
