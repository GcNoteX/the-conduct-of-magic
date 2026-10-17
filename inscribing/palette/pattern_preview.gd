class_name PatternPreview
extends Control

## A small drawing of an enchantment's shape (nodes and its own lines), or a plain swatch when
## there's no enchantment. Used on palette cards.

var enchantment: Enchantment
var color := Color.WHITE


func _draw() -> void:
	var centre := size / 2.0
	if enchantment == null or enchantment.nodes.is_empty():
		draw_circle(centre, minf(size.x, size.y) * 0.32, color, true, -1.0, true)
		return
	var cells: Array[Vector2i] = []
	for n in enchantment.nodes:
		cells.append(n.offset)
	for l in enchantment.lines:
		cells.append_array(l.cells)
	var bounds := Rect2(Hex.to_pixel(cells[0], 1.0), Vector2.ZERO)
	for c in cells:
		bounds = bounds.expand(Hex.to_pixel(c, 1.0))
	bounds = bounds.grow(0.6)
	var scale_by := minf(size.x / bounds.size.x, size.y / bounds.size.y)
	var to_local := func(c: Vector2i) -> Vector2:
		return centre + (Hex.to_pixel(c, 1.0) - bounds.get_center()) * scale_by
	for l in enchantment.lines:
		var pts := PackedVector2Array()
		pts.append(to_local.call(enchantment.nodes[l.from_node].offset))
		for c in l.cells:
			pts.append(to_local.call(c))
		pts.append(to_local.call(enchantment.nodes[l.to_node].offset))
		draw_polyline(pts, color.darkened(0.3), maxf(2.0, scale_by * 0.3), true)
	for n in enchantment.nodes:
		draw_circle(to_local.call(n.offset), maxf(3.0, scale_by * 0.38), color, true, -1.0, true)
