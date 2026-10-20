@tool
@icon("res://editor/icons/enchantment_node_component.svg")
class_name EnchantmentNodeComponent
extends Node2D
## One node of an enchantment in an EnchantmentScene: what it accepts, the cells it covers and the
## ports where lines attach. It snaps to the centre of the hex cell it's dragged onto.
## Its art is a Sprite2D child (with Show Behind Parent on); without one it draws a placeholder.
## The node always draws its number, its requirements and, on a bigger node, its ports.

const COLOR_NODE := Color("2b2a33")
const COLOR_EDGE := Color("9b8fd1")
const COLOR_ORIGIN := Color("e8c26a")
const COLOR_LABEL := Color("e6e2d8")
const COLOR_OVERLAP := Color(0.95, 0.3, 0.3)
const COLOR_PORT := Color("7ee08a")

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
## (for example (1, 0) is the cell to the east). Lines attach only at the node's ports.
@export var extra_cells: Array[Vector2i] = []:
	set(value):
		extra_cells = value
		queue_redraw()
## The cells where lines attach, as offsets from the node's own cell: (0, 0) or one of its extra
## cells. Empty means lines attach at the node's own cell. A line picks a port by its number in
## this list (its From Port or To Port).
@export var ports: Array[Vector2i] = []:
	set(value):
		ports = value
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


## The node's ports as offsets from its own cell, (0, 0) when none are set
func port_offsets() -> Array[Vector2i]:
	if ports.is_empty():
		return [Vector2i.ZERO] as Array[Vector2i]
	return ports.duplicate()


## The cell of port `port`, in the EnchantmentScene's cells
func port_cell(port: int) -> Vector2i:
	return cell() + port_offsets()[port]


## Where port `port` is, in the EnchantmentScene's space
func port_position(port: int) -> Vector2:
	return position + Hex.to_pixel(port_offsets()[port], EnchantmentScene.HEX_SIZE)


## Whether the node has art: a Sprite2D child
func has_art() -> bool:
	for child in get_children():
		if child is Sprite2D:
			return true
	return false


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
	var art := has_art()
	var middle := Vector2.ZERO
	for c in extra_cells:
		var at := Hex.to_pixel(c, size)
		middle += at
		var pts := Hex.corners(at, size - 2.0)
		if overlaps.has(cell() + c):
			draw_colored_polygon(pts, COLOR_OVERLAP)
		elif not art:
			draw_colored_polygon(pts, COLOR_NODE)
			pts.append(pts[0])
			draw_polyline(pts, COLOR_EDGE, 2.0, true)
	middle /= extra_cells.size() + 1
	var edge := COLOR_ORIGIN if index == 0 else COLOR_EDGE
	if overlaps.has(cell()):
		edge = COLOR_OVERLAP
	if not art:
		draw_circle(Vector2.ZERO, size * 0.62, COLOR_NODE)
		draw_arc(Vector2.ZERO, size * 0.62, 0, TAU, 32, edge, 3.0, true)
	elif index == 0 or overlaps.has(cell()):
		draw_arc(middle, size * 0.75, 0, TAU, 32, edge, 2.0, true)
	if not extra_cells.is_empty():
		_draw_ports(size)
	var font := ThemeDB.fallback_font
	var number := str(index) if index >= 0 else "?"
	draw_string_outline(
		font,
		middle + Vector2(-size, 6),
		number,
		HORIZONTAL_ALIGNMENT_CENTER,
		size * 2,
		18,
		4,
		Color.BLACK
	)
	draw_string(
		font, middle + Vector2(-size, 6), number, HORIZONTAL_ALIGNMENT_CENTER, size * 2, 18, edge
	)
	draw_string_outline(
		font,
		middle + Vector2(-size * 1.5, size + 6),
		_requirement_text(),
		HORIZONTAL_ALIGNMENT_CENTER,
		size * 3,
		13,
		4,
		Color.BLACK
	)
	draw_string(
		font,
		middle + Vector2(-size * 1.5, size + 6),
		_requirement_text(),
		HORIZONTAL_ALIGNMENT_CENTER,
		size * 3,
		13,
		COLOR_LABEL
	)


## A green ring and number on each port of a bigger node
func _draw_ports(size: float) -> void:
	var font := ThemeDB.fallback_font
	var offsets := port_offsets()
	for i in offsets.size():
		var at := Hex.to_pixel(offsets[i], size)
		draw_arc(at, size * 0.38, 0, TAU, 24, COLOR_PORT, 2.5, true)
		draw_string_outline(
			font,
			at + Vector2(-size, 5),
			"P%d" % i,
			HORIZONTAL_ALIGNMENT_CENTER,
			size * 2,
			12,
			3,
			Color.BLACK
		)
		draw_string(
			font,
			at + Vector2(-size, 5),
			"P%d" % i,
			HORIZONTAL_ALIGNMENT_CENTER,
			size * 2,
			12,
			COLOR_PORT
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
