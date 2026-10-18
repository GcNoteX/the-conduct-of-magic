class_name ItemThumbnail
extends Control

## A small picture of one item's hex map with its carvings and drafts, in the board's colours
## (see BoardView). Used on the item overview's cards. It only reads the item: an item that has
## never been opened shows its bare map. A map taller than the thumbnail is wide is turned a
## quarter so it fills more of the card.

## Behind the map, so its cells stand out from the card (the table's background)
const COLOR_BACKDROP := Color("17161c")
const BACKDROP_RADIUS := 6
## How much of a hex's size each drawn cell takes, as on the board
const CELL_FILL := 0.96
## Widths in hexes, as on the board
const FIXED_LINE_WIDTH := 0.4
const DRAWN_LINE_WIDTH := 0.32
const MAGIC_RADIUS := 0.3
const ENCHANTMENT_RADIUS := 0.42
## Ring widths in hexes, a little thicker than the board's so they read at this size
const RING_WIDTH := 0.12
## Space kept around the cell centres, in hexes (a cell reaches 1 from its centre)
const MARGIN := 1.1

var item: ItemInstance:
	set(value):
		item = value
		queue_redraw()

## Unit hex space to this control, and its scale, set at the start of each draw. Shapes are
## placed through it rather than with a canvas transform, so antialiasing stays a pixel wide.
var _to_local := Transform2D.IDENTITY
var _scale := 1.0


func _draw() -> void:
	var backdrop := StyleBoxFlat.new()
	backdrop.bg_color = COLOR_BACKDROP
	backdrop.set_corner_radius_all(BACKDROP_RADIUS)
	draw_style_box(backdrop, Rect2(Vector2.ZERO, size))
	var map := _map()
	if map == null:
		return
	var cells := map.get_cells()
	if cells.is_empty():
		return
	_fit(cells)
	for c in cells:
		draw_colored_polygon(_to_local * Hex.corners(_at(c), CELL_FILL), BoardView.COLOR_CELL)
	if item.enchantment_graph_state == null:
		for c in map.get_magic_nodes():
			_draw_node(_at(c), MAGIC_RADIUS, BoardView.COLOR_MAGIC, Color.BLACK)
		return
	_draw_plan(InscriptionBoard.new(item, null))


func _map() -> HexMapDefinition:
	if item == null:
		return null
	var def := item.definition as EnchantableItemDefinition
	return def.map_template if def else null


## Fits unit hex space to this control: centred, as large as fits, turned a quarter when that's
## larger
func _fit(cells: Array[Vector2i]) -> void:
	var bounds := Rect2(Hex.to_pixel(cells[0], 1.0), Vector2.ZERO)
	for c in cells:
		bounds = bounds.expand(Hex.to_pixel(c, 1.0))
	bounds = bounds.grow(MARGIN)
	var upright := minf(size.x / bounds.size.x, size.y / bounds.size.y)
	var turned := minf(size.x / bounds.size.y, size.y / bounds.size.x)
	var angle := PI / 2.0 if turned > upright else 0.0
	_scale = maxf(upright, turned)
	_to_local = (
		Transform2D(angle, Vector2(_scale, _scale), 0.0, size / 2.0)
		* Transform2D(0.0, -bounds.get_center())
	)


func _at(c: Vector2i) -> Vector2:
	return Hex.to_pixel(c, 1.0)


## The item's placed enchantments, drawn lines and nodes, coloured as BoardView colours them
func _draw_plan(board: InscriptionBoard) -> void:
	for f in board.fixed_lines():
		var p: PlacementState = f.placement
		var col := BoardView.COLOR_COMMITTED if p.committed else BoardView.COLOR_FIXED_LINE
		_draw_path(f.cells, col, FIXED_LINE_WIDTH)
	for l in board.state.lines:
		var col := BoardView.COLOR_DRAFT_LINE
		if l.committed:
			col = BoardView.COLOR_COMMITTED
		elif board.is_line_dead(l):
			col = BoardView.COLOR_DEAD
		_draw_path(l.cells, col, DRAWN_LINE_WIDTH)
	for k in board.get_node_keys():
		var pos := board.node_position(k)
		if board.is_magic(k):
			var col := BoardView.COLOR_MAGIC
			if board.is_node_committed(k):
				col = BoardView.COLOR_COMMITTED
			elif board.line_count(k) > 0 and board.is_dead(k):
				col = BoardView.COLOR_DEAD
			_draw_node(pos, MAGIC_RADIUS, col, Color.BLACK)
			continue
		var p := board.node_placement(k)
		var mat := board.node_material(k)
		var ring := BoardView.COLOR_COMMITTED if p.committed else BoardView.COLOR_FIXED_LINE
		if mat and not p.committed:
			ring = BoardView.COLOR_ACTIVE if board.is_node_active(k) else BoardView.COLOR_UNMET
		var fill := mat.color if mat else BoardView.COLOR_EMPTY_NODE
		_draw_node(pos, ENCHANTMENT_RADIUS, fill, ring)


## A node at `pos` (unit hex space), `radius` in hexes
func _draw_node(pos: Vector2, radius: float, fill: Color, ring: Color) -> void:
	var at := _to_local * pos
	draw_circle(at, radius * _scale, fill, true, -1.0, true)
	draw_arc(at, radius * _scale, 0.0, TAU, 24, ring, RING_WIDTH * _scale, true)


func _draw_path(cells: Array[Vector2i], col: Color, width: float) -> void:
	if cells.is_empty():
		return
	var pts := PackedVector2Array()
	for c in cells:
		pts.append(_to_local * _at(c))
	var w := width * _scale
	if pts.size() > 1:
		draw_polyline(pts, col, w, true)
	for pt in pts:
		draw_circle(pt, w / 2.0, col, true, -1.0, true)
