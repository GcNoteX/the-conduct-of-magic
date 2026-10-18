@tool
class_name EnchantmentLineComponent
extends Line2D
## One of an enchantment's own fixed lines in an EnchantmentScene: the two nodes it joins and the
## cells it takes. By default it runs straight from `from_node` to `to_node`. To bend it, add points
## to the line in the 2D editor: each point snaps to a cell centre and the line runs cell by cell
## through them in order. The first and last points always sit on the two nodes.

## The node the line starts at
@export var from_node: EnchantmentNodeComponent
## The node the line ends at
@export var to_node: EnchantmentNodeComponent


## Why this line isn't set up yet, or "" when it is
func check_setup() -> String:
	if from_node == null or to_node == null:
		return "Set both From Node and To Node"
	if from_node.get_parent() != get_parent() or to_node.get_parent() != get_parent():
		return "Its nodes have to be in the same EnchantmentScene"
	return ""


## The cells the line runs through, from from_node's cell to to_node's cell, both included
func path_cells() -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	if check_setup() != "":
		return out
	var stops: Array[Vector2i] = [from_node.cell()]
	for i in range(1, points.size() - 1):
		stops.append(Hex.from_pixel(points[i], EnchantmentScene.HEX_SIZE))
	stops.append(to_node.cell())
	out.append(stops[0])
	for i in range(1, stops.size()):
		var run := Hex.line(stops[i - 1], stops[i])
		out.append_array(run.slice(1))
	return out


## The cells between the two nodes, which the line takes
func middle_cells() -> Array[Vector2i]:
	var path := path_cells()
	return path.slice(1, path.size() - 1) if path.size() > 2 else ([] as Array[Vector2i])


## Pins the ends of the line to its nodes and its bend points to cell centres
func snap() -> void:
	if position != Vector2.ZERO:
		position = Vector2.ZERO
	if rotation != 0.0:
		rotation = 0.0
	if scale != Vector2.ONE:
		scale = Vector2.ONE
	if check_setup() != "":
		return
	var fitted := PackedVector2Array([from_node.position])
	for i in range(1, points.size() - 1):
		var c := Hex.from_pixel(points[i], EnchantmentScene.HEX_SIZE)
		fitted.append(Hex.to_pixel(c, EnchantmentScene.HEX_SIZE))
	fitted.append(to_node.position)
	if points != fitted:
		points = fitted


func _get_configuration_warnings() -> PackedStringArray:
	var out := PackedStringArray()
	if not get_parent() is EnchantmentScene:
		out.append("Put this line directly under an EnchantmentScene")
	var err := check_setup()
	if err != "":
		out.append(err)
	return out
