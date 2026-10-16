class_name BoardView
extends Node2D

"""
Draws an InscriptionBoard and turns mouse input into board actions.
Like the old cursors, this is the "brain" of interaction: the board only answers rule questions.
- Holding an enchantment (picked from the list): a ghost follows the mouse; left click places it,
  mouse wheel or R rotates it, right click drops it
- Holding a material: left click an enchantment node to insert it, right click drops it
- Otherwise: drag from one node to another to draw a line;
  right click removes a draft material, then a draft line, then a draft enchantment
"""

signal message(text: String)
signal changed
signal hovered(key: String)

const COLOR_CELL := Color("2b2a33")
const COLOR_CELL_EDGE := Color("45434f")
const COLOR_MAGIC := Color("7fd6e8")
const COLOR_DEAD := Color("6b6b75")
const COLOR_DRAFT_LINE := Color("c9c4b8")
const COLOR_COMMITTED := Color("e8c26a")
const COLOR_FIXED_LINE := Color("9b8fd1")
const COLOR_ACTIVE := Color("7ee08a")
const COLOR_VALID := Color(0.5, 0.9, 0.55, 0.45)
const COLOR_INVALID := Color(0.95, 0.35, 0.35, 0.45)

var board: InscriptionBoard:
	set(b):
		board = b
		_drag_from = ""
		_recentre()
		queue_redraw()
var hex_size: float = 26.0:
	set(s):
		hex_size = s
		queue_redraw()

var held_enchantment: Enchantment = null:
	set(e):
		held_enchantment = e
		if e:
			held_material = null
		queue_redraw()
var held_rotation: int = 0
var held_material: EnchantmentMaterialDefinition = null:
	set(m):
		held_material = m
		if m:
			held_enchantment = null
		queue_redraw()
## Asked before inserting a material: returns "" or why the player can't
var can_use_material: Callable = func(_m): return ""

var _centre := Vector2.ZERO ## Unit-space centre of the map, drawn at this node's origin
var _mouse_unit := Vector2.ZERO
var _hover_key := ""
var _drag_from := ""

#
# ── Coordinates ──────────────────────────────────
#
func unit_size() -> Vector2:
	if board == null:
		return Vector2.ZERO
	var r := _unit_rect()
	return r.size

func _unit_rect() -> Rect2:
	var cells := board.get_cells()
	var rect := Rect2(Hex.to_pixel(cells[0], 1.0), Vector2.ZERO)
	for c in cells:
		rect = rect.expand(Hex.to_pixel(c, 1.0))
	return rect.grow(1.0)

func _recentre() -> void:
	if board:
		_centre = _unit_rect().get_center()

func to_screen(unit: Vector2) -> Vector2:
	return (unit - _centre) * hex_size

func to_unit(local: Vector2) -> Vector2:
	return local / hex_size + _centre

func cell_under_mouse() -> Vector2i:
	return Hex.from_pixel(_mouse_unit, 1.0)

#
# ── Input ────────────────────────────────────────
#
func _unhandled_input(event: InputEvent) -> void:
	if board == null:
		return
	if event is InputEventMouse:
		_mouse_unit = to_unit(get_global_transform_with_canvas().affine_inverse() * event.position)
	if event is InputEventMouseMotion:
		var k := board.node_at(cell_under_mouse())
		if k != _hover_key:
			_hover_key = k
			hovered.emit(k)
		queue_redraw()
	elif event is InputEventMouseButton and event.pressed:
		if not _over_map():
			return
		match event.button_index:
			MOUSE_BUTTON_LEFT:
				_on_left_pressed()
			MOUSE_BUTTON_RIGHT:
				_on_right_pressed()
			MOUSE_BUTTON_WHEEL_UP:
				_rotate_held(-1)
			MOUSE_BUTTON_WHEEL_DOWN:
				_rotate_held(1)
		get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton and not event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_on_left_released()
	elif event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_R:
			_rotate_held(-1 if event.shift_pressed else 1)
		elif event.keycode == KEY_ESCAPE:
			_drop_held()

func _over_map() -> bool:
	return board.has_cell(cell_under_mouse()) or held_enchantment != null or _drag_from != ""

func _rotate_held(steps: int) -> void:
	if held_enchantment:
		held_rotation = posmod(held_rotation + steps, 6)
		queue_redraw()

func _drop_held() -> void:
	held_enchantment = null
	held_material = null
	_drag_from = ""
	queue_redraw()

func _on_left_pressed() -> void:
	if held_enchantment:
		var origin := cell_under_mouse()
		var err := board.check_place(held_enchantment, origin, held_rotation)
		if err != "":
			message.emit(err)
			return
		board.place(held_enchantment, origin, held_rotation)
		message.emit("Placed %s. Right click it to take it back while it's a draft." % held_enchantment.enchantment_name)
		_changed()
		return
	if held_material:
		if _hover_key == "":
			return
		var why: String = can_use_material.call(held_material)
		if why != "":
			message.emit(why)
			return
		var old := board.node_material(_hover_key)
		var err := board.insert_material(_hover_key, held_material)
		if err != "":
			message.emit(err)
			return
		if old and old != held_material:
			message.emit("Swapped %s for %s" % [InscriptionBoard.material_name(old), InscriptionBoard.material_name(held_material)])
		_changed()
		return
	if _hover_key != "":
		_drag_from = _hover_key

