@tool
class_name HexMapDefinition
extends Resource

"""
An item's map: its silhouette of cells and its magic nodes (one node arrangement).
Authored as rows of characters in odd-r offset layout, top row first:
	'.' or ' '  no cell
	'#'         a cell
	'M'         a cell holding a magic node
"""

@export var map_name: String = ""
@export var layout: PackedStringArray = []


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
