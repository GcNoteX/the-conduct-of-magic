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
