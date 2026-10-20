@tool
@icon("res://editor/icons/magic_node_tile.svg")
class_name MagicNodeTile
extends Node2D
## The root of a magic node scene tile: a bigger or custom magic node painted on a map's Magic
## nodes layer. It holds the runes the node puts on its lines and gives back when freed, and the
## cells it covers besides its own; its art is a child (usually a Sprite2D). ItemMapScene's Bake
## reads these. The node's own cell is where it's painted, and where lines attach.

## The size of one map tile in pixels (hex_map_tiles.tres), to draw the covered cells
const TILE_SIZE := Vector2(56, 64)
const COLOR_OUTLINE := Color(1.0, 0.85, 0.4, 0.8)

## The runes the magic node puts on every line at it
@export var edge_runes: RuneSet:
	set(value):
		edge_runes = value
		update_configuration_warnings()
## The runes the magic node gives back once, when its last line is cut
@export var harvest_runes: RuneSet:
	set(value):
		harvest_runes = value
		update_configuration_warnings()
## Other cells the node covers, as steps from its own cell: (1, 0) is the cell to the right.
## Lines can't run through them; they attach at the node's own cell.
@export var extra_cells: Array[Vector2i] = []:
	set(value):
		extra_cells = value
		queue_redraw()


## Where the centre of the cell `step` away from the node's own cell is, in this node's space
static func cell_position(step: Vector2i) -> Vector2:
	return Vector2(TILE_SIZE.x * (step.x + step.y / 2.0), TILE_SIZE.y * 0.75 * step.y)


func _get_configuration_warnings() -> PackedStringArray:
	var out := PackedStringArray()
	if edge_runes == null:
		out.append("Set Edge Runes: what the node puts on each of its lines")
	if harvest_runes == null:
		out.append("Set Harvest Runes: what the node gives back when freed")
	return out


## In the editor, outlines every cell the node covers so its footprint shows while painting
func _draw() -> void:
	if not Engine.is_editor_hint():
		return
	var steps: Array[Vector2i] = [Vector2i.ZERO]
	steps.append_array(extra_cells)
	for s in steps:
		var pts := Hex.corners(cell_position(s), TILE_SIZE.y / 2.0 - 1.0)
		pts.append(pts[0])
		draw_polyline(pts, COLOR_OUTLINE, 1.5 if s == Vector2i.ZERO else 1.0, true)
