extends Node

"""
Drives the inscribing table with simulated mouse input and saves screenshots.
Run (needs a display): godot --path . res://tests/drive_table.tscn -- <output_dir>
"""

var out_dir := "user://"
var table: Control
var view: BoardView


func _ready() -> void:
	get_tree().create_timer(30.0).timeout.connect(
		func():
			printerr("drive_table timed out")
			get_tree().quit(1)
	)
	var args := OS.get_cmdline_user_args()
	if not args.is_empty():
		out_dir = args[0]
	table = preload("res://inscribing/inscribing_table.tscn").instantiate()
	add_child(table)
	await _frames(5)
	view = table._view
	_shot("01_empty")

	# Place Kindle with the mouse
	table._enchantments.select(0)
	table._on_enchantment_selected(0)
	_move(_cell(Vector2i(1, 5)))
	await _frames(2)
	_shot("02_ghost")
	_click(_cell(Vector2i(1, 5)), MOUSE_BUTTON_LEFT)
	await _frames(2)
	var p: PlacementState = table.board.state.placements[0]
	var e0 := InscriptionBoard.enchantment_key(p.id, 0)
	var e1 := InscriptionBoard.enchantment_key(p.id, 1)
	print("placed: ", table.board.state.placements.size())
	_move(_cell(Vector2i(3, 5)))
	await _frames(2)
	_shot("03_requirements")

	# Drag fire onto the flame node, showing the drop preview first
	var mats: Array[EnchantmentMaterialDefinition] = table._materials.materials
	table._on_material_drag_started(mats[0])
	table._board_area._can_drop_data(_area(Vector2i(1, 5)), mats[0])
	await _frames(2)
	_shot("04_drop_preview")
	table._board_area._drop_data(_area(Vector2i(1, 5)), mats[0])
	table._board_area._drop_data(_area(Vector2i(3, 5)), mats[3])
	await _frames(2)
	_move(_cell(Vector2i(1, 5)))
	await _frames(2)
	_shot("04b_inserted")
	print("materials: ", table.board.node_material(e0), " ", table.board.node_material(e1))

	# Draw lines cell by cell, with a wobble back along the first one
	_draw_path([Vector2i(1, 5), Vector2i(1, 6), Vector2i(0, 7), Vector2i(1, 6), Vector2i(1, 7)])
	_draw_path([Vector2i(1, 5), Vector2i(1, 4), Vector2i(0, 4)])
	_draw_path([Vector2i(3, 5), Vector2i(4, 4)])
	_draw_path(
		[Vector2i(-7, 14), Vector2i(-6, 14), Vector2i(-5, 14), Vector2i(-4, 14), Vector2i(-3, 14)]
	)
	await _frames(2)
	print(
		"lines: ", table.board.state.lines.size(), " active: ", table.board.is_placement_active(p)
	)
	# Try to cross the first line and hold the mouse there
	_draw_path([Vector2i(3, 5), Vector2i(2, 6), Vector2i(1, 6)], false)
	await _frames(2)
	_shot("05_blocked")
	_release(_cell(Vector2i(1, 6)))
	_move(_cell(Vector2i(1, 5)))
	await _frames(2)
	_shot("06_active")

	# The unconnected chain blocks the commit until it's removed
	print("commit button: ", table._commit_button.text)
	_click(_cell(Vector2i(-5, 14)), MOUSE_BUTTON_RIGHT)
	await _frames(2)
	table._on_commit_pressed()
	await _frames(2)
	print("committed: ", p.committed, " message: ", table._message_label.text)
	_shot("07_committed")

	table.time_left = 0.01
	await _frames(3)
	_shot("08_day_over")
	get_tree().quit()


func _cell(c: Vector2i) -> Vector2:
	return view.get_global_transform_with_canvas() * view.to_screen(Hex.to_pixel(c, 1.0))


func _move(pos: Vector2) -> void:
	Input.warp_mouse(pos)  # Keeps the real cursor with the simulated one, for the tooltip
	var ev := InputEventMouseMotion.new()
	ev.position = pos
	ev.global_position = pos
	Input.parse_input_event(ev)
	Input.flush_buffered_events()


func _click(pos: Vector2, button: MouseButton) -> void:
	_move(pos)
	_button(pos, button, true)
	_button(pos, button, false)


func _area(c: Vector2i) -> Vector2:
	return view.position + view.cell_screen(c)


## Presses on the first cell, moves through the rest one by one, then releases unless told not to
func _draw_path(cells: Array, release := true) -> void:
	var start := _cell(cells[0])
	_move(start)
	_button(start, MOUSE_BUTTON_LEFT, true)
	for c in cells.slice(1):
		_move(_cell(c))
	if release:
		_release(_cell(cells.back()))


func _release(pos: Vector2) -> void:
	_button(pos, MOUSE_BUTTON_LEFT, false)


func _button(pos: Vector2, button: MouseButton, pressed: bool) -> void:
	var ev := InputEventMouseButton.new()
	ev.position = pos
	ev.global_position = pos
	ev.button_index = button
	ev.pressed = pressed
	Input.parse_input_event(ev)
	Input.flush_buffered_events()


func _frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame


func _shot(name: String) -> void:
	var img := get_viewport().get_texture().get_image()
	img.save_png(out_dir.path_join(name + ".png"))
