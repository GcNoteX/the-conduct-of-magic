extends Node

"""
Drives the inscribing table with simulated mouse input and saves screenshots.
Run (needs a display): godot --path . res://tests/drive_table.tscn -- <output_dir>
"""

var out_dir := "user://"
var table: Control
var view: BoardView

func _ready() -> void:
	get_tree().create_timer(30.0).timeout.connect(func(): printerr("drive_table timed out"); get_tree().quit(1))
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
	_move(_cell(Vector2i(1, 3)))
	await _frames(2)
	_shot("02_ghost")
	_click(_cell(Vector2i(1, 3)), MOUSE_BUTTON_LEFT)
	await _frames(2)
	var p: PlacementState = table.board.state.placements[0]
	var e0 := InscriptionBoard.enchantment_key(p.id, 0)
	var e1 := InscriptionBoard.enchantment_key(p.id, 1)
	print("placed: ", table.board.state.placements.size())

	# Insert fire and blue
	table._on_material_selected(0)
	_click(_cell(Vector2i(1, 3)), MOUSE_BUTTON_LEFT)
	table._on_material_selected(3)
	_click(_cell(Vector2i(2, 3)), MOUSE_BUTTON_LEFT)
	_click(_cell(Vector2i(2, 3)), MOUSE_BUTTON_RIGHT) # drop held material
	await _frames(2)
	print("materials: ", table.board.node_material(e0), " ", table.board.node_material(e1))

	# Draw lines by dragging
	_drag(Vector2i(1, 3), Vector2i(1, 2))
	_drag(Vector2i(1, 3), Vector2i(1, 5))
	_drag(Vector2i(2, 3), Vector2i(3, 2))
	_drag(Vector2i(-2, 8), Vector2i(0, 8)) # dead chain
	await _frames(2)
	print("lines: ", table.board.state.lines.size(), " active: ", table.board.is_placement_active(p))
	_move(_cell(Vector2i(1, 3)))
	await _frames(2)
	_shot("03_active")

	table._on_commit_pressed()
	await _frames(2)
	print("committed: ", p.committed, " message: ", table._message_label.text)
	_shot("04_committed")

	table.time_left = 0.01
	await _frames(3)
	_shot("05_day_over")
	get_tree().quit()

func _cell(c: Vector2i) -> Vector2:
	return view.get_global_transform_with_canvas() * view.to_screen(Hex.to_pixel(c, 1.0))

func _move(pos: Vector2) -> void:
	var ev := InputEventMouseMotion.new()
	ev.position = pos
	ev.global_position = pos
	Input.parse_input_event(ev)
	Input.flush_buffered_events()

func _click(pos: Vector2, button: MouseButton) -> void:
	_move(pos)
	for pressed in [true, false]:
		var ev := InputEventMouseButton.new()
		ev.position = pos
		ev.global_position = pos
		ev.button_index = button
		ev.pressed = pressed
		Input.parse_input_event(ev)
		Input.flush_buffered_events()

func _drag(a: Vector2i, b: Vector2i) -> void:
	var pa := _cell(a)
	var pb := _cell(b)
	_move(pa)
	var down := InputEventMouseButton.new()
	down.position = pa
	down.global_position = pa
	down.button_index = MOUSE_BUTTON_LEFT
	down.pressed = true
	Input.parse_input_event(down)
	Input.flush_buffered_events()
	_move(pb)
	var up := InputEventMouseButton.new()
	up.position = pb
	up.global_position = pb
	up.button_index = MOUSE_BUTTON_LEFT
	up.pressed = false
	Input.parse_input_event(up)
	Input.flush_buffered_events()

func _frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame

func _shot(name: String) -> void:
	var img := get_viewport().get_texture().get_image()
	img.save_png(out_dir.path_join(name + ".png"))
