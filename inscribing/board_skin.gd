class_name BoardSkin
extends Resource
## The art the inscribing table's board is drawn with: one texture for each kind of thing on the
## board, plus tints for each state. Swap a texture here (or the PNG it points at) to change the
## board's look; a texture left empty is drawn as the flat shape instead. BoardView reads it.
## Every texture is drawn at its own size for a hex of ART_HEX_SIZE pixels, scaled with the board.

## The hex size (centre to corner, in pixels) the art is drawn for, as in the map and enchantment
## editors
const ART_HEX_SIZE := 32.0

@export_group("Cells")
## One item cell
@export var cell: Texture2D
@export var cell_tint := Color(0.4, 0.41, 0.47)
## A strip drawn along each outer edge of the item's cells, its top edge facing out. It repeats
## along the edge.
@export var outline: Texture2D
@export var outline_tint := Color(0.85, 0.86, 0.9)
## How wide the outline is, in hexes
@export var outline_width := 0.2

@export_group("Magic nodes")
## One magic node tile for each rune kind, in RuneSet.Rune order: water, fire, wind, stone. A
## magic node uses the tile of the rune it puts most of on its lines.
@export var magic_nodes: Array[Texture2D] = []
## A magic node that covers more than one cell, like the Ember Well. The art is drawn for a node
## whose other cells run to the right of its own cell, and turned to match.
@export var big_magic_node: Texture2D
## How big a magic node is drawn, in hexes from its centre; its rings go around this
@export var magic_node_radius := 0.5
## Free: no committed line at it. Taken: a committed line uses it. Dead: its drafted chain
## reaches no enchantment.
@export var magic_free_tint := Color.WHITE
@export var magic_taken_tint := Color(1.0, 0.88, 0.6)
@export var magic_dead_tint := Color(0.5, 0.5, 0.55)

@export_group("Enchantment nodes")
## One enchantment node: a socket a material sits in
@export var enchantment_node: Texture2D
## A 2x2 enchantment node, drawn across its four cells and turned with its enchantment
@export var big_enchantment_node: Texture2D
## How big an enchantment node is drawn, in hexes from its centre; its rings go around this
@export var enchantment_node_radius := 0.45
## How much of the node a material fills, from its centre
@export var material_fill := 0.72
@export var enchantment_drafted_tint := Color(0.78, 0.76, 0.92)
@export var enchantment_taken_tint := Color.WHITE

@export_group("Lines")
## A line between nodes. It repeats along the line.
@export var line: Texture2D
## How wide lines are drawn, in hexes: an enchantment's own lines, and lines the player draws
@export var fixed_line_width := 0.36
@export var drawn_line_width := 0.3
@export var line_fixed_tint := Color(0.75, 0.68, 1.0)
@export var line_drafted_tint := Color(0.92, 0.9, 0.86)
@export var line_taken_tint := Color(1.25, 1.05, 0.5)
@export var line_dead_tint := Color(0.5, 0.5, 0.55)


## The tile for a magic node with these edge runes: the rune it puts most of, water when none
func magic_node_texture(edge_runes: RuneSet) -> Texture2D:
	var counts := edge_runes.to_array()
	var best := 0
	for i in counts.size():
		if counts[i] > counts[best]:
			best = i
	return magic_nodes[best] if best < magic_nodes.size() else null


## How much the art is scaled for a board drawn with hexes of `hex_size` pixels
static func art_scale(hex_size: float) -> float:
	return hex_size / ART_HEX_SIZE
