@tool
class_name HexMapDefinition
extends Resource

"""
An item's map: its silhouette of cells and its magic nodes (one node arrangement).
Authored as rows of characters in odd-r offset layout, top row first:
	'.' or ' '  no cell
	'#'         a cell
	'M'         a cell holding a magic node
Magic nodes are numbered in reading order (top row first, left to right), and the rune lists
below use that numbering. A missing entry means no runes.
"""

@export var map_name: String = ""
@export var layout: PackedStringArray = []
@export_category("Disenchanting")
## The runes each magic node puts on every line at it, by magic node number
@export var magic_edge_runes: Array[RuneSet] = []
## The runes each magic node gives back once, when its last line is cut, by magic node number
@export var magic_harvest_runes: Array[RuneSet] = []


## A copy of the edge runes of the magic node in `cell` (empty when none are set)
func edge_runes_at(cell: Vector2i) -> RuneSet:
	return _runes_at(magic_edge_runes, cell)


## A copy of the harvest runes of the magic node in `cell` (empty when none are set)
func harvest_runes_at(cell: Vector2i) -> RuneSet:
	return _runes_at(magic_harvest_runes, cell)


func _runes_at(list: Array[RuneSet], cell: Vector2i) -> RuneSet:
	var i := get_magic_nodes().find(cell)
	return RuneSet.copy_of(list[i] if i >= 0 and i < list.size() else null)


## The entry at `i` of an old rune list, or a new empty set when there is none
static func _kept_runes(list: Array, i: int) -> RuneSet:
	if i >= 0 and i < list.size() and list[i] != null:
		return list[i]
	return RuneSet.new()


## Replaces the layout, keeping each magic node's runes where a magic node stays in the same cell.
## The rune lists are resized to the new magic nodes; a new magic node starts with no runes.
## When the old layout had no magic nodes (never baked), the rune lists are kept in order.
## Returns how many magic nodes got no runes.
func set_layout_keeping_runes(new_layout: PackedStringArray) -> int:
	var old_nodes := get_magic_nodes()
	var old_edge := magic_edge_runes.duplicate()
	var old_harvest := magic_harvest_runes.duplicate()
	layout = new_layout
	var edge: Array[RuneSet] = []
	var harvest: Array[RuneSet] = []
	var added := 0
	var new_nodes := get_magic_nodes()
	for n in new_nodes.size():
		var i := old_nodes.find(new_nodes[n]) if not old_nodes.is_empty() else n
		if i < 0 or i >= old_edge.size():
			added += 1
		edge.append(_kept_runes(old_edge, i))
		harvest.append(_kept_runes(old_harvest, i))
	magic_edge_runes = edge
	magic_harvest_runes = harvest
	return added


## Axial coordinates of every cell in the silhouette (magic node cells included)
func get_cells() -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	for row in layout.size():
		var line := layout[row]
		for col in line.length():
			if line[col] == "#" or line[col] == "M":
				out.append(Hex.offset_to_axial(col, row))
	return out


## Axial coordinates of every magic node
func get_magic_nodes() -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	for row in layout.size():
		var line := layout[row]
		for col in line.length():
			if line[col] == "M":
				out.append(Hex.offset_to_axial(col, row))
	return out


## The layout rows for these cells (axial), the reverse of get_cells() and get_magic_nodes().
## Every cell has to sit at column 0 or more and row 0 or more in odd-r offset coordinates.
static func layout_from_cells(
	cells: Array[Vector2i], magic_nodes: Array[Vector2i]
) -> PackedStringArray:
	var chars := {}  ## offset Vector2i -> "#" or "M"
	var size := Vector2i.ZERO
	for a in cells:
		var o := Hex.axial_to_offset(a)
		assert(o.x >= 0 and o.y >= 0, "Cell %s is left of column 0 or above row 0" % o)
		chars[o] = "M" if a in magic_nodes else "#"
		size = size.max(o + Vector2i.ONE)
	var out := PackedStringArray()
	for row in size.y:
		var line := ""
		for col in size.x:
			var ch: String = chars.get(Vector2i(col, row), ".")
			line += ch
		out.append(line)
	return out
