@tool
@icon("res://editor/icons/enchantment_scene.svg")
class_name EnchantmentScene
extends Node2D
## Where an enchantment's shape is authored: EnchantmentNodeComponent and EnchantmentLineComponent
## children snap to hex cells, the shape is checked as you edit, and Bake writes it into the
## Enchantment resource the game reads. The enchantment's name and description stay on the resource.
##
## Nodes are numbered in scene tree order and the first one is the enchantment's origin.
## Lines are baked in scene tree order. Components go directly under this node.

## Hex size (centre to corner) in pixels for snapping and drawing
const HEX_SIZE := 32.0
## How many rings of empty cells to draw around the shape
const GRID_MARGIN := 2

const COLOR_GRID := Color("45434f")
const COLOR_GRID_FILL := Color("1d1c22")
const COLOR_LINE_CELL := Color(0.61, 0.56, 0.82, 0.35)
const COLOR_OVERLAP := Color(0.95, 0.3, 0.3, 0.7)
const COLOR_LABEL := Color("e6e2d8")

## The Enchantment resource Bake writes the shape into
@export var enchantment: Enchantment:
	set(value):
		enchantment = value
		update_configuration_warnings()

@export_tool_button("Bake", "Save") var bake_action: Callable = bake

var _last_seen := ""


func _ready() -> void:
	set_process(Engine.is_editor_hint())
	snap()
	refresh()


## In the editor: keep everything snapped, and redraw and recheck when the shape changes
func _process(_delta: float) -> void:
	snap()
	var seen := shape_signature(build_enchantment())
	if enchantment:
		seen += shape_signature(enchantment)
	if seen == _last_seen:
		return
	_last_seen = seen
	refresh()


## Redraws the shape and its warnings
func refresh() -> void:
	queue_redraw()
	update_configuration_warnings()
	var index := 0
	for n in node_components():
		n.index = index
		index += 1
		n.queue_redraw()
	for l in line_components():
		l.update_configuration_warnings()


func node_components() -> Array[EnchantmentNodeComponent]:
	var out: Array[EnchantmentNodeComponent] = []
	for child in get_children():
		if child is EnchantmentNodeComponent:
			out.append(child)
	return out


func line_components() -> Array[EnchantmentLineComponent]:
	var out: Array[EnchantmentLineComponent] = []
	for child in get_children():
		if child is EnchantmentLineComponent:
			out.append(child)
	return out


## Moves every node onto the centre of its nearest cell and fits every line to its nodes
func snap() -> void:
	for n in node_components():
		n.snap()
	for l in line_components():
		l.snap()


## The cell under the first node, which becomes the enchantment's origin
func origin_cell() -> Vector2i:
	var nodes := node_components()
	return nodes[0].cell() if not nodes.is_empty() else Vector2i.ZERO


## The shape as an unsaved Enchantment, with offsets from the first node
func build_enchantment() -> Enchantment:
	var e := Enchantment.new()
	var origin := origin_cell()
	var nodes := node_components()
	var built_nodes: Array[EnchantmentPatternNode] = []
	for n in nodes:
		var pn := EnchantmentPatternNode.new()
		pn.offset = n.cell() - origin
		pn.tier_requirement = n.tier_requirement
		var reqs: Array[MaterialCondition] = []
		for r in n.material_requirements:
			if r:
				reqs.append(r.duplicate())
		pn.material_requirements = reqs
		pn.extra_cells = n.extra_cells.duplicate()
		pn.ports = n.ports.duplicate()
		built_nodes.append(pn)
	e.nodes = built_nodes
	var built_lines: Array[EnchantmentPatternLine] = []
	for l in line_components():
		var pl := EnchantmentPatternLine.new()
		pl.from_node = nodes.find(l.from_node)
		pl.to_node = nodes.find(l.to_node)
		pl.from_port = l.from_port
		pl.to_port = l.to_port
		var cells: Array[Vector2i] = []
		for c in l.middle_cells():
			cells.append(c - origin)
		pl.cells = cells
		built_lines.append(pl)
	e.lines = built_lines
	return e


## Why the shape can't be baked, or "" when it can
func check_shape() -> String:
	for l in line_components():
		var err := l.check_setup()
		if err != "":
			return "%s: %s" % [l.name, err]
	return InscriptionBoard.check_shape(build_enchantment())


## Whether the enchantment resource already holds exactly this shape
func is_baked() -> bool:
	return (
		enchantment != null and shape_signature(enchantment) == shape_signature(build_enchantment())
	)


## Writes the shape into `enchantment` and saves it
func bake() -> Error:
	if enchantment == null or enchantment.resource_path == "":
		push_error("Set Enchantment to a saved Enchantment resource before baking")
		return ERR_UNCONFIGURED
	return bake_into(enchantment, enchantment.resource_path)


