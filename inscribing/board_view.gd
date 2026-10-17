class_name BoardView
extends Node2D

## Draws an InscriptionBoard and turns mouse input into board actions.
## Like the old cursors, this is the "brain" of interaction: the board only answers rule questions.
## Its parent (BoardDropArea) hands it mouse events and dropped materials.
## - Holding an enchantment (picked from the list): a ghost follows the mouse; left click places it,
##   mouse wheel or R rotates it, right click or Escape puts it down
## - Otherwise: press on a node and drag through cells to draw a line, moving back to undo cells;
##   right click removes a draft material, then a draft line, then a draft enchantment
## - Materials are dropped onto enchantment nodes (see drop_material)

signal message(text: String)
signal changed
signal hovered(key: String)

const COLOR_CELL := Color("2b2a33")
const COLOR_CELL_EDGE := Color("45434f")
const COLOR_MAGIC := Color("7fd6e8")
const COLOR_DEAD := Color("6b6b75")
const COLOR_DRAFT_LINE := Color("c9c4b8")
const COLOR_DRAWING := Color(1, 1, 1, 0.85)
const COLOR_COMMITTED := Color("e8c26a")
const COLOR_FIXED_LINE := Color("9b8fd1")
const COLOR_ACTIVE := Color("7ee08a")
const COLOR_UNMET := Color("f06060")
const COLOR_EMPTY_NODE := Color("1d1c22")
const COLOR_LABEL := Color("e6e2d8")
const COLOR_VALID := Color(0.5, 0.9, 0.55, 0.45)
const COLOR_INVALID := Color(0.95, 0.35, 0.35, 0.45)
const COLOR_BLOCKED := Color(0.95, 0.3, 0.3, 0.55)
## Short labels drawn on empty nodes, by EnchantmentMaterialDefinition.MATERIAL_ATTRIBUTES
const ATTRIBUTE_LABELS: Array[String] = ["So", "Ha", "Sh", "Fl", "Wa"]

var board: InscriptionBoard:
	set(b):
		board = b
		_path.clear()
		_blocked_reason = ""
		_recentre()
		queue_redraw()
var hex_size: float = 26.0:
	set(s):
		hex_size = s
		queue_redraw()

var held_enchantment: Enchantment = null:
	set(e):
		held_enchantment = e
		queue_redraw()
var held_rotation: int = 0
## Asked before inserting a material: returns "" or why the player can't
var can_use_material: Callable = func(_m): return ""

var _centre := Vector2.ZERO  ## Unit-space centre of the map, drawn at this node's origin
var _mouse_unit := Vector2.ZERO
var _hover_key := ""
var _path: Array[Vector2i] = []  ## The line being drawn, from its start node
var _blocked_cell := Vector2i.ZERO
var _blocked_reason := ""  ## Why the line being drawn can't go further; "" when it isn't blocked
var _dragging_material: EnchantmentMaterialDefinition = null


#
# ── Coordinates ──────────────────────────────────
#
func unit_size() -> Vector2:
	if board == null:
		return Vector2.ZERO
	return _unit_rect().size


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


func cell_screen(c: Vector2i) -> Vector2:
	return to_screen(Hex.to_pixel(c, 1.0))


func cell_under_mouse() -> Vector2i:
	return Hex.from_pixel(_mouse_unit, 1.0)


func is_drawing() -> bool:
	return not _path.is_empty()


#
# ── Input ────────────────────────────────────────
#
## Mouse input from the parent, with the mouse position in this node's local space
func handle_mouse(event: InputEventMouse, local: Vector2) -> void:
	if board == null:
		return
	_set_mouse(local)
	if event is InputEventMouseMotion:
		if is_drawing():
			_extend_path()
		queue_redraw()
	elif event is InputEventMouseButton:
		var button := event as InputEventMouseButton
		if not button.pressed:
			if button.button_index == MOUSE_BUTTON_LEFT:
				_finish_path()
			return
		match button.button_index:
			MOUSE_BUTTON_LEFT:
				_on_left_pressed()
			MOUSE_BUTTON_RIGHT:
				_on_right_pressed()
			MOUSE_BUTTON_WHEEL_UP:
				_rotate_held(-1)
			MOUSE_BUTTON_WHEEL_DOWN:
				_rotate_held(1)


func _unhandled_key_input(event: InputEvent) -> void:
	if board == null or not event.is_pressed() or event.is_echo():
		return
	var key := event as InputEventKey
	if key.keycode == KEY_R:
		_rotate_held(-1 if key.shift_pressed else 1)
	elif key.keycode == KEY_ESCAPE:
		_cancel()


func mouse_left() -> void:
	if _hover_key != "":
		_hover_key = ""
		hovered.emit("")
	queue_redraw()


func _set_mouse(local: Vector2) -> void:
	_mouse_unit = to_unit(local)
	var k := board.node_at(cell_under_mouse())
	if k != _hover_key:
		_hover_key = k
		hovered.emit(k)


func _rotate_held(steps: int) -> void:
	if held_enchantment:
		held_rotation = posmod(held_rotation + steps, 6)
		queue_redraw()