func _on_left_released() -> void:
	if _drag_from == "":
		return
	var from := _drag_from
	_drag_from = ""
	var to := board.node_at(cell_under_mouse())
	if to == "" or to == from:
		queue_redraw()
		return
	var err := board.check_line(from, to)
	if err != "":
		message.emit(err)
		queue_redraw()
		return
	board.add_line(from, to)
	_changed()

func _on_right_pressed() -> void:
	if held_enchantment or held_material:
		_drop_held()
		return
	var key := _hover_key
	if key != "" and board.node_material(key) and not board.node_placement(key).committed:
		board.remove_material(key)
		message.emit("Took the material back out (it's only planned until you commit)")
		_changed()
		return
	var line := _line_under_mouse()
	if line:
		var err := board.remove_line(line)
		message.emit(err if err != "" else "Removed the line")
		if err == "":
			_changed()
		return
	if key != "" and board.node_placement(key):
		var p := board.node_placement(key)
		var err := board.remove_placement(p)
		message.emit(err if err != "" else "Took %s back off the item" % p.enchantment.enchantment_name)
		if err == "":
			_changed()

func _line_under_mouse() -> LineState:
	var best: LineState = null
	var best_d := 0.25
	for l in board.state.lines:
		var d := InscriptionBoard._point_segment_distance(_mouse_unit, board.node_position(l.a), board.node_position(l.b))
		if d < best_d:
			best_d = d
			best = l
	return best

func _changed() -> void:
	_hover_key = board.node_at(cell_under_mouse())
	hovered.emit(_hover_key)
	queue_redraw()
	changed.emit()

#
# ── Drawing ──────────────────────────────────────
#
func _draw() -> void:
	if board == null:
		return
	var radius := hex_size * 0.42
	for c in board.get_cells():
		var centre := to_screen(Hex.to_pixel(c, 1.0))
		var pts := Hex.corners(centre, hex_size * 0.96)
		draw_colored_polygon(pts, COLOR_CELL)
		pts.append(pts[0])
		draw_polyline(pts, COLOR_CELL_EDGE, 1.0)

	for f in board.fixed_lines():
		var p := board.node_placement(f[0])
		draw_line(_screen(f[0]), _screen(f[1]), COLOR_COMMITTED if p.committed else COLOR_FIXED_LINE, 5.0)

	for l in board.state.lines:
		var col := COLOR_DRAFT_LINE
		if l.committed:
			col = COLOR_COMMITTED
		elif board.is_line_dead(l):
			col = COLOR_DEAD
		var w := 4.0 if l.committed else 3.0
		if l.committed:
			draw_line(_screen(l.a), _screen(l.b), col, w)
		else:
			draw_dashed_line(_screen(l.a), _screen(l.b), col, w, 8.0)

	for k in board.get_node_keys():
		var pos := _screen(k)
		if board.is_magic(k):
			var col := COLOR_DEAD if board.line_count(k) > 0 and board.is_dead(k) else COLOR_MAGIC
			if board.is_node_committed(k):
				col = COLOR_COMMITTED
			draw_circle(pos, radius * 0.7, col)
			draw_arc(pos, radius * 0.7, 0, TAU, 24, Color.BLACK, 1.5)
		else:
			var p := board.node_placement(k)
			var mat := board.node_material(k)
			draw_circle(pos, radius, Color("1d1c22"))
			if mat:
				draw_circle(pos, radius * 0.72, mat.color)
			if board.is_node_active(k):
				draw_arc(pos, radius + 2.0, 0, TAU, 32, COLOR_ACTIVE, 3.0)
			var ring := COLOR_COMMITTED if p.committed else COLOR_FIXED_LINE
			draw_arc(pos, radius, 0, TAU, 32, ring, 2.0)
		if k == _hover_key:
			draw_arc(pos, radius + 6.0, 0, TAU, 32, Color(1, 1, 1, 0.6), 1.5)

	if _drag_from != "":
		draw_line(_screen(_drag_from), to_screen(_mouse_unit), Color(1, 1, 1, 0.7), 2.0)

	if held_enchantment:
		_draw_ghost()

	if held_material and _hover_key != "":
		var ok := board.check_insert(_hover_key, held_material) == ""
		draw_arc(_screen(_hover_key), radius + 6.0, 0, TAU, 32, COLOR_VALID if ok else COLOR_INVALID, 4.0)

func _draw_ghost() -> void:
	var origin := cell_under_mouse()
	var ok := board.check_place(held_enchantment, origin, held_rotation) == ""
	var col := COLOR_VALID if ok else COLOR_INVALID
	var cells := board.placement_cells(held_enchantment, origin, held_rotation)
	for l in held_enchantment.lines:
		draw_line(to_screen(Hex.to_pixel(cells[l.x], 1.0)), to_screen(Hex.to_pixel(cells[l.y], 1.0)), col, 5.0)
	for c in cells:
		draw_circle(to_screen(Hex.to_pixel(c, 1.0)), hex_size * 0.42, col)

func _screen(key: String) -> Vector2:
	return to_screen(board.node_position(key))
