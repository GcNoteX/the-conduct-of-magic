class_name MaterialList
extends ItemList

## The player's materials, one row each. A row is dragged onto the board to insert that material.

signal drag_started(material: EnchantmentMaterialDefinition)

## The material on each row, in row order
var materials: Array[EnchantmentMaterialDefinition] = []
## The materials whose rows can't be dragged right now (none left, or Disenchant mode).
## A drag attempt on one only emits drag_started, so the table can say why.
var locked: Array[EnchantmentMaterialDefinition] = []


func _get_drag_data(at_position: Vector2) -> Variant:
	var i := get_item_at_position(at_position, true)
	if i < 0 or i >= materials.size():
		return null
	var m := materials[i]
	if m in locked:
		drag_started.emit(m)
		return null
	set_drag_preview(_preview(m))
	drag_started.emit(m)
	return m


func _preview(m: EnchantmentMaterialDefinition) -> Control:
	var holder := Control.new()
	var chip := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = m.color
	style.set_corner_radius_all(14)
	style.set_content_margin_all(6)
	chip.add_theme_stylebox_override("panel", style)
	var label := Label.new()
	label.text = InscriptionBoard.material_name(m)
	label.add_theme_color_override("font_color", Color.BLACK)
	chip.add_child(label)
	chip.position = Vector2(12, 12)
	holder.add_child(chip)
	return holder
