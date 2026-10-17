class_name ClassicLists
extends PaletteLayout

## The original lists, kept for comparison: click an enchantment to hold it, drag a material.

signal enchantment_chosen(e: Enchantment)

var _enchantments: ItemList
var _materials: MaterialList
var _shown: Array[Enchantment] = []


func _init() -> void:
	custom_minimum_size.x = 280
	var v := VBoxContainer.new()
	v.set_anchors_preset(Control.PRESET_FULL_RECT)
	v.offset_left = 12
	v.offset_top = 12
	v.offset_right = -12
	v.add_theme_constant_override("separation", 8)
	add_child(v)
	_enchantments = ItemList.new()
	_enchantments.custom_minimum_size.y = 4 * 30 + 8
	_enchantments.item_selected.connect(func(i: int): enchantment_chosen.emit(_shown[i]))
	_materials = MaterialList.new()
	_materials.custom_minimum_size.y = 6 * 30 + 8
	for pair in [["Enchantments", _enchantments], ["Materials", _materials]]:
		var l := Label.new()
		l.text = pair[0]
		l.add_theme_font_size_override("font_size", 18)
		v.add_child(l)
		v.add_child(pair[1])


func slot() -> Slot:
	return Slot.LEFT


## Exposes the material list so the table can hear its drags
func material_list() -> MaterialList:
	return _materials


func set_cards(enchantments: Array[PaletteCard], materials: Array[PaletteCard]) -> void:
	_enchantments.clear()
	_shown.clear()
	for c in enchantments:
		var e := c.payload as Enchantment
		_shown.append(e)
		_enchantments.add_item(e.enchantment_name)
		_enchantments.set_item_tooltip(_enchantments.item_count - 1, c.tooltip_text)
		c.queue_free()
	_materials.clear()
	_materials.materials.clear()
	for c in materials:
		var m := c.payload as EnchantmentMaterialDefinition
		_materials.materials.append(m)
		_materials.add_item("%s  %s" % [c.title, c.subtitle])
		_materials.set_item_custom_fg_color(_materials.item_count - 1, m.color.lightened(0.3))
		_materials.set_item_tooltip(_materials.item_count - 1, c.tooltip_text)
		c.queue_free()