func _cancel() -> void:
	held_enchantment = null
	_path.clear()
	_blocked_reason = ""
	queue_redraw()


func _on_left_pressed() -> void:
	if held_enchantment:
		var origin := cell_under_mouse()
		var err := board.check_place(held_enchantment, origin, held_rotation)
		if err != "":
			message.emit(err)
			return
		board.place(held_enchantment, origin, held_rotation)
		message.emit(
			(
				"Placed %s. Right click it to take it back while it's a draft."
				% held_enchantment.enchantment_name
			)
		)
		_changed()
		return
	if _hover_key == "":
		return
	var err := board.check_line_start(cell_under_mouse())
	if err != "":
		message.emit(err)
		return
	_path = [cell_under_mouse()]
	_blocked_reason = ""
	queue_redraw()


## Grows or shrinks the line being drawn towards the cell under the mouse, one cell at a time.
## Moving back onto the line undoes cells; it stops at the first cell it can't enter.
func _extend_path() -> void:
	var target := cell_under_mouse()
	var back := _path.find(target)
	if back >= 0:
		_path.resize(back + 1)
		_set_blocked("")
		return
	var last: Vector2i = _path.back()
	if _path.size() > 1 and board.node_at(last) != "":
		return  # The line already ends on a node; move back along it to change it
	for c in Hex.line(last, target).slice(1):
		var err := board.check_step(_path, c)
		if err != "":
			_blocked_cell = c
			_set_blocked(err)
			return
		_path.append(c)
		if board.node_at(c) != "":
			break
	_set_blocked("")


func _set_blocked(reason: String) -> void:
	if reason != "" and reason != _blocked_reason:
		message.emit(reason)
	_blocked_reason = reason


func _finish_path() -> void:
	if not is_drawing():
		return
	var cells: Array[Vector2i] = _path.duplicate()
	_path.clear()
	_blocked_reason = ""
	queue_redraw()
	if cells.size() < 2:
		return
	var err := board.check_line(cells)
	if err != "":
		message.emit(err)
		return
	board.add_line(cells)
	_changed()


func _on_right_pressed() -> void:
	if held_enchantment or is_drawing():
		_cancel()
		return
	var key := _hover_key
	if key != "" and board.node_material(key) and not board.node_placement(key).committed:
		board.remove_material(key)
		message.emit("Took the material back out (it's only planned until you commit)")
		_changed()
		return
	var line := board.line_at(cell_under_mouse())
	if line == null and key != "" and board.is_magic(key):
		line = board.last_draft_line(key)
	if line:
		_remove_line(line)
		return
	if key != "" and board.node_placement(key):
		var p := board.node_placement(key)
		var err := board.remove_placement(p)
		message.emit(
			err if err != "" else "Took %s back off the item" % p.enchantment.enchantment_name
		)
		if err == "":
			_changed()


func _remove_line(line: LineState) -> void:
	var err := board.remove_line(line)
	message.emit(err if err != "" else "Removed the line")
	if err == "":
		_changed()


func _changed() -> void:
	_hover_key = board.node_at(cell_under_mouse())
	hovered.emit(_hover_key)
	queue_redraw()
	changed.emit()


#
# ── Dropping materials ───────────────────────────
#
## Why `m` can't be dropped at `local` right now, or "" when it can. Also shows the drop preview.
func check_drop(m: EnchantmentMaterialDefinition, local: Vector2) -> String:
	if board == null:
		return "Open an item first"
	_set_mouse(local)
	_dragging_material = m
	queue_redraw()
	if _hover_key == "":
		return "Drop materials onto enchantment nodes"
	var err := board.check_insert(_hover_key, m)
	if err != "":
		return err
	if board.node_material(_hover_key) == m:
		return "That node already holds %s" % InscriptionBoard.material_name(m)
	return can_use_material.call(m)


func drop_material(m: EnchantmentMaterialDefinition, local: Vector2) -> void:
	var err := check_drop(m, local)
	end_drop_preview()
	if err != "":
		message.emit(err)
		return
	var old := board.node_material(_hover_key)
	board.insert_material(_hover_key, m)
	if old:
		message.emit(
			(
				"Swapped %s for %s"
				% [InscriptionBoard.material_name(old), InscriptionBoard.material_name(m)]
			)
		)
	else:
		message.emit("Inserted %s" % InscriptionBoard.material_name(m))
	_changed()


func end_drop_preview() -> void:
	_dragging_material = null
	queue_redraw()


#
# ── Drawing ──────────────────────────────────────
#
func _draw() -> void:
	if board == null:
		return
	for c in board.get_cells():
		var pts := Hex.corners(cell_screen(c), hex_size * 0.96)
		draw_colored_polygon(pts, COLOR_CELL)
		pts.append(pts[0])
		draw_polyline(pts, COLOR_CELL_EDGE, 1.0, true)

	for f in board.fixed_lines():
		var p: PlacementState = f.placement
		_draw_path(f.cells, COLOR_COMMITTED if p.committed else COLOR_FIXED_LINE, 0.4)

	for l in board.state.lines:
		var col := COLOR_DRAFT_LINE
		if l.committed:
			col = COLOR_COMMITTED
		elif board.is_line_dead(l):
			col = COLOR_DEAD
		_draw_path(l.cells, col, 0.32)

	if is_drawing():
		_draw_path(_path, COLOR_DRAWING, 0.32)
		if _blocked_reason != "":
			draw_colored_polygon(
				Hex.corners(cell_screen(_blocked_cell), hex_size * 0.9), COLOR_BLOCKED
			)

	for k in board.get_node_keys():
		if board.is_magic(k):
			_draw_magic_node(k)
		else:
			_draw_enchantment_node(k)

	if held_enchantment:
		_draw_ghost()


