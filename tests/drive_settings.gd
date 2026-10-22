extends Node

"""
Opens the settings menu over the day and saves screenshots at normal and larger text.
Run (needs a display): godot --path . res://tests/drive_settings.tscn -- <output_dir>
"""

var out_dir := "user://"
var day: Day


func _ready() -> void:
	get_tree().create_timer(30.0).timeout.connect(
		func():
			printerr("drive_settings timed out")
			get_tree().quit(1)
	)
	var args := OS.get_cmdline_user_args()
	if not args.is_empty():
		out_dir = args[0]
	var old_path: String = Settings.save_path
	Settings.save_path = out_dir.path_join("drive_settings.cfg")
	day = preload("res://day/day.tscn").instantiate()
	add_child(day)
	await _frames(5)
	Settings.open_menu()
	await _frames(3)
	_shot("01_settings_menu")

	Settings.set_text_scale(Settings.TEXT_SCALES.back())
	await _frames(3)
	_shot("02_settings_larger_text")

	Settings.close_menu()
	await _frames(3)
	_shot("03_counter_larger_text")

	day.switch_to(Day.ShopSide.INSCRIBING)
	await _frames(5)
	_shot("04_table_larger_text")

	Settings.set_text_scale(1.0)
	Settings.save_path = old_path
	get_tree().quit()


func _frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame


func _shot(shot_name: String) -> void:
	var img := get_viewport().get_texture().get_image()
	img.save_png(out_dir.path_join(shot_name + ".png"))
