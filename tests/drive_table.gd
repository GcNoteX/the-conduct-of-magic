extends Node

"""
Drives the inscribing table with simulated mouse input and saves screenshots.
Run (needs a display): godot --path . res://tests/drive_table.tscn -- <output_dir>
"""

const FIRE := preload("res://items/enchantment_materials/fire_stone/fire_stone.tres")
const YELLOW := preload("res://items/enchantment_materials/yellow_stone/yellow_stone.tres")
## The long sword's place in the demo player's items (dagger, short sword, long sword, carved)
const LONG_SWORD := 2
const BLUE := preload("res://items/enchantment_materials/blue_stone/blue_stone.tres")

var out_dir := "user://"
var table: Control
var view: BoardView


func _ready() -> void:
	get_tree().create_timer(60.0).timeout.connect(
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
	_shot("00_dagger")
	table._item_picker.select(1)
	table._open_item(1)
	await _frames(2)
	_shot("00_short_sword")
	# Carve on the long sword, the largest of the three
	table._item_picker.select(LONG_SWORD)
	table._open_item(LONG_SWORD)
	await _frames(2)
	_shot("01_empty")

	# Drag Kindle from the sidebar, rotating it once mid-drag to show the ghost turn
	var kindle := _card(table.player.known_enchantments[0])
	_start_drag(kindle)
	_move(_cell(Vector2i(1, 5)))
	_key(KEY_R)
	_move(_cell(Vector2i(1, 5)) + Vector2(1, 0))
	await _frames(2)
	_shot("02_dragging_rotated")
	for i in 5:
		_key(KEY_R)
	_move(_cell(Vector2i(1, 5)))
	_release(_cell(Vector2i(1, 5)))
	await _frames(2)
	var p: PlacementState = table.board.state.placements[0]
	var e0 := InscriptionBoard.enchantment_key(p.id, 0)
	var e1 := InscriptionBoard.enchantment_key(p.id, 1)
	print("placed: ", table.board.state.placements.size(), " rotation: ", p.rotation_steps)

	# Drag fire onto the flame node, showing the drop preview first
	var mats: Array[EnchantmentMaterialDefinition] = table._material_order()
	table._layout.set_open(true)
	await _frames(15)
	_start_drag(_card(mats[0]))
	_move(_cell(Vector2i(1, 5)))
	await _frames(15)
	_shot("03_drop_preview")
	_release(_cell(Vector2i(1, 5)))
	await _frames(2)
	_start_drag(_card(mats[3]))
	_move(_cell(Vector2i(3, 5)))
	_release(_cell(Vector2i(3, 5)))
	_move(_cell(Vector2i(1, 5)))
	await _frames(2)
	_shot("04_inserted")
	print("materials: ", table.board.node_material(e0), " ", table.board.node_material(e1))

	# Draw lines cell by cell, with a wobble back along the first one
	_draw_path([Vector2i(1, 5), Vector2i(0, 6), Vector2i(0, 5), Vector2i(0, 6), Vector2i(-1, 6)])
	_draw_path([Vector2i(1, 5), Vector2i(1, 6), Vector2i(0, 7), Vector2i(0, 8)])
	_draw_path([Vector2i(3, 5), Vector2i(3, 6)])
	var guard: Array[Vector2i] = []
	for q in range(-7, 2):
		guard.append(Vector2i(q, 14))
	_draw_path(guard)
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
	_click(_cell(Vector2i(-4, 14)), MOUSE_BUTTON_RIGHT)
	await _frames(2)
	table._on_commit_pressed()
	await _frames(2)
	print("committed: ", p.committed, " message: ", table._message_label.text)
	_shot("07_committed")
	await _drag_used_up()

	await _disenchant()

	# The other layouts, for comparison, back in Carve mode
	_click(table._carve_button.get_global_rect().get_center(), MOUSE_BUTTON_LEFT)
	await _frames(2)
	# The other layouts, for comparison
	_key(KEY_TAB)
	await _frames(20)
	_shot("16_sidebar_closed")
	table._set_layout(table.Layout.BOTTOM_TRAY)
	await _frames(3)
	_shot("17_bottom_tray")
	table._set_layout(table.Layout.QUICK_PALETTE)
	await _frames(2)
	_move(_cell(Vector2i(0, 9)))
	_key(KEY_SPACE, true)
	await _frames(3)
	_shot("18_quick_palette")
	_key(KEY_SPACE, false)
	table._set_layout(table.Layout.LISTS)
	await _frames(3)
	_shot("19_lists")
	# The original lists in Disenchant mode: enchantments dimmed, double-click a row to dissolve
	table._item_picker.select(table.player.items.size() - 1)
	table._open_item(table.player.items.size() - 1)
	_click(table._disenchant_button.get_global_rect().get_center(), MOUSE_BUTTON_LEFT)
	await _frames(3)
	_shot("20_lists_disenchant")

	await _bastion_ports()

	table.time_left = 0.01
	await _frames(3)
	_shot("08_day_over")
	get_tree().quit()


## Tries to drag a material the player has none of: no drag starts, and the table says why
func _drag_used_up() -> void:
	var count: int = table.player.get_material_count(BLUE)
	table.player.remove_material(BLUE, count)
	table._refresh_cards()
	table._layout.set_open(true)
	var tabs: TabContainer = table._layout.find_children("*", "TabContainer", true, false)[0]
	tabs.current_tab = 1
	await _frames(15)
	# What the GUI asks a card when a drag starts on it
	var data: Variant = _card(BLUE)._get_drag_data(Vector2.ZERO)
	await _frames(2)
	print("empty material drag data: ", data, " message: ", table._message_label.text)
	_shot("07b_used_up")
	tabs.current_tab = 0
	table._layout.set_open(false)
	table.player.add_material(BLUE, count)
	table._refresh_cards()
	await _frames(15)


## Disenchant mode on the pre-carved demo sword: costs on lines, a cut you can't afford, dissolving,
## planning every cut of Kindle, pulling it out and committing
func _disenchant() -> void:
	var carved: int = table.player.items.size() - 1
	table._item_picker.select(carved)
	table._open_item(carved)
	_click(table._disenchant_button.get_global_rect().get_center(), MOUSE_BUTTON_LEFT)
	await _frames(2)
	print(
		"disenchant mode: ",
		table.is_disenchanting(),
		" carvings: ",
		table.disenchant.carvings().size()
	)
	_move(_edge_point("e:1:0", "m:0,8"))
	await _frames(2)
	_shot("09_disenchant_costs")

	_click(_edge_point("e:1:0", "m:0,8"), MOUSE_BUTTON_LEFT)
	await _frames(2)
	print("blocked step: ", table.disenchant.first_blocked(), " ", table._message_label.text)
	_shot("10_cant_afford")
	_click(_edge_point("e:1:0", "m:0,8"), MOUSE_BUTTON_RIGHT)
	await _frames(1)

	# Dissolve by double-clicking the material cards (the cards are rebuilt after each one)
	_double_click(_card(FIRE))
	await _frames(1)
	_double_click(_card(YELLOW))
	await _frames(1)
	_double_click(_card(BLUE))
	await _frames(1)
	print("planned fire: ", table.board.planned_count(FIRE), " card: ", _card(FIRE).subtitle)
	table._layout.set_open(true)
	var tabs: TabContainer = table._layout.find_children("*", "TabContainer", true, false)[0]
	tabs.current_tab = 1
	await _frames(15)
	_shot("11a_sidebar_dissolved")
	tabs.current_tab = 0
	table._layout.set_open(false)
	await _frames(15)
	for ends in [["e:1:0", "m:0,8"], ["e:1:0", "m:-1,6"]]:
		_click(_edge_point(ends[0], ends[1]), MOUSE_BUTTON_LEFT)
	await _frames(2)
	_move(_cell(Vector2i(-1, 6)))
	await _frames(2)
	_shot("11_planning")

	for ends in [["e:1:0", "e:1:1"], ["m:0,8", "m:3,6"], ["e:1:1", "m:3,6"]]:
		_click(_edge_point(ends[0], ends[1]), MOUSE_BUTTON_LEFT)
	_click(_cell(Vector2i(1, 5)), MOUSE_BUTTON_LEFT)
	# Keen cuts with what's left over until one can't be afforded, so it shows red
	var keen_cuts := [
		["e:2:1", "m:-4,16"],
		["e:2:0", "m:-2,12"],
		["e:2:2", "m:-2,12"],
		["e:2:0", "m:-7,14"],
		["e:2:2", "m:1,14"],
	]
	var added := 0
	for ends in keen_cuts:
		_click(_edge_point(ends[0], ends[1]), MOUSE_BUTTON_LEFT)
		added += 1
		if table.disenchant.first_blocked() >= 0:
			break
	await _frames(2)
	print(
		"plan: ",
		table.disenchant.state.disenchant_plan.size(),
		" blocked: ",
		table.disenchant.first_blocked()
	)
	_shot("12_blocked_mid_plan")
	for i in added:
		table._on_undo_pressed()
	await _frames(2)
	print("commit button: ", table._commit_button.text)
	_shot("13_ready_to_commit")

	_click(table._commit_button.get_global_rect().get_center(), MOUSE_BUTTON_LEFT)
	await _frames(2)
	print(
		"after commit: ",
		table.disenchant.carvings().size(),
		" message: ",
		table._message_label.text
	)
	print(
		"fire left: ",
		table.player.get_material_count(FIRE),
		" yellow left: ",
		table.player.get_material_count(YELLOW)
	)
	_shot("14_committed")

	# Disenchant mode works on the sword carved earlier in this run too
	table._item_picker.select(LONG_SWORD)
	table._open_item(LONG_SWORD)
	await _frames(2)
	_shot("15_own_carving")


## Bastion (the example big node) on the first sword it fits on with room to reach a magic node
## from each of its big node's two ports, with those two lines drawn by mouse
func _bastion_ports() -> void:
	table._set_layout(table.Layout.SIDEBAR)
	table._set_disenchanting(false)
	var found := []
	for item in [1, 2, 0]:
		if found.is_empty():
			table._item_picker.select(item)
			table._open_item(item)
			await _frames(2)
			found = _place_bastion()
	print("bastion placed: ", not found.is_empty())
	if found.is_empty():
		return
	for route in found:
		_draw_path(route)
		await _frames(1)
	var b: InscriptionBoard = table.board
	var big_key := InscriptionBoard.enchantment_key(b.state.placements.back().id, 0)
	print("lines at the big node: ", b.line_count(big_key))
	table._on_board_changed()
	_move(Vector2(1300, 900))  # Off the board, so no tooltip hides the lines
	await _frames(2)
	_shot("21_bastion_ports")


## Places Bastion where both its big node's ports can reach a magic node; returns the two routes
func _place_bastion() -> Array:
	var bastion: Enchantment = load("res://enchantments/patterns/bastion.tres")
	var b: InscriptionBoard = table.board
	for c in b.get_cells():
		for r in 6:
			if b.check_place(bastion, c, r) != "":
				continue
			var p := b.place(bastion, c, r)
			var paths := []
			for port in b.node_ports(InscriptionBoard.enchantment_key(p.id, 0)):
				var route := _route_to_magic(port, paths)
				if not route.is_empty():
					paths.append(route)
			if paths.size() == 2:
				return paths
			b.remove_placement(p)
	return []


## The shortest free route from `start` to a magic node not used by `taken` routes, or []
func _route_to_magic(start: Vector2i, taken: Array) -> Array:
	var b: InscriptionBoard = table.board
	var used := {}
	for t in taken:
		for c in t:
			used[c] = true
	var prev := {start: start}
	var queue: Array[Vector2i] = [start]
	while not queue.is_empty():
		var at: Vector2i = queue.pop_front()
		for n in Hex.neighbours(at):
			if prev.has(n) or used.has(n) or not b.has_cell(n):
				continue
			prev[n] = at
			var route: Array[Vector2i] = [n]
			while route[0] != start:
				route.push_front(prev[route[0]])
			if route.size() > 2 and b.is_magic(b.node_at(n)) and b.check_line(route) == "":
				return route
			if b.node_covering(n) == "" and not b.is_occupied(n):
				queue.append(n)
	return []


func _edge_point(a: String, b: String) -> Vector2:
	var mid := view._edge_middle(DisenchantBoard.edge_key(a, b))
	return view.get_global_transform_with_canvas() * mid


func _card(payload: Resource) -> PaletteCard:
	for c in table.find_children("*", "PaletteCard", true, false):
		if c.payload == payload and not c.is_queued_for_deletion():
			return c
	return null


func _start_drag(card: PaletteCard) -> void:
	card.force_drag(card.payload, card.make_preview())
	table._on_card_drag_started(card.payload)


func _key(code: Key, pressed := true) -> void:
	var ev := InputEventKey.new()
	ev.keycode = code
	ev.physical_keycode = code
	ev.pressed = pressed
	Input.parse_input_event(ev)
	Input.flush_buffered_events()
	if code != KEY_SPACE and pressed:
		_key(code, false)


## A double-click on a card, sent straight to it
func _double_click(card: PaletteCard) -> void:
	for pressed in [true, false]:
		var ev := InputEventMouseButton.new()
		ev.button_index = MOUSE_BUTTON_LEFT
		ev.pressed = pressed
		ev.double_click = pressed
		card._gui_input(ev)


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
