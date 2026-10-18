@tool
@icon("res://editor/icons/enchantment_node_component.svg")
class_name EnchantmentNodeComponent
extends Node2D
## One node of an enchantment in an EnchantmentScene: what it accepts and the cells it covers.
## It snaps to the centre of the hex cell it's dragged onto. Placeholder drawing until it has art.

const COLOR_NODE := Color("2b2a33")
const COLOR_EDGE := Color("9b8fd1")
const COLOR_ORIGIN := Color("e8c26a")
const COLOR_LABEL := Color("e6e2d8")
const COLOR_OVERLAP := Color(0.95, 0.3, 0.3)

## The tier the material has to be or greater
@export_range(1, 10) var tier_requirement: int = 1:
	set(value):
		tier_requirement = value
		queue_redraw()
## Same semantics as MaterialHolder.material_requirements
@export var material_requirements: Array[MaterialCondition] = []:
	set(value):
		material_requirements = value
		queue_redraw()
## Other cells this node covers, as axial offsets from the node's own cell
## (for example (1, 0) is the cell to the east). Lines attach at the node's own cell.
@export var extra_cells: Array[Vector2i] = []:
	set(value):
		extra_cells = value
		queue_redraw()

## This node's number in the enchantment, set by the EnchantmentScene; 0 is the origin
var index := -1


## The hex cell this node sits on, in the EnchantmentScene's cells
func cell() -> Vector2i:
	return Hex.from_pixel(position, EnchantmentScene.HEX_SIZE)


## Every cell this node covers: its own cell first, then its extra cells
func covered_cells() -> Array[Vector2i]:
	var out: Array[Vector2i] = [cell()]
	for c in extra_cells:
		out.append(cell() + c)
	return out


## Moves the node onto the centre of its nearest cell
func snap() -> void:
	var centre := Hex.to_pixel(cell(), EnchantmentScene.HEX_SIZE)
	if position != centre:
		position = centre
	if rotation != 0.0:
		rotation = 0.0
	if scale != Vector2.ONE:
		scale = Vector2.ONE


func _get_configuration_warnings() -> PackedStringArray:
	if not get_parent() is EnchantmentScene:
		return PackedStringArray(["Put this node directly under an EnchantmentScene"])
	return PackedStringArray()


func _notification(what: int) -> void:
	if what == NOTIFICATION_PARENTED:
		update_configuration_warnings()


func _draw() -> void:
	var size := EnchantmentScene.HEX_SIZE
	var scene := get_parent() as EnchantmentScene
	var overlaps := scene.overlapping_cells() if scene else {}
	for c in extra_cells:
		var pts := Hex.corners(Hex.to_pixel(c, size), size - 2.0)
		draw_colored_polygon(pts, COLOR_OVERLAP if overlaps.has(cell() + c) else COLOR_NODE)
		pts.append(pts[0])
		draw_polyline(pts, COLOR_EDGE, 2.0, true)
	var edge := COLOR_ORIGIN if index == 0 else COLOR_EDGE
	if overlaps.has(cell()):
		edge = COLOR_OVERLAP
	draw_circle(Vector2.ZERO, size * 0.62, COLOR_NODE)
	draw_arc(Vector2.ZERO, size * 0.62, 0, TAU, 32, edge, 3.0, true)
	var font := ThemeDB.fallback_font
	var number := str(index) if index >= 0 else "?"
	draw_string(font, Vector2(-size, 6), number, HORIZONTAL_ALIGNMENT_CENTER, size * 2, 18, edge)
	draw_string(
		font,
		Vector2(-size * 1.5, size + 6),
		_requirement_text(),
		HORIZONTAL_ALIGNMENT_CENTER,
		size * 3,
		13,
		COLOR_LABEL
	)


## Short label like "T2 Sh" or "Fl*" (a star marks a required attribute)
func _requirement_text() -> String:
	var parts: Array[String] = []
	if tier_requirement > 1:
		parts.append("T%d" % tier_requirement)
	var names: Array[String] = []
	for r in material_requirements:
		if r:
			names.append(BoardView.ATTRIBUTE_LABELS[r.attribute] + ("*" if r.required else ""))
	parts.append("/".join(names) if not names.is_empty() else "any")
	return " ".join(parts)