## Writes the shape into `target` and saves it to `path`. The name, description and icon are kept,
## and existing node and line resources are updated in place so the file only changes where the
## shape does.
func bake_into(target: Enchantment, path: String) -> Error:
	var problem := check_shape()
	if problem != "":
		push_error("Can't bake %s: %s" % [name, problem])
		return ERR_INVALID_DATA
	var built := build_enchantment()
	var nodes: Array[EnchantmentPatternNode] = []
	for i in built.nodes.size():
		var n: EnchantmentPatternNode = target.nodes[i] if i < target.nodes.size() else null
		nodes.append(_bake_node(n, built.nodes[i]))
	target.nodes = nodes
	var lines: Array[EnchantmentPatternLine] = []
	for i in built.lines.size():
		var l: EnchantmentPatternLine = target.lines[i] if i < target.lines.size() else null
		lines.append(_bake_line(l, built.lines[i]))
	target.lines = lines
	var err := ResourceSaver.save(target, path)
	if err != OK:
		push_error("Could not save %s (error %d)" % [path, err])
	target.emit_changed()
	refresh()
	return err


## What's wrong with the scene, shown as warnings in the editor's scene tree
func get_problems() -> PackedStringArray:
	var out := PackedStringArray()
	if enchantment == null:
		out.append("Set Enchantment to the Enchantment resource this scene bakes into")
	if node_components().is_empty():
		out.append("Add EnchantmentNodeComponent children to make the shape")
		return out
	var problem := check_shape()
	if problem != "":
		out.append(problem)
	elif enchantment and not is_baked():
		out.append("Not baked: the shape differs from the enchantment resource. Press Bake.")
	return out


## A text form of an enchantment's shape, equal for equal shapes
static func shape_signature(e: Enchantment) -> String:
	var nodes := []
	for n in e.nodes:
		var reqs := []
		for r in n.material_requirements:
			reqs.append([r.attribute, r.required] if r else null)
		nodes.append([n.offset, n.tier_requirement, reqs, n.extra_cells, n.ports])
	var lines := []
	for l in e.lines:
		lines.append([l.from_node, l.to_node, l.cells, l.from_port, l.to_port])
	return var_to_str([nodes, lines])


## Every cell taken more than once by the shape's nodes and lines
func overlapping_cells() -> Dictionary:
	var count := {}
	for n in node_components():
		for c in n.covered_cells():
			count[c] = count.get(c, 0) + 1
	for l in line_components():
		for c in l.middle_cells():
			count[c] = count.get(c, 0) + 1
	var out := {}
	for c in count:
		if count[c] > 1:
			out[c] = true
	return out


func _get_configuration_warnings() -> PackedStringArray:
	return get_problems()


func _draw() -> void:
	var taken := {}
	for n in node_components():
		for c in n.covered_cells():
			taken[c] = true
	for l in line_components():
		for c in l.middle_cells():
			taken[c] = true
	var grid := {}
	for c in taken:
		for q in range(-GRID_MARGIN, GRID_MARGIN + 1):
			for r in range(-GRID_MARGIN, GRID_MARGIN + 1):
				if Hex.distance(Vector2i.ZERO, Vector2i(q, r)) <= GRID_MARGIN:
					grid[c + Vector2i(q, r)] = true
	if grid.is_empty():
		grid[Vector2i.ZERO] = true
	for c in grid:
		var pts := Hex.corners(Hex.to_pixel(c, HEX_SIZE), HEX_SIZE - 1.0)
		draw_colored_polygon(pts, COLOR_GRID_FILL)
		pts.append(pts[0])
		draw_polyline(pts, COLOR_GRID, 1.0, true)
	for l in line_components():
		for c in l.middle_cells():
			draw_colored_polygon(
				Hex.corners(Hex.to_pixel(c, HEX_SIZE), HEX_SIZE - 2.0), COLOR_LINE_CELL
			)
	for c in overlapping_cells():
		draw_colored_polygon(Hex.corners(Hex.to_pixel(c, HEX_SIZE), HEX_SIZE - 2.0), COLOR_OVERLAP)
	if enchantment:
		var top := Vector2.INF
		for c in grid:
			top = top.min(Hex.to_pixel(c, HEX_SIZE))
		var font := ThemeDB.fallback_font
		draw_string(
			font,
			top + Vector2(-HEX_SIZE, -HEX_SIZE * 1.4),
			enchantment.enchantment_name,
			HORIZONTAL_ALIGNMENT_LEFT,
			-1,
			22,
			COLOR_LABEL
		)


func _bake_node(
	into: EnchantmentPatternNode, from: EnchantmentPatternNode
) -> EnchantmentPatternNode:
	if into == null:
		return from
	into.offset = from.offset
	into.tier_requirement = from.tier_requirement
	into.extra_cells = from.extra_cells
	into.ports = from.ports
	var reqs: Array[MaterialCondition] = []
	for i in from.material_requirements.size():
		var r: MaterialCondition = from.material_requirements[i]
		var old: MaterialCondition = (
			into.material_requirements[i] if i < into.material_requirements.size() else null
		)
		if old and old.get_script() == r.get_script():
			old.attribute = r.attribute
			old.required = r.required
			reqs.append(old)
		else:
			reqs.append(r)
	into.material_requirements = reqs
	return into


func _bake_line(
	into: EnchantmentPatternLine, from: EnchantmentPatternLine
) -> EnchantmentPatternLine:
	if into == null:
		return from
	into.from_node = from.from_node
	into.to_node = from.to_node
	into.from_port = from.from_port
	into.to_port = from.to_port
	into.cells = from.cells
	return into