func _draw_magic_node(k: String) -> void:
	var pos := _screen(k)
	var radius := hex_size * 0.3
	var col := COLOR_DEAD if board.line_count(k) > 0 and board.is_dead(k) else COLOR_MAGIC
	if board.is_node_committed(k):
		col = COLOR_COMMITTED
	draw_circle(pos, radius, col, true, -1.0, true)
	draw_arc(pos, radius, 0, TAU, 24, Color.BLACK, 1.5, true)
	if k == _hover_key:
		draw_arc(pos, hex_size * 0.48, 0, TAU, 32, Color(1, 1, 1, 0.6), 1.5, true)


## Empty nodes show what they accept; filled nodes show their material and condition progress
func _draw_enchantment_node(k: String) -> void:
	var pos := _screen(k)
	var radius := hex_size * 0.42
	var p := board.node_placement(k)
	var def := board.node_definition(k)
	var mat := board.node_material(k)
	draw_circle(pos, radius, mat.color if mat else COLOR_EMPTY_NODE, true, -1.0, true)
	var ring := COLOR_COMMITTED if p.committed else COLOR_FIXED_LINE
	if mat and not p.committed:
		ring = COLOR_ACTIVE if board.is_node_active(k) else COLOR_UNMET
	draw_arc(pos, radius, 0, TAU, 32, ring, 3.0 if mat else 2.0, true)
	_draw_label(pos, _progress_label(k) if mat else _requirement_label(def), radius * 1.9)
	if def.tier_requirement > 1 and mat == null:
		var badge := pos + Vector2(radius * 0.8, -radius * 0.8)
		draw_circle(badge, radius * 0.42, COLOR_COMMITTED, true, -1.0, true)
		_draw_label(badge, "%d" % def.tier_requirement, radius, Color.BLACK)

	if _dragging_material and not p.committed:
		var ok := board.check_insert(k, _dragging_material) == ""
		draw_arc(pos, radius + 5.0, 0, TAU, 32, COLOR_VALID if ok else COLOR_INVALID, 3.0, true)
	if k == _hover_key:
		var col := Color(1, 1, 1, 0.6)
		if _dragging_material:
			col = COLOR_ACTIVE if board.check_insert(k, _dragging_material) == "" else COLOR_UNMET
		draw_arc(pos, radius + 8.0, 0, TAU, 32, col, 2.0, true)


func _requirement_label(def: EnchantmentPatternNode) -> String:
	if def.material_requirements.is_empty():
		return "any"
	var parts: Array[String] = []
	for req in def.material_requirements:
		parts.append(ATTRIBUTE_LABELS[req.attribute])
	return "/".join(parts)


## The first unmet condition's count (like "1/2"), or a tick when every condition is met
func _progress_label(k: String) -> String:
	for c in board.condition_status(k):
		if not c[1]:
			return (c[2] as String).get_slice(" ", 0)
	return "✓"


func _draw_label(centre: Vector2, text: String, width: float, col := COLOR_LABEL) -> void:
	var font := ThemeDB.fallback_font
	var size := maxi(8, int(hex_size * 0.44))
	var at := Vector2(centre.x - width / 2.0, centre.y + size * 0.35)
	draw_string_outline(font, at, text, HORIZONTAL_ALIGNMENT_CENTER, width, size, 3, Color.BLACK)
	draw_string(font, at, text, HORIZONTAL_ALIGNMENT_CENTER, width, size, col)


## A line through cell centres, `width` in hexes, with rounded joints
func _draw_path(cells: Array[Vector2i], col: Color, width: float) -> void:
	if cells.is_empty():
		return
	var pts := PackedVector2Array()
	for c in cells:
		pts.append(cell_screen(c))
	var w := hex_size * width
	if pts.size() > 1:
		draw_polyline(pts, col, w, true)
	for pt in pts:
		draw_circle(pt, w / 2.0, col, true, -1.0, true)


func _draw_ghost() -> void:
	var origin := cell_under_mouse()
	var ok := board.check_place(held_enchantment, origin, held_rotation) == ""
	var col := COLOR_VALID if ok else COLOR_INVALID
	for cells in board.pattern_line_paths(held_enchantment, origin, held_rotation):
		_draw_path(cells, col, 0.4)
	for c in board.placement_cells(held_enchantment, origin, held_rotation):
		draw_circle(cell_screen(c), hex_size * 0.42, col, true, -1.0, true)


func _screen(key: String) -> Vector2:
	return to_screen(board.node_position(key))
